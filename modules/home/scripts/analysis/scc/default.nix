# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/scripts/analysis/scc/default.nix
# ----------------------------------------------------------------------------
# scc code counter + forge-loc.sh wrapper for grouped per-file / per-folder LOC
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
      # Single-pass LOC report: files grouped by top-level folder, folder totals,
      # and one overall target total. Single positional target, no flags.

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

      # jq owns $root inside this single-quoted filter.
      # shellcheck disable=SC2016
      readonly report_filter='
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
        def sum_by(f): map(f) | add // 0;
        def folder_name:
          if . == "(root)" or (contains("/") | not) then
            "Root"
          else
            split("/")[0]
          end;
        def file_name:
          if . == "(root)" or (contains("/") | not) then
            .
          else
            split("/")[1:] | join("/")
          end;
        def language_summary:
          map(select(.Code > 0) | "\(.Name) \(.Code)")
          | if length == 0 then "none" else join("; ") end;
        def folder_groups:
          files
          | map({
              folder: (.RelPath | folder_name),
              file: (.RelPath | file_name),
              code: .Code,
              complexity: .Complexity
            })
          | group_by(.folder)
          | map({
              folder: .[0].folder,
              files: length,
              code: sum_by(.code),
              complexity: sum_by(.complexity),
              rows: (sort_by(.code) | reverse)
            })
          | sort_by(.code) | reverse;
        def summary:
          "LOC " + ($root | split("/") | last),
          "Target: " + $root,
          "Languages: " + language_summary,
          "";
        def table:
          ["FOLDER / FILE","FILES","CODE","CPX"],
          (
            folder_groups[] as $group
            | [$group.folder, "", "", ""],
              ($group.rows[] | ["  " + .file, "", .code, .complexity]),
              ["  " + $group.folder + " total", $group.files, $group.code, $group.complexity],
              ["", "", "", ""]
          ),
          ["TOTAL", (files | length), (files | sum_by(.Code)), (files | sum_by(.Complexity))];
      '

      ${pkgs.jq}/bin/jq -r --arg root "$target_path" "$report_filter summary" <<<"$json"
      ${pkgs.jq}/bin/jq -r --arg root "$target_path" "$report_filter table | map(tostring) | @tsv" <<<"$json" |
        ${pkgs.util-linux}/bin/column -t -s "$tab"
    '';
  };
}
