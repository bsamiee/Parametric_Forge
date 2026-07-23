# Title         : fmt.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/scripts/fmt.nix
# ----------------------------------------------------------------------------
# fmt: polymorphic formatter front door — one command routes every file type to its owning formatter. Formatters resolve from PATH so the Home
# Manager fallback wrappers keep their never-shadow project-config semantics; those wrappers probe $PWD, so run
# fmt from inside the project the targets live in.
{pkgs, ...}: let
  style = import ../../style.nix;
  fdExcludes = builtins.concatStringsSep " " (map (d: "--exclude " + d) style.transientDirs);
  fmt = pkgs.writeShellApplication {
    name = "fmt";
    runtimeInputs = [pkgs.coreutils pkgs.fd pkgs.gawk pkgs.jq];
    text = ''
      shopt -s inherit_errexit

      # --- [LANE_VOCABULARY]
      # One row per lane — 'tool|write argv|check argv'; subscripts quoted (shfmt parses bare hyphenated subscripts as arithmetic).
      declare -Ar _LANE=(
        ["nix"]='alejandra|alejandra -q --|alejandra -c --'
        ["shell"]='shfmt|shfmt -w|shfmt -d'
        ["python"]='ruff|ruff format --|ruff format --check --'
        ["web"]='biome|biome format --write|biome format'
        ["prose"]='prettier|prettier --log-level warn --write|prettier --log-level warn --check'
        ["workflow"]='prettier|prettier --log-level warn --write|prettier --log-level warn --check'
        ["yaml"]='yamlfmt|yamlfmt|yamlfmt -lint'
        ["lua"]='stylua|stylua --|stylua --check --'
        ["sql"]='sqruff|sqruff fix|sqruff lint'
        ["sql-duckdb"]='sqruff|sqruff fix|sqruff lint'
        ["swift"]='swiftformat|swiftformat --quiet|swiftformat --quiet --lint'
        ["osa"]='forge-osa|forge-osa fmt|forge-osa check'
        ["jq"]='jq|_gate_jq|_gate_jq'
      )
      declare -Ar _MODE_FIELD=(["write"]=1 ["check"]=2)
      _lane_row() { # $1 = lane, $2 = out array name -> (tool, write argv, check argv)
        local -n _row="$2"
        IFS='|' read -r -a _row <<<"''${_LANE[$1]}"
      }
      declare -Ar _EXT_LANE=(
        ["nix"]=nix
        ["sh"]=shell ["bash"]=shell
        ["py"]=python ["pyi"]=python
        ["ts"]=web ["tsx"]=web ["js"]=web ["jsx"]=web ["mjs"]=web ["cjs"]=web ["mts"]=web ["cts"]=web
        ["json"]=web ["jsonc"]=web ["css"]=web
        ["html"]=prose
        ["yml"]=yaml ["yaml"]=yaml
        ["lua"]=lua
        ["sql"]=sql
        ["swift"]=swift
        ["applescript"]=osa
        ["jq"]=jq
      )
      # Package-manager-owned basenames whose extension routes to a lane: the npm lockfile trio plus npm-shrinkwrap ride the web lane, and
      # pnpm rewrites its workspace/lock pair in its own layout — formatting any is corruption or churn. A .lock-extension lockfile needs no row:
      # .lock owns no lane, so it skips already. C# has no lane: csharpier hard-codes Allman braces against the estate K&R editorconfig law
      # — dotnet format owns .cs through the project rails.
      declare -Ar _DENY_BASE=(
        ["pnpm-lock.yaml"]=1 ["package-lock.json"]=1 ["packages.lock.json"]=1
        ["npm-shrinkwrap.json"]=1 ["pnpm-workspace.yaml"]=1
      )
      readonly _SHEBANG_SHELL='^#!.*[/[:space:]](env[[:space:]]+)?(ba|da|mk)?sh([[:space:]]|$)'
      readonly _SHEBANG_PYTHON='^#!.*[/[:space:]](env[[:space:]]+(-S[[:space:]]+)?)?python[0-9.]*([[:space:]]|$)'

      # jq has no safe formatter (jqfmt drops top-level defs); the compile gate is the whole static surface: empty stdin, body never runs, so the
      # gate cannot hang and needs no deadline. Programs written for `jq --arg` reference variables that are compile errors when unbound, so every
      # referenced $var is pre-defined before the compile.
      # shellcheck disable=SC2329  # invoked through the lane dispatch tables
      _gate_jq() {
        local -i bad=0
        local f prog
        for f in "$@"; do
          local -A vars=()
          local -a defs=()
          prog="$(<"$f")"
          while [[ "$prog" =~ \$([A-Za-z_][A-Za-z0-9_]*) ]]; do
            vars[''${BASH_REMATCH[1]}]=1
            prog="''${prog#*"''${BASH_REMATCH[0]}"}"
          done
          local v
          for v in "''${!vars[@]}"; do
            case "$v" in ENV | __loc__ | __prog__) continue ;; esac
            defs+=(--arg "$v" "")
          done
          jq "''${defs[@]}" -f "$f" </dev/null >/dev/null || bad=1
          unset -v vars
        done
        return "$bad"
      }

      # Pure printer: help requests route it to stdout with exit 0, usage errors to stderr with exit 2.
      _usage() { printf 'usage: %s [--check | --write] [--json] [--self-test] [target...]\n' "''${0##*/}"; }

      # Failure envelope: every user-facing error prints its human sentence to stderr; under --json it ALSO emits one {ok:false, error:{…}} object
      # on stdout, so a piped jq consumer meets a well-formed object at every exit instead of stray text. The guard returns 0 so a plain-mode call
      # never trips errexit; kind is the machine tag and .ok is the universal discriminant every fmt json object carries.
      _emit_error() { ((json_mode)) || return 0; jq -nc --arg kind "$1" --arg detail "$2" '{ok: false, error: {surface: "fmt", kind: $kind, detail: $detail}}'; }

      # Pure classification: deny rows first, then the extension row; unowned readable files fall through to a bounded shebang probe. A dotfile's
      # whole name is not an extension; a bare trailing dot owns nothing. SQL dialect is a filename fact (estate law): duckdb-* rides its own lane
      # so batches stay dialect-homogeneous for the sqruff wrapper; sqlite-* is unowned — sqruff's sqlite dialect rewrites virtual-table module
      # arguments (float[2] -> float [2]), which extensions parse verbatim.
      _lane_for() {
        local -r path="$1"
        local -n _out="$2"
        _out=""
        local -r base="''${path##*/}"
        [[ -n "''${_DENY_BASE[$base]:-}" ]] && return 0
        local ext="''${base##*.}"
        [[ "$ext" == "$base" || ".$ext" == "$base" ]] && ext=""
        [[ -n "$ext" ]] && _out="''${_EXT_LANE[''${ext,,}]:-}"
        if [[ "$_out" == sql ]]; then
          case "''${base,,}" in
            sqlite-*) _out="" ;;
            duckdb-*) _out=sql-duckdb ;;
          esac
        fi
        # Workflow-DSL scripts (top-level await/return) reroute to the prettier lane: biome's grammar rejects them, prettier's babel parser does not.
        # Quoted glob segments are deliberate: a bare slash-star byte pair reads as a Nix block comment to scc and poisons this file's own count.
        if [[ "$_out" == web ]]; then
          case "/$path" in
            *"/.claude/workflows/"*.js | *"/workflow-creator/assets/"*.js) _out=workflow ;;
          esac
        fi
        if [[ -z "$_out" && -f "$path" && -r "$path" ]]; then
          local first=""
          IFS= read -r -n 256 first <"$path" || true
          if [[ "$first" =~ $_SHEBANG_SHELL ]]; then
            _out=shell
          elif [[ "$first" =~ $_SHEBANG_PYTHON ]]; then
            _out=python
          fi
        fi
        return 0
      }

      _self_test() {
        local ext lane
        local -a lrow
        for ext in "''${!_EXT_LANE[@]}"; do
          lane="''${_EXT_LANE[$ext]}"
          [[ -n "''${_LANE[$lane]:-}" ]] || {
            printf 'self-test: ext %s -> unowned lane %s\n' "$ext" "$lane" >&2
            return 1
          }
        done
        # Every row carries three non-empty fields; the PATH probe reads the check field's head token for both modes, so the heads must agree.
        for lane in "''${!_LANE[@]}"; do
          _lane_row "$lane" lrow
          [[ ''${#lrow[@]} -eq 3 && -n "''${lrow[0]}" && -n "''${lrow[1]}" && -n "''${lrow[2]}" ]] || {
            printf 'self-test: lane %s row incomplete\n' "$lane" >&2
            return 1
          }
          [[ "''${lrow[1]%% *}" == "''${lrow[2]%% *}" ]] || {
            printf 'self-test: lane %s write/check head tokens diverge\n' "$lane" >&2
            return 1
          }
        done
        local st
        st="$(mktemp -d)"
        printf '#!/usr/bin/env bash\n' >"$st/hook"
        printf '#!/usr/bin/env -S python3 -u\n' >"$st/tool"
        printf '#!/usr/bin/env fish\n' >"$st/fish"
        printf 'ELFjunk' >"$st/blob"
        # shellcheck disable=SC2016  # $want/$ENV are jq variables, not shell
        printf '[.[] | .Labels[$want] // empty | select(. != $ENV.HOME)]\n' >"$st/argy.jq"
        printf 'def broken(\n' >"$st/bad.jq"
        local -A probes=(
          ["dir name/a b.PY"]=python ["-rf.py"]=python ["x.tar.gz"]=""
          [".yamlfmt"]="" ["note."]="" ["$st/hook"]=shell ["$st/tool"]=python
          ["$st/fish"]="" ["$st/blob"]="" ["pkg/pnpm-lock.yaml"]="" ["package-lock.json"]=""
          ["obj/packages.lock.json"]="" ["npm-shrinkwrap.json"]=""
          ["sql/apply-postgres.sql"]=sql ["sql/duckdb-probe.sql"]=sql-duckdb
          ["sql/SQLite-probe.sql"]="" ["sql/duck.sql"]=sql
          [".claude/workflows/estate.js"]=workflow
          ["repo/.claude/skills/workflow-creator/assets/templates/loop.template.js"]=workflow
          [".claude/skills/applescript/assets/examples/probe.js"]=web
        )
        local path got
        for path in "''${!probes[@]}"; do
          _lane_for "$path" got
          [[ "$got" == "''${probes[$path]}" ]] || {
            printf 'self-test: %s -> "%s", want "%s"\n' "$path" "$got" "''${probes[$path]}" >&2
            rm -rf "$st"
            return 1
          }
        done
        _gate_jq "$st/argy.jq" || {
          printf 'self-test: jq gate rejects a valid --arg program\n' >&2
          rm -rf "$st"
          return 1
        }
        ! _gate_jq "$st/bad.jq" 2>/dev/null || {
          printf 'self-test: jq gate accepts a broken program\n' >&2
          rm -rf "$st"
          return 1
        }
        rm -rf "$st"
        printf 'self-test: %d extensions, %d lanes, %d classification probes ok\n' \
          "''${#_EXT_LANE[@]}" "''${#_LANE[@]}" "''${#probes[@]}"
      }

      # --- [ARGUMENTS]
      # Write is the default mode; --write names it explicitly and --check selects the alternative — one collapsed arm owns both, since ''${1#--}
      # strips each flag to exactly the write|check vocabulary _MODE_FIELD keys on. A mode_flag sentinel rejects --check --write in either order.
      mode="write"
      mode_flag=""
      json_mode=0
      targets=()
      # Pre-scan --json so every failure envelope emits regardless of flag order; the main loop re-sets it harmlessly, and a --json past -- stays a target.
      for _arg in "$@"; do
        [[ "$_arg" == -- ]] && break
        [[ "$_arg" == --json ]] && json_mode=1
      done
      while (($#)); do
        case "$1" in
          --check | --write)
            new="''${1#--}"
            [[ -n "$mode_flag" && "$mode_flag" != "$new" ]] && {
              printf 'fmt: --check and --write are mutually exclusive\n' >&2
              _emit_error usage "--check and --write are mutually exclusive"
              exit 2
            }
            mode="$new"
            mode_flag="$new"
            ;;
          --json) json_mode=1 ;;
          --self-test) _self_test; exit ;;
          --help | -h) _usage; exit 0 ;;
          --) shift; targets+=("$@"); break ;;
          --*) _usage >&2; _emit_error usage "unknown flag: $1"; exit 2 ;;
          *) targets+=("$1") ;;
        esac
        shift
      done
      ((''${#targets[@]})) || { _usage >&2; _emit_error usage "no target given"; exit 2; }
      readonly mode json_mode targets
      readonly deadline="''${FMT_DEADLINE_SECONDS:-300}"
      [[ "$deadline" =~ ^[0-9]+$ ]] || {
        printf 'fmt: FMT_DEADLINE_SECONDS must be a whole number of seconds\n' >&2
        _emit_error deadline "FMT_DEADLINE_SECONDS must be a whole number of seconds"
        exit 2
      }
      # Missing formatter is inform-only by default so interactive runs never fail on an uninstalled lane; CI arms FMT_STRICT_MISSING=1 to make an
      # absent tool a hard failure in both the exit code and the json ok predicate — a false-green under --check is otherwise the exact CI hazard.
      readonly strict="''${FMT_STRICT_MISSING:-0}"

      # --- [COLLECTION_EXPLICIT_FILES_AS_GIVEN_DIRECTORIES_VIA_FD]
      tmp="$(mktemp -d)"
      trap 'rm -rf "$tmp"' EXIT
      # Abort rail: each lane records its spawned timeout/tool pid because timeout setpgids itself away. TERM gets a bounded grace, KILL closes every
      # survivor, and explicit waits reap the lane shells before EXIT removes their shared state.
      declare -A lane_pid=() lane_rc=() lane_state=()
      # shellcheck disable=SC2329  # invoked through the INT/TERM trap
      _abort() {
        local -ri exit_code=$((128 + BASH_TRAPSIG))
        trap - INT TERM
        local f pid _
        local -i alive=0
        local -a abort_pid=()
        local -A admitted_pid=()
        for f in "$tmp"/pid.*; do
          [[ -f "$f" ]] || continue
          pid="$(<"$f")"
          [[ "$pid" =~ ^[0-9]+$ ]] || continue
          admitted_pid[$pid]=1
        done
        for pid in "''${lane_pid[@]}"; do admitted_pid[$pid]=1; done
        abort_pid=("''${!admitted_pid[@]}")
        ((''${#abort_pid[@]})) && kill -TERM "''${abort_pid[@]}" 2>/dev/null || true
        for _ in 1 2 3 4 5; do
          alive=0
          for pid in "''${abort_pid[@]}"; do kill -0 "$pid" 2>/dev/null && alive=1; done
          ((alive)) || break
          sleep 1
        done
        for pid in "''${abort_pid[@]}"; do kill -0 "$pid" 2>/dev/null && kill -KILL "$pid" 2>/dev/null || true; done
        for pid in "''${lane_pid[@]}"; do wait "$pid" 2>/dev/null || true; done
        exit "$exit_code"
      }
      trap _abort INT TERM
      declare -A lane_count=() seen=()
      declare -i skipped=0
      _assign() {
        local path="$1"
        [[ "$path" == -* ]] && path="./$path"
        [[ -n "''${seen[$path]:-}" ]] && return 0
        seen[$path]=1
        local lane
        _lane_for "$path" lane
        if [[ -z "$lane" ]]; then
          skipped+=1
          return 0
        fi
        printf '%s\0' "$path" >>"$tmp/list.$lane"
        lane_count[$lane]=$((''${lane_count[$lane]:-0} + 1))
      }

      fd_exts=()
      for ext in "''${!_EXT_LANE[@]}"; do fd_exts+=(-e "$ext"); done
      for target in "''${targets[@]}"; do
        [[ "$target" == -* ]] && target="./$target"
        if [[ -f "$target" ]]; then
          _assign "$target"
        elif [[ -d "$target" ]]; then
          # Streaming boundary: fd emits NUL-delimited paths; the pinned fd is unwrapped, so hidden trees (.github/workflows) need -H here. The
          # second pass surfaces extensionless executables for shebang probing. Transient trees (style.nix transientDirs) never route to a lane —
          # gitignore covers checkouts, these excludes cover non-git trees. fd walks in parallel, so the bytewise sort pins discovery order:
          # lane batches, chunk boundaries, and failure diagnostics stay identical run to run.
          while IFS= read -r -d $'\0' path; do
            _assign "$path"
          done < <(
            {
              fd -0 -t f -H --exclude .git ${fdExcludes} "''${fd_exts[@]}" . "$target"
              fd -0 -t x -H --exclude .git ${fdExcludes} . "$target"
            } | LC_ALL=C sort -zu
          )
        else
          printf 'fmt: no such target: %s\n' "$target" >&2
          _emit_error target "no such target: $target"
          exit 2
        fi
      done

      # --- [LANE_RUNNER]
      # Lanes run concurrently; each lane chunks batched, deadlined calls.
      _run_lane() {
        local -r lane="$1"
        local -a files lrow cmd run batch
        mapfile -d $'\0' -t files <"$tmp/list.$lane"
        _lane_row "$lane" lrow
        read -r -a cmd <<<"''${lrow[''${_MODE_FIELD[$mode]}]}"
        local -i wrap=0
        ((deadline > 0)) && ! declare -F "''${cmd[0]}" >/dev/null && wrap=1
        # Argv per spawn rides a 128KiB byte budget: a huge tree chunks into repeat spawns instead of dying E2BIG, and
        # the one lane deadline spans every chunk.
        local -ri t0="$BASH_MONOSECONDS" n="''${#files[@]}" budget=131072
        local -i rc=0 crc i=0 bytes remaining
        while ((i < n)); do
          batch=("''${files[i]}")
          bytes=$((''${#files[i]} + 1))
          i+=1
          while ((i < n)); do
            ((bytes + ''${#files[i]} + 1 <= budget)) || break
            batch+=("''${files[i]}")
            bytes+=$((''${#files[i]} + 1))
            i+=1
          done
          run=("''${cmd[@]}")
          if ((wrap)); then
            remaining=$((deadline - (BASH_MONOSECONDS - t0)))
            ((remaining > 0)) || {
              rc=124
              break
            }
            # TERM first, KILL after a 10s grace; a write-mode kill can leave an in-place rewrite half-applied — atomicity stays tool-owned.
            run=(timeout -k 10 "$remaining" "''${run[@]}")
          fi
          # The recorded pid is the abort rail's direct handle on timeout/tool.
          "''${run[@]}" "''${batch[@]}" >>"$tmp/out.$lane" 2>&1 &
          printf '%d' "$!" >"$tmp/pid.$lane"
          crc=0
          wait "$!" || crc=$?
          if ((crc)); then
            rc="$crc"
            # A deadline kill ends the lane; other failures keep going so the capture accumulates every chunk's diagnostics.
            ((wrap && (crc == 124 || crc == 137))) && break
          fi
        done
        printf '%d' "$((BASH_MONOSECONDS - t0))" >"$tmp/secs.$lane"
        return "$rc"
      }

      declare -a lrow
      status=0
      for lane in "''${!lane_count[@]}"; do
        _lane_row "$lane" lrow
        runner="''${lrow[2]%% *}"
        if ! command -v "$runner" >/dev/null 2>&1 && ! declare -F "$runner" >/dev/null; then
          lane_state[$lane]=missing
          ((strict)) && status=1 || true
          continue
        fi
        # Lane-shell stderr rides the lane's output capture: a KILL-escalated tool's job-death notice lands in the FAIL snippet, not on fmt's stderr.
        _run_lane "$lane" 2>>"$tmp/out.$lane" &
        lane_pid[$lane]=$!
      done
      for lane in "''${!lane_pid[@]}"; do
        if wait "''${lane_pid[$lane]}"; then
          lane_state[$lane]=ok
          lane_rc[$lane]=0
        else
          lane_rc[$lane]=$?
          lane_state[$lane]=fail
          # 124 = timeout sent TERM; 137 = the -k grace expired and KILL landed. Both read as deadline kills only while the wrapper is armed.
          ((deadline > 0 && (lane_rc[$lane] == 124 || lane_rc[$lane] == 137))) \
            && lane_state[$lane]=timeout
          status=1
        fi
      done

      # --- [REPORT_MISSING_TOOLS_INFORM_ONLY_FAIL_TIMEOUT_DRIVE_EXIT_1]
      if ((''${#lane_count[@]} == 0)); then
        printf 'fmt: no formattable files under: %s\n' "''${targets[*]}" >&2
        ((json_mode)) && jq -nc --arg mode "$mode" --argjson skipped "$skipped" \
          --argjson deadline "$deadline" \
          '{mode: $mode, skipped: $skipped, deadline: $deadline, lanes: [], ok: true}'
        exit 0
      fi
      if ((json_mode)); then
        for lane in "''${!lane_count[@]}"; do
          _lane_row "$lane" lrow
          # tr drops NULs before capture (bash warns on them); jq itself maps invalid UTF-8 — including a head-split multibyte char — to U+FFFD.
          snippet=""
          case "''${lane_state[$lane]:-missing}" in
            fail | timeout) snippet="$(head -c 2048 "$tmp/out.$lane" | tr -d '\0')" ;;
          esac
          secs=null
          if [[ -s "$tmp/secs.$lane" ]]; then
            read -r secs <"$tmp/secs.$lane"
            [[ "$secs" =~ ^[0-9]+$ ]] || secs=null
          fi
          jq -nc --arg lane "$lane" --arg tool "''${lrow[0]}" \
            --argjson files "''${lane_count[$lane]}" --arg state "''${lane_state[$lane]:-missing}" \
            --argjson rc "''${lane_rc[$lane]:-null}" --argjson secs "$secs" --arg output "$snippet" \
            '{lane: $lane, tool: $tool, files: $files, state: $state, rc: $rc, secs: $secs, output: $output}'
        done | jq -sc --arg mode "$mode" --argjson skipped "$skipped" \
          --argjson deadline "$deadline" --argjson strict "$strict" \
          '{mode: $mode, skipped: $skipped, deadline: $deadline, lanes: sort_by(.lane),
            ok: (map(.state == "ok" or (.state == "missing" and $strict == 0)) | all)}'
        exit "$status"
      fi
      ok_tag=OK
      [[ "$mode" == write ]] && ok_tag=FMT
      mapfile -t lanes_sorted < <(printf '%s\n' "''${!lane_count[@]}" | sort)
      for lane in "''${lanes_sorted[@]}"; do
        _lane_row "$lane" lrow
        case "''${lane_state[$lane]:-missing}" in
          ok) printf '[%s] %-8s %3d file(s) via %s\n' "$ok_tag" "$lane" "''${lane_count[$lane]}" "''${lrow[0]}" ;;
          missing) printf '[MISSING] %-8s %3d file(s) — %s not on PATH\n' "$lane" "''${lane_count[$lane]}" "''${lrow[0]}" ;;
          fail | timeout)
            detail="rc=''${lane_rc[$lane]}"
            [[ "''${lane_state[$lane]}" == timeout ]] && detail="timed out after ''${deadline}s"
            printf '[FAIL] %-8s %3d file(s) via %s (%s)\n' "$lane" "''${lane_count[$lane]}" "''${lrow[0]}" "$detail"
            gawk 'NR <= 40 { print "    " $0 } END { if (NR > 40) printf "    [+%d more lines]\n", NR - 40 }' "$tmp/out.$lane"
            ;;
        esac
      done
      if ((skipped)); then
        printf '[SKIP] %d file(s) with no owning lane\n' "$skipped"
      fi
      exit "$status"
    '';
  };
in {
  home.packages = [fmt];
}
