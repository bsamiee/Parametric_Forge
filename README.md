# Parametric Forge

<div style="padding: 8px 0 12px;">
  <img alt="Nix Flake" src="https://img.shields.io/badge/Nix-Flake-1f2937?style=flat&logo=nixos&logoColor=7e9ad9&labelColor=0b1a2a">
  <img alt="Home Manager" src="https://img.shields.io/badge/Home%20Manager-master-1f2937?style=flat&logo=nixos&logoColor=7e9ad9&labelColor=0b1a2a">
  <img alt="nixpkgs" src="https://img.shields.io/badge/nixpkgs-unstable-1f2937?style=flat&logo=nixos&logoColor=7e9ad9&labelColor=0b1a2a">
  <img alt="Bridge" src="https://img.shields.io/badge/Bridge-nix--darwin%20Homebrew-1f2937?style=flat&logo=homebrew&logoColor=FBB040&labelColor=0b1a2a">
  <img alt="Host" src="https://img.shields.io/badge/Host-nix--darwin-1f2937?style=flat&logo=apple&logoColor=white&labelColor=0b1a2a">
  <img alt="Secrets" src="https://img.shields.io/badge/Secrets-1Password%20SSH-1f2937?style=flat&logo=1password&logoColor=0061FF&labelColor=0b1a2a">
  <img alt="License" src="https://img.shields.io/badge/License-MIT-1f2937?style=flat&logo=github&logoColor=white&labelColor=0b1a2a">
</div>

Parametric Forge is a deterministic macOS workspace built with Nix flakes, nix-darwin, and Home Manager. It targets computational design (Rhino/Grasshopper/BIM), heavy media, and modern development stacks with reproducible tooling, tuned defaults, and strict XDG hygiene.

<div style="padding: 12px 14px; border: 1px solid #1f2937; border-radius: 12px; background: #0b111a;">
  <strong>At a glance</strong>
  <ul style="margin: 0 0 0 18px;">
    <li><strong>Scope:</strong> One flake drives macOS defaults, GUI apps, CLI tools, fonts, overlays, provisioning, and cache policy.</li>
    <li><strong>Secrets:</strong> Doppler-first agent env with 1Password SSH + transitional ambient rail; credentials never enter the repo; GitHub CLI auth state stays mutable.</li>
    <li><strong>Terminal mesh:</strong> WezTerm → Zellij → Yazi with Neovim remote control, Starship, Atuin, fzf-tab, and carapace.</li>
    <li><strong>Toolchains:</strong> Python 3.15 (uv/ruff/ty), Node (nix + pnpm), Lua + LSPs, SQLite/DuckDB with sqlean/spatialite/vec, scientific native libs and energy-modeling runtimes, Nix-managed dotnet SDKs (8/9/10).</li>
    <li><strong>Assets:</strong> Repo media ships as plain git blobs kept preview-small — never LFS; ffmpeg/imagemagick tuned for previews.</li>
  </ul>
</div>

---

## Layout
```text
.
├── flake.nix / flake.lock          # Inputs, systems, overlays, host exports
├── flake-modules/                  # Package/app outputs, checks, dev shell, formatter
├── docs/                           # Stack atlases (python/typescript) + docs/standards law
├── hosts/
│   ├── darwin/default.nix          # MacBook host: nix-darwin + Home Manager
│   └── nixos/default.nix           # NixOS host rows (Maghz lands here)
├── modules/
│   ├── common/                     # Determinate Nix custom settings + shared toolchain env
│   ├── darwin/                     # macOS defaults, fonts, homebrew taps/brews/casks
│   └── home/                       # Home Manager: XDG, env, aliases, theme, programs, scripts, assets
│       ├── assets/                 # Fastfetch ASCII art + wallpaper
│       ├── environments/           # Session vars: core/shell/languages/development/applications/containers/media
│       ├── programs/               # Apps (wezterm/zellij/yazi/nvim/vscode/karabiner) + container/git/language/mac/media/nix/shell tool owners + zsh
│       ├── scripts/                # Integration rail (forge-nvim/edit/yazi) + analysis helpers
│       └── xdg.nix                 # XDG base dirs + Linux user-dir rows
├── overlays/                       # Version pins (node/pnpm/gcloud) + carbon compat + duckdb, energyplus, forge-provision, openstudio, sqlean, sqlite-forge
├── services/                       # Doppler estate topology + Pulumi Automation API driver (TypeScript)
└── .archive/                       # Retired configs kept for reference
```

---

## Quick Start
1. **Install Nix (Determinate):**
   ```sh
   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
   ```
2. **Sign into 1Password CLI:**
   ```sh
   op signin <account>
   ```
3. **Clone (the path `forge-redeploy` resolves as `FORGE_ROOT`):**
   ```sh
   git clone https://github.com/bsamiee/Parametric_Forge.git ~/Documents/99.Github/Parametric_Forge
   ```
4. **Apply mac host:**
   ```sh
   sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake ~/Documents/99.Github/Parametric_Forge#macbook
   ```
5. **Rebuild after edits:**
   ```sh
   forge-redeploy --switch
   ```

---

## Secrets + SSH
- **Secret references:** `modules/home/programs/shell-tools/1password.nix` owns the `~/.config/op/env.template` template and token cache refresh.
- **Invocation:** `op run --env-file ~/.config/op/env.template -- <command>` keeps secrets out of git.
- **Agent sessions:** `.claude/hooks/setup-env.sh` resolves agent env Doppler-first across the project/config sources it declares, writes a mode-600 env file, and refreshes cached fallback snapshots under `~/.cache/doppler`; the 1Password ambient rail coexists until the explicit Doppler cutover.
- **MCP fleet:** `modules/home/programs/shell-tools/mcp-fleet.nix` is the declarative fleet manifest; `mcp-launchers.nix` builds the pinned wrappers from it and ships `forge-mcp` (`outdated`, `doctor`, `drift`) as the fleet health surface.
- **SSH agent:** `modules/home/programs/shell-tools/ssh.nix` points to `~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock`.
- **GitHub CLI:** `modules/home/programs/git-tools/gh.nix` declares `config.yml`; `hosts.yml` stays mutable for auth state, and headless auth rides `GH_TOKEN` from the secrets rail.

---

## Terminal Mesh (WezTerm ↔ Zellij ↔ Yazi ↔ Neovim)
- **WezTerm:** Lua modules (`modules/home/programs/apps/wezterm`) split appearance/keys/mouse/behavior/integration; auto-attaches to Zellij sessions.
- **Zellij:** `modules/home/programs/apps/zellij` ships Dracula palette, layouts, and `zjstatus`; one color map reused by theme and plugins.
- **Yazi:** `modules/home/programs/apps/yazi` themed to match; the integration rail (`modules/home/scripts/integration`) runs Yazi as a floating Zellij popup (`forge-yazi.sh`) and sets `EDITOR=forge-edit.sh` so Yazi hands edits to Neovim.
  - `forge-edit.sh` reuses the tab's live editor over per-pane `nvim --listen` RPC sockets and ID-based Zellij pane focus, or spawns a fresh `forge-nvim.sh` editor pane.
- **Shell:** Zsh with fzf-tab, Atuin history, carapace completions, Starship, zoxide, delta pager; session paths/XDG caches tuned in `modules/home/environments/*`.

---

## Tooling Suite
<div style="padding: 12px 14px; border: 1px solid #1f2937; border-radius: 12px; background: #0b111a;">
  <details>
  <summary>Nix, hosts, cache</summary>

  - **Daemon:** Determinate Nix owns the macOS daemon and `/etc/nix/nix.conf`; `modules/common/nix.nix` declares the custom settings the Determinate module writes to `/etc/nix/nix.custom.conf`.
  - **Overlay:** `overlays/default.nix` owns Forge packages and pins: DuckDB CLI, EnergyPlus/OpenStudio, `forge-provision`, `sqlean`/`sqlite-forge`, Node/pnpm/gcloud pins, and Carbon compatibility.
  - **Host binding:** `hosts/darwin/default.nix` wires nix-darwin, Home Manager, the nix-darwin Homebrew module, and user state versions.
  </details>

  <details>
  <summary>Git + security</summary>

  - **VCS stack:** Delta pager everywhere, lazygit, gitleaks, git-quick-stats (`modules/home/programs/git-tools`); the Git LFS client serves external LFS repos only — this repo tracks none.
  - **SSH:** Multiplexing + sockets in `~/.ssh/sockets`; 1Password agent for keys.
  </details>

  <details>
  <summary>Languages</summary>

  - **Python:** 3.15 GIL build with uv, ruff, ty, mypy, and `forge-scientific-env`; ruff/ty/mypy resolve project-local versions first through the shim — ruff/ty fall back to Nix builds, mypy to the newest release through uv's tool cache; caches under XDG (`modules/home/environments/languages.nix`). `MACOSX_DEPLOYMENT_TARGET` follows the stdenv Darwin platform minimum, currently `14.0`.
  - **Node/Lua/DB:** Node 26 via Nix-owned official Darwin binary + pnpm; Prettier; Lua + LSP tooling; DuckDB/SQLite with sqlean/spatialite/vec; PostgreSQL 18 host tools are client-owned (`psql`, `pg_dump`, `pg_restore`, `pg_isready`, SQLFluff, pgformatter, and Postgres LSP). PostgreSQL server extensions stay Docker-owned by `forge-provision`, including Timescale, PostGIS, pgvector/vectorscale, ParadeDB `pg_search`, optional `pg_duckdb`, and Timescale-side `pg_cron` verification.
  - **Scientific + provisioning:** `forge-scientific-sync` creates a locked isolated XDG-state uv environment from root project dependencies with default groups disabled, while `forge-scientific-env` exposes clang, gfortran, GDAL, GEOS, PROJ, HDF5, netCDF, Arrow, OpenBLAS, ONNX Runtime, artifact native libraries, Eigen, PDAL, Boost, EnergyPlus, and OpenStudio for one-off source builds and energy-modeling companion work. EnergyPlus is a Forge-owned machine runtime, not a Python or NuGet package; `energyplus` resolves to the standalone runtime and owns the ambient `ENERGYPLUS*` identity, while `openstudio` resolves to the OpenStudio SDK CLI and runs its release-paired bundled EnergyPlus by relative path without touching the ambient identity. `forge-companion-env` uses Python 3.12 for companion tooling that Rasm gates below the Python 3.15 core. `forge-provision` is the overlay-owned, Home Manager-installed local provisioning command with schema v3 safe JSON, auto-root hidden credentials, deterministic auto ports, preserved volumes on `down`, Timescale `pg_cron` apply support, and optional `pgduckdb` behind `FORGE_PROVISION_PGDUCKDB=1`; use `forge-provision --help` for the live verb list. The MCP and server launchers `forge-ifcmcp` (IfcOpenShell MCP, cp312 lane), `forge-jupyter` (a persistent JupyterLab LaunchAgent on `127.0.0.1:8888`), `forge-jupyter-mcp` (its MCP connector), and `nuget-mcp` (NuGet MCP via the .NET 10 SDK) are Home Manager-installed wrappers consumed by the sibling repos' `ifc`/`jupyter`/`nuget` MCP surfaces.
  </details>

  <details>
  <summary>Media + documents</summary>

  - **Tooling:** ffmpeg, imagemagick, resvg, chafa, mediainfo, qpdf, poppler, djvulibre, inkscape, and pandoc with cache/log paths under XDG.
  - **Config:** Environment knobs in `modules/home/environments/media.nix`.
  </details>

  <details>
  <summary>Homebrew bridge</summary>

  - **Bridge:** `modules/darwin/homebrew` uses the nix-darwin Homebrew module for GUI/proprietary/macOS app bundles and fonts not in nixpkgs. Activation installs and refreshes metadata only; version freshness is a repo-declared schedule — the `forge-brew-autoupdate` reconciler keeps the domt4/autoupdate agent on a daily update+upgrade+cleanup cadence with keychain-backed sudo. Uninstall/zap stays off so operator-installed tools survive.
  </details>
</div>

---

## Maintenance
<div style="padding: 12px 14px; border: 1px solid #1f2937; border-radius: 12px; background: #0b111a;">
  <ul style="margin: 0 0 0 18px;">
    <li><strong>Format check:</strong> <code>nix fmt -- --check</code></li>
    <li><strong>Full flake proof:</strong> <code>nix flake check</code></li>
    <li><strong>Provisioner build:</strong> <code>nix build .#forge-provision</code></li>
    <li><strong>Provisioner smoke:</strong> <code>nix run .#forge-provision -- self-test</code>, plus read-only JSON smoke for <code>env</code>, <code>plan</code>, and <code>extensions</code> when touching provisioning</li>
    <li><strong>Host activation:</strong> <code>forge-redeploy --switch</code> from the repository root after the wrapper proof and closure diff are reviewed</li>
    <li><strong>Update inputs:</strong> <code>nix flake update</code></li>
    <li><strong>Cache push:</strong> <code>forge-redeploy --build|--switch</code> pushes the system closure to Cachix when <code>CACHIX_AUTH_TOKEN</code> resolves; absent token degrades to a skipped push</li>
  </ul>
</div>

## License
MIT © [Bardia Samiee](https://github.com/bsamiee)
