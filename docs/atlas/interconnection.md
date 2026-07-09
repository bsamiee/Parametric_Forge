# Interconnection

The estate is a web of single-owner surfaces whose projections fan into many consumers; a change to an owner ripples to every reader that composes it. This map names the load-bearing seams, the `config.forge.*` option hinges, and the estate's reach into machine, services, Rasm, and Maghz. It carries edges and blast radius only — usage lives in each owner's own surface, module boundaries in [README.md](../../README.md).

## [01]-[CONFIG_FORGE_NAMESPACE]

Two read-only option surfaces are the estate's projection hinges: a downstream module reads the resolved value and renders its own artifact, never a private copy of the source data.

| [INDEX] | [OPTION]              | [OWNER]                                                          | [SHAPE]                                                  | [HINGE_LAW]                                                                                                                                                                                      |
| :-----: | :-------------------- | :--------------------------------------------------------------- | :------------------------------------------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|  [01]   | `config.forge.theme`  | `modules/home/theme.nix` (`options.forge.theme`)                 | `{ palette, roles, ansi16, syntaxScopes, projections; }` | A token rename or shape change fails Nix eval across every themed reader at once.         |
|  [02]   | `config.forge.chords` | `modules/home/programs/apps/chords.nix` (`options.forge.chords`) | `{ layers, modes, karabiner.rules, zellij.{ ... }; }`    | A key or modifier change alters physical leader behavior and runtime popup bytes together. |

## [02]-[THEME_PROJECTION_WEB]

`theme.nix` owns the palette as `mkColor`-lifted rows (uppercase hex plus derived `r g b triple csv rgba`) and the semantic layers built on them: `roles`, `ansi16`, `syntaxScopes`, the tmTheme, and `projections` (`luaPalette`, `blameRamp`, `vscodeTokenRules`). It also writes the external artifacts `forge/theme/palette.json` and `forge/theme/forge-dracula.tmTheme`.

Consumers never restate hex. WezTerm receives `projections.luaPalette` as `wezterm/palette.lua` and maps ANSI in `appearance.lua`; Zellij status rows and the component theme read palette tokens; Yazi points syntect at the owner tmTheme; Neovim writes `forge/palette.lua` and remaps Dracula highlights; VS Code builds terminal ANSI and TextMate settings from the owner and seeds user settings behind a sentinel; bat sources the owner tmTheme and delta reuses the bat cache theme plus the owner `blameRamp`. The extension rule: a tool that needs color reads the resolved option or an owner-emitted artifact — a private palette is the fork the eval-time single owner exists to prevent.

## [03]-[CHORD_PROJECTION_WEB]

`chords.nix` owns the physical layer grammar (Hyper, Super, caps dual-role), the mode table, the bind-row schema, and the render logic that emits `karabiner.rules` and the `zellij.*` KDL fragments. Karabiner reads `karabiner.rules` and writes active `karabiner.json`; Zellij reads `layers`/`modes`, renders hint ribbons from `zellij.ribbon`, and injects generated bind and entry KDL. The Yazi popup runtime reads `zellij.ids.yaziToggle`, and the acceptance harness converts `{key, mods}` to kitty CSI-u bytes. WezTerm is the one terminal that does not read the option: its native left-Command layer lives in `keys.lua` and is documented back into the chord owner's discoverability rows, so the two must be edited together.

## [04]-[HOST_CONTEXT_FACTORY]

`hosts/context.nix` mints the per-host row (`name`, `os`, `system`, versions, user, ssh, and NixOS disk/network/service-user fields). One wrong row shape breaks flake host construction, NixOS static networking, and Home Manager import gates at once. Darwin (`hosts/darwin/default.nix`) projects `context.macbook` into system + Home Manager and imports common/darwin/home; NixOS (`hosts/nixos/default.nix`) projects the `os == "nixos"` row and imports common/nixos. `host.os` is the gate that keeps Darwin-only GUI apps and mac tools off Linux (`modules/home/programs/default.nix`) and drives the static systemd-user-service gates in `ssh.nix` and `scientific-tools.nix`.

## [05]-[TOOLCHAIN_PATH_FACTORY]

`modules/common/toolchain-env.nix` (`forgeToolchainEnvFor`) is the single source of PATH vectors, scientific-env exports, and browser path. Its output is consumed by the shell environment, zsh config, the Darwin GUI launchd env (`darwin/settings/system.nix`), and WezTerm. A bad PATH vector makes shells, launchd agents, and GUI-launched subprocesses resolve different tools — the bug class where a command works in the terminal and fails under a GUI-launched agent. Platform reality for this seam is [platform-facts.md](platform-facts.md).

A sibling context-dispatch seam lives in `languages/python-tools.nix`: `python`, `python3`, `ruff`, `ty`, and `mypy` are project-first shims — inside a project root they exec the project's `.venv` or `uv --project run`, otherwise the system interpreter — so the interpreter a bare `python` binds to is a function of the caller's directory, not a fixed PATH entry. `FORGE_PYTHON_SHIM_BYPASS=1` forces the system interpreter when a shim resolves the wrong environment in a sibling repo.

## [06]-[OWNER_TABLES]

New capability lands as a row on the owning table, never a new file. Each axis has one owner that both installs packages and carries their config.

| [INDEX] | [AXIS]                                                 | [OWNER]                                  | [NEW_CAPABILITY]                                                                      |
| :-----: | :----------------------------------------------------- | :--------------------------------------- | :------------------------------------------------------------------------------------ |
|  [01]   | Home graph                                             | `modules/home/default.nix`               | an import under assets/environments/theme/programs/scripts/xdg                        |
|  [02]   | Program graph                                          | `modules/home/programs/default.nix`      | a program import; Darwin apps/mac-tools gated by `host.os`                            |
|  [03]   | GUI apps                                               | `modules/home/programs/apps/default.nix` | a karabiner/nvim/vscode/wezterm/yazi/zellij import                                    |
|  [04]   | Shell / git / container / language / media / nix tools | the matching `*/default.nix` roster      | a package row on that axis table                                                      |
|  [05]   | DB clients                                             | `languages/db-tools.nix`                 | a wrapped client row (Postgres 18 clients, DuckDB, SQLite/SQLean, linters)            |
|  [06]   | MCP fleet                                              | `shell-tools/mcp-fleet.nix`              | a manifest row (transport, command/url, env-key names, probe, launcher, Codex fields) |
|  [07]   | Environment variables                                  | `environments/default.nix`               | a row on the core/shell/languages/development/apps/containers/media env owner         |

The MCP manifest is the deepest fan-out: `mcp-launchers.nix` filters launcher rows, serializes fleet JSON, builds pnpm wrappers, and validates Claude/Codex registration drift against `~/.claude.json` and `~/.codex/config.toml` — a manifest row change ripples to wrapper presence, `forge-mcp drift`, and required Codex servers. Secret and token custody for these rows is [secrets-and-services.md](secrets-and-services.md).

## [07]-[ESTATE_REACH]

The estate does not end at the flake. Four seams cross into other systems, each owned here and detailed in a sibling atlas doc.

| [INDEX] | [SEAM]               | [FORGE_OWNS]                                                                                                  | [DETAIL]                                           |
| :-----: | :------------------- | :------------------------------------------------------------------------------------------------------------ | :------------------------------------------------- |
|  [01]   | Machine / macOS      | launchd grammar, activation classes, deploy locks, container runtime                                          | [platform-facts.md](platform-facts.md)             |
|  [02]   | Secrets / services   | the Doppler pull rail, `services/` Pulumi topology, GitHub-as-code, tunnels                                   | [secrets-and-services.md](secrets-and-services.md) |
|  [03]   | Rails / provisioning | `forge-redeploy`, `forge-provision`, `forge-accept`, drift, the schema-v3 envelope                            | [rails-and-contracts.md](rails-and-contracts.md)   |
|  [04]   | Rasm / Maghz         | `nixosConfigurations.maghz`, the `ssh.nix` tunnel substrate, mirrored standards, the machine-tooling boundary | [scars.md](scars.md)                               |

The cross-repo law: Forge is the machine owner. When a shell wrapper, PATH entry, container socket, DB CLI, or scientific build fails in Rasm or Maghz, the fix is the Forge owner, never a patch in the sibling. Rasm owns the method and language-law bedrock Forge composes; Maghz owns its own service plane and `ops-doctrine`. Standards mirror by copy, never by tooling.
