# Project Structure

## Root Level Organization

```
flake.nix           # Pure entry point - delegates to flake/
flake.lock          # Flake input locks
flake/              # Flake-parts modules
00.system/          # System-level configurations
01.home/            # User-level configurations
lib/                # Library functions and utilities
modules/            # Shared configuration modules
interface/          # Rust TUI application
devshells/          # Development environment definitions
00.DEPRECATED/      # Legacy code (do not modify)
```

## Key Directories

### `flake/` - Flake Organization
- `default.nix`: Central import, defines systems and global config
- `systems.nix`: Darwin and NixOS system configurations
- `devshells.nix`: Development environments (Rust, Python, Lua)
- `packages.nix`: Custom package definitions
- `formatting.nix`: Code formatting configuration
- `checks.nix`: Build validation

### `00.system/` - System-Level Config
- `darwin/`: macOS system configuration (settings, services, homebrew)
- `nixos/`: Linux system configuration (containers, VMs)
- `nix.nix`: Nix daemon configuration
- `environment.nix`: System environment variables
- `fonts.nix`: System-wide font configuration

### `01.home/` - User-Level Config
- `00.core/`: Essential user configurations (git, ssh, shell)
- `01.packages/`: Package collections by category
- `darwin/`: macOS-specific user services
- `nixos/`: Linux-specific user configuration
- `file-management.nix`: XDG directories and file associations

### `lib/` - Utility Functions
- `default.nix`: Library aggregator and re-exports
- `detection.nix`: Platform and architecture detection
- `config-defaults.nix`: Default configuration values
- `launchd.nix`: macOS service utilities
- `exclusion-filters.nix`: File filtering utilities

### `interface/` - Rust TUI
- `src/main.rs`: Application entry point
- `src/app.rs`: Main application logic
- `src/core/`: Core state management
- `src/components/`: UI components
- `src/runtime/`: System interaction

### Import Organization
1. External inputs
2. Library functions
3. Local modules
4. Configuration values

## Configuration Flow

1. `flake.nix` → `flake/default.nix` → specific modules
2. System configs: `00.system/darwin` or `00.system/nixos`
3. User configs: `01.home/` with platform-specific overrides
4. Library functions: `lib/` provides utilities to all modules
5. Context detection: Runtime platform/architecture detection