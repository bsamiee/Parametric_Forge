# Interconnection

Single-owner surfaces web the estate; each projection fans into many consumers, and a change to an owner ripples to every reader that composes it. This map names the load-bearing seams, the `config.forge.*` option hinges, and the estate's reach into machines, services, and consumer repos. It carries edges and blast radius only — usage lives in each owner's own surface, module boundaries in the repo root router.

Forge is the machine owner — cross-repo law. When a shell wrapper, PATH entry, container socket, DB CLI, or scientific build fails in a consumer repo, the fix is the Forge owner, never a sibling patch. Rasm owns the method and language-law bedrock Forge composes. Standards mirror by copy, never by tooling.

## [01]-[CONFIG_FORGE_NAMESPACE]

`options.forge.*` read-only surfaces are the estate's projection hinges: a downstream module reads the resolved value and renders its own artifact, never a private copy of the source data. Each owner declares the matching `options.forge.<name>`; record shapes for the deep ones sit in a note below.

| [INDEX] | [OPTION]                    | [OWNER]                                 | [HINGE_LAW]                                                    |
| :-----: | :-------------------------- | :-------------------------------------- | :------------------------------------------------------------- |
|  [01]   | `config.forge.theme`        | `modules/home/theme.nix`                | Rename/reshape fails eval for every themed reader.             |
|  [02]   | `config.forge.chords`       | `modules/home/programs/apps/chords.nix` | Key/mod change couples leader and popup bytes.                 |
|  [03]   | `config.forge.ssh.*`        | `shell-tools/ssh.nix`                   | A host row fans to native SSH, WezTerm, and Yazi clients.      |
|  [04]   | `config.forge.ignoreEstate` | `shell-tools/fd.nix`                    | One ignore taxonomy renders for every search/watch consumer.   |
|  [05]   | `config.forge.registers.*`  | `aliases/`                              | One typed alias register folds every row into the zsh surface. |
|  [06]   | `config.forge.fonts`        | `modules/home/fonts.nix`                | Font identity drives terminal, editor, and glyph render seams. |
|  [07]   | `config.forge.lsp`          | `modules/home/programs/apps/nvim/`      | Server rows shared across editor surfaces.                     |

- `config.forge.theme` shape: `{ palette, roles, ansi16, syntaxScopes, projections; }`
- `config.forge.chords` shape: `{ layers, modes, register, nvim.rows, wezterm.rows, karabiner.rules, zellij.{ ... }; }`
- `config.forge.chords` is defined under the darwin-gated `apps/` import: a both-OS consumer reads it only through an `or` default.
- `config.forge.ssh` shape: `{ hosts.<name>.{ name, user, hostName, aliases }, identityAgent; }`. `identityAgent` is the 1Password socket every remote client pins.

## [02]-[THEME_PROJECTION_WEB]

`theme.nix` owns the palette as `mkColor`-lifted rows (uppercase hex with derived `r g b triple csv rgba`) and the semantic layers built on them: `roles`, `ansi16`, `syntaxScopes`, the tmTheme, and `projections` (`luaPalette`, `blameRamp`). It also writes the external artifacts `forge/theme/palette.json` and `forge/theme/forge-dracula.tmTheme`.

Consumers never restate hex. WezTerm receives `projections.luaPalette` as a row of the generated `wezterm/rows.lua`, which `deck.lua` interprets for its ANSI map; Zellij status rows and the component theme read palette tokens; Yazi points syntect at the owner tmTheme; Neovim writes `forge/palette.lua` and remaps Dracula highlights; bat sources the owner tmTheme and delta reuses the bat cache theme and the owner `blameRamp`. Tools needing color read the resolved option or an owner-emitted artifact — a private palette is the fork the eval-time single owner exists to prevent.

## [03]-[CHORD_PROJECTION_WEB]

`chords.nix` owns the physical layer grammar (Hyper, Super, caps dual-role), the mode table, the bind-row schema, and the render logic that emits `karabiner.rules` and the `zellij.*` KDL fragments. Karabiner reads `karabiner.rules` and writes active `karabiner.json`; Zellij reads `layers`/`modes`, renders hint ribbons from `zellij.ribbon`, and injects generated bind and entry KDL. Yazi's popup runtime reads `zellij.ids.yaziToggle`, and id-tagged rows export `{key, mods}` as kitty CSI-u bitmasks for runtime injection. WezTerm reads `config.forge.chords.wezterm.rows` for its native left-Command layer; the key rows in the generated `rows.lua` and the chord owner's discoverability rows derive from the same rows.

## [04]-[HOST_CONTEXT_FACTORY]

`hosts/context.nix` mints the per-host row (`name`, `os`, `system`, versions, time zone, user, ssh, and NixOS disk/network fields; Darwin rows add `label`). The VPS SSH row also carries its client hostname and pinned server key. One wrong row shape breaks flake host construction, NixOS static networking, and Home Manager import gates at once. `hosts/default.nix` is the single factory: an OS dispatch row selects the system builder and module set, and one shared per-host module carries platform, identity, and the Home Manager projection for every row. `host.os` is the gate that keeps Darwin-only GUI apps and Mac tools off Linux (`modules/home/programs/default.nix`).

## [05]-[TOOLCHAIN_PATH_FACTORY]

`modules/common/toolchain-env.nix` (`forgeToolchainEnvFor`) is the single source of PATH vectors, scientific-env exports, and browser path. Its output is consumed by the shell environment, zsh config, the Darwin GUI launchd env (`darwin/settings/system.nix`), and WezTerm. A bad PATH vector makes shells, launchd agents, and GUI-launched subprocesses resolve different tools — the bug class where a command works in the terminal and fails under a GUI-launched agent.

Forge installs no interpreter, package manager, or checker a project pins: `python`, `uv`, `ruff`, `ty`, `mypy`, `node`, `pnpm`, and their peers are rows of each project's `mise.toml` and lock files. Inside a project, `mise activate` sources the `.venv` its `uv.lock` names (`python.uv_venv_auto`) and the pinned tools ahead of every Nix segment; a non-interactive caller reaches the same environment through `uv run` or the mise shim farm, and outside every project those names resolve to nothing.

## [06]-[OWNER_TABLES]

New capability lands as a row on the owning table, never a new file. Each axis has one owner that both installs packages and carries their config.

| [INDEX] | [AXIS]                | [OWNER]                                  | [NEW_CAPABILITY]                                               |
| :-----: | :-------------------- | :--------------------------------------- | :------------------------------------------------------------- |
|  [01]   | Home graph            | `modules/home/default.nix`               | an import under assets/environments/theme/programs/scripts/xdg |
|  [02]   | Program graph         | `modules/home/programs/default.nix`      | a program import; Darwin apps/mac-tools gated by `host.os`     |
|  [03]   | GUI apps              | `modules/home/programs/apps/default.nix` | a karabiner/linearmouse/nvim/wezterm/yazi/zellij import        |
|  [04]   | Shell, git, and peers | the matching `*/default.nix` roster      | a package row on that axis table                               |
|  [05]   | DB clients            | `languages/db-tools.nix`                 | a wrapped client row                                           |
|  [06]   | Environment variables | `environments/default.nix`               | a row on the env owner                                         |

- [04]: axis families: shell, git, container, language, media, nix tools
- [05]: client row: Postgres 18 clients, DuckDB, SQLite/SQLean, linters
- [06]: env owner axes: core, shell, languages, development, apps, containers, media

MCP servers carry no Forge row: each project registers its servers with their upstream commands in its own `.mcp.json`.

## [07]-[RUNTIME_SEAMS]

Beyond eval-time option hinges, these contracts bind processes at runtime across module boundaries; each side is edited only with the other in view.

- [01]-[TERMINAL_MESH]: `apps/chords.nix` bind rows invoke `forge-yazi.sh toggle` (`scripts/terminal.nix`); the yazi opener invokes `forge-edit.sh %s`; the editor registry publishes `editor-tab-*.tsv` rows the dispatcher globs. Every edge rename lands across all of those owners in the same change.
- [02]-[XDG_PROJECTIONS]: agent-facing artifacts live at fixed projection paths — `~/.config/forge/theme/palette.json` and `forge-dracula.tmTheme` carry the theme. Consumers hardcode these paths by contract; moving one is an estate-wide grep, not a local edit.
- [03]-[QA_HOOKS]: `flake-modules/qa.nix` compiles every `.jq` program under `overlays/` with the store jq; treefmt rows (`flake-modules/tooling.nix`) own formatting per extension, and a placeholder-bearing template no row may own (the `.sql.tpl` scar).
- [04]-[SESSION_FABRIC]: one workspace row (`wezterm/default.nix`) carries picker entry, zellij session identity, cwd, and float policy; `deck.lua` reads the row for its native workspace picker and derives the session arguments from it.
