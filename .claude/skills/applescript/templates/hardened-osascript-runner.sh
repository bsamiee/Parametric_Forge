#!/usr/bin/env bash
# Title    : hardened-osascript-runner
# Purpose  : Gate an OSA payload on an external consent preflight, then drive it with argv-only
#            data under a timeout budget, one JSON stdout envelope, and a hash-only audit row.
# Contract : runner <bundle-id> <script-path> [data-arg ...]
#            stdout carries exactly one JSON object; every diagnostic rides stderr.
# Replace  : <PREFLIGHT_COMMAND>, <AUDIT_LOG>, <EVENT_CLASS>, <EVENT_ID>, <AUDIT_FIELDS>.
set -euo pipefail

readonly OSASCRIPT=/usr/bin/osascript
readonly PLUTIL=/usr/bin/plutil
readonly PYTHON3=/usr/bin/python3
readonly SHASUM=/usr/bin/shasum
# The preflight binary is the one that later sends, so consent binds to the identity that ships.
readonly PREFLIGHT="${AUTOMATION_PREFLIGHT:-<PREFLIGHT_COMMAND>}"
readonly AUDIT_LOG="${AUTOMATION_AUDIT_LOG:-<AUDIT_LOG>}"
readonly PREFLIGHT_TIMEOUT="${AUTOMATION_PREFLIGHT_TIMEOUT:-20}"
readonly SEND_TIMEOUT="${AUTOMATION_SEND_TIMEOUT:-45}"
# Four-character codes as hex; typeWildCard 0x2A2A2A2A widens the question to the whole target.
readonly EVENT_CLASS="${AUTOMATION_EVENT_CLASS:-<EVENT_CLASS>}"
readonly EVENT_ID="${AUTOMATION_EVENT_ID:-<EVENT_ID>}"

die() {
    printf '{"ok":false,"stage":"%s","reason":%s}\n' "$1" "$2"
    exit 1
}

json_string() {
    "$PYTHON3" -c 'import json,sys;print(json.dumps(sys.stdin.read()))'
}

# The preflight owns classification and prints one JSON object keyed `verdict`; the runner branches.
# The perl alarm bounds a call that blocks on a target that never answers.
preflight() {
    perl -e 'alarm shift; exec @ARGV' "$PREFLIGHT_TIMEOUT" \
        "$PREFLIGHT" "$1" "$EVENT_CLASS" "$EVENT_ID"
}

# Extend the row through <AUDIT_FIELDS>: non-secret outcome columns beside the digest.
audit() {
    local script_path=$1 ok=$2 result_len=$3 digest preview
    digest=$("$SHASUM" -a 256 "$script_path" | {
        read -r sum _
        printf '%s' "$sum"
    })
    preview=$(head -c 96 "$script_path" | tr -d '\000-\037')
    printf '%s\tok=%s\tlen=%s\tsha256=%s\tpreview=%q\n' \
        "$(date -u +%FT%TZ)" "$ok" "$result_len" "$digest" "$preview" >>"$AUDIT_LOG"
}

main() {
    [[ $# -ge 2 ]] || die "usage" '"runner <bundle-id> <script-path> [data-arg ...]"'
    local bundle_id=$1 script_path=$2
    shift 2
    [[ -f $script_path ]] || die "input" '"script path is not a file"'

    local verdict_json verdict
    verdict_json=$(preflight "$bundle_id" 2>/dev/null) ||
        die "preflight" '"consent preflight timed out or failed"'
    verdict=$(printf '%s' "$verdict_json" | "$PLUTIL" -extract verdict raw -o - - 2>/dev/null || printf 'failed')

    case $verdict in
        granted) ;;
        denied) die "consent" '"automation denied for target — route the user to System Settings > Privacy > Automation"' ;;
        undecided) die "consent" '"automation undecided — trigger the explicit user-initiated permission lane"' ;;
        target-not-running) die "consent" '"target application is not running — launch it before preflight"' ;;
        *) die "consent" '"consent verdict unreadable"' ;;
    esac

    local result rc=0
    result=$(perl -e 'alarm shift; exec @ARGV' "$SEND_TIMEOUT" \
        "$OSASCRIPT" -s s "$script_path" "$bundle_id" "$@" 2>&1) || rc=$?

    if [[ $rc -eq 0 ]]; then
        audit "$script_path" true "${#result}"
        printf '{"ok":true,"verdict":"granted","result":%s}\n' "$(printf '%s' "$result" | json_string)"
    else
        audit "$script_path" false 0
        printf '{"ok":false,"stage":"send","rc":%d,"error":%s}\n' "$rc" "$(printf '%s' "$result" | json_string)"
        exit "$rc"
    fi
}

main "$@"
