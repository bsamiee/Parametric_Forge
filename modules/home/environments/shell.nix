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
    xdgDataHome = config.xdg.dataHome;
    xdgStateHome = config.xdg.stateHome;
  };
in {
  # --- [USER_SESSION_PATH]
  # One vector for the session and the launchd domain; Home Manager prepends it to the inherited PATH, so a non-login shell (VS Code) resolves
  # the same order as a login shell.
  home.sessionPath = toolchainEnv.sessionPathEntries;
  # pnpm installed via nix for PATH stability; PNPM_HOME is data/config only.

  # sessionEnv folds the class-gated pager/gcloud/gws vocabulary and the interactive man/bat/info rows; the rows below are session-only concerns
  # whose tool default is not already the declared path (zsh zle rows live in programs.zsh.localVariables, never the process environment).
  home.sessionVariables =
    toolchainEnv.sessionEnv
    // {
      # --- [SHELL_INTERNALS]
      # procs reads no pager env var; its pager is config-owned, not env; less keeps lesshst under XDG_STATE_HOME on its own.
      RICH_THEME = "dracula"; # rich accepts named Pygments styles only; dracula matches the estate palette variant

      # --- [TOOL_CONFIGURATIONS]
      # ripgrep reads no config file without this row; watchexec, fd, rclone, bat, xh, and trippy read their XDG paths on their own.
      RIPGREP_CONFIG_PATH = "${config.xdg.configHome}/ripgrep/config";
      # Timeout drops are by-design (command_timeout keeps the prompt under budget); error level stops the [WARN] pair a
      # cold toolchain spawn (first node exec after boot) would otherwise print into the terminal.
      STARSHIP_LOG = "error";
      STARSHIP_CACHE = "${config.xdg.cacheHome}/starship"; # starship joins $HOME/.cache itself (src/logger.rs get_log_dir) and reads no XDG_CACHE_HOME
      EZA_CONFIG_DIR = "${config.xdg.configHome}/eza"; # eza's fallback is dirs::config_dir (~/Library/Application Support on macOS), and only this path loads theme.yml (src/options/theme.rs)
      ATUIN_LOG = "error";
      # act caches under XDG_CACHE_HOME/act natively; it reads no ACT_* path var.
      # Zoxide: the macOS data default is ~/Library/Application Support; the exclude list keeps the documented $HOME member.
      _ZO_DATA_DIR = "${config.xdg.dataHome}/zoxide";
      _ZO_RESOLVE_SYMLINKS = "1";
      _ZO_EXCLUDE_DIRS = "${config.home.homeDirectory}:/tmp/*:/var/tmp/*:/usr/bin/*:/usr/sbin/*:/sbin/*:/bin/*";

      # --- [FZF_FORGIT_CONFIGURATION]
      # forgit's pager defaults to git's core.pager (delta through the HM delta integration); only the fzf chrome per command is declared.
      # Its commands reach the shell through the alias register (aliases/git.nix), so its own alias table stays off; forgit reads every knob
      # from the environment and warns at load on one it finds set but unexported, so each is a session row rather than a shell variable.
      FORGIT_NO_ALIASES = "1";
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
    };
}
