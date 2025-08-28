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
      script = ''
        OUTDATED_COUNT=0
        PROJECTS_CHECKED=0

        for dir in ~/Documents/*/package.json ~/Documents/*/*/package.json ~/Projects/*/package.json; do
          if [[ -f "$dir" ]]; then
            project_dir="$(dirname "$dir")"
            echo "Checking updates for: $project_dir"
            
            # Check for updates
            if cd "$project_dir" && ${pkgs.nodePackages.npm-check-updates}/bin/ncu --color | tee /dev/tty | grep -q "Run ncu -u to upgrade"; then
              OUTDATED_COUNT=$((OUTDATED_COUNT + 1))
            fi
            PROJECTS_CHECKED=$((PROJECTS_CHECKED + 1))
            echo "---"
          fi
        done

        # Send notification
        if [ $PROJECTS_CHECKED -gt 0 ]; then
          if [ $OUTDATED_COUNT -gt 0 ]; then
            alerter -title "NPM Updates Available" -subtitle "$OUTDATED_COUNT of $PROJECTS_CHECKED projects" -message "Run 'ncu -u' to update packages" -appIcon "/System/Applications/Utilities/Terminal.app/Contents/Resources/Terminal.icns" -sound Hero
          else
            alerter -title "NPM Check Complete" -message "All $PROJECTS_CHECKED projects are up to date" -appIcon "/System/Applications/Utilities/Terminal.app/Contents/Resources/Terminal.icns" -sound Glass
          fi
        fi
      '';

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
