# [MEMORY]

Memory is the always-loaded instruction layer: operator-authored files plus model-authored auto memory, delivered as context after the system prompt. It shapes behavior without enforcing it — a rule that must hold under pressure moves to permissions or a hook.

## [01]-[HIERARCHY]

| [INDEX] | [LEVEL] | [LOCATION]                         | [SCOPE]                            |
| :-----: | :------ | :--------------------------------- | :--------------------------------- |
|  [01]   | Managed | OS-level managed path              | Organization-wide non-excludable   |
|  [02]   | User    | `~/.claude/CLAUDE.md`              | Every project on the machine       |
|  [03]   | Project | `CLAUDE.md` or `.claude/CLAUDE.md` | Everyone who clones the repository |
|  [04]   | Local   | `CLAUDE.local.md`                  | Gitignored to this checkout        |

The loader walks upward from the working directory, orders discovered files root to working directory, and appends `CLAUDE.local.md` after its sibling `CLAUDE.md` at each level. Subdirectory memory files lazy-load when work touches files beneath them, so folder conventions live beside the folders they govern instead of bloating the root. Target under 200 lines per file — adherence degrades as memory grows, and overflow moves to path-scoped rules. `claudeMdExcludes` skips matching memory files by glob at any settings scope.

## [02]-[IMPORTS]

`@path/to/file` inside a memory file expands the target into context at launch; relative paths resolve against the importing file, imports recurse to a depth of four hops, and code spans plus fenced blocks are skipped — backticks around a path keep it literal. A repository standardized on `AGENTS.md` bridges with a one-line `CLAUDE.md` containing `@AGENTS.md`. Imports pointing outside the project trigger a one-time approval dialog; a declined import stays dormant. A gitignored local file shared across worktrees is an import of an absolute path, since `CLAUDE.local.md` exists only in the worktree that created it.

## [03]-[RULES]

`.claude/rules/**/*.md` and `~/.claude/rules/**/*.md` modularize instructions one topic per file. A rule without `paths` frontmatter loads at launch with project-memory priority; a rule with `paths` globs loads only when work touches matching files — the trigger is the path predicate, no description competes and no session pays for an unused convention. User rules load before project rules. The split with skills is convention versus procedure: a rule states what is always true of a subtree, a skill packages how a task is done.

## [04]-[AUTO_MEMORY]

Auto memory is model-authored learning, on by default, stored per project at `~/.claude/projects/<project>/memory/` — derived from the git repository, so every worktree shares one store. `MEMORY.md` is the index, its first 200 lines or 25KB loading at session start; topic files load on demand when referenced. Toggle through `/memory`, `autoMemoryEnabled`, or `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1`; relocate with `autoMemoryDirectory`. The store is machine-local. Curation is real work: stale notes mislead future sessions with the same authority as fresh ones, and a hardened lesson graduates from auto memory into an operator-authored file or skill.

## [05]-[BOUNDARY]

Every memory level is advisory context delivered as a user message after the system prompt — the model weighs it, and under long-context pressure adherence decays. Blocking a tool, protecting a path, or gating a completion is settings and hooks territory: `permissions.deny` rows block deterministically, lifecycle hooks veto with exit code 2, and neither depends on the model remembering anything. The placement test for any candidate instruction: if violation is acceptable-but-unwanted it rides memory, if violation is unacceptable it rides enforcement.

```markdown rejected
NEVER run `terraform destroy` or force-push to main. Always be careful with destructive commands.
```

```json accepted
{ "permissions": { "deny": ["Bash(terraform destroy:*)", "Bash(git push --force*:*)"] } }
```

## [06]-[SUBAGENT_MEMORY]

Subagents load the full memory hierarchy at spawn (Explore and Plan skip it), and a definition with a `memory` field maintains its own persistent directory under the same 200-line/25KB index law. Worker-side memory mechanics live with agent-dispatch; the placement ruling — which learnings belong to a specialist versus the shared project store — lands here: knowledge only one worker uses stays in that worker's memory, knowledge every session needs rides the project hierarchy.
