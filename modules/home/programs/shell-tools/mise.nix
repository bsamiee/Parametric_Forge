# Title         : mise.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/mise.nix
# ----------------------------------------------------------------------------
# mise runtime manager: installed binary, interactive-zsh activation, a tool-free global config that never shadows a project's own
# `mise.toml`, and log rotation for the launchd agents `mise bootstrap` writes. Activation (`mise activate zsh`, a precmd/chpwd hook) makes
# a project's `[env]` and `[tools]` rows apply to the shell inside its tree, so a per-project variable is owned by that project's `mise.toml`,
# never by a machine-wide export. Non-interactive zsh (zsh/config.nix) and every Claude Code command (CLAUDE_ENV_FILE, toolchain-env.nix)
# apply `mise hook-env` once at start instead. Every process without either (a launchd agent, a GUI app) resolves a project's tools through
# the shim segment `toolchain-env.nix` puts first on every PATH vector, each shim reading its caller's directory and passing through to the
# next copy on PATH where no version is set. The global auto-install gate stays off so a missing tool is a typed failure, never a
# mid-command download; trust covers the estate roots so a project config composes freely while a foreign checkout's config never executes
# implicitly.
{
  config,
  launchdAgent,
  pkgs,
  ...
}: let
  # One .NET root every SDK installs into, so a process holding DOTNET_ROOT or this PATH segment resolves each SDK a later global.json names
  dotnetRoot = "${config.xdg.dataHome}/mise/dotnet-root";
  # Logs of every agent `mise bootstrap` writes (~/Library/LaunchAgents/dev.mise.<name>.plist, any project): launchd opens StandardOutPath and
  # StandardErrorPath once at spawn (O_APPEND) and never reopens them, so a renaming rotator (newsyslog) leaves the job writing into the
  # archive; copytruncate keeps the inode and the append offset follows the truncation.
  miseLogrotate = pkgs.writeShellApplication {
    name = "mise-logrotate";
    runtimeInputs = [pkgs.logrotate];
    text = ''
      shopt -s nullglob
      logs=()
      for plist in "$HOME"/Library/LaunchAgents/dev.mise.*.plist; do
        for key in StandardOutPath StandardErrorPath; do
          if path=$(/usr/bin/plutil -extract "$key" raw -o - "$plist" 2>/dev/null); then logs+=("$path"); fi
        done
      done
      ((''${#logs[@]})) || exit 0
      conf=$(mktemp)
      trap 'rm -f "$conf"' EXIT
      {
        printf '"%s"\n' "''${logs[@]}" | sort -u
        printf '{\n  size 10M\n  rotate 5\n  copytruncate\n  compress\n  delaycompress\n  missingok\n  notifempty\n}\n'
      } >"$conf"
      exec logrotate --state "${config.xdg.stateHome}/mise-logrotate.status" "$conf"
    '';
  };
in {
  programs.mise = {
    enable = true;
    package = pkgs.mise;
    # HM's integration has no order; zsh/init.nix evals `mise activate zsh` as the last interactive line, where mise documents it belongs.
    enableZshIntegration = false;
    globalConfig = {
      settings = {
        trusted_config_paths = ["~/Developer"];
        # The global gate every install path checks: off, so no command ever starts a download. It also turns off exec_auto_install and
        # not_found_auto_install, so activation drops the shim segment from PATH; zsh/init.nix keeps activation out of VS Code's
        # environment resolution for that reason.
        auto_install = false;
        disable_hints = ["*"]; # the wildcard every hint id matches (src/hint.rs)
        # Named, since mise otherwise installs into whatever DOTNET_ROOT the installing shell sets
        dotnet.dotnet_root = dotnetRoot;
      };
      # dotnet-install rewrites the root's `dotnet` host in place, and macOS kills every process mapping a rewritten signed binary: a fresh
      # inode before each install leaves running hosts on the unlinked one
      hooks.preinstall = ''
        if [ -f "${dotnetRoot}/dotnet" ]; then
          cp -p "${dotnetRoot}/dotnet" "${dotnetRoot}/dotnet.next"
          mv -f "${dotnetRoot}/dotnet.next" "${dotnetRoot}/dotnet"
        fi
      '';
    };
  };

  # --- [AGENT_LOG_ROTATION]
  # Hourly, as launchd runs newsyslog; a log past 10 MiB keeps five archives, the newest plain for direct reads and the older ones gzipped.
  estate.bundleApps.mise-logrotate = "Mise Log Rotation";
  launchd.agents.mise-logrotate = launchdAgent {
    name = "mise-logrotate";
    argv = ["${miseLogrotate}/bin/mise-logrotate"];
    StartCalendarInterval = [{Minute = 30;}];
  };
}
