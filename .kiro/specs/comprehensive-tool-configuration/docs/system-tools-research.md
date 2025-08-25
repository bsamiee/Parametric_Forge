# System Utilities and Monitoring Tools Configuration Research

## Research Overview

This document provides comprehensive research on system utilities and monitoring tools configuration capabilities, environment variables, XDG Base Directory support, and file management requirements. All information has been validated against current tool versions and official documentation.

## System Monitoring Tools

### procs (Modern ps Replacement)

**Configuration Method**: `configs/` (config.toml) + environment variables

**Environment Variables**:
- `PROCS_CONFIG` - Config file location
- `XDG_CONFIG_HOME` - Respects XDG for config directory (via config file location)

**XDG Support**: 
- No native XDG support
- Config file location configurable via `PROCS_CONFIG`
- Can be redirected to XDG config directory

**File Management Requirements**:
- Config file: `config.toml` (can be in XDG config directory)
- TOML format configuration
- Column customization and color themes

**Current Configuration Status**: ❌ Not configured - needs config file

---

### bottom (System Monitor)

**Configuration Method**: `configs/` (bottom.toml) + environment variables + command-line flags

**Environment Variables**:
- `BOTTOM_CONFIG_PATH` - Config file location
- `XDG_CONFIG_HOME` - Respects XDG for config directory (via config file location)

**XDG Support**: 
- No native XDG support
- Config file location configurable via `BOTTOM_CONFIG_PATH`
- Default: `~/.config/bottom/bottom.toml`
- Can be redirected to XDG config directory

**File Management Requirements**:
- Config file: `bottom.toml` in XDG config directory
- TOML format configuration
- UI customization, keybindings, and display options

**Current Configuration Status**: ❌ Not configured - needs config file

---

### duf (Disk Usage/Free Utility)

**Configuration Method**: Environment variables + command-line options

**Environment Variables**:
- `DUF_WARNINGS` - Show/hide warnings
- No configuration file support

**XDG Support**: 
- No configuration files
- No XDG requirements

**File Management Requirements**:
- No configuration files
- All configuration via command-line options
- Can be wrapped with shell aliases

**Current Configuration Status**: ❌ Not configured - could benefit from aliases

---

### dust (Disk Usage Tool)

**Configuration Method**: `configs/` (config.toml) + environment variables

**Environment Variables**:
- `DUST_CONFIG` - Config file location
- No XDG-specific environment variables

**XDG Support**: 
- No native XDG support
- Config file location configurable via `DUST_CONFIG`
- Can be redirected to XDG config directory

**File Management Requirements**:
- Config file: `config.toml` (can be in XDG config directory)
- TOML format configuration
- Display options and exclusion patterns

**Current Configuration Status**: ❌ Not configured - needs config file

## Network Tools

### xh (HTTPie-like HTTP Client)

**Configuration Method**: `configs/` (config.json) + environment variables

**Environment Variables**:
- `XH_CONFIG_DIR` - Config directory location (XDG compliant)
- `XH_HTTPIE_COMPAT_MODE` - HTTPie compatibility mode
- `NO_COLOR` - Disable colored output
- `FORCE_COLOR` - Force colored output

**XDG Support**: 
- Native XDG support via `XH_CONFIG_DIR`
- Config: `$XDG_CONFIG_HOME/xh` (default: `~/.config/xh`)
- Config file: `config.json` in config directory

**File Management Requirements**:
- Config file: `config.json` in XDG config directory
- Session files in config directory
- JSON format configuration
- Authentication and default options

**Current Configuration Status**: ❌ Not configured - needs config file

---

### doggo (DNS Client)

**Configuration Method**: `configs/` (config.yaml) + environment variables

**Environment Variables**:
- `DOGGO_CONFIG` - Config file location
- `XDG_CONFIG_HOME` - Respects XDG for config directory (via config file location)

**XDG Support**: 
- No native XDG support
- Config file location configurable via `DOGGO_CONFIG`
- Can be redirected to XDG config directory

**File Management Requirements**:
- Config file: `config.yaml` (can be in XDG config directory)
- YAML format configuration
- DNS server configuration and query defaults

**Current Configuration Status**: ❌ Not configured - needs config file

---

### gping (Ping with Graph)

**Configuration Method**: Command-line options only

**Environment Variables**:
- No specific environment variables
- Respects standard terminal color environment variables

**XDG Support**: 
- No configuration files
- No XDG requirements

**File Management Requirements**:
- No configuration files
- All configuration via command-line options
- Can be wrapped with shell aliases

**Current Configuration Status**: ❌ Not configured - could benefit from aliases

---

### mtr (Network Diagnostic Tool)

**Configuration Method**: `configs/` (.mtrrc) + environment variables

**Environment Variables**:
- `MTR_OPTIONS` - Default options
- `MTR_PACKET` - Packet type
- No XDG-specific environment variables

**XDG Support**: 
- No native XDG support
- Config file: `~/.mtrrc` by default
- Can be symlinked from XDG config directory

**File Management Requirements**:
- Config file: `.mtrrc` in home directory (can be symlinked from XDG)
- Plain text configuration file
- Default options and packet settings

**Current Configuration Status**: ❌ Not configured - needs config file

---

### bandwhich (Network Utilization Monitor)

**Configuration Method**: Command-line options only

**Environment Variables**:
- No specific environment variables
- Requires root privileges for full functionality

**XDG Support**: 
- No configuration files
- No XDG requirements

**File Management Requirements**:
- No configuration files
- All configuration via command-line options
- Requires elevated privileges for network monitoring

**Current Configuration Status**: ❌ Not configured - could benefit from aliases

---

### iperf (Network Performance Tool)

**Configuration Method**: Command-line options only

**Environment Variables**:
- No specific environment variables

**XDG Support**: 
- No configuration files
- No XDG requirements

**File Management Requirements**:
- No configuration files
- All configuration via command-line options
- Can be wrapped with shell aliases for common tests

**Current Configuration Status**: ❌ Not configured - could benefit from aliases

## Archive Tools

### ouch (Archive Tool)

**Configuration Method**: `configs/` (config.yaml) + environment variables

**Environment Variables**:
- `OUCH_CONFIG` - Config file location
- `XDG_CONFIG_HOME` - Respects XDG for config directory (via config file location)

**XDG Support**: 
- No native XDG support
- Config file location configurable via `OUCH_CONFIG`
- Can be redirected to XDG config directory

**File Management Requirements**:
- Config file: `config.yaml` (can be in XDG config directory)
- YAML format configuration
- Default compression levels and formats

**Current Configuration Status**: ❌ Not configured - needs config file

---

### Compression Utilities (gzip, bzip2, xz, zstd)

**Configuration Method**: Environment variables + command-line options

**Environment Variables**:
- `GZIP` - Default gzip options
- `BZIP2` - Default bzip2 options
- `XZ_OPT` - Default xz options
- `ZSTD_CLEVEL` - Default zstd compression level
- `ZSTD_NBTHREADS` - Number of threads for zstd

**XDG Support**: 
- No configuration files
- No XDG requirements

**File Management Requirements**:
- No configuration files
- All configuration via environment variables and command-line options
- Can be wrapped with shell aliases

**Current Configuration Status**: ❌ Not configured - needs environment variables

## Terminal Utilities

### hexyl (Hex Viewer)

**Configuration Method**: Command-line options + environment variables

**Environment Variables**:
- `NO_COLOR` - Disable colored output
- `FORCE_COLOR` - Force colored output
- No configuration file support

**XDG Support**: 
- No configuration files
- No XDG requirements

**File Management Requirements**:
- No configuration files
- All configuration via command-line options
- Can be wrapped with shell aliases

**Current Configuration Status**: ❌ Not configured - could benefit from aliases

---

### tokei (Code Statistics Tool)

**Configuration Method**: `configs/` (.tokeirc) + environment variables

**Environment Variables**:
- `TOKEI_CONFIG` - Config file location
- `XDG_CONFIG_HOME` - Respects XDG for config directory (via config file location)

**XDG Support**: 
- No native XDG support
- Config file location configurable via `TOKEI_CONFIG`
- Can be redirected to XDG config directory

**File Management Requirements**:
- Config file: `.tokeirc` (can be in XDG config directory)
- TOML format configuration
- Language definitions and exclusion patterns

**Current Configuration Status**: ❌ Not configured - needs config file

---

### file (File Type Detection)

**Configuration Method**: System magic files + environment variables

**Environment Variables**:
- `MAGIC` - Magic file location
- No user configuration files

**XDG Support**: 
- No user configuration files
- Uses system magic files
- No XDG requirements

**File Management Requirements**:
- System magic files: `/usr/share/misc/magic`
- No user configuration files
- Custom magic files can be specified via `MAGIC`

**Current Configuration Status**: ❌ Not configured - could benefit from custom magic files

## Summary

### Configuration Coverage Analysis

**Fully Configured Tools**: 0/15 (0%)
- No tools are currently configured

**Partially Configured Tools**: 0/15 (0%)

**Unconfigured Tools**: 15/15 (100%)
- procs (needs config file)
- bottom (needs config file)
- duf (could benefit from aliases)
- dust (needs config file)
- xh (needs config file)
- doggo (needs config file)
- gping (could benefit from aliases)
- mtr (needs config file)
- bandwhich (could benefit from aliases)
- iperf (could benefit from aliases)
- ouch (needs config file)
- compression utilities (need environment variables)
- hexyl (could benefit from aliases)
- tokei (needs config file)
- file (could benefit from custom magic files)

### Priority Implementation Recommendations

**High Priority** (Essential system tools):
1. bottom - System monitor, needs config file
2. xh - HTTP client, needs config file
3. procs - Process monitor, needs config file
4. ouch - Archive tool, needs config file
5. tokei - Code statistics, needs config file

**Medium Priority** (Network and monitoring):
1. doggo - DNS client, needs config file
2. dust - Disk usage, needs config file
3. mtr - Network diagnostic, needs config file
4. compression utilities - Need environment variables

**Low Priority** (Simple tools):
1. duf - Could benefit from aliases
2. gping - Could benefit from aliases
3. bandwhich - Could benefit from aliases
4. iperf - Could benefit from aliases
5. hexyl - Could benefit from aliases
6. file - Could benefit from custom magic files

### XDG Compliance Status

**Native XDG Support**: 1/15 (7%)
- xh

**Environment Variable XDG**: 8/15 (53%)
- procs, bottom, dust, doggo, ouch, tokei (via config file location)

**No XDG Support**: 6/15 (40%)
- duf, gping, mtr, bandwhich, iperf, hexyl, file, compression utilities

### Environment Variable Requirements

**Tools Needing Environment Variables**: 10/15 (67%)
- procs, bottom, dust, xh, doggo, ouch, tokei, compression utilities

**XDG-Related Variables Needed**:
- `PROCS_CONFIG=$XDG_CONFIG_HOME/procs/config.toml`
- `BOTTOM_CONFIG_PATH=$XDG_CONFIG_HOME/bottom/bottom.toml`
- `DUST_CONFIG=$XDG_CONFIG_HOME/dust/config.toml`
- `XH_CONFIG_DIR=$XDG_CONFIG_HOME/xh`
- `DOGGO_CONFIG=$XDG_CONFIG_HOME/doggo/config.yaml`
- `OUCH_CONFIG=$XDG_CONFIG_HOME/ouch/config.yaml`
- `TOKEI_CONFIG=$XDG_CONFIG_HOME/tokei/.tokeirc`

### Configuration File Requirements

**Tools Needing Config Files**: 8/15 (53%)
- procs (config.toml)
- bottom (bottom.toml)
- dust (config.toml)
- xh (config.json)
- doggo (config.yaml)
- mtr (.mtrrc)
- ouch (config.yaml)
- tokei (.tokeirc)

**Tools Needing Only Environment Variables**: 1/15 (7%)
- compression utilities

**Tools Needing Only Aliases**: 6/15 (40%)
- duf, gping, bandwhich, iperf, hexyl

**Tools Needing Custom Files**: 1/15 (7%)
- file (custom magic files)

### Tool Categories by Configuration Complexity

**Complex Configuration** (Config files + environment variables):
- bottom, xh, procs, dust, doggo, ouch, tokei

**Simple Configuration** (Environment variables only):
- compression utilities

**Minimal Configuration** (Aliases sufficient):
- duf, gping, bandwhich, iperf, hexyl

**Special Cases**:
- mtr (needs config file but no XDG support)
- file (could benefit from custom magic files)

### Performance and Resource Considerations

**Resource-Intensive Tools**: 3/15 (20%)
- bottom (continuous system monitoring)
- bandwhich (network monitoring, requires root)
- procs (process monitoring)

**Network Tools**: 5/15 (33%)
- xh, doggo, gping, mtr, bandwhich, iperf

**File System Tools**: 4/15 (27%)
- dust, duf, ouch, file

**Development Tools**: 1/15 (7%)
- tokei

**General Utilities**: 2/15 (13%)
- hexyl, compression utilities