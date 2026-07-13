#!/usr/bin/env bash
# Title    : hardened-osascript-runner
# Purpose  : Drive an OSA payload through a silent TCC consent preflight, argv-only
#            data, a JSON stdout envelope, a timeout budget, and a hash-only audit row.
# Contract : runner <bundle-id> <script-path> [data-arg ...]
#            stdout carries exactly one JSON object; every diagnostic rides stderr.
# Replace  : <AUDIT_LOG> destination, the <EVENT_CLASS>/<EVENT_ID> the payload sends.
set -euo pipefail

readonly OSASCRIPT=/usr/bin/osascript
readonly SHASUM=/usr/bin/shasum
readonly AUDIT_LOG="${AUTOMATION_AUDIT_LOG:-${TMPDIR:-/tmp}/automation-audit.log}"
readonly PREFLIGHT_TIMEOUT="${AUTOMATION_PREFLIGHT_TIMEOUT:-20}"
readonly SEND_TIMEOUT="${AUTOMATION_SEND_TIMEOUT:-45}"
# typeWildCard 0x2A2A2A2A ('****') tests broad automation of the target.
readonly EVENT_CLASS="${AUTOMATION_EVENT_CLASS:-0x2A2A2A2A}"
readonly EVENT_ID="${AUTOMATION_EVENT_ID:-0x2A2A2A2A}"

die() {
    printf '{"ok":false,"stage":"%s","reason":%s}\n' "$1" "$2"
    exit 1
}

# Silent consent verdict from the exact binary that will later automate. The embedded JXA binds
# AEDeterminePermissionToAutomateTarget through the ObjC bridge, passing the target descriptor pointer,
# so askUserIfNeeded stays false and no prompt raises; the perl alarm bounds the call, and JXA prints the raw JSON return (no -s s, which would quote it).
preflight() {
    local bundle_id=$1
    perl -e 'alarm shift; exec @ARGV' "$PREFLIGHT_TIMEOUT" \
        "$OSASCRIPT" -l JavaScript - "$bundle_id" "$EVENT_CLASS" "$EVENT_ID" <<'JXA'
ObjC.import('Foundation')
ObjC.import('CoreServices')
ObjC.bindFunction('AEDeterminePermissionToAutomateTarget', ['int', ['pointer', 'unsigned int', 'unsigned int', 'bool']])

function run(argv) {
  const [bundleID, klass, ident] = argv
  // A non-running target surfaces as procNotFound (-600) from the C call, not a nil descriptor.
  const target = $.NSAppleEventDescriptor.descriptorWithBundleIdentifier(bundleID)
  const status = $.AEDeterminePermissionToAutomateTarget(target.aeDesc, parseInt(klass, 16), parseInt(ident, 16), false)
  const verdict = { 0: 'granted', '-1743': 'denied', '-1744': 'undecided', '-600': 'target-not-running' }[String(status)] || 'failed'
  return JSON.stringify({ verdict, status })
}
JXA
}

# One SHA-256 of the source, a bounded preview, the success bit, and the result length.
# The secret-bearing body never reaches the log.
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
    verdict=$(printf '%s' "$verdict_json" | /usr/bin/plutil -extract verdict raw -o - - 2>/dev/null || printf 'failed')

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
        printf '{"ok":true,"verdict":"granted","result":%s}\n' "$(printf '%s' "$result" | python3 -c 'import json,sys;print(json.dumps(sys.stdin.read()))')"
    else
        audit "$script_path" false 0
        printf '{"ok":false,"stage":"send","rc":%d,"error":%s}\n' "$rc" "$(printf '%s' "$result" | python3 -c 'import json,sys;print(json.dumps(sys.stdin.read()))')"
        exit "$rc"
    fi
}

main "$@"
