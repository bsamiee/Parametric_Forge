# Title         : shell.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/environments/shell.nix
# ----------------------------------------------------------------------------
# Shell environment variables, their GUI launchd domain replay, and the launchd agent row every dev.bsamiee.<name> agent is built from
{
  config,
  launchdAgent,
  toolchainEnvFor,
  lib,
  pkgs,
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
  # A fresh GUI domain carries no locale or XDG roots, and `launchctl setenv` state dies with the login session, so the rows replay at every
  # login. The HM xdg module derives the XDG rows. PATH is no row: launchd takes the user domain's PATH from `launchctl config user path`
  # alone, which nix-darwin activation writes (modules/darwin/settings/system.nix).
  guiEnvRows =
    toolchainEnv.sharedEnv
    // {
      # The 1Password agent for every process the domain launches afterwards (1Password's SSH client compatibility form), in place of the
      # identity-less agent launchd hands out.
      SSH_AUTH_SOCK = config.forge.ssh.identityAgent;
      inherit (config.home.sessionVariables) LANG XDG_CONFIG_HOME XDG_CACHE_HOME XDG_DATA_HOME XDG_STATE_HOME;
    };
  # The one GUI-domain writer every replay agent execs with NAME VALUE pairs; an empty VALUE unsets NAME. launchd orders no user agent against
  # another and copies the domain env into a process only at spawn, so a resident agent that won the login race (pitchfork's supervisor) holds
  # the domain as it stood before the replay. A pass that changed a value restarts every running KeepAlive agent in the user agent directory,
  # where user-scope tools (`pitchfork boot enable`, `brew services`, Home Manager) register: launchd respawns those on exit by their own
  # declaration, and one-shot replays carry no KeepAlive, so no replay restarts another. A pass that changed nothing restarts nothing, so a
  # switch that reruns a replay leaves resident agents alone.
  guiSetenv = pkgs.writeShellApplication {
    name = "gui-setenv";
    text = ''
      changed=0
      while (($# >= 2)); do
        if [[ "$(/bin/launchctl getenv "$1")" != "$2" ]]; then
          if [[ -n "$2" ]]; then
            /bin/launchctl setenv "$1" "$2"
          else
            /bin/launchctl unsetenv "$1"
          fi
          changed=1
        fi
        shift 2
      done
      ((changed == 1)) || exit 0
      for plist in "${config.home.homeDirectory}"/Library/LaunchAgents/*.plist; do
        # raw prints true or false for a bool and the key list for a KeepAlive condition dictionary; an absent key fails the extract.
        keepalive="$(/usr/bin/plutil -extract KeepAlive raw -o - "$plist" 2>/dev/null)" || continue
        [[ "$keepalive" != false ]] || continue
        label="$(/usr/bin/plutil -extract Label raw -o - "$plist")"
        [[ "$(/bin/launchctl print "gui/$UID/$label" 2>/dev/null)" == *"state = running"* ]] || continue
        /bin/launchctl kickstart -k "gui/$UID/$label"
        printf 'restarted %s\n' "$label"
      done
    '';
  };
  guiEnv = pkgs.writeShellApplication {
    name = "gui-env";
    text = "exec ${guiSetenv}/bin/gui-setenv ${lib.escapeShellArgs (lib.concatLists (lib.mapAttrsToList (name: value: [name value]) guiEnvRows))}";
  };
in {
  # --- [LAUNCHD_AGENT_ROW]
  # One launchd-agent grammar: label, argv, background class, and one dual log per agent; every other key (schedule, KeepAlive, RunAtLoad,
  # ThrottleInterval) rides as given.
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

  # sessionEnv folds the interactive man/bat/info rows; PATH and the cross-surface rows are nix-darwin's set-environment
  # (modules/darwin/settings/system.nix). The rows below are session-only concerns whose tool default is not already the declared path (zsh zle
  # rows live in programs.zsh.localVariables, never the process environment).
  home.sessionVariables =
    toolchainEnv.sessionEnv
    // {
      # --- [SHELL_INTERNALS]
      # procs reads no pager env var; its pager is config-owned, not env; less keeps lesshst under XDG_STATE_HOME on its own.
      RICH_THEME = "dracula"; # rich accepts named Pygments styles only; dracula matches the theme palette variant

      # --- [TOOL_CONFIGURATIONS]
      # watchexec, fd, rclone, bat, xh, and trippy read their XDG paths on their own.
      # Timeout drops are by-design (command_timeout keeps the prompt under budget); error level stops the [WARN] pair a
      # cold toolchain spawn (first node exec after boot) would otherwise print into the terminal.
      STARSHIP_LOG = "error";
      EZA_CONFIG_DIR = "${config.xdg.configHome}/eza"; # eza's fallback is dirs::config_dir (~/Library/Application Support on macOS), and only this path loads theme.yml (src/options/theme.rs)
      ATUIN_LOG = "error";
      # act caches under XDG_CACHE_HOME/act natively; it reads no ACT_* path var.
      # Zoxide: the macOS data default is ~/Library/Application Support; the exclude list keeps the documented $HOME member.
      _ZO_DATA_DIR = "${config.xdg.dataHome}/zoxide";
      _ZO_RESOLVE_SYMLINKS = "1";
      _ZO_EXCLUDE_DIRS = "${config.home.homeDirectory}:/tmp/*:/var/tmp/*:/usr/bin/*:/usr/sbin/*:/sbin/*:/bin/*";

      # --- [FZF_FORGIT_CONFIGURATION]
      # forgit's pager defaults to git's core.pager (delta through the HM delta integration); only the fzf chrome per command is declared.
      # git-forgit runs as a git subcommand process, so every knob it reads is an exported session row rather than a shell variable.
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
  # RunAtLoad replays the rows at each login, and a changed row set rewrites the argv, so the switch that lands it reloads and reruns the agent;
  # either run that changes a value restarts the resident agents that spawned before it. 1password.nix replays its secret rows through the same
  # writer. An app login restores before launchd runs its agents keeps its launch environment; WezTerm projects its own spawn rows
  # (apps/wezterm/deck.lua).
  _module.args.guiSetenv = guiSetenv;
  launchd.agents.gui-env = launchdAgent {
    name = "gui-env";
    argv = ["${guiEnv}/bin/gui-env"];
    RunAtLoad = true;
  };
}
