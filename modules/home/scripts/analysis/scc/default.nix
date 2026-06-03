# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/scripts/analysis/scc/default.nix
# ----------------------------------------------------------------------------
# scc code counter + forge-loc.sh wrapper for per-language / per-folder / per-file LOC
{pkgs, ...}: {
  home.packages = [pkgs.scc];

  home.file.".local/bin/forge-loc.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # Title         : forge-loc.sh
      # Author        : Bardia Samiee
      # Project       : Parametric Forge
      # License       : MIT
      # Path          : modules/home/scripts/analysis/scc/forge-loc.sh
      # ----------------------------------------------------------------------------
      # Single-pass LOC report: per-language totals, per-folder rollup (one level
      # under target), and top-100 files by code lines. Hard 100-file cap, no flags.

      set -euo pipefail

      readonly target="''${1:-.}"

      readonly json="$(
        ${pkgs.scc}/bin/scc "$target" \
          --by-file --format json \
          --no-cocomo --no-complexity --no-size \
          --exclude-dir bin,obj,node_modules,.cursor,construction,.artifacts,dist,build,target,vendor \
          --sort code
      )"

      printf '\n==== TOTALS BY LANGUAGE ====\n'
      printf '%s\n' "$json" | ${pkgs.jq}/bin/jq -r '
        ["LANGUAGE","FILES","CODE","COMMENT","BLANK","COMPLEXITY"],
        (.[] | [.Name, (.Count|tostring), (.Code|tostring), (.Comment|tostring), (.Blank|tostring), (.Complexity|tostring)])
        | @tsv
      ' | ${pkgs.util-linux}/bin/column -t -s "$(printf '\t')"

      printf '\n==== PER-FOLDER (one level under target) ====\n'
      printf '%s\n' "$json" | ${pkgs.jq}/bin/jq -r --arg t "$target" '
        [.[] | .Files[]? | {
          folder: (
            .Location
            | ltrimstr($t)
            | ltrimstr("/")
            | split("/")
            | .[0:-1]
            | (.[0] // "(root)")
          ),
          code: .Code
        }]
        | group_by(.folder)
        | map({folder: .[0].folder, files: length, code: (map(.code) | add)})
        | sort_by(.code) | reverse
        | ["FOLDER","FILES","CODE"], (.[] | [.folder, (.files|tostring), (.code|tostring)])
        | @tsv
      ' | ${pkgs.util-linux}/bin/column -t -s "$(printf '\t')"

      printf '\n==== TOP 100 FILES BY CODE ====\n'
      printf '%s\n' "$json" | ${pkgs.jq}/bin/jq -r '
        [.[] | .Files[]? | {path: .Location, code: .Code, complexity: .Complexity}]
        | sort_by(.code) | reverse | .[0:100]
        | ["CODE","CPX","PATH"], (.[] | [(.code|tostring), (.complexity|tostring), .path])
        | @tsv
      ' | ${pkgs.util-linux}/bin/column -t -s "$(printf '\t')"
    '';
  };
}
