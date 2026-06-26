---
name: ast-grep
description: >-
  Author structural code patterns for the assay `code` rail — ast-grep
  metavariable patterns (`$VAR`, `$$$ARGS`) via `code search` and tree-sitter
  S-expression queries via `code query`. Use when matching code by AST shape
  rather than text, finding call/usage/definition patterns across
  C#/Python/TypeScript, or authoring a structural query before a repo-wide scan.
---

# [H1][AST-GREP]

Structural search is authored for the `assay code` rail, which vendors ast-grep and tree-sitter in-process — never the raw `ast-grep`/`sg` CLI. Every pattern runs through `uv run python -m tools.assay code search|query` and returns the same one-`Envelope`, artifact-backed contract as every other rail. The vendored ast-grep version is pinned in the pnpm catalog (`pnpm-workspace.yaml` `@ast-grep/cli`) and resolved through the lockfile; there is no globally installed CLI to match.

## Routing

| [GOAL]                                                                  | [TOOL]                                                       |
| ----------------------------------------------------------------------- | ------------------------------------------------------------ |
| Single declared-symbol nav (definition, references, hover, callers)     | native LSP ops                                               |
| Literal text occurrence                                                 | `code search --pattern <text>` (routes to ripgrep)           |
| Code by AST shape / metavariables                                       | `code search --pattern '$A.m($$$ARGS)'` (routes to ast-grep) |
| Precise node-kind / field query                                         | `code query --pattern '<tree-sitter S-expr>'`                |
| Symbol in an EXTERNAL compiled artifact (DLL, NuGet, py dist, `*.d.ts`) | `assay api`                                                  |

A literal `--pattern` routes to content search; the moment the pattern contains a `$NAME` metavariable it routes to ast-grep structural matching. Reach for `code` when plain single-symbol navigation is insufficient — arbitrary shapes, predicate-filtered captures, or a structural sweep.

## ast-grep metavariables (`code search`)

- `$NAME` — captures exactly one AST node. Names are UPPERCASE (`$A`, `$RECV`, `$COND`); a lowercase token is matched literally.
- `$$$NAME` — captures zero or more sibling nodes (argument lists, statement sequences, type parameters).
- Reusing a name enforces structural equality: `$A == $A` matches only when both nodes are identical, so `$A.foo($A)` finds self-passing calls.
- The pattern must itself parse as valid code in the target grammar; put a metavariable wherever structure varies. Whitespace and comments are irrelevant — node kind is what matches.
- Grammar is selected by flag: `--csharp | --python | --typescript`.

## tree-sitter queries (`code query`)

For node-kind precision and field constraints, author a tree-sitter S-expression with `@captures` and predicates. Grammar-backed for `--python` and `--typescript`.

- Fields anchor structure: `(call_expression function: (identifier) @fn arguments: (arguments) @args)`.
- Predicates filter captures: `(#eq? @fn "run_check")`, `(#match? @name "^_")`.
- Content prefilter: a single-pattern query whose predicates are *only* `#eq?` and/or `#any-of?` auto-prefilters routed files by literal byte presence (zero false negatives) before any parse, so a literal-anchored sweep skips files that cannot match. Adding a `#match?`/`#not-eq?` predicate, or authoring multiple patterns, disables the prefilter and parses every routed file — prefer literal `#eq?`/`#any-of?` over regex `#match?` for repo-wide scans where a literal anchor exists.

## Discipline

- Author against one known file first, confirm the shape, then widen the path set. AST matching is exact about node kind — a pattern that silently matches nothing is usually a node-kind mismatch, not an absent target.
- Prefer the narrowest metavariable set that still generalizes; over-broad `$$$` swallows unintended siblings.
- Authoring here is read/match only. Structural rewrite and formatter mutation are owned by assay's mutation rail (`static fix`); the native LSP tool is read-only.

## Examples

```bash
# structural: every `<recv>.bar(...)` call in C#
uv run python -m tools.assay code search --pattern '$RECV.bar($$$ARGS)' --csharp src/

# structural: Python except-clause that only re-raises
uv run python -m tools.assay code search --pattern 'try:
    $$$BODY
except $E:
    raise' --python tools/

# tree-sitter: capture every Python function name
uv run python -m tools.assay code query --pattern '(function_definition name: (identifier) @name)' --python tools/

# tree-sitter: TypeScript call expressions to a bare identifier
uv run python -m tools.assay code query --pattern '(call_expression function: (identifier) @fn)' --typescript src/

# literal fallback (routes to ripgrep)
uv run python -m tools.assay code search --pattern run_check --python tools/assay

# NEGATIVE — wrong node kind, silently zero matches (not an error): `?.` parses as a distinct
# conditional-access node, so this skips every plain `recv.bar(...)`. An empty Envelope here means
# shape mismatch, not an absent target — re-author against `$RECV.bar($$$ARGS)`.
uv run python -m tools.assay code search --pattern '$RECV?.bar($$$ARGS)' --csharp src/
```
