{
  config,
  launchdAgent,
  lib,
  pkgs,
  ...
}: let
  copies.thesis-working = {
    root = "${config.home.homeDirectory}/Library/CloudStorage/OneDrive-Personal/05.School/Fall 2026/Masters Preperation";
    folders = ["Thesis assignment" "Thesis video"];
    remote = "b2:parametric-arsenal-thesis-working";
    hour = 13;
  };
  historyDays = 30;
  secondCopy = name: row:
    pkgs.writeShellApplication {
      name = "second-copy-${name}";
      runtimeInputs = [pkgs.coreutils pkgs.rclone];
      text = ''
        if [[ -z "''${RCLONE_CONFIG_B2_KEY:-}" && -f ${lib.escapeShellArg config.forge.secrets.sessionCache} ]]; then
          # shellcheck source=/dev/null
          . ${lib.escapeShellArg config.forge.secrets.sessionCache}
        fi
        day="$(date +%F)"
        status=0
        for folder in ${lib.escapeShellArgs row.folders}; do
          rclone sync ${lib.escapeShellArg row.root}/"$folder" ${lib.escapeShellArg row.remote}/current/"$folder" \
            --backup-dir ${lib.escapeShellArg row.remote}/history/"$day"/"$folder" \
            --b2-hard-delete --exclude .DS_Store --exclude '*.idlk' --fast-list --transfers 8 -v || status=$?
        done
        rclone delete ${lib.escapeShellArg row.remote}/history --b2-hard-delete --min-age ${toString historyDays}d --rmdirs -v || status=$?
        exit "$status"
      '';
    };
in {
  home.packages = [pkgs.rclone] ++ lib.mapAttrsToList secondCopy copies;

  # --- [SECOND_COPIES]
  launchd.agents = lib.mapAttrs' (name: row:
    lib.nameValuePair "second-copy-${name}" (launchdAgent {
      name = "second-copy-${name}";
      argv = [(lib.getExe (secondCopy name row))];
      readsProtectedFiles = true;
      StartCalendarInterval = [
        {
          Hour = row.hour;
          Minute = 5;
        }
      ];
    }))
  copies;
}
