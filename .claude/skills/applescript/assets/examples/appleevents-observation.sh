#!/usr/bin/env bash
# Pattern : The three Apple Event observation rails, each distinct. The com.apple.appleevents
#           unified-log carries send/receive descriptors system-wide; AEDebug* instruments only
#           a process the harness launches; eslogger tcc_modify watches consent-state changes,
#           because Endpoint Security models no per-AESend event. Attribution binds to the audit
#           token, not the recycled PID.
# Usage   : appleevents-observation.sh <traffic|taps <script>|consent|attribution>
set -euo pipefail

readonly LOG=/usr/bin/log
readonly OSASCRIPT=/usr/bin/osascript

# System-wide send and receive descriptors for processes the harness does not spawn.
traffic() {
    "$LOG" stream --debug --predicate 'subsystem == "com.apple.appleevents"'
}

# Per-process taps: the env vars attach only to a process this shell launches. A Finder-launched
# applet needs a wrapper launch or a launchd environment; terminal osascript inherits directly.
taps() {
    local script=$1
    AEDebugSends=1 AEDebugReceives=1 "$OSASCRIPT" -sse "$script" 2>&1
}

# Consent-state changes: the write to the TCC database recording a grant or revocation of
# kTCCServiceAppleEvents. es_event_tcc_modify_t observes decision changes, not per-event access.
consent() {
    sudo /usr/bin/eslogger tcc_modify | /usr/bin/grep AppleEvents
}

# The binary actually charged for a request — the identity that receives the entitlement, usage
# string, and remediation copy — not the calling source line.
attribution() {
    "$LOG" stream --debug --predicate 'subsystem == "com.apple.TCC" AND eventMessage BEGINSWITH "AttributionChain"'
}

main() {
    local verb=${1:-traffic}
    case $verb in
        traffic) traffic ;;
        taps)
            [[ $# -eq 2 ]] || {
                printf 'usage: taps <script>\n' >&2
                exit 64
            }
            taps "$2"
            ;;
        consent) consent ;;
        attribution) attribution ;;
        *)
            printf 'usage: appleevents-observation.sh <traffic|taps <script>|consent|attribution>\n' >&2
            exit 64
            ;;
    esac
}

main "$@"
