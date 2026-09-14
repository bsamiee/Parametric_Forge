# Title         : atuin.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/atuin.nix
# ----------------------------------------------------------------------------
# Modern shell history with SQLite backend and full-text search UI
{config, ...}: let
  inherit (config.forge.theme) roles;
in {
  # Hidden identity bundle row: Login Items & Extensions resolves the HM-owned atuin-daemon agent to "Atuin Daemon" instead of the "/bin/sh"
  # basename home-manager's mutateConfig writes into ProgramArguments[0].
  forge.bundleApps.atuin-daemon = "Atuin Daemon";

  # Identity + log rows merge into the HM module's agent config (freeform schema). The label stays upstream (org.nix-community.home.atuin-daemon):
  # the job is HM-module-generated, not repo-owned.
  launchd.agents.atuin-daemon.config = {
    AssociatedBundleIdentifiers = ["com.parametric-forge.atuin-daemon"];
    StandardOutPath = "${config.home.homeDirectory}/Library/Logs/forge-atuin-daemon.log";
    StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/forge-atuin-daemon.log";
  };

  programs.atuin = {
    enable = true;
    # HM evals `atuin init zsh` at order 1000: after fzf (910, whose ^R binding is off), so Atuin owns ^R and the up arrow.
    enableZshIntegration = true;
    daemon.enable = true; # launchd-managed: fast writes plus in-memory daemon-fuzzy search

    # Rows here differ from Atuin's documented defaults; the database and key sit at their XDG defaults under ~/.local/share/atuin.
    settings = {
      logs.dir = "${config.xdg.stateHome}/atuin/logs"; # the daemon's default log root is the hard-coded ~/.atuin/logs
      # History remains local until a new sync owner is deliberately configured.
      auto_sync = false;
      update_check = false;
      # Unset, `atuin init zsh` binds `?` on an empty line to the Hub-backed `atuin ai inline`, whose first-run chooser writes this row into the
      # read-only config on "Disable ? Keybind"; the declared row keeps `?` a self-insert.
      ai.enabled = false;
      search_mode = "daemon-fuzzy";
      search_mode_shell_up_key_binding = "prefix";
      filter_mode = "workspace";
      filter_mode_shell_up_key_binding = "global"; # Up arrow shows all history, not just current session
      ctrl_n_shortcuts = true;
      workspaces = true;
      style = "full";
      inline_height = 50;
      invert = true; # Search bar at top, matching fzf layout
      preview.strategy = "fixed"; # Prevents UI jumping
      max_preview_height = 6;
      keymap_mode = "auto";
      word_chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-";
      scroll_context_lines = 2;
      enter_accept = true;
      # Secrets and destructive host commands only; short/common commands are retrieval material and stay recorded.
      history_filter = [
        "^(rm|kill|pkill|killall|reboot|shutdown|passwd|sudo -i|su -)(\\s|$)"
        "(?i)(token|password|secret|api[_-]?key|bearer)[^\\n]*="
        "^export .*(_KEY|_TOKEN|_SECRET|PASSWORD)="
      ];
      cwd_filter = [
        "/tmp/.*"
        "/var/tmp/.*"
        ".*/\\.git/.*"
        ".*/node_modules/.*"
        ".*/target/debug/.*"
        ".*/target/release/.*"
      ];
      history_format = "{time} {directory} ❯ {command}";
      keys.scroll_exits = false;
      stats = {
        common_prefix = ["sudo" "time" "nohup"];
        common_subcommands = ["git" "cargo" "pnpm" "docker" "kubectl"];
        ignored_commands = ["ls" "cd" "pwd" "exit" "clear" "history"];
      };
      theme.name = "dracula";
    };

    # Dracula theme through the HM theme owner; atuin ships only autumn and marine natively.
    themes.dracula = {
      theme.name = "dracula";
      colors = {
        Base = roles.text.primary.hex;
        Muted = roles.text.muted.hex;
        Title = roles.accent.tertiary.hex;
        Annotation = roles.text.muted.hex;
        Guidance = roles.accent.primary.hex;
        Important = roles.accent.secondary.hex;
        AlertInfo = roles.state.info.hex;
        AlertWarn = roles.state.warning.hex;
        AlertError = roles.state.danger.hex;
      };
    };
  };
}
