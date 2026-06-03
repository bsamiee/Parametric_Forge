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

      set -Eeuo pipefail
      shopt -s inherit_errexit

      if (($# > 1)); then
        printf 'usage: %s [target]\n' "$0" >&2
        exit 2
      fi

      readonly target_input="''${1:-.}"
      target_path="$(${pkgs.coreutils}/bin/realpath "$target_input")"
      readonly target_path
      readonly tab=$'\t'
      readonly exclude_dirs=".git,.hg,.svn,bin,obj,node_modules,.cursor,.artifacts,dist,build,target,vendor"

      json="$(
        ${pkgs.scc}/bin/scc "$target_path" \
          --by-file --format json \
          --no-cocomo --no-size \
          --exclude-dir "$exclude_dirs" \
          --sort code
      )"
      readonly json

      # jq owns $root inside this single-quoted filter prelude.
      # shellcheck disable=SC2016
      readonly jq_prelude='
        def relpath:
          . as $location
          | if $location == $root then
              "(root)"
            elif ($location | startswith($root + "/")) then
              $location | ltrimstr($root + "/")
            else
              $location
            end;
        def files:
          [.[] | .Files[]? | . + {RelPath: (.Location | relpath)}];
      '

      readonly totals_filter='
        (
          ["LANGUAGE","FILES","CODE","COMMENT","BLANK","COMPLEXITY"],
          (.[] | [.Name, .Count, .Code, .Comment, .Blank, .Complexity] | map(tostring))
        )
        | @tsv
      '

      readonly folder_filter='
        def folder:
          if . == "(root)" or (contains("/") | not) then
            "(root)"
          else
            split("/")[0]
          end;
        (
          ["FOLDER","FILES","CODE"],
          (
            (files | map({folder: (.RelPath | folder), code: .Code}))
            | group_by(.folder)
            | map({folder: .[0].folder, files: length, code: (map(.code) | add)})
            | sort_by(.code) | reverse
            | .[] | [.folder, .files, .code] | map(tostring)
          )
        )
        | @tsv
      '

      readonly top_files_filter='
        (
          ["CODE","CPX","PATH"],
          (
            (files | map({path: .RelPath, code: .Code, complexity: .Complexity}))
            | sort_by(.code) | reverse | .[0:100]
            | .[] | [.code, .complexity, .path] | map(tostring)
          )
        )
        | @tsv
      '

      render_section() {
        local -r title="$1"
        local -r filter="$2"

        printf '\n---- %s ----\n' "$title"
        ${pkgs.jq}/bin/jq -r --arg root "$target_path" "$jq_prelude $filter" <<<"$json" |
          ${pkgs.util-linux}/bin/column -t -s "$tab"
      }

      render_section "TOTALS BY LANGUAGE" "$totals_filter"
      render_section "PER-FOLDER (one level under target)" "$folder_filter"
      render_section "TOP 100 FILES BY CODE" "$top_files_filter"
    '';
  };
}
