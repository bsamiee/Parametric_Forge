{
  config,
  launchdAgent,
  toolchainEnvFor,
  lib,
  pkgs,
  sshAgentSocket,
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

    home.sessionVariables =
      toolchainEnv.sessionEnv
      // {
        # --- [TOOL_CONFIGURATIONS]
        STARSHIP_LOG = "error";
        EZA_CONFIG_DIR = "${config.xdg.configHome}/eza";
        ATUIN_LOG = "error";
        CARAPACE_MATCH = "1";
        _ZO_DATA_DIR = "${config.xdg.dataHome}/zoxide";
        _ZO_RESOLVE_SYMLINKS = "1";
        _ZO_EXCLUDE_DIRS = "${config.home.homeDirectory}:/private/tmp:/private/tmp/*:/private/var/tmp/*:/private/var/folders/*:/usr/bin/*:/usr/sbin/*:/sbin/*:/bin/*";

        # --- [FZF_FORGIT_CONFIGURATION]
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

    # --- [GUI_SESSION_ENVIRONMENT]
    _module.args.guiSetenv = guiSetenv;
    launchd.agents.gui-env = launchdAgent {
      name = "gui-env";
      argv = ["${guiEnv}/bin/gui-env"];
      RunAtLoad = true;
    };
  };
}
