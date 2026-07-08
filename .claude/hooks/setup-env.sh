#!/usr/bin/env bash
# SessionStart hook: persist session credentials + tool PATH for sub-agents.
# Canonical across all repos, owned by Parametric_Forge. Doppler-first: pulls
# the agent, forge-machine, and maghz-host configs in parallel with encrypted
# offline fallback snapshots under ~/.cache/doppler; the 1Password cache loads
# only when Doppler yields nothing and CLAUDE_SECRET_BACKEND is 'transition'.
# Resolved keys land in CLAUDE_ENV_FILE so spawned sub-agents inherit them.
# Per-project extras: CLAUDE_ENV_EXPORT_KEYS (comma/space list) and
# CLAUDE_TOOL_PATHS (colon list). CLAUDE_DOPPLER_OFFLINE=1 forces fallback-only.
set -Eeuo pipefail
shopt -s inherit_errexit
IFS=$'\n\t'

# --- [CONSTANTS] --------------------------------------------------------------

readonly TOKEN_CACHE="${HOME}/.config/hm-op-session.sh"
readonly JUPYTER_TOKEN_CACHE="${HOME}/.config/jupyter/forge-token.env"
readonly DOPPLER_CACHE_DIR="${HOME}/.cache/doppler"
readonly SECRET_BACKEND="${CLAUDE_SECRET_BACKEND:-transition}"
readonly DOPPLER_OFFLINE="${CLAUDE_DOPPLER_OFFLINE:-0}"
declare -ra DOPPLER_SOURCES=(
    'arsenal-machine:dev_agent:agent-runtime.json'
    'parametric-forge:dev_machine:forge-machine.json'
    'maghz:prd_host:maghz-host.json'
)
declare -ra _ENV_KEYS=(
    EXA_API_KEY PERPLEXITY_API_KEY TAVILY_API_KEY SONAR_TOKEN
    CONTEXT7_API_KEY GREPTILE_API_KEY CODERABBIT_API_KEY
    GH_TOKEN GITHUB_TOKEN GH_PROJECTS_TOKEN
    HOSTINGER_TOKEN HOSTINGER_API_TOKEN CACHIX_AUTH_TOKEN RHINO_TOKEN
    OP_SERVICE_ACCOUNT_TOKEN GOOGLE_OAUTH_CLIENT_ID GOOGLE_OAUTH_CLIENT_SECRET
    MAGHZ_MCP__DATABASE_URI JUPYTER_TOKEN CLOUDSDK_CONFIG WORKSPACE_MCP_CREDENTIALS_DIR
    GOOGLE_WORKSPACE_CLI_CLIENT_ID GOOGLE_WORKSPACE_CLI_CLIENT_SECRET
    GOOGLE_WORKSPACE_CLI_CONFIG_DIR GOOGLE_WORKSPACE_CLI_CREDENTIALS_FILE GOOGLE_WORKSPACE_PROJECT_ID
    MAGHZ_REMOTE_HOST MAGHZ_REMOTE_USER MAGHZ_REMOTE_WORKROOT
)
readonly EXTRA_ENV_KEYS="${CLAUDE_ENV_EXPORT_KEYS:-}"
readonly TOOL_PATHS="${CLAUDE_TOOL_PATHS:-${HOME}/.cargo/bin:${HOME}/.local/bin}"
readonly ALLOW_MISSING_TOOL_PATHS="${CLAUDE_ALLOW_MISSING_TOOL_PATHS:-0}"
declare -a _TMP_FILES=()

# --- [OPERATIONS] -------------------------------------------------------------

_fetch_doppler_source() {
    local -r spec="$1" out="$2"
    local project config snapshot
    IFS=: read -r project config snapshot <<< "${spec}"
    local -a fallback=(--fallback "${DOPPLER_CACHE_DIR}/${snapshot}")
    if [[ "${DOPPLER_OFFLINE}" == "1" ]]; then
        fallback+=(--fallback-only)
    fi
    doppler secrets download --project "${project}" --config "${config}" \
        --no-file --format env --attempts 1 "${fallback[@]}" >"${out}" 2>/dev/null
}

_load_secrets() {
    local loaded=0
    if command -v doppler >/dev/null 2>&1; then
        mkdir -p "${DOPPLER_CACHE_DIR}"
        chmod 700 "${DOPPLER_CACHE_DIR}"
        local -a outs=() pids=()
        local spec out idx
        for spec in "${DOPPLER_SOURCES[@]}"; do
            out="$(mktemp "${TMPDIR:-/tmp}/doppler-env.XXXXXX")"
            outs+=("${out}")
            _TMP_FILES+=("${out}")
            _fetch_doppler_source "${spec}" "${out}" &
            pids+=("$!")
        done
        for idx in "${!pids[@]}"; do
            wait "${pids[${idx}]}" || : >"${outs[${idx}]}"
        done
        for out in "${outs[@]}"; do
            if [[ -s "${out}" ]]; then
                set -a
                # shellcheck source=/dev/null  # Doppler env-format dump; values quoted by the CLI.
                source "${out}" || true
                set +a
                loaded=1
            fi
            rm -f "${out}"
        done
    fi
    if (( loaded == 0 )) && [[ "${SECRET_BACKEND}" == "transition" ]] &&
        [[ -f "${TOKEN_CACHE}" && "${TOKEN_CACHE}" == "${HOME}/.config/"* ]]; then
        # shellcheck source=/dev/null  # Transition-only 1Password cache; path validated above.
        source "${TOKEN_CACHE}" || true
    fi
    if [[ -z "${JUPYTER_TOKEN:-}" && -f "${JUPYTER_TOKEN_CACHE}" ]]; then
        # shellcheck source=/dev/null  # Nix-owned local Jupyter token; not a Doppler-managed key.
        source "${JUPYTER_TOKEN_CACHE}" || true
    fi
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
    IFS=$' \t' read -ra keys <<< "${EXTRA_ENV_KEYS//,/ }"
    for key in "${keys[@]}"; do
        _emit_env_key "${key}"
    done
}

_emit_tool_paths() {
    [[ -n "${TOOL_PATHS}" ]] || return 0
    local -a paths=() selected=()
    local path path_value
    IFS=: read -ra paths <<< "${TOOL_PATHS}"
    for path in "${paths[@]}"; do
        [[ -n "${path}" ]] || continue
        if [[ -d "${path}" || "${ALLOW_MISSING_TOOL_PATHS}" == "1" ]]; then
            selected+=("${path}")
        fi
    done
    (( ${#selected[@]} > 0 )) || return 0
    printf -v path_value '%s:' "${selected[@]}"
    # shellcheck disable=SC2016  # Single quotes intentional -- expand when Claude sources the env file.
    printf 'export PATH="%s:${PATH}"\n' "${path_value%:}"
}

# --- [ENTRY] ------------------------------------------------------------------

trap '[[ ${#_TMP_FILES[@]} -eq 0 ]] || rm -f "${_TMP_FILES[@]}"' EXIT
trap 'exit 129' HUP INT TERM

[[ -n "${CLAUDE_ENV_FILE:-}" ]] || exit 0
ENV_DIR="$(dirname -- "${CLAUDE_ENV_FILE}")"
readonly ENV_DIR
[[ -d "${ENV_DIR}" && -w "${ENV_DIR}" && ! -d "${CLAUDE_ENV_FILE}" ]] || exit 0

_load_secrets

umask 077
_ENV_TMP="$(mktemp "${CLAUDE_ENV_FILE}.tmp.XXXXXX")"
readonly _ENV_TMP
_TMP_FILES+=("${_ENV_TMP}")
{
    for key in "${_ENV_KEYS[@]}"; do
        _emit_env_key "${key}"
    done
    _emit_extra_env_keys
    _emit_tool_paths
} >"${_ENV_TMP}"
chmod 600 "${_ENV_TMP}"
mv "${_ENV_TMP}" "${CLAUDE_ENV_FILE}"
