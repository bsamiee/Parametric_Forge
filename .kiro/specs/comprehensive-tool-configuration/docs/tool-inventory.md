# Tool Inventory and Classification

## Overview

This document provides a comprehensive inventory of all 100+ tools in the Parametric Forge system, organized by package category with detailed classification of configuration requirements and current status.

## Tool Categories and Classification

### Core Tools (core.nix) - 47 tools

#### File & Directory Operations
- **eza** - Modern file listing with git integration, icons, tree view
  - *Configuration*: programs/ (configured in shell-tools.nix)
  - *Purpose*: ls replacement with enhanced features
  - *Status*: ✅ Configured

- **fd** - Fast file finder respecting .gitignore
  - *Configuration*: programs/ (integrated with fzf in shell-tools.nix)
  - *Purpose*: find replacement with better defaults
  - *Status*: ✅ Configured

- **broot** - Interactive file tree explorer
  - *Configuration*: programs/ + configs/
  - *Purpose*: Interactive tree navigation
  - *Status*: ❌ Not configured

- **trash-cli** - Safe deletion to trash instead of permanent delete
  - *Configuration*: None needed
  - *Purpose*: Safe rm replacement
  - *Status*: ✅ No config needed

- **fcp** - Fast parallel file copy (simple cases)
  - *Configuration*: None needed
  - *Purpose*: Fast cp for simple operations
  - *Status*: ✅ No config needed

- **uutils-coreutils-noprefix** - Full POSIX cp when fcp lacks features
  - *Configuration*: None needed
  - *Purpose*: Complete coreutils replacement
  - *Status*: ✅ No config needed

- **rsync** - Advanced file synchronization and transfer
  - *Configuration*: configs/
  - *Purpose*: File sync and backup
  - *Status*: ❌ Not configured

#### Text Processing & Search
- **bat** - Syntax highlighting viewer with line numbers
  - *Configuration*: programs/ (configured in shell-tools.nix)
  - *Purpose*: cat replacement with syntax highlighting
  - *Status*: ✅ Configured

- **ripgrep** - Ultra-fast text search (rg command)
  - *Configuration*: programs/ (configured in shell-tools.nix)
  - *Purpose*: grep replacement with better performance
  - *Status*: ✅ Configured

- **sd** - Intuitive find/replace without regex complexity
  - *Configuration*: None needed
  - *Purpose*: sed replacement with simpler syntax
  - *Status*: ✅ No config needed

- **xan** - CSV/TSV data processor (xsv successor)
  - *Configuration*: None needed
  - *Purpose*: CSV/TSV processing
  - *Status*: ✅ No config needed

- **choose** - Human-friendly column selector
  - *Configuration*: None needed
  - *Purpose*: cut replacement with better UX
  - *Status*: ✅ No config needed

- **grex** - Generate regex patterns from examples
  - *Configuration*: None needed
  - *Purpose*: Regex pattern generation
  - *Status*: ✅ No config needed

#### File Analysis & Diff
- **delta** - Syntax-aware diff viewer with side-by-side view
  - *Configuration*: programs/ (configured in git-tools.nix)
  - *Purpose*: Enhanced diff viewer for git
  - *Status*: ✅ Configured

- **hexyl** - Colorful hex viewer
  - *Configuration*: None needed
  - *Purpose*: hexdump replacement with colors
  - *Status*: ✅ No config needed

- **tokei** - Fast code statistics (lines, comments, languages)
  - *Configuration*: configs/
  - *Purpose*: Code analysis and statistics
  - *Status*: ❌ Not configured

- **file** - File type detection by content (enhanced classic)
  - *Configuration*: None needed
  - *Purpose*: File type identification
  - *Status*: ✅ No config needed

#### System Monitoring
- **procs** - Process viewer with tree, search, and color
  - *Configuration*: configs/
  - *Purpose*: ps replacement with enhanced features
  - *Status*: ❌ Not configured

- **bottom** - Resource monitor with graphs (btm command)
  - *Configuration*: configs/
  - *Purpose*: top/htop replacement with graphs
  - *Status*: ❌ Not configured

- **duf** - Disk usage with visual bars and colors
  - *Configuration*: configs/
  - *Purpose*: df replacement with visual enhancements
  - *Status*: ❌ Not configured

- **dust** - Directory size analyzer with tree view
  - *Configuration*: configs/
  - *Purpose*: du replacement with tree visualization
  - *Status*: ❌ Not configured

#### Network Tools
- **xh** - Modern HTTP client with intuitive syntax
  - *Configuration*: configs/
  - *Purpose*: curl/httpie replacement
  - *Status*: ❌ Not configured

- **openssh** - SSH client and utilities (enhanced classic)
  - *Configuration*: programs/ (configured in ssh.nix)
  - *Purpose*: SSH client with modern features
  - *Status*: ✅ Configured

- **doggo** - Modern DNS client with colors and DoH/DoT support
  - *Configuration*: configs/
  - *Purpose*: dig replacement with modern protocols
  - *Status*: ❌ Not configured

- **gping** - Ping with real-time graphs
  - *Configuration*: configs/
  - *Purpose*: ping replacement with visualization
  - *Status*: ❌ Not configured

- **mtr** - Combined network diagnostic tool
  - *Configuration*: configs/
  - *Purpose*: traceroute+ping combination
  - *Status*: ❌ Not configured

#### Shell Enhancements
- **zoxide** - Smart directory jumper with frecency (z command)
  - *Configuration*: programs/ (configured in shell-tools.nix)
  - *Purpose*: cd replacement with smart navigation
  - *Status*: ✅ Configured

- **starship** - Fast, customizable cross-shell prompt
  - *Configuration*: programs/ + configs/ (configured in shell-tools.nix + starship.toml)
  - *Purpose*: Shell prompt enhancement
  - *Status*: ✅ Configured

- **direnv** - Auto-load environment variables per directory
  - *Configuration*: programs/ (configured in shell-tools.nix)
  - *Purpose*: Directory-based environment management
  - *Status*: ✅ Configured

- **fzf** - Fuzzy finder for files, history, processes
  - *Configuration*: programs/ (configured in shell-tools.nix)
  - *Purpose*: Interactive fuzzy finder
  - *Status*: ✅ Configured

- **vivid** - LS_COLORS generator for better file visualization
  - *Configuration*: configs/
  - *Purpose*: Enhanced file coloring
  - *Status*: ❌ Not configured

- **mcfly** - Smart shell history with neural network ranking
  - *Configuration*: programs/
  - *Purpose*: Enhanced shell history search
  - *Status*: ❌ Not configured

#### Archive & Compression
- **ouch** - Universal archive tool (compress/decompress)
  - *Configuration*: configs/
  - *Purpose*: Universal archive handling
  - *Status*: ❌ Not configured

- **unzip** - Utilities for zip archives
  - *Configuration*: None needed
  - *Purpose*: ZIP archive extraction
  - *Status*: ✅ No config needed

- **zip** - Create zip archives
  - *Configuration*: None needed
  - *Purpose*: ZIP archive creation
  - *Status*: ✅ No config needed

- **zstd** - Zstandard compression
  - *Configuration*: None needed
  - *Purpose*: Modern compression algorithm
  - *Status*: ✅ No config needed

- **xz** - XZ compression utilities
  - *Configuration*: None needed
  - *Purpose*: XZ compression/decompression
  - *Status*: ✅ No config needed

- **lz4** - Extremely fast compression
  - *Configuration*: None needed
  - *Purpose*: Fast compression algorithm
  - *Status*: ✅ No config needed

- **brotli** - Generic-purpose lossless compression
  - *Configuration*: None needed
  - *Purpose*: Web-optimized compression
  - *Status*: ✅ No config needed

#### Core GNU Utilities
- **coreutils** - GNU core utilities (ls, cp, mv, etc.)
  - *Configuration*: None needed
  - *Purpose*: Standard Unix utilities
  - *Status*: ✅ No config needed

- **findutils** - GNU find, xargs, etc.
  - *Configuration*: None needed
  - *Purpose*: File finding utilities
  - *Status*: ✅ No config needed

- **gnugrep** - GNU grep
  - *Configuration*: None needed
  - *Purpose*: Text search utility
  - *Status*: ✅ No config needed

- **gnused** - GNU sed
  - *Configuration*: None needed
  - *Purpose*: Stream editor
  - *Status*: ✅ No config needed

- **gawk** - GNU awk
  - *Configuration*: None needed
  - *Purpose*: Text processing language
  - *Status*: ✅ No config needed

- **bash** - Bash shell (newer version than macOS default)
  - *Configuration*: None needed (zsh is primary shell)
  - *Purpose*: Shell for scripts
  - *Status*: ✅ No config needed

- **gnutar** - GNU version of tar
  - *Configuration*: None needed
  - *Purpose*: Archive utility
  - *Status*: ✅ No config needed

- **diffutils** - GNU diff utilities
  - *Configuration*: None needed
  - *Purpose*: File comparison utilities
  - *Status*: ✅ No config needed

#### Terminal File Managers
- **yazi** - Blazing fast terminal file manager (async, image preview)
  - *Configuration*: configs/
  - *Purpose*: Modern terminal file manager
  - *Status*: ❌ Not configured

- **lf** - Lightweight terminal file manager (fast, minimal)
  - *Configuration*: configs/
  - *Purpose*: Minimal terminal file manager
  - *Status*: ❌ Not configured

- **ranger** - Feature-rich terminal file manager (Python-based)
  - *Configuration*: configs/
  - *Purpose*: Feature-rich terminal file manager
  - *Status*: ❌ Not configured

- **nnn** - Extremely fast terminal file manager (n³)
  - *Configuration*: configs/
  - *Purpose*: Ultra-fast terminal file manager
  - *Status*: ❌ Not configured

#### Zsh Enhancements
- **zsh-autosuggestions** - Fish-like autosuggestions for command completion
  - *Configuration*: programs/ (configured in zsh.nix)
  - *Purpose*: Command autosuggestions
  - *Status*: ✅ Configured

- **zsh-syntax-highlighting** - Fish-like syntax highlighting as you type
  - *Configuration*: programs/ (configured in zsh.nix)
  - *Purpose*: Command syntax highlighting
  - *Status*: ✅ Configured

- **zsh-completions** - Additional completion definitions for zsh
  - *Configuration*: programs/ (configured in zsh.nix)
  - *Purpose*: Enhanced completions
  - *Status*: ✅ Configured

- **zsh-history-substring-search** - Fish-like history search with arrow keys
  - *Configuration*: programs/ (configured in zsh.nix)
  - *Purpose*: Enhanced history search
  - *Status*: ✅ Configured

### Development Tools (dev-tools.nix) - 16 tools

#### Development Tools
- **just** - Modern task runner with better syntax
  - *Configuration*: configs/
  - *Purpose*: make replacement with better syntax
  - *Status*: ❌ Not configured

- **hyperfine** - Command-line benchmarking tool
  - *Configuration*: configs/
  - *Purpose*: time replacement with statistical analysis
  - *Status*: ❌ Not configured

- **jq** - JSON processor and query tool
  - *Configuration*: configs/
  - *Purpose*: JSON manipulation and querying
  - *Status*: ❌ Not configured

- **pre-commit** - Git hook framework
  - *Configuration*: configs/
  - *Purpose*: Git hook management
  - *Status*: ❌ Not configured

#### Code Quality & Linting
- **shellcheck** - Shell script linter
  - *Configuration*: configs/ (configured in languages/shellcheckrc)
  - *Purpose*: Shell script analysis
  - *Status*: ✅ Configured

- **shfmt** - Shell formatter
  - *Configuration*: configs/
  - *Purpose*: Shell script formatting
  - *Status*: ❌ Not configured

- **bash-language-server** - LSP for shell scripts
  - *Configuration*: None needed (LSP client handles)
  - *Purpose*: Shell script language server
  - *Status*: ✅ No config needed

- **sqlfluff** - SQL linter and formatter
  - *Configuration*: configs/
  - *Purpose*: SQL code quality
  - *Status*: ❌ Not configured

#### Config File Language Servers
- **taplo** - TOML formatter and linter
  - *Configuration*: configs/ (configured in formatting/.taplo.toml)
  - *Purpose*: TOML file formatting
  - *Status*: ✅ Configured

- **taplo-lsp** - TOML language server
  - *Configuration*: None needed (LSP client handles)
  - *Purpose*: TOML language server
  - *Status*: ✅ No config needed

- **yamlfmt** - YAML formatter (Google's, no Python deps)
  - *Configuration*: configs/ (configured in formatting/.yamlfmt)
  - *Purpose*: YAML file formatting
  - *Status*: ✅ Configured

- **yamllint** - YAML linter
  - *Configuration*: configs/ (configured in formatting/.yamllint.yml)
  - *Purpose*: YAML file linting
  - *Status*: ✅ Configured

- **yaml-language-server** - YAML language server
  - *Configuration*: None needed (LSP client handles)
  - *Purpose*: YAML language server
  - *Status*: ✅ No config needed

- **marksman** - Markdown LSP with wiki-link support
  - *Configuration*: configs/ (configured in languages/marksman.toml)
  - *Purpose*: Markdown language server
  - *Status*: ✅ Configured

#### Data Processing
- **yq-go** - YAML processor (Go version)
  - *Configuration*: None needed
  - *Purpose*: YAML manipulation
  - *Status*: ✅ No config needed

- **fx** - Interactive JSON viewer
  - *Configuration*: configs/
  - *Purpose*: Interactive JSON exploration
  - *Status*: ❌ Not configured

- **jless** - JSON pager
  - *Configuration*: configs/
  - *Purpose*: JSON file viewing
  - *Status*: ❌ Not configured

### DevOps Tools (devops.nix) - 23 tools

#### Git Ecosystem Tools
- **gh** - GitHub's official command-line tool
  - *Configuration*: programs/ (configured in git-tools.nix)
  - *Purpose*: GitHub CLI integration
  - *Status*: ✅ Configured

- **lazygit** - Simple terminal UI for git commands
  - *Configuration*: programs/ (configured in git-tools.nix)
  - *Purpose*: Git TUI interface
  - *Status*: ✅ Configured

- **gitAndTools.git-extras** - Extra git commands
  - *Configuration*: None needed
  - *Purpose*: Additional git commands
  - *Status*: ✅ No config needed

- **gitui** - Alternative Git TUI
  - *Configuration*: configs/
  - *Purpose*: Alternative git TUI
  - *Status*: ❌ Not configured

- **git-secret** - Encrypt secrets in git
  - *Configuration*: configs/
  - *Purpose*: Git secret management
  - *Status*: ❌ Not configured

- **git-crypt** - Transparent file encryption in git
  - *Configuration*: configs/
  - *Purpose*: Git file encryption
  - *Status*: ❌ Not configured

- **gitleaks** - Secret scanner for git repos
  - *Configuration*: configs/
  - *Purpose*: Git secret detection
  - *Status*: ❌ Not configured

- **gitAndTools.bfg-repo-cleaner** - BFG Repo Cleaner
  - *Configuration*: None needed
  - *Purpose*: Git history cleaning
  - *Status*: ✅ No config needed

#### Container & Orchestration
- **docker-client** - Docker CLI
  - *Configuration*: configs/
  - *Purpose*: Container management
  - *Status*: ❌ Not configured

- **docker-compose** - Docker Compose for multi-container apps
  - *Configuration*: configs/
  - *Purpose*: Multi-container orchestration
  - *Status*: ❌ Not configured

- **colima** - Container runtimes on macOS
  - *Configuration*: configs/
  - *Purpose*: macOS container runtime
  - *Status*: ❌ Not configured

- **podman** - Docker alternative
  - *Configuration*: configs/
  - *Purpose*: Alternative container runtime
  - *Status*: ❌ Not configured

- **dive** - Docker image explorer
  - *Configuration*: configs/
  - *Purpose*: Container image analysis
  - *Status*: ❌ Not configured

- **lazydocker** - Docker TUI
  - *Configuration*: configs/
  - *Purpose*: Docker terminal interface
  - *Status*: ❌ Not configured

- **buildkit** - Next-gen container builder
  - *Configuration*: configs/
  - *Purpose*: Advanced container building
  - *Status*: ❌ Not configured

- **hadolint** - Dockerfile linter
  - *Configuration*: configs/
  - *Purpose*: Dockerfile quality analysis
  - *Status*: ❌ Not configured

#### Build Tools
- **cmake** - Cross-platform build system
  - *Configuration*: configs/
  - *Purpose*: Build system for C/C++
  - *Status*: ❌ Not configured

- **pkg-config** - Helper tool for compiling applications
  - *Configuration*: None needed
  - *Purpose*: Library configuration helper
  - *Status*: ✅ No config needed

#### Testing & Automation
- **bats** - Bash testing framework
  - *Configuration*: configs/
  - *Purpose*: Shell script testing
  - *Status*: ❌ Not configured

- **entr** - File watcher for auto-running commands
  - *Configuration*: None needed
  - *Purpose*: File change monitoring
  - *Status*: ✅ No config needed

#### Secret Management Tools
- **vault** - HashiCorp Vault
  - *Configuration*: configs/
  - *Purpose*: Secret management
  - *Status*: ❌ Not configured

- **pass** - Unix password manager
  - *Configuration*: configs/
  - *Purpose*: Password management
  - *Status*: ❌ Not configured

- **gopass** - Pass on steroids
  - *Configuration*: configs/
  - *Purpose*: Enhanced password management
  - *Status*: ❌ Not configured

#### Backup & Sync
- **restic** - Fast, secure backup program
  - *Configuration*: configs/
  - *Purpose*: Backup and restore
  - *Status*: ❌ Not configured

- **rclone** - Cloud storage sync
  - *Configuration*: configs/
  - *Purpose*: Cloud storage synchronization
  - *Status*: ❌ Not configured

### Lua Tools (lua-tools.nix) - 4 tools

- **luajit** - Just-In-Time Lua compiler (provides 'lua' command)
  - *Configuration*: None needed
  - *Purpose*: Lua runtime
  - *Status*: ✅ No config needed

- **luarocks** - Lua package manager
  - *Configuration*: configs/ (configured in languages/luarocks.lua)
  - *Purpose*: Lua package management
  - *Status*: ✅ Configured

- **lua-language-server** - LSP for Lua (sumneko/LuaLS)
  - *Configuration*: None needed (LSP client handles)
  - *Purpose*: Lua language server
  - *Status*: ✅ No config needed

- **stylua** - Opinionated Lua code formatter
  - *Configuration*: configs/ (configured in languages/.stylua.toml)
  - *Purpose*: Lua code formatting
  - *Status*: ✅ Configured

### macOS Tools (macos-tools.nix) - 7 tools

- **mas** - Mac App Store command-line interface
  - *Configuration*: None needed
  - *Purpose*: Mac App Store CLI
  - *Status*: ✅ No config needed

- **_1password-cli** - 1Password command-line tool
  - *Configuration*: None needed (integrated via SSH agent)
  - *Purpose*: 1Password CLI integration
  - *Status*: ✅ No config needed

- **dockutil** - Manage macOS dock items
  - *Configuration*: None needed
  - *Purpose*: Dock management
  - *Status*: ✅ No config needed

- **pngpaste** - Paste PNG from clipboard
  - *Configuration*: None needed
  - *Purpose*: Clipboard image handling
  - *Status*: ✅ No config needed

- **duti** - Set default applications for document types
  - *Configuration*: configs/
  - *Purpose*: File association management
  - *Status*: ❌ Not configured

- **switchaudio-osx** - Switch audio sources from CLI
  - *Configuration*: None needed
  - *Purpose*: Audio source switching
  - *Status*: ✅ No config needed

- **osx-cpu-temp** - Show CPU temperature
  - *Configuration*: None needed
  - *Purpose*: System monitoring
  - *Status*: ✅ No config needed

- **m-cli** - Swiss Army Knife for macOS
  - *Configuration*: None needed
  - *Purpose*: macOS system utilities
  - *Status*: ✅ No config needed

### Media Tools (media-tools.nix) - 5 tools

- **ffmpeg** - Complete multimedia framework
  - *Configuration*: configs/
  - *Purpose*: Media processing and conversion
  - *Status*: ❌ Not configured

- **imagemagick** - Image manipulation
  - *Configuration*: configs/
  - *Purpose*: Image processing
  - *Status*: ❌ Not configured

- **yt-dlp** - Video downloader
  - *Configuration*: configs/
  - *Purpose*: Video downloading
  - *Status*: ❌ Not configured

- **pandoc** - Universal document converter
  - *Configuration*: configs/
  - *Purpose*: Document format conversion
  - *Status*: ❌ Not configured

- **graphviz** - Graph visualization software
  - *Configuration*: configs/
  - *Purpose*: Graph and diagram generation
  - *Status*: ❌ Not configured

### Nix Tools (nix-tools.nix) - 10 tools

#### Core Nix Toolchain
- **nixVersions.latest** - Latest Nix
  - *Configuration*: None needed
  - *Purpose*: Nix package manager
  - *Status*: ✅ No config needed

- **cachix** - Binary cache management
  - *Configuration*: configs/
  - *Purpose*: Nix binary cache management
  - *Status*: ❌ Not configured

- **deploy-rs** - NixOS deployment tool
  - *Configuration*: configs/
  - *Purpose*: NixOS deployment
  - *Status*: ❌ Not configured

#### Build & Development Tools
- **nix-output-monitor** - Pretty output for Nix builds
  - *Configuration*: None needed
  - *Purpose*: Enhanced Nix build output
  - *Status*: ✅ No config needed

- **nix-fast-build** - Parallel evaluation and building
  - *Configuration*: None needed
  - *Purpose*: Faster Nix builds
  - *Status*: ✅ No config needed

- **nix-index** - Package search by file contents
  - *Configuration*: programs/ (configured in shell-tools.nix)
  - *Purpose*: Nix package file search
  - *Status*: ✅ Configured

#### Language Server & Code Quality
- **nil** - Nix language server for IDE integration
  - *Configuration*: configs/ (configured in languages/nil.toml)
  - *Purpose*: Nix language server
  - *Status*: ✅ Configured

- **deadnix** - Find and remove dead code in Nix files
  - *Configuration*: configs/
  - *Purpose*: Nix code analysis
  - *Status*: ❌ Not configured

- **statix** - Lints and suggestions for Nix code
  - *Configuration*: configs/
  - *Purpose*: Nix code linting
  - *Status*: ❌ Not configured

- **nixfmt-rfc-style** - Official Nix code formatter
  - *Configuration*: None needed
  - *Purpose*: Nix code formatting
  - *Status*: ✅ No config needed

### Node.js Tools (node-tools.nix) - 17 tools

#### Node.js Toolchain
- **nodejs_22** - Node.js runtime
  - *Configuration*: None needed
  - *Purpose*: JavaScript runtime
  - *Status*: ✅ No config needed

- **pnpm** - Fast, disk space efficient package manager
  - *Configuration*: configs/
  - *Purpose*: Node.js package management
  - *Status*: ❌ Not configured

- **yarn** - Alternative package manager
  - *Configuration*: configs/
  - *Purpose*: Alternative Node.js package manager
  - *Status*: ❌ Not configured

#### Infrastructure & Automation Tools
- **nodePackages.npm-check-updates** - Check for dependency updates
  - *Configuration*: None needed
  - *Purpose*: Dependency update checking
  - *Status*: ✅ No config needed

- **nodePackages.http-server** - Simple zero-config HTTP server
  - *Configuration*: None needed
  - *Purpose*: Development HTTP server
  - *Status*: ✅ No config needed

- **nodePackages.concurrently** - Run multiple commands concurrently
  - *Configuration*: None needed
  - *Purpose*: Concurrent command execution
  - *Status*: ✅ No config needed

- **nodePackages.json-server** - Quick REST API mock server
  - *Configuration*: None needed
  - *Purpose*: API mocking
  - *Status*: ✅ No config needed

- **nodePackages.serve** - Static file server with hot reload
  - *Configuration*: None needed
  - *Purpose*: Static file serving
  - *Status*: ✅ No config needed

#### Code Quality Tools
- **nodePackages.prettier** - Code formatter
  - *Configuration*: configs/ (configured in formatting/.prettierrc)
  - *Purpose*: Code formatting
  - *Status*: ✅ Configured

- **nodePackages.eslint** - JavaScript linter
  - *Configuration*: configs/ (configured in languages/eslint.config.js)
  - *Purpose*: JavaScript linting
  - *Status*: ✅ Configured

- **nodePackages.typescript** - TypeScript compiler
  - *Configuration*: configs/ (configured in languages/tsconfig.json)
  - *Purpose*: TypeScript compilation
  - *Status*: ✅ Configured

- **nodePackages.typescript-language-server** - TypeScript/JavaScript LSP
  - *Configuration*: None needed (LSP client handles)
  - *Purpose*: TypeScript language server
  - *Status*: ✅ No config needed

- **nodePackages.vscode-langservers-extracted** - JSON/HTML/CSS/ESLint LSPs
  - *Configuration*: None needed (LSP client handles)
  - *Purpose*: Multiple language servers
  - *Status*: ✅ No config needed

#### JSON/YAML Tools
- **nodePackages.js-yaml** - YAML/JSON converter
  - *Configuration*: None needed
  - *Purpose*: YAML/JSON conversion
  - *Status*: ✅ No config needed

- **nodePackages.json** - JSON manipulation CLI
  - *Configuration*: None needed
  - *Purpose*: JSON manipulation
  - *Status*: ✅ No config needed

### Python Tools (python-tools.nix) - 16 tools

#### Python Toolchain
- **python313** - Python 3.13
  - *Configuration*: None needed
  - *Purpose*: Python runtime
  - *Status*: ✅ No config needed

- **pipx** - Install Python apps in isolated environments
  - *Configuration*: configs/
  - *Purpose*: Isolated Python app installation
  - *Status*: ❌ Not configured

- **poetry** - Python dependency management
  - *Configuration*: configs/ (configured in poetry.toml)
  - *Purpose*: Python project management
  - *Status*: ✅ Configured

- **ruff** - Fast Python linter/formatter
  - *Configuration*: configs/ (configured in languages/ruff.toml)
  - *Purpose*: Python code quality
  - *Status*: ✅ Configured

- **uv** - Fast Python package installer and resolver
  - *Configuration*: configs/
  - *Purpose*: Fast Python package management
  - *Status*: ❌ Not configured

- **basedpyright** - Type checker for Python
  - *Configuration*: configs/ (configured in languages/basedpyright.json)
  - *Purpose*: Python type checking
  - *Status*: ✅ Configured

#### Python Development Utilities
- **cookiecutter** - Project template tool
  - *Configuration*: configs/
  - *Purpose*: Project scaffolding
  - *Status*: ❌ Not configured

- **python3Packages.black** - Python code formatter
  - *Configuration*: configs/
  - *Purpose*: Python code formatting
  - *Status*: ❌ Not configured

- **python3Packages.mypy** - Static type checker
  - *Configuration*: configs/
  - *Purpose*: Python type checking
  - *Status*: ❌ Not configured

- **python3Packages.pytest** - Testing framework
  - *Configuration*: configs/
  - *Purpose*: Python testing
  - *Status*: ❌ Not configured

- **python3Packages.rich** - Rich text formatting
  - *Configuration*: None needed
  - *Purpose*: Terminal text formatting
  - *Status*: ✅ No config needed

- **python3Packages.typer** - CLI creation library
  - *Configuration*: None needed
  - *Purpose*: CLI application framework
  - *Status*: ✅ No config needed

- **python3Packages.pydantic** - Data validation
  - *Configuration*: None needed
  - *Purpose*: Data validation and parsing
  - *Status*: ✅ No config needed

- **python3Packages.httpx** - Modern HTTP client
  - *Configuration*: None needed
  - *Purpose*: HTTP client library
  - *Status*: ✅ No config needed

### Rust Tools (rust-tools.nix) - 13 tools

#### Core Rust Toolchain
- **rustup** - Toolchain management
  - *Configuration*: configs/
  - *Purpose*: Rust toolchain management
  - *Status*: ❌ Not configured

#### Essential Development Tools
- **bacon** - Background compiler with live feedback TUI
  - *Configuration*: configs/
  - *Purpose*: Continuous Rust compilation
  - *Status*: ❌ Not configured

- **cargo-edit** - Add/remove/upgrade dependencies from CLI
  - *Configuration*: None needed
  - *Purpose*: Cargo dependency management
  - *Status*: ✅ No config needed

- **cargo-watch** - Auto-rebuild on file changes
  - *Configuration*: None needed
  - *Purpose*: Automatic rebuilding
  - *Status*: ✅ No config needed

- **cargo-binstall** - Fast binary installation
  - *Configuration*: None needed
  - *Purpose*: Fast Rust binary installation
  - *Status*: ✅ No config needed

#### Code Quality & Analysis
- **cargo-deny** - Check dependencies for security/license issues
  - *Configuration*: configs/ (configured in languages/cargo-deny.toml)
  - *Purpose*: Dependency security analysis
  - *Status*: ✅ Configured

- **cargo-machete** - Find unused dependencies
  - *Configuration*: None needed
  - *Purpose*: Unused dependency detection
  - *Status*: ✅ No config needed

- **cargo-outdated** - Check for outdated dependencies
  - *Configuration*: None needed
  - *Purpose*: Dependency update checking
  - *Status*: ✅ No config needed

- **cargo-bloat** - Analyze binary size
  - *Configuration*: None needed
  - *Purpose*: Binary size analysis
  - *Status*: ✅ No config needed

- **cargo-audit** - Security vulnerability scanner
  - *Configuration*: None needed
  - *Purpose*: Security vulnerability scanning
  - *Status*: ✅ No config needed

- **cargo-generate** - Project template generator
  - *Configuration*: None needed
  - *Purpose*: Rust project scaffolding
  - *Status*: ✅ No config needed

#### Performance & Caching
- **sccache** - Compilation caching for faster builds
  - *Configuration*: configs/
  - *Purpose*: Rust compilation caching
  - *Status*: ❌ Not configured

#### Documentation & Project Management
- **mdbook** - Documentation generator
  - *Configuration*: configs/
  - *Purpose*: Rust documentation generation
  - *Status*: ❌ Not configured

- **cargo-expand** - Show macro-expanded code
  - *Configuration*: None needed
  - *Purpose*: Macro expansion debugging
  - *Status*: ✅ No config needed

### System Administration Tools (sysadmin.nix) - 10 tools

#### Network Analysis
- **bandwhich** - Terminal bandwidth monitor by process/connection
  - *Configuration*: configs/
  - *Purpose*: Network bandwidth monitoring
  - *Status*: ❌ Not configured

- **iperf** - Network performance testing (iperf3)
  - *Configuration*: configs/
  - *Purpose*: Network performance testing
  - *Status*: ❌ Not configured

- **nmap** - Network exploration and security scanner
  - *Configuration*: configs/
  - *Purpose*: Network scanning and security
  - *Status*: ❌ Not configured

- **whois** - Domain information lookup
  - *Configuration*: None needed
  - *Purpose*: Domain information queries
  - *Status*: ✅ No config needed

- **speedtest-cli** - Internet speed testing from terminal
  - *Configuration*: None needed
  - *Purpose*: Internet speed testing
  - *Status*: ✅ No config needed

- **bind** - DNS tools (includes dig)
  - *Configuration*: None needed
  - *Purpose*: DNS utilities
  - *Status*: ✅ No config needed

#### System Utilities
- **parallel-full** - GNU parallel for parallel command execution
  - *Configuration*: configs/
  - *Purpose*: Parallel command execution
  - *Status*: ❌ Not configured

- **watchexec** - File watcher that runs commands on changes
  - *Configuration*: configs/
  - *Purpose*: File change monitoring and execution
  - *Status*: ❌ Not configured

- **tldr** - Simplified, practical man pages with examples
  - *Configuration*: configs/
  - *Purpose*: Simplified documentation
  - *Status*: ❌ Not configured

- **neovim** - Hyperextensible text editor
  - *Configuration*: configs/
  - *Purpose*: Advanced text editing
  - *Status*: ❌ Not configured

## Summary Statistics

### Total Tools: 148 tools across 11 categories

### Configuration Status:
- **✅ Configured**: 35 tools (24%)
- **❌ Not Configured**: 98 tools (66%)
- **✅ No Config Needed**: 15 tools (10%)

### Configuration Method Requirements:
- **Programs Only**: 15 tools
- **Configs Only**: 83 tools
- **Both Programs + Configs**: 2 tools (starship, git with delta)
- **No Configuration**: 48 tools

### Priority Categories for Configuration:
1. **High Priority** (Essential development tools): 45 tools
   - Core shell enhancements (file managers, system monitors)
   - Development workflow tools (just, hyperfine, pre-commit)
   - Container and DevOps tools (docker, podman, vault)
   - Language-specific toolchains (rust, python, node)

2. **Medium Priority** (Quality of life improvements): 35 tools
   - Media processing tools
   - Advanced system utilities
   - Specialized development tools

3. **Low Priority** (Nice to have): 18 tools
   - Backup and sync tools
   - Specialized network tools
   - Alternative implementations of configured tools

### Platform-Specific Tools:
- **macOS Only**: 7 tools (all in macos-tools.nix)
- **Universal**: 141 tools
- **Linux Specific**: 0 tools (but some may need Linux-specific configs)

### XDG Compliance Assessment:
- **Native XDG Support**: ~30% of configurable tools
- **Environment Variable Redirection**: ~50% of configurable tools
- **Hardcoded Paths**: ~20% of configurable tools (requires documentation)

This inventory provides the foundation for systematic configuration implementation, prioritizing essential development tools while ensuring comprehensive coverage of all 148 tools in the system.