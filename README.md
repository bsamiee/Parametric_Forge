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
    <li><strong>Secrets:</strong> 1Password-backed secrets + SSH keep credentials out of the repo; GitHub CLI stays writable.</li>
    <li><strong>Terminal mesh:</strong> WezTerm → Zellij → Yazi with Neovim remote control, Starship, Atuin, fzf-tab, and carapace.</li>
    <li><strong>Toolchains:</strong> Python 3.15 (uv/ruff/ty), Node (nix + pnpm), Lua + LSPs, SQLite/DuckDB with sqlean/spatialite/vec, scientific native libs, Nix-managed dotnet SDKs (8/9/10).</li>
    <li><strong>Assets:</strong> CAD/BIM/media formats stay versionable via LFS defaults; ffmpeg/imagemagick tuned for previews.</li>
  </ul>
</div>

---

## Layout
```text
.
├── flake.nix / flake.lock          # Inputs, systems, overlays, host exports
├── flake-modules/                  # Package/app outputs, checks, devshell, formatter
├── checks/                         # Bats suites for package behavior
├── hosts/
│   └── darwin/default.nix          # MacBook host: nix-darwin + Home Manager
├── modules/
│   ├── common/                     # Nix daemon perf/cache + Cachix post-build hook
│   ├── darwin/                     # macOS defaults, fonts, homebrew taps/brews/casks
│   └── home/                       # Home Manager: XDG, env, aliases, programs, scripts, assets
│       ├── assets/                 # ASCII + carbon sources/renders
│       ├── environments/           # Session vars for shell/languages/media/secrets/containers
│       ├── programs/               # Apps (wezterm/zellij/yazi), shell-tools, git-tools, nix-tools, zsh
│       ├── scripts/                # Integration wrappers (nvim/zellij/yazi)
│       └── xdg.nix                 # XDG base dirs + scaffolding
├── overlays/                       # Upstream passthrough + duckdb, rasm-provision, sqlean
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
3. **Clone:**
   ```sh
   git clone https://github.com/bsamiee/Parametric_Forge.git ~/Parametric_Forge
   ```
4. **Apply mac host:**
   ```sh
  nix run nix-darwin -- switch --flake ~/Parametric_Forge#macbook
   ```
5. **Rebuild after edits:**
   ```sh
  cd ~/Parametric_Forge
  sudo darwin-rebuild switch --flake .#macbook |& nom
   ```

---

## Secrets + SSH
- **Secret references:** `modules/home/environments/secrets.nix`; template written by `modules/home/xdg.nix` to `~/.config/op/env.template`.
- **Invocation:** `op run --env-file ~/.config/op/env.template -- <command>` keeps secrets out of git.
- **SSH agent:** `modules/home/programs/shell-tools/ssh.nix` points to `~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock`.
- **GitHub CLI:** stays writable because `~/.config/gh` is unmanaged by Home Manager.

---

## Terminal Mesh (WezTerm ↔ Zellij ↔ Yazi ↔ Neovim)
- **WezTerm:** Lua modules (`modules/home/programs/apps/wezterm`) split appearance/keys/mouse/behavior/integration; auto-attaches to Zellij sessions.
- **Zellij:** `modules/home/programs/apps/zellij` ships Dracula palette, layouts, and `zjstatus`; one color map reused by theme and plugins.
- **Yazi:** `modules/home/programs/apps/yazi` themed to match; wrapper scripts (`modules/home/scripts/integration/zellij`) set `EDITOR=forge-edit.sh` so Yazi hands edits to Neovim.
  - `forge-edit.sh` uses per-session nvr sockets; WezTerm focuses the adjacent pane before sending files.
- **Shell:** Zsh with fzf-tab, Atuin history, carapace completions, Starship, zoxide, delta pager; session paths/XDG caches tuned in `modules/home/environments/*`.

---

## Tooling Suite
<div style="padding: 12px 14px; border: 1px solid #1f2937; border-radius: 12px; background: #0b111a;">
  <details>
  <summary>Nix, hosts, cache</summary>

  - **Daemon:** `modules/common/nix.nix` tunes eval/build parallelism, HTTP/2, cache TTLs, and post-build Cachix push.
  - **Overlay:** `overlays/default.nix` forwards upstream overlays and adds the DuckDB CLI overlay, `rasm-provision`, and `sqlean` SQLite extensions.
  - **Host binding:** `hosts/darwin/default.nix` wires nix-darwin, Home Manager, the nix-darwin Homebrew module, and user state versions.
  </details>

  <details>
  <summary>Git + security</summary>

  - **VCS stack:** Delta pager everywhere, LFS patterns for CAD/BIM/media, lazygit, gitleaks, git-quick-stats (`modules/home/programs/git-tools`).
  - **SSH:** Multiplexing + sockets in `~/.ssh/sockets`; 1Password agent for keys.
  </details>

  <details>
  <summary>Languages</summary>

  - **Python:** 3.15 GIL build with uv, ruff, ty, basedpyright, and `forge-scientific-env`; caches under XDG (`modules/home/environments/languages.nix`). `MACOSX_DEPLOYMENT_TARGET` follows the nix-darwin minimum and is currently `14.0`.
  - **Node/Lua/DB:** Node via nix + pnpm (npm is aliased to pnpm for consistency); Lua + LSP tooling; DuckDB/SQLite with sqlean/spatialite/vec; PostgreSQL 18 host tools are client-owned (`psql`, `pg_dump`, `pg_restore`, `pg_isready`, `pg_config`, SQLFluff, and Postgres LSP). PostgreSQL server extensions stay Docker-owned by `rasm-provision`, including Timescale, PostGIS, pgvector/vectorscale, ParadeDB `pg_search`, optional `pg_duckdb`, and Timescale-side `pg_cron` verification.
  - **Scientific + provisioning:** `forge-scientific-sync` creates a locked isolated `.venv-scientific` from the scientific dependency group, while `forge-scientific-env` exposes clang, gfortran, GDAL, GEOS, PROJ, HDF5, netCDF, Arrow, OpenBLAS, ONNX Runtime, artifact native libraries, Eigen, PDAL, and Boost for one-off source builds. `forge-companion-env` provides the Python 3.12 native-build lane for companion tooling. `rasm-provision` is the overlay-owned, Home Manager-installed local provisioning command with schema v2 safe JSON, auto-root hidden credentials, deterministic auto ports, preserved volumes on `down`, Timescale `pg_cron` verification support, and optional `pgduckdb` behind `RASM_PROVISION_PGDUCKDB=1`; use `rasm-provision --help` for the live verb list.
  </details>

  <details>
  <summary>Media + documents</summary>

  - **Tooling:** ffmpeg, imagemagick, resvg, chafa, mediainfo, ocrmypdf, pandoc with cache/log paths under XDG.
  - **Config:** Environment knobs in `modules/home/environments/media.nix`.
  </details>

  <details>
  <summary>Homebrew bridge</summary>

  - **Bridge:** `modules/darwin/homebrew` uses the nix-darwin Homebrew module for taps/brews/casks (Raycast, BTT, Arc, Adobe CC, fonts not in nixpkgs, yabai/skhd/borders). Activation does not auto-update or upgrade Homebrew; upgrades are explicit operator actions.
  </details>
</div>

---

## Code Examples


**SSH via 1Password agent:**

  ![SSH via 1Password agent](modules/home/assets/carbon/ssh-1password.png)

**Zsh gh wrapper with 1Password:**

  ![Zsh gh wrapper with 1Password](modules/home/assets/carbon/zsh-gh-wrapper.png)

**Zellij Dracula palette:**

  ![Zellij Dracula palette](modules/home/assets/carbon/zellij-dracula.png)

**WezTerm appearance:**

  ![WezTerm appearance](modules/home/assets/carbon/wezterm-appearance.png)

**Forge edit/yazi integration:**

  ![Forge edit/yazi integration](modules/home/assets/carbon/forge-edit-wrapper.png)

---

## Maintenance
<div style="padding: 12px 14px; border: 1px solid #1f2937; border-radius: 12px; background: #0b111a;">
  <ul style="margin: 0 0 0 18px;">
    <li><strong>Format check:</strong> <code>nix fmt -- --check</code></li>
    <li><strong>Full flake proof:</strong> <code>nix flake check</code></li>
    <li><strong>Provisioner build:</strong> <code>nix build .#rasm-provision</code></li>
    <li><strong>Provisioner smoke:</strong> <code>nix run .#rasm-provision -- self-test</code>, plus read-only JSON smoke for <code>env</code>, <code>plan</code>, and <code>extensions</code> when touching provisioning</li>
    <li><strong>Host activation:</strong> <code>sudo darwin-rebuild switch --flake .#macbook |& nom</code> from the repository root after the system build and closure diff are reviewed</li>
    <li><strong>Update inputs:</strong> <code>nix flake update</code></li>
    <li><strong>Cache push:</strong> automatic via post-build hook when <code>CACHIX_AUTH_TOKEN</code> is present</li>
  </ul>
</div>

## License
MIT © [Bardia Samiee](https://github.com/bsamiee)
