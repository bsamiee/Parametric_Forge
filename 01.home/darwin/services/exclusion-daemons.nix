# Title         : 01.home/darwin/services/exclusion-daemons.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/darwin/services/exclusion-daemons.nix
# ----------------------------------------------------------------------------
# Development directory exclusion monitor for Spotlight and Time Machine.

{
  config,
  lib,
  userServiceHelpers,
  exclusions,
  exclusionHelpers,
  exclusionFilters,
  ...
}:

let
  # --- Service Helper Functions ---------------------------------------------
  inherit (userServiceHelpers) mkPeriodicJob;
  # --- Exclusion Pattern Helpers --------------------------------------------
  inherit (exclusionFilters) byType byLocation;
  devPatterns = byType "dev" exclusions;
  heavyPatterns = byType "heavy" exclusions;
  indexPatterns = byType "index" exclusions;
  cacheInXdg = byLocation "xdg-cache" exclusions;
  patternsToExclude = lib.unique (map (e: e.pattern) (devPatterns ++ heavyPatterns ++ indexPatterns));
  projectDirs = map (dir: "${config.home.homeDirectory}/${dir}") exclusionHelpers.projectRoots;
in
{
  # --- Development Directory Exclusion Monitor ------------------------------
  launchd.agents."org.nixos.dev-exclusions" = {
    enable = true;
    config = mkPeriodicJob {
    interval = 21600; # 6 hours
    script = ''
      echo "[Dev Exclusions] Starting scan at $(date)"

      # --- Exclusion Function -------------------------------------------
      exclude_dir() {
        local dir="$1"

        if [ ! -f "$dir/.metadata_never_index" ]; then
          touch "$dir/.metadata_never_index" 2>/dev/null && \
            echo "  ✓ Spotlight excluded: $dir" || true
        fi

        if command -v tmutil >/dev/null 2>&1;
        then
          tmutil isexcluded "$dir" >/dev/null 2>&1 || {
            tmutil addexclusion "$dir" 2>/dev/null && \
              echo "  ✓ Time Machine excluded: $dir" || true
          }
        fi
      }

      # --- XDG Cache Exclusions -----------------------------------------
      echo "Checking XDG cache directories..."
      ${lib.concatMapStrings (e: ''
        if [ -d "${config.xdg.cacheHome}/${e.pattern}" ]; then
          exclude_dir "${config.xdg.cacheHome}/${e.pattern}"
        fi
      '') cacheInXdg}

      exclude_dir "${config.xdg.cacheHome}"
      exclude_dir "${config.xdg.stateHome}/logs"
      exclude_dir "${config.xdg.dataHome}/Trash"

      # --- Project Directory Scanning -----------------------------------
      for project_dir in ${lib.concatStringsSep " " projectDirs}; do
        if [ -d "$project_dir" ]; then
          echo "Scanning $project_dir..."

          find "$project_dir" -maxdepth 5 \(
            ${lib.concatMapStringsSep " -o " (p: "-name \"${p}\"") patternsToExclude}
          \) -type d -prune 2>/dev/null | while read -r dir;
          do
            exclude_dir "$dir"
          done
        fi
      done

      echo "[Dev Exclusions] Scan completed at $(date)"
    '';
    logBaseName = "${config.xdg.stateHome}/logs/dev-exclusions";
    nice = 19;
    runAtLoad = true;
    };
  };
}
