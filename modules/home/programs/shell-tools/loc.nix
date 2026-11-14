{pkgs, ...}: let
  reportDefs = ''
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
  '';
  report = name: query: pkgs.writeText "loc-${name}.jq" (reportDefs + query);
  loc = pkgs.writeShellApplication {
    name = "loc";
    runtimeInputs = [pkgs.coreutils pkgs.jq pkgs.scc pkgs.util-linux];
    text = ''
      shopt -s inherit_errexit

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

      scc_flags=(--by-file --format json --no-cocomo --no-size --sort code)
      ((dirs_only)) && scc_flags+=(--no-min-gen --no-large)

      json="$(scc "''${resolved[@]}" "''${scc_flags[@]}" </dev/null)"
      readonly json

      if ((json_mode)); then
        printf '%s\n' "$json" | jq -c --arg root "$root" --argjson targets "$targets_json" -f ${report "json" ''
        {
          target: $root,
          targets: $targets,
          languages: languages,
          total: {files: (files | length), code: (files | sum_by(.Code)), complexity: (files | sum_by(.Complexity))},
          folders: folder_groups
        }
      ''}
        exit 0
      fi

      printf '%s\n' "$json" | jq -r --arg root "$root" --argjson targets "$targets_json" -f ${report "summary" "summary"}
      printf '%s\n' "$json" | jq -r --arg root "$root" --argjson targets "$targets_json" -f ${report "table" "table | map(tostring) | @tsv"} |
        column -t -s "$tab"
    '';
  };
in {
  home.packages = [pkgs.scc loc];
}
