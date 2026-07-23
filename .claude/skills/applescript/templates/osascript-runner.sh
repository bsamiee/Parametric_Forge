#!/usr/bin/env bash
# Title    : osascript-runner
# Purpose  : Drive an OSA payload with argv-only data under a timeout budget, one JSON stdout
#            envelope, and a hash-only audit row.
# Contract : runner <bundle-id> <script-path> [data-arg ...]
#            stdout carries exactly one JSON object; every diagnostic rides stderr.
# Replace  : <AUDIT_LOG>, <AUDIT_FIELDS>.
set -euo pipefail

readonly OSASCRIPT=/usr/bin/osascript
readonly PYTHON3=/usr/bin/python3
readonly SHASUM=/usr/bin/shasum
readonly AUDIT_LOG="${AUTOMATION_AUDIT_LOG:-<AUDIT_LOG>}"
readonly SEND_TIMEOUT="${AUTOMATION_SEND_TIMEOUT:-45}"

die() {
    printf '{"ok":false,"stage":"%s","reason":%s}\n' "$1" "$2"
    exit 1
}

json_string() {
    "$PYTHON3" -c 'import json,sys;print(json.dumps(sys.stdin.read()))'
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

    local result rc=0
    result=$(perl -e 'alarm shift; exec @ARGV' "$SEND_TIMEOUT" \
        "$OSASCRIPT" "$script_path" "$bundle_id" "$@" 2>&1) || rc=$?

    if [[ $rc -eq 0 ]]; then
        audit "$script_path" true "${#result}"
        printf '{"ok":true,"result":%s}\n' "$(printf '%s' "$result" | json_string)"
    else
        audit "$script_path" false 0
        printf '{"ok":false,"stage":"send","rc":%d,"error":%s}\n' "$rc" "$(printf '%s' "$result" | json_string)"
        exit "$rc"
    fi
}

main "$@"
