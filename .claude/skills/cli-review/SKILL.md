---
name: cli-review
description: >
  Runs a Greptile CLI review for the current local branch, installing or authenticating the CLI
  when needed, then summarizes JSON findings for the user. Use when the user wants Greptile
  feedback before opening a PR, outside a hosted PR review flow, or directly from a local checkout.
license: MIT
metadata:
  author: greptileai
  version: "1.0"
allowed-tools: Bash(git:*) Bash(greptile:*) Bash(command:*) Bash(curl:*) Bash(npm:*)
---

# CLI Review

Run a Greptile review from the local checkout and summarize the findings.

## Instructions

### 1. Confirm repository context

Start from the current repository root:

```bash
git rev-parse --show-toplevel
```

If the command fails, tell the user that the Greptile CLI review must be run from a git repository.

`greptile review` reviews the current branch against its base — the repository default, or `-b <base>` — so it needs no PR and no freshly created branch. When already on a feature branch or in a worktree, review in place; only when the work sits on the base branch with nothing to diff, commit it to a branch (or pass `-b`) first. Uncommitted changes never enter the review; commit them before running.

### 2. Check for the Greptile CLI

Check whether `greptile` is installed:

```bash
command -v greptile
```

If it is missing, do not install it automatically. Ask the user for permission, then show the recommended install command:

```bash
npm i -g greptile
```

If npm is unavailable, download the vendor installer to a file, inspect it, then execute it — never piped straight to a shell:

```bash
curl -fsSL "https://greptile.com/cli/install" -o /tmp/greptile-install.sh
sh /tmp/greptile-install.sh
```

After installation, re-run `command -v greptile`.

### 3. Ensure authentication

Check the signed-in account:

```bash
greptile whoami
```

If the CLI reports that authentication is missing, run:

```bash
greptile login
```

Wait for the user to complete the login flow before continuing.

### 4. Run the review

Prefer JSON output:

```bash
greptile review --json
```

If JSON output is unsupported or fails with a usage error, fall back to:

```bash
greptile review --agent
```

Do not hide the raw command failure if both commands fail. Summarize the failing command and the next action the user needs to take.

### 5. Summarize results

Parse JSON output when available and report:

- Review status
- Number of findings
- Highest severity findings first
- Files that need edits
- Suggested next command or fix path

When output is plain text, preserve the same structure as much as possible. Keep the summary concise and focused on actionable findings.

## Repository Configuration

A `.greptile/` directory in any directory of the repository configures reviews for that directory tree; all three files are optional, and a `.greptile/` directory beats a same-directory legacy `greptile.json`.

- `config.json`: review settings, run filters, structured rules, cross-repo context.
- `rules.md`: plain markdown review context for the directory tree; severities and rule IDs live only in `config.json` rules.
- `files.json`: `{"files": [{path, description, scope}]}` pointing the reviewer at load-bearing files; references accumulate down the cascade.

### config.json Fields

| Field | Shape and effect |
| --- | --- |
| `strictness` | `1` verbose, `2` default, `3` critical-only |
| `commentTypes` | subset of `syntax`, `logic`, `style`, `info` |
| `ignorePatterns` | newline-separated gitignore-syntax file patterns |
| `labels` / `disabledLabels` | glob filters on PR labels gating whether reviews run |
| `includeAuthors` / `excludeAuthors` | glob filters on PR authors |
| `includeBranches` / `excludeBranches` | glob filters on target branches |
| `includeKeywords` / `ignoreKeywords` | newline-separated title/description keywords |
| `triggerOnUpdates` | re-review when the PR updates |
| `statusCheck` | post a commit status check |
| `fixWithAI` | append AI-fix prompts to findings |
| `instructions` | free-form reviewer instructions; concatenates down the cascade |
| `rules` | rows of `{rule, id, severity, scope, enabled}`; severity is `low`, `medium`, or `high`; `scope` globs are relative to the `.greptile/` directory |
| `disabledRules` | inherited rule IDs disabled for this tree |
| `context.repos` | `owner/repo` list on the same SCM host, readable with the same credentials |
| section toggles | `summarySection`, `issuesTableSection`, `confidenceScoreSection`, `sequenceDiagramSection`, each `{included, collapsible, defaultOpen}` |

### Cascading

- Greptile walks from the repository root to each reviewed file and collects every `.greptile/` directory on the path: scalar settings take the most specific value, arrays replace parent arrays, section objects merge field-wise, and rules, file references, and instructions accumulate.
- A child disables an inherited rule by listing its `id` in `disabledRules`; a rule without an `id` cannot be selectively disabled.
- Precedence low to high: dashboard settings, org default rules, root `.greptile/`, intermediate `.greptile/`, most specific `.greptile/`, org enforced rules — enforced rules always apply and cannot be overridden from the repository.

### Security Review

No dedicated security mode or flag exists. Security standards are encoded as high-severity `rules` rows, `rules.md` sections, or org enforced dashboard rules, so a security-focused pass is a rules change, not a CLI switch.

### CLI Surface

- Review: `greptile review` compares the current branch to the repository default branch; `-b <base>` overrides the base.
- Output: `--json` for machine parsing, `--text` (alias `--agent`) for plain text, `--diff` for inline diffs, `--context <lines>` for surrounding context, `--width`, `--no-color`.
- Sessions: `--resume` continues an interrupted review; `greptile review show [ID]` reopens a finished one; `greptile review status` exits `0` completed, `3` in progress, `4` failed, `5` cancelled.
- Auth: `greptile login` (browser), `greptile login --api-key` or `GREPTILE_API_KEY` (headless), `greptile whoami`, `greptile logout`, `greptile settings set apiBaseUrl` for self-hosted deployments.
