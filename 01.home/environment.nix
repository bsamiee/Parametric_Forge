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
  lib,
  pkgs,
  ...
}:

{
  # --- User Session Variables -----------------------------------------------
  home.sessionVariables = {
    # --- Locale and Internationalization ------------------------------------
    LANG = "en_US.UTF-8";
    LC_ALL = "";
    TZ = "America/Chicago";

    # --- XDG Base Directory Specification -----------------------------------
    XDG_CONFIG_HOME = "${config.xdg.configHome}";
    XDG_DATA_HOME = "${config.xdg.dataHome}";
    XDG_CACHE_HOME = "${config.xdg.cacheHome}";
    XDG_STATE_HOME = "${config.xdg.stateHome}";

    # --- Shell Security & Performance ---------------------------------------
    KEYTIMEOUT = "1";

    # --- Core Utilities -----------------------------------------------------
    EDITOR = "nvim";
    VISUAL = "code --wait";
    PAGER = "less -FRX";
    LESS = "-FRX";
    GIT_PAGER = "delta";

    # --- System Integration -------------------------------------------------
    # Note: Browser defaults handled by system LSHandlers in 00.system/darwin/settings/system.nix
    # BROWSER env var removed to prevent conflicts with system-level browser configuration

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
    CARGO_PROFILE_RELEASE_DEBUG = "true"; # Enable debug symbols in release for profiling
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
    # UV_PROJECT_ENVIRONMENT, UV_COMPILE_BYTECODE, UV_LINK_MODE → Not documented/supported
    PYTEST_CACHE_DIR = "${config.xdg.cacheHome}/pytest";
    PIPX_DEFAULT_PYTHON = "${config.home.homeDirectory}/.nix-profile/bin/python3";
    NOX_CACHE_DIR = "${config.xdg.cacheHome}/nox";

    # --- XDG-Compliant Shell History ----------------------------------------
    HISTFILE = "${config.xdg.stateHome}/zsh/history";
    LESSHISTFILE = "${config.xdg.stateHome}/less/history";
    SQLITE_HISTORY = "${config.xdg.stateHome}/sqlite/history";

    # --- XDG-Compliant Application Config -----------------------------------
    DOCKER_CONFIG = "${config.xdg.configHome}/docker";
    # DOCKER_HOST → Dynamically set in zsh.nix:200-213 to support multiple runtimes
    DOCKER_CERT_PATH = "${config.xdg.dataHome}/docker/certs";
    MACHINE_STORAGE_PATH = "${config.xdg.dataHome}/docker-machine";
    COLIMA_HOME = "${config.xdg.dataHome}/colima";
    CONTAINERS_CONF = "${config.xdg.configHome}/containers/containers.conf";
    CONTAINERS_REGISTRIES_CONF = "${config.xdg.configHome}/containers/registries.conf";
    CONTAINERS_STORAGE_CONF = "${config.xdg.configHome}/containers/storage.conf";
    PODMAN_USERNS = "keep-id";
    LAZYDOCKER_CONFIG_DIR = "${config.xdg.configHome}/lazydocker";
    DIVE_CONFIG = "${config.xdg.configHome}/dive/config.yaml";
    HADOLINT_CONFIG = "${config.xdg.configHome}/hadolint.yaml";
    GH_CONFIG_DIR = "${config.xdg.configHome}/gh";
    GH_PAGER = "delta";

    # --- Formatter Configs --------------------------------------------------
    YAMLLINT_CONFIG_FILE = "${config.xdg.configHome}/yamllint/config";

    # --- Language Server Configuration --------------------------------------
    BASH_IDE_LOG_LEVEL = "info";
    SHELLCHECK_PATH = "shellcheck";
    SHFMT_PATH = "shfmt";
    LUAROCKS_TREE = "${config.xdg.dataHome}/luarocks";
    LUAROCKS_CONFIG = "${config.xdg.configHome}/luarocks/config.lua";

    # --- Font Configuration -------------------------------------------------
    FONTCONFIG_PATH = "${config.xdg.configHome}/fontconfig";
    FONTCONFIG_FILE = "${config.xdg.configHome}/fontconfig/fonts.conf";
    FONTCONFIG_CACHE = "${config.xdg.cacheHome}/fontconfig";

    # --- Performance & Build Settings ---------------------------------------
    DOCKER_BUILDKIT = "1";
    COMPOSE_DOCKER_CLI_BUILD = "1";
    BUILDKIT_PROGRESS = "plain";
    BUILDKIT_TTY_LOG_LINES = "20";
    BUILDKIT_COLORS = "1";
    TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE = "/var/run/docker.sock";
    MAKEFLAGS = "-j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)";
    CMAKE_BUILD_PARALLEL_LEVEL = "$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)";

    # --- HTTP Client Configuration -------------------------------------------
    XH_CONFIG_DIR = "${config.xdg.configHome}/xh";

    # --- Privacy & Telemetry Opt-Outs ---------------------------------------
    DOTNET_CLI_TELEMETRY_OPTOUT = "1";
    GATSBY_TELEMETRY_DISABLED = "1";
    NEXT_TELEMETRY_DISABLED = "1";
    AZURE_CORE_COLLECT_TELEMETRY = "0";
    SAM_CLI_TELEMETRY = "0";
    POWERSHELL_TELEMETRY_OPTOUT = "1";
    DO_NOT_TRACK = "1";
    CARGO_BINSTALL_DISABLE_TELEMETRY = "1";

    # --- Security & Secret Detection ----------------------------------------
    GITLEAKS_CONFIG = "${config.xdg.configHome}/gitleaks/gitleaks.toml";
    GITLEAKS_NO_UPDATE_CHECK = "true";
    SECRETS_GPG_COMMAND = "gpg";

    # --- Tool Configurations ------------------------------------------------
    BAT_CONFIG_PATH = "${config.xdg.configHome}/bat/config";
    BAT_CACHE_PATH = "${config.xdg.cacheHome}/bat";
    RIPGREP_CONFIG_PATH = "${config.xdg.configHome}/ripgrep/config";
    # STARSHIP_CONFIG removed - using programs.starship.settings instead (shell-tools.nix:29)
    STARSHIP_CACHE = "${config.xdg.cacheHome}/starship";

    # Delta (syntax-highlighting diff viewer)
    DELTA_PAGER = "less -FRX"; # Override default pager for delta
    # DELTA_FEATURES = "+side-by-side"; # Uncomment to temporarily enable features

    # File command (file type detection) - Point to Nix store magic database
    MAGIC = "${pkgs.file}/share/misc/magic.mgc";

    # JQ (JSON processor) - Use default colors (removed mkForce override that was causing corruption)
    # Zsh plugin configurations
    ZSH_AUTOSUGGEST_STRATEGY = "(history completion)"; # Try history first, then completion
    ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE = "20"; # Don't suggest for long commands (20 chars)
    ZSH_COMPDUMP = "${config.xdg.cacheHome}/zsh/zcompdump-$ZSH_VERSION"; # Completion cache location (XDG-compliant)
    NIX_INDEX_DATABASE = "${config.xdg.cacheHome}/nix-index";
    MCFLY_RESULTS = "50"; # Number of results to display
    MCFLY_INTERFACE_VIEW = "BOTTOM"; # Where to display results

    # --- Java/JVM Configuration (XDG-compliant) -----------------------------
    JAVA_OPTIONS = "-Djava.util.prefs.userRoot=${config.xdg.configHome}/java";
    _JAVA_OPTIONS = "-Djava.util.prefs.userRoot=${config.xdg.configHome}/java";

    # --- Build & Task Automation --------------------------------------------
    PRE_COMMIT_HOME = "${config.xdg.dataHome}/pre-commit"; # Pre-commit hooks cache
    JUST_CHOOSER = "fzf"; # Binary chooser for just --choose
    JUST_TIMESTAMP = "1"; # Enable timestamps in just output
    JUST_TIMESTAMP_FORMAT = "%Y-%m-%d %H:%M:%S"; # Format for just timestamps
    JUST_UNSTABLE = "1"; # Enable experimental features

    # Hyperfine (benchmarking) - Uses CLI flags --warmup and --runs, no env vars supported

    # Watchexec (file watcher) - If enabled in packages
    # WATCHEXEC_IGNORE = ".git,target,node_modules,.venv,__pycache__"; # (TODO: Uncomment when tool added)

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
    WEZTERM_UTILS_BIN = "${config.home.profileDirectory}/bin/wezterm-utils.sh";

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
    CLAUDE_CACHE_DIR = "${config.xdg.cacheHome}/claude";

    # --- Karabiner/Goku Configuration -----------------------------------------
    GOKU_EDN_CONFIG_FILE = "${config.xdg.configHome}/karabiner/karabiner.edn";

    # --- Network Tools ------------------------------------------------------
    # WHOIS_SERVER = "whois.iana.org"; # Optional: Default WHOIS server
    # IDN_DISABLE = "1"; # Optional: Disable IDN processing for dig

    # --- Terminal Web Browser (w3m) -----------------------------------------
    # w3m uses ~/.w3m/ directory (not XDG-compliant)
    # Configuration files are deployed via home.file in file-management.nix
    W3M_DIR = "${config.home.homeDirectory}/.w3m";
    WWW_HOME = "https://google.com"; # Default homepage when w3m starts with -v

    # --- File Manager Configuration ------------------------------------------
    # Yazi - Blazing fast terminal file manager (XDG-compliant)
    YAZI_CONFIG_HOME = "${config.xdg.configHome}/yazi"; # Explicit config directory
    YAZI_FILE_ONE = "${pkgs.file}/bin/file"; # File command for type detection

    # --- Media Processing Configuration ---------------------------------------
    # FFmpeg
    # Note: FFMPEG_DATADIR is deprecated and only used for preset file discovery
    # FFmpeg doesn't support XDG - uses ~/.ffmpeg/ for user configs
    FFREPORT = "file=${config.xdg.stateHome}/ffmpeg/ffreport.log:level=32"; # Controls automatic logging output and verbosity

    # ImageMagick
    MAGICK_CONFIGURE_PATH = "${config.xdg.configHome}/ImageMagick"; # Configuration files search path
    # Font path includes both system fonts and home-manager font packages
    MAGICK_FONT_PATH =
      if (context != null && context.isDarwin) then
        "/System/Library/Fonts:/Library/Fonts:${config.home.homeDirectory}/Library/Fonts:${config.home.profileDirectory}/share/fonts"
      else
        "${config.home.homeDirectory}/.local/share/fonts:/usr/share/fonts:${config.home.profileDirectory}/share/fonts";
    MAGICK_TEMPORARY_PATH = "${config.xdg.cacheHome}/ImageMagick"; # Temporary files path
    MAGICK_MEMORY_LIMIT = "2GB"; # Heap memory limit - optimized for large design files
    MAGICK_DISK_LIMIT = "2GB"; # Disk space limit
    MAGICK_THREAD_LIMIT = "0"; # 0 = Use all available CPU cores (ImageMagick auto-detects)

    # --- Document Processing ------------------------------------------------
    # Pandoc supports partial XDG compliance - uses XDG dirs but falls back to ~/.pandoc
    PANDOC_DATA_DIR = "${config.xdg.dataHome}/pandoc"; # Override default data directory for templates, filters, CSL files

    # --- Graph Visualization ------------------------------------------------
    # Graphviz - uses same font paths as ImageMagick
    # DOTFONTPATH = MAGICK_FONT_PATH; # Uncomment if Graphviz can't find fonts
    # D2 diagram scripting language
    D2_LAYOUT = "dagre"; # Default layout engine (dagre, elk, tala)

    # --- File & Directory Operations Tools ----------------------------------
    # Eza (modern ls replacement)
    EZA_CONFIG_DIR = "${config.xdg.configHome}/eza"; # Directory for theme.yml
    EZA_ICON_SPACING = "2"; # Spaces between icon and filename
    EZA_ICONS_AUTO = "1"; # Enable automatic icon display
    EZA_STRICT = "1"; # Error on incompatible options (good for scripts/automation)
    EZA_GRID_ROWS = "3"; # Min rows for grid-details view (prevents sparse layouts on wide screens)

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
