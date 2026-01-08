# Title         : shell.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/environments/shell.nix
# ----------------------------------------------------------------------------
# Shell configuration environment variables
{config, ...}: {
  # --- User Session Path ----------------------------------------------------
  # Order matters: nix-darwin paths must be included for non-login shells (VS Code)
  home.sessionPath = [
    # User paths
    "$HOME/.nix-profile/bin"
    "$HOME/.local/bin"
    "$HOME/bin"
    "${config.xdg.dataHome}/cargo/bin"
    "${config.xdg.dataHome}/go/bin"
    "${config.xdg.dataHome}/pnpm"

    # Nix-darwin managed paths (atuin, zoxide, etc. live here)
    "/etc/profiles/per-user/${config.home.username}/bin"
    "/run/current-system/sw/bin"
    "/nix/var/nix/profiles/default/bin"

    # System tools
    "/opt/homebrew/opt/dotnet@8/bin"
    "/Applications/Rhino 8.app/Contents/Resources/bin"
  ];
  # Note: fnm PATH managed dynamically via `fnm env --use-on-cd` in zsh/init.nix

  home.sessionVariables = {
    # --- Node.js / fnm ------------------------------------------------------
    FNM_DIR = "${config.xdg.dataHome}/fnm"; # Static fnm data dir for VSCode/GUI apps

    # --- Shell Internals ----------------------------------------------------
    SQLITE_HISTORY = "${config.xdg.stateHome}/sqlite/history";
    LESSHISTFILE = "${config.xdg.stateHome}/less/history";
    ZSH_AUTOSUGGEST_STRATEGY = "(atuin completion)";
    ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE = "20";
    ZSH_AUTOSUGGEST_USE_ASYNC = "1"; # Significant performance improvement
    KEYTIMEOUT = "200";
    PAGER = "less"; # Let tools add their own flags
    BAT_PAGER = "less -RFXK"; # Bat pager: -X fixes macOS Terminal.app clearing
    PROCS_PAGER = "less -SRX"; # Procs pager: -S no wrap for tables, -R colors, -X no clear
    LESS = "-RFX"; # -X prevents screen clearing on macOS
    MANROFFOPT = "-c";
    RICH_THEME = "dracula";
    PNPM_HOME = "${config.xdg.dataHome}/pnpm"; # Global pnpm bin location

    # --- Tool Configurations ------------------------------------------------
    WATCHEXEC_IGNORE_FILE = "${config.xdg.configHome}/watchexec/ignore";
    RIPGREP_CONFIG_PATH = "${config.xdg.configHome}/ripgrep/config";
    TRIPPY_CONFIG_DIR = "${config.xdg.configHome}/trippy";
    STARSHIP_CACHE = "${config.xdg.cacheHome}/starship";
    EZA_CONFIG_DIR = "${config.xdg.configHome}/eza";
    BAT_CACHE_PATH = "${config.xdg.cacheHome}/bat";
    XH_CONFIG_DIR = "${config.xdg.configHome}/xh";
    ATUIN_LOG = "error";
    ACT_CACHE_DIR = "${config.xdg.cacheHome}/act";
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
    DOTNET_ROOT = "/opt/homebrew/opt/dotnet@8/libexec";
    DOTNET_NOLOGO = "1"; # Suppress startup banner
    DOTNET_CLI_TELEMETRY_OPTOUT = "1"; # Disable telemetry
  };
}
