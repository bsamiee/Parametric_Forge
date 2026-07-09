# Title         : atuin.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/atuin.nix
# ----------------------------------------------------------------------------
# Modern shell history with SQLite backend and full-text search UI
{
  config,
  lib,
  ...
}: let
  inherit (config.forge.theme) palette;
in {
  # Hidden identity bundle: Login Items & Extensions resolves the HM-owned
  # atuin-daemon agent to "Atuin Daemon" instead of the "/bin/sh" basename
  # home-manager's mutateConfig writes into ProgramArguments[0].
  home.file."Applications/Atuin Daemon.app/Contents/Info.plist".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>CFBundleIdentifier</key>
      <string>com.parametric-forge.atuin-daemon</string>
      <key>CFBundleName</key>
      <string>Atuin Daemon</string>
      <key>CFBundleDisplayName</key>
      <string>Atuin Daemon</string>
      <key>CFBundleVersion</key>
      <string>1</string>
      <key>CFBundleShortVersionString</key>
      <string>1.0</string>
      <key>CFBundlePackageType</key>
      <string>APPL</string>
      <key>LSUIElement</key>
      <true/>
      <key>LSBackgroundOnly</key>
      <true/>
    </dict>
    </plist>
  '';

  home.activation.registerAtuinDaemonApp = lib.hm.dag.entryAfter ["linkGeneration"] ''
    app="$HOME/Applications/Atuin Daemon.app"
    lsregister="/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"
    if [ -d "$app" ] && [ -x "$lsregister" ]; then
      "$lsregister" -f "$app" || true
    fi
  '';

  # Identity row merges into the HM module's agent config (freeform schema).
  launchd.agents.atuin-daemon.config.AssociatedBundleIdentifiers = ["com.parametric-forge.atuin-daemon"];

  programs.atuin = {
    enable = true;
    enableZshIntegration = false;
    # Launchd-managed daemon: fast writes plus in-memory daemon-fuzzy search.
    daemon.enable = true;

    settings = {
      db_path = "${config.xdg.dataHome}/atuin/history.db";
      key_path = "${config.xdg.dataHome}/atuin/key";
      # Sync rail: services.atuin on the maghz NixOS host (modules/nixos),
      # loopback-only through the ssh.nix vpsTunnels registry (atuin row, 8888).
      # Credential custody is Doppler: ATUIN_SYNC_PASSWORD for the one-time
      # register/login, ATUIN_SYNC_KEY escrowing `atuin key` — any host with
      # the tunnel plus Doppler joins; no per-machine roster exists anywhere.
      # auto_sync stays inert until the cutover-runbook login lands a session.
      auto_sync = true;
      sync_address = "http://127.0.0.1:8888";
      sync_frequency = "15m";
      sync.records = true; # sync v2 store
      update_check = false;
      timezone = "local"; # Uses system TZ (via TZ env var)
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
      prefers_reduced_motion = false; # Smooth animations
      preview = {
        strategy = "fixed"; # Prevents UI jumping
        max_height = 6; # Better command visibility
      };
      show_preview = true;
      show_help = true; # Shows keyboard shortcuts
      show_tabs = true;
      exit_mode = "return-original";
      keymap_mode = "auto";
      word_jump_mode = "emacs"; # Valid: "emacs" or "subl"
      word_chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-";
      scroll_context_lines = 2; # Better context when scrolling
      enter_accept = true;
      network_timeout = 30;
      network_connect_timeout = 5;
      local_timeout = 5;
      secrets_filter = true;
      store_failed = true;
      # Secrets and destructive host commands only; short/common commands are
      # retrieval material and stay recorded.
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
  };

  # Dracula theme file (atuin only has "autumn" and "marine" built-in)
  xdg.configFile."atuin/themes/dracula.toml".text = ''
    [theme]
    name = "dracula"

    [colors]
    Base = "${palette.foreground.hex}"
    Title = "${palette.pink.hex}"
    Annotation = "${palette.comment.hex}"
    Guidance = "${palette.cyan.hex}"
    Important = "${palette.magenta.hex}"
    AlertInfo = "${palette.green.hex}"
    AlertWarn = "${palette.yellow.hex}"
    AlertError = "${palette.red.hex}"
  '';
}
