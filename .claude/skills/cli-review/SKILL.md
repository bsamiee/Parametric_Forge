---
name: cli-review
description: >-
    Runs a Greptile CLI review of the current local branch against its base — no PR needed —
    installing or authenticating the CLI when missing, then summarizes JSON findings by
    severity. Use for Greptile feedback before opening a PR, outside a hosted review flow, or
    directly from a local checkout. CodeRabbit review of working-tree changes belongs to
    code-review; hosted PR reviewer round-trips belong to pr-loop.
allowed-tools: Bash(git:*) Bash(greptile:*) Bash(command:*) Bash(curl:*) Bash(npm:*)
---

# [CLI_REVIEW]

Run a Greptile review from the local checkout and summarize the findings. `greptile review` diffs the current branch against its base — the repository default, or `-b <base>` — so it needs no PR and no freshly created branch.

## [01]-[CONTEXT]

`git rev-parse --show-toplevel` anchors the run; a failure means the review needs a git repository, reported to the user. On a feature branch or in a worktree, the review runs in place; only work sitting on the base branch with nothing to diff first moves to a branch (or passes `-b`). Uncommitted changes never enter the review — commit them before running.

## [02]-[CLI_PRESENCE]

`command -v greptile` decides. A missing CLI is never installed silently: ask the user, then run `npm i -g greptile`. Without npm, download the vendor installer to a file, inspect it, then execute it — never piped straight to a shell:

```bash copy-safe
curl -fsSL "https://greptile.com/cli/install" -o /tmp/greptile-install.sh
sh /tmp/greptile-install.sh
```

Re-run `command -v greptile` after installation.

## [03]-[AUTH]

`greptile whoami` reports the signed-in account. Missing authentication runs `greptile login` and waits for the user to complete the browser flow; headless environments use `greptile login --api-key` or `GREPTILE_API_KEY`. `greptile logout` clears the session, and `greptile settings set apiBaseUrl` points the CLI at a self-hosted deployment.

## [04]-[RUN]

```bash copy-safe
greptile review --json
```

A usage error on `--json` falls back to `greptile review --agent`. When both fail, the raw failure surfaces with the next action the user needs — never hidden behind a summary.

## [05]-[SUMMARY]

JSON output reports review status, finding count, highest-severity findings first, files needing edits, and the suggested next command or fix path. Plain-text output preserves the same structure. The summary stays concise and actionable.

## [06]-[REPO_CONFIGURATION]

A `.greptile/` directory in any directory of the repository configures reviews for that directory tree; all three files are optional, and a `.greptile/` directory beats a same-directory legacy `greptile.json`.

- [CONFIG]: `config.json` — review settings, run filters, structured rules, cross-repo context.
- [RULES]: `rules.md` — plain markdown review context for the directory tree; severities and rule IDs live only in `config.json` rules.
- [FILES]: `files.json` — `{"files": [{path, description, scope}]}` pointing the reviewer at load-bearing files; references accumulate down the cascade.

### [06.1]-[CONFIG_JSON_FIELDS]

| [INDEX] | [FIELD]                               | [SHAPE_AND_EFFECT]                                                         |
| :-----: | :------------------------------------ | :------------------------------------------------------------------------- |
|  [01]   | `strictness`                          | `1` verbose, `2` default, `3` critical-only                                |
|  [02]   | `commentTypes`                        | Subset of `syntax`, `logic`, `style`, `info`                               |
|  [03]   | `ignorePatterns`                      | Newline-separated gitignore-syntax file patterns                           |
|  [04]   | `labels` / `disabledLabels`           | Glob filters on PR labels gating whether reviews run                       |
|  [05]   | `includeAuthors` / `excludeAuthors`   | Glob filters on PR authors                                                 |
|  [06]   | `includeBranches` / `excludeBranches` | Glob filters on target branches                                            |
|  [07]   | `includeKeywords` / `ignoreKeywords`  | Newline-separated title/description keywords                               |
|  [08]   | `triggerOnUpdates`                    | Re-review when the PR updates                                              |
|  [09]   | `statusCheck`                         | Post a commit status check                                                 |
|  [10]   | `fixWithAI`                           | Append AI-fix prompts to findings                                          |
|  [11]   | `instructions`                        | Free-form reviewer instructions; concatenates down the cascade             |
|  [12]   | `rules`                               | Rows of `{rule, id, severity, scope, enabled}`                             |
|  [13]   | `disabledRules`                       | Inherited rule IDs disabled for this tree                                  |
|  [14]   | `context.repos`                       | `owner/repo` list on the same SCM host, readable with the same credentials |
|  [15]   | Section toggles                       | Section objects, each `{included, collapsible, defaultOpen}`               |

- `rules` fields: severity `low`/`medium`/`high`; `scope` globs relative to the `.greptile/` directory.
- Section toggles: `summarySection`, `issuesTableSection`, `confidenceScoreSection`, `sequenceDiagramSection`.

### [06.2]-[CASCADING]

- Greptile walks from the repository root to each reviewed file and collects every `.greptile/` directory on the path: scalar settings take the most specific value, arrays replace parent arrays, section objects merge field-wise, and rules, file references, and instructions accumulate.
- A child disables an inherited rule by listing its `id` in `disabledRules`; a rule without an `id` cannot be selectively disabled.
- Precedence low to high: dashboard settings, org default rules, root `.greptile/`, intermediate `.greptile/`, most specific `.greptile/`, org enforced rules — enforced rules always apply and cannot be overridden from the repository.

### [06.3]-[SECURITY_REVIEW]

No dedicated security mode or flag exists. Security standards land as high-severity `rules` rows, `rules.md` sections, or org enforced dashboard rules — a security-focused pass is a rules change, not a CLI switch.

## [07]-[CLI_SURFACE]

- [OUTPUT]: `--json` selects machine parsing, `--text`/`--agent` plain text; the remaining render flags route to `greptile review --help`.
- [SESSIONS]: `--resume` continues an interrupted review; `greptile review show [ID]` reopens a finished one; `greptile review status` exits `0` completed, `3` in progress, `4` failed, `5` cancelled.
