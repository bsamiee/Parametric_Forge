# Title         : shell.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/environments/shell.nix
# ----------------------------------------------------------------------------
# Shell configuration environment variables
{
  config,
  forgeToolchainEnvFor,
  ...
}: let
  toolchainEnv = forgeToolchainEnvFor {
    home = config.home.homeDirectory;
    username = config.home.username;
    xdgCacheHome = config.xdg.cacheHome;
  };
in {
  # --- User Session Path ----------------------------------------------------
  # Order matters: nix-darwin paths must be included for non-login shells (VS Code)
  home.sessionPath = toolchainEnv.userPathEntries;
  # Note: pnpm installed via nix for PATH stability; PNPM_HOME is data/config only.

  home.sessionVariables = {
    # --- Shell Internals ----------------------------------------------------
    SQLITE_HISTORY = "${config.xdg.stateHome}/sqlite/history";
    LESSHISTFILE = "${config.xdg.stateHome}/less/history";
    # ZSH_AUTOSUGGEST_STRATEGY is a zsh array owned by zsh/init.nix, not a session scalar.
    ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE = "20";
    ZSH_AUTOSUGGEST_USE_ASYNC = "1"; # Significant performance improvement
    KEYTIMEOUT = "200";
    PAGER = "less"; # Let tools add their own flags
    BAT_PAGER = "less -RFXK"; # Bat pager: -X fixes macOS Terminal.app clearing
    # procs reads no pager env var; its pager command is owned by procs.nix config.
    LESS = "-RFX"; # -X prevents screen clearing on macOS
    MANROFFOPT = "-c";
    RICH_THEME = "dracula"; # rich accepts named Pygments styles only; dracula matches the estate palette variant

    # --- Tool Configurations ------------------------------------------------
    WATCHEXEC_IGNORE_FILE = "${config.xdg.configHome}/watchexec/ignore";
    RIPGREP_CONFIG_PATH = "${config.xdg.configHome}/ripgrep/config";
    TRIPPY_CONFIG_DIR = "${config.xdg.configHome}/trippy";
    STARSHIP_CACHE = "${config.xdg.cacheHome}/starship";
    EZA_CONFIG_DIR = "${config.xdg.configHome}/eza";
    BAT_CACHE_PATH = "${config.xdg.cacheHome}/bat";
    XH_CONFIG_DIR = "${config.xdg.configHome}/xh";
    ATUIN_LOG = "error";
    # act caches under XDG_CACHE_HOME/act natively; it reads no ACT_* path var.
    CLOUDSDK_CONFIG = "${config.xdg.configHome}/gcloud";
    WORKSPACE_MCP_CREDENTIALS_DIR = "${config.xdg.cacheHome}/workspace-mcp";
    GOOGLE_WORKSPACE_CLI_CONFIG_DIR = "${config.xdg.configHome}/gws";
    GOOGLE_WORKSPACE_PROJECT_ID = "workspace-mcp-500605";
    MAGHZ_REMOTE_HOST = "31.97.131.41";
    MAGHZ_REMOTE_USER = "maghz-agent";
    MAGHZ_REMOTE_WORKROOT = "/home/maghz-agent/maghz";
    # Zoxide
    _ZO_DATA_DIR = "${config.xdg.dataHome}/zoxide";
    _ZO_RESOLVE_SYMLINKS = "1";
    _ZO_EXCLUDE_DIRS = "/tmp/*:/var/tmp/*:/usr/bin/*:/usr/sbin/*:/sbin/*:/bin/*";
    _ZO_DOCTOR = "0"; # Suppress false positive hook warnings
    # Rclone + Rsync
    RCLONE_CONFIG = "${config.xdg.configHome}/rclone/rclone.conf";
    RCLONE_TRANSFERS = "4"; # Balanced concurrent transfers
    RCLONE_CHECKERS = "8"; # Parallel checkers for syncing
    RSYNC_RSH = "ssh"; # Explicit SSH transport for rsync
    RSYNC_PROTECT_ARGS = "1"; # Protect args with spaces/wildcards (pre-3.2.4)

    # --- FZF Forgit Configuration -------------------------------------------
    FORGIT_PAGER = "delta"; # Consistent with GIT_PAGER in core.nix
    FORGIT_ADD_FZF_OPTS = "--border-label='[GIT ADD]'";
    FORGIT_DIFF_FZF_OPTS = "--border-label='[GIT DIFF]'";
    FORGIT_LOG_FZF_OPTS = "--border-label='[GIT LOG]'";
    FORGIT_RESET_HEAD_FZF_OPTS = "--border-label='[GIT RESET]'";
    FORGIT_CHECKOUT_FILE_FZF_OPTS = "--border-label='[GIT CHECKOUT]'";
    FORGIT_STASH_FZF_OPTS = "--border-label='[GIT STASH]'";
    FORGIT_CHERRY_PICK_FZF_OPTS = "--border-label='[GIT CHERRY-PICK]'";
    FORGIT_REBASE_FZF_OPTS = "--border-label='[GIT REBASE]'";
    FORGIT_FIXUP_FZF_OPTS = "--border-label='[GIT FIXUP]'";
    FORGIT_FZF_DEFAULT_OPTS = ''
      --height=80%
      --preview-window=right:60%:border-bold
    '';

    # --- ZSH Plugin Configurations ------------------------------------------
    # you-should-use
    YSU_MESSAGE_POSITION = "before"; # Show message before command execution

    # --- .NET Configuration -------------------------------------------------
    DOTNET_MULTILEVEL_LOOKUP = "0"; # Prefer deterministic Nix-provided SDK/runtime graph
    DOTNET_NOLOGO = "1"; # Suppress startup banner
    DOTNET_CLI_TELEMETRY_OPTOUT = "1"; # Disable telemetry
  };
}
