# Parametric Forge

Parametric Forge owns the machine: one flake owns the macOS workstation — system defaults, GUI apps, CLI tools, fonts, overlays, secrets rails, SSH client config, and cache policy. Consumer repos assume the machine's tools on `PATH` and never import Forge; when shell, toolchain, credential, or wrapper behavior fails in a consumer, the fix lands here. Nothing in this repo couples to a specific project — Forge aligns with consumers, never binds to them.

## [01]-[LAYOUT]

This regenerable topology maps the repository's owning entry points.

```text codemap
Parametric_Forge/
├── Casks/                         # Vendor GUI packages absent from Homebrew's catalog
├── flake.nix                      # Flake inputs, systems, outputs
├── flake.lock
├── flake-modules/                 # Outputs, checks, formatter, development shell
├── hosts/
│   ├── context.nix                # Host-context row registry
│   └── default.nix                # Host factory and system projection
├── modules/
│   ├── common/                    # Shared Nix settings and toolchain environment
│   ├── darwin/
│   │   ├── settings/              # Root-scope macOS defaults, security, launchd environment
│   │   └── homebrew/              # Homebrew bridge
│   └── home/
│       ├── aliases/               # Shell alias registry
│       ├── assets/
│       │   └── ascii/             # Fetch banner assets
│       ├── environments/          # Cross-tool environment projections
│       ├── programs/
│       │   ├── apps/
│       │   │   ├── karabiner/     # Leader-chord keyboard layer
│       │   │   ├── linearmouse/   # External-mouse schemes
│       │   │   ├── nvim/          # Editor
│       │   │   ├── wezterm/       # Terminal host
│       │   │   ├── yazi/          # File manager
│       │   │   └── zellij/        # Multiplexer layouts and themes
│       │   ├── container-tools/
│       │   ├── git-tools/
│       │   ├── languages/         # Language toolchains
│       │   ├── mac-tools/         # Default applications
│       │   │   └── defaults/      # User-scope macOS defaults
│       │   ├── media-tools/
│       │   ├── nix-tools/
│       │   ├── shell-tools/       # CLI kernels, SSH, secrets
│       │   └── zsh/
│       └── scripts/               # Integration and analysis kernels
├── overlays/                      # Manifest-folded package admissions
├── services/                      # Doppler and GitHub IaC rows
└── .claude/                       # Harness commands and skills
```

## [02]-[HOSTS]

`hosts/context.nix` registers `macbook` (aarch64-darwin). Its row carries identity, platform, state versions, and SSH facts; `hosts/default.nix` projects it into `darwinSystem`, and the home graph reads the same row.

## [03]-[DECISION_FRAMEWORK]

Rulings derive from principles, not precedent lists. These axes resolve each new situation:

| [INDEX] | [AXIS]                 | [LAW]                                                                                                          |
| :-----: | :--------------------- | :------------------------------------------------------------------------------------------------------------- |
|  [01]   | Greenfield-only        | Every touched surface rebuilds to the best current shape; no compatibility layer of any kind survives.         |
|  [02]   | One owner per axis     | One declaring file per concern; a second copy of any fact is a fork — extend the owner, never add files.       |
|  [03]   | Rows over hardcodes    | Capability lands as a parameterized row on the owning table; a new host, package, or service is one row.       |
|  [04]   | Polymorphic collapse   | Density rises inside the owning file — merged types, dispatch tables, folds — never by extraction.             |
|  [05]   | IaC over YAML          | Pulumi rows in `services/` own Forge's repo and shared Doppler projects; each repo owns its GitHub settings.   |
|  [06]   | Currency as review     | Newest stable everything; a pin exists only with a named incompatibility and dies when compatibility lands.    |
|  [07]   | No LFS                 | Repo media ships as plain git blobs kept preview-small; a project using LFS pins `git-lfs` in its `mise.toml`. |
|  [08]   | Aesthetics first-class | Visual surfaces (theme, prompt, TUI, fonts) are designed systems with single palette ownership.                |

## [04]-[DETERMINATE_NIX]

This machine runs Determinate Nix, not vanilla: Determinate owns the daemon and `/etc/nix/nix.conf` (`eval-cores`, `lazy-trees`, `netrc-file`, `ssl-cert-file`, `experimental-features`). `modules/common/nix.nix` declares only the custom settings `determinateNix.customSettings` writes to `/etc/nix/nix.custom.conf` — Determinate-owned keys are rejected there by construction. GC and store maintenance run on demand: `sudo -H nix-env -p /nix/var/nix/profiles/system --delete-generations old`, then `nix-collect-garbage -d` and `nix store optimise`.

## [05]-[MODULE_BOUNDARIES]

- `modules/common/` carries Nix settings and the toolchain env vocabulary.
- `modules/darwin/` carries system-scope macOS state: defaults, security, and the Homebrew bridge. Homebrew carries GUI/proprietary bundles nixpkgs cannot ship; activation updates Homebrew, installs missing roster entries, and upgrades outdated ones, while cleanup stays with the manual Homebrew pass so operator installs survive.
- `Casks/` owns vendor GUI packages absent from Homebrew's main catalog; `modules/darwin/homebrew/` projects their installation through the `bsamiee/forge` tap.
- Adobe applications remain Creative Cloud-owned; Typeface Beta uses its native vendor updater. `mac-tools/default-applications.nix` owns exact native handlers through utiluti. `home/fonts.nix` installs the curated catalog through Home Manager's native user font projection.
- `modules/home/` carries user-scope state under Home Manager: XDG hygiene, session environments, program owners, scripts. System and home scopes never mix in one module.
- `overlays/` is the admission gate for upstream packages nixpkgs lacks or pins wrongly: `manifest.nix` owns admission and recipes consume nvfetcher-generated versions and hashes. Admission requires a real consumer now — never anticipatory packaging.
- `services/` owns live service state as code under the TypeScript quality bar. `package.json` and `pnpm-workspace.yaml` bind the repo-root workspace without per-folder manifests. Existing service domains extend their rows; new domains get one organized owner.
- `services/` workspace commands: `node services/driver.ts preview|up|refresh [--adopt] [--target=<p>/<c>/<token>]` converges the topology; `outputs [--reveal]` prints stack outputs; `scopes` applies the directory-scope rows. `services/driver.ts` brokers Pulumi and Doppler credentials from 1Password and resolves `GITHUB_TOKEN` from the agent environment or Doppler.

## [06]-[SECRETS]

Doppler owns project and service configuration; 1Password owns local operator and session custody. Home Manager resolves the mode-600 session cache during activation. Process-specific Doppler consumers invoke `doppler run` or `doppler secrets download` explicitly. Read names with `doppler secrets --project <p> --config <c> --only-names`; add a key in its owning config and wire its process consumer. Topology mutates only through `services/topology.ts` rows. `secrets` owns the custody law.

## [07]-[MCP_SERVERS]

MCP servers are project-owned, never Forge-owned: each repository registers its servers with their upstream commands in its own `.mcp.json` and `.codex/config.toml`, and a machine-wide server rides the client's own user config. Forge provisions no MCP server, package, wrapper, launcher, credential directory, or `~/.claude.json` entry.

## [08]-[SSH]

One ed25519 key serves everything: custodied in the 1Password Personal vault, served through its agent socket, registered on GitHub for authentication and signing. No private key lands on disk: vault sync is the recovery, and a local copy shadows a dead agent. Commit signing uses SSH format and generated allowed signers. `ssh.nix` projects client config alone: the agent socket, signing, and OpenSSH client defaults. Bounded forwarding uses OpenSSH's own `-L`, `-R`, or `-D` flags instead of a resident service.

## [09]-[DEPLOY_RAIL_AND_AUTOMATION]

`redeploy [--host NAME] [--build|--switch]` is the only sanctioned activation path: it runs `nix flake check`, builds the per-host toplevel with `--keep-going` to a stable out-link under `$XDG_STATE_HOME/redeploy`, diffs it against the live system with `nvd`, activates it locally through the primary user's passwordless sudo, and pushes it to Cachix when `CACHIX_AUTH_TOKEN` resolves. `--build` is the default; `--switch` activates the toplevel a previous `--build` linked without building it again, and a failed build resumes from the store.

Probe a machine that misbehaves after a switch before theorizing about it: `which -a <bin>` classifies PATH owners and cross-owner shadows, `launchctl list | grep dev.bsamiee` reconciles the declared agent set against the live table, and `readlink /run/current-system` reads the live generation against `$HOME`. Every probe is read-only, so it opens the investigation rather than closing it.

Recurring machine work is launchd-owned under the `dev.bsamiee.<name>` label grammar, each agent declared beside the surface it serves: `launchctl list | grep dev.bsamiee` is the live census, `launchctl print gui/$UID/dev.bsamiee.<name>` the per-agent probe. Each new recurring job lands as one agent declaration.

## [10]-[TOOLCHAINS]

- [PYTHON]: no machine interpreter or tool; a project's `mise.toml` and `uv.lock` own `python`, `uv`, `ruff`, `ty`, and `mypy` inside its tree, and none resolves outside one. `languages/scientific-tools.nix` installs the native command-line roster; a project's Pixi environment owns the native libraries its source builds and ctypes consumers read.
- [NODE_LUA_DB]: Node, pnpm, and TypeScript are each project's `mise.toml` and `package.json` rows; Lua with LSP tooling; the SQLite extension libraries (sqlean, spatialite, vec) behind the `sqlite-extended` kernel, while the `sqlite3` and `duckdb` clients are project rows; PostgreSQL 18 client tools are Home Manager-owned.
- [DOTNET_AEC]: No machine .NET SDK and no machine .NET tool; each repo's mise install owns the SDK its `global.json` pins and runs its tools through `dotnet dnx <id>`. Every SDK installs into one shared root (mise `dotnet.dotnet_root`, the root `/etc/dotnet/install_location_arm64` names), so a process that captured `DOTNET_ROOT` or the root's PATH segment reaches each SDK a later `global.json` names. That `dotnet` reaches PATH through the mise shim segment `toolchain-env.nix` puts first on the one PATH vector every session and launchd surface projects, so a login shell, a launchd agent, and a GUI app resolve the pinned SDK without the interactive `mise activate` hook; `roslyn-ls`, the editor's C# server, is the one machine-wide .NET consumer. `energyplus` and `openstudio` are Forge-owned machine runtimes with disjoint ambient identities.

## [11]-[TERMINAL_MESH_AND_THEME]

`modules/home/theme.nix` owns the palette and serializes it into every visual consumer. `modules/home/programs/apps/chords.nix` owns the chord vocabulary and projects each row into Karabiner, Zellij, and hint content. `modules/home/scripts/terminal.nix` binds the mesh: WezTerm attaches Zellij, Yazi opens as a floating popup, and edits route into the tab's Neovim RPC socket.

## [12]-[QUALITY_BAR]

| [INDEX] | [SURFACE]       | [STANDARD]                                                                                                      |
| :-----: | :-------------- | :-------------------------------------------------------------------------------------------------------------- |
|  [01]   | Nix             | `alejandra`/`deadnix`/`statix` gate via `nix flake check`.                                                      |
|  [02]   | Shell source    | `.sh` extension; `set -euo pipefail`; ShellCheck passes.                                                        |
|  [03]   | Shell packaging | `writeShellApplication` for any body with a runtime closure; `writeShellScriptBin` for closure-free one-liners. |
|  [04]   | TypeScript      | Effect rails, tagged faults, redacted config, schema decodes at boundaries, pnpm-only.                          |
|  [05]   | Python          | 3.15, `uv`-managed, `ruff` + `ty`.                                                                              |
|  [06]   | Markdown        | `prose_gate.py` (docgen skill) is the check + fix rail.                                                         |
|  [07]   | launchd         | Declared agent rows under the label, log, and lifecycle law, each beside the surface it serves.                 |

## [13]-[GITHUB_AND_SERVICES]

`services/topology.ts` holds Forge's own GitHub repository settings (merge hygiene, rulesets, feature booleans) as `@pulumi/github` rows, and each other repository owns its own; `node driver.ts preview` is the verification surface — repo state is never enumerated in prose or edited in the GitHub UI. Rows in the same file own the shared Doppler projects, environments, branch configs, and service tokens.

## [14]-[FRESH_MACHINE_BOOTSTRAP]

Everything lands declaratively with the first switch; only these steps are manual, each with its proof:

1. Install Determinate Nix via the macOS package — the `curl | sh` installer can die creating the encrypted APFS volume and strand fstab/synthetic.conf residue.
    - Command: `curl -sSfL https://install.determinate.systems/determinate-pkg/stable/Universal -o determinate.pkg && sudo installer -pkg determinate.pkg -target /`
    - Verify: `nix --version` reports Determinate
2. Sign into the 1Password app; enable Settings → Developer → SSH agent + CLI integration. GUI-only by vendor design; key custody syncs from the cloud — zero key handling.
    - Verify: `SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock ssh-add -L` lists the key
3. Clone to the path the deploy rail resolves; the agent socket is explicit until the first switch projects `~/.ssh/config`.
    - Command: `SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock git clone git@github.com:bsamiee/Parametric_Forge.git ~/Developer/Parametric_Forge`
    - Verify: repo present at `~/Developer/Parametric_Forge`
4. Grant the bootstrap terminal Full Disk Access (System Settings → Privacy & Security) — `universalaccess` defaults writes abort activation without it; move the grant to WezTerm after the first switch.
    - Verify: the switch's Home Manager `onChange` import of `com.apple.universalaccess` passes without `Could not write domain com.apple.universalaccess`
5. First switch — installs the passwordless sudo row every later `redeploy --switch` rides. Installer-written real files at `/etc/pam.d/sudo_local` or `/etc/nix/nix.custom.conf` trip the /etc collision guard: move each aside (`.before-nix-darwin`) and rerun.
    - Command: `sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake .#macbook`
    - Verify: `redeploy --build`
6. Authenticate Doppler from the checkout.
    - Command: `mise install`, then `mise exec -- doppler login`
    - Verify: `mise exec -- doppler me`
7. Approve the TCC/automation prompts macOS raises on first launches: Karabiner driver extension + Input Monitoring, LinearMouse Accessibility, and the 1Password autofill pair (AutoFill & Passwords → 1Password on, Apple Passwords off; Privacy & Security → Accessibility → 1Password).
    - Verify: affected agents run without prompting

Day-2 rebuilds: `redeploy --switch`.

## [15]-[MAINTENANCE]

- Format: `nix fmt -- --ci` — full proof: `nix flake check`.
- Inputs, in order, each proven before the next: clean working tree, `nix flake update` proven by `redeploy --build`, `nix develop -c nvfetcher -o overlays/_sources`, `redeploy --switch`, the Homebrew pass, then the store trim; closure diffs review through `nvd`/`nix-diff` before switching.

Every family moves through the ordered update sequence on demand; Homebrew currency runs `brew update && brew upgrade && brew upgrade --greedy-latest wezterm@nightly blender@daily && brew cleanup`.

## [16]-[LICENSE]

MIT — Bardia Samiee
