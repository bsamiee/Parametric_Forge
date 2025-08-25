---
inclusion: always
---

# Technology Stack & Development Guidelines

## Core Technology Stack

### Build System

- **Nix Flakes**: Primary build system with reproducible builds
- **flake-parts**: Modular flake organization - use for all new flake modules
- **treefmt-nix**: Unified code formatting - run `nix fmt` before commits

### Platform Configuration

- **nix-darwin**: macOS system configuration (primary platform)
- **home-manager**: User-level configuration (cross-platform)
- **NixOS**: Linux system configuration (secondary/containers)
- **nixpkgs-unstable**: Package source for latest versions

### Languages & Frameworks

- **Nix**: All configuration files - follow existing patterns in `lib/` and modules
- **Rust**: TUI interface only (`interface/` directory) - use ratatui + crossterm
- **Bash**: System scripts - minimal use, prefer Nix when possible

## Essential Commands

### System Management

```bash
# Apply Darwin system changes
darwin-rebuild switch --flake .

# Apply user configuration only
home-manager switch --flake .

# Build without applying
nix build .#darwinConfigurations.default.system
```

### Development Workflow

```bash
# Enter dev environment
nix develop

# Format all code
nix fmt

# Validate configuration
nix flake check

# Update dependencies
nix flake update
```

### Interface Development

```bash
# Build TUI interface
nix build .#packages.aarch64-darwin.parametric-forge-interface

# Run interface
./result/bin/forge-interface

# Direct Rust development
cd interface && cargo build --release
```

## Architecture Principles

### Code Organization

- **300 LOC maximum** per file - split larger files
- **Modular imports**: Use `lib/` functions, avoid duplication
- **Platform abstraction**: Detect runtime context in `lib/detection.nix`
- **Clear separation**: System (`00.system/`) vs User (`01.home/`) configuration

### Development Rules

- **Read existing code first** - understand patterns before adding new functionality
- **Integrate immediately** - no isolated/unused code
- **Follow file headers** - use standard format from `formatting-standards.md`
- **Respect existing patterns** - match import styles and module organization

### Quality Gates

- All new code must be immediately integrated and used
- No duplicate functionality - refactor existing code instead
- Platform-specific code goes in appropriate directories
- Use `lib/` utilities for shared functionality

## File Structure Conventions

### Configuration Flow

1. `flake.nix` → `flake/default.nix` → specific modules
2. System: `00.system/darwin/` or `00.system/nixos/`
3. User: `01.home/` with platform-specific overrides
4. Shared: `lib/` and `modules/` for reusable components

### Import Patterns

```nix
# Standard import order:
{ inputs, lib, pkgs, ... }:  # External
let
  inherit (lib) mkIf;        # Library functions
  cfg = config.myModule;     # Local references
in
```

### Module Structure

- Use `lib/config-defaults.nix` for default values
- Platform detection via `lib/detection.nix`
- Service definitions in appropriate platform directories
- Package collections in `01.home/01.packages/`
