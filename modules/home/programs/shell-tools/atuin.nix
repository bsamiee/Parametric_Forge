# Title         : atuin.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/atuin.nix
# ----------------------------------------------------------------------------
# Modern shell history with SQLite backend and full-text search UI

{ config, lib, pkgs, ... }:

{
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = false;

    settings = {
      db_path = "${config.xdg.dataHome}/atuin/history.db";
      key_path = "${config.xdg.dataHome}/atuin/key";

      auto_sync = false;
      sync_frequency = "1h";
      update_check = false;

      timezone = "local";  # Uses system TZ (via TZ env var)

      search_mode = "fuzzy";
      filter_mode = "host";
      filter_mode_shell_up_key_binding = "session";
      workspaces = true;

      style = "compact";
      inline_height = 25;
      max_preview_height = 4;
      show_preview = true;
      show_help = false;
      show_tabs = true;
      exit_mode = "return-original";

      keymap_mode = "auto";
      word_jump_mode = "emacs";  # Valid: "emacs" or "subl"
      word_chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-";
      scroll_context_lines = 1;
      enter_accept = true;

      network_timeout = 30;
      network_connect_timeout = 5;
      local_timeout = 5;

      secrets_filter = true;
      store_failed = false;

      history_filter = [
        "^(rm|kill|pkill|killall|reboot|shutdown|passwd|sudo -i|su -).*"
        "^(ls|cd|pwd|exit|cd \\.\\.|clear|history|bg|fg)$"
        "^git.*token"
        "^git.*password"
        "export.*KEY"
        "export.*TOKEN"
        "export.*SECRET"
        "^.{1,3}$"
      ];

      cwd_filter = [
        "/tmp/.*"
        "/var/tmp/.*"
        ".*/\\.git/.*"
        ".*/node_modules/.*"
        ".*/target/debug/.*"
        ".*/target/release/.*"
      ];

      history_format = "{time} | {directory} | {command}";

      keys = {
        scroll_exits = false;
        exit_past_line_start = true;
        accept_past_line_end = true;
      };

      stats = {
        common_prefix = ["sudo" "time" "nohup"];
        common_subcommands = ["git" "cargo" "npm" "docker" "kubectl"];
        ignored_commands = ["ls" "cd" "pwd" "exit" "clear" "history"];
      };
    };
  };
}
