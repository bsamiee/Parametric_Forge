# Interconnection

The estate is a web of single-owner surfaces whose projections fan into many consumers; a change to an owner ripples to every reader that composes it. This map names the load-bearing seams, the `config.forge.*` option hinges, and the estate's reach into machine, services, Rasm, and Maghz. It carries edges and blast radius only — usage lives in each owner's own surface, module boundaries in the repo root router.

The cross-repo law: Forge is the machine owner. When a shell wrapper, PATH entry, container socket, DB CLI, or scientific build fails in Rasm or Maghz, the fix is the Forge owner, never a patch in the sibling. Rasm owns the method and language-law bedrock Forge composes; Maghz owns its own service plane and `ops-doctrine`. Standards mirror by copy, never by tooling.

## [01]-[CONFIG_FORGE_NAMESPACE]

The `options.forge.*` read-only surfaces are the estate's projection hinges: a downstream module reads the resolved value and renders its own artifact, never a private copy of the source data. Each owner declares the matching `options.forge.<name>`; record shapes for the deep ones sit in a note below.

| [INDEX] | [OPTION]                    | [OWNER]                                 | [HINGE_LAW]                                                    |
| :-----: | :-------------------------- | :-------------------------------------- | :------------------------------------------------------------- |
|  [01]   | `config.forge.theme`        | `modules/home/theme.nix`                | Rename/reshape fails eval for every themed reader.             |
|  [02]   | `config.forge.chords`       | `modules/home/programs/apps/chords.nix` | Key/mod change couples leader and popup bytes.                 |
|  [03]   | `config.forge.ssh.*`        | `shell-tools/ssh.nix`                   | A host row fans to supervisors, mounts, receipts, pickers.     |
|  [04]   | `config.forge.ignoreEstate` | `shell-tools/fd.nix`                    | One ignore taxonomy renders for every search/watch consumer.   |
|  [05]   | `config.forge.registers.*`  | `aliases/`, `shell-tools/browsers.nix`  | Register rows project to `forge/registers/*.json` for pickers. |
|  [06]   | `config.forge.fonts`        | `modules/home/fonts.nix`                | Font identity drives terminal, editor, and glyph render seams. |
|  [07]   | `config.forge.lsp`          | `modules/home/programs/apps/nvim/`      | Server rows shared across editor surfaces.                     |

- `config.forge.theme` shape: `{ palette, roles, ansi16, syntaxScopes, projections; }`
- `config.forge.chords` shape: `{ layers, modes, register, nvim.rows, wezterm.rows, vscode.binds, karabiner.rules, zellij.{ ... }; }`
- `config.forge.chords` is defined under the darwin-gated `apps/` import: a both-OS consumer reads it only through an `or` default (`browsers.nix` chords register).
- `config.forge.ssh` shape: `{ hosts.<name>.{ name, user, hostName, aliases, tunnelHost, forwards, mounts }, identityAgent, mountRoot; }` — mount rows carry `{ name, path, readOnly, cache, mountpoint }`; `identityAgent` is the 1Password socket every remote consumer pins, and cache posture sinks only into the rclone `forge-vps-mount` agents (Yazi's SFTP schema has no cache field).
- `config.forge.ssh` mount agents prove liveness continuously and emit `mounted|down|reaped` transitions the receipt registry judges; the workspace picker derives one remote row per (host, mount).

## [02]-[THEME_PROJECTION_WEB]

`theme.nix` owns the palette as `mkColor`-lifted rows (uppercase hex plus derived `r g b triple csv rgba`) and the semantic layers built on them: `roles`, `ansi16`, `syntaxScopes`, the tmTheme, and `projections` (`luaPalette`, `blameRamp`, `vscodeTokenRules`). It also writes the external artifacts `forge/theme/palette.json` and `forge/theme/forge-dracula.tmTheme`.

Consumers never restate hex. WezTerm receives `projections.luaPalette` as `wezterm/palette.lua` and maps ANSI in `appearance.lua`; Zellij status rows and the component theme read palette tokens; Yazi points syntect at the owner tmTheme; Neovim writes `forge/palette.lua` and remaps Dracula highlights; VS Code builds terminal ANSI and TextMate settings from the owner and seeds user settings behind a sentinel; bat sources the owner tmTheme and delta reuses the bat cache theme plus the owner `blameRamp`. The extension rule: a tool that needs color reads the resolved option or an owner-emitted artifact — a private palette is the fork the eval-time single owner exists to prevent.

## [03]-[CHORD_PROJECTION_WEB]

`chords.nix` owns the physical layer grammar (Hyper, Super, caps dual-role), the mode table, the bind-row schema, and the render logic that emits `karabiner.rules` and the `zellij.*` KDL fragments. Karabiner reads `karabiner.rules` and writes active `karabiner.json`; Zellij reads `layers`/`modes`, renders hint ribbons from `zellij.ribbon`, and injects generated bind and entry KDL. The Yazi popup runtime reads `zellij.ids.yaziToggle`, and the acceptance harness converts `{key, mods}` to kitty CSI-u bytes. WezTerm reads `config.forge.chords.wezterm.rows` for its native left-Command layer; the rendered `keys.lua` and the chord owner's discoverability rows derive from the same rows. The VS Code owner reads `config.forge.chords.vscode.binds` and re-lands them as the `forge-keys` sentinel tail of the Default-profile `keybindings.json` on every switch — user rules evaluate bottom-to-top, so the managed tail is the authority position and hand rows above it coexist; `forge-vscode doctor` proves the tail beside the settings sentinel.

## [04]-[HOST_CONTEXT_FACTORY]

`hosts/context.nix` mints the per-host row (`name`, `os`, `system`, versions, timeZone, user, ssh, and NixOS disk/network/service-user fields; Darwin rows add `label`). One wrong row shape breaks flake host construction, NixOS static networking, and Home Manager import gates at once. `hosts/default.nix` is the single factory: an OS dispatch row selects the system builder and module set, and one shared per-host module carries platform, identity, and the Home Manager projection for every row — a new machine is one context row. `host.os` is the gate that keeps Darwin-only GUI apps and mac tools off Linux (`modules/home/programs/default.nix`) and drives the static systemd-user-service gates in `ssh.nix` and `scientific-tools.nix`.

## [05]-[TOOLCHAIN_PATH_FACTORY]

`modules/common/toolchain-env.nix` (`forgeToolchainEnvFor`) is the single source of PATH vectors, scientific-env exports, and browser path. Its output is consumed by the shell environment, zsh config, the Darwin GUI launchd env (`darwin/settings/system.nix`), and WezTerm. A bad PATH vector makes shells, launchd agents, and GUI-launched subprocesses resolve different tools — the bug class where a command works in the terminal and fails under a GUI-launched agent.

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

The MCP manifest is the deepest fan-out: `mcp-launchers.nix` filters launcher rows, serializes fleet JSON, builds pnpm wrappers, reconciles the owned maps in `~/.claude.json` and `~/.codex/config.toml`, joins OAuth credential state into health, and validates registration drift. A manifest row change ripples through switch activation, wrapper presence, both client projections, `forge-mcp doctor`, `forge-mcp drift`, and required Codex servers.

## [07]-[RUNTIME_SEAMS]

Beyond eval-time option hinges, five contracts bind processes at runtime across module boundaries; each side is edited only with the other in view.

- [01]-[RECEIPTS]: every `forge-*` kernel persists TSV receipts to `~/Library/Logs/forge-<name>.receipts.log`, override key `FORGE_<NAME>_RECEIPT_LOG` (grammar minted by the `forge-tools.nix` builder); `forge-receipts` discovers sources from `config.forge.registers.receiptSources` (rows carry `grain` — `kv` TSV or `json` JSONL) plus `config.forge.ssh.hosts` rows. A new kernel that hand-rolls its receipt path is an `--audit` FAIL — invisible to browser and query plane alike.
    - The plane is queryable and live: `--sql`/`--verb` run DuckDB over the normalized event spine, and `--audit` diffs registry rows against on-disk reality and fails on unregistered emitters.
- [02]-[TERMINAL_MESH]: `apps/chords.nix` bind rows invoke `forge-yazi.sh toggle` (`scripts/terminal.nix`); the yazi opener invokes `forge-edit.sh %s`; the editor registry publishes `editor-tab-*.tsv` rows the dispatcher globs; `forge-terminal-accept.sh` asserts the whole mesh. A rename on any edge is a four-file edit proven by the acceptance run.
- [03]-[XDG_PROJECTIONS]: agent-facing artifacts live at fixed projection paths — `~/.config/forge/registers/*.json` (browsers), `~/.config/forge/theme/palette.json` + `forge-dracula.tmTheme` (theme), `~/.config/forge/vscode/roster.json` (extension roster + supersession map), `~/.local/state/forge/` (frozen zellij layout assets), `~/.cache/forge*/` (launcher prefixes). Consumers hardcode these paths by contract; moving one is an estate-wide grep, not a local edit.
- [04]-[QA_HOOKS]: `flake-modules/qa.nix` invokes `fmt --self-test`/`--check` from `scripts/fmt.nix`; treefmt lanes and `fmt` share formatter ownership per extension — a file class both claim gets formatted twice, and a placeholder-bearing template neither may own (the `.sql.tpl` scar).
- [05]-[SESSION_FABRIC]: one workspace row (`wezterm/default.nix`) carries picker entry, zellij session identity, cwd, float policy, and warm posture, and remote rows device-diff their mountpoint before spawning; `forge-terminal-accept.sh` R15/R16 assert both envelopes.
    - `deck.lua session_args` and `forge-workspace` both resolve frozen `~/.local/state/forge/zellij-layouts/<slug>.kdl` assets (`forge-zellij layout record`) before the default layout, and `forge-workspace --json` lifecycle and `forge-zellij state` (schema v2: classification, `serialized_ts`, `last` fabric receipt) parse the same `list-sessions` EXITED text.
