# Title         : config.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/zsh/config.nix
# ----------------------------------------------------------------------------
# Zsh .zshenv floor for every shell: the PATH assertion, the never-clobber floor over the cross-surface rows, the op-injected session secrets,
# and the non-interactive mise refresh, closing .zshenv or, for a login shell, .zprofile.
{
  config,
  toolchainEnvFor,
  lib,
  ...
}: let
  toolchainEnv = toolchainEnvFor {
    home = config.home.homeDirectory;
    username = config.home.username;
    xdgCacheHome = config.xdg.cacheHome;
    xdgConfigHome = config.xdg.configHome;
    xdgDataHome = config.xdg.dataHome;
    xdgStateHome = config.xdg.stateHome;
  };
  # A non-interactive shell never draws the prompt `mise activate` refreshes at and inherits its launcher's mise state. hook-env's early exit
  # trusts the inherited session (directory, watched files, MISE_* rows) and never reads PATH. An inherited mise session already dropped the
  # shim segment and carries every other owner segment, so the assertion adds nothing and the refresh may exit early. Any other gap means PATH
  # was rebuilt outside mise, so the shim returns and the forced first run puts the current directory's installs and [env] rows ahead of it.
  # It runs as the last PATH writer each shell reads: .zshenv for a non-login shell, .zprofile for a login one. Inside a project whose tools
  # ship completions the output runs compinit unless compdef exists, so a no-op compdef makes that guard skip it and the dump it would write.
  miseRefresh = ''{ (( $+functions[compdef] )) || compdef() { :; }; eval "$(${lib.getExe config.programs.mise.package} hook-env ''${_mise_force} -s zsh)"; }'';
in {
  programs.zsh = {
    # Runs in .zshenv for ALL shells (login, interactive, scripts, zellij panes). PATH has ONE owner list, toolchain-env.nix pathEntries;
    # nix-darwin's set-environment (/etc/zshenv, every shell) writes it once per session and this file asserts it in every shell. NIX_* rows come
    # from the same file, man pages resolve from PATH (macOS manpath maps /opt/homebrew/bin to /opt/homebrew/share/man).
    envExtra = ''
      setopt no_equals # bare =-leading words (===, =foo) pass through as literals in every shell; =(...) process substitution is unaffected
      setopt no_nomatch # unmatched globs pass through literally so the tool reports honestly, matching sh/bash expansion semantics

      # The owner segments, asserted present before any tool init: set-environment lands the vector once per session behind its guard, so a
      # shell whose parent exported the guard with a different PATH would otherwise reach .zshrc's tool init without the profile bins. Only the
      # segments the inherited PATH lacks are prepended (array subtraction); the order is the mise refresh's at the end of startup, or `mise
      # activate`'s in an interactive shell. The unique flag takes effect on assignment per interface of the tied pair, so both carry it.
      typeset -U PATH path
      _session_path=(${lib.concatMapStringsSep " " lib.escapeShellArg toolchainEnv.pathEntries})
      _session_missing=(''${_session_path:|path})
      if (( ''${+__MISE_DIFF} )) && [[ $_session_missing == ${lib.escapeShellArg toolchainEnv.shimPath} ]]; then
        _session_missing=() _mise_force=
      else
        _mise_force=--force
      fi
      path=($_session_missing $path)
      unset _session_path _session_missing

      ${toolchainEnv.floorExports toolchainEnv.sharedEnv}
      # The mode-600 cache activation publishes (shell-tools/1password.nix), its rows in the same never-clobber form: every shell, login and
      # script ones included, carries the tokens gh, gws, and the deploy rail read, so a process its multiplexer starts through a login shell
      # holds them too, and a caller-scoped token survives.
      [[ ! -f ${lib.escapeShellArg config.forge.secrets.sessionCache} ]] || source ${lib.escapeShellArg config.forge.secrets.sessionCache}

      # A non-login script shell (an agent harness's `zsh -c` command) ends here; interactive zsh activates at the end of .zshrc (zsh/init.nix).
      [[ -o interactive || -o login ]] || ${miseRefresh}
      [[ -o login ]] || unset _mise_force
    '';
    # A non-interactive login shell (`zsh -lc`, a launchd or GUI spawn) refreshes here, after .zshenv.
    profileExtra = ''
      [[ -o interactive ]] || ${miseRefresh}
      unset _mise_force
    '';
  };
}
