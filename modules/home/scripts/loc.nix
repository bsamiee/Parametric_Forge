# Title         : loc.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/scripts/loc.nix
# ----------------------------------------------------------------------------
# scc code counter + loc wrapper: grouped per-file / per-folder LOC and complexity. --json emits the machine envelope.
{pkgs, ...}: let
  loc = pkgs.writeShellApplication {
    name = "loc";
    runtimeInputs = [pkgs.coreutils pkgs.jq pkgs.scc pkgs.util-linux];
    text = ''
      shopt -s inherit_errexit

      # Payloads ride pipelines, never <<<.
      # Pure printer: help requests route it to stdout with exit 0, usage errors to stderr with exit 2.
      _usage() { printf 'usage: %s [--json] [target...]\n' "''${0##*/}"; }

      json_mode=0
      targets=()
      while (($#)); do
        case "$1" in
          --json) json_mode=1 ;;
          --help | -h) _usage; exit 0 ;;
          --) shift; targets+=("$@"); break ;;
          --*) _usage >&2; exit 2 ;;
          *) targets+=("$1") ;;
        esac
        shift
      done
      ((''${#targets[@]})) || targets=(.)

      # Polymorphic target admission: every entry realpaths to an existing path or the run dies loudly on the envelope rail; a directory-only run
      # unlocks the corpus filters below.
      resolved=()
      dirs_only=1
      for t in "''${targets[@]}"; do
        p="$(realpath -e -- "$t" 2>/dev/null)" || {
          ((json_mode)) && jq -nc --arg t "$t" '{error: {surface: "loc", kind: "target", target: $t}}'
          printf 'loc: no such target: %s\n' "$t" >&2
          exit 2
        }
        duplicate=0
        for seen in "''${resolved[@]}"; do
          [[ "$p" == "$seen" ]] && { duplicate=1; break; }
        done
        ((duplicate)) && continue
        resolved+=("$p")
        [[ -d "$p" ]] || dirs_only=0
      done
      # Relpath root: a sole dir is its own root, a sole file anchors at its parent, several targets anchor at the deepest common ancestor. The
      # quoted-slash trim pattern is deliberate: a bare slash-star byte pair reads as a Nix block comment to scc and poisons this file's own count.
      root="''${resolved[0]}"
      [[ -d "$root" ]] || root="''${root%"/"*}"
      for p in "''${resolved[@]}"; do
        while [[ "$p" != "$root" && "$p" != "$root/"* ]]; do
          root="''${root%"/"*}"
        done
      done
      [[ -n "$root" ]] || root="/"
      readonly root dirs_only json_mode
      readonly tab=$'\t'
      targets_json="$(jq -nc '$ARGS.positional' --args -- "''${resolved[@]}")"
      readonly targets_json

      # Corpus filters ride directory scans only: minified/generated detection and the large-file guard would silently vanish an explicitly named
      # file from its own report, so explicit file targets always count verbatim.
      scc_flags=(--by-file --format json --no-cocomo --no-size --sort code)
      ((dirs_only)) && scc_flags+=(--no-min-gen --no-large)

      # Detached stdin: a dead invoking session never strands this command substitution as an orphaned subshell.
      json="$(scc "''${resolved[@]}" "''${scc_flags[@]}" </dev/null)"
      readonly json

      # jq owns $root/$targets inside this single-quoted filter.
      # shellcheck disable=SC2016
      readonly report_filter='
        def relpath:
          . as $location
          | if $location == $root then
              "(root)"
            elif $root == "/" and startswith("/") then
              ltrimstr("/")
            elif ($location | startswith($root + "/")) then
              $location | ltrimstr($root + "/")
            else
              $location
            end;
        def files:
          [.[] | .Files[]? | . + {RelPath: (.Location | relpath)}]
          | unique_by([.Location, .Language]);
        def sum_by(f): map(f) | add // 0;
        def folder_name:
          if . == "(root)" or startswith("/") or (contains("/") | not) then
            "Root"
          else
            split("/")[0]
          end;
        def file_name:
          if . == "(root)" or startswith("/") or (contains("/") | not) then
            .
          else
            split("/")[1:] | join("/")
          end;
        def languages:
          files
          | group_by(.Language)
          | map({name: .[0].Language, code: sum_by(.Code)})
          | map(select(.code > 0))
          | sort_by(-.code, .name);
        def language_summary:
          languages | map("\(.name) \(.code)")
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
          "LOC " + (if $root == "/" then "/" else ($root | split("/") | last) end),
          (if ($targets | length) > 1 then "Targets: " + ($targets | join(" ")) else "Target: " + $targets[0] end),
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

      if ((json_mode)); then
        # Machine envelope: same folder grouping the table renders, plus per-language and overall totals for agent consumption.
        printf '%s\n' "$json" | jq -c --arg root "$root" --argjson targets "$targets_json" "$report_filter"'
          {
            target: $root,
            targets: $targets,
            languages: languages,
            total: {files: (files | length), code: (files | sum_by(.Code)), complexity: (files | sum_by(.Complexity))},
            folders: folder_groups
          }'
        exit 0
      fi

      printf '%s\n' "$json" | jq -r --arg root "$root" --argjson targets "$targets_json" "$report_filter summary"
      printf '%s\n' "$json" | jq -r --arg root "$root" --argjson targets "$targets_json" "$report_filter table | map(tostring) | @tsv" |
        column -t -s "$tab"
    '';
  };
in {
  home.packages = [pkgs.scc loc];
}
