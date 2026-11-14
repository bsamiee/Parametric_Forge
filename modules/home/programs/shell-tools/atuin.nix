{
  config,
  launchdAgent,
  lib,
  ...
}: let
  inherit (config.forge.theme) roles;
in {
  # --- [DAEMON]
  launchd.agents.atuin-daemon = launchdAgent {
    name = "atuin-daemon";
    argv = [(lib.getExe config.programs.atuin.package) "daemon" "start" "--force"];
    RunAtLoad = true;
    KeepAlive = true;
    ProcessType = "Interactive";
  };

  # --- [STORE_SIZE]
  home.activation.atuinStoreSize = lib.hm.dag.entryAfter ["writeBoundary"] ''
    store_bytes="$({ /usr/bin/stat -f %z ${lib.escapeShellArgs (map (db: "${config.xdg.dataHome}/atuin/${db}.db") ["records" "threads"])} 2>/dev/null || true; } | /usr/bin/awk '{ sum += $1 } END { print sum + 0 }')"
    echo "atuin-store: records.db and threads.db hold $((store_bytes / 1048576)) MiB"
    if ((store_bytes > 10000000000)); then
      echo "NOTICE: the Atuin store passed 10 GB and [threads] has no retention key: removing ai-session records is the owner's call" >&2
    fi
  '';

  programs.atuin = {
    enable = true;

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
