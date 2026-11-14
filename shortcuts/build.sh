#!/usr/bin/env bash
# build.sh: rebuilds every shortcut of this folder in the Shortcuts library, which iCloud syncs to the iPhone
# build.sh <source.cherri>: compiles, signs, and adds that one shortcut
set -euo pipefail

# --- [CONSTANTS] --------------------------------------------------------------------------

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly here
readonly edit="${here}/library-edit.cherri"
readonly token='op://Tokens/NTFY_BUTTON_TOKEN/token'
out="$(mktemp -d)"
readonly out
trap 'rm -r "${out}"' EXIT

# --- [OPERATIONS] -------------------------------------------------------------------------

named() { rg --no-filename --only-matching --replace '$1' '^#define name (.+)$' "$@"; }

# press <process> <text> <label>: presses control <label> of the window of <process> showing <text>
press() {
    local control
    control="$(watch-apps read "$1" | jq --raw-output --arg text "$2" --arg label "$3" '
        first(.. | objects | select(has("controls")) | select(tostring | contains($text))
            | .controls[] | select(.label == $label) | .id) // empty')"
    [[ -z "${control}" ]] || watch-apps perform "${control}" AXPress >/dev/null
}

# approve <shortcut> <label>: runs <shortcut> on stdin and presses <label> on the one prompt naming it
approve() {
    { shortcuts run "$1" <&3 & } 3<&0
    sleep 2
    press "$(pgrep -x ShortcutsViewService)" "$1" "$2"
    wait "$!"
}

add() {
    local name signed
    name="$(named "$1")"
    signed="${out}/${name}.shortcut"
    cp "$1" "${out}/source.cherri"
    (cd "${out}" && cherri source.cherri --no-ansi --derive-uuids --skip-sign)
    shortcuts sign --mode anyone --input "${out}/${name}_unsigned.shortcut" --output "${signed}"
    watch-apps quit com.apple.shortcuts >/dev/null
    watch-apps launch com.apple.shortcuts --document "${signed}" >/dev/null
    sleep 2
    press com.apple.shortcuts "More, ${name}" 'Add Shortcut'
    sleep 1
    shortcuts list | rg --quiet --line-regexp --fixed-strings "${name}"
    printf '%s\n' "${name}"
}

# --- [COMPOSITION] ------------------------------------------------------------------------

if (($#)); then
    add "$1"
    exit
fi
add "${edit}"
jq --null-input --rawfile token <(op read "${token}") --rawfile names <(named "${here}"/*.cherri) \
    '{token: ($token | rtrimstr("\n")), delete: ($names | split("\n") | map(select(. != "")))}' |
    approve "$(named "${edit}")" Delete
fd --extension cherri --exclude "$(basename "${edit}")" --threads 1 . "${here}" --exec "$0"
