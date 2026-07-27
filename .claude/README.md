# Claude Workspace Setup

## [01]-[SESSION_START]

`settings.json` runs `hooks/setup-env.sh` on startup, resume, and compaction in two lanes: a warm session replays the mode-600 session cache into `CLAUDE_ENV_FILE` instantly and dispatches a detached `--refresh`; the refresh lane (or a cold first boot, inline) resolves each `DOPPLER_SOURCES` row independently — a live Doppler fetch refreshes its encrypted snapshot under the doppler cache, a failed fetch serves the snapshot, and a dead row reports loudly with owed key names only. Resolved keys and optional PATH additions land in `CLAUDE_ENV_FILE` for sub-agent/tool inheritance; the hook never sources local shell files, installs tools, or writes profiles.

[VARIABLES]:
- `CLAUDE_ENV_EXPORT_KEYS` - Extra env var names to persist, separated by spaces or commas.
- `CLAUDE_TOOL_PATHS` - Colon-separated PATH entries to prepend when directories exist.
- `CLAUDE_ALLOW_MISSING_TOOL_PATHS=1` - Preserve explicit PATH entries even when the directory is absent.
- `CLAUDE_DOPPLER_OFFLINE=1` - Force fallback-only fetches (snapshots serve, no network).

## [02]-[BOUNDARIES]

[CRITICAL]:
- [ALWAYS]: Keep startup deterministic; the only startup mutations are the hook-owned doppler snapshot and session caches.
- [ALWAYS]: Route machine tooling through the Parametric_Forge owner; no repo script installs tools, writes profiles, or mutates the host.
- [NEVER]: Source local shell files during startup.
- [NEVER]: wire host bootstrap into `SessionStart`.

## [03]-[WORKSPACE]

- `scratch/<slug>/` homes campaign artifacts, one folder per campaign; the session scratchpad carries only throwaway files.
- `workflows/*.js` mix `export const meta` with top-level `await`/`return` — a dialect no Biome mode parses; formatters never touch them.
- `scripts/bootstrap-cli-tools.sh` provisions CLI tools on non-Forge hosts; default `check` reports, `apply` mutates via `CLAUDE_BOOTSTRAP_*` gates.

## [04]-[SKILL_FRONTMATTER]

`SKILL.md` frontmatter accepts the following optional fields; `description` carries the automatic-selection signal.

| [INDEX] | [SKILL_FIELD]              | [CONTRACT]                                                                                             |
| :-----: | :------------------------- | :----------------------------------------------------------------------------------------------------- |
|  [01]   | `name`                     | Display label; a project skill's directory still sets its command name.                                |
|  [02]   | `description`              | Capability and primary invocation trigger; the first Markdown paragraph supplies the omitted fallback. |
|  [03]   | `when_to_use`              | Additional invocation triggers appended to `description` within their 1,536-character listing cap.     |
|  [04]   | `argument-hint`            | Autocomplete hint for the expected argument shape.                                                     |
|  [05]   | `arguments`                | Ordered names for positional `$name` substitutions; accepts a space-separated string or YAML list.     |
|  [06]   | `disable-model-invocation` | Manual invocation only; suppresses automatic loading, subagent preloading, and scheduled invocation.   |
|  [07]   | `user-invocable`           | `false` hides the skill from the `/` menu while preserving model invocation.                           |
|  [08]   | `allowed-tools`            | One-turn tool pre-approval; accepts a space- or comma-separated string or YAML list.                   |
|  [09]   | `disallowed-tools`         | One-turn tool removal; accepts a space- or comma-separated string or YAML list.                        |
|  [10]   | `model`                    | Turn-local `/model` value or `inherit`; organization allowlists retain authority.                      |
|  [11]   | `effort`                   | Model-dependent `low`, `medium`, `high`, `xhigh`, or `max` override.                                   |
|  [12]   | `context`                  | `fork` runs the skill in an isolated subagent context.                                                 |
|  [13]   | `agent`                    | Subagent type selected only with `context: fork`.                                                      |
|  [14]   | `background`               | Fork-only execution mode; `true` runs asynchronously and `false` waits for the result.                 |
|  [15]   | `hooks`                    | Skill-lifecycle hook map using the shared hooks configuration shape.                                   |
|  [16]   | `paths`                    | Automatic-activation globs; accepts a comma-separated string or YAML list.                             |
|  [17]   | `shell`                    | Dynamic-context shell: `bash` by default or `powershell`.                                              |

- Boolean fields accept `true`/`false`, `yes`/`no`, `on`/`off`, or `1`/`0`, case-insensitively.

## [05]-[SUBAGENT_FRONTMATTER]

`.claude/agents/*.md` frontmatter requires `name` and `description`; every other field is optional.

| [INDEX] | [SUBAGENT_FIELD]  | [CONTRACT]                                                                                                |
| :-----: | :---------------- | :-------------------------------------------------------------------------------------------------------- |
|  [01]   | `name`            | Lowercase hyphenated identifier exposed to hooks as `agent_type`; the filename may differ.                |
|  [02]   | `description`     | Delegation trigger Claude uses to select the subagent.                                                    |
|  [03]   | `tools`           | Available tool set; omission inherits every tool available to subagents.                                  |
|  [04]   | `disallowedTools` | Tool deny set removed from the inherited or explicit `tools` set.                                         |
|  [05]   | `model`           | `sonnet`, `opus`, `haiku`, `fable`, a full model ID, or `inherit`; default `inherit`.                     |
|  [06]   | `permissionMode`  | `default`, `manual`, `acceptEdits`, `auto`, `dontAsk`, `bypassPermissions`, or `plan`; plugins ignore it. |
|  [07]   | `maxTurns`        | Maximum agentic turns before the subagent stops.                                                          |
|  [08]   | `skills`          | Skill names whose full content preloads at startup; unlisted skills remain invocable.                     |
|  [09]   | `mcpServers`      | Configured server names or inline definitions; plugin subagents ignore it.                                |
|  [10]   | `hooks`           | Subagent-lifecycle hook map; plugin subagents ignore it.                                                  |
|  [11]   | `memory`          | Persistent-memory scope: `user`, `project`, or `local`.                                                   |
|  [12]   | `background`      | `true` forces background execution; omission lets Claude select the execution mode.                       |
|  [13]   | `effort`          | Model-dependent `low`, `medium`, `high`, `xhigh`, or `max` override.                                      |
|  [14]   | `isolation`       | `worktree` runs the subagent in a temporary Git worktree.                                                 |
|  [15]   | `color`           | Task-list color: `red`, `blue`, `green`, `yellow`, `purple`, `orange`, `pink`, or `cyan`.                 |
|  [16]   | `initialPrompt`   | First user turn when the definition runs as the main agent; prepends any supplied prompt.                 |

## [06]-[SKILL_SUBAGENT_DISTINCTIONS]

Skill and subagent frontmatter separate permission, denial, and composition semantics:
- Skill `allowed-tools` grants one-turn permission without narrowing the available tool pool.
- Subagent `tools` defines the available set and inherits every subagent tool when omitted.
- Skill `disallowed-tools` uses kebab-case.
- Subagent `disallowedTools` uses camelCase.
- Skill `agent` belongs to the skill schema and selects the subagent type executing `context: fork`.
- Subagent `skills` preloads full skill bodies into startup context.
