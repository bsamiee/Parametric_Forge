{
  config,
  launchdAgent,
  lib,
  pkgs,
  theme,
  ...
}: let
  inherit (theme) roles;
  atuin = lib.getExe config.programs.atuin.package;
in {
  # --- [DAEMON]
  launchd.agents.atuin-daemon = launchdAgent {
    name = "atuin-daemon";
    argv = [atuin "daemon" "start" "--force"];
    RunAtLoad = true;
    KeepAlive = true;
    ProcessType = "Interactive";
  };

  xdg.configFile."atuin/config.toml".onChange = ''
    run /bin/launchctl kickstart -k "gui/$UID/${config.launchd.agents.atuin-daemon.config.Label}"
  '';

  home.sessionVariables.ATUIN_LOG = "error";

  # --- [PTY_PROXY]
  programs.zsh.initContent = lib.mkOrder 0 ''
    eval "$(${atuin} pty-proxy init zsh)"
  '';

  programs.atuin = {
    enable = true;
    package = pkgs.atuin;
    flags = ["--bind-ai-resume"];

    settings = {
      sync_address = "https://atuin.parametric-arsenal.cloud";
      daemon.enabled = true;
      output = {
        enabled = true;
        max_disk_usage = "10GiB";
        command_filter = [
          "(^|&&|;)\\s*(cat|bat|head|tail|nl|less)(\\s|$)"
          "(^|&&|;)\\s*sed\\s+-[a-zA-Z]*n[a-zA-Z]*\\s"
        ];
      };
      threads = {
        capture = true;
        filter_mode = "workspace";
        resume.codex = "codex resume --no-daemon {id}";
      };
      update_check = false;
      ai.enabled = false;
      search_mode = "daemon-fuzzy";
      search_mode_shell_up_key_binding = "prefix";
      filter_mode = "workspace";
      filter_mode_shell_up_key_binding = "global";
      search.filters = ["workspace" "directory" "session" "global"];
      command_chaining = true;
      ctrl_n_shortcuts = true;
      style = "full";
      inline_height = 50;
      inline_height_shell_up_key_binding = 15;
      invert = true;
      preview.strategy = "fixed";
      max_preview_height = 6;
      keymap_mode = "auto";
      word_chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-";
      scroll_context_lines = 2;
      ui.columns = [
        "exit"
        "duration"
        "time"
        {
          type = "directory";
          width = 24;
        }
        "command"
      ];
      history_filter = ["^echo wait(ing)?$"];
      cwd_filter = [
        "^(/private)?/tmp(/|$)"
        "^(/private)?/var/tmp(/|$)"
        ".*/\\.git/.*"
        ".*/node_modules/.*"
        ".*/target/debug/.*"
        ".*/target/release/.*"
      ];
      history_format = "{time} {directory} ❯ {command}";
      keymap.emacs.down = "select-next";
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
