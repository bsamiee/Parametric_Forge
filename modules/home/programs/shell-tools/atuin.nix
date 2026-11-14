{
  config,
  launchdAgent,
  lib,
  pkgs,
  theme,
  ...
}: let
  inherit (theme) roles;
in {
  # --- [DAEMON]
  launchd.agents.atuin-daemon = launchdAgent {
    name = "atuin-daemon";
    argv = [(lib.getExe config.programs.atuin.package) "daemon" "start" "--force"];
    RunAtLoad = true;
    KeepAlive = true;
    ProcessType = "Interactive";
  };

  programs.atuin = {
    enable = true;
    package = pkgs.atuin-current;

    settings = {
      daemon = {
        enabled = true;
        autostart = false;
      };
      threads.capture = true;
      auto_sync = false;
      update_check = false;
      ai.enabled = false;
      search_mode = "daemon-fuzzy";
      search_mode_shell_up_key_binding = "prefix";
      filter_mode = "workspace";
      filter_mode_shell_up_key_binding = "global";
      ctrl_n_shortcuts = true;
      workspaces = true;
      style = "full";
      inline_height = 50;
      invert = true;
      preview.strategy = "fixed";
      max_preview_height = 6;
      keymap_mode = "auto";
      word_chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-";
      scroll_context_lines = 2;
      enter_accept = true;
      history_filter = [
        "(?i)(token|password|secret|api[_-]?key|bearer)[^\\n]*="
        "^export .*(_KEY|_TOKEN|_SECRET|PASSWORD)="
      ];
      cwd_filter = [
        "^/tmp(/|$)"
        "^/var/tmp(/|$)"
        ".*/\\.git/.*"
        ".*/node_modules/.*"
        ".*/target/debug/.*"
        ".*/target/release/.*"
      ];
      history_format = "{time} {directory} ❯ {command}";
      keys.scroll_exits = false;
      stats = {
        common_prefix = ["sudo" "time" "nohup"];
        common_subcommands = ["git" "cargo" "pnpm" "docker"];
        ignored_commands = ["ls" "cd" "pwd" "exit" "clear" "history"];
      };
      theme.name = "dracula";
    };

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
