# [SETTINGS]

Settings are the enforcement and defaults layer: they bind regardless of what the model believes. Scope precedence runs managed, command line, local (`.claude/settings.local.json`), project (`.claude/settings.json`), user (`~/.claude/settings.json`). Merge law follows the value shape: a scalar key takes the narrowest scope's value wholesale, array-valued keys — `permissions.allow`, `sandbox.filesystem.allowWrite`, `claudeMdExcludes` — concatenate and deduplicate across scopes, and per-key maps such as `enabledPlugins` consult each key independently. Two arrays break the merge rule: `fallbackModel` takes the highest-precedence file whole, and `availableModels` replaces only when a managed source defines it. Managed rows are immovable; files hot-reload except `model` and `outputStyle`.

## [01]-[PERMISSIONS]

Rules are `Tool` or `Tool(specifier)` strings evaluated deny, then ask, then allow — a deny row beats every allow at any scope. Working surface:

- [MODES]: `permissions.defaultMode` sets the session baseline — `default` (CLI alias `manual`), `acceptEdits`, `auto` (a background classifier reviews commands; honored only from user or managed scope), `dontAsk`, `bypassPermissions`, `plan`. `disableBypassPermissionsMode: "disable"` removes the bypass escape hatch at managed scope.
- [TERRITORY]: `permissions.additionalDirectories` extends the writable surface beyond the working directory — file access only, never configuration discovery. `Cd` rules bound `/cd`: a bare `Cd` deny disables it, `Cd(<path-pattern>)` blocks matching targets through every symlink spelling. Sandbox rows under `sandbox.*` bind filesystem, network, and credential reach beneath whatever permissions allow — schema in `guardrails.md`.
- [PROMPT_ECONOMY]: recurring prompts are a config smell — each session's repeated approvals convert into scoped allow rows, and destructive classes into deny rows, so unattended lanes (workflows, background workers, `-p` calls) run without a human at the prompt. Rows stay specifier-scoped; a blanket grant trades every future prompt for the whole tool surface:

    ```json rejected
    { "permissions": { "allow": ["Bash"] } }
    ```

    ```json accepted
    { "permissions": { "allow": ["Bash(pnpm test:*)", "Bash(gh pr view:*)"], "deny": ["Bash(git push --force*:*)"] } }
    ```

## [02]-[MODEL_ROUTING]

`/model` switches mid-session; `--model` and `ANTHROPIC_MODEL` bind one launch; the `model` setting persists. Aliases track the current provider-selected version — a full model name pins one, `ANTHROPIC_DEFAULT_OPUS_MODEL` and its per-alias siblings re-point what an alias resolves to, and `modelOverrides` adds or replaces picker rows. `opusplan` runs `opus` during plan mode and drops to `sonnet` for execution; `default` clears overrides. `availableModels` plus `enforceAvailableModels` allowlist what any surface resolves to, and `fallbackModel` catches overload. Two adjacent routing rows: `advisorModel` arms a second-model consult at key task moments (`/advisor`, `--advisor`; subagents inherit it), and `fastMode` trades cost for Opus speed (`/fast`), with `fastModePerSessionOptIn` resetting the choice each session from managed scope. Subagent resolution — `CLAUDE_CODE_SUBAGENT_MODEL`, per-invocation, frontmatter, inherited — lives with agent-dispatch.

## [03]-[EFFORT]

Effort binds adaptive reasoning per session: `low`, `medium`, `high`, `xhigh`, `max`, with availability model-dependent and an unsupported level falling to the highest supported one at or below it. Each model calibrates the scale, so a level name is not comparable across models. Set through `/effort`, `--effort`, the persisted `effortLevel` setting, or `CLAUDE_CODE_EFFORT_LEVEL`. `ultracode` is a harness mode, not a model level: it sends `xhigh` and plans a dynamic workflow for every substantive task, reachable through `/effort ultracode` or `--effort ultracode` but never through the persisted setting or environment variable.

## [04]-[POWER_ROWS]

| [INDEX] | [ROW]                                                    | [LEVERAGE]                                                         |
| :-----: | :------------------------------------------------------- | :----------------------------------------------------------------- |
|  [01]   | `env`                                                    | Env vars stamped into every session and spawned subprocess         |
|  [02]   | `skillListingBudgetFraction`, `skillListingMaxDescChars` | Context share for skill descriptions; least-invoked evict first    |
|  [03]   | `skillOverrides`                                         | Per-skill visibility: `on`/`name-only`/`user-invocable-only`/`off` |
|  [04]   | `outputStyle`                                            | Swaps the system-prompt register; rebuilt on `/clear` or restart   |
|  [05]   | `statusLine`                                             | Command-driven status with refresh interval; live telemetry        |
|  [06]   | `plansDirectory`                                         | Relocates plan files from `~/.claude/plans` into the repository    |
|  [07]   | `autoCompactEnabled`, `cleanupPeriodDays`                | Compaction trigger; retention for sessions, checkpoints, worktrees |
|  [08]   | `alwaysThinkingEnabled`                                  | Extended thinking on for every session; subagents inherit it       |
|  [09]   | `teammateMode`, `teammateDefaultModel`                   | Agent-team display and the teammates' default model                |
|  [10]   | `workflowSizeGuideline`                                  | Advisory agent-count target for generated workflows                |
|  [11]   | `disableWorkflows`                                       | Workflow off switch                                                |
|  [12]   | `workflowKeywordTriggerEnabled`                          | `ultracode` keyword gate                                           |
|  [13]   | `fileCheckpointingEnabled`                               | Pre-edit snapshots powering `/rewind`                              |
|  [14]   | `includeGitInstructions`                                 | Drops commit/PR guidance + git snapshot when repo self-owns        |
|  [15]   | `apiKeyHelper`, `forceLoginMethod`                       | Credential injection and auth routing for fleet machines           |
|  [16]   | `autoUpdatesChannel`                                     | `stable` trails `latest` by a validation window; the version pin   |
|  [17]   | `attribution`                                            | Commit and PR co-author trailers, per surface                      |
|  [18]   | `askUserQuestionTimeout`                                 | Auto-continues an unanswered question after the idle window        |
|  [19]   | `editorMode`, `defaultShell`                             | `vim` input bindings; `bash` or `powershell` behind `!` commands   |
|  [20]   | `preferredNotifChannel`                                  | `terminal_bell` where desktop notifications never arrive           |

## [05]-[PLUGINS_AND_MCP]

`enabledPlugins` keys as `plugin@marketplace`; `extraKnownMarketplaces` admits GitHub, git, and directory sources; `strictKnownMarketplaces` and `strictPluginOnlyCustomization` lock fleets to vetted sources. Registration scope law, the plugin cache, and LSP plugin anatomy are `plugins.md`'s. Project MCP servers declare in `.mcp.json` with approval governed by `enableAllProjectMcpServers`, `enabledMcpjsonServers`, and `disabledMcpjsonServers`; managed allow and deny lists (`allowedMcpServers`, `deniedMcpServers`) bind every scope including subagent frontmatter. User and local MCP state lives in `~/.claude.json`, outside the settings files. Two env rows are the context levers for MCP-heavy estates: `ENABLE_TOOL_SEARCH` defers tool schemas behind ToolSearch instead of loading them all at startup, and `MAX_MCP_OUTPUT_TOKENS` caps a single tool result.

## [06]-[INTERFACE]

- [KEYBINDINGS]: `~/.claude/keybindings.json` (`/keybindings` creates and opens it) carries a `bindings` array of per-context blocks — `Global`, `Chat`, `Autocomplete`, `Confirmation`, and kin — each mapping keystrokes to `namespace:action` values such as `chat:submit`; `null` unbinds, and edits hot-reload without restart.
- [STATUSLINE]: `statusLine` runs a command (`type: "command"`) with `refreshInterval`, `padding`, and `hideVimModeIndicator`, receiving session JSON on stdin and the terminal width in `COLUMNS`; `/statusline` generates a starting script.
- [OUTPUT_STYLES]: custom styles are `.md` files under `~/.claude/output-styles` or `.claude/output-styles` whose frontmatter carries `name`, `description`, and `keep-coding-instructions`; the style replaces the system-prompt register while memory, skills, and settings ride unchanged — set through `outputStyle` or `/config`.
