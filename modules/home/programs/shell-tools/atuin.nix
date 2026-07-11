# Title         : atuin.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/atuin.nix
# ----------------------------------------------------------------------------
# Modern shell history with SQLite backend and full-text search UI
{config, ...}: let
  inherit (config.forge.theme) palette;
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
    enableZshIntegration = false;
    daemon.enable = true; # launchd-managed: fast writes plus in-memory daemon-fuzzy search

    settings = {
      db_path = "${config.xdg.dataHome}/atuin/history.db";
      key_path = "${config.xdg.dataHome}/atuin/key";
      # Sync rail: the maghz services.atuin host, loopback-only through the atuin tunnel (port 8788 — the Jupyter loopback owns 8888 on both
      # ends). Credential custody is Doppler: ATUIN_SYNC_PASSWORD for the one-time register/login, ATUIN_SYNC_KEY escrowing `atuin key`. Any
      # host with the tunnel plus Doppler joins; no per-machine roster exists anywhere.
      auto_sync = true;
      sync_address = "http://127.0.0.1:8788";
      sync_frequency = "15m";
      sync.records = true; # sync v2 store
      update_check = false;
      timezone = "local"; # system TZ via the TZ env var
      search_mode = "daemon-fuzzy";
      search_mode_shell_up_key_binding = "prefix";
      filter_mode = "workspace";
      filter_mode_shell_up_key_binding = "global"; # Up arrow shows all history, not just current session
      ctrl_n_shortcuts = true;
      disable_up_arrow = false;
      workspaces = true;
      style = "full";
      inline_height = 50;
      invert = true; # Search bar at top, matching fzf layout
      prefers_reduced_motion = false;
      preview = {
        strategy = "fixed"; # Prevents UI jumping
        max_height = 6;
      };
      show_preview = true;
      show_help = true;
      show_tabs = true;
      exit_mode = "return-original";
      keymap_mode = "auto";
      word_jump_mode = "emacs";
      word_chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-";
      scroll_context_lines = 2;
      enter_accept = true;
      network_timeout = 30;
      network_connect_timeout = 5;
      local_timeout = 5;
      secrets_filter = true;
      store_failed = true;
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
      keys = {
        scroll_exits = false;
        exit_past_line_start = true;
        accept_past_line_end = true;
      };
      stats = {
        common_prefix = ["sudo" "time" "nohup"];
        common_subcommands = ["git" "cargo" "pnpm" "docker" "kubectl"];
        ignored_commands = ["ls" "cd" "pwd" "exit" "clear" "history"];
      };
      theme = {
        name = "dracula";
      };
    };

    # Dracula theme through the HM theme owner; atuin ships only autumn and marine natively.
    themes.dracula = {
      theme.name = "dracula";
      colors = {
        Base = palette.foreground.hex;
        Muted = palette.comment.hex;
        Title = palette.pink.hex;
        Annotation = palette.comment.hex;
        Guidance = palette.cyan.hex;
        Important = palette.magenta.hex;
        AlertInfo = palette.green.hex;
        AlertWarn = palette.yellow.hex;
        AlertError = palette.red.hex;
      };
    };
  };
}
