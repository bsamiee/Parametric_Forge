#!/usr/bin/env bash
# SessionStart hook: persist session credentials + tool PATH for sub-agents.
# Canonical across all repos, owned by Parametric_Forge. Sources the 1Password
# token cache when present (resilient: absent on non-Forge/remote hosts -> falls
# back to the ambient login-shell environment), then writes resolved keys to
# CLAUDE_ENV_FILE so spawned sub-agents inherit them. Per-project extras:
# CLAUDE_ENV_EXPORT_KEYS (comma/space list) and CLAUDE_TOOL_PATHS (colon list).
set -Eeuo pipefail
shopt -s inherit_errexit
IFS=$'\n\t'

# --- [CONSTANTS] --------------------------------------------------------------

readonly TOKEN_CACHE="${HOME}/.config/hm-op-session.sh"
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
readonly TOOL_PATHS="${CLAUDE_TOOL_PATHS:-${CLAUDE_EXTRA_PATH:-${HOME}/.cargo/bin:${HOME}/.local/bin}}"
readonly ALLOW_MISSING_TOOL_PATHS="${CLAUDE_ALLOW_MISSING_TOOL_PATHS:-0}"

# --- [OPERATIONS] -------------------------------------------------------------

_emit_env_key() {
    local -r key="$1"
    [[ "${key}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || return 0
    [[ -n "${!key:-}" ]] && printf 'export %s=%q\n' "${key}" "${!key}"
}

_emit_extra_env_keys() {
    [[ -n "${EXTRA_ENV_KEYS}" ]] || return 0
    local -a keys=()
    local key
    read -ra keys <<< "${EXTRA_ENV_KEYS//,/ }"
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
        [[ -d "${path}" || "${ALLOW_MISSING_TOOL_PATHS}" == "1" ]] && selected+=("${path}")
    done
    (( ${#selected[@]} > 0 )) || return 0
    printf -v path_value '%s:' "${selected[@]}"
    # shellcheck disable=SC2016  # Single quotes intentional -- expand when Claude sources the env file.
    printf 'export PATH="%s:${PATH}"\n' "${path_value%:}"
}

# --- [ENTRY] ------------------------------------------------------------------

if [[ -f "${TOKEN_CACHE}" && "${TOKEN_CACHE}" == "${HOME}/.config/"* ]]; then
    # shellcheck source=/dev/null  # Path validated above; cache is absent on non-Forge hosts.
    source "${TOKEN_CACHE}"
fi

[[ -n "${CLAUDE_ENV_FILE:-}" ]] || exit 0
ENV_DIR="$(dirname -- "${CLAUDE_ENV_FILE}")"
readonly ENV_DIR
[[ -d "${ENV_DIR}" && -w "${ENV_DIR}" && ! -d "${CLAUDE_ENV_FILE}" ]] || exit 0
umask 077
_ENV_TMP="$(mktemp "${CLAUDE_ENV_FILE}.tmp.XXXXXX")"
readonly _ENV_TMP
trap 'rm -f "${_ENV_TMP}"' EXIT
{
    for key in "${_ENV_KEYS[@]}"; do
        _emit_env_key "${key}"
    done
    _emit_extra_env_keys
    _emit_tool_paths
} >"${_ENV_TMP}"
chmod 600 "${_ENV_TMP}"
mv "${_ENV_TMP}" "${CLAUDE_ENV_FILE}"
