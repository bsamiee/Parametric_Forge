# [PLUGINS]

The plugin system is one global registry per user with per-scope enablement flags: marketplace registration state lives in `~/.claude/plugins/known_marketplaces.json` regardless of which scope registered it, and a marketplace name is unique per user — a second registration under an existing name silently replaces the first. Registration and enablement are decoupled surfaces: a project may enable a plugin whose marketplace is known only at user scope.

## [01]-[MARKETPLACES]

- Declarative registration rides `extraKnownMarketplaces` in a settings file — an object keyed by marketplace name whose `source` names a `github`, git-URL, or `directory` origin; `autoUpdate: true` on the entry refreshes a local marketplace at session start, and local marketplaces never auto-update without it.
- Imperative registration rides `claude plugin marketplace add <source> [--scope user|project|local]`; `list`, `update [name]`, and `remove` complete the verb set.
- A directory marketplace roots at the folder carrying `.claude-plugin/marketplace.json`; plugin-entry relative sources resolve against that root, and `..` segments are rejected. URL-source marketplaces fetch only the catalog file, so their plugin entries need non-relative sources.
- Reserved names (`claude-plugins-official`, `claude-community`, `anthropic-plugins`) are refused for third-party catalogs.

## [02]-[ENABLEMENT]

- `enabledPlugins` is a flat object of `plugin@marketplace: bool` rows; the key uses the marketplace-entry name, and scopes are consulted per key, not as whole-object overrides.
- A cross-repo plugin carries one enablement row, in user `~/.claude/settings.json`; a project row exists only for a repo-specific plugin. Duplicate same-value rows at project scope are a drift surface, not reinforcement.
- A project-scope enablement whose plugin source is external (github, npm) loads only after explicit `claude plugin install` consent; directory-source plugins carry no consent gate.
- Fleet lockdown rows (`strictKnownMarketplaces`, `blockedMarketplaces`, managed `extraKnownMarketplaces`) bind from managed settings and outrank every user choice.

## [03]-[CACHE_AND_STALENESS]

- Marketplace installs copy plugin content into `~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/`; `${CLAUDE_PLUGIN_ROOT}` resolves to that dir and changes on update, while `${CLAUDE_PLUGIN_DATA}` persists across updates.
- Version resolves first-match: `version` in the plugin's `plugin.json`, `version` in the marketplace entry, the git commit SHA of the plugin source, else `unknown`. The resolved version is the cache key — an unchanged version skips the update, so editing master files without moving the version ships nothing.
- `claude plugin marketplace update <name>` refreshes the catalog and `claude plugin update <plugin>@<marketplace>` re-copies content; `/reload-plugins` re-reads plugins, skills, agents, hooks, and plugin LSP servers in a live session. Superseded cache versions garbage-collect after seven days.
- Live plugin development bypasses the cache with `--plugin-dir <path>` — the directory loads in place for the session and overrides an installed same-name plugin.

## [04]-[LSP_PLUGINS]

`.lsp.json` at the plugin root declares servers as a dictionary keyed by language id. Required per server: `command` (bare PATH name, absolute path, or plugin-relative) and `extensionToLanguage` (dotted extension keys mapping to LSP language ids). Optional: `args`, `transport` (`stdio` default), `env` (merged into the parent environment), `initializationOptions`, `startupTimeout`, `shutdownTimeout`, `restartOnCrash`, `maxRestarts`, `diagnostics` (default `true`; `false` keeps navigation and suppresses post-edit diagnostic injection), and `loggingConfig` (active under `--enable-lsp-logging`).

- The LSP manager reads configs once at session start and spawns a server on the first matching file; servers live for the process, and each process subtree spawns its own instances — heavy servers multiply under agent fleets.
- Marketplace-level `lspServers` blocks load only for the official marketplace; a third-party plugin ships its servers in `.lsp.json`, never in `marketplace.json`.
- Extension claims are first-wins: when two enabled plugins map the same extension, one server runs and the competitor never starts, surfaced only in the `/plugin` interface.
- The `settings` and `workspaceFolder` fields do not reach the server; per-server configuration travels through `args`, `initializationOptions`, and `env`.
- The `LSP` tool is unreachable from subagents; LSP-first navigation belongs to the main loop. The first LSP call in a fresh session can race server startup — retry, never conclude absence.
- No upstream reaper guards servers whose parent died; a stranded language server is litter to kill on sight.

## [05]-[ESTATE]

- `forge-lsp` is the estate's directory marketplace, mastered at Forge `.claude/lsp-marketplace/` — one catalog, eight single-server plugins, commands as bare PATH names riding the Home Manager profile. Sibling repos declare no marketplace and no enablement rows; the user scope owns both.
- The user-scope `forge-lsp` registration carries `autoUpdate: true`, so session starts refresh the catalog; a master edit still lands in running state only after `claude plugin update <plugin>@forge-lsp` (or the next session start) plus `/reload-plugins`.
- `nixd-lsp` is the one machine-coupled plugin: its flake evals route through the `git+file://` scheme against the Forge checkout. Every other plugin is path-portable.
