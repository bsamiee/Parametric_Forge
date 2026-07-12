# [REVIEWER_REGISTRY]

Keyed by GitHub identity. The loop gathers each active reviewer's comments, detects its completion, and re-triggers it by the listed mechanism. Any bot not listed rides the author-scan fallback. Bot logins are case-sensitive; match on `user.login` (or `author.login` in GraphQL), never on GitHub search qualifiers (`reviewed-by:`/`commenter:` silently drop `[bot]` scopes).

## [01]-[CODERABBIT]

- Logins: `coderabbitai[bot]` (also match `coderabbit[bot]`, `coderabbitai`).
- Surfaces: a sticky summary/walkthrough as an issue comment edited in place (read `updated_at`, not `created_at`); inline review threads; a `COMMENTED` review object.
- Re-trigger: push (auto-reviews each push by default); `@coderabbitai review` (incremental) or `@coderabbitai full review` (from scratch). `@coderabbitai resolve` bulk-resolves its own threads.
- Completion: the ack comment text transitions `Review triggered.` -> `Review finished.` (and `Full review ...`). In progress while the newest body contains `Come back again in a few minutes`.
- Confidence: none; severity labels only. Actionable thread predicate: `isResolved == false && isOutdated == false` with the root author a CodeRabbit login.

## [02]-[GREPTILE]

- Logins: `greptile-apps[bot]` (staging `greptile-apps-staging[bot]`). `@greptileai` / `@greptile` are trigger keywords, not user accounts — never match them as authors.
- Surfaces: a single summary-plus-score issue comment edited in place (pick by latest `updated_at`); inline threads carrying P1/P2/P3 badges; the review object body is empty (the score is not there).
- Re-trigger: push only when `greptile.json` has `triggerOnUpdates: true`; otherwise `@greptile review` (scoped natural language works, e.g. `@greptile review only the API changes`). A retrigger link sits in every summary footer.
- Completion: the summary footer `Last reviewed commit` equals the current head, and the `Reviews (N)` counter increments; the `name ~ /greptile/i` check-run flips `in_progress` -> `completed` only when `statusCheck` is enabled.
- Confidence: `Confidence Score: N/5` in the summary body — regex `Confidence Score:\s*([0-5])/5`. Convergence requires `5/5`. Greptile's internal "addressed" flag is not a GitHub thread resolve; resolve threads via the GraphQL mutation.

## [03]-[MACROSCOPE]

- Login: `macroscopeapp[bot]` (GitHub App id `900172`).
- Surfaces: a `COMMENTED`/`APPROVED` review; inline comments; an issue-comment summary; a PR-body block between `<!-- Macroscope's pull request summary starts here -->` and its `ends here` marker; check runs `Macroscope - Correctness Check` and `Macroscope - Approvability Check`.
- Re-trigger: push (auto); a check-run rerequest (`POST repos/{owner}/{repo}/check-runs/{id}/rerequest`) re-fires the agent. The mention handle is unverified across docs (`@macroscope review` vs `@macroscope-app review`) — prefer the check-run rerequest over a mention.
- Completion: poll `check-runs`, filter `app.id == 900172` (or the `Macroscope - ` name prefix), done when `status == "completed"`. Receipt line: `Macroscope summarized <sha>. N files reviewed, ...`.
- Confidence: severity `Low`/`Medium`/`High`/`Critical`; Approvability gates on unresolved comments at or above the Minimum Blocking Severity (default `Medium`). No number.

## [04]-[OPENAI_CODEX]

- Login: `chatgpt-codex-connector[bot]` (id `199175422`). This is the cloud connector, not `openai/codex-action` (which posts as `github-actions[bot]`).
- Surfaces: a standard PR review plus inline review threads. Reacts with an eyes glyph on the trigger, flipping to a thumbs-up when an auto-review finds nothing.
- Re-trigger: `@codex review` (optionally `@codex review <instructions>`); auto on open when "Automatic reviews" is enabled. `@codex <other text>` starts a Codex cloud task (which pushes fixes) rather than a review — only `@codex review` re-reviews.
- Completion: a posted review by the bot; no separate check-run gate.
- Confidence: priority tags `P0`/`P1` by default (`P2`/`P3` only when an `AGENTS.md` review section defines them); no number.

## [05]-[CLAUDE_GITHUB_APP]

- Login: detected at runtime via the author scan — the exact `[bot]` login depends on the install, commonly a `claude`-prefixed bot or the Actions identity.
- Surfaces: posted review plus inline comments.
- Re-trigger: `@claude` mention.
- Confidence: per its configuration. Until the login is confirmed for the repo, the author-scan fallback gathers and reports it.

## [06]-[HUMANS]

- Any author whose `type` is not `Bot`. Their review `state` (`APPROVED`/`CHANGES_REQUESTED`/`COMMENTED`) drives `reviewDecision`; an open `CHANGES_REQUESTED` on the current head blocks convergence.
- Re-trigger: `gh pr edit <pr> --add-reviewer <login>`.
- Their comments triage like any other; a human thread resolves only when the fix actually satisfies it.

## [07]-[AUTHOR_SCAN_FALLBACK]

For any reviewer not keyed above: scan the PR's reviews and comments for authors with `user.type == "Bot"` (or a `[bot]` login suffix) not already handled, gather their unresolved current-head comments generically, treat completion as a review object present for the current head, re-trigger by push only (no known mention), and name the unknown reviewer explicitly in the final report so its trigger joins this registry.
