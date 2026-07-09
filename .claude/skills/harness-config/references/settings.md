# [SETTINGS]

Settings are the enforcement and defaults layer: they bind regardless of what the model believes. Scope precedence runs managed, command line, local (`.claude/settings.local.json`), project (`.claude/settings.json`), user (`~/.claude/settings.json`) — arrays merge, scalars override, managed rows are immovable. Files hot-reload except `model` and `outputStyle`.

## [01]-[PERMISSIONS]

Rules are `Tool` or `Tool(specifier)` strings evaluated deny, then ask, then allow — a deny row beats every allow at any scope. The working surface:

- [MODES]: `permissions.defaultMode` sets the session baseline — `default`, `acceptEdits`, `auto` (a background classifier reviews commands), `dontAsk`, `bypassPermissions`, `plan`. `disableBypassPermissionsMode: "disable"` removes the bypass escape hatch at managed scope.
- [TERRITORY]: `permissions.additionalDirectories` extends the writable surface beyond the working directory; sandbox rows under `sandbox.*` bind filesystem, network, and credential reach beneath whatever permissions allow.
- [PROMPT_ECONOMY]: recurring prompts are a config smell — each session's repeated approvals convert into scoped allow rows, and destructive classes into deny rows, so unattended lanes (workflows, background workers, `-p` calls) run without a human at the prompt. Rows stay specifier-scoped; a blanket grant trades every future prompt for the whole tool surface:

  ```json rejected
  { "permissions": { "allow": ["Bash"] } }
  ```

  ```json accepted
  { "permissions": { "allow": ["Bash(pnpm test:*)", "Bash(gh pr view:*)"], "deny": ["Bash(git push --force*:*)"] } }
  ```

## [02]-[MODEL_ROUTING]

`/model` switches mid-session; `--model` and `ANTHROPIC_MODEL` bind one launch; the `model` setting persists. Aliases track the current provider-selected version — a full model name pins one. `opusplan` runs `opus` during plan mode and drops to `sonnet` for execution; `default` clears overrides. `availableModels` plus `enforceAvailableModels` allowlist what any surface resolves to, and `fallbackModel` catches overload. Subagent resolution — `CLAUDE_CODE_SUBAGENT_MODEL`, per-invocation, frontmatter, inherited — lives with agent-dispatch.

## [03]-[EFFORT]

Effort binds adaptive reasoning per session: `low`, `medium`, `high`, `xhigh`, `max`, with availability model-dependent and an unsupported level falling to the highest supported one at or below it. The scale is calibrated per model, so a level name is not comparable across models. Set through `/effort`, `--effort`, the persisted `effortLevel` setting, or `CLAUDE_CODE_EFFORT_LEVEL`. `ultracode` is a harness mode, not a model level: it sends `xhigh` and plans a dynamic workflow for every substantive task, reachable through `/effort ultracode` or `--effort ultracode` but never through the persisted setting or environment variable.

## [04]-[POWER_ROWS]

| [INDEX] | [ROW]                                                                        | [LEVERAGE]                                                                                        |
| :-----: | :--------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------ |
|  [01]   | `env`                                                                        | Environment variables stamped into every session and spawned subprocess                           |
|  [02]   | `skillListingBudgetFraction`, `skillListingMaxDescChars`                     | Context share for skill descriptions; least-invoked descriptions evict first                      |
|  [03]   | `skillOverrides`                                                             | Per-skill visibility: `on`, `name-only`, `user-invocable-only`, `off`                             |
|  [04]   | `outputStyle`                                                                | Swaps the system-prompt register; rebuilt on `/clear` or restart                                  |
|  [05]   | `statusLine`                                                                 | Command-driven status content with refresh interval — live session telemetry                      |
|  [06]   | `plansDirectory`                                                             | Relocates plan files from `~/.claude/plans` into the repository                                   |
|  [07]   | `autoCompactEnabled`, `cleanupPeriodDays`                                    | Compaction trigger and transcript retention                                                       |
|  [08]   | `alwaysThinkingEnabled`                                                      | Extended thinking on for every session; subagents inherit it                                      |
|  [09]   | `teammateMode`                                                               | Agent-team display: `in-process`, `auto`, split panes                                             |
|  [10]   | `workflowSizeGuideline`, `disableWorkflows`, `workflowKeywordTriggerEnabled` | Advisory agent-count target for generated workflows; the off switch; the `ultracode` keyword gate |
|  [11]   | `fileCheckpointingEnabled`                                                   | Pre-edit snapshots powering `/rewind`                                                             |
|  [12]   | `includeGitInstructions`                                                     | Removes built-in commit/PR guidance and the git snapshot when a repo owns its own                 |
|  [13]   | `apiKeyHelper`, `forceLoginMethod`                                           | Credential injection and auth routing for fleet machines                                          |

## [05]-[PLUGINS_AND_MCP]

`enabledPlugins` keys as `plugin@marketplace`; `extraKnownMarketplaces` admits GitHub, git, and directory sources; `strictKnownMarketplaces` and `strictPluginOnlyCustomization` lock fleets to vetted sources. Project MCP servers declare in `.mcp.json` with approval governed by `enableAllProjectMcpServers`, `enabledMcpjsonServers`, and `disabledMcpjsonServers`; managed allow and deny lists (`allowedMcpServers`, `deniedMcpServers`) bind every scope including subagent frontmatter. User and local MCP state lives in `~/.claude.json`, outside the settings files.
