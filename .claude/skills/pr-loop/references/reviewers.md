# [REVIEWER_REGISTRY]

Keyed by GitHub identity. Each row registers a reviewer's completion signal, false-positive surface, re-trigger, and severity grammar; `scripts/watch-reviewers.sh` decides completion executably — a predicate change lands in the script and this prose in one pass. Bot logins are case-sensitive; match on `user.login` (`author.login` in GraphQL), never on GitHub search qualifiers (`reviewed-by:`/`commenter:` silently drop `[bot]` scopes). No completion predicate reads any issue-comment `updated_at` — bots edit summaries in place and that churn is the canonical false positive.

## [01]-[CODERABBIT]

- Logins: `coderabbitai[bot]` (also match `coderabbit[bot]`, `coderabbitai`).
- Completes when: a review object by the bot at the current head whose body opens `**Actionable comments posted: N**`, OR the legacy commit-status context `CodeRabbit` reads `success` (it posts a status, not a check-run). Running while an issue comment carries `review in progress by coderabbit.ai` or the `CodeRabbit` status is `pending`.
- Ignore (never a signal): the sticky summary/walkthrough comment and its `updated_at` (churns on old PRs), `Review skipped`/draft notices, the `Failed to replace (edit) comment` self-note.
- Re-trigger: push (auto; `auto_incremental_review`) or `@coderabbitai review` / `@coderabbitai full review`. Guards before any mention: no `pending` CodeRabbit status at head, no trigger comment since the last head advance, and at most 2 explicit triggers per PR per rolling hour (the watcher ledger's `explicit_triggers` rows carry the timestamps; a third is refused and surfaced as possible rate-limiting).
- Chat verbs: `@coderabbitai resolve` (bulk-resolves ITS OWN threads only), `summary`, `pause`, `resume`.
- Severity: first body line `_<class>_ | _<dot> <word>_` — Critical=4, Major=3, Minor=2, Nitpick=1.

## [02]-[GREPTILE]

- Logins: `greptile-apps[bot]` (staging `greptile-apps-staging[bot]`). `@greptileai`/`@greptile` are trigger keywords, never author matches.
- Completes when: the `Greptile Review` check-run (app `greptile-apps`) reaches `COMPLETED`, OR the summary issue comment's footer `Last reviewed commit: .../commit/<sha>` matches the current head. Greptile posts the summary as an issue comment plus the check-run — no PR review object; the review-object surface stays empty by design.
- Ignore: summary `updated_at` churn; `<!-- greptile-status -->` skip/excluded-author comments; Greptile's internal "addressed" flag (never a GitHub thread resolve).
- Re-trigger: push (auto; `triggerOnUpdates: true`, drafts included via `triggerOnDrafts: true`) or comment `@greptileai`. Footer's Re-trigger link is web-only — unusable from `gh`.
- Severity: inline bold category prefix — `**logic:**`=3, `**syntax:**`=2, `**style:**`=1; legacy P1/P2/P3 badges map 3/2/1. `Confidence Score: N/5` lives in the summary body; convergence demands `5/5` at the current head — a completion signal never gates on it.

## [03]-[MACROSCOPE]

- Login: `macroscopeapp[bot]`; GitHub App id `900172` — key every check read on `checkSuite.app.databaseId`, never a check-name roster (custom rules add named checks beside `Macroscope - Correctness Check` and `Macroscope - Approvability Check`).
- Completes when: at least one app-900172 check-run exists at head and ALL of them read `status == COMPLETED`. Conclusions are `neutral` by design — a gate treating non-`success` as failure wedges forever; `neutral` is done, and approvability lives in the comment verdict, not the conclusion.
- Surfaces: a review object, inline comments, an issue-comment summary, and a PR-body block between `<!-- Macroscope's pull request summary starts here -->` markers.
- Re-trigger: push (auto). Explicit: `POST repos/{o}/{r}/check-runs/{id}/rerequest` on an app-900172 run is the primary route — best-effort, a user token rerequesting another app's run may 403, falling back to the next push; the `@macroscope-app review` mention is vendor-documented but unverified live.
- Severity: first line `<emoji> **<word>**` — Critical=4, High=3, Medium=2, Low=1. Approvability blocks on unresolved comments at or above its Minimum Blocking Severity (default Medium).

## [04]-[OPENAI_CODEX]

- Login: `chatgpt-codex-connector[bot]` (the cloud connector; `openai/codex-action` posts as `github-actions[bot]`).
- Completes when: a review object by the bot at the current head. No check-run, no in-progress marker — an engaged-but-stale review (prior head) or a seat in `reviewRequests` is the running signal.
- Re-trigger: `@codex review` (optionally with instructions). Bare `@codex <text>` starts a cloud code task that pushes commits — only the `review` verb re-reviews.
- Severity: `P0`=4 `P1`=3 `P2`=2 `P3`=1, as shields badges or a leading `Pn:`.

## [05]-[CLAUDE_APP]

- Login: `claude[bot]` (verify per install; the author scan catches variants).
- Completes when: a review object at the current head. Re-trigger: `@claude` mention.

## [06]-[HUMANS]

- Any author whose `type` is not `Bot`. Complete when a non-`PENDING` review exists at the current head; an open `CHANGES_REQUESTED` at head is complete-but-blocking and drives `reviewDecision`.
- Re-trigger: `gh pr edit <pr> --add-reviewer <login>`. A human thread resolves only when its author's concern is actually met — a pushback reply never resolves a human thread.

## [07]-[SEVERITY_NORMALIZATION]

`scripts/merge-comments.py` folds every native grammar onto one scale: `CRITICAL=4 MAJOR=3 MINOR=2 NIT=1 INFO=0`. Unrecognized linter bots (rule-tag bodies) land at INFO. Two reviewers flagging one `path:line:issue_class` collapse to the higher rank with the shadowed reviewer in `dups[]` — corroboration without duplicate work.

## [08]-[AUTHOR_SCAN_FALLBACK]

Any bot author not keyed above: gather its unresolved current-head threads generically, treat a review object at head as completion, re-trigger by push only, and name it in the final report so its row joins this registry.

## [09]-[ORG_DASHBOARDS]

Both config-owned reviewers honor an org/dashboard layer that can override repo config (Greptile: dashboard defaults < org rules < repo `.greptile/` < org ENFORCED rules; CodeRabbit org settings can force-disable auto-review). A reviewer that stays `NEVER_TRIGGERED` after one guarded re-trigger is presumed dashboard-disabled: drop it from the expected set, name it in the report.
