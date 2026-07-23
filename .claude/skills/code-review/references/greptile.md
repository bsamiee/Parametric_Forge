# [GREPTILE]

Greptile reviews committed unmerged commits against a base ref — uncommitted edits never enter, recorded by a launch-time `warning: N uncommitted files not included` stderr line — so work commits first, and work sitting on the base moves to a branch or passes `-b <base>` (any committish: branch, remote-tracking ref, or SHA). Reviews are language-agnostic over the diff; `ignorePatterns` and `--include` are the only file gates.

## [01]-[RUN_FACTS]

- Command roster: `review` (subcommands `show [id]`, `status`), `config [path] [--json]`, `login`, `logout`, `whoami`, `settings`, `update`; `onboard` and `fix` sit outside review work.
- `review` flags: `--json` emits the findings envelope on stdout — the harvest source; `-b/--branch <base>` sets the base (omitted, the repo default); `--instructions <text>` carries per-review focus, the same channel as `@greptile <text>` on a PR; `--resume` continues an unfinished review with no new spend, never a re-spending relaunch; `--include <paths...>` admits sensitivity-held files (`.env`, `*.pem`) the engine otherwise silently excludes.
- Exit 0 with a parseable envelope is success at any comment count — identical re-reviews yield differing counts, so zero comments is never failure. A refusal or client error is nonzero exit with the message on its own stderr line and EMPTY stdout — no ledger row, no spend.
- Size gating is a client-side preflight over `git diff -U3 <merge-base>...HEAD`, refusing in under a second before any network at three hard caps: over 500 changed files (`this review touches N files`), over 50 changed Greptile config files, and over 3,000,000 payload bytes (`this review is too large to send`) summing per-file patch and path bytes, range commit subjects and bodies, changed-config contents, and `--instructions` text. A large campaign lands as slice commits, each reviewed with `-b` at the prior boundary.
- Comment generation degrades before the caps refuse: a full-campaign single-range review under the preflight can return a rich summary with an EMPTY `comments` array — the summary carries real cross-file findings as prose, but the structured pipeline receives zero rows. A pinned-base range serves the cross-file coherence read; comment-bearing collection rides bounded ranges, and a summary-only round's findings hand-carry into the pool until rail ingestion owns them.
- `review status --commit <ref> --json` (default `HEAD`) is the out-of-band phase oracle: `COMPLETED` exits 0, `IN_FLIGHT` exits 3, a never-reviewed commit exits 1 with a stderr hint. Stream silence between launch and the terminal JSON dump is the engine's normal shape.

## [02]-[ENVELOPE]

- Top-level keys carry `summary`, `confidence`, `confidenceReasoning`, `securitySummary`, `instructions`, `comments` — `comments[]` is a flat top-level array, and delivery or render config never changes which of these appear.
- Comment keys carry `id`, `path`, `startLine`, `endLine`, `side`, `severity`, `securityIssue`, `category`, `body`, `verifiedEvidence`, `suggestion`, `hunk`; `suggestion` and `verifiedEvidence` are `null` when absent, and `securityIssue` is a bool data field — no security mode or flag exists.
- `hunk` is `null` or an object `{header, oldRange, newRange, before, after}` — `header` the `@@`-line, `oldRange`/`newRange` each `{start, lines}`, `before`/`after` the excerpt text or `null` — never a string.
- `severity` is a per-finding P-scale the model assigns — `P0` critical through `P4` info — a separate scale from rule `severity`, which no config maps onto it.

## [03]-[CONFIG_CASCADE]

`.greptile/` in any directory configures reviews for that tree; three optional files, and a single-file form (`greptile.json` or `.greptile.json`) that loses to a same-directory `.greptile/`.

- [CONFIG]: `config.json` — review settings, run filters, structured rules, cross-repo context.
- [RULES]: `rules.md` — free-prose review charter; severities and rule ids live only in `config.json`.
- [FILES]: `files.json` — `{"files": [{path, description, scope?}]}` points the reviewer at load-bearing repo files; `path` resolves relative to the directory holding `.greptile/`, so doctrine-pointing without duplication is the sanctioned use.

Cascade: the walk from repository root to each reviewed file collects every `.greptile/` on the path — scalars take the most-specific value, arrays replace parent arrays, and rules, file references, and instructions accumulate; org enforced rules always win, and a child disables an inherited rule by listing its `id` in `disabledRules`.

## [04]-[CONFIG_FIELDS]

Generation knobs change the `comments[]` set the CLI surfaces — one cloud engine serves the CLI and the PR bot from one resolved config:

| [INDEX] | [KNOB]            | [LOCAL_EFFECT]                                                                        |
| :-----: | :---------------- | :------------------------------------------------------------------------------------ |
|  [01]   | `strictness`      | importance threshold, int `1` verbose to `3` critical-only; cascade merges to MAX     |
|  [02]   | `commentTypes`    | categories generated from `syntax`/`logic`/`style`/`info`; array REPLACES the default |
|  [03]   | `rules`           | rows `{id, rule, severity, enabled, scope?}`; `scope` globs gate resolution per path  |
|  [04]   | `disabledRules`   | inherited rule ids disabled for this tree                                             |
|  [05]   | `instructions`    | free-form reviewer text; concatenates down the cascade                                |
|  [06]   | `ignorePatterns`  | one newline-separated gitignore-syntax string, never an array                         |
|  [07]   | `fileChangeLimit` | hosted-PR skip gate on changed-file count; never the CLI size preflight               |
|  [08]   | `context.repos`   | `owner/repo` list, same SCM host and credentials                                      |

`scope` globs never cross dot-directories, so every dot-dir surface — `.claude/**`, `libs/.planning/**`, `**/.api/**` — carries its explicit glob, and a scoped rule proves live only through the `greptile config <path>` oracle probed at a path INSIDE the dot-dir; the oracle truncates each rule's text with an ellipsis, so a deep-clause substring proves against `.greptile/config.json` full text instead.

`rules[].severity` (`low`/`medium`/`high`) is a generation-stage importance hint against the strictness threshold — load-bearing at strictness 3, near-inert at 1 — never a local pass/fail gate and never the emitted P-scale. Every other field is PR-only decoration, absent from `--json`: `statusCheck`, `statusCommentsEnabled`, the four summary-section toggles, `triggerOnUpdates`/`triggerOnDrafts`/`skipReview`, the label/author/branch/keyword PR filters, and `shouldUpdateDescription`/`updateSummaryOnly`/`hideFooter`/`fixWithAI` — GitHub delivery and rendering over the same generated review.

## [05]-[DISTILL_SURFACE]

A distill fact takes exactly one home — double-spelling one fact across `config.json` and `rules.md` is the named defect: structured hunt rules live only as `config.json` `rules[]` rows `{id, rule, severity, enabled, scope}` (an outgrown row splits into sibling ids, never a swollen blob), and stance or do-not-flag law lives only in the owning `rules.md` section, one sentence per fact. Placement follows the cascade — a repo-wide fact at the root `.greptile/`, a tree-scoped fact in that tree's own — and correct rule text with a tight `scope` is the real bite, `severity` set honestly.

No JSON Schema exists for `config.json` — `greptile config` is the format gate, and it reads the UNCOMMITTED working-tree cascade, so a landed rule proves itself pre-commit by substring on the resolved rule text (org rules re-key to server UUIDs and reflow, so an id match always misses); a raw JSON parse is the syntactic floor alone.

## [06]-[RETRIEVAL_BRIDGE]

- `~/.greptile/reviews.json` is the CLI-local ledger, an object `{version, reviews[]}` spanning EVERY repo the machine reviews, newest first; rows carry `runId` (a CLI-local UUID, never the MCP `codeReviewId`), `remoteUrl`, `baseRef`/`headRef`, `baseSha`/`headSha`, `createdAt`/`completedAt`, `commentCount`, `confidence`, `summary`, `status` (`IN_FLIGHT`/`COMPLETED`), `accountKey`. A join filters rows on `remoteUrl` matching the repo's origin before taking the newest `createdAt` — a positional read lands another repo's review.
- Bridge a CLI run to its MCP row single-key on head sha: call `mcp__greptile__list_code_reviews` org-scoped with NO `name` filter — the git-remote casing 404s — and match ledger `headSha` == row `commitSha`, `baseSha` confirming; timestamp is no part of the match. Headless rows carry `source: "headless"` with `mergeRequest` null.
- MCP is retrieval and PR-only, never a per-round step: `trigger_code_review` starts PR reviews alone, so the CLI is the local rail and no branch or PR is ever created to run one.
- `get_code_review` returns the summary NARRATIVE — confidence reasoning and files table, never line findings — a recovery leg when the CLI log is lost, with the CLI `--json` `comments[]` authoritative.
- `search_greptile_comments` returns nothing for headless reviews account-wide, so recurrence and dedup never build on it — the rail's own fingerprint store owns local recurrence.
- Org custom context is the one channel `.greptile/` cannot reach — account-wide rules mutable only through MCP or the dashboard, composing into the resolved cascade as `(from org rule)` rows; a distill escalates there only when a lesson must bite every repo.
