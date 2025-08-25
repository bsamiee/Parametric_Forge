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
    TZ = config.configuration.settings.system.timezone or "America/Chicago"; # Timezone from configuration

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
    # Node/npm
    NPM_CONFIG_USERCONFIG = "${config.xdg.configHome}/npm/npmrc";
    NPM_CONFIG_PREFIX = "${config.xdg.dataHome}/npm";
    NODE_REPL_HISTORY = "${config.xdg.dataHome}/node_repl_history";
    # Python
    # PYTHONSTARTUP not set - no pythonrc file exists
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

    # --- XDG-Compliant Shell History ----------------------------------------
    HISTFILE = "${config.xdg.stateHome}/bash/history";
    LESSHISTFILE = "${config.xdg.stateHome}/less/history";
    SQLITE_HISTORY = "${config.xdg.stateHome}/sqlite/history";

    # --- XDG-Compliant Application Config -----------------------------------
    DOCKER_CONFIG = "${config.xdg.configHome}/docker";
    MACHINE_STORAGE_PATH = "${config.xdg.dataHome}/docker-machine";
    COLIMA_HOME = "${config.xdg.dataHome}/colima";
    CONTAINERS_CONF = "${config.xdg.configHome}/containers/containers.conf";
    GH_CONFIG_DIR = "${config.xdg.configHome}/gh";
    GH_PAGER = "delta"; # Use delta for rich diffs in gh commands
    GNUPGHOME = "${config.xdg.dataHome}/gnupg";
    GRADLE_USER_HOME = "${config.xdg.dataHome}/gradle";
    LUAROCKS_CONFIG = "${config.xdg.configHome}/luarocks/config.lua";

    # --- Formatter Configs --------------------------------------------------
    # Note: Only some tools support env vars for config paths
    YAMLLINT_CONFIG_FILE = "${config.xdg.configHome}/yamllint/config"; # Supported by yamllint

    # --- Additional Language Server Paths -----------------------------------
    # Lua package manager
    LUAROCKS_TREE = "${config.xdg.dataHome}/luarocks";

    # --- Font Configuration -------------------------------------------------
    FONTCONFIG_PATH = "${config.xdg.configHome}/fontconfig";
    FONTCONFIG_FILE = "${config.xdg.configHome}/fontconfig/fonts.conf";
    FONTCONFIG_CACHE = "${config.xdg.cacheHome}/fontconfig";

    # --- Performance & Build Settings ---------------------------------------
    DOCKER_BUILDKIT = "1";
    COMPOSE_DOCKER_CLI_BUILD = "1";
    TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE = "/var/run/docker.sock";
    MAKEFLAGS = "-j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)";
    CMAKE_BUILD_PARALLEL_LEVEL = "$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)";

    # --- Temporary Directory Management -------------------------------------
    # npm uses this for package extraction during install
    NPM_CONFIG_TMP = "${config.xdg.cacheHome}/npm-tmp";
    # xh (our HTTP client) configuration directory
    XH_CONFIG_DIR = "${config.xdg.configHome}/xh";

    # --- Privacy & Telemetry Opt-Outs ---------------------------------------
    DOTNET_CLI_TELEMETRY_OPTOUT = "1";
    GATSBY_TELEMETRY_DISABLED = "1";
    NEXT_TELEMETRY_DISABLED = "1";
    AZURE_CORE_COLLECT_TELEMETRY = "0";
    SAM_CLI_TELEMETRY = "0";
    POWERSHELL_TELEMETRY_OPTOUT = "1";
    DO_NOT_TRACK = "1";

    # --- Tool Configurations ------------------------------------------------
    # Difftastic configuration
    DFT_BACKGROUND = "dark";
    DFT_DISPLAY = "inline";
    # Enhanced directory colors (molokai theme)
    LS_COLORS = "fi=00:mi=00:mh=00:ln=01;36:or=01;31:di=01;34:ow=04;01;34:st=34:tw=04;34:pi=01;33:so=01;33:bd=33:cd=33:su=01;35:sg=01;35:ca=01;33:ex=01;32";
    # Nix-index database location
    NIX_INDEX_DATABASE = "${config.xdg.cacheHome}/nix-index";

    # --- Java/JVM Configuration (XDG-compliant) -----------------------------
    JAVA_OPTIONS = "-Djava.util.prefs.userRoot=${config.xdg.configHome}/java";
    _JAVA_OPTIONS = "-Djava.util.prefs.userRoot=${config.xdg.configHome}/java";

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
    CLAUDE_CONFIG_DIR = "${config.home.homeDirectory}/.claude";
    CLAUDE_CACHE_DIR = "${config.xdg.cacheHome}/claude";
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
  ];
}
