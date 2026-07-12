#!/usr/bin/env bash
# Shared stale-reclaiming directory-lock protocol for fleet ledger writers; callers own LOCK, REAPER, STALE_SECONDS, and ownership state.

_normalize_decimal() {
    local -r raw="$1" max_digits="$2" target="$3"
    [[ "${raw}" =~ ^[0-9]+$ && ${#raw} -le max_digits ]] || return 1
    printf -v "${target}" '%d' "$((10#${raw}))"
}

_path_epoch() {
    REPLY="$(stat -c %Y -- "$1" 2>/dev/null)" || REPLY="$(stat -f %m -- "$1" 2>/dev/null)" || return 1
    _normalize_decimal "${REPLY}" 18 REPLY
}

_read_record() {
    REPLY=""
    IFS= read -r REPLY 2>/dev/null <"$1"
}

_record_is_stale() {
    local -r path="$1" record="$2"
    local epoch="" pid="" raw_epoch=""
    if [[ "${record}" =~ ^([0-9]{1,18})[[:space:]]([1-9][0-9]{0,9})$ ]]; then
        raw_epoch="${BASH_REMATCH[1]}"
        pid="${BASH_REMATCH[2]}"
        _normalize_decimal "${raw_epoch}" 18 epoch || return 1
        ((epoch <= EPOCHSECONDS)) || return 1
        kill -0 "${pid}" 2>/dev/null && return 1
        return 0
    fi
    _path_epoch "${path}" || return 1
    ((REPLY <= EPOCHSECONDS && EPOCHSECONDS - REPLY > STALE_SECONDS))
}

_reap_stale_reaper() {
    local owner_record="" current_record=""
    if [[ ! -e "${REAPER}/owner" ]]; then
        _path_epoch "${REAPER}" || return 1
        ((REPLY <= EPOCHSECONDS && EPOCHSECONDS - REPLY > STALE_SECONDS)) || return 1
        rmdir -- "${REAPER}" 2>/dev/null
        return
    fi
    _read_record "${REAPER}/owner" || return 1
    owner_record="${REPLY}"
    _record_is_stale "${REAPER}/owner" "${owner_record}" || return 1
    _read_record "${REAPER}/owner" || return 1
    current_record="${REPLY}"
    [[ "${current_record}" == "${owner_record}" ]] || return 1
    rm -- "${REAPER}/owner" 2>/dev/null || return 1
    rmdir -- "${REAPER}" 2>/dev/null
}

_claim_reaper() {
    local -i attempt
    for ((attempt = 0; attempt < 2; attempt++)); do
        if mkdir -- "${REAPER}" 2>/dev/null; then
            REAPER_TOKEN="${EPOCHSECONDS} $$"
            if printf '%s\n' "${REAPER_TOKEN}" >"${REAPER}/owner"; then
                reaper_owned=1
                return 0
            fi
            REAPER_TOKEN=""
            rmdir -- "${REAPER}" 2>/dev/null || true
        fi
        _reap_stale_reaper || true
    done
    return 1
}

_release_reaper() {
    local owner_record=""
    _read_record "${REAPER}/owner" || return 1
    owner_record="${REPLY}"
    [[ -n "${REAPER_TOKEN}" && "${owner_record}" == "${REAPER_TOKEN}" ]] || return 1
    rm -- "${REAPER}/owner" 2>/dev/null || return 1
    rmdir -- "${REAPER}" 2>/dev/null || return 1
    reaper_owned=0
    REAPER_TOKEN=""
}

_reap_stale_lock() {
    local owner_record="" current_record=""
    if [[ -e "${LOCK}/owner" ]]; then
        _read_record "${LOCK}/owner" || return 1
        owner_record="${REPLY}"
        _record_is_stale "${LOCK}/owner" "${owner_record}" || return 1
    else
        _path_epoch "${LOCK}" || return 1
        ((REPLY <= EPOCHSECONDS && EPOCHSECONDS - REPLY > STALE_SECONDS)) || return 1
    fi
    _claim_reaper || return 1
    if [[ -e "${LOCK}/owner" ]]; then
        _read_record "${LOCK}/owner" || REPLY=""
        current_record="${REPLY}"
        [[ -n "${owner_record}" && "${current_record}" == "${owner_record}" ]] || {
            _release_reaper || true
            return 1
        }
    elif [[ -n "${owner_record}" ]]; then
        _release_reaper || true
        return 1
    fi
    rm -rf -- "${LOCK}" 2>/dev/null || true
    _release_reaper || true
}

_release_lock() {
    local owner_record=""
    _read_record "${LOCK}/owner" || return 1
    owner_record="${REPLY}"
    [[ -n "${LOCK_TOKEN}" && "${owner_record}" == "${LOCK_TOKEN}" ]] || return 1
    rm -- "${LOCK}/owner" 2>/dev/null || return 1
    rmdir -- "${LOCK}" 2>/dev/null || return 1
    lock_owned=0
    LOCK_TOKEN=""
}

_acquire_lock() {
    local -i attempt
    for ((attempt = 0; attempt < 100; attempt++)); do
        if mkdir -- "${LOCK}" 2>/dev/null; then
            LOCK_TOKEN="${EPOCHSECONDS} $$"
            if { printf '%s\n' "${LOCK_TOKEN}"; } 2>/dev/null >"${LOCK}/owner"; then
                lock_owned=1
                return 0
            fi
            LOCK_TOKEN=""
            rmdir -- "${LOCK}" 2>/dev/null || true
        fi
        _reap_stale_lock || true
        sleep 0.01
    done
    return 1
}
