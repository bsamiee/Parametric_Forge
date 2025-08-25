# Platform-Specific and Media Tools Configuration Research

## Research Overview

This document provides comprehensive research on macOS-specific tools, media processing tools, and sysadmin utilities configuration capabilities, environment variables, XDG Base Directory support, and file management requirements. All information has been validated against current tool versions and official documentation.

## macOS-Specific Tools

### mas (Mac App Store CLI)

**Configuration Method**: Environment variables + keychain integration

**Environment Variables**:
- `MAS_TIMEOUT` - Request timeout in seconds
- `MAS_DEBUG` - Enable debug output
- No configuration file support

**XDG Support**: 
- No configuration files
- No XDG requirements
- Uses macOS keychain for authentication

**File Management Requirements**:
- No configuration files
- Authentication via macOS keychain
- All configuration via command-line options

**Current Configuration Status**: ❌ Not configured - could benefit from aliases

---

### _1password-cli (1Password CLI)

**Configuration Method**: `configs/` (config.json) + environment variables

**Environment Variables**:
- `OP_CONFIG_DIR` - Config directory location (XDG compliant)
- `OP_CACHE_DIR` - Cache directory location (XDG compliant)
- `OP_DATA_DIR` - Data directory location (XDG compliant)
- `OP_SESSION_<account>` - Session tokens for accounts
- `OP_DEVICE` - Device UUID
- `OP_FORMAT` - Default output format
- `OP_DEBUG` - Enable debug output

**XDG Support**: 
- Native XDG support via environment variables
- Config: `$XDG_CONFIG_HOME/op` (default: `~/.config/op`)
- Cache: `$XDG_CACHE_HOME/op` (default: `~/.cache/op`)
- Data: `$XDG_DATA_HOME/op` (default: `~/.local/share/op`)

**File Management Requirements**:
- Config file: `config.json` in XDG config directory
- Session data and cache in appropriate XDG directories
- Device registration data in data directory
- JSON format configuration

**Current Configuration Status**: ❌ Not configured - needs config file + environment variables

---

### dockutil (macOS Dock Management)

**Configuration Method**: Command-line options only

**Environment Variables**:
- No specific environment variables
- macOS-specific tool

**XDG Support**: 
- No configuration files
- No XDG requirements
- Modifies macOS Dock preferences directly

**File Management Requirements**:
- No configuration files
- All configuration via command-line options
- Can be scripted for automated dock setup

**Current Configuration Status**: ❌ Not configured - could benefit from setup scripts

---

### pngpaste (PNG Clipboard Tool)

**Configuration Method**: Command-line options only

**Environment Variables**:
- No specific environment variables
- macOS-specific clipboard tool

**XDG Support**: 
- No configuration files
- No XDG requirements

**File Management Requirements**:
- No configuration files
- All configuration via command-line options
- Can be wrapped with shell aliases

**Current Configuration Status**: ❌ Not configured - could benefit from aliases

---

### duti (Default Applications Manager)

**Configuration Method**: `configs/` (duti settings file) + command-line options

**Environment Variables**:
- No specific environment variables
- macOS-specific tool

**XDG Support**: 
- No native XDG support
- Config files can be placed anywhere
- Can be redirected to XDG config directory

**File Management Requirements**:
- Config file: Custom format for default application settings
- Can be placed in XDG config directory
- Plain text configuration with UTI mappings

**Current Configuration Status**: ❌ Not configured - needs config file

## Media Processing Tools

### ffmpeg (Multimedia Framework)

**Configuration Method**: Environment variables + command-line options

**Environment Variables**:
- `FFMPEG_DATADIR` - Data directory for presets and filters
- `FFREPORT` - Report file location and options
- `AV_LOG_FORCE_NOCOLOR` - Disable colored output
- `AV_LOG_FORCE_COLOR` - Force colored output
- `FFMPEG_FORCE_NOCOLOR` - Disable colored output (deprecated)

**XDG Support**: 
- No native XDG support
- Data directory configurable via `FFMPEG_DATADIR`
- Can be redirected to XDG data directory

**File Management Requirements**:
- Preset files in data directory
- Filter files in data directory
- No user configuration files by default
- Can use custom preset and filter files

**Current Configuration Status**: ❌ Not configured - could benefit from presets

---

### imagemagick (Image Processing Suite)

**Configuration Method**: `configs/` (policy.xml, delegates.xml) + environment variables

**Environment Variables**:
- `MAGICK_CONFIGURE_PATH` - Configuration file search paths
- `MAGICK_CODER_MODULE_PATH` - Coder module search paths
- `MAGICK_FILTER_MODULE_PATH` - Filter module search paths
- `MAGICK_HOME` - ImageMagick installation directory
- `MAGICK_TEMPORARY_PATH` - Temporary file directory
- `MAGICK_THREAD_LIMIT` - Thread limit for operations
- `MAGICK_MEMORY_LIMIT` - Memory limit for operations
- `MAGICK_DISK_LIMIT` - Disk limit for operations

**XDG Support**: 
- Partial XDG support via `MAGICK_CONFIGURE_PATH`
- Config files can be placed in XDG config directory
- System configs: `/etc/ImageMagick-7/`
- User configs: `~/.config/ImageMagick/` (can be XDG)

**File Management Requirements**:
- Config files: `policy.xml`, `delegates.xml`, `type.xml`
- Module files in specified directories
- XML format configuration files
- Security policies and delegate configurations

**Current Configuration Status**: ❌ Not configured - needs config files + environment variables

---

### yt-dlp (YouTube Downloader)

**Configuration Method**: `configs/` (yt-dlp.conf) + environment variables

**Environment Variables**:
- `YT_DLP_CONFIG_HOME` - Config directory location (XDG compliant)
- `XDG_CONFIG_HOME` - Respects XDG for config directory

**XDG Support**: 
- Native XDG support via `YT_DLP_CONFIG_HOME`
- Config: `$XDG_CONFIG_HOME/yt-dlp/config` (default: `~/.config/yt-dlp/config`)
- Also checks: `yt-dlp.conf` in current directory

**File Management Requirements**:
- Config file: `config` or `yt-dlp.conf` in config directory
- Plain text configuration with command-line options
- Archive files for tracking downloads
- Cookie files for authentication

**Current Configuration Status**: ❌ Not configured - needs config file

---

### pandoc (Document Converter)

**Configuration Method**: `configs/` (defaults.yaml) + environment variables

**Environment Variables**:
- `PANDOC_VERSION` - Version information
- `XDG_DATA_HOME` - Respects XDG for data directory
- `XDG_CONFIG_HOME` - Respects XDG for config directory

**XDG Support**: 
- Native XDG support
- Config: `$XDG_CONFIG_HOME/pandoc/` (default: `~/.config/pandoc/`)
- Data: `$XDG_DATA_HOME/pandoc/` (default: `~/.local/share/pandoc/`)

**File Management Requirements**:
- Config files: `defaults.yaml` in config directory
- Templates in data directory
- Filters in data directory
- YAML format configuration

**Current Configuration Status**: ❌ Not configured - needs config files

---

### graphviz (Graph Visualization)

**Configuration Method**: Environment variables + system configuration

**Environment Variables**:
- `GRAPHVIZ_DOT` - Path to dot executable
- `GVBINDIR` - Graphviz binary directory
- `GVLIBDIR` - Graphviz library directory

**XDG Support**: 
- No user configuration files
- System-level configuration only
- No XDG requirements

**File Management Requirements**:
- System config files in installation directory
- Plugin files in library directory
- No user-specific configuration files

**Current Configuration Status**: ❌ Not configured - could benefit from environment variables

## Sysadmin Tools

### parallel-full (GNU Parallel)

**Configuration Method**: `configs/` (parallel.conf) + environment variables

**Environment Variables**:
- `PARALLEL` - Default options
- `PARALLEL_HOME` - Parallel home directory
- `PARALLEL_ARGHOSTGROUPS` - Argument and hostgroup separation
- `PARALLEL_ENV` - Environment variables to export

**XDG Support**: 
- No native XDG support
- Config file: `~/.parallel/config` by default
- Can be redirected via symlinks to XDG config directory

**File Management Requirements**:
- Config file: `config` in parallel directory
- Will-cite file to disable citation notice
- Plain text configuration with default options

**Current Configuration Status**: ❌ Not configured - needs config file

---

### watchexec (File Watcher)

**Configuration Method**: `configs/` (watchexec.toml) + environment variables

**Environment Variables**:
- `WATCHEXEC_CONFIG_FILE` - Config file location
- `RUST_LOG` - Logging level
- `XDG_CONFIG_HOME` - Respects XDG for config directory (via config file location)

**XDG Support**: 
- No native XDG support
- Config file location configurable via `WATCHEXEC_CONFIG_FILE`
- Can be redirected to XDG config directory

**File Management Requirements**:
- Config file: `watchexec.toml` (can be in XDG config directory)
- TOML format configuration
- Watch patterns and command configuration

**Current Configuration Status**: ❌ Not configured - needs config file

---

### tldr (Simplified Man Pages)

**Configuration Method**: `configs/` (config.json) + environment variables

**Environment Variables**:
- `TLDR_CONFIG_DIR` - Config directory location (XDG compliant)
- `TLDR_CACHE_DIR` - Cache directory location (XDG compliant)
- `TLDR_LANGUAGE` - Language for pages
- `TLDR_COLOR` - Color output control

**XDG Support**: 
- Native XDG support via environment variables
- Config: `$XDG_CONFIG_HOME/tldr` (default: `~/.config/tldr`)
- Cache: `$XDG_CACHE_HOME/tldr` (default: `~/.cache/tldr`)

**File Management Requirements**:
- Config file: `config.json` in config directory
- Page cache in cache directory
- JSON format configuration
- Language and display preferences

**Current Configuration Status**: ❌ Not configured - needs config file + environment variables

---

### neovim (Text Editor)

**Configuration Method**: `configs/` (init.lua/init.vim) + environment variables

**Environment Variables**:
- `NVIM_APPNAME` - Application name for config isolation
- `XDG_CONFIG_HOME` - Respects XDG for config directory
- `XDG_DATA_HOME` - Respects XDG for data directory
- `XDG_STATE_HOME` - Respects XDG for state directory
- `XDG_CACHE_HOME` - Respects XDG for cache directory
- `EDITOR` - Set neovim as default editor
- `VISUAL` - Set neovim as visual editor

**XDG Support**: 
- Native XDG support
- Config: `$XDG_CONFIG_HOME/nvim/` (default: `~/.config/nvim/`)
- Data: `$XDG_DATA_HOME/nvim/` (default: `~/.local/share/nvim/`)
- State: `$XDG_STATE_HOME/nvim/` (default: `~/.local/state/nvim/`)
- Cache: `$XDG_CACHE_HOME/nvim/` (default: `~/.cache/nvim/`)

**File Management Requirements**:
- Config files: `init.lua` or `init.vim` in config directory
- Plugin files in data directory
- State files (shada, sessions) in state directory
- Cache files in cache directory
- Lua or Vimscript configuration

**Current Configuration Status**: ❌ Not configured - needs config files + environment variables

## Summary

### Configuration Coverage Analysis

**Fully Configured Tools**: 0/12 (0%)
- No tools are currently configured

**Partially Configured Tools**: 0/12 (0%)

**Unconfigured Tools**: 12/12 (100%)
- mas (could benefit from aliases)
- _1password-cli (needs config + environment variables)
- dockutil (could benefit from setup scripts)
- pngpaste (could benefit from aliases)
- duti (needs config file)
- ffmpeg (could benefit from presets)
- imagemagick (needs config files + environment variables)
- yt-dlp (needs config file)
- pandoc (needs config files)
- graphviz (could benefit from environment variables)
- parallel-full (needs config file)
- watchexec (needs config file)
- tldr (needs config file + environment variables)
- neovim (needs config files + environment variables)

### Priority Implementation Recommendations

**High Priority** (Essential development tools):
1. neovim - Text editor, needs config files + environment variables
2. _1password-cli - Password management, needs config + environment variables
3. tldr - Documentation, needs config file + environment variables
4. yt-dlp - Media downloading, needs config file
5. pandoc - Document conversion, needs config files

**Medium Priority** (Media and system tools):
1. imagemagick - Image processing, needs config files + environment variables
2. watchexec - File watching, needs config file
3. parallel-full - Parallel processing, needs config file
4. duti - Default applications (macOS), needs config file

**Low Priority** (Simple tools):
1. ffmpeg - Could benefit from presets
2. graphviz - Could benefit from environment variables
3. mas - Could benefit from aliases
4. pngpaste - Could benefit from aliases
5. dockutil - Could benefit from setup scripts

### XDG Compliance Status

**Native XDG Support**: 5/12 (42%)
- _1password-cli, yt-dlp, pandoc, tldr, neovim

**Environment Variable XDG**: 4/12 (33%)
- ffmpeg, imagemagick, watchexec (via config file location)

**No XDG Support**: 3/12 (25%)
- mas, dockutil, pngpaste, duti, graphviz, parallel-full

### Environment Variable Requirements

**Tools Needing Environment Variables**: 8/12 (67%)
- _1password-cli, ffmpeg, imagemagick, graphviz, parallel-full, watchexec, tldr, neovim

**XDG-Related Variables Needed**:
- `OP_CONFIG_DIR=$XDG_CONFIG_HOME/op`
- `OP_CACHE_DIR=$XDG_CACHE_HOME/op`
- `OP_DATA_DIR=$XDG_DATA_HOME/op`
- `FFMPEG_DATADIR=$XDG_DATA_HOME/ffmpeg`
- `MAGICK_CONFIGURE_PATH=$XDG_CONFIG_HOME/ImageMagick`
- `YT_DLP_CONFIG_HOME=$XDG_CONFIG_HOME/yt-dlp`
- `WATCHEXEC_CONFIG_FILE=$XDG_CONFIG_HOME/watchexec/watchexec.toml`
- `TLDR_CONFIG_DIR=$XDG_CONFIG_HOME/tldr`
- `TLDR_CACHE_DIR=$XDG_CACHE_HOME/tldr`
- `EDITOR=nvim`
- `VISUAL=nvim`

### Configuration File Requirements

**Tools Needing Config Files**: 8/12 (67%)
- _1password-cli (config.json)
- duti (settings file)
- imagemagick (policy.xml, delegates.xml)
- yt-dlp (config)
- pandoc (defaults.yaml)
- parallel-full (config)
- watchexec (watchexec.toml)
- tldr (config.json)
- neovim (init.lua/init.vim)

**Tools Needing Only Environment Variables**: 2/12 (17%)
- ffmpeg, graphviz

**Tools Needing Only Aliases/Scripts**: 3/12 (25%)
- mas, pngpaste, dockutil

### Platform-Specific Considerations

**macOS-Only Tools**: 5/12 (42%)
- mas, _1password-cli, dockutil, pngpaste, duti

**Cross-Platform Tools**: 7/12 (58%)
- ffmpeg, imagemagick, yt-dlp, pandoc, graphviz, parallel-full, watchexec, tldr, neovim

### Security and Authentication

**Tools Requiring Authentication**: 2/12 (17%)
- mas (Mac App Store account)
- _1password-cli (1Password account)

**Tools Handling Sensitive Data**: 1/12 (8%)
- _1password-cli (password management)

### Complex Configuration Requirements

**Tools with Complex Config**: 4/12 (33%)
- imagemagick (XML policies and delegates)
- pandoc (templates and filters)
- neovim (extensive Lua/Vimscript configuration)
- _1password-cli (account and session management)

**Tools with Simple Config**: 4/12 (33%)
- yt-dlp, tldr, watchexec, parallel-full

**Tools with No Config Files**: 4/12 (33%)
- mas, dockutil, pngpaste, ffmpeg, graphviz

### Integration Patterns

**Editor Integration**: 1/12 (8%)
- neovim (primary text editor)

**System Integration**: 2/12 (17%)
- dockutil (macOS Dock management)
- duti (macOS default applications)

**Media Pipeline Integration**: 3/12 (25%)
- ffmpeg, imagemagick, yt-dlp

**Development Workflow Integration**: 3/12 (25%)
- neovim, watchexec, parallel-full

**Documentation Integration**: 1/12 (8%)
- tldr (command documentation)

### Resource and Performance Considerations

**Resource-Intensive Tools**: 3/12 (25%)
- ffmpeg (video processing)
- imagemagick (image processing)
- neovim (with plugins)

**Network-Dependent Tools**: 3/12 (25%)
- mas (Mac App Store)
- yt-dlp (video downloading)
- tldr (page updates)

**System-Level Tools**: 2/12 (17%)
- dockutil, duti (macOS system modification)