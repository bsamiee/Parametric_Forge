# Title         : atuin.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/atuin.nix
# ----------------------------------------------------------------------------
# Modern shell history with SQLite backend and full-text search UI

{ config, lib, pkgs, ... }:

# Dracula theme color reference
# background    #15131F
# current_line  #2A2640
# selection     #44475A
# foreground    #F8F8F2
# comment       #6272A4
# purple        #A072C6
# cyan          #94F2E8
# green         #50FA7B
# yellow        #F1FA8C
# orange        #F97359
# red           #FF5555
# magenta       #d82f94
# pink          #E98FBE

{
  programs.atuin = {
    enable = true;
    enableZshIntegration = false;

    settings = {
      db_path = "${config.xdg.dataHome}/atuin/history.db";
      key_path = "${config.xdg.dataHome}/atuin/key";
      auto_sync = false;
      sync_frequency = "1h";
      update_check = false;
      timezone = "local";  # Uses system TZ (via TZ env var)
      search_mode = "fuzzy";
      search_mode_shell_up_key_binding = "prefix";
      filter_mode = "global";
      filter_mode_shell_up_key_binding = "session";
      ctrl_n_shortcuts = true;
      disable_up_arrow = false;
      workspaces = true;
      style = "full";
      inline_height = 50;
      invert = true;   # Search bar at top, matching fzf layout
      prefers_reduced_motion = false;  # Smooth animations
      preview = {
        strategy = "fixed";  # Prevents UI jumping
        max_height = 6;  # Better command visibility
      };
      show_preview = true;
      show_help = true;  # Shows keyboard shortcuts
      show_tabs = true;
      exit_mode = "return-original";
      keymap_mode = "auto";
      word_jump_mode = "emacs";  # Valid: "emacs" or "subl"
      word_chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-";
      scroll_context_lines = 2;  # Better context when scrolling
      enter_accept = true;
      network_timeout = 30;
      network_connect_timeout = 5;
      local_timeout = 5;
      secrets_filter = true;
      store_failed = false;
      history_filter = [
        "^(rm|kill|pkill|killall|reboot|shutdown|passwd|sudo -i|su -).*"
        "^(ls|cd|pwd|exit|cd \\.\\.|clear|history|bg|fg)$"
        "^pnpm (run|start|test|build)$"
        "^(cat|bat|less|more) "
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
      colors = {
        Base = "#F8F8F2";           # Main text (fg+)
        Annotation = "#6272A4";     # Secondary text (info)
        AlertInfo = "#50FA7B";      # Success/info (marker/spinner)
        AlertWarn = "#F97359";      # Warning (orange)
        AlertError = "#FF5555";     # Error (red)
        Important = "#d82f94";      # Highlights (prompt/pointer)
        Guidance = "#94F2E8";       # Help text (hl/border)
        Title = "#E98FBE";          # Section titles (separator)
      };
    };
  };
}
