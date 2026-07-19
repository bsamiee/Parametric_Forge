---
name: harness-steering
description: >-
    Owns the persistent behavior surfaces of the Claude Code harness and the placement law
    that picks one: the CLAUDE.md hierarchy, imports, path-scoped rules, the memory
    content law and scored audit, auto memory, settings scopes and precedence,
    permission evaluation, sandbox and auto-mode guardrails, model and effort routing
    (aliases, opusplan, advisor), skill listing budget, statusline, output styles,
    keybindings, plugin marketplaces, LSP plugins, env, plus the headless lanes — print
    and bare mode, session continuation, background sessions, the SDK.
    Use when deciding where an instruction lives (memory file, rule, skill, hook, setting,
    or subagent), auditing or slimming a CLAUDE.md, tuning model, effort, permission, or
    sandbox defaults, diagnosing what loaded into context, or scripting noninteractive
    calls. Mechanical settings.json edits belong to update-config; hook
    construction to hooks-builder; skill bundle authoring to skill-writer; work placement
    across subagents, teams, and workflows to agent-dispatch.
---

# [HARNESS_STEERING]

One instruction, one owner: every durable behavior rides exactly one steering surface, chosen by load timing, scope, authority, and context cost. Memory shapes behavior and hooks and permissions enforce it — an instruction that must never be violated is not prose.

Every Claude Code fact — settings keys, limits, defaults, command and flag surfaces, official values — resolves live through the claudeCodeDocs MCP, never from recall: `mcp__claudeCodeDocs__search_claude_code_docs` for concept queries, `mcp__claudeCodeDocs__query_docs_filesystem_claude_code_docs` for exact pages and key spellings under `/en/*.mdx` (`rg`, `cat`, `tree` against a virtual docs filesystem), and `mcp__claudeCodeDocs__submit_feedback` for doc defects found along the way.

## [01]-[ROUTING]

- [01]-[MEMORY](references/memory.md): memory hierarchy, @path imports, path-scoped rules, auto memory, the memory content law and scored audit
- [02]-[SETTINGS](references/settings.md): scope precedence, permission evaluation, model and effort routing, skill listing budget, interface rows
- [03]-[GUARDRAILS](references/guardrails.md): sandbox schema, auto-mode classifier tuning, managed lockdown rows
- [04]-[HEADLESS](references/headless.md): print mode, structured output, session continuation, background sessions, worktree isolation, SDK boundary
- [05]-[PLUGINS](references/plugins.md): marketplace registration, scope, enablement rows, cache staleness, `.lsp.json` anatomy, LSP lifecycle, traps

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

Memory loads broad to specific — managed policy, user, project, local — and every level is context, never enforcement. Load algorithm, `@path` imports with the four-hop recursion cap, `.claude/rules/` with `paths` scoping, `CLAUDE.local.md`, auto memory limits, exclusion globs, the content law deciding what a memory file may carry, the recall mechanics that decide which one fires, and the scored audit are `memory.md`.

## [04]-[SETTINGS]

Precedence runs managed, command line, local, project, user — scalars replace across scopes while arrays concatenate and deduplicate — and permission rules evaluate deny, ask, allow. Model aliases, effort levels and their per-model floors, the skill listing budget, interface rows (keybindings, statusline, output styles), and the high-leverage rows worth setting deliberately are `settings.md`. Editing mechanics for `settings.json` files belong to update-config; this skill decides which row, which scope, and which value.

## [05]-[GUARDRAILS]

Guardrails bind beneath permissions: `sandbox.*` isolates Bash at the OS level, `autoMode.*` tunes the classifier that adjudicates commands no rule decided, and managed lockdown rows freeze what a fleet's users can re-open. Sandbox schema, classifier rule grammar, and the lockdown census are `guardrails.md`.

## [06]-[HEADLESS]

`claude -p` runs the full harness noninteractively; `--bare` strips discovery for deterministic scripted calls; `--bg` detaches whole sessions; `--agents` and `--agent` define and mount agents at launch. Lane selection, structured output, session continuation and persistence, worktree isolation for background work, cache economics, and the SDK boundary are `headless.md`.

## [07]-[PLUGINS]

Marketplace registration state is global per user and marketplace names are unique — registration and enablement are decoupled surfaces, and a cross-repo plugin set lives once at user scope while projects add rows only for repo-specific plugins. Plugin cache keys on resolved version, making unbumped master edits invisible until an explicit update. Registration mechanics, cache law, `.lsp.json` anatomy, and the LSP trap census are `plugins.md`.

## [08]-[DIAGNOSTICS]

- `/context` shows token allocation across system prompt, tools, memory, skills, and history — the first stop when context is mysteriously full.
- `/memory` lists every loaded memory file and the auto memory directory — the first stop when an instruction is mysteriously absent.
- `InstructionsLoaded` logs which instruction files loaded, when, and why — the deterministic answer for lazy-loaded rules and subdirectory memory.
- `ConfigChange` fires on every settings reload.
- `/doctor` validates installation, settings parse, hook health; `claude --safe-mode` starts with customization disabled to bisect a broken config.
- `/config` surfaces the interactive toggles and sets any key as `/config key=value`; a behavior that survives `--safe-mode` is upstream, not local.

## [09]-[COMPOSITION]

- update-config performs the mechanical `settings.json` and `settings.local.json` edits this skill's decisions call for.
- hooks-builder constructs the hook a steering decision lands on; this skill only rules that a hook is the right surface.
- skill-writer owns bundle anatomy, triggers, and listing economics beyond the budget rows named here.
- agent-dispatch owns where work executes; this skill owns where instructions and defaults persist.
