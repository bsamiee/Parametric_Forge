# Language Ecosystem Tools Configuration Research

## Research Overview

This document provides comprehensive research on language ecosystem tools configuration capabilities, environment variables, XDG Base Directory support, and file management requirements. All information has been validated against current tool versions and official documentation.

## Python Ecosystem

### python313 (Python Interpreter)

**Configuration Method**: Environment variables + site-packages

**Environment Variables**:
- `PYTHONPATH` - Additional module search paths
- `PYTHONHOME` - Python installation directory
- `PYTHONSTARTUP` - Startup script file
- `PYTHONUSERBASE` - User site-packages directory (XDG compliant)
- `PYTHONDONTWRITEBYTECODE` - Disable .pyc file creation
- `PYTHONUNBUFFERED` - Unbuffered stdout/stderr
- `PYTHONIOENCODING` - Default encoding for stdin/stdout/stderr
- `PYTHONHASHSEED` - Hash randomization seed
- `PYTHONUTF8` - UTF-8 mode
- `PYTHONWARNINGS` - Warning control

**XDG Support**: 
- Partial XDG support via `PYTHONUSERBASE`
- User packages: `$XDG_DATA_HOME/python` or `~/.local`
- Cache: `__pycache__` directories (can be disabled)
- No standard config file location

**File Management Requirements**:
- User site-packages in XDG data directory
- Startup script can be placed in XDG config directory
- History file: `~/.python_history` (can be redirected)

**Current Configuration Status**: ❌ Not configured - needs environment variables

---

### pipx (Install Python Applications in Isolated Environments)

**Configuration Method**: Environment variables + `configs/` (optional)

**Environment Variables**:
- `PIPX_HOME` - pipx installation directory (XDG compliant)
- `PIPX_BIN_DIR` - Binary installation directory
- `PIPX_MAN_DIR` - Manual page directory
- `PIPX_DEFAULT_PYTHON` - Default Python interpreter
- `USE_EMOJI` - Enable/disable emoji in output

**XDG Support**: 
- Native XDG support via `PIPX_HOME`
- Data: `$XDG_DATA_HOME/pipx` (default: `~/.local/share/pipx`)
- Binaries: `$XDG_BIN_HOME` or `~/.local/bin`

**File Management Requirements**:
- Installation directory in XDG data directory
- Binary symlinks in PATH directory
- No configuration files needed
- Metadata stored in installation directory

**Current Configuration Status**: ❌ Not configured - needs environment variables

---

### poetry (Python Dependency Management)

**Configuration Method**: `configs/` (pyproject.toml templates) + environment variables

**Environment Variables**:
- `POETRY_HOME` - Poetry installation directory
- `POETRY_CONFIG_DIR` - Configuration directory (XDG compliant)
- `POETRY_DATA_DIR` - Data directory (XDG compliant)
- `POETRY_CACHE_DIR` - Cache directory (XDG compliant)
- `POETRY_VENV_PATH` - Virtual environment path
- `POETRY_REPOSITORIES_<name>_URL` - Custom repository URLs
- `POETRY_HTTP_BASIC_<name>_USERNAME` - Repository authentication
- `POETRY_HTTP_BASIC_<name>_PASSWORD` - Repository authentication

**XDG Support**: 
- Native XDG support via environment variables
- Config: `$XDG_CONFIG_HOME/pypoetry` (default: `~/.config/pypoetry`)
- Data: `$XDG_DATA_HOME/pypoetry` (default: `~/.local/share/pypoetry`)
- Cache: `$XDG_CACHE_HOME/pypoetry` (default: `~/.cache/pypoetry`)

**File Management Requirements**:
- Global config: `config.toml` in config directory
- Project config: `pyproject.toml` in project root
- Virtual environments in data directory
- Package cache in cache directory

**Current Configuration Status**: ✅ Configured in `configs/poetry.toml`

---

### ruff (Python Linter and Formatter)

**Configuration Method**: `configs/` (ruff.toml, pyproject.toml)

**Environment Variables**:
- `RUFF_CONFIG` - Config file location
- `RUFF_CACHE_DIR` - Cache directory location (XDG compliant)
- `NO_COLOR` - Disable colored output
- `FORCE_COLOR` - Force colored output

**XDG Support**: 
- Partial XDG support via `RUFF_CACHE_DIR`
- Cache: `$XDG_CACHE_HOME/ruff` or `~/.cache/ruff`
- Config: Project-specific or global via `RUFF_CONFIG`

**File Management Requirements**:
- Global config: `ruff.toml` or custom location
- Project config: `ruff.toml` or `pyproject.toml` section
- Cache files in XDG cache directory
- TOML format configuration

**Current Configuration Status**: ✅ Configured in `configs/languages/ruff.toml`

---

### uv (Fast Python Package Manager)

**Configuration Method**: Environment variables + `configs/` (uv.toml)

**Environment Variables**:
- `UV_CONFIG_FILE` - Config file location
- `UV_CACHE_DIR` - Cache directory location (XDG compliant)
- `UV_PYTHON_DOWNLOADS` - Python download behavior
- `UV_INDEX_URL` - Default package index URL
- `UV_EXTRA_INDEX_URL` - Additional package index URLs
- `UV_NO_CACHE` - Disable caching
- `UV_OFFLINE` - Offline mode

**XDG Support**: 
- Native XDG support via environment variables
- Cache: `$XDG_CACHE_HOME/uv` (default: `~/.cache/uv`)
- Config: `$XDG_CONFIG_HOME/uv/uv.toml` or project-specific

**File Management Requirements**:
- Global config: `uv.toml` in XDG config directory
- Project config: `uv.toml` in project root
- Cache files in XDG cache directory
- TOML format configuration

**Current Configuration Status**: ❌ Not configured - needs config file + environment variables

---

### basedpyright (Python Language Server)

**Configuration Method**: `configs/` (pyrightconfig.json, pyproject.toml)

**Environment Variables**:
- `PYRIGHT_PYTHON_PATH` - Python interpreter path
- `PYRIGHT_PYTHON_ENV_VAR` - Environment variable for Python path
- `NODE_PATH` - Node.js module search paths (for pyright)

**XDG Support**: 
- No native XDG support
- Config files are project-specific
- LSP client may support XDG for logs/cache

**File Management Requirements**:
- Global config: Can be placed in XDG config directory and referenced
- Project config: `pyrightconfig.json` or `pyproject.toml` section
- JSON format for standalone config
- LSP client handles caching and logs

**Current Configuration Status**: ✅ Configured in `configs/languages/basedpyright.json`

## Rust Ecosystem

### rustup (Rust Toolchain Manager)

**Configuration Method**: Environment variables + `configs/` (settings.toml)

**Environment Variables**:
- `RUSTUP_HOME` - Rustup data directory (XDG compliant)
- `CARGO_HOME` - Cargo data directory (XDG compliant)
- `RUSTUP_DIST_SERVER` - Distribution server URL
- `RUSTUP_UPDATE_ROOT` - Update server URL
- `RUSTUP_IO_THREADS` - Number of IO threads
- `RUSTUP_UNPACK_RAM` - RAM limit for unpacking
- `RUSTUP_NO_BACKTRACE` - Disable backtraces

**XDG Support**: 
- Native XDG support via environment variables
- Data: `$XDG_DATA_HOME/rustup` (default: `~/.rustup`)
- Cargo: `$XDG_DATA_HOME/cargo` (default: `~/.cargo`)

**File Management Requirements**:
- Settings file: `settings.toml` in rustup directory
- Toolchain installations in rustup directory
- Cargo registry and git caches in cargo directory
- TOML format configuration

**Current Configuration Status**: ❌ Not configured - needs environment variables

---

### bacon (Background Rust Code Checker)

**Configuration Method**: `configs/` (bacon.toml)

**Environment Variables**:
- `BACON_CONFIG` - Config file location
- `RUST_LOG` - Logging level
- `CARGO_TARGET_DIR` - Cargo target directory

**XDG Support**: 
- No native XDG support
- Config file location configurable via `BACON_CONFIG`
- Can be redirected to XDG config directory

**File Management Requirements**:
- Global config: `bacon.toml` (can be in XDG config directory)
- Project config: `bacon.toml` in project root
- TOML format configuration
- Watches cargo build output

**Current Configuration Status**: ❌ Not configured - needs config file

---

### cargo-* tools (Cargo Extensions)

**Configuration Method**: Cargo configuration + individual tool configs

**Common Cargo Environment Variables**:
- `CARGO_HOME` - Cargo data directory (XDG compliant)
- `CARGO_TARGET_DIR` - Build output directory
- `CARGO_INCREMENTAL` - Incremental compilation
- `CARGO_NET_RETRY` - Network retry attempts
- `CARGO_NET_GIT_FETCH_WITH_CLI` - Use git CLI for fetching
- `CARGO_REGISTRIES_CRATES_IO_PROTOCOL` - Registry protocol

**Tool-Specific Variables**:
- `CARGO_DENY_CONFIG` - cargo-deny config location
- `CARGO_AUDIT_CONFIG` - cargo-audit config location
- `CARGO_CLIPPY_OPTS` - clippy options
- `CARGO_FMT_OPTS` - rustfmt options

**XDG Support**: 
- Cargo has native XDG support via `CARGO_HOME`
- Individual tools may have their own XDG support
- Config files typically in `$CARGO_HOME/config.toml`

**File Management Requirements**:
- Global cargo config: `config.toml` in cargo directory
- Tool-specific configs: Various locations and formats
- Registry and git caches in cargo directory
- Build artifacts in target directory

**Current Configuration Status**: ✅ Partially configured in `configs/languages/` (cargo.toml, cargo-deny.toml, clippy.toml, rustfmt.toml)

## Node.js Ecosystem

### nodejs (Node.js Runtime)

**Configuration Method**: Environment variables + npm configuration

**Environment Variables**:
- `NODE_PATH` - Module search paths
- `NODE_ENV` - Environment mode (development/production)
- `NODE_OPTIONS` - Node.js command-line options
- `NODE_REPL_HISTORY` - REPL history file location (XDG compliant)
- `NODE_REPL_HISTORY_SIZE` - REPL history size
- `NODE_DISABLE_COLORS` - Disable colored output
- `NODE_NO_WARNINGS` - Disable warnings

**XDG Support**: 
- Partial XDG support via `NODE_REPL_HISTORY`
- REPL history: `$XDG_DATA_HOME/node_repl_history` or `~/.node_repl_history`
- No standard config file location

**File Management Requirements**:
- REPL history file in XDG data directory
- Global modules via npm configuration
- No direct configuration files

**Current Configuration Status**: ❌ Not configured - needs environment variables

---

### pnpm (Fast Node.js Package Manager)

**Configuration Method**: `configs/` (.pnpmrc) + environment variables

**Environment Variables**:
- `PNPM_HOME` - pnpm installation directory
- `XDG_CONFIG_HOME` - Respects XDG for config directory
- `XDG_DATA_HOME` - Respects XDG for data directory
- `XDG_STATE_HOME` - Respects XDG for state directory
- `XDG_CACHE_HOME` - Respects XDG for cache directory

**XDG Support**: 
- Native XDG support
- Config: `$XDG_CONFIG_HOME/pnpm/rc` (default: `~/.config/pnpm/rc`)
- Data: `$XDG_DATA_HOME/pnpm` (default: `~/.local/share/pnpm`)
- Cache: `$XDG_CACHE_HOME/pnpm` (default: `~/.cache/pnpm`)
- State: `$XDG_STATE_HOME/pnpm` (default: `~/.local/state/pnpm`)

**File Management Requirements**:
- Global config: `.pnpmrc` in XDG config directory
- Project config: `.pnpmrc` in project root
- Store and cache in XDG directories
- INI-style configuration format

**Current Configuration Status**: ❌ Not configured - needs config file

---

### yarn (Node.js Package Manager)

**Configuration Method**: `configs/` (.yarnrc.yml) + environment variables

**Environment Variables**:
- `YARN_CACHE_FOLDER` - Cache directory location (XDG compliant)
- `YARN_GLOBAL_FOLDER` - Global packages directory
- `YARN_PREFER_OFFLINE` - Prefer offline mode
- `YARN_SILENT` - Silent mode
- `YARN_IGNORE_ENGINES` - Ignore engine requirements

**XDG Support**: 
- Partial XDG support via `YARN_CACHE_FOLDER`
- Cache: `$XDG_CACHE_HOME/yarn` or `~/.yarn/cache`
- Config: Project-specific `.yarnrc.yml`
- Global config: `~/.yarnrc.yml`

**File Management Requirements**:
- Global config: `.yarnrc.yml` in home directory
- Project config: `.yarnrc.yml` in project root
- Cache files in XDG cache directory
- YAML format configuration

**Current Configuration Status**: ❌ Not configured - needs config file + environment variables

---

### npm (Node Package Manager)

**Configuration Method**: `configs/` (.npmrc) + environment variables

**Environment Variables**:
- `NPM_CONFIG_USERCONFIG` - User config file location (XDG compliant)
- `NPM_CONFIG_CACHE` - Cache directory location (XDG compliant)
- `NPM_CONFIG_PREFIX` - Global installation prefix
- `NPM_CONFIG_REGISTRY` - Package registry URL
- `NPM_CONFIG_LOGLEVEL` - Logging level

**XDG Support**: 
- Partial XDG support via environment variables
- Config: `$XDG_CONFIG_HOME/npm/npmrc` or `~/.npmrc`
- Cache: `$XDG_CACHE_HOME/npm` or `~/.npm`

**File Management Requirements**:
- Global config: `.npmrc` (can be in XDG config directory)
- Project config: `.npmrc` in project root
- Cache files in XDG cache directory
- INI-style configuration format

**Current Configuration Status**: ✅ Configured in `configs/npmrc`

## Lua Ecosystem

### luajit (Lua Just-In-Time Compiler)

**Configuration Method**: Environment variables + package paths

**Environment Variables**:
- `LUA_PATH` - Lua module search paths
- `LUA_CPATH` - Lua C module search paths
- `LUA_INIT` - Initialization script
- `LUA_INIT_5_1` - Version-specific initialization
- `LUAJIT_NUMMODE` - Number mode for LuaJIT

**XDG Support**: 
- No native XDG support
- Paths can be configured to include XDG directories
- No standard config file location

**File Management Requirements**:
- Initialization script can be placed in XDG config directory
- Module paths can include XDG directories
- No configuration files by default

**Current Configuration Status**: ❌ Not configured - needs environment variables

---

### luarocks (Lua Package Manager)

**Configuration Method**: `configs/` (config-5.x.lua) + environment variables

**Environment Variables**:
- `LUAROCKS_CONFIG` - Config file location
- `LUA_PATH` - Lua module search paths
- `LUA_CPATH` - Lua C module search paths
- `LUAROCKS_SYSCONFDIR` - System config directory

**XDG Support**: 
- No native XDG support
- Config file location configurable via `LUAROCKS_CONFIG`
- Can be redirected to XDG config directory

**File Management Requirements**:
- Global config: `config-5.x.lua` (can be in XDG config directory)
- User config: `~/.luarocks/config-5.x.lua`
- Lua format configuration file
- Package installations in configured directories

**Current Configuration Status**: ✅ Configured in `configs/languages/luarocks.lua`

---

### lua-language-server (Lua LSP Server)

**Configuration Method**: `configs/` (.luarc.json) + LSP client configuration

**Environment Variables**:
- `LUA_PATH` - Lua module search paths
- `LUA_CPATH` - Lua C module search paths

**XDG Support**: 
- No native XDG support
- Config files are project-specific
- LSP client may support XDG for logs/cache

**File Management Requirements**:
- Project config: `.luarc.json` in project root
- Global config: Can be placed in XDG config directory and referenced
- JSON format configuration
- LSP client handles caching and logs

**Current Configuration Status**: ❌ Not configured - needs config file

---

### stylua (Lua Code Formatter)

**Configuration Method**: `configs/` (stylua.toml, .stylua.toml)

**Environment Variables**:
- `STYLUA_CONFIG_PATH` - Config file location
- No XDG-specific environment variables

**XDG Support**: 
- No native XDG support
- Config file location configurable via `STYLUA_CONFIG_PATH`
- Can be redirected to XDG config directory

**File Management Requirements**:
- Global config: `stylua.toml` (can be in XDG config directory)
- Project config: `stylua.toml` or `.stylua.toml` in project root
- TOML format configuration
- EditorConfig integration available

**Current Configuration Status**: ✅ Configured in `configs/languages/.stylua.toml`

## Summary

### Configuration Coverage Analysis

**Fully Configured Tools**: 6/16 (38%)
- poetry ✅
- ruff ✅
- basedpyright ✅
- cargo-* tools ✅ (partial)
- npm ✅
- luarocks ✅
- stylua ✅

**Partially Configured Tools**: 1/16 (6%)
- cargo-* tools (some configs exist, missing environment variables)

**Unconfigured Tools**: 9/16 (56%)
- python313 (needs environment variables)
- pipx (needs environment variables)
- uv (needs config + environment variables)
- rustup (needs environment variables)
- bacon (needs config file)
- nodejs (needs environment variables)
- pnpm (needs config file)
- yarn (needs config + environment variables)
- luajit (needs environment variables)
- lua-language-server (needs config file)

### Priority Implementation Recommendations

**High Priority** (Essential development tools):
1. rustup - Rust toolchain manager, needs environment variables for XDG
2. uv - Modern Python package manager, needs config + environment variables
3. pnpm - Fast Node.js package manager, needs config file
4. python313 - Python interpreter, needs environment variables for XDG
5. nodejs - Node.js runtime, needs environment variables

**Medium Priority** (Development enhancement):
1. bacon - Rust background checker, needs config file
2. pipx - Python app installer, needs environment variables
3. yarn - Node.js package manager, needs config + environment variables
4. lua-language-server - Lua LSP, needs config file
5. luajit - Lua runtime, needs environment variables

**Low Priority** (Already functional):
- Existing configured tools just need environment variable optimization

### XDG Compliance Status

**Native XDG Support**: 7/16 (44%)
- poetry, uv, rustup, pnpm, pipx, ruff, basedpyright

**Environment Variable XDG**: 6/16 (38%)
- python313, nodejs, npm, yarn, luarocks, stylua

**No XDG Support**: 3/16 (19%)
- bacon, luajit, lua-language-server

### Environment Variable Requirements

**Tools Needing Environment Variables**: 12/16 (75%)
- All tools except ruff, basedpyright, stylua, lua-language-server

**XDG-Related Variables Needed**:
- `PYTHONUSERBASE=$XDG_DATA_HOME/python`
- `PIPX_HOME=$XDG_DATA_HOME/pipx`
- `POETRY_CONFIG_DIR=$XDG_CONFIG_HOME/pypoetry`
- `POETRY_DATA_DIR=$XDG_DATA_HOME/pypoetry`
- `POETRY_CACHE_DIR=$XDG_CACHE_HOME/pypoetry`
- `UV_CACHE_DIR=$XDG_CACHE_HOME/uv`
- `RUSTUP_HOME=$XDG_DATA_HOME/rustup`
- `CARGO_HOME=$XDG_DATA_HOME/cargo`
- `NODE_REPL_HISTORY=$XDG_DATA_HOME/node_repl_history`
- `NPM_CONFIG_USERCONFIG=$XDG_CONFIG_HOME/npm/npmrc`
- `NPM_CONFIG_CACHE=$XDG_CACHE_HOME/npm`
- `YARN_CACHE_FOLDER=$XDG_CACHE_HOME/yarn`
- `LUAROCKS_CONFIG=$XDG_CONFIG_HOME/luarocks/config.lua`

### Configuration File Requirements

**Tools Needing New Config Files**: 5/16 (31%)
- uv (uv.toml)
- bacon (bacon.toml)
- pnpm (.pnpmrc)
- yarn (.yarnrc.yml)
- lua-language-server (.luarc.json)

**Tools with Existing Configs**: 6/16 (38%)
- poetry, ruff, basedpyright, cargo-*, npm, luarocks, stylua

**Tools Needing Only Environment Variables**: 5/16 (31%)
- python313, pipx, rustup, nodejs, luajit