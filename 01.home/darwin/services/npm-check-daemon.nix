# Title         : npm-check-daemon.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/darwin/services/npm-check-daemon.nix
# ----------------------------------------------------------------------------
# Daily npm dependency update checker - runs at 3 PM

{
  pkgs,
  myLib,
  config,
  ...
}:

{
  # --- NPM Update Check Service ---------------------------------------------
  launchd.agents.npm-check-updates = {
    enable = true;
    config = myLib.launchd.mkCalendarJob pkgs {
      label = "NPM Daemon";
      command = "${
        pkgs.writeShellApplication {
          name = "npm-daemon";
          runtimeInputs = [ pkgs.nodePackages.npm-check-updates ];
          text = ''
            OUTDATED_COUNT=0
            PROJECTS_CHECKED=0

            for dir in ~/Documents/*/package.json ~/Documents/*/*/package.json ~/Projects/*/package.json; do
              if [[ -f "$dir" ]]; then
                project_dir="$(dirname "$dir")"
                echo "Checking updates for: $project_dir"

                # Check for updates
                if cd "$project_dir" && ncu --color > /tmp/ncu-output 2>&1; then
                  cat /tmp/ncu-output
                  if grep -q "Run ncu -u to upgrade" /tmp/ncu-output; then
                    OUTDATED_COUNT=$((OUTDATED_COUNT + 1))
                  fi
                  rm -f /tmp/ncu-output
                fi
                PROJECTS_CHECKED=$((PROJECTS_CHECKED + 1))
                echo "---"
              fi
            done

            # Send notification
            if [ $PROJECTS_CHECKED -gt 0 ]; then
              if [ $OUTDATED_COUNT -gt 0 ]; then
                echo "NPM Updates Available: $OUTDATED_COUNT of $PROJECTS_CHECKED projects need updates"
              else
                echo "NPM Check Complete: All $PROJECTS_CHECKED projects are up to date"
              fi
            fi
          '';
        }
      }/bin/npm-daemon";

      calendar = [
        {
          Hour = 15;
          Minute = 0;
        }
      ];

      logBaseName = "${config.xdg.stateHome}/logs/npm-check-updates";

      nice = 19;
      processType = "Background";
    };
  };
}
