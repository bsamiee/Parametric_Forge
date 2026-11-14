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
    envExtra = ''
      setopt no_equals
      setopt no_nomatch
      disable log

      if (( ''${+__MISE_DIFF} )); then
        eval "$(${mise} --no-config hook-env --force -s zsh)"
      fi

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
      [[ ! -f ${lib.escapeShellArg config.forge.secrets.sessionCache} ]] || source ${lib.escapeShellArg config.forge.secrets.sessionCache}

      [[ -o interactive || -o login ]] || ${miseRefresh}
    '';
    profileExtra = ''
      [[ -o interactive ]] || ${miseRefresh}
    '';
    initContent = lib.mkOrder 1950 ''
      # --- [SESSION_CACHE_REFRESH]
      _session-cache-refresh() {
        local stamp=$FORGE_OP_STAMP
        [[ ! -f ${lib.escapeShellArg config.forge.secrets.sessionCache} ]] || source ${lib.escapeShellArg config.forge.secrets.sessionCache}
        [[ $stamp == $FORGE_OP_STAMP ]] || ${miseRefresh}
      }
      autoload -Uz add-zsh-hook
      add-zsh-hook precmd _session-cache-refresh
    '';
  };
}
