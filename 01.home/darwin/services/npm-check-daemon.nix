# Title         : npm-check-daemon.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/darwin/services/npm-check-daemon.nix
# ----------------------------------------------------------------------------
# Daily npm dependency update checker - runs at 3 PM

{ pkgs, myLib, config, ... }:

{
  # --- NPM Update Check Service ---------------------------------------------
  launchd.agents.npm-check-updates = {
    enable = true;
    config = myLib.launchd.mkCalendarJob pkgs {
      # --- Script Execution ---------------------------------------------------
      script = ''
        # Find all package.json files in common project locations
        for dir in ~/Documents/*/package.json ~/Documents/*/*/package.json ~/Projects/*/package.json; do
          if [[ -f "$dir" ]]; then
            project_dir="$(dirname "$dir")"
            echo "Checking updates for: $project_dir"
            cd "$project_dir" && ${pkgs.nodePackages.npm-check-updates}/bin/ncu --color
            echo "---"
          fi
        done
      '';

      # --- Schedule Configuration ---------------------------------------------
      calendar = [
        {
          Hour = 15;   # 3:00 PM
          Minute = 0;
        }
      ];

      # --- Logging Configuration ----------------------------------------------
      logBaseName = "${config.xdg.stateHome}/logs/npm-check-updates";

      # --- Resource Management ------------------------------------------------
      nice = 19;                    # Lowest priority
      processType = "Background";   # Background process
    };
  };
}