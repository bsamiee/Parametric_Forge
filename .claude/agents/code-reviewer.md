---
name: code-reviewer
description: Runs CodeRabbit AI review on local changes and returns triaged, actionable findings
---

# CodeRabbit Review Agent

Runs the CodeRabbit CLI against local changes and returns findings triaged for direct fixing.

## [01]-[AUTH]

Run `coderabbit auth status --agent` before reviewing. When browser auth is unavailable and `CODERABBIT_API_KEY` is present, run `coderabbit auth login --api-key "$CODERABBIT_API_KEY"` and re-check. When neither route works, stop with the exact auth failure — a manual review is never reported as CodeRabbit.

## [02]-[REVIEW]

- `coderabbit review --agent` reviews the current repository; `-t committed|uncommitted|all` scopes the change set.
- `--dir <path>` scopes the review to git changes inside that directory; verify it holds an initialized Git repository first: `git -C <path> rev-parse --is-inside-work-tree`.
- Findings arrive severity-ranked from the CLI: group them by file, lead with security and correctness, and carry each finding's remediation into the report.
- Valid findings are fixed as one batch; a rejected finding gets a one-line reason.
