# Title         : loc.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/scripts/loc.nix
# ----------------------------------------------------------------------------
# scc code counter + loc wrapper: grouped per-file / per-folder LOC and complexity. --json emits the machine envelope.
{
  lib,
  pkgs,
  ...
}: let
  style = import ../../style.nix;
  # One transient vocabulary: style.nix scratch dirs unioned with build-output dirs. gitignore covers checkouts; these excludes cover non-git trees.
  excludeDirs = builtins.concatStringsSep "," (lib.unique (style.transientDirs ++ [".git" ".hg" ".svn" "bin" "obj" ".cursor" ".artifacts" "dist" "build" "target" "vendor"]));
  loc = pkgs.writeShellApplication {
    name = "loc";
    runtimeInputs = [pkgs.coreutils pkgs.jq pkgs.scc pkgs.util-linux];
    text = ''
      shopt -s inherit_errexit

      # Whole-body deadline: the entire run re-execs under timeout, so NO internal stage — scan, jq report, or pipe setup — can wedge a caller
      # past the budget. Decimal normalization precedes arithmetic because Bash reads a leading zero as octal; malformed or oversized values use
      # the safe outer fallback, then the invoked body rejects them unless help already terminated the CLI. Payloads ride pipelines, never <<<.
      _deadline_value() {
        local -r raw="$1"
        local -n _result="$2"
        [[ "$raw" =~ ^0*([0-9]{1,5})$ ]] || return 1
        local -r value=$((10#''${BASH_REMATCH[1]}))
        ((value <= 86400)) || return 1
        _result="$value"
      }
      if [[ -z "''${_LOC_DEADLINE_ACTIVE:-}" ]]; then
        _outer="''${LOC_SCAN_DEADLINE_SECONDS:-120}"
        _outer_seconds=120
        _deadline_value "$_outer" _outer_seconds || true
        _LOC_DEADLINE_ACTIVE=1 exec timeout -k 10 "$((_outer_seconds + 30))" "$0" "$@"
      fi

      # Pure printer: help requests route it to stdout with exit 0, usage errors to stderr with exit 2.
      _usage() { printf 'usage: %s [--json] [--self-test] [target...]\n' "''${0##*/}"; }

      # Self-test rides the full scan -> envelope rail: the fixture overlaps a directory with a repeated file target and uses a leading-zero
      # deadline, while the second scan forces / as the common root. Unique totals, language derivation, target truth, and grouping prove the jq arm.
      _self_test() {
        local st out root_out cleanup
        st="$(mktemp -d)"
        printf -v cleanup 'rm -rf -- %q' "$st"
        # shellcheck disable=SC2064  # Capture the shell-quoted path while the function-local value remains in scope.
        trap "$cleanup" EXIT
        printf 'x = 1\n' >"$st/a.py"
        mkdir "$st/sub"
        printf '{a = 1;}\n' >"$st/sub/b.nix"
        out="$(env -u _LOC_DEADLINE_ACTIVE LOC_SCAN_DEADLINE_SECONDS=08 "$0" --json "$st" "$st/a.py" "$st/a.py")" || {
          printf 'self-test: fixture scan failed\n' >&2
          return 1
        }
        printf '%s\n' "$out" | jq -e '.total.files == 2 and .total.code == 2
          and (.targets | length == 2)
          and ([.folders[].folder] | sort == ["Root", "sub"])
          and ([.languages[].name] | sort == ["Nix", "Python"])' >/dev/null || {
          printf 'self-test: envelope mismatch: %s\n' "$out" >&2
          return 1
        }
        root_out="$("$0" --json "$st/a.py" "$0")" || {
          printf 'self-test: root scan failed\n' >&2
          return 1
        }
        printf '%s\n' "$root_out" | jq -e '.target == "/" and .total.files == 2
          and (.folders | length == 2) and all(.folders[]; .folder != "Root")' >/dev/null || {
          printf 'self-test: root envelope mismatch: %s\n' "$root_out" >&2
          return 1
        }
        rm -rf -- "$st"
        trap - EXIT
        printf 'self-test: scan envelope ok (deduplicated targets, decimal deadline, root grouping)\n'
      }

      json_mode=0
      targets=()
      while (($#)); do
        case "$1" in
          --json) json_mode=1 ;;
          --self-test) _self_test; exit ;;
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
      readonly deadline="''${LOC_SCAN_DEADLINE_SECONDS:-120}"
      deadline_seconds=0
      _deadline_value "$deadline" deadline_seconds || {
        printf 'loc: LOC_SCAN_DEADLINE_SECONDS must be 0..86400 decimal seconds\n' >&2
        exit 2
      }
      readonly deadline_seconds
      readonly tab=$'\t'
      readonly exclude_dirs="${excludeDirs}"
      targets_json="$(jq -nc '$ARGS.positional' --args -- "''${resolved[@]}")"
      readonly targets_json

      # Corpus filters ride directory scans only: minified/generated detection and the large-file guard would silently vanish an explicitly named
      # file from its own report, so explicit file targets always count verbatim.
      scc_flags=(--by-file --format json --no-cocomo --no-size --exclude-dir "$exclude_dirs" --sort code)
      ((dirs_only)) && scc_flags+=(--no-min-gen --no-large)

      # Detached stdin + deadline: a dead invoking session must never strand this command substitution as an orphaned subshell. TERM first, KILL
      # after a 10s grace — a scan wedged on a dead mount ignores TERM.
      json="$(timeout -k 10 "$deadline_seconds" scc "''${resolved[@]}" "''${scc_flags[@]}" </dev/null)" || {
        rc=$?
        # Failure keeps the envelope rail: machine consumers get one typed error shape, never empty stdout beside a human stderr line.
        if ((json_mode)); then
          jq -nc --argjson rc "$rc" --argjson deadline "$deadline_seconds" \
            '{error: {surface: "loc", kind: "scan", rc: $rc, deadline: $deadline}}'
        fi
        printf 'loc: scc scan failed (rc=%s, deadline=%ss)\n' "$rc" "$deadline_seconds" >&2
        exit "$rc"
      }
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
