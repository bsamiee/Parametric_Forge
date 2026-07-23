# [GITHUB_TOOLKIT]

Copyable `gh`/GraphQL/REST patterns for the judgment-bearing spine steps; the judgment-free steps (watch, pull, merge-set, resolve, converge-read) ride the bundled scripts and never re-derive their queries here. `{owner}`/`{repo}` are auto-filled by `gh` from the repo cwd; `$PR`, `$PRID`, `$HEAD`, `$BRANCH`, `$BASE` are shell vars. `mcp__github__*` tools win only single typed writes (one resolve, one reply, one reaction); the bulk pull rides `gh api` — the MCP projections omit the fixer anchor fields (diffSide, subjectType, originalLine, review join, databaseId).

## [01]-[S0_PIN_HEAD]

Identify the PR and pin the head SHA — first thing, at the top of every phase.

```bash template
read -r PR PRID HEAD BRANCH <<<"$(gh pr view --json number,id,headRefOid,headRefName \
  -q '[.number,.id,.headRefOid,.headRefName]|@tsv')"
# Branch->PR without relying on current-branch inference (detached HEAD / CI):
gh pr list --state open --head "$(git branch --show-current)" \
  --json number,id,headRefOid -q '.[0]'
```

`id` (`PR_kwDO...`) is the GraphQL node id; `number` drives REST. Stale-SHA invariant: `HEAD` is the one source of truth — re-pin after every push; a review or comment is current iff its (or its parent review's) `commit_id == HEAD`, a thread iff `isOutdated == false`.

## [02]-[S1_FEEDBACK_SURFACES]

Four orthogonal surfaces — reviews, inline review comments, issue comments, review threads (the only carrier of resolution state) — pull to disk via `${CLAUDE_SKILL_DIR}/scripts/pull-comments.sh` and join via `merge-comments.py`. Field law the consumer needs:
- An outdated inline comment carries `line == null`; anchor on `original_line`. `subject_type == "file"` anchors on `path` alone.
- `pull_request_review_id` joins an inline comment to its owning review for the review-level `commit_id` and verdict; the thread comment's `databaseId` is the REST join key and the `#discussion_r<id>` anchor.
- Bots edit summaries in place — track `updated_at` high-water on issue comments for report freshness, never as a completion signal.

## [03]-[S2_REVIEWER_STATE]

Two disjoint check systems coexist on a commit; the watcher's snapshot reads both. One-off manual reads:

```bash template
gh api repos/{owner}/{repo}/commits/$HEAD/check-runs --paginate \
  -q '.check_runs[]|{name,app:.app.slug,app_id:.app.id,status,conclusion}'
gh api repos/{owner}/{repo}/commits/$HEAD/status \
  -q '{state:.state, contexts:[.statuses[]|{context,state}]}'
```

`conclusion` is null until `status == completed`; Macroscope concludes `neutral` — completion keys on `status`, never on a `success` conclusion. Review-only bots (Codex, Claude, humans) appear in neither system — their signal is a review object at `$HEAD`.

## [04]-[S3_RETRIGGER]

Idempotent per-reviewer re-trigger — guards, strings, and caps are the registry's (`reviewers.md`); the mechanical forms:

```bash template
gh pr comment "$PR" --body "@coderabbitai review"                    # after the registry guards pass
gh api -X POST repos/{owner}/{repo}/check-runs/$RUN_ID/rerequest     # Macroscope, best-effort
gh pr edit "$PR" --add-reviewer "$LOGIN"                             # humans
```

## [05]-[S4_THREAD_MUTATIONS]

Batch resolve and disposition-driven replies ride `${CLAUDE_SKILL_DIR}/scripts/resolve-threads.sh`. One-off manual forms:

```bash template
gh api graphql -f tid="$THREAD_NODE_ID" -f body="$REPLY" -f query='
  mutation($tid:ID!,$body:String!){
    addPullRequestReviewThreadReply(input:{pullRequestReviewThreadId:$tid,body:$body}){comment{id}}}'
gh api graphql -f query='mutation{t0:resolveReviewThread(input:{threadId:"PRRT_..."}){thread{id isResolved}}}'
```

`threadId` takes the thread NODE id (`PRRT_...`), never the REST comment id; resolving an already-resolved thread is a no-op. `unresolveReviewThread` reopens with the identical input. Batch via aliases in ONE round-trip — secondary rate limits punish burst writes, never a resolve-per-thread loop.

## [06]-[S6_MERGE_SURFACE]

`${CLAUDE_SKILL_DIR}/scripts/converge.sh` reads the convergence gate. Raw merge-surface read for the report:

```bash template
gh pr view "$PR" --json reviewDecision,mergeable,mergeStateStatus,statusCheckRollup
```

`mergeable in MERGEABLE|CONFLICTING|UNKNOWN` (UNKNOWN = still computing, re-read). `mergeStateStatus in CLEAN|HAS_HOOKS|UNSTABLE|BLOCKED|BEHIND|DIRTY|UNKNOWN`; `BEHIND` -> `gh pr update-branch "$PR"`; `DIRTY` (conflicts) -> human.

## [07]-[S8_SHIP]

Branch, commit, push, open — PHASE 1's mechanics; the commit message and PR narrative stay judgment.

```bash template
git checkout -b "$BRANCH"                                    # only when on the default branch
git add -A && git commit -m "$MSG"                           # scoped adds when the tree is mixed
git push -u origin "$BRANCH"
gh pr create --base "$BASE" --title "$TITLE" --body "$BODY"  # non-draft; --fill when commits carry it
```

## [08]-[S9_MERGE_CLOSEOUT]

PHASE 7's terminal act — squash-merge, base sync, local delete, clean verify.

```bash template
gh pr merge "$PR" --squash --delete-branch
git checkout "$BASE" && git pull --ff-only
git branch -d "$BRANCH" 2>/dev/null || true      # -d asserts the squash landed; remote self-deletes
git status --porcelain=v2                        # empty
git ls-remote --heads origin "$BRANCH"           # empty
```

## [09]-[CROSS_CUTTING]

- Pagination: REST `--paginate` (+ `?per_page=100`); GraphQL `--paginate` needs `$endCursor: String` and `pageInfo{ hasNextPage endCursor }`, max `first:100`.
- Rate: 5000/hr each rail (`gh api rate_limit`); a full four-surface pull of a 50-thread PR costs 5 calls, the watcher <1% of the GraphQL pool per arming. Honor a `Retry-After` on 403.
