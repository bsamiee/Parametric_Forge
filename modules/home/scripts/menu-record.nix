{
  config,
  launchdAgent,
  lib,
  pkgs,
  ...
}: let
  stream = "${config.home.homeDirectory}/Library/Biome/streams/restricted/App.MenuItem/local";
  store = "${config.xdg.stateHome}/menu-record";
  retentionDays = 365;
  reader = "git+https://github.com/cclgroupltd/ccl-segb@23c3f7d3d969a79627b738ba0a2486c31d675753";
  menuRecord = pkgs.writeShellApplication {
    name = "menu-record";
    runtimeInputs = [pkgs.uv];
    text = ''
      shopt -s nullglob
      segments=(${lib.escapeShellArg store}/*)
      ((''${#segments[@]})) || exit 0
      exec uvx --quiet --from ${lib.escapeShellArg reader} python -I ${./menu-record.py} "''${segments[@]}"
    '';
  };
  menuRecordCopy = pkgs.writeShellApplication {
    name = "menu-record-copy";
    runtimeInputs = [pkgs.coreutils pkgs.findutils];
    text = ''
      mkdir -p ${lib.escapeShellArg store}
      cp -p ${lib.escapeShellArg stream}/* ${lib.escapeShellArg store}/
      find ${lib.escapeShellArg store} -type f -mtime +${toString retentionDays} -delete
    '';
  };
in {
  home.packages = [menuRecord];

  # --- [DAILY_COPY]
  launchd.agents.menu-record = launchdAgent {
    name = "menu-record";
    argv = [(lib.getExe menuRecordCopy)];
    readsProtectedFiles = true;
    StartCalendarInterval = [
      {
        Hour = 13;
        Minute = 10;
      }
    ];
  };
}
