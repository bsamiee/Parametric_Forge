# Title         : shell.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/environments/shell.nix
# ----------------------------------------------------------------------------
# Shell configuration environment variables

{ config, lib, pkgs, ... }:

{
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

  home.sessionVariables = {
    # --- Shell Internals -----------------------------------------------------
    SQLITE_HISTORY = "${config.xdg.stateHome}/sqlite/history";
    LESSHISTFILE = "${config.xdg.stateHome}/less/history";
    ZSH_COMPDUMP = "${config.xdg.cacheHome}/zsh/zcompdump-$ZSH_VERSION";
    ZSH_AUTOSUGGEST_STRATEGY = "(atuin completion)";
    ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE = "20";
    ZSH_AUTOSUGGEST_USE_ASYNC = "1";  # Significant performance improvement
    KEYTIMEOUT = "1";

    # --- Tool Configurations -------------------------------------------------
    BROOT_CONFIG_DIR = "${config.xdg.configHome}/broot";
    EZA_CONFIG_DIR = "${config.xdg.configHome}/eza";
    RIPGREP_CONFIG_PATH = "${config.xdg.configHome}/ripgrep/config";
    BAT_CACHE_PATH = "${config.xdg.cacheHome}/bat";
    # Atuin
    ATUIN_LOG = "error";
    # Zoxide
    _ZO_DATA_DIR = "${config.xdg.dataHome}/zoxide";
    _ZO_RESOLVE_SYMLINKS = "1";
    _ZO_EXCLUDE_DIRS = "/tmp/*:/var/tmp/*:/usr/bin/*:/usr/sbin/*:/sbin/*:/bin/*";

    # --- FZF Additional Configuration ---------------------------------------
    # Forgit Configuration
    FORGIT_PAGER = "delta";  # Consistent with GIT_PAGER in core.nix

    # Forgit-specific FZF options (uppercase labels)
    FORGIT_ADD_FZF_OPTS = "--border-label='[GIT ADD]'";
    FORGIT_DIFF_FZF_OPTS = "--border-label='[GIT DIFF]'";
    FORGIT_LOG_FZF_OPTS = "--border-label='[GIT LOG]'";
    FORGIT_RESET_HEAD_FZF_OPTS = "--border-label='[GIT RESET]'";
    FORGIT_CHECKOUT_FILE_FZF_OPTS = "--border-label='[GIT CHECKOUT]'";
    FORGIT_STASH_FZF_OPTS = "--border-label='[GIT STASH]'";
    FORGIT_CHERRY_PICK_FZF_OPTS = "--border-label='[GIT CHERRY-PICK]'";
    FORGIT_REBASE_FZF_OPTS = "--border-label='[GIT REBASE]'";
    FORGIT_FIXUP_FZF_OPTS = "--border-label='[GIT FIXUP]'";

    # General forgit options
    FORGIT_FZF_DEFAULT_OPTS = ''
      --height=80%
      --preview-window=right:60%:border-bold
    '';

    # --- ZSH Plugin Configurations -------------------------------------------
    # you-should-use
    YSU_MESSAGE_POSITION = "before";  # Show message before command execution
  };
}
