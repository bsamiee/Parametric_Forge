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
        for dir in ~/Documents/*/package.json ~/Documents/*/*/package.json ~/Projects/*/package.json; do
          if [[ -f "$dir" ]]; then
            project_dir="$(dirname "$dir")"
            echo "Checking updates for: $project_dir"
            cd "$project_dir" && ${pkgs.nodePackages.npm-check-updates}/bin/ncu --color
            echo "---"
          fi
        done
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
