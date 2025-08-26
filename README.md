# Parametric Forge

Multi-platform Nix configuration using flakes, nix-darwin, and home-manager. Host-file-less, deployable everywhere.

## Architecture

```
00.system/        # System-level (requires root)
├── darwin/       # macOS: system settings, homebrew, services
└── nixos/        # Linux: system config, container support

01.home/          # User-level (no root)
├── 00.core/      # Programs and configs
├── 01.packages/  # Curated package sets
└── 02.assets/    # Scripts and data files

flake/            # Flake-parts modules
lib/              # Custom library functions
```

## Key Concepts

**Seperation of Concerns**
- IMPORTANT: All components are centralized by domain, all XDG's are in xdg.nix, annd environment variables and in the envrionemnts.nix, all file deployments are in file-management.nix, all daemon files exist in the services/ - this is the pattern to maintain
- CRITICAL: All configurations are pulled apart, aliases live in categorized alias files within aliases/ cli downloads are in packages/ hombebrew installs are in homebrew.nix. Configs/ contain large file configurations - whether home-manager supports the tool of not (ex: git-tools.nix + configs/git/.gitignore)
- IMPORTANT: Always propritize nix package management over homebrew (homebrew is for gui + fallback option if a tool doesn't exist in nix packages) - the last resort is manual installation in 01.home/activation.nix

**System vs Home**
- `system/` = root-level OS configuration (darwin-rebuild/nixos-rebuild)
- `home/` = user-level dotfiles and packages (home-manager)
- Both integrated, not standalone - single `flake.nix` entry point

**Platform Priority**: macOS primary, NixOS secondary, containers/VMs supported

**No Host Files**: Context detected at runtime via `lib/detection.nix`:
```nix
context = myLib.detectContext system user;
# Returns: { isDarwin, isLinux, isAarch64, isX86_64, user, userHome, ... }
```

## Library (`lib/`)

Core utilities available as `myLib` throughout:

```nix
# Platform detection
isDarwin, isLinux, isAarch64, isX86_64, detectContext

# Deployment
build.deployDir        # Deploy asset folders
build.mkBinPackage    # Package scripts for PATH

# Darwin-specific
launchd.*             # Service management

# Development
devshell.*            # Shell environment helpers
secrets.*             # 1Password integration
```

## Deployment

**File Deployment** (`01.home/file-management.nix`):
- `xdg.configFile` → `~/.config/app/`
- `home.file` → `~/.*` 
- `myLib.build.deployDir` → Asset folders (e.g., `claude/` → `~/.claude/`)

**Commands**:
```bash
# macOS
darwin-rebuild switch --flake .

# NixOS/Linux
nixos-rebuild switch --flake .

# Update all inputs
nix flake update
```

## Flake Structure

Using flake-parts for modularity:
- `flake.nix` → Pure entry, delegates to `flake/`
- `flake/systems.nix` → Darwin/NixOS configurations
- `flake/devshells.nix` → Development environments
- Universal builder handles both platforms

**Configurations**:
- **Darwin**: `default` (aarch64), `x86_64`
- **NixOS**: `vm`, `container`, `aarch64-vm`

## Platform Features

**macOS (Darwin)**:
- Homebrew integration via nix-homebrew
- System settings (keyboard, trackpad, Finder)
- Launch daemons for maintenance
- Rosetta auto-enabled on Apple Silicon

**Containers/VMs**:
- Optimized NixOS configs
- Docker/Podman configurations deployed
- Colima for macOS container runtime

## Package Management

**Modern CLI replacements** (`01.home/01.packages/core.nix`):
- `eza` → ls, `ripgrep` → grep, `bat` → cat, `fd` → find
- `bottom` → htop, `delta` → diff, `zoxide` → cd

**Language toolchains**: Python (uv, ruff), Rust (cargo, rustup), Node (fnm), Lua

**SQLite extensions**: sqlite-vec, libspatialite, sqlean (manual)

## Development Shells

```bash
nix develop          # Default Nix tools
nix develop .#python # Python environment
nix develop .#rust   # Rust environment
nix develop .#lua    # Lua environment
```

## Philosophy

- **KISS**: Minimal complexity, maximum capability
- **Foundation first**: Start small, build slowly
- **No dead code**: Every line has purpose
- **Platform-aware**: Optimize per-platform, share when possible