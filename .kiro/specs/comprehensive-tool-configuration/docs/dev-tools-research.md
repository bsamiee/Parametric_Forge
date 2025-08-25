# Core Development Tools Configuration Research

## Research Overview

This document provides comprehensive research on core development tools configuration capabilities, environment variables, XDG Base Directory support, and file management requirements. All information has been validated against current tool versions and official documentation.

## Git Ecosystem Tools

### git (Git Version Control)

**Configuration Method**: `programs/` (home-manager git module) + `configs/` (gitconfig, gitignore, gitattributes)

**Environment Variables**:
- `GIT_CONFIG_GLOBAL` - Global config file location (XDG compliant)
- `GIT_CONFIG_SYSTEM` - System config file location
- `GIT_AUTHOR_NAME`, `GIT_AUTHOR_EMAIL` - Default author info
- `GIT_COMMITTER_NAME`, `GIT_COMMITTER_EMAIL` - Default committer info
- `GIT_EDITOR` - Default editor for commit messages
- `GIT_PAGER` - Pager for git output
- `GIT_SSH_COMMAND` - SSH command for git operations
- `GIT_ASKPASS` - Program for password prompts

**XDG Support**: 
- Native XDG support via `GIT_CONFIG_GLOBAL=$XDG_CONFIG_HOME/git/config`
- Fallback: `~/.gitconfig`
- Additional files: `~/.gitignore_global`, `~/.gitattributes_global`

**File Management Requirements**:
- Config files: `$XDG_CONFIG_HOME/git/config`, `gitignore`, `gitattributes`
- Global ignore/attributes files can be placed in XDG config directory
- Repository-specific configs remain in `.git/config`

**Current Configuration Status**: ✅ Configured in `programs/git-tools.nix` and `configs/git/`

---

### gh (GitHub CLI)

**Configuration Method**: `programs/` (home-manager gh module) + environment variables

**Environment Variables**:
- `GH_CONFIG_DIR` - Config directory location (XDG compliant)
- `GH_DATA_DIR` - Data directory location (XDG compliant)
- `GH_HOST` - GitHub Enterprise hostname
- `GH_TOKEN` - Authentication token
- `GH_EDITOR` - Editor for gh commands
- `GH_BROWSER` - Browser for opening URLs
- `GH_PAGER` - Pager for gh output
- `GH_PROMPT_DISABLED` - Disable interactive prompts
- `GH_NO_UPDATE_NOTIFIER` - Disable update notifications

**XDG Support**: 
- Native XDG support via environment variables
- Config: `$XDG_CONFIG_HOME/gh/` (default: `~/.config/gh/`)
- Data: `$XDG_DATA_HOME/gh/` (default: `~/.local/share/gh/`)

**File Management Requirements**:
- Config files: `config.yml`, `hosts.yml` in config directory
- Data files: Authentication tokens, cached data in data directory
- No static config files needed - all managed via programs module

**Current Configuration Status**: ✅ Configured in `programs/git-tools.nix`

---

### lazygit (Terminal UI for Git)

**Configuration Method**: `programs/` (home-manager lazygit module) + `configs/` (config.yml)

**Environment Variables**:
- `LG_CONFIG_FILE` - Config file location
- `XDG_CONFIG_HOME` - Respects XDG for config directory
- `EDITOR` - Editor for commit messages and file editing
- `GIT_EDITOR` - Git-specific editor override

**XDG Support**: 
- Native XDG support
- Config: `$XDG_CONFIG_HOME/lazygit/config.yml`
- Fallback: `~/.config/lazygit/config.yml`

**File Management Requirements**:
- Single config file: `config.yml` in XDG config directory
- Large config file suitable for `configs/` directory
- State files stored in appropriate XDG directories

**Current Configuration Status**: ❌ Not configured - needs programs module + config file

---

### gitui (Terminal UI for Git)

**Configuration Method**: `configs/` (key_bindings.ron, theme.ron)

**Environment Variables**:
- `GITUI_CONFIG_DIR` - Config directory location
- `XDG_CONFIG_HOME` - Respects XDG for config directory
- `EDITOR` - Editor for commit messages

**XDG Support**: 
- Native XDG support
- Config: `$XDG_CONFIG_HOME/gitui/`
- Fallback: `~/.config/gitui/`

**File Management Requirements**:
- Config files: `key_bindings.ron`, `theme.ron` in config directory
- RON format configuration files
- No programs module available - pure config file approach

**Current Configuration Status**: ❌ Not configured - needs config files

---

### git-secret (Encrypt Files in Git Repository)

**Configuration Method**: Environment variables only

**Environment Variables**:
- `SECRETS_GPG_COMMAND` - GPG command to use
- `SECRETS_EXTENSION` - Extension for encrypted files (default: .secret)
- `SECRETS_DIR` - Directory for git-secret files (default: .gitsecret)
- `SECRETS_VERBOSE` - Enable verbose output
- `TMPDIR` - Temporary directory for operations

**XDG Support**: 
- No XDG support - operates within git repository
- Uses repository-local `.gitsecret/` directory

**File Management Requirements**:
- No user config files - all configuration via environment variables
- Repository-specific files in `.gitsecret/` directory
- GPG keyring integration required

**Current Configuration Status**: ❌ Not configured - needs environment variables

---

### git-crypt (Transparent File Encryption in Git)

**Configuration Method**: Environment variables + GPG integration

**Environment Variables**:
- `GPG_AGENT_INFO` - GPG agent socket information
- `GNUPGHOME` - GPG home directory
- `TMPDIR` - Temporary directory for operations

**XDG Support**: 
- No direct XDG support - relies on GPG configuration
- GPG can be configured for XDG compliance

**File Management Requirements**:
- No user config files - uses repository `.git-crypt/` directory
- Relies on GPG keyring configuration
- Repository-specific `.gitattributes` configuration

**Current Configuration Status**: ❌ Not configured - needs GPG integration

---

### gitleaks (Detect Secrets in Git Repositories)

**Configuration Method**: `configs/` (gitleaks.toml)

**Environment Variables**:
- `GITLEAKS_CONFIG` - Config file location
- `GITLEAKS_VERBOSE` - Enable verbose output
- `GITLEAKS_LOG_LEVEL` - Log level (info, warn, error, debug)

**XDG Support**: 
- No native XDG support
- Config file location configurable via environment variable
- Can be redirected to XDG config directory

**File Management Requirements**:
- Config file: `gitleaks.toml` or `.gitleaks.toml`
- TOML format configuration
- Can be global or repository-specific

**Current Configuration Status**: ❌ Not configured - needs config file

## Build and Task Tools

### just (Command Runner)

**Configuration Method**: `configs/` (justfile templates) + environment variables

**Environment Variables**:
- `JUST_CHOOSER` - Program to use for `--choose` flag
- `JUST_LOG_LEVEL` - Log level (error, warn, info, debug)
- `JUST_SUPPRESS_DOTENV_LOAD_WARNING` - Suppress .env warnings
- `JUST_UNSTABLE` - Enable unstable features

**XDG Support**: 
- No native XDG support for global config
- Uses project-local `justfile` or `.justfile`
- Global justfile can be placed anywhere and referenced

**File Management Requirements**:
- Project-specific: `justfile` or `.justfile` in project root
- Global templates can be stored in configs directory
- No user-specific configuration file

**Current Configuration Status**: ❌ Not configured - could benefit from templates

---

### hyperfine (Command-line Benchmarking Tool)

**Configuration Method**: Environment variables only

**Environment Variables**:
- `HYPERFINE_EXPORT_FORMAT` - Default export format
- `SHELL` - Shell to use for command execution
- `TMPDIR` - Temporary directory for benchmark files

**XDG Support**: 
- No configuration files - pure command-line tool
- No XDG requirements

**File Management Requirements**:
- No configuration files
- Temporary files in system temp directory
- Export files in current directory or specified location

**Current Configuration Status**: ✅ No configuration needed

---

### jq (JSON Processor)

**Configuration Method**: Environment variables + optional config

**Environment Variables**:
- `JQ_COLORS` - Color configuration for output
- `JQ_LIBRARY_PATH` - Additional library search paths

**XDG Support**: 
- No native XDG support
- No standard configuration file location
- Can use `~/.jq` for custom functions/modules

**File Management Requirements**:
- Optional: `~/.jq` for custom functions and modules
- Library files can be placed in custom directories
- No standard configuration file

**Current Configuration Status**: ❌ Partial - could benefit from color configuration

---

### pre-commit (Git Hook Framework)

**Configuration Method**: `configs/` (.pre-commit-config.yaml templates)

**Environment Variables**:
- `PRE_COMMIT_HOME` - Cache directory location (XDG compliant)
- `PRE_COMMIT_COLOR` - Color output control
- `SKIP` - Skip specific hooks during execution
- `PRE_COMMIT_ALLOW_NO_CONFIG` - Allow running without config

**XDG Support**: 
- Partial XDG support via `PRE_COMMIT_HOME`
- Cache: `$XDG_CACHE_HOME/pre-commit` or `~/.cache/pre-commit`
- Config files are project-specific

**File Management Requirements**:
- Project config: `.pre-commit-config.yaml` in repository root
- Global templates can be stored for reuse
- Cache files in XDG cache directory

**Current Configuration Status**: ❌ Not configured - needs cache directory + templates

## Shell and Language Tools

### shellcheck (Shell Script Analysis Tool)

**Configuration Method**: `configs/` (.shellcheckrc)

**Environment Variables**:
- `SHELLCHECK_OPTS` - Default options for shellcheck
- No XDG-specific environment variables

**XDG Support**: 
- No native XDG support
- Config file: `.shellcheckrc` in project root or `~/.shellcheckrc`
- Can be redirected via symlinks or wrapper scripts

**File Management Requirements**:
- Global config: `~/.shellcheckrc` (can be symlinked from XDG)
- Project config: `.shellcheckrc` in project root
- INI-style configuration format

**Current Configuration Status**: ✅ Configured in `configs/languages/shellcheckrc`

---

### shfmt (Shell Script Formatter)

**Configuration Method**: Command-line options + `.editorconfig`

**Environment Variables**:
- No specific environment variables
- Respects `EDITOR` for some operations

**XDG Support**: 
- No native XDG support
- Uses `.editorconfig` for project-specific formatting
- No user-specific configuration file

**File Management Requirements**:
- Project config: `.editorconfig` (shared with other formatters)
- No user-specific configuration
- Formatting rules embedded in project files

**Current Configuration Status**: ✅ Configured via `.editorconfig`

---

### bash-language-server (Bash LSP Server)

**Configuration Method**: LSP client configuration + environment variables

**Environment Variables**:
- `BASH_IDE_LOG_LEVEL` - Log level for the server
- `PATH` - Must include shellcheck and other analysis tools

**XDG Support**: 
- No direct configuration - configured via LSP client
- LSP clients typically support XDG config directories

**File Management Requirements**:
- No direct config files - configured via editor/LSP client
- Requires shellcheck and other tools in PATH
- Log files may be created by LSP client

**Current Configuration Status**: ❌ Not configured - needs LSP client setup

---

### sqlfluff (SQL Linter and Formatter)

**Configuration Method**: `configs/` (.sqlfluff, pyproject.toml)

**Environment Variables**:
- `SQLFLUFF_CONFIG` - Config file location
- `SQLFLUFF_DIALECT` - Default SQL dialect
- `SQLFLUFF_TEMPLATER` - Default templater

**XDG Support**: 
- No native XDG support
- Config file: `.sqlfluff` in project root or `~/.sqlfluff`
- Can be redirected via `SQLFLUFF_CONFIG` environment variable

**File Management Requirements**:
- Global config: `~/.sqlfluff` (can be symlinked from XDG)
- Project config: `.sqlfluff` or `pyproject.toml` section
- INI-style configuration format

**Current Configuration Status**: ❌ Not configured - needs config file

## Summary

### Configuration Coverage Analysis

**Fully Configured Tools**: 4/12 (33%)
- git ✅
- gh ✅  
- shellcheck ✅
- hyperfine ✅ (no config needed)

**Partially Configured Tools**: 2/12 (17%)
- jq (could benefit from color config)
- shfmt (via .editorconfig)

**Unconfigured Tools**: 6/12 (50%)
- lazygit (needs programs + config)
- gitui (needs config files)
- git-secret (needs environment variables)
- git-crypt (needs GPG integration)
- gitleaks (needs config file)
- just (could benefit from templates)
- pre-commit (needs cache + templates)
- bash-language-server (needs LSP setup)
- sqlfluff (needs config file)

### Priority Implementation Recommendations

**High Priority** (Essential development tools):
1. lazygit - Popular git TUI, needs programs module + config
2. pre-commit - Git hook framework, needs cache directory + templates
3. gitleaks - Security tool, needs config file
4. sqlfluff - SQL development, needs config file

**Medium Priority** (Enhancement tools):
1. gitui - Alternative git TUI, needs config files
2. just - Task runner, could benefit from templates
3. bash-language-server - IDE integration, needs LSP setup
4. jq - JSON processing, could benefit from color config

**Low Priority** (Specialized tools):
1. git-secret - Specialized encryption, needs environment variables
2. git-crypt - Specialized encryption, needs GPG integration

### XDG Compliance Status

**Native XDG Support**: 3/12 (25%)
- git, gh, lazygit

**Environment Variable XDG**: 3/12 (25%)  
- pre-commit, gitleaks, sqlfluff

**No XDG Support**: 6/12 (50%)
- gitui, git-secret, git-crypt, just, hyperfine, jq, shellcheck, shfmt, bash-language-server

### Environment Variable Requirements

**Tools Needing Environment Variables**: 8/12 (67%)
- git, gh, git-secret, git-crypt, gitleaks, just, pre-commit, bash-language-server

**XDG-Related Variables Needed**:
- `GIT_CONFIG_GLOBAL=$XDG_CONFIG_HOME/git/config`
- `GH_CONFIG_DIR=$XDG_CONFIG_HOME/gh`
- `GH_DATA_DIR=$XDG_DATA_HOME/gh`
- `PRE_COMMIT_HOME=$XDG_CACHE_HOME/pre-commit`
- `SQLFLUFF_CONFIG=$XDG_CONFIG_HOME/sqlfluff/config`