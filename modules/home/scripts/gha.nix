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
      # 1 findings, 2 tool failure. Rows are the verdict detail; tool exit codes only classify the state.
      declare -Ar _GATE=(
        ["actionlint"]=_gate_actionlint
        ["ratchet"]=_gate_ratchet
        ["zizmor"]=_gate_zizmor
      )

      # shellcheck disable=SC2329  # invoked through the gate dispatch table
      _gate_actionlint() {
        local out rc=0
        out="$(actionlint -format '{{json .}}' -- "$@" 2>&1)" || rc=$?
        ((rc <= 1)) || {
          printf '%s\n' "$out" >&2
          return 2
        }
        jq -c '.[] | {tool: "actionlint", file: .filepath, line: .line, id: .kind, severity: "error", message: .message}' <<<"$out"
        return "$rc"
      }

      # shellcheck disable=SC2329  # invoked through the gate dispatch table
      _gate_ratchet() {
        local out rc=0
        out="$(ratchet lint "$@" 2>&1)" || rc=$?
        ((rc <= 1)) || {
          printf '%s\n' "$out" >&2
          return 2
        }
        jq -cR 'try capture("^(?<file>[^:]+):(?<line>[0-9]+):[0-9]+: (?<message>.+)$")
          | {tool: "ratchet", file: .file, line: (.line | tonumber), id: "unpinned", severity: "error", message: .message}' <<<"$out"
        return "$rc"
      }

      # shellcheck disable=SC2329  # invoked through the gate dispatch table
      _gate_zizmor() {
        local out rc=0
        out="$(zizmor --format json --no-online-audits "$@" 2>/dev/null)" || rc=$?
        case "$rc" in
          0) ;;
          1[0-4]) rc=1 ;; # zizmor encodes the highest finding severity as exit 10-14
          *) return 2 ;;
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
            printf 'gha: no such target: %s\n' "$t" >&2
            exit 2
          }
          root="$t"
          [[ -d "$t/.github/workflows" ]] && root="$t/.github/workflows"
          while IFS= read -r -d $'\0' f; do files+=("$f"); done \
            < <(fd -0 -t f -H -e yml -e yaml . "$root" | LC_ALL=C sort -z)
        done
        ((''${#files[@]})) || {
          printf 'gha: no workflow files under: %s\n' "$*" >&2
          exit 2
        }
      }

      _check() {
        _discover "''${targets[@]:-.}"
        local tmp gate rc n
        tmp="$(mktemp -d)"
        trap 'rm -rf "$tmp"' EXIT
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
            *) gate_state[$gate]=error ;;
          esac
          ((rc == 0)) || status=1
        done
        if ((json_mode)); then
          for gate in "''${gates[@]}"; do
            jq -sc --arg tool "$gate" --arg state "''${gate_state[$gate]}" --argjson rc "''${gate_rc[$gate]}" \
              '{tool: $tool, state: $state, rc: $rc, findings: length, rows: .}' <"$tmp/$gate.jsonl"
          done | jq -sc --argjson files "''${#files[@]}" \
            '{mode: "check", files: $files, tools: sort_by(.tool), ok: (map(.state == "ok") | all)}'
          exit "$status"
        fi
        for gate in "''${gates[@]}"; do
          n="$(wc -l <"$tmp/$gate.jsonl")"
          case "''${gate_state[$gate]}" in
            ok) printf '[OK]   %-10s %3d file(s)\n' "$gate" "''${#files[@]}" ;;
            fail)
              printf '[FAIL] %-10s %3d finding(s)\n' "$gate" "$n"
              jq -r '"    \(.file):\(.line) [\(.severity)] \(.id): \(.message)"' <"$tmp/$gate.jsonl" | head -40
              ;;
            error) printf '[ERROR] %-9s rc=%d — tool failure, findings unknown\n' "$gate" "''${gate_rc[$gate]}" ;;
          esac
        done
        exit "$status"
      }

      _pin() {
        _discover "''${targets[@]:-.}"
        local out rc=0
        out="$(ratchet pin "''${files[@]}" 2>&1)" || rc=$?
        if ((json_mode)); then
          printf '%s\n' "''${files[@]}" | jq -Rc '{file: .}' | jq -sc --argjson rc "$rc" --arg output "$out" \
            '{mode: "pin", files: ., rc: $rc, ok: ($rc == 0), output: $output}'
        else
          local f
          for f in "''${files[@]}"; do printf '[PIN] %s\n' "$f"; done
          ((rc == 0)) || printf '[FAIL] ratchet pin rc=%d\n%s\n' "$rc" "$out"
        fi
        ((rc == 0)) || exit 1
      }

      _events() {
        [[ -d .github/workflows ]] || {
          printf 'gha: no workflow files under: .\n' >&2
          exit 2
        }
        # act --list projection: the Events column is the table's last field; header row drops, comma lists split, duplicates collapse.
        local ev_json
        ev_json="$(act --list 2>/dev/null | jq -Rsc 'split("\n")[1:] | map(select(length > 0) | split(" ") | last | split(",")) | flatten | unique')"
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
        local st
        st="$(mktemp -d)"
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
        rm -rf "$st"
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
