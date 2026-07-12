# Parametric Forge

Parametric Forge is the machine estate: one flake owns the macOS workstation and the NixOS VPS — system defaults, GUI apps, CLI tools, fonts, overlays, secrets rails, MCP fleet, SSH estate, provisioning, and cache policy. Sibling repos (Rasm, Maghz) assume this estate on `PATH` and never import it; when shell, toolchain, credential, or wrapper behavior fails in a sibling repo, the fix lands here. Nothing in this repo couples to a specific project — Forge aligns with consumers, never binds to them.

## [01]-[LAYOUT]

This regenerable topology maps the repository's owning entry points.

```text codemap
Parametric_Forge/
├── flake.nix                      # Flake inputs, systems, outputs
├── flake.lock
├── flake-modules/                 # Outputs, checks, formatter, development shell
├── hosts/
│   ├── context.nix                # Host-context row registry
│   └── default.nix                # OS dispatch and system projection
├── modules/
│   ├── common/                    # Shared Nix settings and toolchain environment
│   ├── darwin/
│   │   ├── settings/              # MacOS defaults, input, interface, security
│   │   └── homebrew/              # Homebrew bridge
│   ├── nixos/                     # Boot, network, SSH, users, containers, services
│   └── home/
│       ├── aliases/               # Shell alias registry
│       ├── assets/
│       │   ├── ascii/             # Fetch banner assets
│       │   └── wallpaper/         # Wallpaper assets
│       ├── environments/          # Cross-tool environment projections
│       ├── programs/
│       │   ├── apps/
│       │   │   ├── karabiner/     # Leader-chord keyboard layer
│       │   │   ├── nvim/          # Editor estate
│       │   │   ├── vscode/
│       │   │   ├── wezterm/       # Terminal host
│       │   │   ├── yazi/          # File manager
│       │   │   └── zellij/        # Multiplexer layouts and themes
│       │   ├── container-tools/
│       │   ├── git-tools/
│       │   ├── languages/         # Language toolchains
│       │   ├── mac-tools/
│       │   ├── media-tools/
│       │   ├── nix-tools/
│       │   ├── shell-tools/       # CLI kernels, MCP launchers, SSH, secrets
│       │   └── zsh/
│       └── scripts/               # Integration and analysis kernels
├── overlays/                      # Manifest-folded package admissions
│   └── forge-provision/           # Local provisioning CLI
├── services/                      # Doppler and GitHub IaC rows
├── docs/
│   ├── atlas/                     # Platform facts, rails, interconnection
│   ├── laws/                      # Estate design and machine law
│   ├── stacks/                    # Language law
│   └── standards/                 # Prose, formatting, information structure
├── .claude/                       # Harness skills, hooks, workflows, LSP marketplace
├── .greptile/                     # Per-repo reviewer configuration
└── .coderabbit.yaml               # Per-repo reviewer configuration
```

## [02]-[HOSTS]

`hosts/context.nix` is the host register: one row per machine carries name, OS, system, state versions, user identity, feature flags, and SSH keys — server rows add service users, the disk device, and static network facts. Host files project rows into `darwinSystem`/`nixosSystem`; the home graph gates imports on `host.os` and `host.features`, never on `pkgs`. Two hosts are live: `macbook` (aarch64-darwin workstation, desktop features) and `maghz` (x86_64-linux Hostinger VPS, server features — static addressing projected from its network row, SSH the only open port, every service loopback-bound and reached through `vpsTunnels` rows). A new machine is a new row; nothing else changes shape.

## [03]-[DECISION_FRAMEWORK]

Rulings derive from principles, not precedent lists. A new situation resolves from these axes without a new ruling:

| [INDEX] | [AXIS]                 | [LAW]                                                                                                       |
| :-----: | :--------------------- | :---------------------------------------------------------------------------------------------------------- |
|  [01]   | Greenfield-only        | Every touched surface rebuilds to the best current shape; no compatibility layer of any kind survives.      |
|  [02]   | One owner per axis     | One declaring file per concern; a second copy of any fact is a fork — extend the owner, never add files.    |
|  [03]   | Rows over hardcodes    | Capability lands as a parameterized row on the owning table; a new host, tunnel, or service is one row.     |
|  [04]   | Polymorphic collapse   | Density rises inside the owning file — merged types, dispatch tables, folds — never by extraction.          |
|  [05]   | IaC over YAML          | Service state is typed Pulumi rows in `services/` — Doppler, GitHub — never per-repo files or click-ops.    |
|  [06]   | Currency as review     | Newest stable everything; a pin exists only with a named incompatibility and dies when compatibility lands. |
|  [07]   | No LFS                 | Repo media ships as plain git blobs kept preview-small; the Git LFS client serves external repos only.      |
|  [08]   | Aesthetics first-class | Visual surfaces (theme, prompt, TUI, fonts) are designed systems with single palette ownership.             |

## [04]-[DETERMINATE_NIX]

This machine runs Determinate Nix, not vanilla: Determinate owns the daemon and `/etc/nix/nix.conf` (`eval-cores`, `lazy-trees`, `netrc-file`, `ssl-cert-file`, `experimental-features`). `modules/common/nix.nix` declares only the custom settings the Determinate module writes to `/etc/nix/nix.custom.conf` — Determinate-owned keys are rejected there by construction. One settings vocabulary projects to both OSes: Darwin rides `determinateNix.customSettings`, NixOS rides the thin determinate module plus `nix.settings`. GC and store maintenance ride the `forge-nix-maintenance` agent, never ad-hoc `nix-collect-garbage`.

## [05]-[MODULE_BOUNDARIES]

- `modules/common/` carries what both OSes consume identically: Nix settings and the toolchain env vocabulary. The OS branch keys on the static host context (`hosts/context.nix`), never on `pkgs` — module fixpoint safety.
- `modules/darwin/` carries system-scope macOS state: defaults, security (sudoers NOPASSWD allowlist, TCC adjacency), fonts, and the Homebrew bridge. Homebrew exists only for GUI/proprietary bundles nixpkgs cannot ship; activation refreshes metadata while the `forge-brew-autoupdate` reconciler owns the upgrade/cleanup cadence with keychain-backed sudo. Uninstall/zap stays off so operator installs survive.
- `modules/nixos/` carries system-scope NixOS state for server hosts: boot and disko, static addressing projected from the host-context network row, key-only SSH, declarative users, container runtime, and loopback-bound services reached solely through tunnel rows. Nothing Darwin-owned — Homebrew, launchd, macOS defaults — generalizes here.
- `modules/home/` carries user-scope state under Home Manager: XDG hygiene, session environments, program owners, scripts. System and home scopes never mix in one module.
- `overlays/` is the admission gate for upstream packages nixpkgs lacks or pins wrongly: each overlay owns its version, source hash (`nix-prefetch-github`), and build; the flake-level overlay composes them. Admission requires a real consumer now — never anticipatory packaging.
- `services/` owns live service state as code, held to `docs/stacks/typescript/` in full. The repo root is the single pnpm workspace (`package.json` + `pnpm-workspace.yaml` catalog — one manifest, no per-folder package files). An existing service domain extends its rows; a new service domain gets a new organized owner, mirroring the module folder philosophy.
- `services/` workspace commands: `node services/driver.ts preview|up|refresh [--adopt] [--target=<p>/<c>/<token>]` converges the estate; `outputs [--reveal]` projects receipts; `scopes apply|doctor|strict` governs directory-scope resolution; `reviewers` proves the reviewer matrix; `apps` projects the browser-custodied GitHub App census. The driver brokers the Pulumi and Doppler control credentials from 1Password and resolves `GITHUB_TOKEN` from the agent environment or Doppler.

## [06]-[SECRETS]

Doppler is the sole secret backend for projects and agents; 1Password is operator-personal custody (the SSH key item, personal vaults, and the driver-brokered IaC tokens). The canonical SessionStart hook (`.claude/hooks/setup-env.sh`, byte-identical in every repo, mastered here) resolves each Doppler source row live with per-source verdicts, serves encrypted snapshots on fetch failure, and writes a mode-600 env file — agents read credentials from the environment, key names only in receipts, never values. Reading: `doppler secrets --project <p> --config <c> --only-names`. Adding: set the key in the owning Doppler config; the hook propagates it — zero per-repo secret files. Topology (projects, configs, service tokens) mutates only through `services/topology.ts` rows. The `secrets` skill owns the full custody and consumption law.

## [07]-[MCP_FLEET]

`modules/home/programs/shell-tools/mcp-fleet.nix` is the single fleet manifest: one row declares transport, spawn line or endpoint, env key names, probe class, launcher pin, authentication mode, tool-approval posture, and client expectations. Every Darwin switch runs `forge-mcp reconcile claude` and `forge-mcp reconcile codex`, replacing only manifest-owned MCP maps while preserving unrelated client state and app-private Codex rows. `forge-mcp doctor --network` joins endpoint health to declared credentials, `forge-mcp drift` proves the live projections, and `forge-mcp outdated` surfaces stale pins. Add or extend a server as one manifest row.

## [08]-[SSH_ESTATE]

One ed25519 key serves everything: custodied in the 1Password Personal vault, served through the 1Password agent socket (`~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock`), registered on GitHub exactly twice (authentication key + signing key), with `~/.ssh/id_ed25519` as the on-disk recovery pair. Commit signing is SSH-format (`gpg.format ssh`, allowed-signers projected by `git-tools`). Remotes and tunnels are `vpsTunnels` rows in `modules/home/programs/shell-tools/ssh.nix`: one row projects the interactive host block, the transport-only tunnel block, the health-gated launchd supervisor (bind proof, service-probe receipts, port-conflict detection), and the Linux systemd twin. The tunnel agent solely owns loopback forwards; interactive sessions never bind them. A new remote is a new row.

## [09]-[DEPLOY_RAIL_AND_AUTOMATION]

`forge-redeploy [--os darwin|nixos] [--host NAME] [--target-host SSH] --check-only|--build|--switch|--rollback [gen]|--generations` is the only sanctioned activation path: it locks against concurrent runs, builds, diffs the closure, activates, appends a receipt row (timings, generation, diff size), and pushes the system closure to Cachix when `CACHIX_AUTH_TOKEN` resolves. Darwin activates locally under the sudoers allowlist; NixOS targets deploy over SSH, and NixOS generations live on the target. `forge-accept [--from STEP|--only STEP|--list]` is the post-switch acceptance rail: an ordered, resumable step pipeline from preflight through fleet, lane, and maghz probes to relaunch, receipting pass/warn/fail per step — a switch is done when `forge-accept` exits ok, not when activation returns.

Recurring machine work is launchd-owned under the `com.parametric-forge.<name>` label grammar, each agent declared beside the surface it serves: `launchctl list | grep com.parametric-forge` is the live census, `launchctl print gui/$UID/com.parametric-forge.<name>` the per-agent probe. The scheduled nix rails double as manual commands — `forge-nix-maintenance` (GC/store), `forge-nix-drift` (input currency), `forge-cleanup plan|apply` (declared-row litter sweep), `forge-activation-sweep [--clear]` (activation residue) — every rail appends receipts under `~/Library/Logs/forge-<name>.receipts.log`, and the receipt is read before a failed rail reruns. Ad-hoc background processes are a defect; a new job is a new agent declaration.

## [10]-[TOOLCHAINS]

- [PYTHON]: 3.15 GIL build; `uv`, `ruff`, `ty`, `mypy` resolve project-local versions first through the shim. `forge-scientific-sync` locks an isolated XDG-state uv env; `forge-scientific-env` exposes the native build closure (clang, gfortran, GDAL/GEOS/PROJ, HDF5/netCDF, Arrow, OpenBLAS, ONNX, Eigen, PDAL, Boost) plus EnergyPlus/OpenStudio. `forge-companion-env` is the cp312 lane for tooling gated below 3.15.
- [NODE_LUA_DB]: Node 26 via the Nix-owned official binary + pnpm pin; Lua with LSP tooling; DuckDB/SQLite with sqlean/spatialite/vec; PostgreSQL 18 client tools are Home Manager-owned, PostgreSQL server extensions stay Docker-owned by `forge-provision`.
- [DOTNET_AEC]: Nix-managed dotnet SDKs (8/9/10); `energyplus` and `openstudio` are Forge-owned machine runtimes with disjoint ambient identities.
- [PROVISIONING]: `forge-provision` (overlay-owned, Home Manager-installed) is the local service provisioner — schema-v3 sanitized JSON, deterministic ports, preserved volumes, noninteractive by contract; `forge-provision --help` is the live verb list. Rasm campaign work enters through its own assay rail; direct calls are Forge-level debugging.
- [MCP_LAUNCHERS]: `forge-ifcmcp` (cp312 IfcOpenShell), `forge-jupyter-mcp`, `nuget-mcp` (.NET 10), and the fleet wrappers are Home Manager-installed; sibling-repo skills invoke them — launcher behavior is fixed here, never in a sibling.

## [11]-[TERMINAL_MESH_AND_THEME]

`modules/home/theme.nix` is the estate palette owner: Dracula-variant base rows, semantic roles, ANSI-16 projection, and syntax scope tables serialize into every consumer (WezTerm, Zellij, Yazi, Neovim, VS Code, bat/delta, Starship) — no consumer carries a private hex. `modules/home/programs/apps/chords.nix` is the single chord-vocabulary owner: one parameterized table projects physical leader layers into Karabiner JSON, Zellij keybind KDL, and which-key/hint content — a new bind is one row. The mesh: WezTerm auto-attaches Zellij; the integration rail (`modules/home/scripts/terminal.nix`) runs Yazi as a floating popup and routes edits into the tab's live Neovim over RPC sockets; shell is zsh with fzf-tab, Atuin, carapace, Starship, zoxide, delta.

## [12]-[QUALITY_BAR]

| [INDEX] | [SURFACE]       | [STANDARD]                                                                                                      |
| :-----: | :-------------- | :-------------------------------------------------------------------------------------------------------------- |
|  [01]   | Nix             | `docs/laws/design.md` + the machine law pages; `alejandra`/`deadnix`/`statix` gate via `nix flake check`.       |
|  [02]   | Shell source    | `.sh` extension; `set -euo pipefail`; ShellCheck passes.                                                        |
|  [03]   | Shell packaging | `writeShellApplication` for any body with a runtime closure; `writeShellScriptBin` for closure-free one-liners. |
|  [04]   | TypeScript      | `docs/stacks/typescript/` — `services/` code is held to it in full.                                             |
|  [05]   | Python          | `docs/stacks/python/`; 3.15, `uv`-managed, `ruff` + `ty`.                                                       |
|  [06]   | Markdown        | `docs/standards/` prose owners; `prose_gate.py` (docgen skill) is the check + fix rail.                         |
|  [07]   | launchd         | Declared agent rows with receipts and health gates; never ad-hoc `launchctl` state.                             |

## [13]-[GITHUB_AND_SERVICES]

GitHub repository settings for the estate (merge hygiene, rulesets, feature booleans) are `@pulumi/github` rows in `services/topology.ts`; `node driver.ts preview` is the verification surface — repo state is never enumerated in prose or edited in the GitHub UI. GitHub App installation IDs and selection modes live in the same topology as a browser-custodied census: the universal SSH identity owns Git transport and commit signing, while GitHub exposes no SSH-authenticated REST control for app installation selection. Doppler projects, environments, branch configs, and service tokens live as rows in the same file. Code review rides CodeRabbit (`.coderabbit.yaml`) and Greptile (`.greptile/`); the `pr-loop` skill owns hosted-PR round-trips.

## [14]-[FRESH_MACHINE_BOOTSTRAP]

Everything lands declaratively with the first switch; only these steps are manual, each with its proof:

1. Install Determinate Nix.
    - Command: `curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install`
    - Verify: `nix --version` reports Determinate
2. Sign into the 1Password app; enable Settings → Developer → SSH agent + CLI integration. GUI-only by vendor design; key custody syncs from the cloud — zero key handling.
    - Verify: `SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock ssh-add -L` lists the key
3. Clone to the path the deploy rail resolves; the agent socket is explicit until the first switch projects `~/.ssh/config`.
    - Command: `SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock git clone git@github.com:bsamiee/Parametric_Forge.git ~/Documents/99.Github/Parametric_Forge`
    - Verify: repo present at `FORGE_ROOT`
4. Authenticate GitHub.
    - Command: `gh auth login` (keyring, SSH protocol)
    - Verify: `gh auth status`
5. Authenticate Doppler.
    - Command: `doppler login`
    - Verify: `doppler me`
6. First switch — installs the sudoers allowlist every later `forge-redeploy --switch` rides.
    - Command: `sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake .#macbook`
    - Verify: `forge-redeploy --check-only`
7. Approve the TCC/automation prompts macOS raises on first agent launches.
    - Verify: affected agents run without prompting

Day-2 rebuilds: `forge-redeploy --switch`. A fresh NixOS host bootstraps with nixos-anywhere + disko from its `hosts/context.nix` row; day-2 is the same rail with `--os nixos --target-host`.

## [15]-[MAINTENANCE]

- Format: `nix fmt -- --check` — full proof: `nix flake check`.
- Acceptance: `forge-accept` after any `--switch`; `--from`/`--only` re-enter a failed step without replaying the pipeline.
- Provisioner: `nix build .#forge-provision`; smoke with `nix run .#forge-provision -- self-test`.
- Inputs: `nix flake update`; closure diffs review through `nvd`/`nix-diff` before switching.
- Fleet: `forge-mcp reconcile claude`, `forge-mcp reconcile codex`, `forge-mcp doctor --network`, and `forge-mcp drift` after any fleet or client change.

## [16]-[LICENSE]

MIT — Bardia Samiee
