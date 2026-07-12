#!/usr/bin/env bash
# SessionStart hook: persist session credentials + tool PATH for sub-agents.
# Canonical across all repos, owned by Parametric_Forge. Two lanes keep the
# network out of the hook budget: a session with a warm cache REPLAYS it into
# CLAUDE_ENV_FILE instantly and dispatches a detached `--refresh`; the refresh
# lane (or a cold first boot, inline) resolves Doppler and rewrites the cache
# for the next session. Doppler-first: each DOPPLER_SOURCES row resolves
# independently — live fetch refreshes its encrypted snapshot under the
# doppler cache; a failed fetch serves the snapshot; a dead row is loud and
# names the keys it owes (names only, never values).
# Row shape 'project:config:snapshot[:TOKEN_ENV_VAR]': the token var names a
# config-scoped Doppler service token once the secret rail installs one; empty
# or unset means ambient CLI auth; a degraded token attempt retries ambient.
# Per-project extras: CLAUDE_ENV_EXPORT_KEYS (comma/space list) and
# CLAUDE_TOOL_PATHS (colon list). CLAUDE_DOPPLER_OFFLINE=1 forces fallback-only.
set -Eeuo pipefail
# GUI/TUI launch contexts can resolve `env bash` to Apple Bash 3.2, which rejects inherit_errexit below; re-exec through the per-user profile Bash 5.
profile_user="${USER:-${LOGNAME:-}}"
if ((BASH_VERSINFO[0] < 5)) && [[ -n "$profile_user" && -x "/etc/profiles/per-user/${profile_user}/bin/bash" ]]; then
    exec "/etc/profiles/per-user/${profile_user}/bin/bash" "$0" "$@"
fi

# The raw byte-copied hook re-enters its packaged owner so every host receives the same Bash and dependency closure even from a minimal GUI PATH.
if [[ -z "${_FORGE_SETUP_ENV_OWNER:-}" ]]; then
    setup_env_owner="$(command -v forge-setup-env 2>/dev/null || true)"
    [[ -x "$setup_env_owner" || -z "$profile_user" ]] || setup_env_owner="/etc/profiles/per-user/${profile_user}/bin/forge-setup-env"
    [[ -x "$setup_env_owner" || -z "${HOME:-}" ]] || setup_env_owner="${HOME}/.nix-profile/bin/forge-setup-env"
    if [[ -x "$setup_env_owner" && ! "$setup_env_owner" -ef "$0" ]]; then
        export _FORGE_SETUP_ENV_OWNER=1
        exec "$setup_env_owner" "$@"
    fi
fi
((BASH_VERSINFO[0] >= 5)) || exit 0

# One outer deadline owns cold resolution and detached refresh alike; individual Doppler request budgets remain narrower inner bounds.
setup_env_timeout="$(command -v timeout 2>/dev/null || true)"
[[ -x "$setup_env_timeout" || -z "$profile_user" ]] || setup_env_timeout="/etc/profiles/per-user/${profile_user}/bin/timeout"
[[ -x "$setup_env_timeout" || -z "${HOME:-}" ]] || setup_env_timeout="${HOME}/.nix-profile/bin/timeout"
if [[ -z "${_FORGE_SETUP_ENV_DEADLINE_ACTIVE:-}" && -x "$setup_env_timeout" ]]; then
    setup_env_deadline="${FORGE_SETUP_ENV_DEADLINE_SECONDS:-45}"
    if [[ ! "$setup_env_deadline" =~ ^[1-9][0-9]{0,2}$ ]] || ((10#$setup_env_deadline > 300)); then
        printf 'setup-env: FORGE_SETUP_ENV_DEADLINE_SECONDS must be 1..300\n' >&2
        exit 2
    fi
    setup_env_deadline="$((10#$setup_env_deadline))"
    export _FORGE_SETUP_ENV_DEADLINE_ACTIVE=1
    exec "$setup_env_timeout" -k 5 "$setup_env_deadline" "$0" "$@"
fi
shopt -s inherit_errexit
IFS=$'\n\t'
# Every artifact this hook writes is secret-adjacent: resolver dumps, retry side files, stderr captures, key manifests. One umask owns their mode.
umask 077

# --- [CONSTANTS] ------------------------------------------------------------------------

readonly JUPYTER_TOKEN_CACHE="${HOME}/.config/jupyter/forge-token.env"
readonly DOPPLER_CACHE_DIR="${CLAUDE_DOPPLER_CACHE_DIR:-${HOME}/.cache/doppler}"
readonly SESSION_CACHE_DIR="${XDG_CACHE_HOME:-${HOME}/.cache}/forge-secrets"
readonly SESSION_CACHE="${SESSION_CACHE_DIR}/session-env.sh"
readonly REFRESH_LOCK="${SESSION_CACHE_DIR}/.refresh.lock"
readonly DOPPLER_OFFLINE="${CLAUDE_DOPPLER_OFFLINE:-0}"
_stale_days="${CLAUDE_DOPPLER_STALE_DAYS:-14}"
[[ "${_stale_days}" =~ ^[0-9]{1,5}$ ]] || _stale_days=14
_stale_days="$((10#${_stale_days}))"
readonly SNAPSHOT_STALE_DAYS="${_stale_days}"
declare -ra DOPPLER_SOURCES=(
    'agent-runtime:dev:agent-runtime.json:DOPPLER_TOKEN_AGENT_RUNTIME'
    'parametric-forge:dev_machine:forge-machine.json:DOPPLER_TOKEN_FORGE_MACHINE'
    'maghz:prd_host:maghz-host.json:DOPPLER_TOKEN_MAGHZ_HOST'
)
# Non-hook snapshots that live in the doppler cache dir (fleet-owned rows).
declare -ra SNAPSHOT_KEEP=('doppler-mcp.json')
declare -ra _ENV_KEYS=(
    EXA_API_KEY PERPLEXITY_API_KEY TAVILY_API_KEY
    CONTEXT7_API_KEY GREPTILE_API_KEY CODERABBIT_API_KEY
    GH_TOKEN GITHUB_TOKEN GH_PROJECTS_TOKEN
    HOSTINGER_TOKEN HOSTINGER_API_TOKEN CACHIX_AUTH_TOKEN RHINO_TOKEN
    OP_SERVICE_ACCOUNT_TOKEN GOOGLE_OAUTH_CLIENT_ID GOOGLE_OAUTH_CLIENT_SECRET
    MAGHZ_MCP__DATABASE_URI JUPYTER_TOKEN CLOUDSDK_CONFIG WORKSPACE_MCP_CREDENTIALS_DIR
    GOOGLE_WORKSPACE_CLI_CLIENT_ID GOOGLE_WORKSPACE_CLI_CLIENT_SECRET
    GOOGLE_WORKSPACE_CLI_CONFIG_DIR GOOGLE_WORKSPACE_PROJECT_ID
    MAGHZ_REMOTE_HOST MAGHZ_REMOTE_USER MAGHZ_REMOTE_WORKROOT
    NTFY_URL NTFY_TOPIC NTFY_TOKEN
)
readonly EXTRA_ENV_KEYS="${CLAUDE_ENV_EXPORT_KEYS:-}"
readonly TOOL_PATHS="${CLAUDE_TOOL_PATHS:-${HOME}/.local/bin}"
readonly ALLOW_MISSING_TOOL_PATHS="${CLAUDE_ALLOW_MISSING_TOOL_PATHS:-0}"
declare -a _TMP_FILES=()
declare -a _RECEIPT=()
declare -a _ALERTS=()
_MATERIAL=0

# --- [OPERATIONS] -----------------------------------------------------------------------

_mtime() {
    # Fractional seconds: a refresh inside the same wall-clock second must still classify live.
    # Shape-validated per stat flavor — GNU stat reads BSD's '-f %Fm' as a file operand, emitting multiline junk.
    local m
    m="$(stat -f %Fm "$1" 2>/dev/null)" || m=""
    [[ "${m}" =~ ^[0-9]+(\.[0-9]+)?$ ]] || { m="$(stat -c %.9Y "$1" 2>/dev/null)" || m=""; }
    [[ "${m}" =~ ^[0-9]+(\.[0-9]+)?$ ]] || m=0
    printf '%s\n' "${m}"
}

_newer() {
    awk -v a="$1" -v b="$2" 'BEGIN { exit !(b > a) }'
}

_join() {
    local IFS=' '
    printf '%s' "$*"
}

_fetch() {
    local -r project="$1" config="$2" snap="$3" token="$4" out="$5"
    # Request budget sits inside the hook timeout: a stalled API degrades to the snapshot, never kills emission.
    # --no-cache forces a full fetch so every live success rewrites the snapshot — the mtime advance IS the live verdict, where a cache-served read would fake it.
    # --format json is parsed, never sourced, so secret bytes never reach the shell parser; the snapshot holds json for offline.
    local -a flags=(--fallback "${snap}" --no-cache --timeout 3s)
    [[ "${DOPPLER_OFFLINE}" != "1" ]] || flags+=(--fallback-only)
    if [[ -n "${token}" ]]; then
        DOPPLER_TOKEN="${token}" doppler secrets download --project "${project}" --config "${config}" \
            --no-file --format json --attempts 1 "${flags[@]}" >"${out}" 2>>"${out}.err"
    else
        # env -u: an ambient DOPPLER_TOKEN outranks --project/--config and cannot represent three configs; strip it so each fetch resolves its named source.
        env -u DOPPLER_TOKEN doppler secrets download --project "${project}" --config "${config}" \
            --no-file --format json --attempts 1 "${flags[@]}" >"${out}" 2>>"${out}.err"
    fi
}

_classify() {
    local -r rc="$1" pre="$2" post="$3"
    if ((rc != 0)); then
        echo dead
    elif [[ "${DOPPLER_OFFLINE}" == "1" ]]; then
        echo snapshot
    elif _newer "${pre}" "${post}"; then
        echo live
    else echo snapshot; fi
}

_resolve_source() {
    # Background worker: writes ${out} (env dump), ${out}.err, and ${out}.meta
    # (outcome|keys|age_days|auth|reason), and refreshes the per-source key-name manifest a dead row is reported against.
    local -r spec="$1" out="$2"
    local project config snapshot tokenvar
    IFS=: read -r project config snapshot tokenvar < <(printf '%s\n' "${spec}")
    local -r snap="${DOPPLER_CACHE_DIR}/${snapshot}"
    local token="" auth=cli
    if [[ -n "${tokenvar}" && -n "${!tokenvar:-}" ]]; then
        token="${!tokenvar}"
        auth=token
    fi
    local pre post rc=0 outcome
    pre="$(_mtime "${snap}")"
    _fetch "${project}" "${config}" "${snap}" "${token}" "${out}" || rc=$?
    post="$(_mtime "${snap}")"
    outcome="$(_classify "${rc}" "${pre}" "${post}")"
    if [[ "${auth}" == "token" && "${outcome}" != "live" ]]; then
        # Resilient rail: a degraded token attempt retries ambient CLI auth once into a side file, so a failed retry never clobbers served material.
        # Offline too — fallback decryption is passphrase-bound to the fetching auth, so only the ambient retry reads a CLI-written snapshot.
        # Blame lands on the token only when ambient disproves it: a live retry, or ambient material where the token lane died (Doppler never
        # serves fallback on 401/403/404, so a dead token lane IS auth). Snapshot-for-snapshot keeps auth=token — the snapshot alert covers it.
        local rc2=0 retry
        pre="${post}"
        _fetch "${project}" "${config}" "${snap}" "" "${out}.retry" || rc2=$?
        post="$(_mtime "${snap}")"
        retry="$(_classify "${rc2}" "${pre}" "${post}")"
        if [[ "${retry}" == "live" ]] || { [[ "${outcome}" == "dead" ]] && ((rc2 == 0)); }; then
            auth="token-failed-cli-served"
            outcome="${retry}"
            cat "${out}.retry.err" >>"${out}.err" 2>/dev/null || true
            mv -f "${out}.retry" "${out}"
        fi
        rm -f "${out}.retry" "${out}.retry.err"
    fi
    local nkeys=0 age=0 reason=""
    if [[ "${outcome}" == "dead" ]]; then
        : >"${out}"
        reason="$(tail -n1 "${out}.err" 2>/dev/null | sed -E $'s/\x1b\\[[0-9;]*m//g' || true)"
    else
        # One projection per snapshot: the keys manifest is the count's source.
        jq -r 'keys_unsorted[]' "${out}" >"${snap%.json}.keys.$$" 2>/dev/null || true
        nkeys="$(wc -l <"${snap%.json}.keys.$$" | tr -d ' ')"
        chmod 600 "${snap%.json}.keys.$$" 2>/dev/null || true
        mv -f "${snap%.json}.keys.$$" "${snap%.json}.keys" 2>/dev/null || rm -f "${snap%.json}.keys.$$"
        if [[ "${outcome}" == "snapshot" && -f "${snap}" ]]; then
            age=$(((EPOCHSECONDS - ${post%%.*}) / 86400))
        fi
    fi
    printf '%s|%s|%s|%s|%s\n' "${outcome}" "${nkeys}" "${age}" "${auth}" "${reason}" >"${out}.meta"
}

_prune_snapshots() {
    local f base row spec keep
    local -a expected=("${SNAPSHOT_KEEP[@]}") pruned=()
    for spec in "${DOPPLER_SOURCES[@]}"; do
        IFS=: read -r _ _ row _ < <(printf '%s\n' "${spec}")
        expected+=("${row}" "${row%.json}.keys")
    done
    # Prune only the file families this hook owns; doppler's own dot-prefixed fallback/metadata files and foreign material stay untouched.
    for f in "${DOPPLER_CACHE_DIR}"/*.json "${DOPPLER_CACHE_DIR}"/*.keys; do
        [[ -f "${f}" ]] || continue
        base="${f##*/}"
        keep=0
        for row in "${expected[@]}"; do
            [[ "${base}" != "${row}" ]] || {
                keep=1
                break
            }
        done
        ((keep == 1)) || {
            rm -f "${f}"
            pruned+=("${base}")
        }
    done
    ((${#pruned[@]} == 0)) || _RECEIPT+=("note  pruned orphan snapshots: $(_join "${pruned[@]}")")
}

_load_secrets() {
    local missing_cli=""
    command -v doppler >/dev/null 2>&1 || missing_cli="doppler"
    command -v jq >/dev/null 2>&1 || missing_cli="${missing_cli:+${missing_cli} }jq"
    if [[ -z "${missing_cli}" ]]; then
        mkdir -p "${DOPPLER_CACHE_DIR}"
        chmod 700 "${DOPPLER_CACHE_DIR}"
        local -a outs=() pids=()
        local spec out idx
        for spec in "${DOPPLER_SOURCES[@]}"; do
            out="$(mktemp "${TMPDIR:-/tmp}/doppler-env.XXXXXX")"
            outs+=("${out}")
            _TMP_FILES+=("${out}" "${out}.err" "${out}.meta")
            _resolve_source "${spec}" "${out}" &
            pids+=("$!")
        done
        for idx in "${!pids[@]}"; do
            wait "${pids[${idx}]}" || true
        done
        for idx in "${!outs[@]}"; do
            out="${outs[${idx}]}"
            local project config snapshot tokenvar label keysfile owed
            local outcome=dead nkeys=0 age=0 auth=none reason="resolver died"
            IFS=: read -r project config snapshot tokenvar < <(printf '%s\n' "${DOPPLER_SOURCES[${idx}]}")
            label="${project}/${config}"
            if [[ -f "${out}.meta" ]]; then
                IFS='|' read -r outcome nkeys age auth reason <"${out}.meta" || true
            fi
            if [[ "${outcome}" != "dead" && -s "${out}" ]]; then
                _MATERIAL=1
                # NUL-delimited literal assignment, never source/eval: Doppler's env escaping is server-side and unproven shell-safe,
                # so secret bytes never reach the parser; jq decodes json exactly.
                local k v
                while IFS= read -r -d '' k && IFS= read -r -d '' v; do
                    [[ "${k}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || continue
                    printf -v "${k}" '%s' "${v}"
                    # shellcheck disable=SC2163  # Exports the named key assigned above.
                    export "${k}"
                done < <(jq -j 'to_entries[] | "\(.key)\u0000\(.value)\u0000"' "${out}" 2>/dev/null || true)
            fi
            [[ "${auth}" != "token-failed-cli-served" ]] ||
                _ALERTS+=("setup-env: ${label} service token failed; ambient CLI auth served (${tokenvar:-unset})")
            case "${outcome}" in
                live)
                    _RECEIPT+=("ok    ${label} live keys=${nkeys} auth=${auth}")
                    ;;
                snapshot)
                    local stale=""
                    ((age < SNAPSHOT_STALE_DAYS)) || stale=" STALE"
                    _RECEIPT+=("warn  ${label} snapshot keys=${nkeys} age=${age}d auth=${auth}${stale}")
                    if [[ -n "${stale}" ]]; then
                        _ALERTS+=("setup-env: ${label} snapshot is STALE (${age}d >= ${SNAPSHOT_STALE_DAYS}d)")
                    elif [[ "${DOPPLER_OFFLINE}" != "1" ]]; then
                        _ALERTS+=("setup-env: ${label} live fetch failed; snapshot served (age ${age}d)")
                    fi
                    ;;
                *)
                    keysfile="${DOPPLER_CACHE_DIR}/${snapshot%.json}.keys"
                    owed="none-recorded"
                    if [[ -f "${keysfile}" ]]; then
                        owed="$(paste -sd' ' - <"${keysfile}")"
                    fi
                    _RECEIPT+=("DEAD  ${label} reason: ${reason:-unknown}; owed keys: ${owed}")
                    _ALERTS+=("setup-env: ${label} DEAD (${reason:-unknown}); owed keys: ${owed}")
                    ;;
            esac
        done
        _prune_snapshots
    else
        _RECEIPT+=("DEAD  CLI absent from PATH: ${missing_cli}")
        _ALERTS+=("setup-env: ${missing_cli} absent — secrets rail down")
    fi
    [[ "${DOPPLER_OFFLINE}" != "1" ]] || _RECEIPT+=("note  offline mode: fallback-only fetches")
    if [[ -z "${JUPYTER_TOKEN:-}" && -f "${JUPYTER_TOKEN_CACHE}" ]]; then
        # shellcheck source=/dev/null  # Nix-owned local Jupyter token; not a Doppler-managed key.
        source "${JUPYTER_TOKEN_CACHE}" || true
    fi
    local key
    local -a unresolved=()
    for key in "${_ENV_KEYS[@]}"; do
        [[ -n "${!key:-}" ]] || unresolved+=("${key}")
    done
    ((${#unresolved[@]} == 0)) || _RECEIPT+=("warn  unresolved keys: $(_join "${unresolved[@]}")")
}

_emit_env_key() {
    local -r key="$1"
    [[ "${key}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || return 0
    [[ -n "${!key:-}" ]] || return 0
    printf 'export %s=%q\n' "${key}" "${!key}"
}

_emit_extra_env_keys() {
    [[ -n "${EXTRA_ENV_KEYS}" ]] || return 0
    local -a keys=()
    local key
    IFS=$' \t' read -ra keys < <(printf '%s\n' "${EXTRA_ENV_KEYS//,/ }")
    for key in "${keys[@]}"; do
        _emit_env_key "${key}"
    done
}

_emit_tool_paths() {
    [[ -n "${TOOL_PATHS}" ]] || return 0
    local -a paths=() selected=()
    local path path_value
    IFS=: read -ra paths < <(printf '%s\n' "${TOOL_PATHS}")
    for path in "${paths[@]}"; do
        [[ -n "${path}" ]] || continue
        if [[ -d "${path}" || "${ALLOW_MISSING_TOOL_PATHS}" == "1" ]]; then
            selected+=("${path}")
        fi
    done
    ((${#selected[@]} > 0)) || return 0
    printf -v path_value '%s:' "${selected[@]}"
    # shellcheck disable=SC2016  # Single quotes intentional -- expand when Claude sources the env file.
    printf 'export PATH=%q":${PATH}"\n' "${path_value%:}"
}

# --- [PUBLISH] --------------------------------------------------------------------------

# Resolve Doppler, then publish: keys into CLAUDE_ENV_FILE (env mode only), the session cache on resolver material, and the key-name receipt.
# A total outage preserves the last good cache; a cache-less fresh machine still bootstraps from whatever emitted.
_resolve_and_publish() {
    local publish_env="$1" key
    _load_secrets
    local keys_tmp
    keys_tmp="$(mktemp "${TMPDIR:-/tmp}/claude-keys.XXXXXX")"
    _TMP_FILES+=("${keys_tmp}")
    {
        for key in "${_ENV_KEYS[@]}"; do
            _emit_env_key "${key}"
        done
        _emit_extra_env_keys
    } >"${keys_tmp}"

    if [[ "${publish_env}" == "env" ]]; then
        local env_tmp
        env_tmp="$(mktemp "${CLAUDE_ENV_FILE}.tmp.XXXXXX")"
        _TMP_FILES+=("${env_tmp}")
        {
            cat "${keys_tmp}"
            _emit_tool_paths
        } >"${env_tmp}"
        chmod 600 "${env_tmp}"
        mv "${env_tmp}" "${CLAUDE_ENV_FILE}"
    fi

    mkdir -p "${SESSION_CACHE_DIR}"
    chmod 700 "${SESSION_CACHE_DIR}"
    if [[ -s "${keys_tmp}" ]] && { ((_MATERIAL == 1)) || [[ ! -f "${SESSION_CACHE}" ]]; }; then
        local cache_tmp
        cache_tmp="$(mktemp "${SESSION_CACHE_DIR}/.session-env.XXXXXX")"
        _TMP_FILES+=("${cache_tmp}")
        cat "${keys_tmp}" >"${cache_tmp}"
        chmod 600 "${cache_tmp}"
        mv "${cache_tmp}" "${SESSION_CACHE}"
    fi

    # Receipt: key names only, never values. Full receipt to stderr + file; degraded rows also to stdout so the session context carries them loudly.
    local receipt_tmp
    receipt_tmp="$(mktemp "${SESSION_CACHE_DIR}/.receipt.XXXXXX")"
    _TMP_FILES+=("${receipt_tmp}")
    {
        printf 'setup-env %(%Y-%m-%dT%H:%M:%S)T offline=%s\n' "${EPOCHSECONDS}" "${DOPPLER_OFFLINE}"
        printf '%s\n' "${_RECEIPT[@]}"
    } >"${receipt_tmp}"
    chmod 600 "${receipt_tmp}"
    mv -f "${receipt_tmp}" "${SESSION_CACHE_DIR}/receipt"
    printf '%s\n' "${_RECEIPT[@]}" >&2
    ((${#_ALERTS[@]} == 0)) || printf '%s\n' "${_ALERTS[@]}"
}

# --- [ENTRY] ----------------------------------------------------------------------------

trap '[[ ${#_TMP_FILES[@]} -eq 0 ]] || rm -f "${_TMP_FILES[@]}"' EXIT
# Signal death reaps the parallel resolver workers before the EXIT cleanup.
_reap() {
    local pids
    pids="$(jobs -p)"
    # shellcheck disable=SC2086  # Intentional split: one PID per line under this IFS.
    [[ -z "${pids}" ]] || kill ${pids} 2>/dev/null || true
    [[ -z "${_LOCKED:-}" ]] || rm -rf "${REFRESH_LOCK}"
    exit "$((128 + $1))"
}
trap '_reap 1' HUP
trap '_reap 2' INT
trap '_reap 15' TERM

# Refresh lane: detached network resolve rewriting the cache for the NEXT session. Single-flight via lock dir; a stale lock (>3 min) is taken over.
if [[ "${1:-}" == "--refresh" ]]; then
    mkdir -p "${SESSION_CACHE_DIR}"
    chmod 700 "${SESSION_CACHE_DIR}"
    if ! mkdir "${REFRESH_LOCK}" 2>/dev/null; then
        [[ -n "$(find "${REFRESH_LOCK}" -maxdepth 0 -mmin +3 2>/dev/null)" ]] || exit 0
        rm -rf "${REFRESH_LOCK}"
        mkdir "${REFRESH_LOCK}" 2>/dev/null || exit 0
    fi
    _LOCKED=1
    trap 'rm -rf "${REFRESH_LOCK}"; [[ ${#_TMP_FILES[@]} -eq 0 ]] || rm -f "${_TMP_FILES[@]}"' EXIT
    _resolve_and_publish cache
    exit 0
fi

[[ -n "${CLAUDE_ENV_FILE:-}" ]] || exit 0
ENV_DIR="$(dirname -- "${CLAUDE_ENV_FILE}")"
readonly ENV_DIR
[[ -d "${ENV_DIR}" && -w "${ENV_DIR}" && ! -d "${CLAUDE_ENV_FILE}" ]] || exit 0

# Warm lane: replay the cache into the env file instantly — no network inside the hook budget — and dispatch the
# detached refresh (PATH-resolved nohup: /usr/bin is a Darwin fact and this hook runs on every host).
_replay_cache() {
    local env_tmp
    env_tmp="$(mktemp "${CLAUDE_ENV_FILE}.tmp.XXXXXX")"
    _TMP_FILES+=("${env_tmp}")
    {
        cat "${SESSION_CACHE}"
        _emit_extra_env_keys
        _emit_tool_paths
    } >"${env_tmp}"
    chmod 600 "${env_tmp}"
    mv "${env_tmp}" "${CLAUDE_ENV_FILE}"
    # Last refresh verdicts stay loud: degraded rows reach the session context.
    grep -E 'DEAD|STALE' "${SESSION_CACHE_DIR}/receipt" 2>/dev/null || true
}
if [[ -s "${SESSION_CACHE}" ]]; then
    _replay_cache
    printf 'setup-env: replay served from session cache; refresh dispatched\n' >&2
    (
        unset _FORGE_SETUP_ENV_DEADLINE_ACTIVE
        nohup "$0" --refresh >/dev/null 2>>"${SESSION_CACHE_DIR}/refresh.err" &
    )
    exit 0
fi

# Cold lane (first boot, no cache): resolve inline so the first session still receives keys. Concurrent cold sessions single-flight through the
# refresh lock: the loser polls for the winner's cache and replays it, resolving inline unlocked only when no cache lands inside the wait budget.
mkdir -p "${SESSION_CACHE_DIR}"
chmod 700 "${SESSION_CACHE_DIR}"
if mkdir "${REFRESH_LOCK}" 2>/dev/null; then
    _LOCKED=1
    trap 'rm -rf "${REFRESH_LOCK}"; [[ ${#_TMP_FILES[@]} -eq 0 ]] || rm -f "${_TMP_FILES[@]}"' EXIT
else
    for _ in {1..20}; do
        [[ -s "${SESSION_CACHE}" ]] && break
        sleep 0.5
    done
    if [[ -s "${SESSION_CACHE}" ]]; then
        _replay_cache
        printf 'setup-env: replay served from a concurrent resolver cache\n' >&2
        exit 0
    fi
fi
_resolve_and_publish env
