# Title         : loc.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/scripts/loc.nix
# ----------------------------------------------------------------------------
# scc code counter + loc wrapper for grouped per-file / per-folder LOC

{pkgs, ...}: let
  # Single-pass LOC report: files grouped by top-level folder, folder totals, and one overall target total. --json emits the machine envelope.
  loc = pkgs.writeShellApplication {
    name = "loc";
    runtimeInputs = [pkgs.coreutils pkgs.jq pkgs.scc pkgs.util-linux];
    text = ''
      shopt -s inherit_errexit

      json_mode=0
      if [[ "''${1:-}" == "--json" ]]; then
        json_mode=1
        shift
      fi
      if (($# > 1)); then
        printf 'usage: %s [--json] [target]\n' "''${0##*/}" >&2
        exit 2
      fi

      readonly target_input="''${1:-.}"
      target_path="$(realpath -- "$target_input" 2>/dev/null)" || {
        printf 'loc: no such target: %s\n' "$target_input" >&2
        exit 2
      }
      readonly target_path
      readonly deadline="''${LOC_SCAN_DEADLINE_SECONDS:-120}"
      [[ "$deadline" =~ ^[0-9]+$ ]] || {
        printf 'loc: LOC_SCAN_DEADLINE_SECONDS must be a whole number of seconds\n' >&2
        exit 2
      }
      readonly tab=$'\t'
      readonly exclude_dirs=".git,.hg,.svn,bin,obj,node_modules,.cursor,.artifacts,dist,build,target,vendor"

      # Detached stdin + deadline: a dead invoking session must never strand this command substitution as an orphaned subshell. TERM first, KILL
      # after a 10s grace — a scan wedged on a dead mount ignores TERM.
      json="$(
        timeout -k 10 "$deadline" \
          scc "$target_path" \
          --by-file --format json \
          --no-cocomo --no-size \
          --exclude-dir "$exclude_dirs" \
          --sort code </dev/null
      )" || {
        rc=$?
        # Failure keeps the envelope rail: machine consumers get one typed error shape, never empty stdout beside a human stderr line.
        if [[ "$json_mode" == 1 ]]; then
          jq -nc --argjson rc "$rc" --argjson deadline "$deadline" \
            '{error: {surface: "loc", kind: "scan", rc: $rc, deadline: $deadline}}'
        fi
        printf 'loc: scc scan failed (rc=%s, deadline=%ss)\n' "$rc" "$deadline" >&2
        exit "$rc"
      }
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

      if [[ "$json_mode" == 1 ]]; then
        # Machine envelope: same folder grouping the table renders, plus per-language and overall totals for agent consumption.
        jq -c --arg root "$target_path" "$report_filter"'
          {
            target: $root,
            languages: (map(select(.Code > 0) | {name: .Name, code: .Code}) | sort_by(-.code)),
            total: {files: (files | length), code: (files | sum_by(.Code)), complexity: (files | sum_by(.Complexity))},
            folders: folder_groups
          }' <<<"$json"
        exit 0
      fi

      jq -r --arg root "$target_path" "$report_filter summary" <<<"$json"
      jq -r --arg root "$target_path" "$report_filter table | map(tostring) | @tsv" <<<"$json" |
        column -t -s "$tab"
    '';
  };
in {
  home.packages = [pkgs.scc loc];
}
