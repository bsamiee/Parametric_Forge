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
    Authoring runnable workflow scripts belongs to workflow-creator; gpt-5.6 offload belongs
    to the codex skill; harness configuration belongs to harness-config.
---

# [AGENT_DISPATCH]

Dispatch is three decisions taken in order: placement — which execution surface holds the work; contract — what the worker receives and what it returns; topology — how many workers run and how their results flow back.

## [01]-[ROUTING]

- [01]-[SURFACES](references/surfaces.md): per-surface mechanics and runtime — background permission surfacing, `SendMessage` resume guards, and transcript persistence.
- [02]-[PROMPTING](references/prompting.md): the delegation contract — startup context, contract fields, receipt discipline, and meta-delegation prompts.
- [03]-[TOPOLOGIES](references/topologies.md): result-flow shape mechanics, the file-ownership law, and stop-condition law.

## [02]-[PLACEMENT]

| [INDEX] | [SURFACE]          | [CONTEXT]                                  | [SELECT_WHEN]                                                         |
| :-----: | :----------------- | :----------------------------------------- | :-------------------------------------------------------------------- |
|  [01]   | Main turn          | Full history, full tools                   | Iterative back-and-forth, phases share context, targeted change       |
|  [02]   | `/btw`             | Full history, no tools, answer discarded   | A side question about material already in the conversation            |
|  [03]   | Fork               | Inherits history + system prompt + cache   | Side task needing accumulated context; parallel takes on a base       |
|  [04]   | Subagent           | Fresh: own prompt, memory, git snapshot    | Noisy or verbose work whose transcript stays out of the parent        |
|  [05]   | Nested subagent    | Fresh, spawned by a worker                 | A delegated task that itself splits; grandchild noise stays hidden    |
|  [06]   | Agent team         | Independent peer sessions, tasks, mailbox  | Workers must trade findings, challenge, self-claim tasks              |
|  [07]   | Dynamic workflow   | Script vars hold every intermediate result | Dozens to hundreds of agents, codified reruns, bounded loops          |
|  [08]   | Codex offload      | Separate model + context, one report       | Transcript-heavy mechanical or research legs — codex skill owns these |
|  [09]   | Machine automation | No agent; launchd, mise, webhook rows      | Recurring, watch-shaped, or event work with no per-firing judgment    |

Placement law rides four axes: cost rises down the table, so the cheapest surface that isolates the noise wins; a fork beats a fresh subagent when the worker needs the conversation so far, because the fork reuses the parent prompt cache; a team beats parallel subagents only when workers must communicate, since each teammate is a full session priced accordingly; a workflow beats a team when the plan is codifiable and the intermediates belong in script variables instead of any context window.

The law is hierarchy-independent: every agent at every depth — main loop, subagent, workflow agent, offloaded session — applies the same placement economics and the same model mixture. Writing and judgment run at capable tiers, recon and mechanical legs offload to the workhorse lineage, an independent perspective comes from an external lineage — codex for workhorse second reads, agy for Gemini judgment and visual legs — rather than a second reviewer of the same one, and no agent escalates its own model tier beyond its brief. The active repo's model table prices the tiers; the codex and agy skills own their legs once this law picks one.

## [03]-[CONTRACT]

A non-fork worker sees none of the parent conversation — no prior reads, no invoked skills, no history — so every delegation prompt is decision-complete: objective, territory, exclusions, output contract, and success criteria, with no reliance on mid-run clarification since `AskUserQuestion` is withheld from subagents.

COMMIT DISCIPLINE is a contract field, not an afterthought: a worker that writes to a repo commits each completed unit in scoped, signed commits as it lands — explicit pathspecs, `[scope]: action`, `git status` before staging so a concurrent worker's hunks stay frozen, never `git add -A`/`-u`. A worker that dies mid-run — API drop, kill, context exhaustion — then loses only its uncommitted tail; committed work survives, and the receipt's commit hashes hand the orchestrator or a successor the trail to resume from. The trail RECORDS progress; it never DECIDES work — a successor reads the current tree to know what remains, never the changelog.

ROOT DISCIPLINE is a contract field beside commit discipline: a worker resolves every defect it touches at the cause, not the symptom, and a quirk it notices beyond its stated territory is fixed in the same run — never deferred to a later pass, never annotated as another worker's scope. A defect genuinely beyond reach — a contended file, a locked seam, an absent credential — travels back in the receipt as an explicit unreachable naming the owner that closes it, never a silent residual a successor must rediscover. A worker that leaves a known defect unfixed because it sits outside the brief has broken the contract.

## [04]-[TOPOLOGY]

Result flow is chosen before the first spawn: star for independent fan-out with one consolidator, pipeline for staged transforms with artifact contracts, panel for adversarial judgment, tournament for best-of-N with blind comparison, loop for repeat-until-verified.

## [05]-[DEPTH]

Subagents spawn subagents to a fixed ceiling of five levels below the main conversation; at the floor the Agent tool is withheld, and a background worker's depth is pinned at spawn — resuming it from a shallower context restores no headroom. Depth is spent to shed noise, never for parallelism theater: a worker earns the Agent tool only when its own task splits, and its prompt then carries an explicit split policy — what each child owns, what returns, and the remaining depth budget. A fork spawns named subagents but never another fork.

Depth ledgers are per-lineage: the five-level ceiling meters Claude spawning Claude only — an offload to the other lineage spends no Claude depth, and that lineage's own spawn bound is its skill's law (codex).

## [06]-[RUNTIME]

Workers run in the background by default and drop to the foreground only when the result gates the next step. Background permission prompts surface in the main session named by requester; approval releases one call, Esc denies that call without killing the worker. Stopped workers resume through `SendMessage` with full history intact; an API-error death returns the worker's last output rather than losing the run.

## [07]-[COMPOSITION]

- Runnable workflow scripts — the `meta` block, `agent()`, `pipeline()`, schemas — belong to workflow-creator; this skill decides when a workflow is the right surface and how its agents are prompted.
- Offload to gpt-5.6 (terra workhorse, sol flagship) through the `codex` MCP tool or `codex exec` belongs to the codex skill; this skill's placement table names the trigger.
- Hook construction for `SubagentStart`, `SubagentStop`, `TeammateIdle`, and task gates belongs to hooks-builder; this skill names where a gate pays for itself.
- Recurring machine work — launchd rows, `mise` task and watch surfaces, the signed webhook inbox — belongs to the estate machine owner; the placement table names when work leaves agent surfaces entirely.
- Memory files, rules, settings, model and effort defaults, and headless lanes belong to harness-config; a subagent definition's frontmatter stays here.
- A delegation smell, orchestration error, or superior pattern surfaced mid-run is codified into its owning skill — codex for offload mechanics, workflow-creator for script shapes, this skill for placement and contract law, harness-config for settings and hooks — in the same session, then propagated byte-identical to every project, reviewer configs included; a lesson left as session knowledge is a regression.
