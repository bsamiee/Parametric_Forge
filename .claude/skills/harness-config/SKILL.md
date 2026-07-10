---
name: harness-config
description: >-
    Owns the persistent behavior surfaces of the Claude Code harness and the placement law
    that picks one: the CLAUDE.md memory hierarchy with imports and path-scoped rules, auto
    memory, settings scopes and precedence, permission rule evaluation, model and effort
    routing (aliases, opusplan, subagent overrides), skill listing budget rows,
    statusline, output styles, plugin marketplaces, LSP plugins, env, plus the headless
    lanes — print mode, bare mode, structured output, session continuation, background
    sessions, dynamic agents, and the SDK. Use when deciding where an instruction lives
    (memory file, rule, skill, hook, setting, or subagent), tuning model, effort, or
    permission defaults, diagnosing what loaded into context, scripting Claude Code
    noninteractively, or wiring CI calls.
    Mechanical settings.json edits belong to update-config; hook construction belongs to
    hooks-builder; skill bundle authoring belongs to skill-writer; work placement across
    subagents, teams, and workflows belongs to agent-dispatch.
---

# [HARNESS_CONFIG]

One instruction, one owner: every durable behavior rides exactly one steering surface, chosen by load timing, scope, authority, and context cost. Memory shapes behavior and hooks and permissions enforce it — an instruction that must never be violated is not prose.

## [01]-[ROUTING]

- [01]-[MEMORY](references/memory.md): memory hierarchy, @path imports, path-scoped rules, auto memory limits, exclusion globs
- [02]-[SETTINGS](references/settings.md): settings scopes and precedence, permission evaluation, model and effort routing, skill listing budget
- [03]-[HEADLESS](references/headless.md): print mode, structured output, session continuation, background sessions, SDK boundary
- [04]-[PLUGINS](references/plugins.md): marketplace registration and scope law, enablement rows, plugin cache and staleness, `.lsp.json` anatomy, LSP lifecycle and traps

## [02]-[STEERING]

| [INDEX] | [SURFACE]    | [LOADS]                            | [PLACE_WHEN]                                                               |
| :-----: | :----------- | :--------------------------------- | :------------------------------------------------------------------------- |
|  [01]   | Memory file  | Every session, always in context   | An always-true convention for the machine, project, or operator            |
|  [02]   | Rule         | Launch, or lazily on `paths` match | A convention true only for a subtree or file class                         |
|  [03]   | Skill        | On task-shape selection            | A reusable procedure or deliverable doctrine — skill-writer owns it        |
|  [04]   | Subagent     | On delegation                      | Work whose transcript belongs out of context — agent-dispatch owns it      |
|  [05]   | Hook         | On lifecycle event, deterministic  | A gate that must fire regardless of model judgment — hooks-builder owns it |
|  [06]   | Setting      | Startup and hot-reload             | Enforcement, defaults, and budgets: permissions, model, effort, env        |
|  [07]   | Output style | System prompt, rebuilt on `/clear` | A register change for the whole session, not a task procedure              |

## [03]-[MEMORY]

The hierarchy loads broad to specific — managed policy, user, project, local — and every level is context, never enforcement. Load algorithm, `@path` imports with the four-hop recursion cap, `.claude/rules/` with `paths` scoping, `CLAUDE.local.md`, auto memory limits, and exclusion globs are `memory.md`.

## [04]-[SETTINGS]

Precedence runs managed, command line, local, project, user; permission rules evaluate deny, ask, allow. Model aliases, effort levels and their per-model floors, the skill listing budget, and the high-leverage rows worth setting deliberately are `settings.md`. Editing mechanics for `settings.json` files belong to update-config; this skill decides which row, which scope, and which value.

## [05]-[HEADLESS]

`claude -p` runs the full harness noninteractively; `--bare` strips discovery for deterministic scripted calls; `--bg` detaches whole sessions; `--agents` and `--agent` define and mount agents at launch. Lane selection, structured output, session continuation, cache economics, and the SDK boundary are `headless.md`.

## [06]-[PLUGINS]

Marketplace registration state is global per user and marketplace names are unique — registration and enablement are decoupled surfaces, and a cross-repo plugin set lives once at user scope while projects add rows only for repo-specific plugins. The plugin cache keys on resolved version, making unbumped master edits invisible until an explicit update. Registration mechanics, cache law, `.lsp.json` anatomy, and the LSP trap census are `plugins.md`.

## [07]-[DIAGNOSTICS]

- `/context` shows token allocation across system prompt, tools, memory, skills, and history — the first stop when context is mysteriously full.
- `/memory` lists every loaded memory file and the auto memory directory — the first stop when an instruction is mysteriously absent.
- `/doctor` validates installation, settings parse, and hook health; `claude --safe-mode` starts with all customization disabled to bisect a broken config.
- `/config` surfaces the interactive toggles; a behavior that survives `--safe-mode` is upstream, not local.

## [08]-[COMPOSITION]

- update-config performs the mechanical `settings.json` and `settings.local.json` edits this skill's decisions call for.
- hooks-builder constructs the hook a steering decision lands on; this skill only rules that a hook is the right surface.
- skill-writer owns bundle anatomy, triggers, and listing economics beyond the budget rows named here.
- agent-dispatch owns where work executes; this skill owns where instructions and defaults persist.
