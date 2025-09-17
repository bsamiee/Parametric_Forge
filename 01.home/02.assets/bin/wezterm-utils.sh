#!/usr/bin/env bash
# Title         : wezterm-utils.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/02.assets/bin/wezterm-utils.sh
# ----------------------------------------------------------------------------
# Helper commands for coordinating WezTerm CLI actions and yabai integration.

set -euo pipefail

: "${WEZTERM_BIN:=wezterm}"
: "${WEZTERM_UTILS_BIN:=${0##*/}}" # Self-reference for consistency
: "${WEZTERM_UTILS_DISABLE_YABAI:=0}"
: "${WEZTERM_UTILS_VERBOSE:=0}"

log() {
    if [[ ${WEZTERM_UTILS_VERBOSE} == "1" ]]; then
        printf 'wezterm-utils: %s\n' "$*" >&2
    fi
}

die() {
    printf 'wezterm-utils: %s\n' "$*" >&2
    exit 1
}

require_wezterm() {
    command -v "${WEZTERM_BIN}" >/dev/null 2>&1 || die "WezTerm CLI not found (set WEZTERM_BIN)."
}

sanitize_label() {
    local input trimmed
    input="${1:-}"
    trimmed="${input%/}"
    [[ -n ${trimmed} ]] || trimmed="workspace"
    trimmed="${trimmed// /-}"
    trimmed="${trimmed//[^[:alnum:]-]/-}"
    trimmed="${trimmed##-}"
    trimmed="${trimmed%%-}"
    [[ -n ${trimmed} ]] || trimmed="workspace"
    printf '%s' "${trimmed:0:32}"
}

yabai_available() {
    [[ ${WEZTERM_UTILS_DISABLE_YABAI} == "1" ]] && return 1
    command -v yabai >/dev/null 2>&1
}

yabai_cmd() {
    if yabai_available; then
        if ! yabai "$@" 2>/dev/null; then
            log "Warning: yabai command failed: $*"
            return 1
        fi
    else
        return 0
    fi
}

usage() {
    cat <<'EOF'
Usage: wezterm-utils <command> [args]

Commands:
  spawn-workspace <name> [cwd]   Spawn new tab in workspace (defaults cwd to $PWD).
  switch-workspace <name>        Switch active WezTerm workspace.
  space-label <label>            Label current yabai space (no-op if yabai absent).
  focus-space <label>            Focus yabai space by label (no-op if yabai absent).
  workspace-change <name>        Internal helper: focus yabai space matching workspace.

Environment:
  WEZTERM_BIN                    Override wezterm binary (default: wezterm).
  WEZTERM_UTILS_BIN              Self-reference for this utility.
  WEZTERM_UTILS_DISABLE_YABAI    Set to 1 to skip yabai actions.
  WEZTERM_UTILS_VERBOSE          Set to 1 for debug logging.
EOF
}

main() {
    local cmd
    cmd="${1:-}"
    shift || true

    case "${cmd}" in
    spawn-workspace)
        require_wezterm
        local workspace cwd
        workspace="${1:-}"
        [[ -n ${workspace} ]] || die "spawn-workspace requires a workspace name."
        shift || true
        cwd="${1:-$PWD}"
        log "Spawning workspace '${workspace}' at '${cwd}'."
        "${WEZTERM_BIN}" cli spawn --workspace "${workspace}" --cwd "${cwd}"
        if yabai_available; then
            log "Focusing yabai space '${workspace}'."
            if ! yabai_cmd -m space --focus "${workspace}"; then
                log "Note: Could not focus yabai space '${workspace}' (may not exist yet)"
            fi
        fi
        ;;
    switch-workspace)
        require_wezterm
        local workspace
        workspace="${1:-}"
        [[ -n ${workspace} ]] || die "switch-workspace requires a workspace name."
        log "Switching workspace to '${workspace}'."
        "${WEZTERM_BIN}" cli switch-workspace --workspace "${workspace}"
        if yabai_available; then
            log "Focusing yabai space '${workspace}'."
            if ! yabai_cmd -m space --focus "${workspace}"; then
                log "Note: Could not focus yabai space '${workspace}' (may not exist yet)"
            fi
        fi
        ;;
    space-label)
        local label
        label="${1:-}"
        [[ -n ${label} ]] || die "space-label requires a label."
        label="$(sanitize_label "${label}")"
        if yabai_available; then
            log "Labelling yabai space as '${label}'."
            if ! yabai_cmd -m space --label "${label}"; then
                log "Note: Could not label space '${label}' (space may not exist)"
            fi
        fi
        ;;
    focus-space)
        local label
        label="${1:-}"
        [[ -n ${label} ]] || die "focus-space requires a label."
        label="$(sanitize_label "${label}")"
        if yabai_available; then
            log "Focusing yabai space '${label}'."
            if ! yabai_cmd -m space --focus "${label}"; then
                log "Note: Could not focus yabai space '${label}' (may not exist)"
            fi
        fi
        ;;
    workspace-change)
        local workspace
        workspace="${1:-}"
        [[ -n ${workspace} ]] || die "workspace-change requires a workspace name."
        workspace="$(sanitize_label "${workspace}")"
        if yabai_available; then
            log "WezTerm workspace change -> focusing yabai space '${workspace}'."
            if ! yabai_cmd -m space --focus "${workspace}"; then
                log "Note: Could not focus yabai space '${workspace}' (creating new space if needed)"
                # Try to create and label a new space if focus failed
                yabai_cmd -m space --create 2>/dev/null || true
                yabai_cmd -m space --label "${workspace}" 2>/dev/null || true
                yabai_cmd -m space --focus "${workspace}" 2>/dev/null || true
            fi
        fi
        ;;
    help | -h | --help | "")
        usage
        ;;
    *)
        usage >&2
        die "Unknown command '${cmd}'."
        ;;
    esac
}

main "$@"
