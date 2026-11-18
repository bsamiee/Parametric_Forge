{
  config,
  launchdAgent,
  toolchainEnv,
  lib,
  pkgs,
  sshAgentSocket,
  ...
}: let
  guiEnvRows =
    toolchainEnv.sharedEnv
    // {
      PATH = lib.concatStringsSep ":" toolchainEnv.pathEntries;
      SSH_AUTH_SOCK = sshAgentSocket;
    };
  guiSetenv = pkgs.writeShellApplication {
    name = "gui-setenv";
    text = ''
      ledger="${config.xdg.stateHome}/gui-setenv/$1"
      shift
      declare -A replayed=()
      while (($# >= 2)); do
        replayed["$1"]=1
        if [[ "$(/bin/launchctl getenv "$1")" != "$2" ]]; then
          if [[ -n "$2" ]]; then
            /bin/launchctl setenv "$1" "$2"
          else
            /bin/launchctl unsetenv "$1"
          fi
        fi
        shift 2
      done
      if [[ -f "$ledger" ]]; then
        while IFS= read -r name; do
          [[ -z "''${replayed[$name]:-}" && -n "$(/bin/launchctl getenv "$name")" ]] || continue
          /bin/launchctl unsetenv "$name"
        done < "$ledger"
      fi
      mkdir -p "''${ledger%/*}"
      for name in "''${!replayed[@]}"; do
        printf '%s\n' "$name"
      done > "$ledger"
    '';
  };
  guiEnv = pkgs.writeShellApplication {
    name = "gui-env";
    text = "exec ${guiSetenv}/bin/gui-setenv gui-env ${lib.escapeShellArgs (lib.concatLists (lib.mapAttrsToList (name: value: [name value]) guiEnvRows))}";
  };
in {
  config = {
    # --- [LAUNCHD_AGENT_ROW]
    _module.args.launchdAgent = {
      name,
      argv,
      ...
    } @ row: {
      enable = true;
      config =
        {
          Label = "dev.bsamiee.${name}";
          ProgramArguments = argv;
          ProcessType = "Background";
          StandardOutPath = "${config.home.homeDirectory}/Library/Logs/${name}.log";
          StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/${name}.log";
        }
        // removeAttrs row ["name" "argv"];
    };

    home.packages = [toolchainEnv.editor];

    home.sessionVariables = toolchainEnv.sessionEnv;

    # --- [GUI_SESSION_ENVIRONMENT]
    _module.args.guiSetenv = guiSetenv;
    launchd.agents.gui-env = launchdAgent {
      name = "gui-env";
      argv = ["${guiEnv}/bin/gui-env"];
      RunAtLoad = true;
    };
  };
}
