# Title         : TOOL-REFERENCE.md
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : .kiro/specs/comprehensive-tool-configuration/reference-implementation/TOOL-REFERENCE.md
# ----------------------------------------------------------------------------
# Comprehensive Tool Configuration Cross-Reference Guide

# NET-NEW Tool Configuration Cross-Reference Guide

## Overview

This document provides a cross-reference for NET-NEW tools that are not yet configured in the actual Parametric Forge system (01.home/). After auditing against the actual project, this reference implementation focuses ONLY on tools that provide genuine value-add and are not already implemented.

**IMPORTANT**: Tools already fully configured in the actual project (git, gh, lazygit, starship, fzf, zoxide, direnv, eza, bat, ripgrep, ssh, zsh, wezterm, most language servers, etc.) have been removed from this reference implementation to avoid duplication.

## NET-NEW Configuration Status Summary

- **Total NET-NEW Tools**: 30 tools requiring configuration
- **High Priority**: 12 tools (essential development workflow)
- **Medium Priority**: 10 tools (important but not critical)  
- **Low Priority**: 8 tools (nice-to-have enhancements)

## Priority Classification

- **🟢 High Priority**: 12 tools (essential development workflow)
- **🟡 Medium Priority**: 10 tools (important but not critical)
- **🔴 Low Priority**: 8 tools (nice-to-have enhancements)

## Configuration Method Legend

- **programs/** - Declarative Nix-managed configuration via home-manager
- **configs/** - Static configuration files deployed via file-management.nix
- **environment** - Environment variables only (defined in environment.nix)
- **No config needed** - Tool works well with defaults or is configured via CLI options
- **LSP client** - Language server configured by editor/IDE, no separate config needed

## Implementation Status Legend

- **✅ Configured** - Fully implemented and working
- **🔄 Partially Configured** - Some configuration exists but incomplete
- **❌ Not configured** - No configuration implemented
- **✅ No config needed** - Tool doesn't require configuration

## Quick Reference by Tool Name

### A-C
- **bacon** → rust-tools.nix → configs/ (bacon.toml) → ❌ Not configured → 🔴 LOW Priority
- **bandwhich** → sysadmin.nix → configs/ → ❌ Not configured → ⚪ No Priority
- **bash** → core.nix → No config needed → ✅ No config needed → ⚪ No Priority
- **bash-language-server** → dev-tools.nix → LSP client → ✅ No config needed → ⚪ No Priority
- **basedpyright** → python-tools.nix → configs/ (basedpyright.json) → ✅ Configured → ⚪ No Priority
- **bat** → core.nix → programs/ + configs/ → ✅ Configured → ⚪ No Priority
- **bats** → devops.nix → configs/ → ❌ Not configured → ⚪ No Priority
- **bind** → sysadmin.nix → No config needed → ✅ No config needed → ⚪ No Priority
- **bottom** → core.nix → configs/ (bottom.toml) → ❌ Not configured → 🟢 HIGH Priority
- **broot** → core.nix → programs/ + configs/ (conf.hjson) → ❌ Not configured → 🟢 HIGH Priority
- **brotli** → core.nix → No config needed → ✅ No config needed → ⚪ No Priority
- **buildkit** → devops.nix → configs/ (buildkitd.toml) → ❌ Not configured → ⚪ No Priority
- **cachix** → nix-tools.nix → configs/ (cachix.dhall) → ❌ Not configured → ⚪ No Priority
- **cargo-audit** → rust-tools.nix → No config needed → ✅ No config needed → ⚪ No Priority
- **cargo-binstall** → rust-tools.nix → No config needed → ✅ No config needed → ⚪ No Priority
- **cargo-bloat** → rust-tools.nix → No config needed → ✅ No config needed → ⚪ No Priority
- **cargo-deny** → rust-tools.nix → configs/ (cargo-deny.toml) → ✅ Configured → ⚪ No Priority
- **cargo-edit** → rust-tools.nix → No config needed → ✅ No config needed → ⚪ No Priority
- **cargo-expand** → rust-tools.nix → No config needed → ✅ No config needed → ⚪ No Priority
- **cargo-generate** → rust-tools.nix → No config needed → ✅ No config needed → ⚪ No Priority
- **cargo-machete** → rust-tools.nix → No config needed → ✅ No config needed → ⚪ No Priority
- **cargo-outdated** → rust-tools.nix → No config needed → ✅ No config needed → ⚪ No Priority
- **cargo-watch** → rust-tools.nix → No config needed → ✅ No config needed → ⚪ No Priority
- **choose** → core.nix → No config needed → ✅ No config needed → ⚪ No Priority
- **cmake** → devops.nix → environment variables → ❌ Not configured → ⚪ No Priority
- **colima** → devops.nix → configs/ (colima.yaml) → ❌ Not configured → 🔴 LOW Priority
- **concurrently** → node-tools.nix → No config needed → ✅ No config needed → ⚪ No Priority
- **cookiecutter** → python-tools.nix → configs/ → ❌ Not configured → ⚪ No Priority
- **coreutils** → core.nix → No config needed → ✅ No config needed → ⚪ No Priority

### D-G
- **deadnix** → nix-tools.nix → pre-commit integration → ❌ Not configured → ⚪ No Priority
- **delta** → core.nix → programs/ (git-tools.nix) → ✅ Configured → ⚪ No Priority
- **deploy-rs** → nix-tools.nix → project-specific → ❌ Project-specific → ⚪ No Priority
- **diffutils** → core.nix → No config needed → ✅ No config needed → ⚪ No Priority
- **direnv** → core.nix → programs/ + configs/ → ✅ Configured → ⚪ No Priority
- **dive** → devops.nix → configs/ (.dive.yaml) → ❌ Not configured → ⚪ No Priority
- **docker-client** → devops.nix → configs/ (config.json) → ❌ Not configured → 🔴 LOW Priority
- **docker-compose** → devops.nix → templates → ❌ Not configured → ⚪ No Priority
- **dockutil** → macos-tools.nix → setup scripts → ✅ No config needed → ⚪ No Priority
- **doggo** → core.nix → configs/ (config.yaml) → ❌ Not configured → 🟡 MEDIUM Priority
- **duf** → core.nix → configs/ → ❌ Not configured → 🟡 MEDIUM Priority
- **dust** → core.nix → configs/ (config.toml) → ❌ Not configured → 🟡 MEDIUM Priority
- **duti** → macos-tools.nix → configs/ → ❌ Not configured → ⚪ No Priority
- **entr** → devops.nix → No config needed → ✅ No config needed → ⚪ No Priority
- **eslint** → node-tools.nix → configs/ (eslint.config.js) → ✅ Configured → ⚪ No Priority
- **eza** → core.nix → programs/ (shell-tools.nix) → ✅ Configured → ⚪ No Priority
- **fcp** → core.nix → No config needed → ✅ No config needed → ⚪ No Priority
- **fd** → core.nix → programs/ (shell-tools.nix) → ✅ Configured → ⚪ No Priority
- **ffmpeg** → media-tools.nix → configs/ (presets) → ❌ Not configured → 🔴 LOW Priority
- **file** → core.nix → custom magic files → ❌ Not configured → ⚪ No Priority
- **findutils** → core.nix → No config needed → ✅ No config needed → ⚪ No Priority
- **fx** → dev-tools.nix → configs/ → ❌ Not configured → 🟡 MEDIUM Priority
- **fzf** → core.nix → programs/ (shell-tools.nix) → ✅ Configured → ⚪ No Priority
- **gawk** → core.nix → No config needed → ✅ No config needed → ⚪ No Priority
- **gh** → devops.nix → programs/ (git-tools.nix) → ✅ Configured → ⚪ No Priority
- **git** → (system) → programs/ + configs/ → ✅ Configured → ⚪ No Priority
- **git-crypt** → devops.nix → GPG integration → ❌ Not configured → ⚪ No Priority
- **git-secret** → devops.nix → environment variables → ❌ Not configured → ⚪ No Priority
- **gitleaks** → devops.nix → configs/ (gitleaks.toml) → ❌ Not configured → ⚪ No Priority
- **gitui** → devops.nix → configs/ → ❌ Not configured → 🔴 LOW Priority
- **gnugrep** → core.nix → No config needed → ✅ No config needed → ⚪ No Priority
- **gnused** → core.nix → No config needed → ✅ No config needed → ⚪ No Priority
- **gnutar** → core.nix → No config needed → ✅ No config needed → ⚪ No Priority
- **gopass** → devops.nix → configs/ (config.yml) → ❌ Not configured → ⚪ No Priority
- **gping** → core.nix → configs/ → ❌ Not configured → 🟡 MEDIUM Priority
- **graphviz** → media-tools.nix → environment variables → ❌ Not configured → ⚪ No Priority
- **grex** → core.nix → No config needed → ✅ No config needed → ⚪ No Priority

### H-M
- **hadolint** → devops.nix → configs/ (.hadolint.yaml) → ❌ Not configured → ⚪ No Priority
- **hexyl** → core.nix → No config needed → ✅ No config needed → ⚪ No Priority
- **http-server** → node-tools.nix → No config needed → ✅ No config needed → ⚪ No Priority
- **httpx** → python-tools.nix → No config needed → ✅ No config needed → ⚪ No Priority
- **hyperfine** → dev-tools.nix → configs/ → ❌ Not configured → 🟢 HIGH Priority
- **imagemagick** → media-tools.nix → configs/ (policy.xml) → ❌ Not configured → ⚪ No Priority
- **iperf** → sysadmin.nix → configs/ → ❌ Not configured → ⚪ No Priority
- **jless** → dev-tools.nix → configs/ → ❌ Not configured → ⚪ No Priority
- **jq** → dev-tools.nix → configs/ (color config) → ❌ Not configured → 🟢 HIGH Priority
- **js-yaml** → node-tools.nix → No config needed → ✅ No config needed → ⚪ No Priority
- **json** → node-tools.nix → No config needed → ✅ No config needed → ⚪ No Priority
- **json-server** → node-tools.nix → No config needed → ✅ No config needed → ⚪ No Priority
- **just** → dev-tools.nix → configs/ (templates) → ❌ Not configured → 🟢 HIGH Priority
- **lazydocker** → devops.nix → configs/ (config.yml) → ❌ Not configured → ⚪ No Priority
- **lazygit** → devops.nix → programs/ (git-tools.nix) → ✅ Configured → ⚪ No Priority
- **lf** → core.nix → configs/ (lfrc) → ❌ Not configured → 🟡 MEDIUM Priority
- **lua-language-server** → lua-tools.nix → LSP client → ✅ No config needed → ⚪ No Priority
- **luajit** → lua-tools.nix → environment variables → ❌ Not configured → ⚪ No Priority
- **luarocks** → lua-tools.nix → configs/ (config.lua) → ✅ Configured → ⚪ No Priority
- **lz4** → core.nix → No config needed → ✅ No config needed → ⚪ No Priority
- **m-cli** → macos-tools.nix → No config needed → ✅ No config needed → ⚪ No Priority
- **marksman** → dev-tools.nix → configs/ (marksman.toml) → ✅ Configured → ⚪ No Priority
- **mas** → macos-tools.nix → No config needed → ✅ No config needed → ⚪ No Priority
- **mcfly** → core.nix → programs/ → ❌ Not configured → 🟢 HIGH Priority
- **mdbook** → rust-tools.nix → configs/ → ❌ Not configured → ⚪ No Priority
- **mtr** → core.nix → configs/ (.mtrrc) → ❌ Not configured → ⚪ No Priority
- **mypy** → python-tools.nix → configs/ → ❌ Not configured → ⚪ No Priority

### N-R
- **neovim** → sysadmin.nix → configs/ (init.lua) → ❌ Not configured → 🔴 LOW Priority
- **nil** → nix-tools.nix → configs/ (nil.toml) → ✅ Configured → ⚪ No Priority
- **nix-fast-build** → nix-tools.nix → No config needed → ✅ No config needed → ⚪ No Priority
- **nix-index** → nix-tools.nix → programs/ (shell-tools.nix) → ✅ Configured → ⚪ No Priority
- **nix-output-monitor** → nix-tools.nix → No config needed → ✅ No config needed → ⚪ No Priority
- **nixfmt-rfc-style** → nix-tools.nix → No config needed → ✅ No config needed → ⚪ No Priority
- **nixVersions.latest** → nix-tools.nix → No config needed → ✅ No config needed → ⚪ No Priority
- **nmap** → sysadmin.nix → configs/ → ❌ Not configured → ⚪ No Priority
- **nnn** → core.nix → environment variables → ❌ Not configured → ⚪ No Priority
- **nodejs** → node-tools.nix → environment variables → ❌ Not configured → ⚪ No Priority
- **npm-check-updates** → node-tools.nix → No config needed → ✅ No config needed → ⚪ No Priority
- **openssh** → core.nix → programs/ (ssh.nix) → ✅ Configured → ⚪ No Priority
- **osx-cpu-temp** → macos-tools.nix → No config needed → ✅ No config needed → ⚪ No Priority
- **ouch** → core.nix → configs/ (config.yaml) → ❌ Not configured → 🟢 HIGH Priority
- **pandoc** → media-tools.nix → configs/ (defaults.yaml) → ❌ Not configured → ⚪ No Priority
- **parallel-full** → sysadmin.nix → configs/ (config) → ❌ Not configured → ⚪ No Priority
- **pass** → devops.nix → environment variables → ❌ Not configured → ⚪ No Priority
- **pipx** → python-tools.nix → environment variables → ❌ Not configured → ⚪ No Priority
- **pkg-config** → devops.nix → environment variables → ❌ Not configured → ⚪ No Priority
- **pngpaste** → macos-tools.nix → No config needed → ✅ No config needed → ⚪ No Priority
- **pnpm** → node-tools.nix → configs/ (.pnpmrc) → ❌ Not configured → ⚪ No Priority
- **podman** → devops.nix → configs/ (containers.conf) → ❌ Not configured → ⚪ No Priority
- **poetry** → python-tools.nix → configs/ (poetry.toml) → ✅ Configured → ⚪ No Priority
- **pre-commit** → dev-tools.nix → configs/ + cache → ❌ Not configured → 🟢 HIGH Priority
- **prettier** → node-tools.nix → configs/ (.prettierrc) → ✅ Configured → ⚪ No Priority
- **procs** → core.nix → configs/ (config.toml) → ❌ Not configured → 🟢 HIGH Priority
- **pydantic** → python-tools.nix → No config needed → ✅ No config needed → ⚪ No Priority
- **pytest** → python-tools.nix → configs/ → ❌ Not configured → ⚪ No Priority
- **python313** → python-tools.nix → environment variables → ❌ Not configured → ⚪ No Priority
- **ranger** → core.nix → configs/ (rc.conf) → ❌ Not configured → ⚪ No Priority
- **rclone** → devops.nix → configs/ → ❌ Not configured → ⚪ No Priority
- **restic** → devops.nix → configs/ → ❌ Not configured → ⚪ No Priority
- **rich** → python-tools.nix → No config needed → ✅ No config needed → ⚪ No Priority
- **ripgrep** → core.nix → programs/ (shell-tools.nix) → ✅ Configured → ⚪ No Priority
- **rsync** → core.nix → configs/ → ❌ Not configured → 🟢 HIGH Priority
- **ruff** → python-tools.nix → configs/ (ruff.toml) → ✅ Configured → ⚪ No Priority
- **rustup** → rust-tools.nix → environment variables → ❌ Not configured → 🔴 LOW Priority

### S-Z
- **sccache** → rust-tools.nix → configs/ → ❌ Not configured → ⚪ No Priority
- **sd** → core.nix → No config needed → ✅ No config needed → ⚪ No Priority
- **serve** → node-tools.nix → No config needed → ✅ No config needed → ⚪ No Priority
- **shellcheck** → dev-tools.nix → configs/ (shellcheckrc) → ✅ Configured → ⚪ No Priority
- **shfmt** → dev-tools.nix → configs/ → ❌ Not configured → 🟡 MEDIUM Priority
- **speedtest-cli** → sysadmin.nix → No config needed → ✅ No config needed → ⚪ No Priority
- **sqlfluff** → dev-tools.nix → configs/ (.sqlfluff) → ❌ Not configured → 🟡 MEDIUM Priority
- **starship** → core.nix → programs/ + configs/ → ✅ Configured → ⚪ No Priority
- **statix** → nix-tools.nix → configs/ (statix.toml) → ❌ Not configured → ⚪ No Priority
- **stylua** → lua-tools.nix → configs/ (.stylua.toml) → ✅ Configured → ⚪ No Priority
- **switchaudio-osx** → macos-tools.nix → No config needed → ✅ No config needed → ⚪ No Priority
- **taplo** → dev-tools.nix → configs/ (.taplo.toml) → ✅ Configured → ⚪ No Priority
- **taplo-lsp** → dev-tools.nix → LSP client → ✅ No config needed → ⚪ No Priority
- **tldr** → sysadmin.nix → configs/ (config.json) → ❌ Not configured → ⚪ No Priority
- **tokei** → core.nix → configs/ (.tokeirc) → ❌ Not configured → 🟢 HIGH Priority
- **trash-cli** → core.nix → No config needed → ✅ No config needed → ⚪ No Priority
- **typer** → python-tools.nix → No config needed → ✅ No config needed → ⚪ No Priority
- **typescript** → node-tools.nix → configs/ (tsconfig.json) → ✅ Configured → ⚪ No Priority
- **typescript-language-server** → node-tools.nix → LSP client → ✅ No config needed → ⚪ No Priority
- **unzip** → core.nix → No config needed → ✅ No config needed → ⚪ No Priority
- **uutils-coreutils-noprefix** → core.nix → No config needed → ✅ No config needed → ⚪ No Priority
- **uv** → python-tools.nix → configs/ (uv.toml) → ❌ Not configured → ⚪ No Priority
- **vault** → devops.nix → configs/ (config.hcl) → ❌ Not configured → 🔴 LOW Priority
- **vivid** → core.nix → configs/ (themes) → ❌ Not configured → 🟢 HIGH Priority
- **vscode-langservers-extracted** → node-tools.nix → LSP client → ✅ No config needed → ⚪ No Priority
- **watchexec** → sysadmin.nix → configs/ (watchexec.toml) → ❌ Not configured → ⚪ No Priority
- **whois** → sysadmin.nix → No config needed → ✅ No config needed → ⚪ No Priority
- **xan** → core.nix → No config needed → ✅ No config needed → ⚪ No Priority
- **xh** → core.nix → configs/ (config.json) → ❌ Not configured → 🟡 MEDIUM Priority
- **xz** → core.nix → No config needed → ✅ No config needed → ⚪ No Priority
- **yaml-language-server** → dev-tools.nix → LSP client → ✅ No config needed → ⚪ No Priority
- **yamlfmt** → dev-tools.nix → configs/ (.yamlfmt) → ✅ Configured → ⚪ No Priority
- **yamllint** → dev-tools.nix → configs/ (.yamllint.yml) → ✅ Configured → ⚪ No Priority
- **yarn** → node-tools.nix → configs/ (.yarnrc.yml) → ❌ Not configured → ⚪ No Priority
- **yazi** → core.nix → configs/ (yazi.toml) → ❌ Not configured → 🟡 MEDIUM Priority
- **yq-go** → dev-tools.nix → No config needed → ✅ No config needed → ⚪ No Priority
- **yt-dlp** → media-tools.nix → configs/ (config) → ❌ Not configured → ⚪ No Priority
- **zip** → core.nix → No config needed → ✅ No config needed → ⚪ No Priority
- **zoxide** → core.nix → programs/ (shell-tools.nix) → ✅ Configured → ⚪ No Priority
- **zsh-autosuggestions** → core.nix → programs/ (zsh.nix) → ✅ Configured → ⚪ No Priority
- **zsh-completions** → core.nix → programs/ (zsh.nix) → ✅ Configured → ⚪ No Priority
- **zsh-history-substring-search** → core.nix → programs/ (zsh.nix) → ✅ Configured → ⚪ No Priority
- **zsh-syntax-highlighting** → core.nix → programs/ (zsh.nix) → ✅ Configured → ⚪ No Priority
- **zstd** → core.nix → No config needed → ✅ No config needed → ⚪ No Priority
- **_1password-cli** → macos-tools.nix → No config needed → ✅ No config needed → ⚪ No Priority

## Configuration Method Summary

### Programs Module (home-manager declarative) - 15 tools
Tools that use home-manager program modules for declarative configuration:
- **Configured**: bat, delta, direnv, eza, fd, fzf, gh, lazygit, nix-index, openssh, ripgrep, starship, zoxide
- **Zsh enhancements**: zsh-autosuggestions, zsh-syntax-highlighting, zsh-completions, zsh-history-substring-search
- **Not configured**: broot (partial), mcfly

### Config Files (static configurations) - 45 tools
Tools that require static configuration files in configs/ directory:
- **High Priority**: bottom, broot (partial), hyperfine, jq, just, ouch, pre-commit, procs, rsync, tokei, vivid
- **Medium Priority**: doggo, duf, dust, fx, gping, lf, shfmt, sqlfluff, xh, yazi
- **Low Priority**: bacon, colima, docker-client, ffmpeg, gitui, neovim, rustup, vault

### Environment Variables Only - 25 tools
Tools configured purely through environment variables:
- cmake, graphviz, luajit, nodejs, pipx, pkg-config, python313, rustup, etc.

### No Configuration Needed - 42 tools
Tools that work well with default settings or are configured via command-line options:
- Most compression utilities, GNU utilities, simple CLI tools, LSP servers

## Implementation Priority

### 🟢 High Priority (Essential tools needing configuration) - 12 tools
1. **broot** - Interactive file tree explorer (programs/ + configs/)
2. **bottom** - Resource monitor with graphs (configs/)
3. **hyperfine** - Command-line benchmarking (configs/)
4. **jq** - JSON processor (configs/)
5. **just** - Modern task runner (configs/)
6. **mcfly** - Smart shell history (programs/)
7. **ouch** - Universal archive tool (configs/)
8. **pre-commit** - Git hook framework (configs/)
9. **procs** - Process viewer (configs/)
10. **rsync** - Advanced file synchronization (configs/)
11. **tokei** - Fast code statistics (configs/)
12. **vivid** - LS_COLORS generator (configs/)

### 🟡 Medium Priority (Enhancement tools) - 10 tools
1. **doggo** - Modern DNS client (configs/)
2. **duf** - Disk usage with visual bars (configs/)
3. **dust** - Directory size analyzer (configs/)
4. **fx** - Interactive JSON viewer (configs/)
5. **gping** - Ping with real-time graphs (configs/)
6. **lf** - Lightweight terminal file manager (configs/)
7. **shfmt** - Shell formatter (configs/)
8. **sqlfluff** - SQL linter and formatter (configs/)
9. **xh** - Modern HTTP client (configs/)
10. **yazi** - Blazing fast terminal file manager (configs/)

### 🔴 Low Priority (Specialized/Optional tools) - 8 tools
1. **bacon** - Background Rust compiler (configs/)
2. **colima** - Container runtimes on macOS (configs/)
3. **docker-client** - Docker CLI (configs/)
4. **ffmpeg** - Multimedia framework (configs/)
5. **gitui** - Alternative Git TUI (configs/)
6. **neovim** - Hyperextensible text editor (configs/)
7. **rustup** - Rust toolchain management (environment)
8. **vault** - HashiCorp Vault (configs/)

## Configuration Location Reference

### Programs Directory Structure
```
00.core/programs/
├── advanced-editors.nix      # neovim
├── container-tools.nix       # docker-client, colima
├── development-tools.nix     # shfmt, sqlfluff, fx
├── development-workflow.nix  # just, pre-commit, hyperfine, tokei
├── essential-tools.nix       # broot, mcfly
├── file-managers.nix         # yazi, lf
├── file-operations.nix       # rsync, ouch
├── git-alternatives.nix      # gitui
├── language-tools.nix        # rustup, bacon
├── media-tools.nix           # ffmpeg
├── network-tools.nix         # xh, doggo, gping
├── shell-enhancements.nix    # vivid
└── system-monitoring.nix     # procs, bottom
```

### Configs Directory Structure
```
00.core/configs/
├── containers/               # docker, colima
├── development/             # just, jq, shfmt, sqlfluff, fx
├── editors/                 # neovim
├── file-managers/           # yazi, lf
├── file-ops/               # rsync, ouch
├── git/                    # gitui
├── languages/              # bacon, rust
├── media/                  # ffmpeg
├── network/                # xh, doggo, gping
├── security/               # vault
├── shell/                  # vivid
└── system/                 # procs, bottom, duf, dust
```

## Quick Find by Configuration Type

### Find Programs Configurations
- **Shell Tools**: `00.core/programs/shell-enhancements.nix` (vivid)
- **Development**: `00.core/programs/development-workflow.nix` (just, pre-commit, hyperfine, tokei)
- **File Operations**: `00.core/programs/file-operations.nix` (rsync, ouch)
- **System Monitoring**: `00.core/programs/system-monitoring.nix` (procs, bottom)
- **Essential Tools**: `00.core/programs/essential-tools.nix` (broot, mcfly)

### Find Static Configurations
- **Development Tools**: `00.core/configs/development/` (just, jq, shfmt, sqlfluff, fx)
- **System Tools**: `00.core/configs/system/` (procs, bottom, duf, dust)
- **Network Tools**: `00.core/configs/network/` (xh, doggo, gping)
- **File Managers**: `00.core/configs/file-managers/` (yazi, lf)
- **Shell Enhancements**: `00.core/configs/shell/` (vivid)

### Find Environment Variables
- **XDG Compliance**: `environment.nix` (XDG section)
- **Language Tools**: `environment.nix` (language-specific sections)
- **Performance Settings**: `environment.nix` (performance section)

### Find File Deployments
- **Static Configs**: `file-management.nix` (xdg.configFile entries)
- **Home Files**: `file-management.nix` (home.file entries)
- **Data Files**: `file-management.nix` (xdg.dataFile entries)

## Implementation Status by Category

### Core Tools (47 tools)
- **Configured**: 25 tools (53%)
- **Not Configured**: 8 tools (17%)
- **No Config Needed**: 14 tools (30%)

### Development Tools (16 tools)
- **Configured**: 8 tools (50%)
- **Not Configured**: 5 tools (31%)
- **No Config Needed**: 3 tools (19%)

### DevOps Tools (23 tools)
- **Configured**: 3 tools (13%)
- **Not Configured**: 12 tools (52%)
- **No Config Needed**: 8 tools (35%)

### Language-Specific Tools
- **Python Tools (16 tools)**: 4 configured, 4 not configured, 8 no config needed
- **Rust Tools (13 tools)**: 1 configured, 4 not configured, 8 no config needed
- **Node.js Tools (17 tools)**: 3 configured, 2 not configured, 12 no config needed
- **Lua Tools (4 tools)**: 2 configured, 1 not configured, 1 no config needed
- **Nix Tools (10 tools)**: 2 configured, 3 not configured, 5 no config needed

### System Tools
- **macOS Tools (7 tools)**: 0 configured, 1 not configured, 6 no config needed
- **Media Tools (5 tools)**: 0 configured, 3 not configured, 2 no config needed
- **Sysadmin Tools (10 tools)**: 1 configured, 5 not configured, 4 no config needed

## Next Steps for Implementation

### Phase 1: High Priority Tools (Weeks 1-2)
Implement the 12 high-priority tools that provide immediate productivity benefits:
1. Essential daily tools: broot, just, jq, procs, bottom, mcfly
2. Development workflow: pre-commit, hyperfine, tokei, vivid
3. File operations: rsync, ouch

### Phase 2: Medium Priority Tools (Weeks 3-4)
Implement the 10 medium-priority tools for enhanced system capabilities:
1. System monitoring: xh, duf, dust, doggo, gping
2. Development tools: shfmt, sqlfluff, fx
3. File managers: yazi, lf

### Phase 3: Low Priority Tools (Weeks 5-6)
Implement the 8 low-priority specialized tools:
1. Container tools: docker-client, colima
2. Language tools: rustup, bacon
3. Alternatives: gitui, neovim
4. Media/Security: ffmpeg, vault

This cross-reference guide provides the complete mapping needed to implement comprehensive tool configuration coverage across the entire Parametric Forge system.