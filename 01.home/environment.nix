# Title         : 01.home/environment.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/environment.nix
# ----------------------------------------------------------------------------
# Environment variables - organized by category

{
  config,
  context ? null,
  pkgs,
  ...
}:

{
  home.sessionVariables = {
    # --- Core System Configuration -------------------------------------------

    # Locale & Time
    LANG = "en_US.UTF-8";
    LC_ALL = "";
    TZ = "America/Chicago";

    # XDG Base Directory Specification
    XDG_CONFIG_HOME = "${config.xdg.configHome}";
    XDG_DATA_HOME = "${config.xdg.dataHome}";
    XDG_CACHE_HOME = "${config.xdg.cacheHome}";
    XDG_STATE_HOME = "${config.xdg.stateHome}";

    # Editor & Pager
    EDITOR = "nvim";
    VISUAL = "code --wait";
    PAGER = "less -FRX";
    LESS = "-FRX";
    GIT_PAGER = "delta";
    GH_PAGER = "delta";

    # Shell
    KEYTIMEOUT = "1";
    HISTFILE = "${config.xdg.stateHome}/zsh/history";
    LESSHISTFILE = "${config.xdg.stateHome}/less/history";
    SQLITE_HISTORY = "${config.xdg.stateHome}/sqlite/history";

    # Zsh-specific
    ZSH_AUTOSUGGEST_STRATEGY = "(history completion)";
    ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE = "20";
    ZSH_COMPDUMP = "${config.xdg.cacheHome}/zsh/zcompdump-\${ZSH_VERSION}";

    # --- Development Languages -----------------------------------------------

    # Rust
    CARGO_HOME = "${config.xdg.dataHome}/cargo";
    RUSTUP_HOME = "${config.xdg.dataHome}/rustup";
    RUSTC_WRAPPER = "sccache";
    SCCACHE_DIR = "${config.xdg.cacheHome}/sccache";
    SCCACHE_CACHE_SIZE = "10G";
    CARGO_NET_GIT_FETCH_WITH_CLI = "true";
    CARGO_TERM_COLOR = "always";
    CARGO_PROFILE_RELEASE_DEBUG = "true";
    CARGO_BINSTALL_DISABLE_TELEMETRY = "1";
    BINSTALL_DISABLE_TELEMETRY = "1";

    # Python
    PYTHONHISTORY = "${config.xdg.stateHome}/python/history";
    PYTHONDONTWRITEBYTECODE = "1";
    PIPX_HOME = "${config.xdg.dataHome}/pipx";
    PIPX_BIN_DIR = "${config.xdg.dataHome}/pipx/bin";
    PIPX_DEFAULT_PYTHON = "${config.home.homeDirectory}/.nix-profile/bin/python3";
    PYLINTHOME = "${config.xdg.cacheHome}/pylint";
    POETRY_VIRTUALENVS_IN_PROJECT = "true";
    POETRY_CACHE_DIR = "${config.xdg.cacheHome}/pypoetry";
    RUFF_CACHE_DIR = "${config.xdg.cacheHome}/ruff";
    MYPY_CACHE_DIR = "${config.xdg.cacheHome}/mypy";
    MYPY_CONFIG_FILE = "${config.xdg.configHome}/mypy/mypy.ini";
    UV_CACHE_DIR = "${config.xdg.cacheHome}/uv";
    PYTEST_CACHE_DIR = "${config.xdg.cacheHome}/pytest";
    NOX_CACHE_DIR = "${config.xdg.cacheHome}/nox";

    # Node/JavaScript
    NPM_CONFIG_USERCONFIG = "${config.xdg.configHome}/npm/npmrc";
    NPM_CONFIG_PREFIX = "${config.xdg.dataHome}/npm";
    NODE_REPL_HISTORY = "${config.xdg.dataHome}/node_repl_history";
    PNPM_HOME = "${config.xdg.dataHome}/pnpm";

    # Go
    GOPATH = "${config.xdg.dataHome}/go";

    # Lua
    LUAROCKS_TREE = "${config.xdg.dataHome}/luarocks";
    LUAROCKS_CONFIG = "${config.xdg.configHome}/luarocks/config.lua";

    # Java/JVM
    JAVA_OPTIONS = "-Djava.util.prefs.userRoot=${config.xdg.configHome}/java";
    _JAVA_OPTIONS = "-Djava.util.prefs.userRoot=${config.xdg.configHome}/java";

    # --- Container & DevOps Tools --------------------------------------------

    # Docker
    DOCKER_CONFIG = "${config.xdg.configHome}/docker";
    DOCKER_CERT_PATH = "${config.xdg.dataHome}/docker/certs";
    MACHINE_STORAGE_PATH = "${config.xdg.dataHome}/docker-machine";
    DOCKER_BUILDKIT = "1";
    COMPOSE_DOCKER_CLI_BUILD = "1";
    BUILDKIT_PROGRESS = "plain";
    BUILDKIT_TTY_LOG_LINES = "20";
    BUILDKIT_COLORS = "1";
    TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE = "/var/run/docker.sock";

    # Container Runtimes
    COLIMA_HOME = "${config.xdg.dataHome}/colima";
    CONTAINERS_CONF = "${config.xdg.configHome}/containers/containers.conf";
    CONTAINERS_REGISTRIES_CONF = "${config.xdg.configHome}/containers/registries.conf";
    CONTAINERS_STORAGE_CONF = "${config.xdg.configHome}/containers/storage.conf";
    PODMAN_USERNS = "keep-id";

    # Container Tools
    LAZYDOCKER_CONFIG_DIR = "${config.xdg.configHome}/lazydocker";
    DIVE_CONFIG = "${config.xdg.configHome}/dive/config.yaml";
    HADOLINT_CONFIG = "${config.xdg.configHome}/hadolint.yaml";

    # --- Developer Tools & Utilities -----------------------------------------

    # Version Control
    GH_CONFIG_DIR = "${config.xdg.configHome}/gh";
    GITLEAKS_CONFIG = "${config.xdg.configHome}/gitleaks/gitleaks.toml";
    GITLEAKS_NO_UPDATE_CHECK = "true";

    # Language Servers & Linters
    BASH_IDE_LOG_LEVEL = "info";
    SHELLCHECK_PATH = "shellcheck";
    SHFMT_PATH = "shfmt";
    YAMLLINT_CONFIG_FILE = "${config.xdg.configHome}/yamllint/config";

    # Text Processing Tools
    BAT_CACHE_PATH = "${config.xdg.cacheHome}/bat";
    RIPGREP_CONFIG_PATH = "${config.xdg.configHome}/ripgrep/config";

    # Build Systems
    MAKEFLAGS = "-j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)";
    CMAKE_BUILD_PARALLEL_LEVEL = "$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)";
    PRE_COMMIT_HOME = "${config.xdg.dataHome}/pre-commit";

    # Task Automation
    JUST_CHOOSER = "fzf";
    JUST_TIMESTAMP = "1";
    JUST_TIMESTAMP_FORMAT = "%Y-%m-%d %H:%M:%S";
    JUST_UNSTABLE = "1";

    # Nix Tools
    NIX_INDEX_DATABASE = "${config.xdg.cacheHome}/nix-index";

    # HTTP Clients
    XH_CONFIG_DIR = "${config.xdg.configHome}/xh";

    # Security
    SECRETS_GPG_COMMAND = "gpg";

    # Backup & Sync
    RCLONE_CONFIG = "${config.xdg.configHome}/rclone/rclone.conf";
    RESTIC_CACHE_DIR = "${config.xdg.cacheHome}/restic";

    # Development Utilities
    TLDR_CACHE_DIR = "${config.xdg.cacheHome}/tldr";
    PARALLEL = "-j+0 --bar --eta";

    # --- Application-Specific Configuration ----------------------------------

    # Starship Prompt
    STARSHIP_CACHE = "${config.xdg.cacheHome}/starship";

    # WezTerm Terminal
    WEZTERM_CONFIG_DIR = "${config.xdg.configHome}/wezterm";
    WEZTERM_RUNTIME_DIR = "${config.xdg.stateHome}/wezterm";
    WEZTERM_LOG_DIR = "${config.xdg.stateHome}/wezterm";
    WEZTERM_UTILS_BIN = "${config.home.profileDirectory}/bin/wezterm-utils.sh";

    # 1Password
    OP_ENV_TEMPLATE = config.secrets.paths.template;
    OP_ENV_CACHE = config.secrets.paths.cache;
    OP_BIOMETRIC_UNLOCK_ENABLED = "true";

    # Claude Code
    CLAUDE_CACHE_DIR = "${config.xdg.cacheHome}/claude";

    # Karabiner/Goku
    GOKU_EDN_CONFIG_FILE = "${config.xdg.configHome}/karabiner/karabiner.edn";

    # Web Browsers
    W3M_DIR = "${config.home.homeDirectory}/.w3m";
    WWW_HOME = "https://google.com";

    # --- Media & Document Processing -----------------------------------------

    # FFmpeg
    FFREPORT = "file=${config.xdg.stateHome}/ffmpeg/ffreport.log:level=32";

    # ImageMagick
    MAGICK_CONFIGURE_PATH = "${config.xdg.configHome}/ImageMagick";
    MAGICK_TEMPORARY_PATH = "${config.xdg.cacheHome}/ImageMagick";
    MAGICK_MEMORY_LIMIT = "2GB";
    MAGICK_DISK_LIMIT = "2GB";
    MAGICK_THREAD_LIMIT = "0";
    MAGICK_FONT_PATH =
      if (context != null && context.isDarwin) then
        "/System/Library/Fonts:/Library/Fonts:${config.home.homeDirectory}/Library/Fonts:${config.home.profileDirectory}/share/fonts"
      else
        "${config.home.homeDirectory}/.local/share/fonts:/usr/share/fonts:${config.home.profileDirectory}/share/fonts";

    # Document Processing
    PANDOC_DATA_DIR = "${config.xdg.dataHome}/pandoc";

    # Visualization
    D2_LAYOUT = "dagre";
    FONTCONFIG_PATH = "${config.xdg.configHome}/fontconfig";
    FONTCONFIG_FILE = "${config.xdg.configHome}/fontconfig/fonts.conf";
    FONTCONFIG_CACHE = "${config.xdg.cacheHome}/fontconfig";

    # --- System & Shell Utilities --------------------------------------------

    # File Operations
    RSYNC_RSH = "ssh";

    # File Type Detection
    MAGIC = "${pkgs.file}/share/misc/magic.mgc";

    # --- Privacy & Telemetry Opt-Outs ----------------------------------------
    DOTNET_CLI_TELEMETRY_OPTOUT = "1";
    GATSBY_TELEMETRY_DISABLED = "1";
    NEXT_TELEMETRY_DISABLED = "1";
    AZURE_CORE_COLLECT_TELEMETRY = "0";
    SAM_CLI_TELEMETRY = "0";
    POWERSHELL_TELEMETRY_OPTOUT = "1";
    DO_NOT_TRACK = "1";
  };

  # --- User Session Path ----------------------------------------------------
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
