# Title         : shell.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/environments/shell.nix
# ----------------------------------------------------------------------------
# Shell configuration environment variables

{ config, pkgs, ... }:

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
    KEYTIMEOUT = "1";

    # --- Tool Configurations -------------------------------------------------
    ATUIN_LOG = "error";
    ATUIN_CONFIG_DIR = "${config.xdg.configHome}/atuin";
    BAT_CACHE_PATH = "${config.xdg.cacheHome}/bat";
    BROOT_CONFIG_DIR = "${config.xdg.configHome}/broot";
    RIPGREP_CONFIG_PATH = "${config.xdg.configHome}/ripgrep/config";
    TLDR_CACHE_DIR = "${config.xdg.cacheHome}/tldr";
    # Zoxide
    _ZO_DATA_DIR = "${config.xdg.dataHome}/zoxide";
    _ZO_ECHO = "1";
    _ZO_RESOLVE_SYMLINKS = "1";
    _ZO_MAXAGE = "10000";
    _ZO_EXCLUDE_DIRS = "/tmp/*:/var/tmp/*:/usr/bin/*:/usr/sbin/*:/sbin/*:/bin/*";

    # --- FZF Integration -----------------------------------------------------
    # FZF completion settings (these supplement FZF_DEFAULT_OPTS from programs.fzf)
    FZF_COMPLETION_TRIGGER = "**";
    FZF_COMPLETION_DIR_COMMANDS = "cd pushd rmdir tree cdi";
    FZF_COMPLETION_OPTS = "--preview-window=right:hidden";
    FZF_COMPLETION_PATH_OPTS = "--walker file,dir,follow,hidden";
    FZF_COMPLETION_DIR_OPTS = "--walker dir,follow";

    # Zoxide FZF integration (cdi command)
    _ZO_FZF_OPTS = "--border-label='[ Zoxide ]' --prompt='Jump❯ ' --header='CTRL-/ (preview) | ENTER (jump) | ESC (cancel)' --preview='eza {2}'";

    # Forgit plugin - inherits FZF_DEFAULT_OPTS automatically
    FORGIT_FZF_DEFAULT_OPTS = "--border-label='[ Forgit ]'";
    FORGIT_LOG_FORMAT = "%C(auto)%h%d %C(blue)%an %C(cyan)%cr%C(auto) %s";
    FORGIT_DIFF_PAGER = "delta";
    FORGIT_IGNORE_PAGER = "bat -l gitignore";
    FORGIT_INSTALL_DIR = "${pkgs.zsh-forgit}/share/zsh/zsh-forgit";

    # --- ZSH Plugin Configurations -------------------------------------------
    # you-should-use - alias reminder settings
    YSU_MODE = "BESTMATCH";  # Show only the best match alias (default)
    YSU_MESSAGE_POSITION = "before";  # Show message before command execution
  };
}
