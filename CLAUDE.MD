# AI Assistant Context for Parametric Forge

## MCP Server Access

You have access to enhanced capabilities through these MCP servers. Use them intelligently:

- **Search & Research**: Use `perplexity` (primary) and `tavily` (fallback) for web searches, current information, and research
- **Documentation**: Use `context7` for accessing documentation, then `perplexity` if needed
- **File Operations**: Use `filesystem` for reading, writing, and navigating local files and directories
- **Repository Analysis**: Use `github` for analyzing repositories, commits, and remote codebases
- **Browser Automation**: Use `puppeteer` for web interactions and screenshots
- **Persistent Memory**: Use `memory` for knowledge graphs and context retention across sessions

**Auto-Detection**: Your queries are automatically analyzed to select appropriate servers. Standard `WebSearch` is disabled - use the superior MCP alternatives.

## Project Overview

Multi-platform configuration management using Nix flakes, nix-darwin (system-level for macOS), and home-manager (user-level).
Designed for local and remote deployment (machines/VMs/containers). Starting small, building slowly.

### Configuration Deployment Reality

**CRITICAL**: This is a Nix/Darwin/Home-Manager project with sophisticated deployment infrastructure.

- **Source Files**: Located in `01.home/02.assets/` within the project structure
- **Deployment Target**: Files are automatically deployed to their expected locations (`~/.claude/`, `~/.config/`, etc.)
- **Deployment Mechanism**: `01.home/file-management.nix` handles all configuration file deployment via:
  - `xdg.configFile` - XDG-compliant applications
  - `home.file` - Non-XDG applications (home directory)
  - `myLib.deploy.deployDir` - Asset folder deployment (e.g., `02.assets/ai/claude` → `~/.claude/`)

**Don't be confused by source vs deployment locations:**
- Project files in `02.assets/ai/claude/` are deployed to `~/.claude/`
- Project files in `02.assets/bin/` are packaged and added to PATH
- All configurations land where applications expect them

This deployment system ensures:
- Version control of all configurations
- Atomic updates via `darwin-rebuild switch`
- Platform-aware deployment
- XDG compliance where supported

## Philosophy: Sophisticated Minimalism

## Core Principles

- **Documentation**: Always reference current docs for nix, darwin, home-manager
- **Platform Priority**: macOS first, then NixOS/Linux, container/VM friendly from the start
- **Code Style**: Clean, self-documenting code with minimal comments
- **Section Markers**: Use `# --- Section Name ---` for logical separation
- **Headers**: Every file requires standard header (Title, Author, Project, License, Path)
- **Efficiency**: Inline where reasonable, minimize vertical LOC

### Quality Over Quantity

**Quality Standards**

- **Maintainability**: Less code = less bugs = less maintenance
- **INFRASTRUCTURE**: Always leverage existing functionality. Double-check before creating new files/functionality
- **INTEGRATION**: Only add functionality that is needed immediately and will be used
- **INTELLIGENCE**: Prefer intelligent, multi-capable functions over many simple ones
- **ZERO-WASTE**: No tolerance for dead/unused code or under-leveraged capabilities
- **LOC LIMIT**: 300 LOC per file

### Code Principles

1. **When NOT to Add Code**:
   - It duplicates existing functionality
   - It won't be used immediately
   - A native tool does it better
   - It adds complexity without clear benefit

2. **Decision Hierarchy**:
   - Can existing tool do it? → Use it
   - Can we extend existing pattern? → Extend it
   - Only then → Create new functionality

## Current Architecture

### Project Structure

```
flake.nix           # Pure entry point - delegates to flake/
flake/              # Flake-parts modules
  default.nix       # Central import, defines systems
  systems.nix       # Darwin and NixOS configurations
  home.nix          # Home-manager configuration
  devshells.nix     # Development environments
  packages.nix      # Custom packages
  formatting.nix    # Code formatting
  checks.nix        # Build checks
lib/                # Library functions
  default.nix       # Platform detection, re-exports
system/             # System-level configurations
  darwin/           # macOS system configuration
  nixos/            # Linux system configuration
    containers.nix  # Container-specific config
home/               # User-level configurations
  default.nix       # Home-manager entry point
  platforms/        # Platform-specific home configs
    darwin.nix
    linux.nix
```

### Key Configurations (flake/systems.nix)

- **Darwin**: `default` (aarch64), `x86_64`
- **NixOS**: `vm`, `container`
- **Home-manager**: Integrated as module, not standalone
- **Unfree packages**: Enabled globally

### Library Functions (lib/default.nix)

- `isDarwin`, `isLinux`: Platform detection
- `isAarch64`, `isX86_64`: Architecture detection
- Re-exports from nixpkgs.lib: `mkIf`, `mkMerge`, `mkOption`, `types`

## Development Guidelines

### File Organization

1. File header (Title, Author, Project, License, Path)
2. Imports (grouped logically)
3. Let bindings (minimize, prefer inline)
4. Main configuration
5. Exports

### Comments

- **AVOID** unless truly necessary
- Code should self-document through good naming
- Section separators: `# --- Section ---` only when needed

______________________________________________________________________

Remember: Start small, build slowly. Focus on foundation before features.
