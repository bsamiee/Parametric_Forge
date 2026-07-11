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
    xdgConfigHome = config.xdg.configHome;
  };
in {
  # --- [USER_SESSION_PATH]
  # Order matters: nix-darwin paths must be included for non-login shells (VS Code)
  home.sessionPath = toolchainEnv.userPathEntries;
  # pnpm installed via nix for PATH stability; PNPM_HOME is data/config only.

  # sessionEnv folds the class-gated pager/gcloud/gws/maghz/gh + interactive man/bat vocabulary; the rows below are session-only concerns.
  home.sessionVariables =
    toolchainEnv.sessionEnv
    // {
      # --- [SHELL_INTERNALS]
      SQLITE_HISTORY = "${config.xdg.stateHome}/sqlite/history";
      LESSHISTFILE = "${config.xdg.stateHome}/less/history";
      # ZSH_AUTOSUGGEST_STRATEGY is a zsh array, not a session scalar.
      ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE = "20";
      ZSH_AUTOSUGGEST_USE_ASYNC = "1";
      KEYTIMEOUT = "200";
      # procs reads no pager env var; its pager is config-owned, not env.
      RICH_THEME = "dracula"; # rich accepts named Pygments styles only; dracula matches the estate palette variant

      # --- [TOOL_CONFIGURATIONS]
      WATCHEXEC_IGNORE_FILE = "${config.xdg.configHome}/watchexec/ignore";
      RIPGREP_CONFIG_PATH = "${config.xdg.configHome}/ripgrep/config";
      TRIPPY_CONFIG_DIR = "${config.xdg.configHome}/trippy";
      STARSHIP_CACHE = "${config.xdg.cacheHome}/starship";
      EZA_CONFIG_DIR = "${config.xdg.configHome}/eza";
      BAT_CACHE_PATH = "${config.xdg.cacheHome}/bat";
      XH_CONFIG_DIR = "${config.xdg.configHome}/xh";
      ATUIN_LOG = "error";
      # act caches under XDG_CACHE_HOME/act natively; it reads no ACT_* path var.
      # Zoxide
      _ZO_DATA_DIR = "${config.xdg.dataHome}/zoxide";
      _ZO_RESOLVE_SYMLINKS = "1";
      _ZO_EXCLUDE_DIRS = "/tmp/*:/var/tmp/*:/usr/bin/*:/usr/sbin/*:/sbin/*:/bin/*";
      _ZO_DOCTOR = "0"; # Suppress false positive hook warnings
      # Rclone + Rsync
      RCLONE_CONFIG = "${config.xdg.configHome}/rclone/rclone.conf";
      RCLONE_TRANSFERS = "4"; # Balanced concurrent transfers
      RCLONE_CHECKERS = "8";
      RSYNC_RSH = "ssh";
      RSYNC_PROTECT_ARGS = "1"; # Protect args with spaces/wildcards (pre-3.2.4)

      # --- [FZF_FORGIT_CONFIGURATION]
      FORGIT_PAGER = "delta"; # Consistent with GIT_PAGER
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

      # --- [ZSH_PLUGIN_CONFIGURATIONS]
      YSU_MESSAGE_POSITION = "before";

      # --- [DOTNET]
      DOTNET_MULTILEVEL_LOOKUP = "0"; # Prefer deterministic Nix-provided SDK/runtime graph
      DOTNET_NOLOGO = "1";
      DOTNET_CLI_TELEMETRY_OPTOUT = "1";
    };
}
