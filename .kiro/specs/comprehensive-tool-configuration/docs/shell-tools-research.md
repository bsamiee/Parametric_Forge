# Shell Enhancement Tools Configuration Research

## Research Overview

This document provides comprehensive research on shell enhancement tools configuration capabilities, environment variables, XDG Base Directory support, and file management requirements. All information has been validated against current tool versions and official documentation.

## Navigation and Directory Tools

### zoxide (Smart Directory Jumper)

**Configuration Method**: `programs/` (home-manager zoxide module) + environment variables

**Environment Variables**:
- `_ZO_DATA_DIR` - Data directory location (XDG compliant)
- `_ZO_ECHO` - Echo the matched directory before navigating
- `_ZO_EXCLUDE_DIRS` - Directories to exclude from database
- `_ZO_FZF_OPTS` - Options to pass to fzf
- `_ZO_MAXAGE` - Maximum age of entries in database
- `_ZO_RESOLVE_SYMLINKS` - Resolve symlinks when adding directories

**XDG Support**: 
- Native XDG support via `_ZO_DATA_DIR`
- Data: `$XDG_DATA_HOME/zoxide` (default: `~/.local/share/zoxide`)
- Database file: `db.zo` in data directory

**File Management Requirements**:
- Database file: `db.zo` in XDG data directory
- No configuration files - all via environment variables and programs module
- Shell integration handled by programs module

**Current Configuration Status**: ❌ Not configured - needs programs module

---

### starship (Cross-shell Prompt)

**Configuration Method**: `programs/` (home-manager starship module) + `configs/` (starship.toml)

**Environment Variables**:
- `STARSHIP_CONFIG` - Config file location (XDG compliant)
- `STARSHIP_CACHE` - Cache directory location (XDG compliant)
- `STARSHIP_SESSION_KEY` - Session key for caching
- `STARSHIP_SHELL` - Shell being used

**XDG Support**: 
- Native XDG support
- Config: `$XDG_CONFIG_HOME/starship.toml` (default: `~/.config/starship.toml`)
- Cache: `$XDG_CACHE_HOME/starship` (default: `~/.cache/starship`)

**File Management Requirements**:
- Config file: `starship.toml` in XDG config directory
- Cache files in XDG cache directory
- Large config file suitable for `configs/` directory

**Current Configuration Status**: ✅ Configured in `programs/shell-tools.nix` and `configs/apps/starship.toml`

---

### direnv (Environment Variable Manager)

**Configuration Method**: `programs/` (home-manager direnv module) + `configs/` (direnvrc)

**Environment Variables**:
- `DIRENV_CONFIG` - Config directory location
- `DIRENV_LOG_FORMAT` - Log format for direnv output
- `XDG_CONFIG_HOME` - Respects XDG for config directory

**XDG Support**: 
- Native XDG support
- Config: `$XDG_CONFIG_HOME/direnv/` (default: `~/.config/direnv/`)
- Config file: `direnvrc` in config directory

**File Management Requirements**:
- Config file: `direnvrc` in XDG config directory
- Project-specific: `.envrc` files in project directories
- Allow file: `allow` directory for trusted .envrc files

**Current Configuration Status**: ❌ Not configured - needs programs module + config

---

### fzf (Fuzzy Finder)

**Configuration Method**: `programs/` (home-manager fzf module) + environment variables

**Environment Variables**:
- `FZF_DEFAULT_COMMAND` - Default command for file search
- `FZF_DEFAULT_OPTS` - Default options for fzf
- `FZF_CTRL_T_COMMAND` - Command for Ctrl-T file search
- `FZF_CTRL_T_OPTS` - Options for Ctrl-T
- `FZF_CTRL_R_OPTS` - Options for Ctrl-R history search
- `FZF_ALT_C_COMMAND` - Command for Alt-C directory search
- `FZF_ALT_C_OPTS` - Options for Alt-C

**XDG Support**: 
- No configuration files - all via environment variables
- History files can be redirected to XDG directories via shell config

**File Management Requirements**:
- No configuration files
- Shell integration files managed by programs module
- History integration with shell history files

**Current Configuration Status**: ❌ Not configured - needs programs module

---

### vivid (LS_COLORS Generator)

**Configuration Method**: Environment variables + `configs/` (themes)

**Environment Variables**:
- `LS_COLORS` - Generated color configuration
- `VIVID_DATABASE` - Custom database directory

**XDG Support**: 
- No native XDG support
- Custom themes can be stored anywhere
- Database files can be placed in XDG config directory

**File Management Requirements**:
- Theme files: YAML format in custom directory
- Database files for color definitions
- Generated `LS_COLORS` environment variable

**Current Configuration Status**: ❌ Not configured - needs theme files + environment variable

---

### mcfly (Shell History Search)

**Configuration Method**: `programs/` (home-manager mcfly module) + environment variables

**Environment Variables**:
- `MCFLY_KEY_SCHEME` - Key binding scheme (emacs/vim)
- `MCFLY_FUZZY` - Fuzzy search factor (0-2)
- `MCFLY_RESULTS` - Number of results to show
- `MCFLY_RESULTS_SORT` - Sort order for results
- `MCFLY_INTERFACE_VIEW` - Interface view (TOP/BOTTOM)
- `MCFLY_DISABLE_MENU` - Disable the selection menu
- `MCFLY_LIGHT` - Light mode for terminal
- `MCFLY_HISTORY_LIMIT` - Maximum history entries

**XDG Support**: 
- Database stored in `~/.local/share/mcfly/` by default
- Can be redirected to XDG data directory

**File Management Requirements**:
- Database file: `history.db` in data directory
- No configuration files - all via environment variables
- Shell integration handled by programs module

**Current Configuration Status**: ❌ Not configured - needs programs module

## File and Content Tools

### eza (Modern ls Replacement)

**Configuration Method**: Environment variables + `configs/` (optional aliases)

**Environment Variables**:
- `EZA_COLORS` - Color configuration
- `EZA_ICON_SPACING` - Spacing for icons
- `EZA_GRID_ROWS` - Number of rows in grid view
- `EZA_STRICT` - Strict mode for parsing
- `TIME_STYLE` - Time format style

**XDG Support**: 
- No configuration files
- All configuration via environment variables and command-line options
- No XDG requirements

**File Management Requirements**:
- No configuration files
- Color configuration via environment variables
- Alias definitions can be stored in shell configs

**Current Configuration Status**: ❌ Not configured - needs environment variables

---

### bat (Cat with Syntax Highlighting)

**Configuration Method**: `programs/` (home-manager bat module) + environment variables

**Environment Variables**:
- `BAT_CONFIG_PATH` - Config file location
- `BAT_THEME` - Default theme
- `BAT_STYLE` - Default style options
- `BAT_TABS` - Tab width
- `BAT_PAGER` - Pager to use
- `BAT_PAGING` - Paging behavior

**XDG Support**: 
- Native XDG support via `BAT_CONFIG_PATH`
- Config: `$XDG_CONFIG_HOME/bat/config` (default: `~/.config/bat/config`)
- Themes: `$XDG_CONFIG_HOME/bat/themes/`

**File Management Requirements**:
- Config file: `config` in XDG config directory
- Theme files: `*.tmTheme` in themes subdirectory
- Syntax files: `*.sublime-syntax` in syntaxes subdirectory

**Current Configuration Status**: ❌ Not configured - needs programs module + config

---

### ripgrep (Fast Text Search)

**Configuration Method**: `configs/` (.ripgreprc) + environment variables

**Environment Variables**:
- `RIPGREP_CONFIG_PATH` - Config file location (XDG compliant)
- `GREP_COLORS` - Color configuration (fallback)

**XDG Support**: 
- Partial XDG support via `RIPGREP_CONFIG_PATH`
- Config can be placed in `$XDG_CONFIG_HOME/ripgrep/config`
- Default: `~/.ripgreprc`

**File Management Requirements**:
- Config file: `.ripgreprc` or custom location via environment variable
- Plain text configuration file with command-line options
- Can be symlinked from XDG config directory

**Current Configuration Status**: ❌ Not configured - needs config file

---

### fd (Fast File Search)

**Configuration Method**: Environment variables + command-line options

**Environment Variables**:
- `FD_OPTIONS` - Default options (unofficial)
- No official configuration file support

**XDG Support**: 
- No configuration files
- No XDG requirements

**File Management Requirements**:
- No configuration files
- All configuration via command-line options
- Can be wrapped with shell aliases/functions

**Current Configuration Status**: ❌ Not configured - could benefit from aliases

---

### broot (Directory Tree Navigator)

**Configuration Method**: `configs/` (conf.hjson) + environment variables

**Environment Variables**:
- `BR_INSTALL` - Installation directory
- `BROOT_CONFIG_DIR` - Config directory location

**XDG Support**: 
- Partial XDG support via `BROOT_CONFIG_DIR`
- Config: `$XDG_CONFIG_HOME/broot/` or `~/.config/broot/`
- Config file: `conf.hjson` in config directory

**File Management Requirements**:
- Config file: `conf.hjson` in config directory
- Verb files: Custom command definitions
- Skin files: Color and style definitions
- HJSON format (Human JSON)

**Current Configuration Status**: ❌ Not configured - needs config files

## File Manager Tools

### yazi (Terminal File Manager)

**Configuration Method**: `configs/` (yazi.toml, keymap.toml, theme.toml)

**Environment Variables**:
- `YAZI_CONFIG_HOME` - Config directory location (XDG compliant)
- `YAZI_FILE_ONE` - File for single file selection
- `EDITOR` - Editor for file editing

**XDG Support**: 
- Native XDG support via `YAZI_CONFIG_HOME`
- Config: `$XDG_CONFIG_HOME/yazi/` (default: `~/.config/yazi/`)
- State: `$XDG_STATE_HOME/yazi/` (default: `~/.local/state/yazi/`)

**File Management Requirements**:
- Config files: `yazi.toml`, `keymap.toml`, `theme.toml` in config directory
- Plugin files: Lua scripts in plugins subdirectory
- State files: History, bookmarks in state directory
- TOML format configuration

**Current Configuration Status**: ❌ Not configured - needs config files

---

### lf (Terminal File Manager)

**Configuration Method**: `configs/` (lfrc)

**Environment Variables**:
- `LF_CONFIG_HOME` - Config directory location
- `EDITOR` - Editor for file editing
- `PAGER` - Pager for file viewing
- `SHELL` - Shell for command execution

**XDG Support**: 
- Partial XDG support via `LF_CONFIG_HOME`
- Config: `$XDG_CONFIG_HOME/lf/lfrc` or `~/.config/lf/lfrc`
- No standard data/state directory support

**File Management Requirements**:
- Config file: `lfrc` in config directory
- Custom command scripts can be referenced
- History and bookmarks in config directory

**Current Configuration Status**: ❌ Not configured - needs config file

---

### ranger (Python File Manager)

**Configuration Method**: `configs/` (rc.conf, rifle.conf, scope.sh)

**Environment Variables**:
- `RANGER_LOAD_DEFAULT_RC` - Load default configuration
- `EDITOR` - Editor for file editing
- `PAGER` - Pager for file viewing
- `SHELL` - Shell for command execution

**XDG Support**: 
- Native XDG support
- Config: `$XDG_CONFIG_HOME/ranger/` (default: `~/.config/ranger/`)
- Data: `$XDG_DATA_HOME/ranger/` (default: `~/.local/share/ranger/`)

**File Management Requirements**:
- Config files: `rc.conf`, `rifle.conf`, `scope.sh` in config directory
- Commands: `commands.py` for custom commands
- Colorschemes: Python files in colorschemes subdirectory
- Bookmarks and history in data directory

**Current Configuration Status**: ❌ Not configured - needs config files

---

### nnn (Terminal File Manager)

**Configuration Method**: Environment variables + plugins

**Environment Variables**:
- `NNN_OPTS` - Default options
- `NNN_PLUG` - Plugin key bindings
- `NNN_BMS` - Bookmark definitions
- `NNN_COLORS` - Color configuration
- `NNN_FCOLORS` - File type colors
- `NNN_ARCHIVE` - Archive handling command
- `NNN_DE_FILE_MANAGER` - Desktop file manager
- `NNN_OPENER` - File opener command
- `NNN_TMPFILE` - Temporary file for shell integration

**XDG Support**: 
- No configuration files
- All configuration via environment variables
- Plugin directory can be placed anywhere

**File Management Requirements**:
- No configuration files
- Plugin scripts in custom directory
- Shell integration via temporary files
- All configuration via environment variables

**Current Configuration Status**: ❌ Not configured - needs environment variables

## Summary

### Configuration Coverage Analysis

**Fully Configured Tools**: 1/12 (8%)
- starship ✅

**Partially Configured Tools**: 0/12 (0%)

**Unconfigured Tools**: 11/12 (92%)
- zoxide (needs programs module)
- direnv (needs programs + config)
- fzf (needs programs module)
- vivid (needs theme files + env vars)
- mcfly (needs programs module)
- eza (needs environment variables)
- bat (needs programs + config)
- ripgrep (needs config file)
- fd (could benefit from aliases)
- broot (needs config files)
- yazi (needs config files)
- lf (needs config file)
- ranger (needs config files)
- nnn (needs environment variables)

### Priority Implementation Recommendations

**High Priority** (Essential shell enhancements):
1. fzf - Fuzzy finder, needs programs module
2. bat - Syntax highlighting, needs programs + config
3. ripgrep - Text search, needs config file
4. zoxide - Directory navigation, needs programs module
5. eza - Modern ls, needs environment variables

**Medium Priority** (Productivity tools):
1. direnv - Environment management, needs programs + config
2. yazi - Modern file manager, needs config files
3. mcfly - History search, needs programs module
4. vivid - LS_COLORS, needs theme files

**Low Priority** (Alternative tools):
1. broot - Tree navigator, needs config files
2. lf - File manager alternative, needs config file
3. ranger - Python file manager, needs config files
4. nnn - Minimal file manager, needs environment variables
5. fd - File search (simple aliases sufficient)

### XDG Compliance Status

**Native XDG Support**: 6/12 (50%)
- starship, direnv, yazi, ranger, zoxide, bat

**Environment Variable XDG**: 4/12 (33%)
- broot, lf, ripgrep, vivid

**No XDG Support**: 2/12 (17%)
- fzf, eza, fd, nnn, mcfly

### Environment Variable Requirements

**Tools Needing Environment Variables**: 10/12 (83%)
- All tools except starship and ranger (which use config files primarily)

**XDG-Related Variables Needed**:
- `_ZO_DATA_DIR=$XDG_DATA_HOME/zoxide`
- `STARSHIP_CONFIG=$XDG_CONFIG_HOME/starship.toml`
- `STARSHIP_CACHE=$XDG_CACHE_HOME/starship`
- `BAT_CONFIG_PATH=$XDG_CONFIG_HOME/bat/config`
- `RIPGREP_CONFIG_PATH=$XDG_CONFIG_HOME/ripgrep/config`
- `BROOT_CONFIG_DIR=$XDG_CONFIG_HOME/broot`
- `YAZI_CONFIG_HOME=$XDG_CONFIG_HOME/yazi`
- `LF_CONFIG_HOME=$XDG_CONFIG_HOME/lf`

### Configuration File Requirements

**Tools Needing Config Files**: 8/12 (67%)
- starship (starship.toml) ✅
- direnv (direnvrc)
- vivid (theme files)
- bat (config + themes)
- ripgrep (.ripgreprc)
- broot (conf.hjson)
- yazi (yazi.toml, keymap.toml, theme.toml)
- lf (lfrc)
- ranger (rc.conf, rifle.conf, scope.sh)

**Programs Module Candidates**: 6/12 (50%)
- zoxide, fzf, direnv, mcfly, bat, starship ✅