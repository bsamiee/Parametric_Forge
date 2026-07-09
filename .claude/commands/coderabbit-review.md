---
description: Run CodeRabbit AI code review on your changes
argument-hint: "[type] [--base <branch>] [--dir <path>]"
allowed-tools: "Bash(coderabbit:*), Bash(cr:*), Bash(git:*)"
---

# CodeRabbit Code Review

Runs an AI-powered code review using the CodeRabbit CLI. Review target: `$ARGUMENTS`.

## [01]-[CONTEXT]

- Current directory: !`pwd`
- Git repo: !`git rev-parse --is-inside-work-tree 2>/dev/null && echo "Yes" || echo "No"`
- Branch: !`git branch --show-current 2>/dev/null || echo "detached HEAD"`
- Has changes: !`git status --porcelain 2>/dev/null | head -1 | grep -q . && echo "Yes" || echo "No"`

## [02]-[PREREQUISITES]

Skip when already verified earlier in this session; otherwise run:

```bash
coderabbit --version 2>/dev/null && coderabbit auth status --agent 2>&1 | head -3
```

- CLI absent: report that the CodeRabbit CLI is not installed, route to <https://www.coderabbit.ai/cli> with a package manager or verified binary, then stop.
- Browser auth unavailable with `CODERABBIT_API_KEY` present: authenticate headlessly, then re-check status.

```bash
coderabbit auth login --api-key "$CODERABBIT_API_KEY"
coderabbit auth status --agent
```

- Neither route works: stop with the exact auth failure — a manual review is never reported as CodeRabbit.

## [03]-[RUN]

```bash
# type defaults to "all"; add --base and --dir only when specified
args=(review --agent -t "${type:-all}")
[ -n "${base:-}" ] && args+=(--base "$base")
[ -n "${dir:-}" ] && args+=(--dir "$dir")
coderabbit "${args[@]}"
```

`type`, `base`, and `dir` come from `$ARGUMENTS`:

- `type`: `all` (default), `committed`, or `uncommitted`.
- `--base <branch>`: only when a base branch is specified.
- `--dir <path>`: only when a review directory is specified; the directory must hold an initialized Git repository — verify first:

```bash
git -C "$dir" rev-parse --is-inside-work-tree
```

## [04]-[RESULTS]

Group findings by severity: Critical (security vulnerabilities, data loss, crashes), Warning (bugs, performance issues, anti-patterns), Info (style, minor improvements). Offer to apply fixes from the `--agent` findings when the output carries actionable remediation detail.
