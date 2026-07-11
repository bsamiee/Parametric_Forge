# [CODEX_META_MANAGEMENT]

Codex carries three configurable surfaces — skills, custom agents, MCP servers — and each answers a different question: a skill changes what the running agent knows, a custom agent changes who executes a delegated subtask, an MCP row changes which external tools exist in the session. Route a change to the surface that owns its question; lane-level MCP selection and approval law stay in the skill root.

## [01]-[SURFACE_MAP]

| [INDEX] | [SURFACE]    | [UNIT]                         | [HOME]                                        | [SELECTED_BY]                          |
| :-----: | :----------- | :----------------------------- | :-------------------------------------------- | :------------------------------------- |
|  [01]   | skill        | directory holding a `SKILL.md` | `~/.agents/skills` (legacy `~/.codex/skills`) | description match or `$skill-name`     |
|  [02]   | custom agent | one TOML file, one agent       | `~/.codex/agents/*.toml`                      | parent prompt by name, or codex by fit |
|  [03]   | MCP server   | one `[mcp_servers.<name>]` row | `~/.codex/config.toml`, fleet-projected       | the model calling its tools mid-turn   |

Doctrine and procedure land as a skill; a delegated worker persona (model, effort, sandbox, instructions) lands as an agent file; external capability lands as an MCP row. A concern spread across two surfaces is a defect — collapse it into the one that owns the question.

## [02]-[SKILLS]

A Codex skill is a directory holding a `SKILL.md` whose frontmatter carries `name` and `description`, with `scripts/`, `references/`, and `assets/` alongside optionally. The format follows the agent-skills open standard, so a Claude-side bundle ports with only frontmatter and routing deltas.

- [NAME]: 64 characters maximum; the qualified plugin-namespaced form caps at 128.
- [DESCRIPTION]: 1024 characters maximum — the hard truncation point, not a style budget.
- [SCAN]: Discovery walks 6 directory levels deep, 2000 skill directories per root; repo skills ride `.agents/skills` in cwd, parents, and repo root; `/etc/codex/skills` is machine-shared; bundled system skills cache at `$CODEX_HOME/skills/.system` and are never edited.
- [TRIGGERS]: Invocation is explicit (`$skill-name`, or `/skills` in the CLI/IDE) or implicit by description match. The skills list rides at most 2% of the model's context window; descriptions shorten first and whole skills drop under pressure — the owned deliverable and primary trigger nouns ride the first clause. The selected skill's full `SKILL.md` always loads regardless of listing truncation.
- [COLLISIONS]: Two skills sharing a `name` do not merge and do not shadow — both list, unlike Claude Code where personal beats project. Symlinked folders resolve to targets. Codex detects skill edits automatically; a missing update means restart.
- [CLAUDE_DELTAS]: `disable-model-invocation`, `user-invocable`, `context: fork`, `allowed-tools`, and dynamic context injection are Claude Code extensions Codex ignores; invocation policy moves to `policy.allow_implicit_invocation` in `agents/openai.yaml`. Upstream-tracking frontmatter and `use_cases.yaml` fixtures drop on port; an estate skill carries `name` and `description` only.
- [ESTATE]: Estate codex skills are ports of the Claude-side Forge masters — same body, Claude-only frontmatter stripped, `agents/openai.yaml` added where app-surface metadata or invocation policy earns it. `~/.agents/skills` is the target root for new ports; the deprecated `~/.codex/skills` root still loads and hosts the standing estate until drained.

`agents/openai.yaml` is the optional Codex-native metadata file — app-surface presentation (`interface.display_name`, icons, `default_prompt`), invocation policy, and the skill's declared tool dependencies:

```yaml template
policy:
    allow_implicit_invocation: false # default true; false leaves only explicit $skill

dependencies:
    tools:
        - type: 'mcp'
          value: 'serverName'
          description: 'What the server provides'
          transport: 'streamable_http'
          url: 'https://example.com/mcp'
```

`[[skills.config]]` rows in `~/.codex/config.toml` disable a skill without deleting it (`path = ".../SKILL.md"`, `enabled = false`); restart applies. The skills-budget warning rides an `item.type=="error"` JSONL event on every run under a large library — disabling unused skills is the relief valve.

## [03]-[AGENTS]

A custom agent file defines a spawnable worker persona: `name`, `description`, and `developer_instructions` are required; `nickname_candidates`, `model`, `model_reasoning_effort`, `sandbox_mode`, `mcp_servers`, and `skills.config` inherit from the parent session when omitted. Codex identifies the agent by its `name` field, never the filename; a custom name matching a built-in (`default`, `worker`, `explorer`) takes precedence.

```toml template
name = "reviewer"
description = "PR reviewer focused on correctness, security, and missing tests."
model = "gpt-5.6-terra"
model_reasoning_effort = "high"
sandbox_mode = "read-only"
developer_instructions = """
Review code like an owner; lead with concrete findings and reproduction steps.
"""
```

- Spawning is prompt-triggered at EVERY effort tier — "spawn the reviewer agent on X" lands a `collab_tool_call` even at medium; effort `ultra` only biases the model to decompose without being asked.
- Globals live under `[agents]` in config: `max_threads` (default 6) caps concurrent threads, `max_depth` (default 1) stops children spawning grandchildren, `job_max_runtime_seconds` defaults the per-worker CSV timeout. Raise `max_depth` never — recursive fan-out turns one broad instruction into unbounded spend.
- The best agents are narrow and opinionated: one job, a tool surface matching it, instructions that refuse adjacent work. Subagents inherit the parent sandbox unless their file overrides it.
- Edits to an agent file apply on the next spawn — running threads keep the definition they started with. A persona no other prompt spawns is deleted, not kept.

## [04]-[MCP_LIFECYCLE]

The fleet manifest is the single source for MCP membership: one manifest row projects the launcher wrapper, both client registrations, and the health probe, and `forge-mcp drift` proves the user-owned registrations (`~/.claude.json`, `~/.codex/config.toml`) mirror the rows. Which servers a LANE spawns and which tools it may CALL headless is the skill root's MCP-selection law — this section owns membership and health only.

- [ADD]: a new server is a new manifest row (plus `codex.toolsApprovalMode = "approve"` only for a pure information-retrieval server), then redeploy, then hand-merge the registration rows drift reports missing — registrations stay user-owned, the manifest is the contract.
- [REMOVE]: delete the manifest row, redeploy, delete the registration rows drift now flags as EXTRA.
- [HEALTH]: `forge-mcp doctor` probes rows, `forge-mcp drift` proves registration parity, `forge-mcp outdated` surfaces stale launcher pins; `codex mcp list --json` is the codex-side registry read.
- [PER_AGENT_WIRING]: a custom agent file may carry its own `[mcp_servers.<name>]` rows — a server only that persona sees — and `[[skills.config]]` rows to blank skills from its context; a skill declares the servers it needs through `dependencies.tools` in `agents/openai.yaml`. Both are wiring, not membership: the fleet manifest still owns what exists machine-wide.

## [05]-[MAINTENANCE]

- A Claude-side skill edit propagates to the codex port by copy from the Forge master; a port that drifts from its master is repaired by re-copy, never by parallel editing.
- Codex surfaces are home-only: a project-local `.codex/` directory is a defect — port load-bearing rows to `~/.codex`, then delete it; checked-in repo skills ride `.agents/skills`, never `.codex/`.
- Config hygiene rides `--strict-config` canaries: an unknown field fails fast there, and steady-state lanes stay unflagged.
- Cleanup is census-driven: `/skills` lists what codex sees, `codex mcp list --json` what it registers, `ls ~/.codex/agents/` what it can spawn — a row in any census with no live consumer is deleted in the same pass that finds it.
