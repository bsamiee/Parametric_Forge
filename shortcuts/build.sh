#!/usr/bin/env bash
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

press() {
    local control
    control="$(watch-apps read "$1" | jq --raw-output --arg text "$2" --arg label "$3" '
        first(.. | objects | select(has("controls")) | select(tostring | contains($text))
            | .controls[] | select(.label == $label) | .id) // empty')"
    [[ -n "${control}" ]] && watch-apps perform "${control}" AXPress >/dev/null
}

approve() {
    { shortcuts run "$1" <&3 & } 3<&0
    sleep 2
    press "$(pgrep -x ShortcutsViewService)" "$1" "$2" || true
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
    press com.apple.shortcuts "More, ${name}" 'Add Shortcut' ||
        { sleep 3 && press com.apple.shortcuts "More, ${name}" 'Add Shortcut'; } ||
        { sleep 5 && press com.apple.shortcuts "More, ${name}" 'Add Shortcut'; } ||
        { printf '%s: no import window within 10 seconds, run build.sh again\n' "${name}" >&2 && exit 1; }
    sleep 1
    shortcuts list | rg --line-regexp --fixed-strings "${name}"
}

# --- [COMPOSITION] ------------------------------------------------------------------------

if (($#)); then
    add "$1"
    exit
fi
add "${edit}"
jq --null-input --rawfile token <(op read "${token}") --rawfile names <(named "${here}"/*.cherri) \
    '{token: ($token | rtrimstr("\n")), delete: ($names | split("\n") | map(select(. != "")))}' |
    approve "$(named "${edit}")" Delete >/dev/null
fd --extension cherri --exclude "$(basename "${edit}")" --threads 1 . "${here}" --exec "$0"
