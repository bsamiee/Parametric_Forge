# 1Password-aware GitHub CLI wrapper
# Keeps gh writable but injects secrets via op run when needed.

# Use native gh auth for auth commands or when hosts.yml already exists
# Fallback: hydrate tokens from ~/.config/op/env.template via op run

gh() {
  local gh_bin
  if ! gh_bin="$(whence -p gh)"; then
    printf 'parametric-forge: gh not on PATH\n' >&2
    return 127
  fi

  local op_template="${OP_ENV_TEMPLATE:-$HOME/.config/op/env.template}"
  local gh_config_dir="${GH_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/gh}"
  local gh_hosts="$gh_config_dir/hosts.yml"
  local prefer_native=0

  if [[ "$1" == "auth" ]]; then
    case "${2:-}" in
      login|logout|status|refresh|setup-git|token) prefer_native=1 ;;
    esac
  fi

  [[ -f "$gh_hosts" ]] && prefer_native=1
  [[ "${GH_FORCE_OP_TOKEN:-0}" == "1" ]] && prefer_native=0
  [[ "${GH_BYPASS_OP:-0}" == "1" ]] && prefer_native=1

  if (( prefer_native )); then
    "$gh_bin" "$@"
    return $?
  fi

  if command -v op >/dev/null 2>&1 \
     && [[ -f "$op_template" ]]; then
    op run --env-file "$op_template" -- "$gh_bin" "$@"
  else
    "$gh_bin" "$@"
  fi
}
