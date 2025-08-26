# Title         : 01.home/environment.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/environment.nix
# ----------------------------------------------------------------------------
# Defines user-specific environment variables and session PATH.

{
  config,
  context ? null,
  ...
}:

{
  # --- User Session Variables -----------------------------------------------
  home.sessionVariables = {
    # --- Locale and Internationalization ------------------------------------
    LANG = "en_US.UTF-8"; # System locale
    LC_ALL = ""; # Don't override individual locale categories
    TZ = "America/Chicago"; # Central Time (Houston)

    # --- XDG Base Directory Specification -----------------------------------
    # Explicitly set XDG variables for tools that don't use home-manager's values
    XDG_CONFIG_HOME = "${config.xdg.configHome}";
    XDG_DATA_HOME = "${config.xdg.dataHome}";
    XDG_CACHE_HOME = "${config.xdg.cacheHome}";
    XDG_STATE_HOME = "${config.xdg.stateHome}";
    # XDG_RUNTIME_DIR is set by system (macOS: ~/Library/Caches/TemporaryItems, Linux: /run/user/$UID)

    # --- Shell Security & Performance ---------------------------------------
    TMPDIR =
      if (context != null && context.isDarwin) then "${config.home.homeDirectory}/Library/Caches/TemporaryItems" else "/tmp"; # Secure temporary directory
    KEYTIMEOUT = "1"; # Faster vi mode switching (10ms)

    # --- Core Utilities -----------------------------------------------------
    EDITOR = "nvim";
    VISUAL = "code --wait";
    PAGER = "less -FRX";
    LESS = "-FRX";
    GIT_PAGER = "delta";

    # --- System Integration -------------------------------------------------
    # Platform-aware browser command
    BROWSER = if (context != null && context.isDarwin) then "open" else "xdg-open";
    COLORTERM = "truecolor";
    # Better man pages with bat if available
    MANPAGER = "sh -c 'col -bx | bat -l man -p'";

    # --- XDG-Compliant Development Paths ------------------------------------
    # Rust
    CARGO_HOME = "${config.xdg.dataHome}/cargo";
    RUSTUP_HOME = "${config.xdg.dataHome}/rustup";
    RUSTC_WRAPPER = "sccache";
    SCCACHE_DIR = "${config.xdg.cacheHome}/sccache";
    SCCACHE_CACHE_SIZE = "10G";
    CARGO_NET_GIT_FETCH_WITH_CLI = "true";
    CARGO_TERM_COLOR = "always";
    BINSTALL_DISABLE_TELEMETRY = "1";
    # Go
    GOPATH = "${config.xdg.dataHome}/go";
    # Node/npm (npm doesn't support XDG - uses these env vars for custom paths)
    NPM_CONFIG_USERCONFIG = "${config.xdg.configHome}/npm/npmrc";
    NPM_CONFIG_PREFIX = "${config.xdg.dataHome}/npm";
    NODE_REPL_HISTORY = "${config.xdg.dataHome}/node_repl_history";
    # pnpm (fully XDG-compliant - respects XDG_* vars directly)
    PNPM_HOME = "${config.xdg.dataHome}/pnpm"; # Base directory for pnpm installations
    # Python
    PYTHONHISTORY = "${config.xdg.stateHome}/python/history";
    PYTHONDONTWRITEBYTECODE = "1";
    PIPX_HOME = "${config.xdg.dataHome}/pipx";
    PIPX_BIN_DIR = "${config.xdg.dataHome}/pipx/bin";
    PYLINTHOME = "${config.xdg.cacheHome}/pylint";
    POETRY_VIRTUALENVS_IN_PROJECT = "true";
    POETRY_CACHE_DIR = "${config.xdg.cacheHome}/pypoetry";
    RUFF_CACHE_DIR = "${config.xdg.cacheHome}/ruff";
    MYPY_CACHE_DIR = "${config.xdg.cacheHome}/mypy";
    MYPY_CONFIG_FILE = "${config.xdg.configHome}/mypy/mypy.ini";
    UV_CACHE_DIR = "${config.xdg.cacheHome}/uv";
    PYTEST_CACHE_DIR = "${config.xdg.cacheHome}/pytest";
    PIPX_DEFAULT_PYTHON = "${config.home.homeDirectory}/.nix-profile/bin/python3";

    # --- XDG-Compliant Shell History ----------------------------------------
    HISTFILE = "${config.xdg.stateHome}/bash/history";
    LESSHISTFILE = "${config.xdg.stateHome}/less/history";
    SQLITE_HISTORY = "${config.xdg.stateHome}/sqlite/history";

    # --- XDG-Compliant Application Config -----------------------------------
    # Docker & Container Runtimes
    DOCKER_CONFIG = "${config.xdg.configHome}/docker";
    DOCKER_HOST = "unix://${config.home.homeDirectory}/.colima/default/docker.sock"; # Colima socket
    DOCKER_CERT_PATH = "${config.xdg.dataHome}/docker/certs";
    MACHINE_STORAGE_PATH = "${config.xdg.dataHome}/docker-machine";
    # Colima
    COLIMA_HOME = "${config.xdg.dataHome}/colima";
    # Podman
    CONTAINERS_CONF = "${config.xdg.configHome}/containers/containers.conf";
    CONTAINERS_REGISTRIES_CONF = "${config.xdg.configHome}/containers/registries.conf";
    CONTAINERS_STORAGE_CONF = "${config.xdg.configHome}/containers/storage.conf";
    PODMAN_USERNS = "keep-id"; # Better rootless experience
    # Container tool configs
    LAZYDOCKER_CONFIG_DIR = "${config.xdg.configHome}/lazydocker";
    DIVE_CONFIG = "${config.xdg.configHome}/dive/config.yaml";
    HADOLINT_CONFIG = "${config.xdg.configHome}/hadolint.yaml";
    # GitHub CLI
    GH_CONFIG_DIR = "${config.xdg.configHome}/gh";
    GH_PAGER = "delta"; # Use delta for rich diffs in gh commands

    # --- Formatter Configs --------------------------------------------------
    YAMLLINT_CONFIG_FILE = "${config.xdg.configHome}/yamllint/config"; # Supported by yamllint

    # --- Language Server Configuration --------------------------------------
    # Bash Language Server
    BASH_IDE_LOG_LEVEL = "info"; # Logging level for bash-language-server
    SHELLCHECK_PATH = "shellcheck"; # Path to ShellCheck (available in PATH)
    SHFMT_PATH = "shfmt"; # Path to shfmt (available in PATH)
    LUAROCKS_TREE = "${config.xdg.dataHome}/luarocks"; # Lua package manager
    LUAROCKS_CONFIG = "${config.xdg.configHome}/luarocks/config.lua";

    # --- Font Configuration -------------------------------------------------
    FONTCONFIG_PATH = "${config.xdg.configHome}/fontconfig";
    FONTCONFIG_FILE = "${config.xdg.configHome}/fontconfig/fonts.conf";
    FONTCONFIG_CACHE = "${config.xdg.cacheHome}/fontconfig";

    # --- Performance & Build Settings ---------------------------------------
    DOCKER_BUILDKIT = "1";
    COMPOSE_DOCKER_CLI_BUILD = "1";
    BUILDKIT_PROGRESS = "plain"; # Options: auto, plain, tty
    TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE = "/var/run/docker.sock";
    MAKEFLAGS = "-j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)";
    CMAKE_BUILD_PARALLEL_LEVEL = "$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)";

    # --- HTTP Client Configuration -------------------------------------------
    XH_CONFIG_DIR = "${config.xdg.configHome}/xh"; # HTTPie-like client config

    # --- Privacy & Telemetry Opt-Outs ---------------------------------------
    DOTNET_CLI_TELEMETRY_OPTOUT = "1";
    GATSBY_TELEMETRY_DISABLED = "1";
    NEXT_TELEMETRY_DISABLED = "1";
    AZURE_CORE_COLLECT_TELEMETRY = "0";
    SAM_CLI_TELEMETRY = "0";
    POWERSHELL_TELEMETRY_OPTOUT = "1";
    DO_NOT_TRACK = "1";

    # --- Tool Configurations ------------------------------------------------
    # Bat (enhanced cat)
    BAT_THEME = "Dracula"; # Consistent with Nix module setting
    BAT_STYLE = "numbers,changes,header"; # Add header for better file context
    BAT_PAGER = "less -FRX"; # Same as PAGER for consistency
    BAT_CONFIG_PATH = "${config.xdg.configHome}/bat/config"; # Config file location
    BAT_CACHE_PATH = "${config.xdg.cacheHome}/bat"; # Cache directory for themes/syntaxes
    
    # Ripgrep (ultra-fast text search)
    RIPGREP_CONFIG_PATH = "${config.xdg.configHome}/ripgrep/config"; # Config file location
    
    # Delta (syntax-highlighting diff viewer)
    DELTA_PAGER = "less -FRX"; # Override default pager for delta
    # DELTA_FEATURES = "+side-by-side"; # Uncomment to temporarily enable features
    
    # Hexyl (hex viewer) - Dracula-themed colors for different byte types
    HEXYL_COLOR_ASCII_PRINTABLE = "#50fa7b"; # Green for printable ASCII
    HEXYL_COLOR_ASCII_WHITESPACE = "#8be9fd"; # Cyan for whitespace
    HEXYL_COLOR_ASCII_OTHER = "#f1fa8c"; # Yellow for other ASCII
    HEXYL_COLOR_NULL = "#ff5555"; # Red for null bytes
    HEXYL_COLOR_NONASCII = "#bd93f9"; # Purple for non-ASCII
    HEXYL_COLOR_OFFSET = "#6272a4"; # Comment color for offsets
    
    # Tokei (code statistics) - Terminal color control
    # NO_COLOR = "1"; # Uncomment to disable colored output globally
    # CLICOLOR_FORCE = "1"; # Uncomment to force color output when not in terminal
    
    # File command (file type detection)
    MAGIC = "${config.xdg.configHome}/file/magic:${config.xdg.dataHome}/file/magic"; # Custom magic file paths
    # Zsh plugin configurations
    ZSH_AUTOSUGGEST_STRATEGY = "(history completion)"; # Try history first, then completion
    ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE = "20"; # Don't suggest for long commands (20 chars)
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE = "fg=#6272a4"; # Dracula comment color for suggestions
    ZSH_COMPDUMP = "${config.xdg.cacheHome}/zsh/zcompdump-$ZSH_VERSION"; # Completion cache location (XDG-compliant)
    DFT_BACKGROUND = "dark";
    DFT_DISPLAY = "inline";
    NIX_INDEX_DATABASE = "${config.xdg.cacheHome}/nix-index";
    MCFLY_RESULTS = "50"; # Number of results to display
    MCFLY_INTERFACE_VIEW = "BOTTOM"; # Where to display results
    # Enhanced directory colors (Dracula-inspired)
    LS_COLORS = "fi=00:mi=00:mh=00:ln=01;36:or=01;31:di=01;34:ow=04;01;34:st=34:tw=04;34:pi=01;33:so=01;33:bd=33:cd=33:su=01;35:sg=01;35:ca=01;33:ex=01;32";

    # --- Java/JVM Configuration (XDG-compliant) -----------------------------
    JAVA_OPTIONS = "-Djava.util.prefs.userRoot=${config.xdg.configHome}/java";
    _JAVA_OPTIONS = "-Djava.util.prefs.userRoot=${config.xdg.configHome}/java";

    # --- Build & Task Automation --------------------------------------------
    PRE_COMMIT_HOME = "${config.xdg.dataHome}/pre-commit"; # Pre-commit hooks cache

    # --- Backup & Sync Tools ------------------------------------------------
    RCLONE_CONFIG = "${config.xdg.configHome}/rclone/rclone.conf"; # Rclone configuration
    RESTIC_CACHE_DIR = "${config.xdg.cacheHome}/restic"; # Restic cache

    # --- Development Utilities ----------------------------------------------
    TLDR_CACHE_DIR = "${config.xdg.cacheHome}/tldr"; # TLDR pages cache
    PARALLEL = "-j+0 --bar --eta"; # GNU parallel defaults: use all cores, show progress
    # WATCHEXEC_LOG = "debug"; # Optional: Watchexec debug logging level

    # --- WezTerm Integration ------------------------------------------------
    # WezTerm daemon paths (XDG-compliant)
    WEZTERM_CONFIG_DIR = "${config.xdg.configHome}/wezterm";
    WEZTERM_RUNTIME_DIR = "${config.xdg.stateHome}/wezterm"; # Using state instead of runtime for macOS
    WEZTERM_LOG_DIR = "${config.xdg.stateHome}/wezterm";

    # --- 1Password Integration ----------------------------------------------
    # Secrets are available through:
    # 1. op-run command: op-run npm publish
    # 2. Cache loading: source ~/.cache/op/env.cache (if fresh)
    # 3. Direct template: op run --env-file=$OP_ENV_TEMPLATE -- <cmd>
    # Template and cache locations:
    OP_ENV_TEMPLATE = config.secrets.paths.template;
    OP_ENV_CACHE = config.secrets.paths.cache;
    OP_BIOMETRIC_UNLOCK_ENABLED = "true";
    # Note: SSH_AUTH_SOCK is dynamically set in zsh.nix based on socket availability

    # --- Claude Code Configuration -------------------------------------------

    # --- Network Performance Testing ----------------------------------------
    # IPERF3_PASSWORD = "your-password-here"; # Optional: Set password for iperf3 auth

    CLAUDE_CONFIG_DIR = "${config.home.homeDirectory}/.claude";
    CLAUDE_CACHE_DIR = "${config.xdg.cacheHome}/claude";

    # --- Network Tools ------------------------------------------------------
    # WHOIS_SERVER = "whois.iana.org"; # Optional: Default WHOIS server
    # IDN_DISABLE = "1"; # Optional: Disable IDN processing for dig

    # --- Media Processing Configuration ---------------------------------------
    # FFmpeg
    # Note: FFMPEG_DATADIR is deprecated and only used for preset file discovery
    # FFmpeg doesn't support XDG - uses ~/.ffmpeg/ for user configs
    FFREPORT = "file=${config.xdg.stateHome}/ffmpeg/ffreport.log:level=32"; # Controls automatic logging output and verbosity

    # ImageMagick
    MAGICK_CONFIGURE_PATH = "${config.xdg.configHome}/ImageMagick"; # Configuration files search path
    MAGICK_FONT_PATH = if (context != null && context.isDarwin)
      then "/System/Library/Fonts:/Library/Fonts:${config.home.homeDirectory}/Library/Fonts"
      else "${config.home.homeDirectory}/.local/share/fonts:/usr/share/fonts"; # Font files search path
    MAGICK_TEMPORARY_PATH = "${config.xdg.cacheHome}/ImageMagick"; # Temporary files path
    MAGICK_MEMORY_LIMIT = "1GB"; # Heap memory limit
    MAGICK_DISK_LIMIT = "2GB"; # Disk space limit
    MAGICK_THREAD_LIMIT = "4"; # Parallel threads limit

    # --- Document Processing ------------------------------------------------
    # Pandoc supports partial XDG compliance - uses XDG dirs but falls back to ~/.pandoc
    PANDOC_DATA_DIR = "${config.xdg.dataHome}/pandoc"; # Override default data directory for templates, filters, CSL files

    # --- Graph Visualization ------------------------------------------------
    # Graphviz - uses same font paths as ImageMagick
    # DOTFONTPATH = MAGICK_FONT_PATH; # Uncomment if Graphviz can't find fonts

    # --- File & Directory Operations Tools ----------------------------------
    # Eza (modern ls replacement)
    EZA_CONFIG_DIR = "${config.xdg.configHome}/eza"; # Directory for theme.yml
    EZA_ICON_SPACING = "2"; # Spaces between icon and filename
    EZA_ICONS_AUTO = "1"; # Enable automatic icon display
    # Note: EZA_COLORS removed - using theme.yml instead for color configuration

    # Rsync (file synchronization)
    RSYNC_RSH = "ssh"; # Use SSH for remote transfers (default)
    # RSYNC_PASSWORD = ""; # Only set if using rsync daemon auth
    # RSYNC_PROXY = ""; # Only set if behind proxy for rsync daemon
  };

  # --- User Session Path ----------------------------------------------------
  # Prepends XDG-compliant binary paths to the user's PATH
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/bin"
    "${config.xdg.dataHome}/cargo/bin"
    "${config.xdg.dataHome}/go/bin"
    "${config.xdg.dataHome}/pipx/bin"
    "${config.xdg.dataHome}/npm/bin"
    "${config.xdg.dataHome}/pnpm"
  ];
}
