# [GITHUB_TOOLKIT]

Copyable `gh`/GraphQL/REST patterns, labeled by the loop step each serves. `{owner}`/`{repo}` are auto-filled by `gh` from the repo cwd; `$PR`, `$PRID`, `$HEAD`, `$BRANCH` are shell vars. All field and enum names are introspection-verified. The `mcp__github__*` tools cover the same surface when shelling out is undesirable (`pull_request_read` for S1/S2, `pull_request_review_write` for per-thread resolve, `add_reply_to_pull_request_comment` for replies).

## [01]-[S0_PIN_HEAD]

Identify the PR and pin the head SHA — first thing, every iteration.

```bash
read -r PR PRID HEAD BRANCH <<<"$(gh pr view --json number,id,headRefOid,headRefName \
  -q '[.number,.id,.headRefOid,.headRefName]|@tsv')"
# Branch->PR without relying on current-branch inference (detached HEAD / CI):
gh pr list --state open --head "$(git branch --show-current)" \
  --json number,id,headRefOid -q '.[0]'
```

`id` (`PR_kwDO...`) is the GraphQL node id required by `enablePullRequestAutoMerge`; `number` drives REST.

## [02]-[S1_SNAPSHOT]

Snapshot all feedback in one pass. Four orthogonal sources; none subsumes another. Threads are the only source carrying resolution state.

```bash
# (a) Review verdicts. state in APPROVED|CHANGES_REQUESTED|COMMENTED|DISMISSED|PENDING.
gh api repos/{owner}/{repo}/pulls/$PR/reviews --paginate \
  -q '.[]|{id,user:.user.login,state,commit_id,submitted_at,body}'
# (b) Inline review comments (diff-anchored). commit_id vs $HEAD = fresh/outdated.
gh api repos/{owner}/{repo}/pulls/$PR/comments --paginate \
  -q '.[]|{id,user:.user.login,path,line,commit_id,in_reply_to_id,updated_at,body}'
# (c) Top-level / issue comments — where bots post rolling status, EDITED IN PLACE. Track updated_at.
gh api "repos/{owner}/{repo}/issues/$PR/comments?per_page=100${SINCE:+&since=$SINCE}" --paginate \
  -q '.[]|{id,user:.user.login,created_at,updated_at,edited:(.updated_at>.created_at),body}'
# (d) Review THREADS + resolution state (GraphQL only). Paginates via $endCursor.
gh api graphql --paginate -F owner='{owner}' -F repo='{repo}' -F pr="$PR" -f query='
query($owner:String!,$repo:String!,$pr:Int!,$endCursor:String){
  repository(owner:$owner,name:$repo){ pullRequest(number:$pr){
    reviewThreads(first:100, after:$endCursor){
      pageInfo{ hasNextPage endCursor }
      nodes{ id isResolved isOutdated isCollapsed viewerCanResolve path line
             comments(first:1){ nodes{ author{login} body url } } } } } } }'
```

In-place-edit detection: keep a high-water mark `SINCE=$(max updated_at across (b)+(c))`; a comment with `updated_at > SINCE` is new signal even if its `id` was seen.

## [03]-[S2_REVIEWER_STATE]

Per-reviewer check-run / status state — who finished versus still running. Two disjoint systems coexist on a commit; read both. Both are keyed on the SHA, so passing `$HEAD` keeps them fresh.

```bash
# Modern Checks API — grouped by producing app => per-reviewer finished state.
# status in queued|in_progress|completed ; conclusion in success|failure|neutral|cancelled|
#   skipped|timed_out|action_required|stale|startup_failure (null until completed)
gh api repos/{owner}/{repo}/commits/$HEAD/check-runs --paginate \
  -q '.check_runs[]|{name,app:.app.slug,app_id:.app.id,status,conclusion}'
# Legacy Commit Status API (older bots / external CI post here, not check-runs).
gh api repos/{owner}/{repo}/commits/$HEAD/status \
  -q '{state:.state, contexts:[.statuses[]|{context,state}]}'
# Normalized rollup for the merge gate (gh fuses both).
gh pr checks "$PR" --json name,state,bucket,workflow,completedAt,link   # bucket in pass|fail|pending|skipping|cancel
```

"Reviewer X still running" holds iff any check-run with `app.slug==X` (or `app.id`, or name match) has `status != completed`. "All finished" holds iff no such row remains — this is the wait predicate Step 2 blocks on.

## [04]-[S3_RETRIGGER]

Re-trigger a specific bot, idempotently. Detect "already running" before posting; guard against duplicate triggers on the same head.

```bash
BOT=coderabbitai
RUNNING=$(gh api repos/{owner}/{repo}/commits/$HEAD/check-runs \
  -q "[.check_runs[]|select((.app.slug==\"$BOT\") or (.name|ascii_downcase|contains(\"$BOT\")))
       |select(.status!=\"completed\")]|length")
ALREADY=$(gh api repos/{owner}/{repo}/issues/$PR/comments --paginate \
  -q "[.[]|select(.body|test(\"@${BOT} (full )?review\"))]|length")
if [ "$RUNNING" -eq 0 ] && [ "$ALREADY" -eq 0 ]; then
  gh pr comment "$PR" --body "@coderabbitai full review"
fi
```

Per-reviewer trigger strings live in `reviewers.md`. Re-request a human/team reviewer: `gh pr edit "$PR" --add-reviewer <login>`.

## [05]-[S4_BATCH_RESOLVE]

Batch-resolve review threads in one GraphQL round-trip. `resolveReviewThread` takes only `threadId: ID!`; resolving an already-resolved thread is a no-op (safe to over-include).

```bash
IDS=$(gh api graphql -F owner='{owner}' -F repo='{repo}' -F pr="$PR" -f query='
  query($owner:String!,$repo:String!,$pr:Int!){repository(owner:$owner,name:$repo){
    pullRequest(number:$pr){reviewThreads(first:100){nodes{id isResolved isOutdated}}}}}' \
  -q '.data.repository.pullRequest.reviewThreads.nodes[]|select(.isResolved==false)|.id')
M=$(printf '%s\n' "$IDS" | awk 'NF{printf "t%d:resolveReviewThread(input:{threadId:\"%s\"}){thread{id isResolved}}\n",NR-1,$0}')
[ -n "$M" ] && gh api graphql -f query="mutation{ $M }"
```

Reply instead of resolving (false positive): GraphQL `addPullRequestReviewThreadReply(input:{pullRequestReviewThreadId, body})`, or REST `POST pulls/$PR/comments` with `in_reply_to`.

## [06]-[S5_FRESH_REVIEWS]

Push, then detect reviews targeting the latest commit. After push the head advances; re-pin `$HEAD` and treat every prior review/comment as stale until proven by SHA equality.

```bash
git push origin "$BRANCH"
HEAD=$(gh pr view "$PR" --json headRefOid -q .headRefOid)   # re-pin AFTER push
gh api repos/{owner}/{repo}/pulls/$PR/reviews --paginate \
  -q ".[]|select(.commit_id==\"$HEAD\")|{user:.user.login,state,submitted_at}"
```

Never act on a `CHANGES_REQUESTED` whose `commit_id != $HEAD` — it predates the fix. A new review for the new head has landed when a review with `commit_id == $HEAD` exists, or the bot's check-run for `$HEAD` reached `completed`.

## [07]-[S6_CONVERGENCE]

Convergence read plus merge surface — read only; the loop never merges.

```bash
gh pr view "$PR" --json reviewDecision,mergeable,mergeStateStatus,statusCheckRollup \
  -q '{decision:.reviewDecision, mergeable:.mergeable, state:.mergeStateStatus,
       failing:[.statusCheckRollup[]|select((.conclusion//.state)
         |IN("FAILURE","ERROR","TIMED_OUT","ACTION_REQUIRED","CANCELLED","STARTUP_FAILURE"))]|length,
       pending:[.statusCheckRollup[]|select((.status=="IN_PROGRESS") or (.status=="QUEUED")
         or ((.conclusion//.state)=="PENDING"))]|length}'
```

`reviewDecision in APPROVED|CHANGES_REQUESTED|REVIEW_REQUIRED|null` (null = no required reviewers). `mergeable in MERGEABLE|CONFLICTING|UNKNOWN` (UNKNOWN = still computing, re-poll). `mergeStateStatus in CLEAN|HAS_HOOKS|UNSTABLE|BLOCKED|BEHIND|DIRTY|UNKNOWN`. Merge-ready: `mergeable==MERGEABLE && failing==0 && pending==0 && decision in {APPROVED,null} && state in {CLEAN,HAS_HOOKS}`. `BEHIND` -> `gh pr update-branch "$PR"`. `DIRTY` (conflicts) -> human. The merge itself (`gh pr merge`) is outside this skill's autonomy contract — report merge-ready and stop.

## [08]-[S7_POLLING]

Polling discipline — wait without busy-spinning.

```bash
gh pr checks "$PR" --watch --fail-fast --interval 30; RC=$?   # 0=all pass, 1=a check failed
```

Prefer the server-driven `--watch` (one long-poll) over repeated `gh pr checks`. Never poll threads/comments tighter than checks settle — feedback only changes after a check-run completes. Drive the wait off S2's "reviewer still running" predicate, not a fixed sleep.

## [09]-[CROSS_CUTTING]

- Pagination: REST `--paginate` (+ `?per_page=100`); GraphQL `--paginate` needs `$endCursor: String` and `pageInfo{ hasNextPage endCursor }`, max `first:100`.
- Rate limits: 5000/hr each for REST and GraphQL (`gh api rate_limit`); secondary limits punish burst writes, so batch resolves (S4 aliases) and never post in a tight loop; honor a `Retry-After` on 403.
- Stale-review invariant: `headRefOid` is the one source of truth — re-pin after every push and at the top of every iteration; a review/comment is current iff `commit_id == headRefOid`, a thread iff `isOutdated == false`.
