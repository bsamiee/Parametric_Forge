# Title         : config.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/zsh/config.nix
# ----------------------------------------------------------------------------
# Zsh .zshenv refresh for every shell: PATH, current managed variables, the op-injected session secrets,
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
  mise = lib.getExe config.programs.mise.package;
  miseRefresh = ''{ (( $+functions[compdef] )) || compdef() { :; }; eval "$(${mise} hook-env --force -s zsh)"; }'';
in {
  programs.zsh = {
    # Runs in .zshenv for ALL shells (login, interactive, scripts, zellij panes). PATH has ONE owner list, toolchain-env.nix pathEntries;
    # nix-darwin's set-environment (/etc/zshenv, every shell) writes it once per session and this file asserts it in every shell. NIX_* rows come
    # from the same file, man pages resolve from PATH (macOS manpath maps /opt/homebrew/bin to /opt/homebrew/share/man).
    envExtra = ''
      setopt no_equals # bare =-leading words (===, =foo) pass through as literals in every shell; =(...) process substitution is unaffected
      setopt no_nomatch # unmatched globs pass through literally so the tool reports honestly, matching sh/bash expansion semantics

      # Remove the inherited project's changes before establishing this generation's defaults. The final mise refresh applies the current
      # project's environment over those defaults and records them for a later directory change.
      if (( ''${+__MISE_DIFF} )); then
        eval "$(${mise} --no-config hook-env --force -s zsh)"
      fi

      # The owner segments, asserted present before any tool init: set-environment lands the vector once per session behind its guard, so a
      # shell whose parent exported the guard with a different PATH would otherwise reach .zshrc's tool init without the profile bins. Only the
      # segments the inherited PATH lacks are prepended (array subtraction); the order is the mise refresh's at the end of startup, or `mise
      # activate`'s in an interactive shell. The unique flag takes effect on assignment per interface of the tied pair, so both carry it.
      typeset -U PATH path
      _session_path=(${lib.concatMapStringsSep " " lib.escapeShellArg toolchainEnv.pathEntries})
      _session_missing=(''${_session_path:|path})
      path=($_session_missing $path)
      unset _session_path _session_missing

      ${config.lib.shell.exportAll toolchainEnv.runtimeEnv}
      typeset -A _session_defaults=(${lib.escapeShellArgs (lib.concatLists (lib.mapAttrsToList (name: value: [name value]) (removeAttrs (toolchainEnv.sessionEnv // toolchainEnv.sharedEnv) (builtins.attrNames toolchainEnv.runtimeEnv))))})
      for _session_name _session_default in "''${(@kv)_session_defaults}"; do
        _session_value="''${(P)_session_name:-}"
        if [[ -z $_session_value ]]; then
          export "$_session_name=$_session_default"
          continue
        fi
        for _session_word in ''${(z)_session_value}; do
          _session_word="''${(Q)_session_word}"
          _session_root="''${_session_word#${builtins.storeDir}/}"
          _session_root="${builtins.storeDir}/''${_session_root%%[/:]*}"
          if [[ $_session_word == "${builtins.storeDir}/"* && ! -e $_session_root ]]; then
            export "$_session_name=$_session_default"
            break
          fi
        done
      done
      unset _session_defaults _session_name _session_default _session_value _session_word _session_root
      # The mode-600 cache activation publishes (shell-tools/1password.nix), its rows retain caller values: every shell, login and
      # script ones included, carries the tokens gh, gws, and the deploy rail read, so a process its multiplexer starts through a login shell
      # holds them too, and a caller-scoped token survives.
      [[ ! -f ${lib.escapeShellArg config.forge.secrets.sessionCache} ]] || source ${lib.escapeShellArg config.forge.secrets.sessionCache}

      # A non-login script shell (an agent harness's `zsh -c` command) ends here; interactive zsh activates at the end of .zshrc (zsh/init.nix).
      [[ -o interactive || -o login ]] || ${miseRefresh}
    '';
    # A non-interactive login shell (`zsh -lc`, a launchd or GUI spawn) refreshes here, after .zshenv.
    profileExtra = ''
      [[ -o interactive ]] || ${miseRefresh}
    '';
  };
}
