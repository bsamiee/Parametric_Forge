# Parametric Forge

Parametric Forge is the machine estate: one flake owns the macOS workstation and the NixOS VPS — system defaults, GUI apps, CLI tools, fonts, overlays, secrets rails, MCP fleet, SSH estate, provisioning, and cache policy. Consumer repos assume this estate on `PATH` and never import it; when shell, toolchain, credential, or wrapper behavior fails in a consumer, the fix lands here. Nothing in this repo couples to a specific project — Forge aligns with consumers, never binds to them.

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
│       │   └── ascii/             # Fetch banner assets
│       ├── environments/          # Cross-tool environment projections
│       ├── programs/
│       │   ├── apps/
│       │   │   ├── karabiner/     # Leader-chord keyboard layer
│       │   │   ├── nvim/          # Editor estate
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

`hosts/context.nix` registers `macbook` (aarch64-darwin) and `vps` (x86_64-linux Hostinger). Each row carries identity, platform, state versions, and SSH facts; the VPS adds static networking, its client hostname, and pinned server key. Host files project the rows into `darwinSystem` or `nixosSystem`, while the home graph gates on `host.os`. `ssh.nix` derives the plain `ssh vps` connection from the same row without a mount or background tunnel.

## [03]-[DECISION_FRAMEWORK]

Rulings derive from principles, not precedent lists. These axes resolve each new situation:

| [INDEX] | [AXIS]                 | [LAW]                                                                                                       |
| :-----: | :--------------------- | :---------------------------------------------------------------------------------------------------------- |
|  [01]   | Greenfield-only        | Every touched surface rebuilds to the best current shape; no compatibility layer of any kind survives.      |
|  [02]   | One owner per axis     | One declaring file per concern; a second copy of any fact is a fork — extend the owner, never add files.    |
|  [03]   | Rows over hardcodes    | Capability lands as a parameterized row on the owning table; a new host, package, or service is one row.    |
|  [04]   | Polymorphic collapse   | Density rises inside the owning file — merged types, dispatch tables, folds — never by extraction.          |
|  [05]   | IaC over YAML          | Service state is typed Pulumi rows in `services/` — Doppler, GitHub — never per-repo files or click-ops.    |
|  [06]   | Currency as review     | Newest stable everything; a pin exists only with a named incompatibility and dies when compatibility lands. |
|  [07]   | No LFS                 | Repo media ships as plain git blobs kept preview-small; the Git LFS client serves external repos only.      |
|  [08]   | Aesthetics first-class | Visual surfaces (theme, prompt, TUI, fonts) are designed systems with single palette ownership.             |

## [04]-[DETERMINATE_NIX]

This machine runs Determinate Nix, not vanilla: Determinate owns the daemon and `/etc/nix/nix.conf` (`eval-cores`, `lazy-trees`, `netrc-file`, `ssl-cert-file`, `experimental-features`). `modules/common/nix.nix` declares only the custom settings the Determinate module writes to `/etc/nix/nix.custom.conf` — Determinate-owned keys are rejected there by construction. One settings vocabulary projects to both OSes: Darwin rides `determinateNix.customSettings`, and NixOS rides the thin determinate module with `nix.settings`. GC and store maintenance ride the `forge-nix-maintenance` agent, never ad-hoc `nix-collect-garbage`.

## [05]-[MODULE_BOUNDARIES]

- `modules/common/` carries what both OSes consume identically: Nix settings and the toolchain env vocabulary. `host.os` selects the OS branch from the static host context without entering the package fixpoint.
- `modules/darwin/` carries system-scope macOS state: defaults, security (sudoers NOPASSWD allowlist, TCC adjacency), fonts, and the Homebrew bridge. Homebrew carries GUI/proprietary bundles nixpkgs cannot ship; nix-darwin's Brewfile installs missing roster entries while native Homebrew owns metadata, versions, and cleanup. Uninstall/zap stays off so operator installs survive.
- `modules/nixos/` carries the generic VPS baseline: boot and disko, static addressing projected from the host-context network row, key-only SSH, declarative users, and routine Nix maintenance. Work reaches the server through its native `ssh vps` host; no local mount, persistent tunnel, or project service is implied. Nothing Darwin-owned — Homebrew, launchd, macOS defaults — generalizes here.
- `modules/home/` carries user-scope state under Home Manager: XDG hygiene, session environments, program owners, scripts. System and home scopes never mix in one module.
- `overlays/` is the admission gate for upstream packages nixpkgs lacks or pins wrongly: each overlay owns its version, source hash (`nix-prefetch-github`), and build; the flake-level overlay composes them. Admission requires a real consumer now — never anticipatory packaging.
- `services/` owns live service state as code, held to `docs/stacks/typescript/` in full. `package.json` and `pnpm-workspace.yaml` bind the repo-root workspace without per-folder manifests. Existing service domains extend their rows; new domains get one organized owner.
- `services/` workspace commands: `node services/driver.ts preview|up|refresh [--adopt] [--target=<p>/<c>/<token>]` converges the estate; `outputs [--reveal]` projects receipts; `scopes apply|doctor|strict` governs directory-scope resolution; `reviewers` proves the reviewer matrix; `apps` projects the browser-custodied GitHub App census. `services/driver.ts` brokers Pulumi and Doppler credentials from 1Password and resolves `GITHUB_TOKEN` from the agent environment or Doppler.

## [06]-[SECRETS]

Doppler owns project and service configuration; 1Password owns local operator and session custody. Home Manager resolves the mode-600 session cache during activation. Process-specific Doppler consumers invoke `doppler run` or `doppler secrets download` explicitly. Read names with `doppler secrets --project <p> --config <c> --only-names`; add a key in its owning config and wire its process consumer. Topology mutates only through `services/topology.ts` rows. `secrets` owns the custody law.

## [07]-[MCP_FLEET]

`modules/home/programs/shell-tools/mcp-fleet.nix` owns the fleet manifest: each row declares transport, spawn line or endpoint, environment names, ecosystem runner, auth, clients, and host admission. Every switch reconciles host-filtered rows into Claude and Codex while preserving client-private state. `uvx` resolves Python servers, `pnpm dlx` resolves npm servers, `dnx` resolves NuGet, Yak owns Rhino, and providers own remote servers. `forge-mcp doctor` proves wrappers; `forge-mcp drift` proves projections. One row adds or extends a server.

## [08]-[SSH_ESTATE]

One ed25519 key serves everything: custodied in the 1Password Personal vault, served through its agent socket, registered on GitHub for authentication and signing. No private key lands on disk: vault sync is the recovery, and a local copy shadows a dead agent (`scars.md` [02]-[SIGNING]). Commit signing uses SSH format and generated allowed signers. `hosts/context.nix` owns the generic VPS destination and pinned host key; `ssh.nix` projects native OpenSSH, WezTerm, and Yazi SFTP clients. Bounded forwarding uses OpenSSH's own `-L`, `-R`, or `-D` flags instead of a resident service.

## [09]-[DEPLOY_RAIL_AND_AUTOMATION]

`forge-redeploy [--os darwin|nixos] [--host NAME] [--target-host SSH] --check-only|--build|--switch` is the only sanctioned activation path: it locks against concurrent runs, builds, diffs the closure, activates, appends a receipt row (timings, generation, diff size), and pushes the system closure to Cachix when `CACHIX_AUTH_TOKEN` resolves. Darwin activates locally under the sudoers allowlist; NixOS targets deploy over SSH. `forge-accept [--from STEP|--only STEP|--list]` is the post-switch acceptance rail: an ordered, resumable pipeline from preflight through fleet and credential-lane checks to relaunch, receipting pass/warn/fail per step — a switch is done when `forge-accept` exits ok, not when activation returns.

`forge-doctor <lens> [--json]` is the read-only machine doctor standing behind that rail, one lens per question: `path` classifies PATH owners and cross-owner shadows, `launchd` reconciles declared plists against the live `launchctl` table, `parity` diffs the generation's home-files against live `$HOME`, and `updates` projects a currency board from existing receipts. Each lens emits one typed row stream rendering both the human table and `--json`, and drift exits nonzero.

`forge-cleanup plan|apply|sweep` drives the litter registry: `plan` writes a durable precheck receipt, `apply` trashes only plan-proved rows after re-detecting live state, and `sweep` is the hourly orphan lane. Registry rows carry standing policy no first-party tool expresses; storage questions are answered on demand with `dust -d 1 -n 20 -r ~` and each tool's own prune verb.

Recurring machine work is launchd-owned under the `com.parametric-forge.<name>` label grammar, each agent declared beside the surface it serves: `launchctl list | grep com.parametric-forge` is the live census, `launchctl print gui/$UID/com.parametric-forge.<name>` the per-agent probe. Scheduled nix rails double as manual commands and append receipts under `~/Library/Logs/forge-<name>.receipts.log`; a failed rail's receipt governs re-entry. Each new recurring job lands as one agent declaration.

## [10]-[TOOLCHAINS]

- [PYTHON]: 3.15 GIL build; `uv`, `ruff`, `ty`, `mypy` resolve project-local versions first through the shim. `forge-scientific-env` exposes the native build closure — compilers, numeric, columnar, geospatial, messaging, artifact, and point-cloud library folds, each a named list in `languages/scientific-tools.nix` — as the pkg-config, cmake, and library search paths a wheel-less sdist builds against; `forge-python-overlay build|link <venv>|unlink <venv>|status [<venv>]` realizes the uncached nixpkgs python-module env (manifest row `forge-python-overlay-env`) behind an XDG-state GC root and projects it into a uv venv as one `.pth`.
- [NODE_LUA_DB]: Node 26 via the Nix-owned official binary + pnpm pin; Lua with LSP tooling; DuckDB/SQLite with sqlean/spatialite/vec; PostgreSQL 18 client tools are Home Manager-owned, PostgreSQL server extensions stay Docker-owned by `forge-provision`.
- [DOTNET_AEC]: Nix-managed dotnet SDKs (8/9/10); `energyplus` and `openstudio` are Forge-owned machine runtimes with disjoint ambient identities.
- [PROTOBUF]: `protoc` and the `grpc` plugin set (`grpc_csharp_plugin`, `grpc_python_plugin`) are machine-owned and unpinned; the `buf` driver that invokes them stays pinned in the consuming repo's own package manager, never installed here.
- [PROVISIONING]: `forge-provision` (overlay-owned, Home Manager-installed) is the local service provisioner — schema-v3 sanitized JSON, deterministic ports, preserved volumes, noninteractive by contract; `forge-provision --help` is the live verb list. Rasm campaign work enters through its own assay rail; direct calls are Forge-level debugging.
- [MCP_LAUNCHERS]: `nuget-mcp` (.NET 10) and the fleet wrappers are Home Manager-installed; sibling-repo MCP configs invoke them — launcher behavior is fixed here, never in a sibling.

## [11]-[TERMINAL_MESH_AND_THEME]

`modules/home/theme.nix` owns the estate palette and serializes it into every visual consumer. `modules/home/programs/apps/chords.nix` owns the chord vocabulary and projects each row into Karabiner, Zellij, and hint content. `modules/home/scripts/terminal.nix` binds the mesh: WezTerm attaches Zellij, Yazi opens as a floating popup, and edits route into the tab's Neovim RPC socket.

## [12]-[QUALITY_BAR]

| [INDEX] | [SURFACE]       | [STANDARD]                                                                                                      |
| :-----: | :-------------- | :-------------------------------------------------------------------------------------------------------------- |
|  [01]   | Nix             | `docs/laws/design.md` + the machine law pages; `alejandra`/`deadnix`/`statix` gate via `nix flake check`.       |
|  [02]   | Shell source    | `.sh` extension; `set -euo pipefail`; ShellCheck passes.                                                        |
|  [03]   | Shell packaging | `writeShellApplication` for any body with a runtime closure; `writeShellScriptBin` for closure-free one-liners. |
|  [04]   | TypeScript      | `docs/stacks/typescript/` — `services/` code is held to it in full.                                             |
|  [05]   | Python          | `docs/stacks/python/`; 3.15, `uv`-managed, `ruff` + `ty`.                                                       |
|  [06]   | Markdown        | `docs/standards/` prose owners; `prose_gate.py` (docgen skill) is the check + fix rail.                         |
|  [07]   | launchd         | Declared agent rows under the label, log, and lifecycle law; every scheduled rail receipts its own run.        |

## [13]-[GITHUB_AND_SERVICES]

GitHub repository settings for the estate (merge hygiene, rulesets, feature booleans) are `@pulumi/github` rows in `services/topology.ts`; `node driver.ts preview` is the verification surface — repo state is never enumerated in prose or edited in the GitHub UI. GitHub App installation IDs and selection modes live in the same topology as a browser-custodied census: the universal SSH identity owns Git transport and commit signing, while GitHub exposes no SSH-authenticated REST control for app installation selection. Doppler projects, environments, branch configs, and service tokens live as rows in the same file. Code review rides CodeRabbit (`.coderabbit.yaml`) and Greptile (`.greptile/`); the `pr-loop` skill owns hosted-PR round-trips.

## [14]-[FRESH_MACHINE_BOOTSTRAP]

Everything lands declaratively with the first switch; only these steps are manual, each with its proof:

1. Install Determinate Nix via the macOS package — the `curl | sh` installer can die creating the encrypted APFS volume and strand fstab/synthetic.conf residue.
    - Command: `curl -sSfL https://install.determinate.systems/determinate-pkg/stable/Universal -o determinate.pkg && sudo installer -pkg determinate.pkg -target /`
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
6. Grant the bootstrap terminal Full Disk Access (System Settings → Privacy & Security) — `universalaccess` defaults writes abort activation without it; move the grant to WezTerm after the first switch.
    - Verify: the switch's `user defaults` phase passes without `Could not write domain com.apple.universalaccess`
7. First switch — installs the sudoers allowlist every later `forge-redeploy --switch` rides. Installer-written real files at `/etc/pam.d/sudo_local` or `/etc/nix/nix.custom.conf` trip the /etc collision guard: move each aside (`.before-nix-darwin`) and rerun.
    - Command: `sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake .#macbook`
    - Verify: `forge-redeploy --check-only`
8. Approve the TCC/automation prompts macOS raises on first launches: Karabiner driver extension + Input Monitoring, Hammerspoon and LinearMouse Accessibility, and the 1Password autofill pair (AutoFill & Passwords → 1Password on, Apple Passwords off; Privacy & Security → Accessibility → 1Password).
    - Verify: affected agents run without prompting

Day-2 rebuilds: `forge-redeploy --switch`. `nixos-anywhere` with disko bootstraps each NixOS host from its `hosts/context.nix` row; day-2 uses the same rail with `--os nixos --target-host`.

## [15]-[MAINTENANCE]

- Format: `nix fmt -- --check` — full proof: `nix flake check`.
- Acceptance: `forge-accept` after any `--switch`; `--from`/`--only` re-enter a failed step without replaying the pipeline.
- Provisioner: `nix build .#forge-provision`; smoke with `nix run .#forge-provision -- self-test`.
- Inputs: the ordered update sequence in `docs/atlas/rails-and-contracts.md` `[09]-[UPDATE_SEQUENCE]`; closure diffs review through `nvd`/`nix-diff` before switching.
- Fleet: `forge-mcp reconcile claude`, `forge-mcp reconcile codex`, `forge-mcp doctor`, and `forge-mcp drift` after any fleet or client change.
- Discovery: `forge-browse tools` indexes every packaged command with its owner file and its trigger; bare `forge-browse` lists the register domains, and `forge-receipts --verb`/`--sql`/`--audit` queries the receipt plane every rail writes.

MCP launchers resolve server currency through their ecosystem runners at spawn. Every other family moves through the ordered update sequence on demand; `forge-doctor updates` reads existing receipts, local Homebrew currency, and flake-input age.

## [16]-[LICENSE]

MIT — Bardia Samiee
