# Parametric Forge

Parametric Forge owns the machine: one flake owns the macOS workstation — system defaults, GUI apps, CLI tools, fonts, overlays, secrets rails, SSH client config, and cache policy. Consumer repos assume the machine's tools on `PATH` and never import Forge; when shell, toolchain, credential, or wrapper behavior fails in a consumer, the fix lands here. Nothing in this repo couples to a specific project — Forge aligns with consumers, never binds to them.

## [01]-[LAYOUT]

This regenerable topology maps the repository's owning entry points.

```text codemap
Parametric_Forge/
├── Casks/                         # Vendor GUI packages absent from Homebrew's catalog
├── flake.nix                      # Flake inputs, systems, outputs
├── flake.lock
├── flake-modules/                 # nixpkgs instance, host factory, outputs, checks, formatter
├── hosts/
│   └── context.nix                # Host-context row registry
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
│       │   ├── mac-tools/         # Application rows and default handlers
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

`hosts/context.nix` registers `macbook` (aarch64-darwin). Its row carries identity, platform, state versions, and SSH facts; `flake-modules/hosts.nix` projects it into `darwinSystem` on the one perSystem nixpkgs instance (`flake-modules/nixpkgs.nix`, overlay and unfree included) and derives the flake's systems from the rows, and the home graph reads the same row.

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

This machine runs Determinate Nix, not vanilla: Determinate owns the daemon and `/etc/nix/nix.conf` (`eval-cores`, `lazy-trees`, `experimental-features`, its caches). `modules/common/nix.nix` declares only `determinateNix.customSettings` (written to `/etc/nix/nix.custom.conf`), the flake registry, and `determinateNixd` rows; the module rejects `bash-prompt-prefix`, `external-builders`, `extra-nix-path`, `netrc-file`, `ssl-cert-file`, and `upgrade-nix-store-path-url` in custom settings. The registry pins every flake input at its locked revision, so `nix run nixpkgs#x` and `<nixpkgs>` resolve to the nixpkgs the system was built from; ids outside the inputs are spelled as full refs. Every new store path is hard-linked on arrival (`auto-optimise-store`); determinate-nixd's automatic GC frees dead paths in the background, and generation retention runs on demand: `nh clean all --keep 1`.

## [05]-[MODULE_BOUNDARIES]

- `modules/common/` carries Nix settings and the toolchain env vocabulary: one PATH vector and one cross-surface row set, which nix-darwin's `set-environment` writes for every zsh and bash, `launchctl config user path` and the `gui-env` agent replay into the GUI launchd domain, and `.zshenv` asserts as a never-clobber floor. Interactive-only rows stay Home Manager session variables. The shell is Apple's `/bin/zsh` (`forge.shell`); Nix supplies its configuration, not the binary. The time zone is macOS's automatic zone, never a `TZ` row.
- `modules/darwin/` carries system-scope macOS state: defaults, security, and the Homebrew bridge. Homebrew carries GUI/proprietary bundles nixpkgs cannot ship; activation updates Homebrew, installs missing roster entries, and upgrades outdated ones, while cleanup stays with the manual Homebrew pass so operator installs survive.
- `Casks/` owns vendor GUI packages absent from Homebrew's main catalog; Homebrew taps this checkout as `bsamiee/forge` (`modules/darwin/homebrew/`), so a committed cask reaches the next activation without a push.
- Adobe applications remain Creative Cloud-owned; Typeface Beta uses its native vendor updater. `mac-tools/default-applications.nix` owns the application rows (bundle id, path, handled extensions and schemes) that the Dock, LinearMouse, and the utiluti handler reconcile read. `mac-tools/defaults/` owns user-scope macOS defaults as Home Manager `targets.darwin.defaults` rows, imported every switch. `home/fonts.nix` installs the curated catalog through Home Manager's native user font projection and projects its roles into fontconfig's generic families.
- `modules/home/` carries user-scope state under Home Manager: XDG hygiene, session environments, program owners, scripts. System and home scopes never mix in one module.
- `overlays/` is the admission gate for upstream packages nixpkgs lacks or pins wrongly: `manifest.nix` owns admission and recipes consume nvfetcher-generated versions and hashes. Admission requires a real consumer now — never anticipatory packaging.
- `services/` owns live service state as code under the TypeScript quality bar. `package.json` and `pnpm-workspace.yaml` bind the repo-root workspace without per-folder manifests. Existing service domains extend their rows; new domains get one organized owner.
- `services/` workspace commands: `node services/driver.ts preview|up|refresh [--adopt] [--target=<p>/<c>/<token>]` converges the topology; `outputs [--reveal]` prints stack outputs; `scopes` applies the directory-scope rows. `services/driver.ts` brokers Pulumi and Doppler credentials from 1Password and resolves `GITHUB_TOKEN` from the agent environment or Doppler.

## [06]-[SECRETS]

Doppler owns project and service configuration; 1Password owns local operator and session custody. Home Manager resolves the mode-600 session cache during activation. Process-specific Doppler consumers invoke `doppler run` or `doppler secrets download` explicitly. Read names with `doppler secrets --project <p> --config <c> --only-names`; add a key in its owning config and wire its process consumer. Topology mutates only through `services/topology.ts` rows. `secrets` owns the custody law.

## [07]-[SSH]

One ed25519 key serves everything: custodied in the 1Password Personal vault, served through its agent socket, registered on GitHub for authentication and signing. No private key lands on disk: vault sync is the recovery, and a local copy shadows a dead agent. Commit signing uses SSH format and generated allowed signers. `ssh.nix` projects client config alone: the agent socket, signing, and OpenSSH client defaults. Bounded forwarding uses OpenSSH's own `-L`, `-R`, or `-D` flags instead of a resident service.

## [08]-[DEPLOY_RAIL_AND_AUTOMATION]

`redeploy build|switch [nh args]` is the only sanctioned activation path: `nh darwin` builds the host toplevel with nom progress, prints a dix diff against the live system, and on `switch` sets the system profile and activates through the primary user's passwordless sudo. It runs under `cachix watch-exec`, so every locally built path is pushed to Cachix as it lands and a failed build retries from the cache; the push reads the ambient `CACHIX_AUTH_TOKEN` and fails loudly without it.

Probe a machine that misbehaves after a switch before theorizing about it: `which -a <bin>` classifies PATH owners and cross-owner shadows, `launchctl list | grep dev.bsamiee` reconciles the declared agent set against the live table, and `readlink /run/current-system` reads the live generation against `$HOME`. Every probe is read-only, so it opens the investigation rather than closing it.

Recurring machine work is launchd-owned under the `dev.bsamiee.<name>` label grammar, each agent declared beside the surface it serves: `launchctl list | grep dev.bsamiee` is the live census of Forge agents (project tools such as Rasm's pitchfork register their own `dev.mise.*` labels outside it), `launchctl print gui/$UID/dev.bsamiee.<name>` the per-agent probe. Each new recurring job lands as one agent declaration.

`gui-setenv` (`environments/shell.nix`) owns every write into the GUI launchd domain: a replay that changes a value restarts each running `KeepAlive` agent in `~/Library/LaunchAgents`, so a resident process that spawned before the replay, a project tool's included, inherits the replayed rows.

## [09]-[TOOLCHAINS]

- [PYTHON]: no machine interpreter or tool; a project's `mise.toml` and `uv.lock` own `python`, `uv`, `ruff`, `ty`, and `mypy` inside its tree, and none resolves outside one. `languages/scientific-tools.nix` installs the native command-line roster; a project's Pixi environment owns the native libraries its source builds and ctypes consumers read.
- [NODE_LUA_DB]: Node, pnpm, and TypeScript are each project's `mise.toml` and `package.json` rows; Lua with LSP tooling; the SQLite extension libraries (sqlean, spatialite, vec) behind the `sqlite-extended` kernel, while the `sqlite3` and `duckdb` clients are project rows; PostgreSQL 18 client tools are Home Manager-owned.
- [DOTNET_AEC]: No machine .NET SDK and no machine .NET tool; each repo's mise install owns the SDK its `global.json` pins and runs its tools through `dotnet dnx <id>`. Every SDK installs into one shared root (mise `dotnet.dotnet_root`, the root `/etc/dotnet/install_location_arm64` names), so a process that captured `DOTNET_ROOT` or the root's PATH segment reaches each SDK a later `global.json` names. That `dotnet` reaches PATH through the mise shim segment `toolchain-env.nix` puts first on the one PATH vector every session and launchd surface projects, so a login shell, a launchd agent, and a GUI app resolve the pinned SDK without the interactive `mise activate` hook; `roslyn-ls`, the editor's C# server, is the one machine-wide .NET consumer. `energyplus` and `openstudio` are Forge-owned machine runtimes with disjoint ambient identities.

## [10]-[TERMINAL_MESH_AND_THEME]

`modules/home/theme.nix` owns the palette and serializes it into every visual consumer. `modules/home/programs/apps/chords.nix` owns the chord vocabulary and projects each row into Karabiner, Zellij, and hint content. `modules/home/scripts/terminal.nix` binds the mesh: WezTerm attaches Zellij, Yazi opens as a floating popup, and edits route into the tab's Neovim RPC socket, one editor per tab named by the tab id, through blocking Zellij and Neovim primitives rather than retries. A delta `file://<path>:<line>` link and a quick-select `file:line` span both open Neovim at the line in a WezTerm utility float.

## [11]-[QUALITY_BAR]

| [INDEX] | [SURFACE]       | [STANDARD]                                                                                                      |
| :-----: | :-------------- | :-------------------------------------------------------------------------------------------------------------- |
|  [01]   | Nix             | `alejandra`/`deadnix`/`statix`/`nixf-diagnose` gate via treefmt, `statix check` via `nix flake check`.          |
|  [02]   | Shell source    | `.sh` extension; `set -euo pipefail`; ShellCheck passes.                                                        |
|  [03]   | Shell packaging | `writeShellApplication` for any body with a runtime closure; `writeShellScriptBin` for closure-free one-liners. |
|  [04]   | TypeScript      | Effect rails, tagged faults, redacted config, schema decodes at boundaries, pnpm-only.                          |
|  [05]   | Python          | 3.15, `uv`-managed, `ruff` + `ty`.                                                                              |
|  [06]   | Markdown        | `prose_gate.py` (docgen skill) is the check + fix rail.                                                         |
|  [07]   | launchd         | Declared agent rows under the label, log, and lifecycle law, each beside the surface it serves.                 |

## [12]-[GITHUB_AND_SERVICES]

`services/topology.ts` holds Forge's own GitHub repository settings (merge hygiene, rulesets, feature booleans) as `@pulumi/github` rows, and each other repository owns its own; `node driver.ts preview` is the verification surface — repo state is never enumerated in prose or edited in the GitHub UI. Rows in the same file own the shared Doppler projects, environments, branch configs, and service tokens.

## [13]-[FRESH_MACHINE_BOOTSTRAP]

Everything lands declaratively with the first switch; only these steps are manual, each with its proof:

1. Install Determinate Nix via the macOS package — the `curl | sh` installer can die creating the encrypted APFS volume and strand fstab/synthetic.conf residue.
    - Command: `curl -sSfL https://install.determinate.systems/determinate-pkg/stable/Universal -o determinate.pkg && sudo installer -pkg determinate.pkg -target /`
    - Verify: `nix --version` reports Determinate
2. Install the Xcode Command Line Tools and Homebrew via its macOS package — activation's `brew bundle` requires `brew`, the tap and clone below need `git`, and Homebrew's own `brew update` keeps it on the newest stable tag from then on.
    - Command: `xcode-select --install`, then `curl -sSfL https://github.com/Homebrew/brew/releases/latest/download/Homebrew.pkg -o Homebrew.pkg && sudo installer -pkg Homebrew.pkg -target /`
    - Verify: `/opt/homebrew/bin/brew --version` reports the latest release
3. Sign into the 1Password app; enable Settings → Developer → SSH agent + CLI integration. GUI-only by vendor design; key custody syncs from the cloud — zero key handling.
    - Verify: `SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock ssh-add -L` lists the key
4. Clone to the path the deploy rail resolves; the agent socket is explicit until the first switch projects `~/.ssh/config`.
    - Command: `SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock git clone git@github.com:bsamiee/Parametric_Forge.git ~/Developer/Parametric_Forge`
    - Verify: repo present at `~/Developer/Parametric_Forge`
5. Grant the bootstrap terminal Full Disk Access (System Settings → Privacy & Security) — `universalaccess` defaults writes abort activation without it; move the grant to WezTerm after the first switch.
    - Verify: from the granted terminal (WezTerm after the move), `sqlite3 -readonly ~/Library/Application\ Support/com.apple.TCC/TCC.db 'select count(*) from access'` prints a count
6. First switch — installs the passwordless sudo row every later `redeploy switch` rides. Installer-written real files at `/etc/pam.d/sudo_local` or `/etc/nix/nix.custom.conf` trip the /etc collision guard: move each aside (`.before-nix-darwin`) and rerun.
    - Command: `sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake .#macbook`
    - Verify: `redeploy build`
7. Authenticate Doppler from the checkout.
    - Command: `mise install`, then `mise exec -- doppler login`
    - Verify: `mise exec -- doppler me`
8. Grant the manual permission set. Each row is a TCC or system-extension decision with no declarative path on an unmanaged Mac (System Settings → Privacy & Security unless noted):

    | [APP_OR_SERVICE]           | [GRANT]                                                                                                                                            | [WHEN]                                                                                                                |
    | :------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------- | :-------------------------------------------------------------------------------------------------------------------- |
    | Terminal                   | Full Disk Access                                                                                                                                   | Bootstrap only (step 5); remove after WezTerm holds it                                                                |
    | WezTerm                    | Full Disk Access, Accessibility, Input Monitoring, Screen & System Audio Recording, Developer Tools, App Management                                | After the first switch: the responsible process for zsh, zellij, agents, and `redeploy`; App Management lets `copyApps` write `~/Applications/Home Manager Apps` |
    | Karabiner-Elements         | General → Login Items & Extensions → Driver Extensions → Karabiner-DriverKit-VirtualHIDDevice on; Accessibility → Karabiner-Core-Service             | First launch (16.x needs no Input Monitoring)                                                                         |
    | LinearMouse                | Accessibility                                                                                                                                      | First launch                                                                                                          |
    | 1Password                  | Accessibility; AutoFill & Passwords → 1Password on, Passwords off; app Settings → Developer → SSH agent + CLI                                       | Step 2 and first launch                                                                                               |
    | Raycast                    | Accessibility                                                                                                                                      | First launch                                                                                                          |
    | CleanShot X                | Screen & System Audio Recording, Accessibility                                                                                                     | First launch                                                                                                          |
    | Claude (desktop)           | Accessibility, Input Monitoring, Developer Tools                                                                                                   | First launch                                                                                                          |
    | Codex + Codex Computer Use | Codex: Accessibility, Screen & System Audio Recording, Input Monitoring, Developer Tools, Full Disk Access; Codex Computer Use: Accessibility, Screen & System Audio Recording, Full Disk Access | First launch                                                                       |
    | Visual Studio Code         | Developer Tools, Full Disk Access                                                                                                                  | First launch (integrated terminal parity with WezTerm)                                                                |
    | Atelier (Rasm)             | Accessibility, Screen & System Audio Recording; Automation → Atelier → each Adobe app it drives                                                    | First run of each target                                                                                              |
    | Arc, Blender, Rhino, Adobe | Screen & System Audio Recording                                                                                                                    | First capture prompt; the user-defaults owner keeps the periodic screen-capture hint away afterwards                  |
    | calibre, Discord, new casks | Open once, then Privacy & Security → Open Anyway (or the Anywhere confirm, step 9)                                                               | First launch; Homebrew carries the approval across upgrades                                                           |
    | Arc as default browser     | Confirm the "change default browser" dialog                                                                                                        | First switch whose handler reconcile changes `http`                                                                   |

    - Verify: `systemextensionsctl list` shows Karabiner `[activated enabled]`; affected agents run without prompting
9. Confirm the two root settings activation cannot write: Privacy & Security → Allow applications from → Anywhere (`sudo spctl --global-disable` reveals it and exits 1 until confirmed; the choice lands in a SIP-protected file), and Users & Groups → Automatically log in as → the primary user (writes `/etc/kcpassword`, which `autoLoginUser` cannot).
    - Verify: `spctl --status` reports `assessments disabled`; `sysadminctl -autologin status` names the primary user

Day-2 rebuilds: `redeploy switch`.

## [14]-[MAINTENANCE]

- Format: `nix fmt -- --ci` — full proof: `nix flake check`.
- Inputs, in one pass on a clean tree: `sudo determinate-nixd upgrade`, then `nix flake update` and `nix shell .#nvfetcher -c nvfetcher -o overlays/_sources -k =(printf '[keys]\ngithub = "%s"\n' "$(gh auth token)")` together (zsh `=()` hands nvchecker a keyfile every check reads), prune each overlay row nixpkgs caught up to and advance the rest, `biome migrate --write` after a biome bump, one `redeploy switch`, the Homebrew pass, then `nh clean all --keep 1`.

Every family moves through the ordered update sequence on demand; Homebrew currency runs `brew update && brew upgrade && brew cleanup`.
