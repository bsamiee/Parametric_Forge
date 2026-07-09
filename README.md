# Parametric Forge

Parametric Forge is the machine estate: one flake owns the macOS workstation and the NixOS VPS seam — system defaults, GUI apps, CLI tools, fonts, overlays, secrets rails, MCP fleet, SSH estate, provisioning, and cache policy. Sibling repos (Rasm, Maghz) assume this estate on `PATH` and never import it; when shell, toolchain, credential, or wrapper behavior fails in a sibling repo, the fix lands here. Nothing in this repo couples to a specific project — Forge aligns with consumers, never binds to them.

## [01]-[LAYOUT]

```text
flake.nix / flake.lock    Inputs (Determinate pin, nixpkgs-unstable, flake-parts, nix-darwin,
                          home-manager master, disko, treefmt-nix), systems, host exports
flake-modules/            nixpkgs config, package/app outputs, checks + formatter, dev shell
hosts/                    context.nix host-context factory; darwin/ (macbook) and nixos/
                          (VPS rows: nixos-anywhere + disko bootstrap, forge-redeploy day-2)
modules/common/           Determinate Nix custom settings + shared toolchain env (both OSes)
modules/darwin/           macOS defaults/input/interface/security, fonts, Homebrew bridge
modules/home/             Home Manager: xdg, theme, aliases, assets, environments/,
                          programs/ (apps, git/language/container/mac/media/nix/shell tools,
                          zsh), scripts/ (integration + analysis)
overlays/                 Forge packages and pins: duckdb, energyplus, openstudio, sqlean,
                          sqlite-forge, forge-provision, nodejs-bin, pnpm
services/                 IaC owner: Doppler topology + GitHub settings rows (topology.ts),
                          Pulumi Automation API driver (driver.ts), estate.ts
docs/                     stacks/ (python, typescript atlases) + standards/ (design/nix
                          doctrine, style, formatting, information structure)
```

## [02]-[DECISION_FRAMEWORK]

Rulings derive from principles, not precedent lists. A new situation resolves from these axes without a new ruling:

| [INDEX] | [AXIS]                 | [LAW]                                                                                                       |
| :-----: | :--------------------- | :----------------------------------------------------------------------------------------------------------- |
|  [01]   | Greenfield-only        | Every touched surface rebuilds to the best current shape; shims, aliases, compat wrappers, and migration helpers never exist. |
|  [02]   | One owner per axis     | Each concern has exactly one declaring file; a second copy of any fact is a fork. Extend the owner before adding files. |
|  [03]   | Rows over hardcodes    | Capability lands as a parameterized row on the owning table — tunnel, chord, fleet member, overlay pin, service. |
|  [04]   | Polymorphic collapse   | Density rises inside the owning file — merged types, dispatch tables, folds — never by extraction. ~300 LOC per file; justified single-concern lists may exceed it. |
|  [05]   | IaC over YAML          | Service state (Doppler topology, GitHub settings, VPS resources) is typed Pulumi rows in `services/`, never per-repo config files or click-ops. |
|  [06]   | Currency as review     | Newest stable everything; a pin exists only with a named incompatibility and dies when compatibility lands.  |
|  [07]   | No LFS                 | Repo media ships as plain git blobs kept preview-small; the Git LFS client serves external repos only.       |
|  [08]   | Aesthetics first-class | Visual surfaces (theme, prompt, TUI, fonts) are designed systems with single palette ownership.              |

## [03]-[DETERMINATE_NIX]

This machine runs Determinate Nix, not vanilla: Determinate owns the daemon and `/etc/nix/nix.conf` (`eval-cores`, `lazy-trees`, `netrc-file`, `ssl-cert-file`, `experimental-features`). `modules/common/nix.nix` declares only the custom settings the Determinate module writes to `/etc/nix/nix.custom.conf` — Determinate-owned keys are rejected there by construction. One settings vocabulary projects to both OSes: Darwin rides `determinateNix.customSettings`, NixOS rides the thin determinate module plus `nix.settings`. GC and store maintenance ride the `forge-nix-maintenance` agent, never ad-hoc `nix-collect-garbage`.

## [04]-[MODULE_BOUNDARIES]

- `modules/common/` carries what both OSes consume identically: Nix settings and the toolchain env vocabulary. The OS branch keys on the static host context (`hosts/context.nix`), never on `pkgs` — module fixpoint safety.
- `modules/darwin/` carries system-scope macOS state: defaults, security (sudoers NOPASSWD allowlist, TCC adjacency), fonts, and the Homebrew bridge. Homebrew exists only for GUI/proprietary bundles nixpkgs cannot ship; activation refreshes metadata while the `forge-brew-autoupdate` reconciler owns the daily `--upgrade --cleanup` cadence with keychain-backed sudo. Uninstall/zap stays off so operator installs survive.
- `modules/home/` carries user-scope state under Home Manager: XDG hygiene, session environments, program owners, scripts. System and home scopes never mix in one module.
- `overlays/` is the admission gate for upstream packages nixpkgs lacks or pins wrongly: each overlay owns its version, source hash (`nix-prefetch-github`), and build; the flake-level overlay composes them. Admission requires a real consumer now — never anticipatory packaging.
- `services/` owns live service state as code. `node driver.ts preview|up|refresh [--adopt] [--target=<p>/<c>/<token>]` converges the estate; `outputs [--reveal]` projects receipts; `scopes apply|doctor|strict` governs directory-scope resolution. The driver brokers its own tokens from `op` per invocation. An existing service domain extends its rows; a new service domain gets a new organized owner, mirroring the module folder philosophy.

## [05]-[SECRETS]

Doppler is the sole secret backend for projects and agents; 1Password is operator-personal custody (the SSH key item, personal vaults, and the driver-brokered IaC tokens). The canonical SessionStart hook (`.claude/hooks/setup-env.sh`, byte-identical in every repo, mastered here) resolves each Doppler source row live with per-source verdicts, serves encrypted snapshots on fetch failure, and writes a mode-600 env file — agents read credentials from the environment, key names only in receipts, never values. Reading: `doppler secrets --project <p> --config <c> --only-names`. Adding: set the key in the owning Doppler config; the hook propagates it — zero per-repo secret files. Topology (projects, configs, service tokens) mutates only through `services/topology.ts` rows. The `secrets` skill owns the full custody and consumption law.

## [06]-[MCP_FLEET]

`modules/home/programs/shell-tools/mcp-fleet.nix` is the single fleet manifest: one row declares a member's transport, spawn line or endpoint, env key names, probe class, launcher pin, and client expectations. `mcp-launchers.nix` builds the pinned `forge-*-mcp` wrappers from `launcher` rows; `forge-mcp doctor [--network]` proves every row live, `forge-mcp drift` validates both client registrations against rows, `forge-mcp outdated` surfaces stale pins. Add or extend a server as one manifest row — registrations mirror rows, and drift is the proof.

## [07]-[SSH_ESTATE]

One ed25519 key serves everything: custodied in the 1Password Personal vault, served through the 1Password agent socket (`~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock`), registered on GitHub exactly twice (authentication key + signing key), with `~/.ssh/id_ed25519` as the on-disk recovery pair. Commit signing is SSH-format (`gpg.format ssh`, allowed-signers projected by `git-tools`). Remotes and tunnels are `vpsTunnels` rows in `modules/home/programs/shell-tools/ssh.nix`: one row projects the interactive host block, the transport-only tunnel block, the health-gated launchd supervisor (bind proof, service-probe receipts, port-conflict detection), and the Linux systemd twin. The tunnel agent solely owns loopback forwards; interactive sessions never bind them. A new remote is a new row.

## [08]-[DEPLOY_RAIL]

`forge-redeploy [--os darwin|nixos] [--host NAME] [--target-host SSH] --check-only|--build|--switch|--rollback|--generations` is the only sanctioned activation path: it locks against concurrent runs, builds, diffs the closure, activates, appends a receipt row (timings, generation, diff size), and pushes the system closure to Cachix when `CACHIX_AUTH_TOKEN` resolves. Darwin activates locally under the sudoers allowlist; NixOS targets deploy over SSH. Declared launchd agents carry the recurring work — `forge-jupyter` (persistent JupyterLab), `forge-nix-maintenance` (GC/store), `forge-nix-drift`, `forge-mcp-outdated`, `forge-brew-autoupdate`, and per-row VPS tunnels — powerful and few, each with receipts; ad-hoc background processes are a defect.

## [09]-[TOOLCHAINS]

- [PYTHON]: 3.15 GIL build; `uv`, `ruff`, `ty`, `mypy` resolve project-local versions first through the shim. `forge-scientific-sync` locks an isolated XDG-state uv env; `forge-scientific-env` exposes the native build closure (clang, gfortran, GDAL/GEOS/PROJ, HDF5/netCDF, Arrow, OpenBLAS, ONNX, Eigen, PDAL, Boost) plus EnergyPlus/OpenStudio. `forge-companion-env` is the cp312 lane for tooling gated below 3.15.
- [NODE_LUA_DB]: Node 26 via the Nix-owned official binary + pnpm pin; Lua with LSP tooling; DuckDB/SQLite with sqlean/spatialite/vec; PostgreSQL 18 client tools are Home Manager-owned, PostgreSQL server extensions stay Docker-owned by `forge-provision`.
- [DOTNET_AEC]: Nix-managed dotnet SDKs (8/9/10); `energyplus` and `openstudio` are Forge-owned machine runtimes with disjoint ambient identities.
- [PROVISIONING]: `forge-provision` (overlay-owned, Home Manager-installed) is the local service provisioner — schema-v3 sanitized JSON, deterministic ports, preserved volumes, noninteractive by contract; `forge-provision --help` is the live verb list. Rasm campaign work enters through its own assay rail; direct calls are Forge-level debugging.
- [MCP_LAUNCHERS]: `forge-ifcmcp` (cp312 IfcOpenShell), `forge-jupyter-mcp`, `nuget-mcp` (.NET 10), and the fleet wrappers are Home Manager-installed; sibling-repo skills invoke them — launcher behavior is fixed here, never in a sibling.

## [10]-[TERMINAL_MESH_AND_THEME]

`modules/home/theme.nix` is the estate palette owner: Dracula-variant base rows, semantic roles, ANSI-16 projection, and syntax scope tables serialize into every consumer (WezTerm, Zellij, Yazi, Neovim, VS Code, bat/delta, Starship) — no consumer carries a private hex. `modules/home/programs/apps/chords.nix` is the single chord-vocabulary owner: one parameterized table projects physical leader layers into Karabiner JSON, Zellij keybind KDL, and which-key/hint content — a new bind is one row. The mesh: WezTerm auto-attaches Zellij; the integration rail (`modules/home/scripts/integration`) runs Yazi as a floating popup and routes edits into the tab's live Neovim over RPC sockets; shell is zsh with fzf-tab, Atuin, carapace, Starship, zoxide, delta.

## [11]-[QUALITY_BAR]

| [INDEX] | [SURFACE]  | [STANDARD]                                                                                                    |
| :-----: | :--------- | :-------------------------------------------------------------------------------------------------------------- |
|  [01]   | Nix        | `docs/standards/nix-doctrine.md`; density target ~300 LOC by polymorphic collapse; `alejandra`/`deadnix`/`statix` gate via `nix flake check`. |
|  [02]   | Shell      | `writeShellApplication` for any body with a runtime closure (ShellCheck in the build); `writeShellScriptBin` only for closure-free one-liners; `.sh` extension, `set -euo pipefail`. |
|  [03]   | TypeScript | `docs/stacks/typescript/` (Rasm doctrine) — `services/` code is held to it in full.                             |
|  [04]   | Python     | `docs/stacks/python/`; 3.15+, `uv`-managed, `ruff` + `ty`.                                                     |
|  [05]   | Markdown   | `docs/standards/` owners: style-guide, formatting, information-structure; agent-facing declarative register.    |
|  [06]   | launchd    | Declared agent rows with receipts and health gates; never ad-hoc `launchctl` state.                            |

## [12]-[GITHUB_AND_SERVICES]

GitHub repository settings for the estate (merge hygiene, rulesets, feature booleans) are `@pulumi/github` rows in `services/topology.ts`; `node driver.ts preview` is the verification surface — repo state is never enumerated in prose or edited in the GitHub UI. Doppler projects, environments, branch configs, and service tokens live as rows in the same file. Code review rides CodeRabbit (`.coderabbit.yaml`) and Greptile (`.greptile/`); the `pr-loop` skill owns hosted-PR round-trips.

## [13]-[FRESH_MACHINE_BOOTSTRAP]

Everything lands declaratively with the first switch; only these steps are manual, each with its proof:

| [INDEX] | [ACTION]                                                                                             | [VERIFY]                                        |
| :----: | :------------------------------------------------------------------------------------------------------ | :----------------------------------------------- |
|  [01]  | Install Determinate Nix: `curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \| sh -s -- install` | `nix --version` reports Determinate              |
|  [02]  | Sign into the 1Password app; enable Settings → Developer → SSH agent + CLI integration (GUI-only by vendor design; key custody syncs from the cloud — zero key handling) | `SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock ssh-add -L` lists the key |
|  [03]  | Clone to the path the deploy rail resolves — the agent socket is explicit until the first switch projects `~/.ssh/config`: `SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock git clone git@github.com:bsamiee/Parametric_Forge.git ~/Documents/99.Github/Parametric_Forge` | repo present at `FORGE_ROOT`                     |
|  [04]  | `gh auth login` (keyring, SSH protocol)                                                                 | `gh auth status`                                 |
|  [05]  | `doppler login`                                                                                         | `doppler me`                                     |
|  [06]  | First switch: `sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake .#macbook` — this installs the sudoers allowlist every later `forge-redeploy --switch` rides | `forge-redeploy --check-only`                    |
|  [07]  | Approve the TCC/automation prompts macOS raises on first agent launches                                 | affected agents run without prompting            |

Day-2 rebuilds: `forge-redeploy --switch`.

## [14]-[MAINTENANCE]

- Format: `nix fmt -- --check` — full proof: `nix flake check`.
- Provisioner: `nix build .#forge-provision`; smoke with `nix run .#forge-provision -- self-test`.
- Inputs: `nix flake update`; closure diffs review through `nvd`/`nix-diff` before switching.
- Fleet: `forge-mcp doctor --network` and `forge-mcp drift` after any fleet or client change.

## [15]-[LICENSE]

MIT — Bardia Samiee
