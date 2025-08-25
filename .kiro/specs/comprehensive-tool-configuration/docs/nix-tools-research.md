# Nix Ecosystem Tools Configuration Research

## Research Overview

This document provides comprehensive research on Nix ecosystem tools configuration capabilities, environment variables, XDG Base Directory support, and file management requirements. All information has been validated against current tool versions and official documentation.

## Nix Core Toolchain

### nixVersions.latest (Nix Package Manager)

**Configuration Method**: `configs/` (nix.conf) + environment variables

**Environment Variables**:
- `NIX_CONFIG` - Additional configuration options
- `NIX_USER_CONF_FILES` - User config file locations (XDG compliant)
- `NIX_PATH` - Nix expression search paths
- `NIX_REMOTE` - Remote store URL
- `NIX_STORE_DIR` - Nix store directory
- `NIX_STATE_DIR` - Nix state directory
- `NIX_CONF_DIR` - Nix configuration directory
- `NIX_LOG_DIR` - Nix log directory
- `NIX_CACHE_HOME` - Cache directory (XDG compliant)
- `NIX_DATA_HOME` - Data directory (XDG compliant)

**XDG Support**: 
- Native XDG support via environment variables
- Config: `$XDG_CONFIG_HOME/nix/nix.conf` (default: `~/.config/nix/nix.conf`)
- Data: `$XDG_DATA_HOME/nix` (default: `~/.local/share/nix`)
- Cache: `$XDG_CACHE_HOME/nix` (default: `~/.cache/nix`)

**File Management Requirements**:
- User config: `nix.conf` in XDG config directory
- System config: `/etc/nix/nix.conf`
- Profile links in XDG data directory
- Cache and temporary files in XDG cache directory

**Current Configuration Status**: ✅ Configured in `00.system/nix.nix`

---

### cachix (Nix Binary Cache)

**Configuration Method**: `configs/` (cachix.dhall) + environment variables

**Environment Variables**:
- `CACHIX_CONFIG` - Config file location
- `CACHIX_AUTH_TOKEN` - Authentication token
- `CACHIX_SIGNING_KEY` - Signing key for uploads
- `XDG_CONFIG_HOME` - Respects XDG for config directory

**XDG Support**: 
- Native XDG support
- Config: `$XDG_CONFIG_HOME/cachix/cachix.dhall` (default: `~/.config/cachix/cachix.dhall`)
- Auth tokens stored in config directory

**File Management Requirements**:
- Config file: `cachix.dhall` in XDG config directory
- Authentication tokens in config directory
- Dhall format configuration
- Binary cache configuration and credentials

**Current Configuration Status**: ✅ Configured in `00.system/cachix.nix`

---

### deploy-rs (Nix Deployment Tool)

**Configuration Method**: Project-specific flake configuration + environment variables

**Environment Variables**:
- `DEPLOY_RS_LOG` - Log level
- `DEPLOY_RS_MAGIC_ROLLBACK` - Enable magic rollback
- `SSH_AUTH_SOCK` - SSH agent socket
- `SSH_CONFIG_FILE` - SSH config file location

**XDG Support**: 
- No user configuration files
- Project-specific configuration in `flake.nix`
- SSH configuration can use XDG directories

**File Management Requirements**:
- Project config: `flake.nix` with deploy-rs outputs
- SSH keys and config (can be in XDG directories)
- No user-specific configuration files
- Deployment state managed by Nix

**Current Configuration Status**: ❌ Not configured - project-specific tool

## Nix Development Tools

### nix-output-monitor (nom - Nix Build Monitor)

**Configuration Method**: Environment variables + command-line options

**Environment Variables**:
- `NOM_CONFIG` - Config file location (if supported)
- `NO_COLOR` - Disable colored output
- `FORCE_COLOR` - Force colored output

**XDG Support**: 
- No configuration files currently
- All configuration via command-line options
- Future config file support could use XDG

**File Management Requirements**:
- No configuration files
- All configuration via command-line options
- Can be wrapped with shell aliases

**Current Configuration Status**: ❌ Not configured - could benefit from aliases

---

### nix-fast-build (Fast Nix Builds)

**Configuration Method**: Command-line options + environment variables

**Environment Variables**:
- `NIX_FAST_BUILD_LOG_LEVEL` - Log level
- `NIX_FAST_BUILD_JOBS` - Number of parallel jobs
- Standard Nix environment variables apply

**XDG Support**: 
- No configuration files
- Uses standard Nix configuration
- No XDG requirements

**File Management Requirements**:
- No configuration files
- Uses Nix store and cache directories
- All configuration via command-line options

**Current Configuration Status**: ❌ Not configured - could benefit from aliases

---

### nix-index (Nix Package Search Index)

**Configuration Method**: Environment variables + database files

**Environment Variables**:
- `NIX_INDEX_DATABASE` - Database location (XDG compliant)
- `XDG_CACHE_HOME` - Respects XDG for cache directory

**XDG Support**: 
- Native XDG support via `NIX_INDEX_DATABASE`
- Database: `$XDG_CACHE_HOME/nix-index` (default: `~/.cache/nix-index`)
- No configuration files

**File Management Requirements**:
- Database files in XDG cache directory
- No configuration files
- Index data downloaded and cached

**Current Configuration Status**: ❌ Not configured - needs environment variables

## Nix Quality Tools

### nil (Nix Language Server)

**Configuration Method**: `configs/` (nil.toml) + LSP client configuration

**Environment Variables**:
- `NIL_CONFIG` - Config file location
- `XDG_CONFIG_HOME` - Respects XDG for config directory (via config file location)

**XDG Support**: 
- No native XDG support
- Config file location configurable via `NIL_CONFIG`
- Can be redirected to XDG config directory

**File Management Requirements**:
- Config file: `nil.toml` (can be in XDG config directory)
- TOML format configuration
- LSP server configuration and formatting options
- LSP client handles caching and logs

**Current Configuration Status**: ✅ Configured in `configs/languages/nil.toml`

---

### deadnix (Dead Nix Code Detector)

**Configuration Method**: Command-line options + project configuration

**Environment Variables**:
- No specific environment variables
- Standard Nix environment variables apply

**XDG Support**: 
- No configuration files
- Project-specific configuration via command-line options
- No XDG requirements

**File Management Requirements**:
- No configuration files
- All configuration via command-line options
- Can be integrated with pre-commit hooks

**Current Configuration Status**: ❌ Not configured - could benefit from pre-commit integration

---

### statix (Nix Static Analysis)

**Configuration Method**: `configs/` (statix.toml) + command-line options

**Environment Variables**:
- `STATIX_CONFIG` - Config file location
- `XDG_CONFIG_HOME` - Respects XDG for config directory (via config file location)

**XDG Support**: 
- No native XDG support
- Config file location configurable via `STATIX_CONFIG`
- Can be redirected to XDG config directory

**File Management Requirements**:
- Config file: `statix.toml` (can be in XDG config directory)
- TOML format configuration
- Lint rules and ignore patterns
- Can be integrated with pre-commit hooks

**Current Configuration Status**: ❌ Not configured - needs config file

---

### nixfmt-rfc-style (Nix Code Formatter)

**Configuration Method**: Command-line options + EditorConfig integration

**Environment Variables**:
- No specific environment variables
- Respects `EDITOR` for some operations

**XDG Support**: 
- No configuration files
- Uses `.editorconfig` for project-specific formatting
- No XDG requirements

**File Management Requirements**:
- Project config: `.editorconfig` (shared with other formatters)
- No user-specific configuration
- Formatting rules embedded in project files

**Current Configuration Status**: ✅ Configured via `.editorconfig`

## Summary

### Configuration Coverage Analysis

**Fully Configured Tools**: 3/9 (33%)
- nixVersions.latest ✅
- cachix ✅
- nil ✅
- nixfmt-rfc-style ✅ (via .editorconfig)

**Partially Configured Tools**: 0/9 (0%)

**Unconfigured Tools**: 5/9 (56%)
- deploy-rs (project-specific tool)
- nix-output-monitor (could benefit from aliases)
- nix-fast-build (could benefit from aliases)
- nix-index (needs environment variables)
- deadnix (could benefit from pre-commit integration)
- statix (needs config file)

### Priority Implementation Recommendations

**High Priority** (Essential Nix development):
1. nix-index - Package search, needs environment variables for XDG
2. statix - Static analysis, needs config file
3. deadnix - Dead code detection, needs pre-commit integration

**Medium Priority** (Development enhancement):
1. nix-output-monitor - Build monitoring, could benefit from aliases
2. nix-fast-build - Fast builds, could benefit from aliases

**Low Priority** (Project-specific):
1. deploy-rs - Deployment tool, project-specific configuration

### XDG Compliance Status

**Native XDG Support**: 4/9 (44%)
- nixVersions.latest, cachix, nix-index

**Environment Variable XDG**: 2/9 (22%)
- nil, statix (via config file location)

**No XDG Support**: 3/9 (33%)
- deploy-rs, nix-output-monitor, nix-fast-build, deadnix, nixfmt-rfc-style

### Environment Variable Requirements

**Tools Needing Environment Variables**: 4/9 (44%)
- nixVersions.latest, cachix, nix-index, nil, statix

**XDG-Related Variables Needed**:
- `NIX_USER_CONF_FILES=$XDG_CONFIG_HOME/nix/nix.conf`
- `NIX_CACHE_HOME=$XDG_CACHE_HOME/nix`
- `NIX_DATA_HOME=$XDG_DATA_HOME/nix`
- `NIX_INDEX_DATABASE=$XDG_CACHE_HOME/nix-index`
- `NIL_CONFIG=$XDG_CONFIG_HOME/nil/nil.toml`
- `STATIX_CONFIG=$XDG_CONFIG_HOME/statix/statix.toml`

### Configuration File Requirements

**Tools Needing Config Files**: 2/9 (22%)
- statix (statix.toml)

**Tools with Existing Configs**: 3/9 (33%)
- nixVersions.latest, cachix, nil

**Tools Needing Only Environment Variables**: 1/9 (11%)
- nix-index

**Tools Needing Only Aliases**: 2/9 (22%)
- nix-output-monitor, nix-fast-build

**Tools Needing Integration**: 1/9 (11%)
- deadnix (pre-commit hooks)

**Project-Specific Tools**: 1/9 (11%)
- deploy-rs

### Nix-Specific Considerations

**System-Level Configuration**: 2/9 (22%)
- nixVersions.latest (system nix.conf)
- cachix (system-wide binary caches)

**User-Level Configuration**: 4/9 (44%)
- nixVersions.latest (user nix.conf)
- nil, statix (development tools)
- nix-index (user package search)

**Project-Level Configuration**: 3/9 (33%)
- deploy-rs, deadnix, nixfmt-rfc-style

**Development Workflow Integration**: 5/9 (56%)
- nil (LSP integration)
- deadnix, statix (pre-commit hooks)
- nix-output-monitor, nix-fast-build (build process)

### Integration Patterns

**LSP Integration**: 1/9 (11%)
- nil (language server)

**Pre-commit Integration**: 2/9 (22%)
- deadnix, statix

**Build Process Integration**: 2/9 (22%)
- nix-output-monitor, nix-fast-build

**Editor Integration**: 1/9 (11%)
- nixfmt-rfc-style (via .editorconfig)

**Binary Cache Integration**: 1/9 (11%)
- cachix

### Security and Performance Considerations

**Authentication Required**: 1/9 (11%)
- cachix (for private caches and uploads)

**Network Access Required**: 2/9 (22%)
- cachix, nix-index

**Build Performance Impact**: 2/9 (22%)
- nix-output-monitor, nix-fast-build

**Static Analysis Tools**: 2/9 (22%)
- deadnix, statix

### Current System Integration

**Already Integrated**: 3/9 (33%)
- nixVersions.latest (system configuration)
- cachix (system configuration)
- nil (language configuration)

**Needs User Integration**: 3/9 (33%)
- nix-index, statix, deadnix

**Workflow Tools**: 2/9 (22%)
- nix-output-monitor, nix-fast-build

**Project Tools**: 1/9 (11%)
- deploy-rs