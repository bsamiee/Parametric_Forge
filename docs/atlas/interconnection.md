# Interconnection

The estate is a web of single-owner surfaces whose projections fan into many consumers; a change to an owner ripples to every reader that composes it. This map names the load-bearing seams, the `config.forge.*` option hinges, and the estate's reach into machine, services, Rasm, and Maghz. It carries edges and blast radius only — usage lives in each owner's own surface, module boundaries in [README.md](../../README.md).

## [01]-[CONFIG_FORGE_NAMESPACE]

The `options.forge.*` read-only surfaces are the estate's projection hinges: a downstream module reads the resolved value and renders its own artifact, never a private copy of the source data. Each owner declares the matching `options.forge.<name>`; record shapes for the deep ones sit in a note below.

| [INDEX] | [OPTION]                    | [OWNER]                                 | [HINGE_LAW]                                                      |
| :-----: | :-------------------------- | :-------------------------------------- | :--------------------------------------------------------------- |
|  [01]   | `config.forge.theme`        | `modules/home/theme.nix`                | Rename/reshape fails eval for every themed reader.               |
|  [02]   | `config.forge.chords`       | `modules/home/programs/apps/chords.nix` | Key/mod change couples leader and popup bytes.                   |
|  [03]   | `config.forge.ssh.hosts`    | `shell-tools/ssh.nix`                   | A tunnel row fans to supervisors, receipts, acceptance, pickers. |
|  [04]   | `config.forge.ignoreEstate` | `shell-tools/fd.nix`                    | One ignore taxonomy renders for every search/watch consumer.     |
|  [05]   | `config.forge.registers.*`  | `aliases/`, `shell-tools/browsers.nix`  | Register rows project to `forge/registers/*.json` for pickers.   |
|  [06]   | `config.forge.fonts`        | `modules/home/fonts.nix`                | Font identity drives terminal, editor, and glyph render seams.   |
|  [07]   | `config.forge.lsp`          | `modules/home/programs/apps/nvim/`      | Server rows shared across editor surfaces.                       |

- `config.forge.theme` shape: `{ palette, roles, ansi16, syntaxScopes, projections; }`
- `config.forge.chords` shape: `{ layers, modes, karabiner.rules, zellij.{ ... }; }`
- `config.forge.chords` is defined under the darwin-gated `apps/` import: a both-OS consumer reads it only through an `or` default (`browsers.nix` chords register).

## [02]-[THEME_PROJECTION_WEB]

`theme.nix` owns the palette as `mkColor`-lifted rows (uppercase hex plus derived `r g b triple csv rgba`) and the semantic layers built on them: `roles`, `ansi16`, `syntaxScopes`, the tmTheme, and `projections` (`luaPalette`, `blameRamp`, `vscodeTokenRules`). It also writes the external artifacts `forge/theme/palette.json` and `forge/theme/forge-dracula.tmTheme`.

Consumers never restate hex. WezTerm receives `projections.luaPalette` as `wezterm/palette.lua` and maps ANSI in `appearance.lua`; Zellij status rows and the component theme read palette tokens; Yazi points syntect at the owner tmTheme; Neovim writes `forge/palette.lua` and remaps Dracula highlights; VS Code builds terminal ANSI and TextMate settings from the owner and seeds user settings behind a sentinel; bat sources the owner tmTheme and delta reuses the bat cache theme plus the owner `blameRamp`. The extension rule: a tool that needs color reads the resolved option or an owner-emitted artifact — a private palette is the fork the eval-time single owner exists to prevent.

## [03]-[CHORD_PROJECTION_WEB]

`chords.nix` owns the physical layer grammar (Hyper, Super, caps dual-role), the mode table, the bind-row schema, and the render logic that emits `karabiner.rules` and the `zellij.*` KDL fragments. Karabiner reads `karabiner.rules` and writes active `karabiner.json`; Zellij reads `layers`/`modes`, renders hint ribbons from `zellij.ribbon`, and injects generated bind and entry KDL. The Yazi popup runtime reads `zellij.ids.yaziToggle`, and the acceptance harness converts `{key, mods}` to kitty CSI-u bytes. WezTerm reads `config.forge.chords.wezterm.rows` for its native left-Command layer; the rendered `keys.lua` and the chord owner's discoverability rows derive from the same rows.

## [04]-[HOST_CONTEXT_FACTORY]

`hosts/context.nix` mints the per-host row (`name`, `os`, `system`, versions, timeZone, user, ssh, and NixOS disk/network/service-user fields; Darwin rows add `label`). One wrong row shape breaks flake host construction, NixOS static networking, and Home Manager import gates at once. `hosts/default.nix` is the single factory: an OS dispatch row selects the system builder and module set, and one shared per-host module carries platform, identity, and the Home Manager projection for every row — a new machine is one context row. `host.os` is the gate that keeps Darwin-only GUI apps and mac tools off Linux (`modules/home/programs/default.nix`) and drives the static systemd-user-service gates in `ssh.nix` and `scientific-tools.nix`.

## [05]-[TOOLCHAIN_PATH_FACTORY]

`modules/common/toolchain-env.nix` (`forgeToolchainEnvFor`) is the single source of PATH vectors, scientific-env exports, and browser path. Its output is consumed by the shell environment, zsh config, the Darwin GUI launchd env (`darwin/settings/system.nix`), and WezTerm. A bad PATH vector makes shells, launchd agents, and GUI-launched subprocesses resolve different tools — the bug class where a command works in the terminal and fails under a GUI-launched agent. Platform reality for this seam is [platform-facts.md](platform-facts.md).

A sibling context-dispatch seam lives in `languages/python-tools.nix`: `python`, `python3`, `ruff`, `ty`, and `mypy` are project-first shims — inside a project root they exec the project's `.venv` or `uv --project run`, otherwise the system interpreter — so the interpreter a bare `python` binds to is a function of the caller's directory, not a fixed PATH entry. `FORGE_PYTHON_SHIM_BYPASS=1` forces the system interpreter when a shim resolves the wrong environment in a sibling repo.

## [06]-[OWNER_TABLES]

New capability lands as a row on the owning table, never a new file. Each axis has one owner that both installs packages and carries their config.

| [INDEX] | [AXIS]                | [OWNER]                                  | [NEW_CAPABILITY]                                               |
| :-----: | :-------------------- | :--------------------------------------- | :------------------------------------------------------------- |
|  [01]   | Home graph            | `modules/home/default.nix`               | an import under assets/environments/theme/programs/scripts/xdg |
|  [02]   | Program graph         | `modules/home/programs/default.nix`      | a program import; Darwin apps/mac-tools gated by `host.os`     |
|  [03]   | GUI apps              | `modules/home/programs/apps/default.nix` | a karabiner/nvim/vscode/wezterm/yazi/zellij import             |
|  [04]   | Shell, git, and peers | the matching `*/default.nix` roster      | a package row on that axis table                               |
|  [05]   | DB clients            | `languages/db-tools.nix`                 | a wrapped client row                                           |
|  [06]   | MCP fleet             | `shell-tools/mcp-fleet.nix`              | a manifest row                                                 |
|  [07]   | Environment variables | `environments/default.nix`               | a row on the env owner                                         |

- [04]: axis families: shell, git, container, language, media, nix tools
- [05]: client row: Postgres 18 clients, DuckDB, SQLite/SQLean, linters
- [06]: manifest row fields: transport, command/url, env-key names, probe, launcher, Codex fields
- [07]: env owner axes: core, shell, languages, development, apps, containers, media

The MCP manifest is the deepest fan-out: `mcp-launchers.nix` filters launcher rows, serializes fleet JSON, builds pnpm wrappers, and validates Claude/Codex registration drift against `~/.claude.json` and `~/.codex/config.toml` — a manifest row change ripples to wrapper presence, `forge-mcp drift`, and required Codex servers. Secret and token custody for these rows is [secrets-and-services.md](secrets-and-services.md).

## [07]-[RUNTIME_SEAMS]

Beyond eval-time option hinges, five contracts bind processes at runtime across module boundaries; each side is edited only with the other in view.

- [01]-[ATTENTION]: `.claude/hooks/agent-attention.sh` appends JSONL rows (`ts, event, session_id, cwd, term, wezterm_pane, zellij_session, zellij_pane, tty`) that `forge-agents collect` folds and `forge-agents focus` routes; the zjstatus bar renders the collector's `pipe_agents`/`pipe_quota` cells by exact pipe name (`apps/zellij/config.nix`). A field rename, tty-form change, or pipe-name edit on either side severs the chain silently. Budgets ride `FORGE_ATTENTION_{FEED,MAX_ROWS,KEEP_ROWS}`.
- [02]-[RECEIPTS]: every `forge-*` kernel persists TSV receipts to `~/Library/Logs/forge-<name>.receipts.log`, override key `FORGE_<NAME>_RECEIPT_LOG` (grammar minted by the `forge-tools.nix` builder); `forge-receipts` discovers sources from `config.forge.registers.receiptSources` plus `config.forge.ssh.hosts` rows. A new kernel that hand-rolls its receipt path is invisible to the browser.
- [03]-[TERMINAL_MESH]: `apps/chords.nix` bind rows invoke `forge-yazi.sh toggle` (`scripts/terminal.nix`); the yazi opener invokes `forge-edit.sh %s`; the editor registry publishes `editor-tab-*.tsv` rows the dispatcher globs; `forge-terminal-accept.sh` asserts the whole mesh. A rename on any edge is a four-file edit proven by the acceptance run.
- [04]-[XDG_PROJECTIONS]: agent-facing artifacts live at fixed projection paths — `~/.config/forge/registers/*.json` (browsers), `~/.config/forge/theme/palette.json` + `forge-dracula.tmTheme` (theme), `~/.local/state/forge/` (collector state, attention feed), `~/.cache/forge*/` (launcher prefixes). Consumers hardcode these paths by contract; moving one is an estate-wide grep, not a local edit.
- [05]-[QA_HOOKS]: `flake-modules/qa.nix` invokes `fmt --self-test`/`--check` from `scripts/fmt.nix`; treefmt lanes and `fmt` share formatter ownership per extension — a file class both claim gets formatted twice, and a placeholder-bearing template neither may own (`.sql.tpl` scar, [scars.md](scars.md)).

## [08]-[ESTATE_REACH]

The estate does not end at the flake. Four seams cross into other systems, each owned here and detailed in a sibling atlas doc.

- [01]-[MACHINE_MACOS](platform-facts.md): Forge owns launchd grammar, activation classes, deploy locks, container runtime
- [02]-[SECRETS_AND_SERVICES](secrets-and-services.md): Forge owns the Doppler pull rail, `services/` Pulumi topology, GitHub-as-code, tunnels
- [03]-[RAILS_AND_CONTRACTS](rails-and-contracts.md): Forge owns `forge-redeploy`, `forge-provision`, `forge-accept`, drift, the schema-v3 envelope
- [04]-[RASM_MAGHZ](scars.md): Forge owns `nixosConfigurations.maghz`, the `ssh.nix` tunnel substrate, mirrored standards, the machine-tooling boundary

The cross-repo law: Forge is the machine owner. When a shell wrapper, PATH entry, container socket, DB CLI, or scientific build fails in Rasm or Maghz, the fix is the Forge owner, never a patch in the sibling. Rasm owns the method and language-law bedrock Forge composes; Maghz owns its own service plane and `ops-doctrine`. Standards mirror by copy, never by tooling.
