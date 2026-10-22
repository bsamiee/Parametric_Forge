# Title         : config.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/zsh/config.nix
# ----------------------------------------------------------------------------
# Zsh .zshenv floor for every shell: the PATH assertion, the never-clobber floor over the scientific and cross-surface rows, the op-injected
# session secrets, and the non-interactive mise refresh, closing .zshenv or, for a login shell, .zprofile.
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
  # A non-interactive shell never draws the prompt `mise activate` refreshes at and inherits its launcher's mise state, which hook-env's early
  # exit (directory, watched files, MISE_* rows; never PATH) takes as current. Startup files ran again, so the first-run --force applies, as
  # `mise activate`'s own first hook does: hook-env reverts the inherited diff and puts the current directory's installs and [env] rows ahead
  # of the floor. It runs as the last PATH writer each shell reads: .zshenv for a non-login shell, .zprofile after hm-session-vars for a login one.
  # Inside a project whose tools ship completions the output runs compinit unless compdef exists, so a no-op compdef makes that guard skip it
  # and the dump it would write.
  miseRefresh = ''{ (( $+functions[compdef] )) || compdef() { :; }; eval "$(${lib.getExe config.programs.mise.package} hook-env --force -s zsh)"; }'';
in {
  programs.zsh = {
    # Runs in .zshenv for ALL shells (login, interactive, scripts, zellij panes). PATH has ONE owner list, toolchain-env.nix pathEntries;
    # home.sessionPath projects it once per session and this file asserts it in every shell. NIX_* rows come from nix-darwin's /etc/zshenv
    # (set-environment, every shell), man pages resolve from PATH (macOS manpath maps /opt/homebrew/bin to /opt/homebrew/share/man).
    envExtra = ''
      setopt no_equals # bare =-leading words (===, =foo) pass through as literals in every shell; =(...) process substitution is unaffected
      setopt no_nomatch # unmatched globs pass through literally so the tool reports honestly, matching sh/bash expansion semantics

      # The owner segments, asserted present before any tool init: hm-session-vars lands home.sessionPath once per session behind its guard and
      # nix-darwin's set-environment behind its own, so a shell whose parent exported either guard with a different PATH would otherwise reach
      # .zshrc's tool init without the profile bins. Only the segments the inherited PATH lacks are prepended (array subtraction); the order is
      # the mise refresh's at the end of startup, or `mise activate`'s in an interactive shell. The unique flag takes effect on assignment per
      # interface of the tied pair, so both carry it: the array here and the scalar for hm-session-vars' later prepend, which then adds no second
      # copy of any segment.
      typeset -U PATH path
      _session_path=(${lib.concatMapStringsSep " " lib.escapeShellArg toolchainEnv.sessionPathEntries})
      path=(''${_session_path:|path} $path)
      unset _session_path

      ${toolchainEnv.floorExports (toolchainEnv.scientificSessionEnv // toolchainEnv.launchdEnv)}
      # The mode-600 cache activation publishes (shell-tools/1password.nix), its rows in the same never-clobber form: every shell, login and
      # script ones included, carries the tokens gh, gws, and the deploy rail read, so a process its multiplexer starts through a login shell
      # holds them too, and a caller-scoped token survives.
      [[ ! -f ${lib.escapeShellArg config.forge.secrets.sessionCache} ]] || source ${lib.escapeShellArg config.forge.secrets.sessionCache}

      # A non-login script shell (an agent harness's `zsh -c` command) ends here; interactive zsh activates at the end of .zshrc (zsh/init.nix).
      [[ -o interactive || -o login ]] || ${miseRefresh}
    '';
    # A non-interactive login shell (`zsh -lc`, a launchd or GUI spawn) reads hm-session-vars here, after .zshenv, and its prepend ends last.
    profileExtra = ''
      [[ -o interactive ]] || ${miseRefresh}
    '';
  };
}
