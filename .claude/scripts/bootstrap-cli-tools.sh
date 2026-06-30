#!/usr/bin/env bash
# Idempotent CLI tool bootstrap. Default mode checks only; apply mutates explicitly.
set -Eeuo pipefail
shopt -s inherit_errexit
IFS=$'\n\t'

# --- [CONSTANTS] --------------------------------------------------------------

readonly COMMAND="${1:-check}"
readonly CARGO_HOME_DIR="${CARGO_HOME:-${HOME}/.cargo}"
readonly BIN_DIR="${CLAUDE_BOOTSTRAP_BIN_DIR:-${CARGO_HOME_DIR}/bin}"
readonly PROFILE_PATH="${CLAUDE_BOOTSTRAP_PROFILE:-${HOME}/.bashrc}"
readonly ALLOW_SUDO="${CLAUDE_BOOTSTRAP_ALLOW_SUDO:-0}"
readonly ALLOW_PROFILE_WRITE="${CLAUDE_BOOTSTRAP_WRITE_PROFILE:-0}"
readonly ALLOW_NETWORK="${CLAUDE_BOOTSTRAP_ALLOW_NETWORK:-0}"
readonly ALLOW_REMOTE_INSTALLERS="${CLAUDE_BOOTSTRAP_ALLOW_REMOTE_INSTALLERS:-0}"
readonly BINSTALL_URL='https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh'
declare -Ar TOOLS=(
    [rg]='ripgrep:binstall' [fd]='fd-find:binstall'
    [sd]='sd:binstall' [bat]='bat:binstall'
    [eza]='eza:binstall' [choose]='choose:binstall'
    [xh]='xh:binstall' [dust]='du-dust:binstall'
    [procs]='procs:binstall' [ouch]='ouch:binstall'
    [jnv]='jnv:binstall' [scc]='boyter/scc:github-go'
    [hyperfine]='hyperfine:binstall' [gping]='gping:binstall'
    [trip]='trippy:binstall'
    [doggo]='mr-karan/doggo:github-go'
    [trash-put]='trash-cli:pipx'
)
declare -Ar STRATEGY_DISPATCH=(
    [binstall]=_install_binstall
    [github-go]=_install_github_go
    [pipx]=_install_pipx
)
declare -Ar COMMAND_DISPATCH=(
    [check]=_check
    [apply]=_apply
    [help]=_usage
)
declare -Ar ARCH_MAP=([x86_64]='(amd64|x86_64)' [aarch64]='arm64' [arm64]='arm64')
declare -Ar POST_NOTES=([trip]='requires: sudo setcap cap_net_raw+ep')
declare -ar PKG_MGRS=(apt-get dnf)
declare -ar PREREQS=(curl tar gzip jq)
declare -a installed=() skipped=() failed=()

# --- [ERRORS] -----------------------------------------------------------------

_die() {
    printf '[FATAL] %s\n' "$1" >&2
    exit 1
}

_require_enabled() {
    local -r value="$1" message="$2"
    [[ "${value}" == "1" ]] || _die "${message}"
}

# --- [FUNCTIONS] --------------------------------------------------------------

_usage() {
    cat <<'USAGE'
Usage:
  .claude/scripts/bootstrap-cli-tools.sh check
  .claude/scripts/bootstrap-cli-tools.sh apply

Environment:
  CLAUDE_BOOTSTRAP_BIN_DIR                 Install target for user-local binaries.
  CLAUDE_BOOTSTRAP_ALLOW_SUDO=1            Permit package-manager prerequisite installs.
  CLAUDE_BOOTSTRAP_WRITE_PROFILE=1         Permit appending the bin dir to the profile.
  CLAUDE_BOOTSTRAP_PROFILE=/path/to/file   Profile file used when profile writes are enabled.
  CLAUDE_BOOTSTRAP_ALLOW_NETWORK=1         Permit network package/tool downloads.
  CLAUDE_BOOTSTRAP_ALLOW_REMOTE_INSTALLERS=1
                                            Permit remote installer scripts and release assets.
USAGE
}

_detect_pkg_mgr() {
    local mgr
    for mgr in "${PKG_MGRS[@]}"; do
        command -v "${mgr}" >/dev/null 2>&1 && {
            printf '%s' "${mgr}"
            return 0
        }
    done
    _die "No supported package manager found: ${PKG_MGRS[*]}"
}

_ensure_prereqs() {
    local -a missing=()
    local bin
    for bin in "${PREREQS[@]}"; do
        command -v "${bin}" >/dev/null 2>&1 || missing+=("${bin}")
    done
    ((${#missing[@]} == 0)) && return 0
    _require_enabled "${ALLOW_SUDO}" "Missing prerequisites (${missing[*]}). Set CLAUDE_BOOTSTRAP_ALLOW_SUDO=1 to install them."
    local -r pkg_mgr="$(_detect_pkg_mgr)"
    printf '[PREREQS] Installing with %s: %s\n' "${pkg_mgr}" "${missing[*]}"
    sudo "${pkg_mgr}" install -y "${missing[@]}"
}

_ensure_path() {
    mkdir -p "${BIN_DIR}"
    export PATH="${BIN_DIR}:${PATH}"
    [[ "${ALLOW_PROFILE_WRITE}" == "1" ]] || return 0
    [[ -f "${PROFILE_PATH}" ]] || : >"${PROFILE_PATH}"
    grep -qF "${BIN_DIR}" "${PROFILE_PATH}" 2>/dev/null && return 0
    # shellcheck disable=SC2016  # Single quotes intentional -- expand when shell reads the profile.
    printf 'export PATH="%s:${PATH}"\n' "${BIN_DIR}" >>"${PROFILE_PATH}"
    printf '[PATH] Appended %s to %s\n' "${BIN_DIR}" "${PROFILE_PATH}"
}

_ensure_binstall() {
    command -v cargo-binstall >/dev/null 2>&1 && return 0
    _require_enabled "${ALLOW_NETWORK}" "cargo-binstall is missing. Set CLAUDE_BOOTSTRAP_ALLOW_NETWORK=1 to fetch it."
    _require_enabled "${ALLOW_REMOTE_INSTALLERS}" "Remote installer disabled. Set CLAUDE_BOOTSTRAP_ALLOW_REMOTE_INSTALLERS=1 to install cargo-binstall."
    local -r tmp="$(mktemp)"
    curl -L --proto '=https' --tlsv1.2 -sSf "${BINSTALL_URL}" -o "${tmp}"
    bash "${tmp}"
    rm -f "${tmp}"
}

# shellcheck disable=SC2329  # invoked indirectly through STRATEGY_DISPATCH
_emit_post_note() {
    local -r binary="$1"
    [[ -v POST_NOTES["${binary}"] ]] || return 0
    local -r bin_path="$(command -v "${binary}")"
    printf '[NOTE] %s %s "%s"\n' "${binary}" "${POST_NOTES[${binary}]}" "${bin_path}"
}

# shellcheck disable=SC2329  # invoked indirectly through STRATEGY_DISPATCH
_install_binstall() {
    local -r crate="$1" binary="$2"
    _require_enabled "${ALLOW_NETWORK}" "Network install disabled. Set CLAUDE_BOOTSTRAP_ALLOW_NETWORK=1 to install ${binary}."
    cargo binstall --no-confirm "${crate}" || {
        failed+=("${binary}")
        return 1
    }
    installed+=("${binary}")
    _emit_post_note "${binary}"
}

# shellcheck disable=SC2329  # invoked indirectly through STRATEGY_DISPATCH
_install_github_go() {
    local -r repo="$1" binary="$2"
    _require_enabled "${ALLOW_NETWORK}" "Network install disabled. Set CLAUDE_BOOTSTRAP_ALLOW_NETWORK=1 to install ${binary}."
    _require_enabled "${ALLOW_REMOTE_INSTALLERS}" "GitHub release install disabled. Set CLAUDE_BOOTSTRAP_ALLOW_REMOTE_INSTALLERS=1 to install ${binary}."
    local -r raw_arch="$(uname -m)"
    [[ -v ARCH_MAP["${raw_arch}"] ]] || _die "Unsupported architecture: ${raw_arch}"
    local -r arch="${ARCH_MAP[${raw_arch}]}"
    local raw_os url tmp
    raw_os="$(uname -s)"
    readonly raw_os
    local -r os="${raw_os@L}"
    url="$(curl -sSf "https://api.github.com/repos/${repo}/releases/latest" |
        jq -r --arg os "${os}" --arg arch "${arch}" \
            '[.assets[].browser_download_url | select(test($os; "i") and test($arch; "i") and test("\\.tar\\.gz$"))] | first // empty')"
    readonly url
    [[ -n "${url}" ]] || {
        printf '[FAIL] No release asset for %s/%s\n' "${os}" "${arch}"
        failed+=("${binary}")
        return 1
    }
    tmp="$(mktemp -d)"
    readonly tmp
    curl -sSfL "${url}" | tar -xz -C "${tmp}"
    install -m 0755 "${tmp}/${binary}" "${BIN_DIR}/${binary}"
    rm -rf "${tmp}"
    installed+=("${binary}")
}

# shellcheck disable=SC2329  # invoked indirectly through STRATEGY_DISPATCH
_install_pipx() {
    local -r package="$1" binary="$2"
    _require_enabled "${ALLOW_NETWORK}" "Network install disabled. Set CLAUDE_BOOTSTRAP_ALLOW_NETWORK=1 to install ${binary}."
    command -v pipx >/dev/null 2>&1 || {
        _require_enabled "${ALLOW_SUDO}" "pipx is missing. Set CLAUDE_BOOTSTRAP_ALLOW_SUDO=1 to install it."
        local -r pkg_mgr="$(_detect_pkg_mgr)"
        sudo "${pkg_mgr}" install -y pipx
    }
    pipx install "${package}" || {
        failed+=("${binary}")
        return 1
    }
    installed+=("${binary}")
}

_provision() {
    local binary spec package strategy
    for binary in "${!TOOLS[@]}"; do
        spec="${TOOLS[${binary}]}"
        IFS=: read -r package strategy <<<"${spec}"
        command -v "${binary}" >/dev/null 2>&1 && {
            printf '[SKIP] %s already present\n' "${binary}"
            skipped+=("${binary}")
            continue
        }
        printf '[INSTALL] %s via %s (%s)\n' "${binary}" "${strategy}" "${package}"
        [[ -v STRATEGY_DISPATCH["${strategy}"] ]] || _die "Unknown install strategy: ${strategy}"
        "${STRATEGY_DISPATCH[${strategy}]}" "${package}" "${binary}"
    done
}

_verify() {
    local binary
    for binary in "${!TOOLS[@]}"; do
        command -v "${binary}" >/dev/null 2>&1 || continue
        "${binary}" --version >/dev/null 2>&1 || printf '[WARN] %s installed but --version failed\n' "${binary}"
    done
}

_check() {
    local -a missing_tools=() missing_prereqs=()
    local binary prereq spec package strategy
    printf '[CHECK] bin_dir=%s profile=%s\n' "${BIN_DIR}" "${PROFILE_PATH}"
    printf '[CHECK] allow_sudo=%s write_profile=%s allow_network=%s allow_remote_installers=%s\n' \
        "${ALLOW_SUDO}" "${ALLOW_PROFILE_WRITE}" "${ALLOW_NETWORK}" "${ALLOW_REMOTE_INSTALLERS}"
    for binary in "${!TOOLS[@]}"; do
        command -v "${binary}" >/dev/null 2>&1 && continue
        missing_tools+=("${binary}")
        spec="${TOOLS[${binary}]}"
        IFS=: read -r package strategy <<<"${spec}"
        [[ "${strategy}" == "pipx" ]] && {
            command -v pipx >/dev/null 2>&1 || missing_prereqs+=("pipx")
        }
        [[ "${strategy}" == "github-go" ]] && {
            for prereq in curl tar gzip jq; do
                command -v "${prereq}" >/dev/null 2>&1 || missing_prereqs+=("${prereq}")
            done
        }
    done
    printf '[CHECK] missing_prereqs=%d missing_tools=%d\n' "${#missing_prereqs[@]}" "${#missing_tools[@]}"
    ((${#missing_prereqs[@]} == 0)) || printf '[CHECK] missing prereqs: %s\n' "${missing_prereqs[*]}"
    ((${#missing_tools[@]} == 0)) || printf '[CHECK] missing tools: %s\n' "${missing_tools[*]}"
    ((${#missing_prereqs[@]} == 0 && ${#missing_tools[@]} == 0))
}

_report() {
    printf '\n[REPORT] installed=%d skipped=%d failed=%d\n' "${#installed[@]}" "${#skipped[@]}" "${#failed[@]}"
    ((${#failed[@]} == 0))
}

_apply() {
    _ensure_prereqs
    _ensure_path
    _ensure_binstall
    _provision
    _verify
    _report
}

# --- [EXPORT] -----------------------------------------------------------------

[[ -v COMMAND_DISPATCH["${COMMAND}"] ]] || {
    _usage >&2
    _die "Unknown command: ${COMMAND}"
}
"${COMMAND_DISPATCH[${COMMAND}]}"
