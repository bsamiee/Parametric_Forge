# Title         : gha.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/scripts/gha.nix
# ----------------------------------------------------------------------------
# gha: the local GitHub-Actions gate router — actionlint (workflow semantics), zizmor (security policy), and ratchet (immutable references)
# fold into one typed check verdict; pin rewrites mutable refs to SHAs; run and events ride act against the deployed actrc, with the container
# socket resolved from the environment. Hosted CI stays the execution authority — this surface is the pre-push defect gate.
{pkgs, ...}: let
  gha = pkgs.writeShellApplication {
    name = "gha";
    runtimeInputs = [pkgs.act pkgs.actionlint pkgs.coreutils pkgs.fd pkgs.jq pkgs.ratchet pkgs.zizmor];
    text = ''
      shopt -s inherit_errexit

      _usage() { printf 'usage: %s check|pin [--json] [PATH...] | run [ACT-ARGS...] | events [--json] | --self-test\n' "''${0##*/}"; }

      # --- [GATE_VOCABULARY]
      # One row per gate: the normalizer emits one JSON row per finding on stdout — {tool,file,line,id,severity,message} — and returns 0 clean,
      # 1 findings, >1 tool failure with deadline kills passing through as 124/137. Rows are the verdict detail; exit codes only classify state.
      # Every tool spawn rides `timeout -k 10` under the one deadline: TERM first, KILL after a 10s grace (duration 0 disarms, matching fmt/loc).
      declare -Ar _GATE=(
        ["actionlint"]=_gate_actionlint
        ["ratchet"]=_gate_ratchet
        ["zizmor"]=_gate_zizmor
      )

      # shellcheck disable=SC2329  # invoked through the gate dispatch table
      _gate_actionlint() {
        local out rc=0
        out="$(timeout -k 10 "$deadline" actionlint -format '{{json .}}' -- "$@" 2>&1)" || rc=$?
        ((rc <= 1)) || {
          printf '%s\n' "$out" >&2
          return "$rc"
        }
        jq -c '.[] | {tool: "actionlint", file: .filepath, line: .line, id: .kind, severity: "error", message: .message}' <<<"$out"
        return "$rc"
      }

      # shellcheck disable=SC2329  # invoked through the gate dispatch table
      # ratchet's reader is CWD-rooted — absolute and ..-relative paths are read errors — so each file runs from its own directory by basename
      # and the caller's path is restored on the row. The one gate deadline spans every file: the remaining budget shrinks per spawn.
      _gate_ratchet() {
        local f dir out rc=0 frc
        local -ri t0="$BASH_MONOSECONDS"
        local -i remaining=0
        for f in "$@"; do
          if ((deadline > 0)); then
            remaining=$((deadline - (BASH_MONOSECONDS - t0)))
            ((remaining > 0)) || return 124
          fi
          dir="''${f%/*}"
          [[ "$dir" == "$f" ]] && dir=.
          frc=0
          out="$(cd "$dir" && timeout -k 10 "$remaining" ratchet lint "''${f##*/}" 2>&1)" || frc=$?
          ((frc <= 1)) || {
            printf '%s\n' "$out" >&2
            return "$frc"
          }
          ((frc == 0)) || rc=1
          jq -cR --arg file "$f" 'try capture("^[^:]+:(?<line>[0-9]+):[0-9]+: (?<message>.+)$")
            | {tool: "ratchet", file: $file, line: (.line | tonumber), id: "unpinned", severity: "error", message: .message}' <<<"$out"
        done
        return "$rc"
      }

      # shellcheck disable=SC2329  # invoked through the gate dispatch table
      # zizmor chats progress on stderr, so stderr rides a side file: findings JSON stays clean and a tool failure still surfaces its diagnostics.
      _gate_zizmor() {
        local out err rc=0
        err="$tmp/zizmor.err"
        out="$(timeout -k 10 "$deadline" zizmor --format json --no-online-audits "$@" 2>"$err")" || rc=$?
        case "$rc" in
          0) ;;
          1[0-4]) rc=1 ;; # zizmor encodes the highest finding severity as exit 10-14
          *)
            cat "$err" >&2
            return "$rc"
            ;;
        esac
        jq -c '.[] | {tool: "zizmor", file: (.locations[0].symbolic.key.Local.given_path // ""),
          line: ((.locations[0].concrete.location.start_point.row // -1) + 1), id: .ident,
          severity: (.determinations.severity | ascii_downcase), message: .desc}' <<<"$out"
        return "$rc"
      }

      # Workflow discovery: explicit files pass verbatim, a directory resolves to its .github/workflows tree when present (else scanned as
      # given), and the bare default is the CWD's tree. Empty discovery is a typed usage failure. Sort pins gate batch order run to run.
      _discover() {
        files=()
        local t root f
        for t in "$@"; do
          if [[ -f "$t" ]]; then
            files+=("$t")
            continue
          fi
          [[ -d "$t" ]] || {
            ((json_mode)) && jq -nc --arg t "$t" '{error: {surface: "gha", kind: "target", target: $t}}'
            printf 'gha: no such target: %s\n' "$t" >&2
            exit 2
          }
          root="$t"
          [[ -d "$t/.github/workflows" ]] && root="$t/.github/workflows"
          while IFS= read -r -d $'\0' f; do files+=("$f"); done \
            < <(fd -0 -t f -H -e yml -e yaml . "$root" | LC_ALL=C sort -z)
        done
        ((''${#files[@]})) || {
          ((json_mode)) && jq -nc '{error: {surface: "gha", kind: "discovery", targets: $ARGS.positional}}' --args -- "$@"
          printf 'gha: no workflow files under: %s\n' "$*" >&2
          exit 2
        }
      }

      # One scratch owner: a fatal INT/TERM lands as a deferred trap that exits through EXIT cleanup, so no run leaves temp litter — the
      # in-flight tool spawn drains first (bash defers traps past the foreground command) and stays deadline-bounded.
      _scratch() {
        tmp="$(mktemp -d)"
        trap 'rm -rf "$tmp"' EXIT
        trap 'exit 130' INT
        trap 'exit 143' TERM
      }

      _check() {
        _discover "''${targets[@]:-.}"
        local gate rc n
        _scratch
        local -A gate_rc=() gate_state=()
        local status=0
        mapfile -t gates < <(printf '%s\n' "''${!_GATE[@]}" | sort)
        for gate in "''${gates[@]}"; do
          rc=0
          "''${_GATE[$gate]}" "''${files[@]}" >"$tmp/$gate.jsonl" || rc=$?
          gate_rc[$gate]=$rc
          case "$rc" in
            0) gate_state[$gate]=ok ;;
            1) gate_state[$gate]=fail ;;
            *)
              gate_state[$gate]=error
              # 124 = timeout sent TERM; 137 = the -k grace expired and KILL landed. Both read as deadline kills only while the wrapper is armed.
              ((deadline > 0 && (rc == 124 || rc == 137))) && gate_state[$gate]=timeout
              ;;
          esac
          ((rc == 0)) || status=1
        done
        if ((json_mode)); then
          for gate in "''${gates[@]}"; do
            jq -sc --arg tool "$gate" --arg state "''${gate_state[$gate]}" --argjson rc "''${gate_rc[$gate]}" \
              '{tool: $tool, state: $state, rc: $rc, findings: length, rows: .}' <"$tmp/$gate.jsonl"
          done | jq -sc --argjson files "''${#files[@]}" --argjson deadline "$deadline" \
            '{mode: "check", files: $files, deadline: $deadline, tools: sort_by(.tool), ok: (map(.state == "ok") | all)}'
          exit "$status"
        fi
        for gate in "''${gates[@]}"; do
          n="$(wc -l <"$tmp/$gate.jsonl")"
          case "''${gate_state[$gate]}" in
            ok) printf '[OK]   %-10s %3d file(s)\n' "$gate" "''${#files[@]}" ;;
            fail)
              printf '[FAIL] %-10s %3d finding(s)\n' "$gate" "$n"
              jq -rs 'limit(40; .[]) | "    \(.file):\(.line) [\(.severity)] \(.id): \(.message)"' <"$tmp/$gate.jsonl"
              ;;
            timeout) printf '[FAIL] %-10s timed out after %ss\n' "$gate" "$deadline" ;;
            error) printf '[ERROR] %-9s rc=%d — tool failure, findings unknown\n' "$gate" "''${gate_rc[$gate]}" ;;
          esac
        done
        exit "$status"
      }

      _pin() {
        _discover "''${targets[@]:-.}"
        local f dir out frc status=0 rows=""
        local -ri t0="$BASH_MONOSECONDS"
        local -i remaining=0
        for f in "''${files[@]}"; do
          if ((deadline > 0)); then
            remaining=$((deadline - (BASH_MONOSECONDS - t0)))
            ((remaining > 0)) || {
              ((json_mode)) && jq -nc --argjson deadline "$deadline" --arg file "$f" \
                '{error: {surface: "gha", kind: "deadline", deadline: $deadline, at: $file}}'
              printf 'gha: pin deadline (%ss) exhausted at %s\n' "$deadline" "$f" >&2
              exit 1
            }
          fi
          dir="''${f%/*}"
          [[ "$dir" == "$f" ]] && dir=.
          frc=0
          # ratchet pin resolves refs over the network — the estate's most deadline-worthy spawn.
          out="$(cd "$dir" && timeout -k 10 "$remaining" ratchet pin "''${f##*/}" 2>&1)" || frc=$?
          ((frc == 0)) || status=1
          if ((json_mode)); then
            rows+="$(jq -nc --arg file "$f" --argjson rc "$frc" --arg output "$out" \
              '{file: $file, rc: $rc, ok: ($rc == 0), output: $output}')"$'\n'
          elif ((frc == 0)); then
            printf '[PIN]  %s\n' "$f"
          else
            printf '[FAIL] %s rc=%d\n%s\n' "$f" "$frc" "$out"
          fi
        done
        if ((json_mode)); then
          jq -sc '{mode: "pin", files: length, rows: ., ok: (map(.ok) | all)}' <<<"$rows"
        fi
        exit "$status"
      }

      _events() {
        # act reads the CWD's .github/workflows only, so the guard demands actual workflow files there — a present-but-empty tree is the same
        # typed discovery failure a check run reports, on both rails.
        local f
        local -a wf=()
        if [[ -d .github/workflows ]]; then
          while IFS= read -r -d $'\0' f; do wf+=("$f"); done < <(fd -0 -t f -H -e yml -e yaml . .github/workflows)
        fi
        ((''${#wf[@]})) || {
          ((json_mode)) && jq -nc '{error: {surface: "gha", kind: "discovery", targets: ["."]}}'
          printf 'gha: no workflow files under: .github/workflows\n' >&2
          exit 2
        }
        # act --list projection: the Events column is the table's last field; header row drops, comma lists split, duplicates collapse.
        # A parse-rejected workflow is a typed failure, never an empty event list.
        local out errf rc=0 ev_json
        _scratch
        errf="$tmp/act.err"
        out="$(timeout -k 10 "$deadline" act --list 2>"$errf")" || rc=$?
        ((rc == 0)) || {
          ((json_mode)) && jq -nc --rawfile detail "$errf" '{error: {surface: "gha", kind: "act", detail: $detail}}'
          printf 'gha: act --list failed:\n' >&2
          cat "$errf" >&2
          exit 1
        }
        # Columns pad with trailing spaces to the widest row, so the last non-space token — never split(" ")|last — is the Events field.
        ev_json="$(jq -Rsc '[split("\n")[1:][] | select(test("\\S")) | [scan("\\S+")] | last | split(",")] | flatten | unique' <<<"$out")"
        if ((json_mode)); then
          jq -nc --argjson events "$ev_json" '{mode: "events", events: $events}'
        else
          jq -r '.[]' <<<"$ev_json"
        fi
      }

      _self_test() {
        local gate
        for gate in "''${!_GATE[@]}"; do
          declare -F "''${_GATE[$gate]}" >/dev/null || {
            printf 'self-test: gate %s -> missing normalizer\n' "$gate" >&2
            return 1
          }
        done
        _scratch
        local st="$tmp/fixture"
        mkdir -p "$st/.github/workflows"
        # Fixture carries one defect per gate: an undefined function for actionlint, a mutable ref for ratchet, credential persistence for zizmor.
        cat >"$st/.github/workflows/probe.yml" <<'EOF'
      name: probe
      on: push
      jobs:
        probe:
          runs-on: ubuntu-latest
          steps:
            - uses: actions/checkout@v4
            - run: exit 0
              if: alway()
      EOF
        local -i a r z
        a="$({ _gate_actionlint "$st/.github/workflows/probe.yml" || true; } | jq -sc length)"
        r="$({ _gate_ratchet "$st/.github/workflows/probe.yml" || true; } | jq -sc length)"
        z="$({ _gate_zizmor "$st/.github/workflows/probe.yml" || true; } | jq -sc length)"
        ((a >= 1 && r == 1 && z >= 1)) || {
          printf 'self-test: fixture findings actionlint=%d ratchet=%d zizmor=%d (want >=1, ==1, >=1)\n' "$a" "$r" "$z" >&2
          return 1
        }
        printf 'self-test: %d gates, fixture findings actionlint=%d ratchet=%d zizmor=%d ok\n' "''${#_GATE[@]}" "$a" "$r" "$z"
      }

      # --- [ARGUMENTS]
      (($#)) || {
        _usage >&2
        exit 2
      }
      verb="$1"
      shift
      json_mode=0
      targets=()
      readonly deadline="''${GHA_DEADLINE_SECONDS:-300}"
      [[ "$deadline" =~ ^[0-9]+$ ]] || {
        printf 'gha: GHA_DEADLINE_SECONDS must be a whole number of seconds\n' >&2
        exit 2
      }
      case "$verb" in
        --help | -h)
          _usage
          exit 0
          ;;
        --self-test)
          _self_test
          exit
          ;;
        run) exec act "$@" ;;
        check | pin | events)
          while (($#)); do
            case "$1" in
              --json) json_mode=1 ;;
              --help | -h)
                _usage
                exit 0
                ;;
              --)
                shift
                targets+=("$@")
                break
                ;;
              --*)
                _usage >&2
                exit 2
                ;;
              *) targets+=("$1") ;;
            esac
            shift
          done
          ;;
        *)
          _usage >&2
          exit 2
          ;;
      esac
      readonly json_mode
      if [[ "$verb" == events && ''${#targets[@]} -gt 0 ]]; then
        _usage >&2
        exit 2
      fi

      case "$verb" in
        check) _check ;;
        pin) _pin ;;
        events) _events ;;
      esac
    '';
  };
in {
  home.packages = [gha];
}
