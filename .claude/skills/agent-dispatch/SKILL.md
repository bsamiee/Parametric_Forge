---
name: agent-dispatch
description: >-
  Owns work placement and delegation craft across Claude Code's execution surfaces — main
  turn, `/btw`, fork, subagent, background task, nested subagent, agent team, dynamic
  workflow — with the selection economics that pick one, the delegation contract that makes
  a worker prompt self-contained (objective, territory, output contract, receipt), the
  communication topologies (star, pipeline, panel, tournament, loop), depth budgeting for
  meta-delegation, and the runtime mechanics of background permission surfacing,
  `SendMessage` resume, and persistent worker memory. Use when parallelizing work,
  delegating a task to a subagent or teammate, choosing between a subagent, fork, team, or
  workflow, writing a `.claude/agents/` definition, designing a fan-out or review pipeline,
  or when a delegation stalls, over-prompts for permission, or returns weak results.
  Authoring runnable workflow scripts belongs to workflow-creator; gpt-5.5 offload belongs
  to the codex skill; harness configuration belongs to harness-config.
---

# [AGENT_DISPATCH]

Dispatch is three decisions taken in order: placement — which execution surface holds the work; contract — what the worker receives and what it returns; topology — how many workers run and how their results flow back. Per-surface mechanics are [references/surfaces.md](references/surfaces.md); the delegation contract is [references/prompting.md](references/prompting.md); result-flow shapes and loop law are [references/topologies.md](references/topologies.md).

## [01]-[PLACEMENT]

| [INDEX] | [SURFACE]        | [CONTEXT]                                         | [SELECT_WHEN]                                                              |
| :-----: | :--------------- | :------------------------------------------------ | :------------------------------------------------------------------------- |
|  [01]   | Main turn        | Full history, full tools                          | Iterative back-and-forth, phases sharing context, quick targeted change    |
|  [02]   | `/btw`           | Full history, no tools, answer discarded          | A side question about material already in the conversation                 |
|  [03]   | Fork             | Inherits history, system prompt, and prompt cache | A side task that needs the accumulated context; parallel takes on one base |
|  [04]   | Subagent         | Fresh: own prompt, memory hierarchy, git snapshot | Noisy or verbose work whose transcript must stay out of the parent         |
|  [05]   | Nested subagent  | Fresh, spawned by a worker                        | A delegated task that itself splits; grandchild noise never surfaces       |
|  [06]   | Agent team       | Independent peer sessions, shared tasks, mailbox  | Workers must trade findings, challenge each other, self-claim tasks        |
|  [07]   | Dynamic workflow | Script variables hold every intermediate result   | Dozens to hundreds of agents, codified reruns, bounded loops               |
|  [08]   | Codex offload    | Separate model and context, one report returns    | Transcript-heavy mechanical or research legs — the codex skill owns these  |

Placement law rides four axes: cost rises down the table, so the cheapest surface that isolates the noise wins; a fork beats a fresh subagent when the worker needs the conversation so far, because the fork reuses the parent prompt cache; a team beats parallel subagents only when workers must communicate, since each teammate is a full session priced accordingly; a workflow beats a team when the plan is codifiable and the intermediates belong in script variables instead of any context window.

## [02]-[CONTRACT]

A non-fork worker sees none of the parent conversation — no prior reads, no invoked skills, no history — so every delegation prompt is decision-complete: objective, territory, exclusions, output contract, and success criteria, with no reliance on mid-run clarification since `AskUserQuestion` is withheld from subagents. Startup context, contract fields, receipt discipline, and meta-delegation prompts are [references/prompting.md](references/prompting.md).

COMMIT DISCIPLINE is a contract field, not an afterthought: a worker that writes to a repo commits each completed unit in scoped, signed commits as it lands — explicit pathspecs, `[scope]: action`, `git status` before staging so a concurrent worker's hunks stay frozen, never `git add -A`/`-u`. A worker that dies mid-run — API drop, kill, context exhaustion — then loses only its uncommitted tail; committed work survives, and the receipt's commit hashes hand the orchestrator or a successor the trail to resume from. The trail RECORDS progress; it never DECIDES work — a successor reads the current tree to know what remains, never the changelog.

## [03]-[TOPOLOGY]

Result flow is chosen before the first spawn: star for independent fan-out with one consolidator, pipeline for staged transforms with artifact contracts, panel for adversarial judgment, tournament for best-of-N with blind comparison, loop for repeat-until-verified. Shape mechanics, the file-ownership law, and stop-condition law are [references/topologies.md](references/topologies.md).

## [04]-[DEPTH]

Subagents spawn subagents to a fixed ceiling of five levels below the main conversation; at the floor the Agent tool is withheld, and a background worker's depth is pinned at spawn — resuming it from a shallower context restores no headroom. Depth is spent to shed noise, never for parallelism theater: a worker earns the Agent tool only when its own task splits, and its prompt then carries an explicit split policy — what each child owns, what returns, and the remaining depth budget. A fork spawns named subagents but never another fork.

## [05]-[RUNTIME]

Workers run in the background by default and drop to the foreground only when the result gates the next step. Background permission prompts surface in the main session named by requester; approval releases one call, Esc denies that call without killing the worker. Stopped workers resume through `SendMessage` with full history intact; an API-error death returns the worker's last output rather than losing the run. Runtime mechanics, resume guards, and transcript persistence are [references/surfaces.md](references/surfaces.md).

## [06]-[COMPOSITION]

- Runnable workflow scripts — the `meta` block, `agent()`, `pipeline()`, schemas — belong to workflow-creator; this skill decides when a workflow is the right surface and how its agents are prompted.
- Offload to gpt-5.5 through `codex exec` belongs to the codex skill; this skill's placement table names the trigger.
- Hook construction for `SubagentStart`, `SubagentStop`, `TeammateIdle`, and task gates belongs to hooks-builder; this skill names where a gate pays for itself.
- Memory files, rules, settings, model and effort defaults, and headless lanes belong to harness-config; a subagent definition's frontmatter stays here.
