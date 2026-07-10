# Title         : fmt.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/scripts/fmt.nix
# ----------------------------------------------------------------------------
# fmt: polymorphic formatter front door — one command routes every file type
# to its owning formatter. Formatters resolve from PATH so the Home Manager
# fallback wrappers keep their never-shadow project-config semantics; those
# wrappers probe $PWD, so run fmt from inside the project the targets live in.
{pkgs, ...}: let
  fmt = pkgs.writeShellApplication {
    name = "fmt";
    runtimeInputs = [pkgs.coreutils pkgs.fd pkgs.jq];
    text = ''
      shopt -s inherit_errexit

      # --- Dispatch tables: lane -> tool / argv prefix per mode --------------
      declare -Ar _LANE_TOOL=(
        [nix]=alejandra [shell]=shfmt [python]=ruff [web]=biome
        [prose]=prettier [yaml]=yamlfmt [toml]=taplo [lua]=stylua
        [sql]=sqruff [swift]=swiftformat [csharp]=csharpier [osa]=forge-osa [jq]=jq
      )
      declare -Ar _LANE_WRITE=(
        [nix]='alejandra -q --' [shell]='shfmt -w' [python]='ruff format --'
        [web]='biome format --write' [prose]='prettier --log-level warn --write'
        [yaml]='yamlfmt' [toml]='taplo fmt' [lua]='stylua --'
        [sql]='sqruff fix' [swift]='swiftformat --quiet' [csharp]='csharpier format'
        [osa]='forge-osa fmt' [jq]='_gate_jq'
      )
      declare -Ar _LANE_CHECK=(
        [nix]='alejandra -c --' [shell]='shfmt -d' [python]='ruff format --check --'
        [web]='biome format' [prose]='prettier --log-level warn --check'
        [yaml]='yamlfmt -lint' [toml]='taplo fmt --check' [lua]='stylua --check --'
        [sql]='sqruff lint' [swift]='swiftformat --quiet --lint' [csharp]='csharpier check'
        [osa]='forge-osa check' [jq]='_gate_jq'
      )
      declare -Ar _EXT_LANE=(
        [nix]=nix
        [sh]=shell [bash]=shell
        [py]=python [pyi]=python
        [ts]=web [tsx]=web [js]=web [jsx]=web [mjs]=web [cjs]=web [mts]=web [cts]=web
        [json]=web [jsonc]=web [css]=web
        [md]=prose [markdown]=prose [html]=prose
        [yml]=yaml [yaml]=yaml
        [toml]=toml
        [lua]=lua
        [sql]=sql
        [swift]=swift
        [cs]=csharp
        [applescript]=osa
        [jq]=jq
      )
      # Package-manager lockfiles are machine-owned; formatting one is corruption.
      declare -Ar _DENY_BASE=(
        [pnpm-lock.yaml]=1 [package-lock.json]=1 [packages.lock.json]=1
        [yarn.lock]=1 [bun.lock]=1 [composer.lock]=1 [Gemfile.lock]=1
      )
      readonly _SHEBANG_SHELL='^#!.*[/[:space:]](env[[:space:]]+)?(ba|da|mk)?sh([[:space:]]|$)'
      readonly _SHEBANG_PYTHON='^#!.*[/[:space:]](env[[:space:]]+(-S[[:space:]]+)?)?python[0-9.]*([[:space:]]|$)'

      # jq has no safe formatter (jqfmt drops top-level defs); the compile
      # gate is the whole static surface: empty stdin, body never runs, so
      # the gate cannot hang and needs no deadline. Programs written for
      # `jq --arg` reference variables that are compile errors when unbound,
      # so every referenced $var is pre-defined before the compile.
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

      _usage() {
        printf 'usage: %s [--check] [--json] [--self-test] [target...]\n' "''${0##*/}" >&2
        exit 2
      }

      # Pure classification: deny rows first, then the extension row; unowned
      # readable files fall through to a bounded shebang probe. A dotfile's
      # whole name is not an extension; a bare trailing dot owns nothing.
      _lane_for() {
        local -r path="$1"
        local -n _out="$2"
        _out=""
        local -r base="''${path##*/}"
        [[ -n "''${_DENY_BASE[$base]:-}" ]] && return 0
        local ext="''${base##*.}"
        [[ "$ext" == "$base" || ".$ext" == "$base" ]] && ext=""
        [[ -n "$ext" ]] && _out="''${_EXT_LANE[''${ext,,}]:-}"
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
        for ext in "''${!_EXT_LANE[@]}"; do
          lane="''${_EXT_LANE[$ext]}"
          [[ -n "''${_LANE_TOOL[$lane]:-}" && -n "''${_LANE_WRITE[$lane]:-}" && -n "''${_LANE_CHECK[$lane]:-}" ]] || {
            printf 'self-test: ext %s -> lane %s incomplete\n' "$ext" "$lane" >&2
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
          ["obj/packages.lock.json"]=""
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
          "''${#_EXT_LANE[@]}" "''${#_LANE_TOOL[@]}" "''${#probes[@]}"
      }

      # --- Arguments ----------------------------------------------------------
      mode="write"
      json_mode=0
      targets=()
      while (($#)); do
        case "$1" in
          --check) mode=check ;;
          --json) json_mode=1 ;;
          --self-test) _self_test; exit ;;
          --help | -h) _usage ;;
          --) shift; targets+=("$@"); break ;;
          --*) _usage ;;
          *) targets+=("$1") ;;
        esac
        shift
      done
      ((''${#targets[@]})) || targets=(.)
      readonly mode json_mode
      readonly deadline="''${FMT_DEADLINE_SECONDS:-300}"
      [[ "$deadline" =~ ^[0-9]+$ ]] || {
        printf 'fmt: FMT_DEADLINE_SECONDS must be a whole number of seconds\n' >&2
        exit 2
      }

      # --- Collection: explicit files as given, directories via fd -----------
      tmp="$(mktemp -d)"
      trap 'rm -rf "$tmp"' EXIT
      # Abort rail: async lanes inherit SIGINT-ignored, so Ctrl-C or TERM on the
      # parent would orphan running formatters. Each lane records its spawned
      # tool pid — timeout setpgids itself away, so only a direct TERM reaches
      # it, and it forwards the TERM to its child group before exiting. A
      # formatter that ignores TERM holds _abort in wait — the traps are already
      # cleared, so a second Ctrl-C kills the shell and the EXIT trap still runs.
      declare -A lane_pid=() lane_rc=() lane_state=()
      # shellcheck disable=SC2329  # invoked through the INT/TERM trap
      _abort() {
        trap - INT TERM
        local f
        for f in "$tmp"/pid.*; do
          [[ -f "$f" ]] && kill -TERM "$(<"$f")" 2>/dev/null || true
        done
        ((''${#lane_pid[@]})) && kill -TERM "''${lane_pid[@]}" 2>/dev/null || true
        wait
        exit "$((128 + BASH_TRAPSIG))"
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
          # Streaming boundary: fd emits NUL-delimited paths; the pinned fd is
          # unwrapped, so hidden trees (.github/workflows) need -H here. The
          # second pass surfaces extensionless executables for shebang probing.
          while IFS= read -r -d $'\0' path; do
            _assign "$path"
          done < <(
            fd -0 -t f -H --exclude .git "''${fd_exts[@]}" . "$target"
            fd -0 -t x -H --exclude .git . "$target"
          )
        else
          printf 'fmt: no such target: %s\n' "$target" >&2
          exit 2
        fi
      done

      # --- Lanes run concurrently; each lane is one batched, deadlined call --
      _run_lane() {
        local -r lane="$1"
        local -a files cmd
        mapfile -d $'\0' -t files <"$tmp/list.$lane"
        local -n mtab="_LANE_''${mode^^}"
        read -r -a cmd <<<"''${mtab[$lane]}"
        # TERM first, KILL after a 10s grace; a write-mode kill can leave an
        # in-place rewrite half-applied — write atomicity stays tool-owned.
        if ((deadline > 0)) && ! declare -F "''${cmd[0]}" >/dev/null; then
          cmd=(timeout -k 10 "$deadline" "''${cmd[@]}")
        fi
        local -ri t0="$BASH_MONOSECONDS"
        local -i rc=0
        # The recorded pid is the abort rail's direct handle on timeout/tool.
        "''${cmd[@]}" "''${files[@]}" >"$tmp/out.$lane" 2>&1 &
        printf '%d' "$!" >"$tmp/pid.$lane"
        wait "$!" || rc=$?
        printf '%d' "$((BASH_MONOSECONDS - t0))" >"$tmp/secs.$lane"
        return "$rc"
      }

      for lane in "''${!lane_count[@]}"; do
        runner="''${_LANE_CHECK[$lane]%% *}"
        if ! command -v "$runner" >/dev/null 2>&1 && ! declare -F "$runner" >/dev/null; then
          lane_state[$lane]=missing
          continue
        fi
        # Lane-shell stderr rides the lane's output capture: a KILL-escalated
        # tool's job-death notice lands in the FAIL snippet, not on fmt's stderr.
        _run_lane "$lane" 2>>"$tmp/out.$lane" &
        lane_pid[$lane]=$!
      done
      status=0
      for lane in "''${!lane_pid[@]}"; do
        if wait "''${lane_pid[$lane]}"; then
          lane_state[$lane]=ok
          lane_rc[$lane]=0
        else
          lane_rc[$lane]=$?
          lane_state[$lane]=fail
          # 124 = timeout sent TERM; 137 = the -k grace expired and KILL landed.
          # Both read as deadline kills only while the wrapper is armed.
          ((deadline > 0 && (lane_rc[$lane] == 124 || lane_rc[$lane] == 137))) \
            && lane_state[$lane]=timeout
          status=1
        fi
      done

      # --- Report: missing tools inform, only fail/timeout drive exit 1 ------
      if ((''${#lane_count[@]} == 0)); then
        printf 'fmt: no formattable files under: %s\n' "''${targets[*]}" >&2
        ((json_mode)) && jq -nc --arg mode "$mode" --argjson skipped "$skipped" \
          --argjson deadline "$deadline" \
          '{mode: $mode, skipped: $skipped, deadline: $deadline, lanes: [], ok: true}'
        exit 0
      fi
      if ((json_mode)); then
        for lane in "''${!lane_count[@]}"; do
          # tr drops NULs before capture (bash warns on them); jq itself maps
          # invalid UTF-8 — including a head-split multibyte char — to U+FFFD.
          snippet=""
          case "''${lane_state[$lane]:-missing}" in
            fail | timeout) snippet="$(head -c 2048 "$tmp/out.$lane" | tr -d '\0')" ;;
          esac
          secs=null
          [[ -f "$tmp/secs.$lane" ]] && secs="$(<"$tmp/secs.$lane")"
          jq -nc --arg lane "$lane" --arg tool "''${_LANE_TOOL[$lane]}" \
            --argjson files "''${lane_count[$lane]}" --arg state "''${lane_state[$lane]:-missing}" \
            --argjson rc "''${lane_rc[$lane]:-null}" --argjson secs "$secs" --arg output "$snippet" \
            '{lane: $lane, tool: $tool, files: $files, state: $state, rc: $rc, secs: $secs, output: $output}'
        done | jq -sc --arg mode "$mode" --argjson skipped "$skipped" \
          --argjson deadline "$deadline" \
          '{mode: $mode, skipped: $skipped, deadline: $deadline, lanes: sort_by(.lane),
            ok: (map(.state == "ok" or .state == "missing") | all)}'
        exit "$status"
      fi
      ok_tag=OK
      [[ "$mode" == write ]] && ok_tag=FMT
      mapfile -t lanes_sorted < <(printf '%s\n' "''${!lane_count[@]}" | sort)
      for lane in "''${lanes_sorted[@]}"; do
        case "''${lane_state[$lane]:-missing}" in
          ok) printf '[%s] %-8s %3d file(s) via %s\n' "$ok_tag" "$lane" "''${lane_count[$lane]}" "''${_LANE_TOOL[$lane]}" ;;
          missing) printf '[MISSING] %-8s %3d file(s) — %s not on PATH\n' "$lane" "''${lane_count[$lane]}" "''${_LANE_TOOL[$lane]}" ;;
          fail | timeout)
            detail="rc=''${lane_rc[$lane]}"
            [[ "''${lane_state[$lane]}" == timeout ]] && detail="timed out after ''${deadline}s"
            printf '[FAIL] %-8s %3d file(s) via %s (%s)\n' "$lane" "''${lane_count[$lane]}" "''${_LANE_TOOL[$lane]}" "$detail"
            head -n 40 "$tmp/out.$lane" | sed 's/^/    /'
            out_lines=$(wc -l <"$tmp/out.$lane")
            ((out_lines > 40)) && printf '    [+%d more lines]\n' "$((out_lines - 40))"
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
