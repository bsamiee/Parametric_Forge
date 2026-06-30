# Reviewer registry

Keyed by GitHub identity. The loop gathers each active reviewer's comments, detects its completion, and re-triggers it by the listed mechanism. Any bot not listed is handled by the author-scan fallback at the end. Bot logins are case-sensitive; match on `user.login` (or `author.login` in GraphQL), never on GitHub search qualifiers (`reviewed-by:`/`commenter:` silently drop `[bot]` scopes).

## CodeRabbit

- Logins: `coderabbitai[bot]` (also match `coderabbit[bot]`, `coderabbitai`).
- Surfaces: a sticky summary/walkthrough as an issue comment edited in place (read `updated_at`, not `created_at`); inline review threads; a `COMMENTED` review object.
- Re-trigger: push (auto-reviews each push by default); `@coderabbitai review` (incremental) or `@coderabbitai full review` (from scratch). `@coderabbitai resolve` bulk-resolves its own threads.
- Completion: the ack comment text transitions `Review triggered.` -> `Review finished.` (and `Full review ...`). In progress while the newest body contains `Come back again in a few minutes`.
- Confidence: none; severity labels only. Actionable thread predicate: `isResolved == false && isOutdated == false` with the root author a CodeRabbit login.

## Greptile

- Logins: `greptile-apps[bot]` (staging `greptile-apps-staging[bot]`). `@greptileai` / `@greptile` are trigger keywords, not user accounts — do not match them as authors.
- Surfaces: a single summary-plus-score issue comment edited in place (pick by latest `updated_at`); inline threads carrying P1/P2/P3 badges; the review object body is empty (the score is not there).
- Re-trigger: push only when `greptile.json` has `triggerOnUpdates: true`; otherwise `@greptile review` (supports scoped natural language, e.g. `@greptile review only the API changes`). A retrigger link sits in every summary footer.
- Completion: the summary footer `Last reviewed commit` equals the current head, and the `Reviews (N)` counter increments; the `name ~ /greptile/i` check-run flips `in_progress` -> `completed` only when `statusCheck` is enabled.
- Confidence: `Confidence Score: N/5` in the summary body — regex `Confidence Score:\s*([0-5])/5`. Convergence requires `5/5`. Greptile's internal "addressed" flag is not a GitHub thread resolve; resolve threads via the GraphQL mutation.

## Macroscope

- Login: `macroscopeapp[bot]` (GitHub App id `900172`).
- Surfaces: a `COMMENTED`/`APPROVED` review; inline comments; an issue-comment summary; a PR-body block between `<!-- Macroscope's pull request summary starts here -->` and its `ends here` marker; check runs `Macroscope - Correctness Check` and `Macroscope - Approvability Check`.
- Re-trigger: push (auto); a check-run rerequest (`POST repos/{owner}/{repo}/check-runs/{id}/rerequest`) re-fires the agent. Mention handle is unverified across docs (`@macroscope review` vs `@macroscope-app review`) — prefer the check-run rerequest over a mention.
- Completion: poll `check-runs`, filter `app.id == 900172` (or the `Macroscope - ` name prefix), done when `status == "completed"`. Receipt line: `Macroscope summarized <sha>. N files reviewed, ...`.
- Confidence: severity `Low`/`Medium`/`High`/`Critical`; Approvability gates on unresolved comments at or above the Minimum Blocking Severity (default `Medium`). No number.

## Gemini Code Assist

- Login: `gemini-code-assist[bot]` (id `176961590`) — one login for summary, review, and inline comments. The plain `gemini-code-assist` user (id `200291788`) is a different account, not the reviewer.
- Surfaces: a `COMMENTED` review whose body opens `## Code Review`; inline comments each prefixed with a severity badge `https://www.gstatic.com/codereviewagent/<low|medium|high|critical>-priority.svg`; an issue-comment summary. No check-run; no PR-body edit.
- Re-trigger: `/gemini review` as a top-level issue comment (`/gemini summary`, `/gemini help` also exist). Auto on open via `.gemini/config.yaml` (`code_review.pull_request_opened`); `comment_severity_threshold` default `MEDIUM`.
- Completion: appearance of the `gemini-code-assist[bot]` review object (state always `COMMENTED`; it never gates merge).
- Confidence: per-finding `LOW`/`MEDIUM`/`HIGH`/`CRITICAL` via the badge image; no overall rating.

## OpenAI Codex (ChatGPT connector)

- Login: `chatgpt-codex-connector[bot]` (id `199175422`). This is the cloud connector, not `openai/codex-action` (which posts as `github-actions[bot]`).
- Surfaces: a standard PR review plus inline review threads. Reacts with an eyes glyph on the trigger, flipping to a thumbs-up when an auto-review finds nothing.
- Re-trigger: `@codex review` (optionally `@codex review <instructions>`); auto on open when "Automatic reviews" is enabled. Note: `@codex <other text>` starts a Codex cloud task (can push a fix) rather than a review — use only `@codex review` to re-review.
- Completion: a posted review by the bot; no separate check-run gate.
- Confidence: priority tags `P0`/`P1` by default (`P2`/`P3` only when an `AGENTS.md` review section defines them); no number.

## Claude GitHub app

- Login: detect at runtime via the author scan (the exact `[bot]` login depends on the install; commonly a `claude`-prefixed bot or the Actions identity). Re-trigger: `@claude` mention. Surfaces: posted review plus inline comments. Confidence: per its configuration. Until the login is confirmed for this repo, the author-scan fallback gathers and reports it.

## Human reviewers

- Any author whose `type` is not `Bot`. Their review `state` (`APPROVED`/`CHANGES_REQUESTED`/`COMMENTED`) drives `reviewDecision`; an open `CHANGES_REQUESTED` on the current head blocks convergence. Re-request with `gh pr edit <pr> --add-reviewer <login>`. Address their comments like any other, but never resolve a human thread the fix did not actually satisfy.

## Author-scan fallback

For any reviewer not keyed above, scan the PR's reviews and comments for authors with `user.type == "Bot"` (or a `[bot]` login suffix) that are not already handled, gather their unresolved current-head comments generically, treat completion as "review object present for the current head," re-trigger by push only (no known mention), and name the unknown reviewer explicitly in the final report so its trigger can be added to this registry.
