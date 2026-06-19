# shellcheck shell=bash
set -Eeuo pipefail
shopt -s inherit_errexit array_expand_once nullglob

resolve_share_dir() {
  local source_dir bin_dir
  source_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)" || return
  if [[ -d "$source_dir/data" && -d "$source_dir/sql" ]]; then
    printf '%s\n' "$source_dir"
    return 0
  fi
  bin_dir="$(cd -- "$(dirname -- "$(realpath "${BASH_SOURCE[0]}")")" && pwd -P)" || return
  printf '%s/share/forge-provision\n' "${bin_dir%/bin}"
}

readonly forge_provision_share="${FORGE_PROVISION_SHARE:-$(resolve_share_dir)}"
readonly schema_version=3
readonly owner_label="dev.bsamiee.forge-provision"
readonly service_label="dev.bsamiee.forge-provision.service"
readonly root_label="dev.bsamiee.forge-provision.root"
readonly project_label="dev.bsamiee.forge-provision.project"
readonly resource_label="dev.bsamiee.forge-provision.resource"
readonly generation_label="dev.bsamiee.forge-provision.generation"
readonly project_override="${FORGE_PROVISION_PROJECT:-}"
readonly provision_instance="${FORGE_PROVISION_INSTANCE:-default}"
readonly lock_wait_seconds="${FORGE_PROVISION_LOCK_WAIT_SECONDS:-30}"
readonly lock_ttl_seconds="${FORGE_PROVISION_LOCK_TTL_SECONDS:-900}"
readonly compose_parallel_limit="${FORGE_PROVISION_COMPOSE_PARALLEL_LIMIT:-1}"
readonly max_active_projects="${FORGE_PROVISION_MAX_ACTIVE_PROJECTS:-4}"
readonly default_colima_socket="$HOME/.local/share/colima/default/docker.sock"
readonly default_port_range="15364-15554,25010-25099,25101-25470,25472-25575"
readonly fixed_port_base="${FORGE_PROVISION_PORT_BASE:-}"
readonly port_policy_requested="${FORGE_PROVISION_PORT_POLICY:-auto}"
readonly port_range_requested="${FORGE_PROVISION_PORT_RANGE:-$default_port_range}"
readonly port_exclude_requested="${FORGE_PROVISION_PORT_EXCLUDE:-}"
readonly auth_mode_requested="${FORGE_PROVISION_AUTH:-auto-root}"
readonly pg_cron_requested="${FORGE_PROVISION_PG_CRON:-0}"
host_os="$(uname -s 2>/dev/null || printf unknown)"
readonly host_os

if [[ -f "$forge_provision_share/forge-provision.sh" && -d "$forge_provision_share/data" && -d "$forge_provision_share/sql" ]]; then
  {
    printf 'forge-provision: source-tree execution is unsupported; use the packaged command.\n'
    printf '  Installed command: forge-provision <command>\n'
    printf '  From the Forge repo: nix run .#forge-provision -- <command>\n'
    printf '  From a consumer repo: use that repo'\''s provision rail, for example uv run python -m tools.assay provision <verb>\n'
  } >&2
  exit 126
fi

catalog_path() {
  local relative="$1"
  local path="$forge_provision_share/$relative"
  [[ -r "$path" ]] || {
    printf 'forge-provision: missing packaged catalog: %s\n' "$path" >&2
    exit 70
  }
  printf '%s\n' "$path"
}

command_route_tsv() {
  jq -r '
    .[]
    | [
        .verb,
        .handler,
        (if .json then "1" else "0" end),
        (if .docker then "1" else "0" end),
        .argspec,
        (if .root then "1" else "0" end),
        (if .mutates then "1" else "0" end),
        .lockMode,
        (if .diagnosticJson then "1" else "0" end),
        .description
      ]
    | @tsv
  ' "$(catalog_path data/commands.json)"
}

declare -A command_handler=() command_desc=() command_json=() command_mutates=() command_argspec=()
declare -A command_required_root=() command_required_docker=() command_lock_mode=() command_diagnostic_json=()
declare -a command_order=()

load_command_routes() {
  local verb handler json_mode required_docker argspec required_root mutates lock_mode diagnostic desc extra
  while IFS=$'\t' read -r verb handler json_mode required_docker argspec required_root mutates lock_mode diagnostic desc extra; do
    [[ -n "$verb" ]] || continue
    if [[ -n "${extra:-}" || -z "$handler" || -z "$argspec" || -z "$required_root" || -z "$required_docker" || -z "$lock_mode" || -z "$diagnostic" || -z "$desc" ]]; then
      printf 'forge-provision: invalid command route row for verb=%s\n' "${verb:-unknown}" >&2
      exit 70
    fi
    command_order+=("$verb")
    command_handler[$verb]="$handler"
    command_desc[$verb]="$desc"
    command_argspec[$verb]="$argspec"
    command_required_root[$verb]="$required_root"
    command_required_docker[$verb]="$required_docker"
    command_lock_mode[$verb]="$lock_mode"
    [[ "$json_mode" == 1 ]] && command_json[$verb]=1
    [[ "$mutates" == 1 ]] && command_mutates[$verb]=1
    [[ "$diagnostic" == 1 ]] && command_diagnostic_json[$verb]=1
  done < <(command_route_tsv)
  return 0
}

load_command_routes
service_tsv() {
  jq -r '
    .[]
    | [
        .service,
        .role,
        .profile,
        (if .enabledEnv == "" then "-" else .enabledEnv end),
        .enabledDefault,
        .imageEnv,
        .imageDefault,
        .portEnv,
        .portDefault,
        .dsnEnv,
        .volumeMount,
        .preload,
        .applySqlKey
      ]
    | @tsv
  ' "$(catalog_path data/services.json)"
}

declare -a service_order=()
declare -A service_role=() service_profile=() service_enabled_env=() service_enabled_default=()
declare -A service_image_env=() service_image_default=() service_port_env=() service_port_default=()
declare -A service_dsn_env=() service_volume_mount=() service_preload_base=() service_apply_sql_key=() service_apply_handler=()

load_service_rows() {
  local service role profile enabled_env enabled_default image_env image_default port_env port_default dsn_env volume_mount preload apply_sql_key extra
  while IFS=$'\t' read -r service role profile enabled_env enabled_default image_env image_default port_env port_default dsn_env volume_mount preload apply_sql_key extra; do
    [[ -n "$service" ]] || continue
    if [[ -n "${extra:-}" || -z "$role" || -z "$profile" || -z "$enabled_default" || -z "$image_env" || -z "$image_default" || -z "$port_env" || -z "$port_default" || -z "$dsn_env" || -z "$volume_mount" || -z "$preload" || -z "$apply_sql_key" ]]; then
      printf 'forge-provision: invalid service row for service=%s\n' "${service:-unknown}" >&2
      exit 70
    fi
    [[ "$enabled_env" == "-" ]] && enabled_env=""
    service_order+=("$service")
    service_role[$service]="$role"
    service_profile[$service]="$profile"
    service_enabled_env[$service]="$enabled_env"
    service_enabled_default[$service]="$enabled_default"
    service_image_env[$service]="$image_env"
    service_image_default[$service]="$image_default"
    service_port_env[$service]="$port_env"
    service_port_default[$service]="$port_default"
    service_dsn_env[$service]="$dsn_env"
    service_volume_mount[$service]="$volume_mount"
    service_preload_base[$service]="$preload"
    service_apply_sql_key[$service]="$apply_sql_key"
    service_apply_handler[$service]="apply_service_extensions"
  done < <(service_tsv)
  return 0
}

load_service_rows

forge_root=""
project_key=""
project_name=""
root_key=""
instance_name=""
provisioning_root_dir=""
provisioning_dir=""
current_link=""
compose_file=""
env_file=""
volume_ledger_file=""
docker_config_dir=""
lock_dir=""
lock_token=""
endpoint_lock_dir=""
docker_endpoint=""
docker_endpoint_issue=""
current_command=""
output_json=false
diagnostic_json=false
auth_mode=""
auth_risk=""
auth_secret_dir=""
port_policy_mode=""
port_policy_source=""
port_policy_seed=""
ports_resolved=false
ports_busy_aware=false
lock_owned=false
lock_releasing=false
json_result_emitted=false
endpoint_lock_owned=false
heartbeat_pid=0
foreground_child_pid=0
declare -a json_warnings=()
declare -a compose_command=()
declare -a parsed_args=()
declare -a port_lock_dirs=()
declare -a auto_port_blacklist=()
declare -a psql_session_locks=()
declare -a tracked_tmp_files=()
declare -A resolved_service_port=()
declare -A resolved_service_port_source=()
unpublished_generation=""
unpublished_compose_file=""
cleanup_empty_parents_after_lock=false
cleanup_assets_on_failed_up=false

on_err() {
  local rc=$?
  local stack="${FUNCNAME[*]:-main}"
  cleanup_tracked_tmp_files
  if [[ "$output_json" == true ]]; then
    [[ "$json_result_emitted" == false ]] || exit "$rc"
    emit_error_json "internal-error" "command failed rc=$rc line=${BASH_LINENO[0]:-?} stack=$stack" "$rc"
  else
    printf 'forge-provision: error: command failed rc=%s line=%s stack=%s\n' "$rc" "${BASH_LINENO[0]:-?}" "$stack" >&2
  fi
  exit "$rc"
}
trap on_err ERR

emit_error_json() {
  local code="$1"
  local message="$2"
  local rc="${3:-1}"
  local project="null"
  message="$(redact_message "$message")"
  if [[ -n "${root_key:-}" && -n "${project_key:-}" && -n "${instance_name:-}" && -n "${project_name:-}" ]]; then
    project="$(project_json)"
  fi
  if [[ "$project" != "null" && -n "${auth_mode:-}" && -n "${port_policy_mode:-}" ]] && declare -F emit_stack_json >/dev/null; then
    # shellcheck disable=SC2016
    emit_stack_json "${current_command:-unknown}" false \
      '. + {error: {code: $code, message: $message, exitCode: $exitCode}}' \
      --arg code "$code" \
      --arg message "$message" \
      --argjson exitCode "$rc"
    return 0
  fi
  if ! jq -nc \
    --argjson schemaVersion "$schema_version" \
    --arg command "${current_command:-unknown}" \
    --arg code "$code" \
    --arg message "$message" \
    --argjson exitCode "$rc" \
    --argjson warnings "$(warnings_json)" \
    --argjson project "$project" \
    '{
      schemaVersion: $schemaVersion,
      command: $command,
      ok: false,
      warnings: $warnings,
      error: {code: $code, message: $message, exitCode: $exitCode},
      auth: {},
      portPolicy: {},
      services: {},
      ports: [],
      resources: {counts: {}, owned: {containers: [], volumes: [], networks: []}, images: [], dockerDisk: [], runtime: {}},
      artifacts: {generated: [], plan: null},
      extensions: {catalog: [], results: [], summary: {}},
      tools: {surfaces: {}, summary: {}}
    } + if $project == null then {} else {project: $project} end'; then
    printf 'forge-provision: failed to emit JSON error code=%s rc=%s\n' "$code" "$rc" >&2
  fi
  json_result_emitted=true
}

die() {
  local message
  message="$(redact_message "$*")"
  if [[ "$output_json" == true ]]; then
    emit_error_json "error" "$message" 1
  else
    stderr_line "forge-provision: $message"
  fi
  exit 1
}

die_usage() {
  local message
  message="$(redact_message "$*")"
  if [[ "$output_json" == true ]]; then
    emit_error_json "usage" "$message" 2
  else
    stderr_line "forge-provision: usage: $message"
  fi
  exit 2
}

warn() {
  local message
  message="$(redact_message "$*")"
  if [[ "$output_json" == true ]]; then
    json_warnings+=("$message")
    return 0
  fi
  stderr_line "forge-provision: warning: $message"
}

redact_message() {
  local text="$*"
  local needle
  for needle in "$auth_secret_dir" "$docker_config_dir" "$provisioning_dir" "$provisioning_root_dir" "$forge_root" "${FORGE_PROVISION_ROOT:-}" "$default_colima_socket" "$docker_endpoint" "${DOCKER_CONFIG:-}" "${DOCKER_HOST:-}"; do
    [[ -n "$needle" ]] || continue
    text="${text//"$needle"/[redacted]}"
  done
  if command -v jq >/dev/null 2>&1; then
    text="$(printf '%s\n' "$text" | jq -Rr -f "$(catalog_path jq/redact-message.jq)" 2>/dev/null || printf '%s\n' "$text")"
  else
    text="${text//POSTGRES_PASSWORD=*/POSTGRES_PASSWORD=[redacted]}"
    text="${text//PGPASSFILE=*/PGPASSFILE=[redacted]}"
    text="${text//DOCKER_CONFIG=*/DOCKER_CONFIG=[redacted]}"
  fi
  printf '%s\n' "$text"
}

stderr_line() {
  [[ "$output_json" == true && "$diagnostic_json" != true ]] && return 0
  printf '%s\n' "$(redact_message "$*")" >&2
}

command_supports_json() {
  local command="$1"
  [[ -n "${command_json[$command]:-}" ]]
}

command_supports_diagnostic_json() {
  [[ -n "${command_diagnostic_json[$1]:-}" ]]
}

validate_json_only_args() {
  local command="$1"
  shift
  if [[ "$output_json" == true ]]; then
    [[ "${1:-}" != "--json" ]] || die_usage "$command received --json both globally and locally"
    (($# == 0)) || die_usage "$command accepts no arguments when --json is global"
    return 0
  fi
  if [[ "${1:-}" == "--json" ]]; then
    command_supports_json "$command" || die_usage "$command does not support JSON output"
    (($# == 1)) || die_usage "$command --json accepts no additional arguments"
    return 0
  fi
  (($# == 0)) || die_usage "$command accepts only --json or no arguments"
}

command_wants_json() {
  local _command="$1"
  shift || true
  (($# == 0)) || die_usage "$_command received arguments after route normalization"
  [[ "$output_json" == true ]]
}

normalize_command_args() {
  local command="$1"
  shift
  local arg seen_owned=false
  parsed_args=()
  tool_surface_selector="all"
  case "${command_argspec[$command]}" in
    json-only)
      validate_json_only_args "$command" "$@"
      [[ "$output_json" == false && "${1:-}" == "--json" ]] && output_json=true
      return 0
      ;;
    owned-prune)
      for arg in "$@"; do
        case "$arg" in
          --owned)
            seen_owned=true
            parsed_args+=("$arg")
            ;;
          --volumes)
            parsed_args+=("$arg")
            ;;
          --json) [[ "$output_json" == false ]] || die_usage "prune received --json both globally and locally" ;;
          *) die_usage "prune requires --owned and accepts optional --volumes and --json" ;;
        esac
      done
      [[ "$seen_owned" == true ]] || die_usage "prune requires --owned"
      [[ " $* " == *" --json "* ]] && output_json=true
      return 0
      ;;
    tool-surface-selector)
      tool_surface_selector="all"
      local seen_surface=false seen_json=false
      while (($# > 0)); do
        case "$1" in
          --json)
            [[ "$output_json" == false ]] || die_usage "tools received --json both globally and locally"
            [[ "$seen_json" == false ]] || die_usage "tools received duplicate --json"
            seen_json=true
            output_json=true
            shift
            ;;
          --surface)
            [[ "$seen_surface" == false ]] || die_usage "tools received duplicate --surface"
            seen_surface=true
            shift
            [[ -n "${1:-}" ]] || die_usage "tools --surface requires duckdb, sqlite, or all"
            case "$1" in
              duckdb | sqlite | all) tool_surface_selector="$1" ;;
              *) die_usage "tools --surface must be duckdb, sqlite, or all" ;;
            esac
            shift
            ;;
          *) die_usage "tools accepts --json and optional --surface duckdb|sqlite|all" ;;
        esac
      done
      return 0
      ;;
    psql-pass-through)
      parsed_args=("$@")
      return 0
      ;;
    *)
      die_usage "unknown command argspec for $command: ${command_argspec[$command]}"
      ;;
  esac
}

warnings_json() {
  local warning
  for warning in "${json_warnings[@]}"; do
    jq -nc --arg message "$warning" '{message: $message}'
  done | jq -s .
}

usage() {
  local command
  printf 'Usage: forge-provision [--json | --diagnostic-json] <command> [args]\n\nCommands:\n'
  for command in "${command_order[@]}"; do
    printf '  %-18s %s\n' "$command" "${command_desc[$command]}"
  done
}

env_default() {
  local name="$1"
  local default="$2"
  printf '%s' "${!name:-$default}"
}

known_service() {
  [[ -v service_profile["$1"] ]]
}

service_enabled() {
  local service="$1"
  local env_name="${service_enabled_env[$service]}"
  local value="${service_enabled_default[$service]}"
  [[ -n "$env_name" ]] && value="${!env_name:-$value}"
  [[ "$value" == "1" ]]
}

service_enabled_value() {
  service_enabled "$1" && printf '1' || printf '0'
}

service_image() {
  local service="$1"
  env_default "${service_image_env[$service]}" "${service_image_default[$service]}"
}

service_port() {
  local service="$1"
  resolve_ports false
  printf '%s' "${resolved_service_port[$service]}"
}

service_port_source() {
  local service="$1"
  resolve_ports false
  printf '%s' "${resolved_service_port_source[$service]}"
}

service_dsn() {
  local service="$1"
  printf 'postgres://postgres@127.0.0.1:%s/forge' "$(service_port "$service")"
}

service_dsn_redacted() {
  local service="$1"
  printf 'postgres://postgres:***@127.0.0.1:%s/forge' "$(service_port "$service")"
}

hash_text() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum
  else
    shasum -a 256
  fi
}

auth_secret_name() {
  local service="$1"
  printf '%s-postgres-password' "$service"
}

auth_secret_file() {
  local service="$1"
  printf '%s/%s.password' "$auth_secret_dir" "$service"
}

resolve_auth() {
  [[ -n "$auth_mode" ]] && return 0
  case "$auth_mode_requested" in
    auto-root)
      auth_mode="auto-root"
      auth_risk="generated-root-secret"
      ;;
    trust-loopback)
      auth_mode="trust-loopback"
      auth_risk="local-superuser-trust"
      ;;
    *)
      die "FORGE_PROVISION_AUTH must be auto-root or trust-loopback: $auth_mode_requested"
      ;;
  esac
  auth_secret_dir="$provisioning_dir/secrets"
}

auth_json() {
  resolve_auth
  jq -nc \
    --arg mode "$auth_mode" \
    --arg risk "$auth_risk" \
    --arg user postgres \
    '{mode: $mode, risk: $risk, user: $user, credential: "managed-hidden", agentPromptRequired: false}'
}

ensure_auth_secret() {
  local service="$1"
  resolve_auth
  [[ "$auth_mode" == "auto-root" ]] || return 0
  ensure_dir_component "$auth_secret_dir"
  chmod 700 "$auth_secret_dir"
  local secret tmp old_umask
  secret="$(auth_secret_file "$service")"
  if [[ -f "$secret" ]]; then
    chmod 600 "$secret"
    return 0
  fi
  old_umask="$(umask)"
  umask 077
  tmp="$(mktemp "$auth_secret_dir/.${service}.password.XXXXXX")" || {
    umask "$old_umask"
    return 1
  }
  if ! head -c 32 /dev/urandom | base64 | tr -d '\n' >"$tmp"; then
    rm -f "$tmp"
    umask "$old_umask"
    return 1
  fi
  umask "$old_umask"
  [[ -s "$tmp" ]] || {
    rm -f "$tmp"
    return 1
  }
  chmod 600 "$tmp"
  mv -f "$tmp" "$secret"
}

ensure_auth_secrets() {
  local service
  while IFS= read -r service; do
    ensure_auth_secret "$service"
  done < <(enabled_services)
  refresh_lock_heartbeat
  return 0
}

port_in_csv_ranges() {
  local port="$1"
  local ranges="$2"
  local spec start end
  [[ -n "$ranges" ]] || return 1
  IFS=',' read -ra __ranges <<<"$ranges"
  for spec in "${__ranges[@]}"; do
    [[ -n "$spec" ]] || continue
    if [[ "$spec" =~ ^([0-9]+)-([0-9]+)$ ]]; then
      start="${BASH_REMATCH[1]}"
      end="${BASH_REMATCH[2]}"
    elif [[ "$spec" =~ ^[0-9]+$ ]]; then
      start="$spec"
      end="$spec"
    else
      die "invalid TCP port range segment: $spec"
    fi
    ((port >= start && port <= end)) && return 0
  done
  return 1
}

os_ephemeral_ranges() {
  if [[ "${FORGE_PROVISION_ALLOW_EPHEMERAL_PORTS:-0}" == "1" ]]; then
    printf '\n'
    return 0
  fi
  case "$host_os" in
    Linux)
      if [[ -r /proc/sys/net/ipv4/ip_local_port_range ]]; then
        local first last
        read -r first last </proc/sys/net/ipv4/ip_local_port_range
        printf '%s-%s\n' "$first" "$last"
        return 0
      fi
      ;;
    Darwin)
      local first last hifirst hilast ranges=()
      first="$(sysctl -n net.inet.ip.portrange.first 2>/dev/null || true)"
      last="$(sysctl -n net.inet.ip.portrange.last 2>/dev/null || true)"
      hifirst="$(sysctl -n net.inet.ip.portrange.hifirst 2>/dev/null || true)"
      hilast="$(sysctl -n net.inet.ip.portrange.hilast 2>/dev/null || true)"
      [[ "$first" =~ ^[0-9]+$ && "$last" =~ ^[0-9]+$ ]] && ranges+=("$first-$last")
      [[ "$hifirst" =~ ^[0-9]+$ && "$hilast" =~ ^[0-9]+$ ]] && ranges+=("$hifirst-$hilast")
      if ((${#ranges[@]} > 0)); then
        local IFS=,
        printf '%s\n' "${ranges[*]}"
        return 0
      fi
      ;;
  esac
  return 1
}

combined_excluded_ports() {
  local os_ranges
  if ! os_ranges="$(os_ephemeral_ranges)"; then
    printf 'probe-unavailable\n'
    return 1
  fi
  printf '%s%s%s\n' "$os_ranges" "${os_ranges:+,}" "$port_exclude_requested"
}

port_allowed_for_auto() {
  local base="$1"
  local excluded="$2"
  local offset=0 port service max_port=49151
  [[ "${FORGE_PROVISION_ALLOW_EPHEMERAL_PORTS:-0}" == "1" ]] && max_port=65535
  for service in "${service_order[@]}"; do
    service_enabled "$service" || continue
    port=$((base + offset))
    ((port >= 1024 && port <= max_port)) || return 1
    port_in_csv_ranges "$port" "$port_range_requested" || return 1
    [[ "$excluded" == "probe-unavailable" ]] && return 1
    port_in_csv_ranges "$port" "$excluded" && return 1
    ((offset += 1))
  done
  ((offset > 0)) || return 1
  return 0
}

port_lock_busy() {
  local port="$1"
  [[ -n "$docker_endpoint" ]] || return 1
  local lock
  lock="$(port_lock_root_path)/$port.lock.d"
  [[ -d "$lock" ]] || return 1
  recover_dead_port_lock "$lock" && return 1
  [[ -d "$lock" ]]
}

auto_block_busy() {
  local base="$1"
  local offset=0 service port
  for service in "${service_order[@]}"; do
    service_enabled "$service" || continue
    port=$((base + offset))
    port_lock_busy "$port" && return 0
    port_busy "$port" && return 0
    ((offset += 1))
  done
  return 1
}

host_listener_probe_available() {
  command -v lsof >/dev/null 2>&1 && return 0
  command -v ss >/dev/null 2>&1 && return 0
  [[ -r /proc/net/tcp || -r /proc/net/tcp6 ]]
}

proc_net_port_busy() {
  local port="$1"
  local hex
  printf -v hex '%04X' "$port"
  awk -v p="$hex" '
    NR > 1 {
      split($2, local_addr, ":")
      if (toupper(local_addr[2]) == p && $4 == "0A") {
        found = 1
      }
    }
    END { exit(found ? 0 : 1) }
  ' /proc/net/tcp /proc/net/tcp6 2>/dev/null
}

ss_port_busy() {
  local port="$1"
  ss -H -ltnp 2>/dev/null | awk -v suffix=":$port" '
    $4 == suffix || $4 ~ suffix "$" { found = 1 }
    END { exit(found ? 0 : 1) }
  '
}

host_port_busy() {
  local port="$1"
  if command -v lsof >/dev/null 2>&1; then
    lsof -nP -iTCP:"$port" -sTCP:LISTEN -t >/dev/null 2>&1
    return
  fi
  if command -v ss >/dev/null 2>&1; then
    ss_port_busy "$port"
    return
  fi
  if [[ -r /proc/net/tcp || -r /proc/net/tcp6 ]]; then
    proc_net_port_busy "$port"
    return
  fi
  return 2
}

manifest_port_for_service() {
  local service="$1"
  local manifest="$current_link/manifest.json"
  [[ -f "$manifest" ]] || return 1
  jq -er --arg service "$service" '.services[$service].port // empty' "$manifest" 2>/dev/null
}

set_resolved_block() {
  local base="$1"
  local source="$2"
  local active_only="${3:-false}"
  local offset=0 service
  for service in "${service_order[@]}"; do
    if [[ "$active_only" == true ]] && ! service_enabled "$service"; then
      resolved_service_port[$service]="${service_port_default[$service]}"
      resolved_service_port_source[$service]="disabled-default"
      continue
    fi
    resolved_service_port[$service]=$((base + offset))
    resolved_service_port_source[$service]="$source"
    ((offset += 1))
  done
}

set_resolved_manifest_ports() {
  local service port excluded="probe-unavailable"
  local -A manifest_ports=() seen_active_ports=()
  combined_excluded_ports >/dev/null 2>&1 && excluded="$(combined_excluded_ports)" || excluded="$port_exclude_requested"
  for service in "${service_order[@]}"; do
    port="$(manifest_port_for_service "$service")" || return 1
    validate_port "manifest port for $service" "$port"
    manifest_ports[$service]="$port"
    if service_enabled "$service"; then
      port_in_csv_ranges "$port" "$port_range_requested" || return 1
      [[ "$excluded" == "probe-unavailable" ]] || ! port_in_csv_ranges "$port" "$excluded" || return 1
      [[ -z "${seen_active_ports[$port]:-}" ]] || return 1
      seen_active_ports[$port]="$service"
    fi
  done
  for service in "${service_order[@]}"; do
    resolved_service_port[$service]="${manifest_ports[$service]}"
    resolved_service_port_source[$service]="current-manifest"
  done
}

set_resolved_individual_ports() {
  local service env_name port
  local -A seen_active_ports=()
  for service in "${service_order[@]}"; do
    env_name="${service_port_env[$service]}"
    port="${!env_name:-${service_port_default[$service]}}"
    validate_port "$env_name" "$port"
    if service_enabled "$service"; then
      [[ -z "${seen_active_ports[$port]:-}" ]] || die_usage "$env_name conflicts with ${seen_active_ports[$port]} on TCP port $port"
      seen_active_ports[$port]="$env_name"
    fi
    resolved_service_port[$service]="$port"
    if [[ -n "${!env_name:-}" ]]; then
      resolved_service_port_source[$service]="$env_name"
    else
      resolved_service_port_source[$service]="disabled-default"
    fi
  done
}

resolve_auto_ports() {
  local busy_aware="$1"
  local excluded hash offset bases=() base range_start range_end spec start end count i service port block_width
  if set_resolved_manifest_ports; then
    if [[ "$busy_aware" != true ]]; then
      port_policy_mode="auto"
      port_policy_source="current-manifest"
      return 0
    fi
    local manifest_ok=true
    for service in "${service_order[@]}"; do
      port="${resolved_service_port[$service]}"
      if port_busy "$port" && ! port_owned_by_service "$service" "$port"; then
        manifest_ok=false
      fi
    done
    if [[ "$manifest_ok" == true ]]; then
      port_policy_mode="auto"
      port_policy_source="current-manifest"
      return 0
    fi
    resolved_service_port=()
    resolved_service_port_source=()
  fi

  if ! excluded="$(combined_excluded_ports)"; then
    if [[ "$busy_aware" == true ]]; then
      die "cannot probe OS ephemeral port range for auto allocation; set explicit fixed ports or FORGE_PROVISION_ALLOW_EPHEMERAL_PORTS=1"
    fi
    warn "OS ephemeral port range probe unavailable; read-only auto port plan did not subtract ephemeral ranges"
    excluded="$port_exclude_requested"
  fi
  if ! host_listener_probe_available; then
    if [[ "$busy_aware" == true ]]; then
      die "cannot probe host TCP listeners for auto allocation; install lsof or ss, or set explicit fixed ports"
    fi
    warn "host TCP listener probe unavailable; read-only auto port plan did not inspect listener occupancy"
  fi
  IFS=',' read -ra __candidate_ranges <<<"$port_range_requested"
  block_width="$(enabled_service_count)"
  ((block_width > 0)) || die "no enabled services available for auto port allocation"
  for spec in "${__candidate_ranges[@]}"; do
    [[ "$spec" =~ ^([0-9]+)-([0-9]+)$ ]] || die "invalid FORGE_PROVISION_PORT_RANGE segment: $spec"
    range_start="${BASH_REMATCH[1]}"
    range_end="${BASH_REMATCH[2]}"
    for ((base = range_start; base <= range_end - block_width + 1; base++)); do
      port_allowed_for_auto "$base" "$excluded" && bases+=("$base")
    done
  done
  ((${#bases[@]} > 0)) || die "no usable auto port blocks in FORGE_PROVISION_PORT_RANGE after exclusions"
  port_policy_seed="forge-provision:v2:$(docker_endpoint_hash):$root_key:$project_name:service-order-1"
  hash="$(printf '%s' "$port_policy_seed" | hash_text)"
  hash="${hash%% *}"
  hash="$((16#${hash:0:8}))"
  offset=$((hash % ${#bases[@]}))
  count="${#bases[@]}"
  for ((i = 0; i < count; i++)); do
    base="${bases[$(((offset + i) % count))]}"
    if [[ " ${auto_port_blacklist[*]} " == *" $base "* ]]; then
      continue
    fi
    if [[ "$busy_aware" == true ]] && auto_block_busy "$base"; then
      continue
    fi
    set_resolved_block "$base" "auto" true
    port_policy_mode="auto"
    port_policy_source="auto"
    return 0
  done
  die "no free auto port block available for project=$project_name"
}

resolve_ports() {
  local busy_aware="${1:-false}"
  if [[ "$ports_resolved" == true && ("$ports_busy_aware" == true || "$busy_aware" != true) ]]; then
    return 0
  fi
  require_root
  resolved_service_port=()
  resolved_service_port_source=()
  local active_count=0 explicit_count=0 explicit_active_count=0 service env_name base
  for service in "${service_order[@]}"; do
    env_name="${service_port_env[$service]}"
    if service_enabled "$service"; then
      ((active_count += 1))
      [[ -n "${!env_name:-}" ]] && ((explicit_active_count += 1))
    fi
    [[ -n "${!env_name:-}" ]] && ((explicit_count += 1))
  done
  [[ -z "$fixed_port_base" || "$explicit_count" -eq 0 ]] || die_usage "FORGE_PROVISION_PORT_BASE conflicts with individual service port env vars"
  if [[ -n "$fixed_port_base" ]]; then
    validate_port "FORGE_PROVISION_PORT_BASE" "$fixed_port_base"
    set_resolved_block "$fixed_port_base" "FORGE_PROVISION_PORT_BASE"
    port_policy_mode="fixed-block"
    port_policy_source="FORGE_PROVISION_PORT_BASE"
  elif ((explicit_active_count == active_count && explicit_count > 0)); then
    set_resolved_individual_ports
    port_policy_mode="fixed-individual"
    port_policy_source="service-env"
  elif ((explicit_count > 0)); then
    die_usage "ambiguous port configuration: set every enabled service port or FORGE_PROVISION_PORT_BASE"
  elif [[ "$port_policy_requested" == "auto" ]]; then
    resolve_auto_ports "$busy_aware"
  elif [[ "$port_policy_requested" == "fixed" ]]; then
    base="${service_port_default[timescale]}"
    set_resolved_block "$base" "FORGE_PROVISION_PORT_POLICY=fixed"
    port_policy_mode="fixed-block"
    port_policy_source="policy-default"
  else
    die_usage "FORGE_PROVISION_PORT_POLICY must be auto or fixed: $port_policy_requested"
  fi
  ports_resolved=true
  ports_busy_aware="$busy_aware"
}

reset_resolved_ports() {
  ports_resolved=false
  ports_busy_aware=false
  port_policy_mode=""
  port_policy_source=""
  port_policy_seed=""
  resolved_service_port=()
  resolved_service_port_source=()
}

port_policy_json() {
  resolve_ports false
  local seed_fingerprint=""
  if [[ -n "$port_policy_seed" ]]; then
    seed_fingerprint="$(printf '%s' "$port_policy_seed" | hash_text)"
    seed_fingerprint="${seed_fingerprint%% *}"
  fi
  jq -nc \
    --arg mode "$port_policy_mode" \
    --arg source "$port_policy_source" \
    --arg range "$port_range_requested" \
    --arg exclude "$port_exclude_requested" \
    --arg seedFingerprint "$seed_fingerprint" \
    '{mode: $mode, source: $source, range: $range, exclude: $exclude, seedFingerprint: (if $seedFingerprint == "" then null else $seedFingerprint end)}'
}

project_json() {
  jq -nc \
    --arg rootKey "$root_key" \
    --arg projectKey "$project_key" \
    --arg instance "$instance_name" \
    --arg composeProject "$project_name" \
    '{rootKey: $rootKey, projectKey: $projectKey, instance: $instance, composeProject: $composeProject}'
}

sql_quote() {
  local value="${1//\'/\'\'}"
  printf "'%s'" "$value"
}

extension_catalog_rows() {
  local service="$1"
  known_service "$service" || die "unknown service: $service"
  jq -r --arg service "$service" '
    def env_enabled($row):
      ($row.gateEnv // "") as $env
      | if $env == "" then true
        else ((env[$env] // ($row.gateDefault // "0")) | ascii_downcase) as $value
        | any(($row.gateEnabledValues // ["1", "true", "yes", "on"])[]; ascii_downcase == $value)
        end;
    map(select(.service == $service or .service == "*"))
    | .[]
    | .extension as $extension
    | (if env_enabled(.) and .required then "1" else "0" end) as $required
    | (if env_enabled(.) and .createOnApply then "1" else "0" end) as $createOnApply
    | [
        $extension,
        .category,
        $required,
        $createOnApply,
        (.createPolicy // ""),
        (.loadPolicy // ""),
        (.probeKind // ""),
        ((.probeSqlKey // "") | if . == "" then "none" else . end),
        (if .requiresSharedPreload then "1" else "0" end),
        (.postgres.sharedPreloadLibrary // "")
      ]
    | @tsv
  ' "$(catalog_path data/postgres-extensions.json)"
}

extension_catalog_json_for_service() {
  local service="$1"
  known_service "$service" || die "unknown service: $service"
  jq --arg service "$service" '
    def env_enabled($row):
      ($row.gateEnv // "") as $env
      | if $env == "" then true
        else ((env[$env] // ($row.gateDefault // "0")) | ascii_downcase) as $value
        | any(($row.gateEnabledValues // ["1", "true", "yes", "on"])[]; ascii_downcase == $value)
        end;
    map(select(.service == $service or .service == "*"))
    | map(. + {
        expectedService: $service,
        required: (if env_enabled(.) then (.required // false) else false end),
        createOnApply: (if env_enabled(.) then (.createOnApply // false) else false end),
        createPolicy: (if env_enabled(.) and (.createOnApply // false) then "apply-create" else (.createPolicy // "probe-only") end),
        loadPolicy: (if env_enabled(.) and (.createOnApply // false) then "apply-create" else (.loadPolicy // "probe-only") end)
      })
  ' "$(catalog_path data/postgres-extensions.json)"
}

extension_sql_values() {
  local service="$1"
  local ext category required create_on_apply create_policy load_policy probe_kind probe_sql_key requires_shared_preload shared_preload_library first=true ordinal=0
  while IFS=$'\t' read -r ext category required create_on_apply create_policy load_policy probe_kind probe_sql_key requires_shared_preload shared_preload_library; do
    [[ -n "$ext" ]] || continue
    ((++ordinal))
    if [[ "$first" == true ]]; then
      first=false
    else
      printf ',\n'
    fi
    printf '(%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)' \
      "$ordinal" \
      "$(sql_quote "$ext")" \
      "$(sql_quote "$category")" \
      "$([[ "$required" == 1 ]] && printf true || printf false)" \
      "$([[ "$create_on_apply" == 1 ]] && printf true || printf false)" \
      "$(sql_quote "$create_policy")" \
      "$(sql_quote "$load_policy")" \
      "$(sql_quote "$probe_kind")" \
      "$(sql_quote "$probe_sql_key")" \
      "$([[ "$requires_shared_preload" == 1 ]] && printf true || printf false)" \
      "$(sql_quote "$shared_preload_library")"
  done < <(extension_catalog_rows "$service")
  return 0
}

extension_catalog_json() {
  local service
  for service in "${service_order[@]}"; do
    extension_catalog_json_for_service "$service"
  done | jq -s 'add | sort_by(.service, .category, .extension)'
}

disabled_service_apply_rows() {
  local service="$1"
  extension_catalog_json_for_service "$service" | jq -r --arg service "$service" '
    .[]
    | select(.required == true or .createOnApply == true)
    | [$service, .extension, "disabled", "-", .category, "optional"]
    | @tsv
  '
}

tool_surface_extension_catalog_json() {
  jq -s 'add | sort_by(.surface, .category, .extension)' \
    "$(catalog_path data/duckdb-extensions.json)" \
    "$(catalog_path data/sqlite-extensions.json)"
}

provision_extension_catalog_json() {
  jq -s 'add | sort_by(.service, .category, .extension)' <(extension_catalog_json) <(tool_surface_extension_catalog_json)
}

duckdb_tool_surface_json() {
  local raw
  if ! raw="$(duckdb -bail -no-init -json :memory: <"$(catalog_path sql/duckdb-extension-probe.sql)" 2>/dev/null)"; then
    return 1
  fi
  jq -nc --argjson catalog "$(jq 'map(select(.surface == "duckdb"))' "$(catalog_path data/duckdb-extensions.json)")" --argjson rows "$raw" '
    {
      ok: true,
      executable: "duckdb",
      catalog: $catalog,
      probe: {
        extensionRows: ($rows | length),
        security: {
          autoinstallKnownExtensions: false,
          autoloadKnownExtensions: false,
          allowCommunityExtensions: false,
          allowUnsignedExtensions: false
        },
        extensions: ($rows | map({extension: .extension_name, loaded: .loaded, installed: .installed}))
      }
    }'
}

sqlite_tool_surface_json() {
  local raw
  if ! raw="$(SQLITE_FORGE_PROFILE=safe sqlite-forge -bail -json :memory: <"$(catalog_path sql/sqlite-extension-probe.sql)" 2>/dev/null)"; then
    return 1
  fi
  jq -nc --argjson catalog "$(jq 'map(select(.surface == "sqlite-forge"))' "$(catalog_path data/sqlite-extensions.json)")" --argjson rows "$raw" '
    {
      ok: true,
      executable: "sqlite-forge",
      catalog: $catalog,
      probe: (($rows[0] // {}) + {rowCount: ($rows | length)})
    }'
}

tool_surfaces_json() {
  local duckdb_json="null" sqlite_json="null"
  case "$tool_surface_selector" in
    duckdb)
      duckdb_json="$(duckdb_tool_surface_json)" || return 1
      jq -nc --argjson duckdb "$duckdb_json" '{duckdb: $duckdb}'
      ;;
    sqlite)
      sqlite_json="$(sqlite_tool_surface_json)" || return 1
      jq -nc --argjson sqlite "$sqlite_json" '{sqlite: $sqlite}'
      ;;
    all)
      duckdb_json="$(duckdb_tool_surface_json)" || return 1
      sqlite_json="$(sqlite_tool_surface_json)" || return 1
      jq -nc --argjson duckdb "$duckdb_json" --argjson sqlite "$sqlite_json" '{duckdb: $duckdb, sqlite: $sqlite}'
      ;;
  esac
}

enabled_services() {
  local service
  for service in "${service_order[@]}"; do
    service_enabled "$service" && printf '%s\n' "$service"
  done
  return 0
}

enabled_service_count() {
  local service count=0
  for service in "${service_order[@]}"; do
    service_enabled "$service" && ((count += 1))
  done
  printf '%s\n' "$count"
}

validate_port() {
  local name="$1"
  local value="$2"
  [[ "$value" =~ ^[0-9]+$ ]] || die "$name must be a numeric TCP port: $value"
  ((value >= 1 && value <= 65535)) || die "$name outside TCP port range: $value"
}

validate_image() {
  local name="$1"
  local value="$2"
  [[ -n "$value" && ! "$value" =~ [[:space:]] ]] || die "$name must be a non-empty image reference"
  [[ "$value" != *'$'* && "$value" != *'{'* && "$value" != *'}'* ]] || die "$name must not contain Compose or shell interpolation syntax: $value"
}

validate_lock_wait_seconds() {
  [[ "$lock_wait_seconds" =~ ^[0-9]+$ ]] || die "FORGE_PROVISION_LOCK_WAIT_SECONDS must be a non-negative integer: $lock_wait_seconds"
  ((lock_wait_seconds <= 3600)) || die "FORGE_PROVISION_LOCK_WAIT_SECONDS must be <= 3600: $lock_wait_seconds"
  [[ "$lock_ttl_seconds" =~ ^[0-9]+$ ]] || die "FORGE_PROVISION_LOCK_TTL_SECONDS must be a non-negative integer: $lock_ttl_seconds"
  ((lock_ttl_seconds >= 60 && lock_ttl_seconds <= 86400)) || die "FORGE_PROVISION_LOCK_TTL_SECONDS must be between 60 and 86400: $lock_ttl_seconds"
  [[ "$compose_parallel_limit" =~ ^[0-9]+$ ]] || die "FORGE_PROVISION_COMPOSE_PARALLEL_LIMIT must be a non-negative integer: $compose_parallel_limit"
  ((compose_parallel_limit <= 32)) || die "FORGE_PROVISION_COMPOSE_PARALLEL_LIMIT must be <= 32: $compose_parallel_limit"
  [[ "$max_active_projects" =~ ^[0-9]+$ ]] || die "FORGE_PROVISION_MAX_ACTIVE_PROJECTS must be a non-negative integer: $max_active_projects"
  ((max_active_projects <= 64)) || die "FORGE_PROVISION_MAX_ACTIVE_PROJECTS must be <= 64: $max_active_projects"
}

validate_project_slug() {
  local value="$1"
  [[ "$value" =~ ^[a-z0-9][a-z0-9_-]*$ ]] || die "FORGE_PROVISION_PROJECT must match ^[a-z0-9][a-z0-9_-]*$: $value"
}

slug_text() {
  local value="${1,,}"
  value="${value//[^a-z0-9_-]/-}"
  value="${value##[-_]}"
  value="${value%%[-_]}"
  [[ -n "$value" ]] || value="project"
  printf '%s\n' "$value"
}

compose_project_name() {
  local raw="$1"
  local digest
  if ((${#raw} <= 63)); then
    printf '%s\n' "$raw"
    return 0
  fi
  digest="$(printf '%s' "$raw" | hash_text)"
  digest="${digest%% *}"
  printf '%s-%s\n' "${raw:0:50}" "${digest:0:12}"
}

validate_static_env() {
  validate_lock_wait_seconds
  validate_project_slug "$project_name"
  [[ "$pg_cron_requested" == "0" || "$pg_cron_requested" == "1" ]] ||
    die "FORGE_PROVISION_PG_CRON must be 0 or 1: $pg_cron_requested"
  resolve_auth
  resolve_ports false

  local service env_name enabled_env enabled_value port image
  local -A active_ports=()
  for service in "${service_order[@]}"; do
    enabled_env="${service_enabled_env[$service]}"
    if [[ -n "$enabled_env" ]]; then
      enabled_value="${!enabled_env:-${service_enabled_default[$service]}}"
      [[ "$enabled_value" == "0" || "$enabled_value" == "1" ]] || die "$enabled_env must be 0 or 1"
    fi

    port="$(service_port "$service")"
    image="$(service_image "$service")"
    env_name="${service_port_env[$service]}"
    validate_port "$env_name" "$port"
    validate_image "${service_image_env[$service]}" "$image"

    if service_enabled "$service"; then
      [[ -z "${active_ports[$port]:-}" ]] || die "$env_name conflicts with ${active_ports[$port]} on TCP port $port"
      active_ports[$port]="$env_name"
    fi
  done
}

find_forge_root() {
  local -n _out="$1"
  local candidate
  if [[ -n "${FORGE_PROVISION_ROOT:-}" ]]; then
    candidate="$FORGE_PROVISION_ROOT"
    [[ -d "$candidate" ]] || die "FORGE_PROVISION_ROOT is not a directory: $candidate"
    [[ ! -L "$candidate" ]] || die "refusing symlinked FORGE_PROVISION_ROOT: $candidate"
    candidate="$(cd "$candidate" && pwd -P)" || die "cannot resolve FORGE_PROVISION_ROOT: $candidate"
    _out="$candidate"
    return
  fi

  candidate="$(git rev-parse --show-toplevel 2>/dev/null)" || die "cannot find VCS root from PWD; run inside a Git worktree or set FORGE_PROVISION_ROOT"
  [[ -d "$candidate" ]] || die "discovered VCS root is not a directory: $candidate"
  [[ ! -L "$candidate" ]] || die "refusing symlinked VCS root: $candidate"
  candidate="$(cd "$candidate" && pwd -P)" || die "cannot resolve discovered VCS root: $candidate"
  _out="$candidate"
}

validate_forge_root() {
  local root="$1"
  [[ -d "$root" ]] || die "Forge provision root is not a directory: $root"
  [[ ! -L "$root" ]] || die "refusing symlinked Forge provision root: $root"
  if [[ -z "${FORGE_PROVISION_ROOT:-}" ]]; then
    git -C "$root" rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "Forge provision root is not a Git worktree: $root"
  fi
}

init_root() {
  local fingerprint root_slug state_root
  [[ -n "$forge_root" ]] && return 0
  validate_lock_wait_seconds
  find_forge_root forge_root
  validate_forge_root "$forge_root"
  fingerprint="$(printf '%s' "$forge_root" | hash_text)"
  root_key="${fingerprint%% *}"
  root_key="${root_key:0:12}"
  if [[ -n "$project_override" ]]; then
    validate_project_slug "$project_override"
    project_key="$project_override"
  else
    root_slug="$(slug_text "${forge_root##*/}")"
    project_key="$root_slug-$root_key"
  fi
  instance_name="$provision_instance"
  validate_project_slug "$project_key"
  validate_project_slug "$instance_name"
  project_name="$(compose_project_name "forge-$project_key-$instance_name")"
  validate_project_slug "$project_name"
  provisioning_root_dir="$forge_root/.artifacts/provisioning/forge/$project_key"
  provisioning_dir="$provisioning_root_dir/$instance_name"
  current_link="$provisioning_dir/current"
  compose_file="$current_link/compose.yaml"
  env_file="$current_link/.env"
  volume_ledger_file="$provisioning_dir/volume-ledger.json"
  docker_config_dir="$provisioning_dir/docker-config"
  state_root="${XDG_STATE_HOME:-$HOME/.local/state}"
  lock_dir="$state_root/forge-provision/locks/project/$root_key/$project_key/$instance_name/mutation.lock.d"
  readonly forge_root root_key project_key instance_name project_name provisioning_root_dir provisioning_dir current_link compose_file env_file volume_ledger_file docker_config_dir lock_dir
}

require_root() {
  init_root
}

ensure_dir_component() {
  local path="$1"
  [[ ! -L "$path" ]] || die "refusing symlinked provisioning path component: $path"
  mkdir -p "$path"
  [[ -d "$path" && ! -L "$path" ]] || die "cannot create safe directory: $path"
  chmod 700 "$path" 2>/dev/null || true
}

ensure_state_lock_root() {
  local path="$1"
  local state_root="${XDG_STATE_HOME:-$HOME/.local/state}"
  [[ "$path" == "$state_root/forge-provision/"* ]] || die "unexpected state lock root: $path"
  ensure_dir_component "$state_root"
  ensure_dir_component "$state_root/forge-provision"
  ensure_dir_component "$path"
}

project_lock_base() {
  require_root
  printf '%s/forge-provision/locks/project/%s/%s/%s\n' "${XDG_STATE_HOME:-$HOME/.local/state}" "$root_key" "$project_key" "$instance_name"
}

psql_session_lock_root() {
  printf '%s/session\n' "$(project_lock_base)"
}

docker_endpoint_lock_base() {
  local endpoint_hash
  require_root
  [[ -n "$docker_endpoint" ]] || die "Docker endpoint must be resolved before endpoint lock path calculation"
  endpoint_hash="$(docker_endpoint_hash)"
  printf '%s/forge-provision/locks/%s/%s/%s/%s\n' "${XDG_STATE_HOME:-$HOME/.local/state}" "${endpoint_hash:0:16}" "$root_key" "$project_key" "$instance_name"
}

port_lock_root_path() {
  printf '%s/port\n' "$(docker_endpoint_lock_base)"
}

endpoint_lock_path() {
  printf '%s/endpoint.lock.d\n' "$(docker_endpoint_lock_base)"
}

cleanup_project_lock_parents() {
  local state_root="${XDG_STATE_HOME:-$HOME/.local/state}"
  rmdir "$state_root/forge-provision/locks/project/$root_key/$project_key/$instance_name" "$state_root/forge-provision/locks/project/$root_key/$project_key" "$state_root/forge-provision/locks/project/$root_key" "$state_root/forge-provision/locks/project" "$state_root/forge-provision/locks" "$state_root/forge-provision" 2>/dev/null || true
}

cleanup_endpoint_lock_parents() {
  local endpoint_root endpoint_hash state_root="${XDG_STATE_HOME:-$HOME/.local/state}"
  [[ -n "$docker_endpoint" ]] || return 0
  endpoint_root="$(docker_endpoint_lock_base)"
  endpoint_hash="$(docker_endpoint_hash)"
  rmdir "$endpoint_root/port" "$endpoint_root" "$state_root/forge-provision/locks/${endpoint_hash:0:16}/$root_key/$project_key" "$state_root/forge-provision/locks/${endpoint_hash:0:16}/$root_key" "$state_root/forge-provision/locks/${endpoint_hash:0:16}" "$state_root/forge-provision/locks" "$state_root/forge-provision" 2>/dev/null || true
}

ensure_provisioning_root() {
  require_root
  ensure_dir_component "$forge_root/.artifacts"
  ensure_dir_component "$forge_root/.artifacts/provisioning"
  ensure_dir_component "$provisioning_root_dir"
}

ensure_project_dir() {
  ensure_provisioning_root
  ensure_dir_component "$provisioning_dir"
}

assert_safe_project_dir_for_cleanup() {
  require_root
  [[ "$provisioning_dir" == "$provisioning_root_dir/$instance_name" ]] || die "unexpected project provisioning dir: $provisioning_dir"
  [[ ! -L "$provisioning_dir" ]] || die "refusing symlinked project provisioning dir: $provisioning_dir"
  if [[ -d "$provisioning_dir" ]]; then
    local real
    real="$(cd "$provisioning_dir" && pwd -P)" || die "cannot resolve project provisioning dir: $provisioning_dir"
    [[ "$real" == "$provisioning_root_dir/$instance_name" ]] || die "project provisioning dir escapes canonical root: $real"
  fi
}

owner_field() {
  local lock="$1"
  local key="$2"
  local line
  [[ -f "$lock/owner" ]] || return 0
  while IFS= read -r line; do
    [[ "${line%%=*}" == "$key" ]] || continue
    printf '%s\n' "${line#*=}"
    return 0
  done <"$lock/owner"
  return 0
}

lock_owner_field() {
  owner_field "$lock_dir" "$1" || true
  return 0
}

current_host() {
  printf '%s\n' "${HOSTNAME:-unknown}"
}

token_file_matches_owner() {
  local lock="$1"
  local owner_token token_file line
  [[ -f "$lock/owner" && -f "$lock/token" ]] || return 1
  owner_token=""
  token_file=""
  while IFS= read -r line; do
    [[ "${line%%=*}" == "token" ]] || continue
    owner_token="${line#*=}"
    break
  done <"$lock/owner"
  token_file="$(<"$lock/token")"
  [[ -n "$owner_token" && "$owner_token" == "$token_file" ]]
}

write_owner_metadata() {
  local lock="$1"
  local heartbeat="$2"
  shift 2
  local tmp started_at host pair
  host="$(current_host)"
  started_at="$(owner_field "$lock" started_at || true)"
  [[ -n "$started_at" ]] || TZ=UTC printf -v started_at '%(%Y-%m-%dT%H:%M:%SZ)T' -1
  tmp="$(mktemp "$lock/owner.XXXXXX")" || return
  {
    printf 'pid=%s\n' "$$"
    printf 'host=%s\n' "$host"
    printf 'started_at=%s\n' "$started_at"
    [[ "$heartbeat" == true ]] && printf 'last_heartbeat_epoch=%s\n' "$EPOCHSECONDS"
    printf 'token=%s\n' "$lock_token"
    printf 'root_key=%s\n' "$root_key"
    printf 'project=%s\n' "$project_name"
    for pair in "$@"; do
      printf '%s\n' "$pair"
    done
  } >"$tmp" || {
    rm -f "$tmp"
    return 1
  }
  chmod 600 "$tmp" || return 1
  mv -f "$tmp" "$lock/owner"
}

write_lock_metadata() {
  write_owner_metadata "$lock_dir" true "command=$current_command" "docker_endpoint_hash=$(docker_endpoint_hash)"
}

lock_active_message() {
  local pid host started_at command
  pid="$(lock_owner_field pid)"
  host="$(lock_owner_field host)"
  started_at="$(lock_owner_field started_at)"
  command="$(lock_owner_field command)"
  printf 'another forge-provision mutating command is active: lock=%s pid=%s host=%s command=%s started_at=%s' \
    "$lock_dir" "${pid:-unknown}" "${host:-unknown}" "${command:-unknown}" "${started_at:-unknown}"
}

path_mtime_epoch() {
  local path="$1"
  stat -c %Y "$path" 2>/dev/null || stat -f %m "$path" 2>/dev/null
}

pid_looks_like_forge_provision() {
  local pid="$1"
  [[ "$pid" =~ ^[0-9]+$ ]] || return 1
  kill -0 "$pid" 2>/dev/null || return 1
  command -v ps >/dev/null 2>&1 || return 0
  local command_line
  command_line="$(ps -p "$pid" -o command= 2>/dev/null || printf forge-provision)"
  [[ "$command_line" == *forge-provision* ]]
}

recover_ownerless_lock_dir() {
  local lock="$1"
  [[ -d "$lock" && ! -f "$lock/owner" ]] || return 1
  local mtime
  mtime="$(path_mtime_epoch "$lock")" || return 1
  ((EPOCHSECONDS - mtime >= lock_ttl_seconds)) || return 1
  rm -f "$lock/token" "$lock"/owner.* 2>/dev/null || return 1
  rmdir "$lock" 2>/dev/null || return 1
}

try_recover_dead_lock() {
  local pid host
  pid="$(lock_owner_field pid)"
  [[ -n "$pid" ]] || {
    recover_ownerless_lock_dir "$lock_dir"
    return
  }
  pid_looks_like_forge_provision "$pid" && return 1
  host="$(lock_owner_field host)"
  [[ "$host" == "$(current_host)" ]] || return 1
  token_file_matches_owner "$lock_dir" || return 1
  rm -f "$lock_dir/token" "$lock_dir/owner" "$lock_dir"/owner.* 2>/dev/null || return 1
  rmdir "$lock_dir" 2>/dev/null || return 1
}

acquire_mutation_lock() {
  require_root
  ensure_provisioning_root
  ensure_state_lock_root "${lock_dir%/*}"
  local deadline
  ((deadline = EPOCHSECONDS + lock_wait_seconds))
  while true; do
    if mkdir -m 700 "$lock_dir" 2>/dev/null; then
      lock_token="$$-${EPOCHREALTIME//[^0-9]/}-$SRANDOM"
      if ! printf '%s\n' "$lock_token" >"$lock_dir/token" || ! write_lock_metadata; then
        rm -f "$lock_dir/token" "$lock_dir/owner" "$lock_dir"/owner.* 2>/dev/null || true
        rmdir "$lock_dir" 2>/dev/null || true
        return 1
      fi
      chmod 600 "$lock_dir/token"
      lock_owned=true
      start_lock_heartbeat
      return 0
    fi
    try_recover_dead_lock && continue
    ((EPOCHSECONDS >= deadline)) && die "$(lock_active_message)"
    sleep 1
  done
}

session_owner_field() {
  owner_field "$1" "$2" || true
  return 0
}

write_psql_session_metadata() {
  local lock="$1"
  local service="$2"
  write_owner_metadata "$lock" false "command=psql" "service=$service"
}

recover_dead_psql_session_lock() {
  local lock="$1"
  local pid host mtime
  [[ -d "$lock" ]] || return 1
  if [[ ! -f "$lock/owner" ]]; then
    mtime="$(path_mtime_epoch "$lock" 2>/dev/null || true)"
    [[ -n "$mtime" && $((EPOCHSECONDS - mtime)) -ge "$lock_ttl_seconds" ]] || return 1
  else
    pid="$(session_owner_field "$lock" pid)"
    host="$(session_owner_field "$lock" host)"
    [[ "$host" == "$(current_host)" ]] || return 1
    [[ "$pid" =~ ^[0-9]+$ ]] || return 1
    kill -0 "$pid" 2>/dev/null && return 1
    token_file_matches_owner "$lock" || return 1
  fi
  rm -f "$lock/token" "$lock/owner" "$lock"/owner.* 2>/dev/null || return 1
  rmdir "$lock" 2>/dev/null || return 1
}

cleanup_stale_psql_session_locks() {
  local lock root
  root="$(psql_session_lock_root)"
  [[ -d "$root" ]] || return 0
  for lock in "$root"/*.lock.d; do
    [[ -d "$lock" ]] || continue
    recover_dead_psql_session_lock "$lock" || true
  done
}

active_psql_session_message() {
  local lock="$1"
  local pid host started_at service project
  pid="$(session_owner_field "$lock" pid)"
  host="$(session_owner_field "$lock" host)"
  started_at="$(session_owner_field "$lock" started_at)"
  service="$(session_owner_field "$lock" service)"
  project="$(session_owner_field "$lock" project)"
  printf 'active psql session blocks lifecycle mutation: service=%s project=%s pid=%s host=%s started_at=%s' \
    "${service:-unknown}" "${project:-unknown}" "${pid:-unknown}" "${host:-unknown}" "${started_at:-unknown}"
}

assert_no_active_psql_sessions() {
  local lock root
  cleanup_stale_psql_session_locks
  root="$(psql_session_lock_root)"
  [[ -d "$root" ]] || return 0
  for lock in "$root"/*.lock.d; do
    [[ -d "$lock" ]] || continue
    recover_dead_psql_session_lock "$lock" && continue
    die "$(active_psql_session_message "$lock")"
  done
}

mutation_lock_blocks_psql() {
  [[ -d "$lock_dir" ]] || return 1
  try_recover_dead_lock && return 1
  return 0
}

assert_no_active_mutation_for_psql() {
  mutation_lock_blocks_psql || return 0
  die "$(lock_active_message)"
}

acquire_psql_session_lock() {
  local service="$1"
  local lock root deadline
  assert_no_active_mutation_for_psql
  root="$(psql_session_lock_root)"
  ensure_state_lock_root "$root"
  lock_token="$$-${EPOCHREALTIME//[^0-9]/}-$SRANDOM"
  lock="$root/$service.lock.d"
  ((deadline = EPOCHSECONDS + lock_wait_seconds))
  while true; do
    if mkdir -m 700 "$lock" 2>/dev/null; then
      if ! printf '%s\n' "$lock_token" >"$lock/token" || ! write_psql_session_metadata "$lock" "$service"; then
        rm -f "$lock/token" "$lock/owner" "$lock"/owner.* 2>/dev/null || true
        rmdir "$lock" 2>/dev/null || true
        die "cannot write psql session lock metadata: service=$service"
      fi
      chmod 600 "$lock/token"
      psql_session_locks+=("$lock")
      break
    fi
    recover_dead_psql_session_lock "$lock" && continue
    ((EPOCHSECONDS < deadline)) || die "$(active_psql_session_message "$lock")"
    sleep 1
  done
  if mutation_lock_blocks_psql; then
    local message
    message="$(lock_active_message)"
    release_psql_session_locks || true
    die "$message"
  fi
}

release_psql_session_locks() {
  local lock current_token rc=0 root
  for lock in "${psql_session_locks[@]}"; do
    [[ -d "$lock" ]] || continue
    current_token=""
    [[ -f "$lock/token" ]] && current_token="$(<"$lock/token")"
    if [[ -n "$current_token" && "$current_token" == "$lock_token" ]]; then
      rm -f "$lock/token" "$lock/owner" "$lock"/owner.* 2>/dev/null || rc=1
      rmdir "$lock" 2>/dev/null || rc=1
    fi
  done
  psql_session_locks=()
  root="$(psql_session_lock_root)"
  rmdir "$root" 2>/dev/null || true
  cleanup_project_lock_parents
  return "$rc"
}

refresh_lock_heartbeat() {
  if [[ "$lock_owned" == true && -d "$lock_dir" ]]; then
    write_lock_metadata || true
  fi
  if [[ "$endpoint_lock_owned" == true && -d "$endpoint_lock_dir" ]]; then
    write_endpoint_lock_metadata || true
  fi
  local lock service port
  for lock in "${port_lock_dirs[@]}"; do
    [[ -d "$lock" ]] || continue
    service="$(port_lock_owner_field "$lock" service)"
    port="$(port_lock_owner_field "$lock" port)"
    [[ -n "$service" && -n "$port" ]] || continue
    write_port_lock_metadata "$lock" "$service" "$port" || true
  done
}

start_lock_heartbeat() {
  ((heartbeat_pid == 0)) || return 0
  (
    heartbeat_sleep_pid=0
    trap '[[ ${heartbeat_sleep_pid:-0} -gt 0 ]] && kill -TERM "$heartbeat_sleep_pid" 2>/dev/null || true; exit 0' INT TERM HUP QUIT
    while true; do
      sleep 5 &
      heartbeat_sleep_pid=$!
      wait "$heartbeat_sleep_pid" || exit 0
      heartbeat_sleep_pid=0
      refresh_lock_heartbeat
    done
  ) &
  heartbeat_pid=$!
}

stop_lock_heartbeat() {
  ((heartbeat_pid > 0)) || return 0
  kill -TERM "$heartbeat_pid" 2>/dev/null || true
  for _ in 1 2 3; do
    kill -0 "$heartbeat_pid" 2>/dev/null || break
    sleep 1
  done
  kill -0 "$heartbeat_pid" 2>/dev/null && kill -KILL "$heartbeat_pid" 2>/dev/null || true
  wait "$heartbeat_pid" 2>/dev/null || true
  heartbeat_pid=0
}

release_mutation_lock() {
  local current_token rc=0
  [[ "$lock_releasing" == false ]] || return 0
  lock_releasing=true
  stop_lock_heartbeat
  cleanup_tracked_tmp_files
  [[ -n "$lock_dir" && -d "$lock_dir" ]] || {
    lock_releasing=false
    return 0
  }
  cleanup_publication_artifacts || rc=1
  if [[ -n "$unpublished_compose_file" && -f "$unpublished_compose_file" ]]; then
    if [[ "$cleanup_assets_on_failed_up" == true && ! -e "$current_link" ]]; then
      docker_compose_file "$unpublished_compose_file" down --remove-orphans --volumes >/dev/null 2>&1 || true
    else
      docker_compose_file "$unpublished_compose_file" down --remove-orphans >/dev/null 2>&1 || true
    fi
  fi
  if [[ -n "$unpublished_generation" && -d "$unpublished_generation" ]]; then
    rm -rf -- "$unpublished_generation" || rc=1
    unpublished_generation=""
    unpublished_compose_file=""
  fi
  if [[ "$cleanup_assets_on_failed_up" == true && ! -e "$current_link" ]]; then
    cleanup_assets || rc=1
    cleanup_empty_parents_after_lock=true
  fi
  cleanup_assets_on_failed_up=false
  release_port_locks || rc=1
  release_endpoint_lock || rc=1
  current_token=""
  [[ -f "$lock_dir/token" ]] && current_token="$(<"$lock_dir/token")"
  if [[ "$lock_owned" == true && (-z "$current_token" || "$current_token" == "$lock_token") ]]; then
    rm -f "$lock_dir/token" "$lock_dir/owner" "$lock_dir"/owner.* 2>/dev/null || rc=1
    rmdir "$lock_dir" 2>/dev/null || rc=1
    lock_owned=false
  elif [[ -n "$current_token" && "$current_token" == "$lock_token" ]]; then
    rm -f "$lock_dir/token" "$lock_dir/owner" "$lock_dir"/owner.* 2>/dev/null || rc=1
    rmdir "$lock_dir" 2>/dev/null || rc=1
  fi
  if [[ "$cleanup_empty_parents_after_lock" == true ]]; then
    cleanup_empty_provisioning_parents || true
    cleanup_empty_parents_after_lock=false
  fi
  cleanup_project_lock_parents
  lock_releasing=false
  return "$rc"
}

with_mutation_lock() {
  current_command="$1"
  shift
  local cleanup_rc=0
  require_root
  validate_static_env
  trap 'rc=$?; release_mutation_lock || true; exit "$rc"' EXIT
  trap 'trap - INT; forward_foreground_child INT; release_mutation_lock || true; kill -INT "$$"' INT
  trap 'trap - TERM; forward_foreground_child TERM; release_mutation_lock || true; kill -TERM "$$"' TERM
  trap 'trap - HUP; forward_foreground_child HUP; release_mutation_lock || true; kill -HUP "$$"' HUP
  trap 'trap - QUIT; forward_foreground_child QUIT; release_mutation_lock || true; kill -QUIT "$$"' QUIT
  trap 'trap - PIPE; release_mutation_lock || true; exit 141' PIPE
  acquire_mutation_lock
  cleanup_empty_parents_after_lock=true
  assert_no_active_psql_sessions
  "$@"
  release_mutation_lock || cleanup_rc=$?
  trap - EXIT INT TERM HUP QUIT PIPE
  ((cleanup_rc == 0)) || exit "$cleanup_rc"
  return 0
}

port_lock_owner_field() {
  owner_field "$1" "$2" || true
  return 0
}

write_port_lock_metadata() {
  local lock="$1"
  local service="$2"
  local port="$3"
  write_owner_metadata "$lock" true "docker_endpoint_hash=$(docker_endpoint_hash)" "service=$service" "port=$port"
}

recover_dead_port_lock() {
  local lock="$1"
  local pid host
  pid="$(port_lock_owner_field "$lock" pid)"
  if [[ -n "$pid" ]]; then
    pid_looks_like_forge_provision "$pid" && return 1
    host="$(port_lock_owner_field "$lock" host)"
    [[ "$host" == "$(current_host)" ]] || return 1
    token_file_matches_owner "$lock" || return 1
    rm -f "$lock/token" "$lock/owner" "$lock"/owner.* 2>/dev/null || return 1
    rmdir "$lock" 2>/dev/null || return 1
    return 0
  fi
  recover_ownerless_lock_dir "$lock"
}

acquire_port_locks() {
  require_root
  resolve_docker_endpoint
  local port_root service port lock deadline pid host started_at lock_service
  port_root="$(port_lock_root_path)"
  ensure_state_lock_root "$port_root"
  while IFS= read -r service; do
    port="$(service_port "$service")"
    lock="$port_root/$port.lock.d"
    ((deadline = EPOCHSECONDS + lock_wait_seconds))
    while true; do
      if mkdir -m 700 "$lock" 2>/dev/null; then
        if ! printf '%s\n' "$lock_token" >"$lock/token" || ! write_port_lock_metadata "$lock" "$service" "$port"; then
          rm -f "$lock/token" "$lock/owner" "$lock"/owner.* 2>/dev/null || true
          rmdir "$lock" 2>/dev/null || true
          return 1
        fi
        chmod 600 "$lock/token"
        port_lock_dirs+=("$lock")
        break
      fi
      recover_dead_port_lock "$lock" && continue
      if ((EPOCHSECONDS >= deadline)); then
        pid="$(port_lock_owner_field "$lock" pid)"
        host="$(port_lock_owner_field "$lock" host)"
        started_at="$(port_lock_owner_field "$lock" started_at)"
        lock_service="$(port_lock_owner_field "$lock" service)"
        die "port lock active: port=$port service=$service lock_service=${lock_service:-unknown} pid=${pid:-unknown} host=${host:-unknown} started_at=${started_at:-unknown}"
      fi
      sleep 1
    done
  done < <(enabled_services)
  return 0
}

release_port_locks() {
  local lock current_token rc=0 port_root endpoint_root
  for lock in "${port_lock_dirs[@]}"; do
    [[ -d "$lock" ]] || continue
    current_token=""
    [[ -f "$lock/token" ]] && current_token="$(<"$lock/token")"
    if [[ -n "$current_token" && "$current_token" == "$lock_token" ]]; then
      rm -f "$lock/token" "$lock/owner" "$lock"/owner.* 2>/dev/null || rc=1
      rmdir "$lock" 2>/dev/null || rc=1
    fi
  done
  port_lock_dirs=()
  if [[ -n "$docker_endpoint" ]]; then
    port_root="$(port_lock_root_path)"
    endpoint_root="$(docker_endpoint_lock_base)"
    rmdir "$port_root" "$endpoint_root" 2>/dev/null || true
    cleanup_endpoint_lock_parents
  fi
  return "$rc"
}

write_endpoint_lock_metadata() {
  write_owner_metadata "$endpoint_lock_dir" true "docker_endpoint_hash=$(docker_endpoint_hash)" "command=$current_command" "service=endpoint"
}

recover_dead_endpoint_lock() {
  local pid host
  pid="$(port_lock_owner_field "$endpoint_lock_dir" pid)"
  if [[ -n "$pid" ]]; then
    pid_looks_like_forge_provision "$pid" && return 1
    host="$(port_lock_owner_field "$endpoint_lock_dir" host)"
    [[ "$host" == "$(current_host)" ]] || return 1
    token_file_matches_owner "$endpoint_lock_dir" || return 1
    rm -f "$endpoint_lock_dir/token" "$endpoint_lock_dir/owner" "$endpoint_lock_dir"/owner.* 2>/dev/null || return 1
    rmdir "$endpoint_lock_dir" 2>/dev/null || return 1
    return 0
  fi
  recover_ownerless_lock_dir "$endpoint_lock_dir"
}

acquire_endpoint_lock() {
  require_root
  resolve_docker_endpoint
  local endpoint_hash endpoint_root deadline pid host started_at owner_project
  endpoint_hash="$(docker_endpoint_hash)"
  endpoint_root="$(docker_endpoint_lock_base)"
  endpoint_lock_dir="$(endpoint_lock_path)"
  ensure_state_lock_root "$endpoint_root"
  ((deadline = EPOCHSECONDS + lock_wait_seconds))
  while true; do
    if mkdir -m 700 "$endpoint_lock_dir" 2>/dev/null; then
      if ! printf '%s\n' "$lock_token" >"$endpoint_lock_dir/token" || ! write_endpoint_lock_metadata; then
        rm -f "$endpoint_lock_dir/token" "$endpoint_lock_dir/owner" "$endpoint_lock_dir"/owner.* 2>/dev/null || true
        rmdir "$endpoint_lock_dir" 2>/dev/null || true
        return 1
      fi
      chmod 600 "$endpoint_lock_dir/token"
      endpoint_lock_owned=true
      stop_lock_heartbeat
      start_lock_heartbeat
      return 0
    fi
    recover_dead_endpoint_lock && continue
    if ((EPOCHSECONDS >= deadline)); then
      pid="$(port_lock_owner_field "$endpoint_lock_dir" pid)"
      host="$(port_lock_owner_field "$endpoint_lock_dir" host)"
      started_at="$(port_lock_owner_field "$endpoint_lock_dir" started_at)"
      owner_project="$(port_lock_owner_field "$endpoint_lock_dir" project)"
      die "endpoint lock active: endpoint_hash=${endpoint_hash:0:16} project=${owner_project:-unknown} pid=${pid:-unknown} host=${host:-unknown} started_at=${started_at:-unknown}"
    fi
    sleep 1
  done
}

release_endpoint_lock() {
  local current_token rc=0
  [[ -n "$endpoint_lock_dir" && -d "$endpoint_lock_dir" ]] || return 0
  current_token=""
  [[ -f "$endpoint_lock_dir/token" ]] && current_token="$(<"$endpoint_lock_dir/token")"
  if [[ "$endpoint_lock_owned" == true && -n "$current_token" && "$current_token" == "$lock_token" ]]; then
    rm -f "$endpoint_lock_dir/token" "$endpoint_lock_dir/owner" "$endpoint_lock_dir"/owner.* 2>/dev/null || rc=1
    rmdir "$endpoint_lock_dir" 2>/dev/null || rc=1
  fi
  endpoint_lock_owned=false
  endpoint_lock_dir=""
  cleanup_endpoint_lock_parents
  return "$rc"
}

resolve_docker_endpoint() {
  local endpoint=""
  [[ -n "$docker_endpoint" ]] && return 0
  docker_endpoint_issue=""
  if [[ -n "${DOCKER_HOST:-}" ]]; then
    endpoint="$DOCKER_HOST"
  elif [[ -n "${DOCKER_CONTEXT:-}" ]]; then
    if ! endpoint="$(env -u DOCKER_HOST docker context inspect "$DOCKER_CONTEXT" --format '{{ .Endpoints.docker.Host }}' 2>/dev/null)"; then
      docker_endpoint="unavailable://docker-context"
      docker_endpoint_issue="explicit Docker context cannot be inspected"
      return 0
    fi
  elif [[ -S "$default_colima_socket" ]]; then
    endpoint="unix://$default_colima_socket"
  else
    endpoint="$(env -u DOCKER_HOST docker context inspect --format '{{ .Endpoints.docker.Host }}' 2>/dev/null || true)"
  fi
  [[ -n "$endpoint" ]] || endpoint="unix://$default_colima_socket"
  docker_endpoint="$endpoint"
}

docker_endpoint_hash() {
  resolve_docker_endpoint
  local digest
  digest="$(printf '%s' "$docker_endpoint" | hash_text)"
  printf '%s\n' "${digest%% *}"
}

docker_runtime_issue() {
  resolve_docker_endpoint
  if [[ -n "$docker_endpoint_issue" ]]; then
    printf '%s' "$docker_endpoint_issue"
    return 1
  fi
  if [[ "$docker_endpoint" == tcp://* || "$docker_endpoint" == ssh://* ]]; then
    printf 'remote Docker endpoint rejected for local provisioning'
    return 1
  fi
  [[ "$docker_endpoint" == unix://* ]] || {
    printf 'non-local Docker endpoint rejected'
    return 1
  }
  if [[ "$host_os" == "Darwin" && "${FORGE_PROVISION_ALLOW_NON_COLIMA_DOCKER:-0}" != "1" && "$docker_endpoint" != "unix://$default_colima_socket" ]]; then
    printf 'non-Colima Docker endpoint rejected; set FORGE_PROVISION_ALLOW_NON_COLIMA_DOCKER=1 to override'
    return 1
  fi
  return 0
}

apply_docker_endpoint() {
  resolve_docker_endpoint
  export DOCKER_HOST="$docker_endpoint"
  unset DOCKER_CONTEXT
}

docker_ready() {
  command -v docker >/dev/null 2>&1 || return 1
  docker_runtime_issue >/dev/null || return 1
  apply_docker_endpoint
  docker info >/dev/null 2>&1
}

require_docker() {
  local issue
  command -v docker >/dev/null 2>&1 || die "docker is unavailable"
  if ! issue="$(docker_runtime_issue)"; then
    die "$issue"
  fi
  apply_docker_endpoint
  docker info >/dev/null 2>&1 || die "docker daemon is unavailable for the selected local Docker endpoint"
}

require_mutating_docker() {
  require_docker
  ensure_docker_config
  apply_docker_endpoint
}

select_compose_command() {
  ((${#compose_command[@]} > 0)) && return 0
  local version
  if docker compose version >/dev/null 2>&1; then
    compose_command=(docker compose)
  elif command -v docker-compose >/dev/null 2>&1; then
    version="$(docker-compose version --short 2>/dev/null || true)"
    [[ "$version" =~ ^v?([2-9]|[1-9][0-9])\. ]] || die "Docker Compose v2 is required; docker-compose reported version=${version:-unknown}"
    compose_command=(docker-compose)
  else
    die "Docker Compose v2 is unavailable; expected docker compose or docker-compose"
  fi
}

forward_foreground_child() {
  local signal="$1"
  ((foreground_child_pid > 0)) || return 0
  kill -"$signal" "$foreground_child_pid" 2>/dev/null || true
}

run_foreground_child() {
  "$@" &
  foreground_child_pid=$!
  local rc=0
  wait -f "$foreground_child_pid" || rc=$?
  foreground_child_pid=0
  return "$rc"
}

docker_compose_file() {
  local compose="$1"
  shift
  local old_parallel="${COMPOSE_PARALLEL_LIMIT-}"
  local had_parallel=false
  [[ -v COMPOSE_PARALLEL_LIMIT ]] && had_parallel=true
  select_compose_command
  export COMPOSE_PARALLEL_LIMIT="$compose_parallel_limit"
  local rc=0
  run_foreground_child "${compose_command[@]}" -f "$compose" --project-name "$project_name" "$@" || rc=$?
  if [[ "$had_parallel" == true ]]; then
    export COMPOSE_PARALLEL_LIMIT="$old_parallel"
  else
    unset COMPOSE_PARALLEL_LIMIT
  fi
  return "$rc"
}

docker_compose_version() {
  select_compose_command || {
    printf 'unavailable'
    return 0
  }
  "${compose_command[@]}" version --short 2>/dev/null || printf 'unavailable'
}

atomic_render() {
  local target="$1"
  local renderer="$2"
  local dir tmp old_umask rc
  shift 2
  dir="${target%/*}"
  ensure_dir_component "$dir"
  old_umask="$(umask)"
  umask 077
  tmp="$(mktemp "$dir/.tmp.XXXXXX")" || {
    rc=$?
    umask "$old_umask"
    return "$rc"
  }
  umask "$old_umask"
  "$renderer" "$@" >"$tmp" || {
    rc=$?
    rm -f "$tmp"
    return "$rc"
  }
  if ! chmod 600 "$tmp" || ! mv -f "$tmp" "$target"; then
    rc=$?
    rm -f -- "$tmp"
    return "$rc"
  fi
}

secure_tmp_file() {
  local prefix="$1"
  local old_umask tmp rc
  old_umask="$(umask)"
  umask 077
  tmp="$(mktemp "${TMPDIR:-/tmp}/${prefix}.XXXXXX")" || {
    rc=$?
    umask "$old_umask"
    return "$rc"
  }
  umask "$old_umask"
  tracked_tmp_files+=("$tmp")
  printf '%s\n' "$tmp"
}

cleanup_tracked_tmp_files() {
  local file
  for file in "${tracked_tmp_files[@]}"; do
    [[ -n "$file" ]] && rm -f -- "$file" 2>/dev/null || true
  done
  tracked_tmp_files=()
}

ensure_docker_config() {
  ensure_project_dir
  atomic_render "$docker_config_dir/config.json" printf '%s\n' '{}'
  export DOCKER_CONFIG="$docker_config_dir"
  stderr_line "docker-credentials	mode=anonymous	reason=agent-local-public-images	config=$docker_config_dir"
}

volume_prefix() {
  printf '%s' "$project_name"
}

network_name() {
  printf '%s-net' "$(volume_prefix)"
}

service_volume_name() {
  local service="$1"
  printf '%s-%s-data' "$(volume_prefix)" "$service"
}

service_postgres_command() {
  local service="$1"
  local preload="${service_preload_base[$service]:-}"
  extension_catalog_json_for_service "$service" | jq -r --arg base "$preload" '
    def words($s): if $s == "" then [] else ($s | split(",") | map(select(length > 0))) end;
    (words($base) + [.[] | select(.required == true or .createOnApply == true) | .postgres.sharedPreloadLibrary? | select(. != null and . != "")] | unique) as $preloads
    | ([.[] | select(.required == true or .createOnApply == true) | .postgres.settings[]? | select((.name // "") != "" and (.value // "") != "")]) as $settings
    | if (($preloads | length) == 0 and ($settings | length) == 0) then empty
      else
        ["postgres"]
        + (if ($preloads | length) == 0 then [] else ["-c", "shared_preload_libraries=" + ($preloads | join(","))] end)
        + ($settings | map(["-c", .name + "=" + .value]) | add // [])
        | @json
      end
  '
}

render_common_labels() {
  local resource="$1"
  local service="$2"
  printf '      %s: "1"\n' "$owner_label"
  printf '      %s: %s\n' "$service_label" "$service"
  printf '      %s: "%s"\n' "$root_label" "$root_key"
  printf '      %s: "%s"\n' "$project_label" "$project_name"
  printf '      %s: %s\n' "$resource_label" "$resource"
  [[ -z "${unpublished_generation##*/}" ]] || printf '      %s: "%s"\n' "$generation_label" "${unpublished_generation##*/}"
}

render_auth_environment() {
  local service="$1"
  resolve_auth
  printf '      POSTGRES_DB: forge\n'
  printf '      POSTGRES_USER: postgres\n'
  if [[ "$auth_mode" == "trust-loopback" ]]; then
    printf '      POSTGRES_HOST_AUTH_METHOD: trust\n'
  else
    printf '      POSTGRES_PASSWORD_FILE: /run/secrets/%s\n' "$(auth_secret_name "$service")"
  fi
}

render_compose_service() {
  local service="$1"
  local command
  command="$(service_postgres_command "$service")"
  printf '  %s:\n' "$service"
  printf '    image: %s\n' "$(service_image "$service")"
  [[ -z "$command" ]] || printf '    command: %s\n' "$command"
  printf '    ports:\n'
  printf '      - name: %s-postgres\n' "$service"
  printf '        target: 5432\n'
  printf '        host_ip: 127.0.0.1\n'
  printf '        published: "%s"\n' "$(service_port "$service")"
  printf '        protocol: tcp\n'
  printf '    environment:\n'
  render_auth_environment "$service"
  if [[ "$auth_mode" == "auto-root" ]]; then
    printf '    secrets:\n'
    printf '      - %s\n' "$(auth_secret_name "$service")"
  fi
  printf '    volumes:\n'
  printf '      - %s-data:%s\n' "$service" "${service_volume_mount[$service]}"
  printf '    networks:\n'
  printf '      - provision-net\n'
  printf '    user: "0:0"\n'
  printf '    labels:\n'
  render_common_labels container "$service"
  printf '    healthcheck:\n'
  printf '      test: ["CMD-SHELL", "pg_isready -U postgres -d forge"]\n'
  printf '      interval: 5s\n'
  printf '      timeout: 5s\n'
  printf '      start_period: 10s\n'
  printf '      start_interval: 2s\n'
  printf '      retries: 30\n'
}

render_compose_volume() {
  local service="$1"
  printf '  %s-data:\n' "$service"
  printf '    name: "%s"\n' "$(service_volume_name "$service")"
  printf '    labels:\n'
  render_common_labels volume "$service"
}

render_compose_secret() {
  local service="$1"
  local source
  [[ "$auth_mode" == "auto-root" ]] || return 0
  source="$(auth_secret_file "$service")"
  [[ -f "$source" ]] || source="$auth_secret_dir/<generated-by-up>"
  printf '  %s:\n' "$(auth_secret_name "$service")"
  printf '    file: "%s"\n' "$source"
}

render_compose() {
  local service network
  resolve_auth
  resolve_ports false
  network="$(network_name)"
  printf 'name: %s\n' "$project_name"
  printf 'services:\n'
  while IFS= read -r service; do
    render_compose_service "$service"
  done < <(enabled_services)
  printf '\nvolumes:\n'
  while IFS= read -r service; do
    render_compose_volume "$service"
  done < <(enabled_services)
  printf '\nnetworks:\n'
  printf '  provision-net:\n'
  printf '    name: "%s"\n' "$network"
  printf '    labels:\n'
  render_common_labels network network
  if [[ "$auth_mode" == "auto-root" ]]; then
    printf '\nsecrets:\n'
    while IFS= read -r service; do
      render_compose_secret "$service"
    done < <(enabled_services)
  fi
}

render_env() {
  local service
  resolve_auth
  resolve_ports false
  printf 'FORGE_PROVISION_ROOT=%s\n' "$forge_root"
  printf 'FORGE_PROVISION_PROJECT=%s\n' "$project_key"
  printf 'FORGE_PROVISION_INSTANCE=%s\n' "$instance_name"
  printf 'FORGE_PROVISION_COMPOSE_PROJECT=%s\n' "$project_name"
  printf 'FORGE_PROVISION_DIR=%s\n' "$provisioning_dir"
  printf 'FORGE_PROVISION_COMPOSE=%s\n' "$compose_file"
  printf 'FORGE_PROVISION_ENV=%s\n' "$env_file"
  printf 'FORGE_PROVISION_AUTH=%s\n' "$auth_mode"
  printf 'FORGE_PROVISION_PORT_POLICY=%s\n' "$port_policy_mode"
  for service in "${service_order[@]}"; do
    printf '%s=%s\n' "${service_image_env[$service]}" "$(service_image "$service")"
    printf '%s=%s\n' "${service_port_env[$service]}" "$(service_port "$service")"
    if service_enabled "$service"; then
      printf '%s=%s\n' "${service_dsn_env[$service]}" "$(service_dsn "$service")"
    fi
  done
  printf 'FORGE_PROVISION_PGDUCKDB=%s\n' "$(service_enabled_value pgduckdb)"
}

render_generation_manifest() {
  local generation_id="$1"
  local created_at services_json
  TZ=UTC printf -v created_at '%(%Y-%m-%dT%H:%M:%SZ)T' -1
  services_json="$(service_records_json)"
  jq -n \
    --argjson schemaVersion "$schema_version" \
    --arg generation "$generation_id" \
    --arg root "$forge_root" \
    --argjson project "$(project_json)" \
    --arg createdAt "$created_at" \
    --argjson auth "$(auth_json)" \
    --argjson portPolicy "$(port_policy_json)" \
    --argjson services "$services_json" \
    --arg dockerEndpointHash "$(docker_endpoint_hash)" \
    --arg hostOs "$host_os" \
    '{schemaVersion: $schemaVersion, generation: $generation, root: $root, project: $project, createdAt: $createdAt, dockerEndpointHash: $dockerEndpointHash, hostOs: $hostOs, auth: $auth, portPolicy: $portPolicy, services: $services}'
}

render_volume_ledger() {
  local generation_id="$1"
  local created_at
  TZ=UTC printf -v created_at '%(%Y-%m-%dT%H:%M:%SZ)T' -1
  jq -n \
    --argjson schemaVersion "$schema_version" \
    --arg generation "$generation_id" \
    --argjson project "$(project_json)" \
    --arg createdAt "$created_at" \
    --arg authMode "$auth_mode" \
    --arg authRisk "$auth_risk" \
    --argjson services "$(service_records_json)" \
    --arg volumePrefix "$(volume_prefix)" \
    '{
      schemaVersion: $schemaVersion,
      project: $project,
      generation: $generation,
      createdAt: $createdAt,
      auth: {mode: $authMode, risk: $authRisk},
      rollback: {persistentVolumesIntact: true, eligibility: "compose-generation-only", imageStability: "best-effort-image-tag"},
      volumes: (
        $services
        | to_entries
        | map({service: .key, volume: ($volumePrefix + "-" + .key + "-data"), enabled: .value.enabled})
        | sort_by(.service)
      )
    }'
}

create_generation() {
  ensure_project_dir
  validate_static_env
  ensure_auth_secrets
  local generation_id staging generation rc
  generation_id="gen-${EPOCHREALTIME//[^0-9]/}-$SRANDOM"
  staging="$provisioning_dir/.staging-$generation_id"
  generation="$provisioning_dir/.$generation_id"
  unpublished_generation="$generation"
  mkdir "$staging"
  if ! {
    atomic_render "$staging/.env" render_env
    atomic_render "$staging/compose.yaml" render_compose
    atomic_render "$staging/manifest.json" render_generation_manifest "$generation_id"
    docker_compose_file "$staging/compose.yaml" config >/dev/null
  }; then
    rc=$?
    rm -rf -- "$staging"
    return "$rc"
  fi
  mv -T "$staging" "$generation"
  unpublished_generation=""
  printf '%s\n' "$generation"
}

publish_generation() {
  local generation="$1"
  local link_tmp="$provisioning_dir/.current.next"
  [[ -d "$generation" ]] || die "cannot publish missing generation: $generation"
  [[ ! -e "$current_link" || -L "$current_link" ]] || die "refusing to replace non-symlink current path: $current_link"
  rm -f "$link_tmp"
  ln -s "${generation##*/}" "$link_tmp"
  mv -Tf "$link_tmp" "$current_link"
}

restore_previous_generation() {
  local previous_compose="$1"
  local failed_compose="$2"
  local down_args=(down --remove-orphans)
  if [[ -f "$failed_compose" ]]; then
    docker_compose_file "$failed_compose" "${down_args[@]}" >/dev/null 2>&1 || warn "failed to clean unpublished Compose generation"
  fi
  if [[ "$cleanup_assets_on_failed_up" == true && -z "$previous_compose" ]]; then
    warn "failed first-up preserves any owned volumes until prune --owned --volumes proves removal intent"
  fi
  unpublished_compose_file=""
  if [[ -n "$previous_compose" && -f "$previous_compose" ]]; then
    if docker_compose_file "$previous_compose" up -d --remove-orphans --wait --wait-timeout 180 >/dev/null 2>&1; then
      warn "failed upgrade restored previous published Compose generation; persistent volumes were left intact"
    else
      warn "failed upgrade could not restore previous published Compose generation; persistent volumes were left intact"
      return 1
    fi
  fi
  return 0
}

cleanup_publication_artifacts() {
  [[ -n "$provisioning_dir" && -d "$provisioning_dir" && ! -L "$provisioning_dir" ]] || return 0
  rm -f "$provisioning_dir/.current.next" "$docker_config_dir"/.tmp.* "$provisioning_dir"/.tmp.* 2>/dev/null || true
  [[ -n "$auth_secret_dir" && -d "$auth_secret_dir" ]] && rm -f "$auth_secret_dir"/.*.password.* 2>/dev/null || true
  rm -rf -- "$provisioning_dir"/.staging-gen-* 2>/dev/null || true
}

cleanup_stale_generations() {
  [[ -d "$provisioning_dir" && ! -L "$provisioning_dir" ]] || return 0
  local current_target generation
  current_target=""
  [[ -L "$current_link" ]] && current_target="$(readlink "$current_link")"
  for generation in "$provisioning_dir"/.gen-* "$provisioning_dir"/.gen.*; do
    [[ -d "$generation" ]] || continue
    [[ "${generation##*/}" == "$current_target" ]] && continue
    rm -rf "$generation"
  done
}

cleanup_assets() {
  require_root
  assert_safe_project_dir_for_cleanup
  if [[ -e "$provisioning_dir" ]]; then
    rm -rf "$provisioning_dir"
  fi
}

cleanup_runtime_assets_preserve_state() {
  require_root
  assert_safe_project_dir_for_cleanup
  [[ -d "$provisioning_dir" && ! -L "$provisioning_dir" ]] || return 0
  rm -f "$current_link" "$provisioning_dir/.current.next" 2>/dev/null || true
  rm -rf -- "$provisioning_dir"/.gen-* "$provisioning_dir"/.gen.* "$provisioning_dir"/.staging-gen-* "$docker_config_dir" 2>/dev/null || true
}

cleanup_transient_assets() {
  require_root
  assert_safe_project_dir_for_cleanup
  [[ -d "$provisioning_dir" && ! -L "$provisioning_dir" ]] || return 0
  rm -f "$provisioning_dir/.current.next" "$provisioning_dir"/.tmp.* 2>/dev/null || true
  rm -rf -- "$provisioning_dir"/.staging-gen-* "$docker_config_dir" 2>/dev/null || true
}

cleanup_empty_provisioning_parents() {
  require_root
  rmdir "$provisioning_root_dir" "$forge_root/.artifacts/provisioning/forge" "$forge_root/.artifacts/provisioning" "$forge_root/.artifacts" 2>/dev/null || true
}

# shellcheck source=/dev/null
source "$(catalog_path bash/docker-projection.sh)"

lock_json() {
  local present=false active=false pid="" host="" started_at="" command="" heartbeat="" state="none" pid_alive=false heartbeat_stale=false mtime=""
  if [[ -d "$lock_dir" ]]; then
    present=true
    pid="$(lock_owner_field pid)"
    host="$(lock_owner_field host)"
    started_at="$(lock_owner_field started_at)"
    command="$(lock_owner_field command)"
    heartbeat="$(lock_owner_field last_heartbeat_epoch)"
    if [[ -z "$pid" ]]; then
      mtime="$(path_mtime_epoch "$lock_dir" 2>/dev/null || true)"
      if [[ -n "$mtime" && $((EPOCHSECONDS - mtime)) -ge "$lock_ttl_seconds" ]]; then
        state="ownerless-expired"
      else
        state="ownerless"
      fi
    elif kill -0 "$pid" 2>/dev/null; then
      pid_alive=true
      active=true
      if [[ "$heartbeat" =~ ^[0-9]+$ && $((EPOCHSECONDS - heartbeat)) -ge "$lock_ttl_seconds" ]]; then
        heartbeat_stale=true
        state="stale-heartbeat-live-pid"
      else
        state="active-live"
      fi
    elif [[ "$host" == "$(current_host)" ]]; then
      state="stale-dead-pid"
    else
      state="foreign-host"
    fi
  fi
  jq -nc --argjson present "$present" --argjson active "$active" --arg state "$state" --argjson pidAlive "$pid_alive" --argjson heartbeatStale "$heartbeat_stale" --arg command "$command" --argjson diagnostic "$([[ "$diagnostic_json" == true ]] && printf true || printf false)" \
    'def empty_null: if . == "" then null else . end;
    {present: $present, active: $active, state: $state, pidAlive: $pidAlive, heartbeatStale: $heartbeatStale, command: ($command | empty_null)}
    + if $diagnostic then {ownerMetadataRedacted: true} else {} end'
}

colima_json() {
  local status
  if command -v colima >/dev/null 2>&1; then
    if status="$(colima status --json 2>/dev/null)"; then
      jq -nc --argjson status "$status" --argjson diagnostic "$([[ "$diagnostic_json" == true ]] && printf true || printf false)" -f "$(catalog_path jq/colima-status.jq)"
    else
      jq -nc '{available: true, status: null, raw: null, statusRedacted: true}'
    fi
  else
    jq -nc '{available: false, status: null, raw: null}'
  fi
}

cmd_up() {
  require_root
  validate_static_env
  require_mutating_docker
  acquire_endpoint_lock
  enforce_max_active_projects
  resolve_ports true
  assert_owned_project
  assert_owned_named_resources
  local preexisting_volumes=()
  collect_owned_volume_names preexisting_volumes
  cleanup_assets_on_failed_up=false
  [[ ! -e "$current_link" && ${#preexisting_volumes[@]} -eq 0 ]] && cleanup_assets_on_failed_up=true
  acquire_port_locks
  preflight_ports
  local previous_compose=""
  [[ -f "$compose_file" ]] && previous_compose="$compose_file"
  local generation apply_output extensions_json compose_up_log service
  local auto_retry_count=0
  while true; do
    generation="$(create_generation)"
    unpublished_generation="$generation"
    unpublished_compose_file="$generation/compose.yaml"
    compose_up_log="$(secure_tmp_file forge-provision-compose-up)"
    if docker_compose_file "$generation/compose.yaml" up -d --remove-orphans --wait --wait-timeout 180 >"$compose_up_log" 2>&1; then
      rm -f -- "$compose_up_log"
      break
    fi
    while IFS= read -r line; do
      stderr_line "$line"
    done <"$compose_up_log"
    if [[ "$port_policy_mode" == "auto" ]] &&
      awk '{ line = tolower($0) } line ~ /port[[:space:]]is[[:space:]]already[[:space:]]allocated/ || line ~ /ports[[:space:]]are[[:space:]]not[[:space:]]available/ || line ~ /bind:[[:space:]]address[[:space:]]already[[:space:]]in[[:space:]]use/ || line ~ /bind[[:space:]]for[[:space:]].*failed/ || line ~ /listen[[:space:]]tcp.*:[[:space:]]bind/ { found = 1 } END { exit(found ? 0 : 1) }' "$compose_up_log" &&
      ((auto_retry_count < 8)); then
      for service in "${service_order[@]}"; do
        service_enabled "$service" || continue
        auto_port_blacklist+=("${resolved_service_port[$service]}")
        break
      done
      ((auto_retry_count += 1))
      warn "auto port block conflicted during Docker bind; retrying deterministic next block attempt=$auto_retry_count"
      docker_compose_file "$generation/compose.yaml" down --remove-orphans >/dev/null 2>&1 || true
      rm -rf -- "$generation"
      rm -f -- "$compose_up_log"
      unpublished_generation=""
      unpublished_compose_file=""
      release_port_locks || true
      reset_resolved_ports
      resolve_ports true
      acquire_port_locks
      preflight_ports
      continue
    fi
    while IFS= read -r service; do
      readiness_report "$service"
    done < <(enabled_services)
    rm -f -- "$compose_up_log"
    restore_previous_generation "$previous_compose" "$generation/compose.yaml" || true
    die "Docker Compose up failed; generation was not published"
  done
  require_enabled_services
  wait_services
  release_port_locks || true
  if ! apply_output="$(apply_rows)"; then
    restore_previous_generation "$previous_compose" "$generation/compose.yaml" || true
    die "extension apply command failed; generation was not published"
  fi
  if ! apply_required_rows_ok "$apply_output"; then
    if [[ "$output_json" != true || "$diagnostic_json" == true ]]; then
      printf '%s\n' "$apply_output" >&2
    fi
    restore_previous_generation "$previous_compose" "$generation/compose.yaml" || true
    die "required extension apply failed; generation was not published"
  fi
  publish_generation "$generation"
  local generation_id="${generation##*/}"
  generation_id="${generation_id#.}"
  atomic_render "$volume_ledger_file" render_volume_ledger "$generation_id"
  unpublished_generation=""
  unpublished_compose_file=""
  cleanup_assets_on_failed_up=false
  cleanup_stale_generations
  if [[ "$output_json" == true ]]; then
    extensions_json="$(printf '%s\n' "$apply_output" | apply_rows_json)"
    # shellcheck disable=SC2016
    emit_stack_json up true \
      '($extensions | flatten) as $extensionRows
      | . + {ports: $ports, extensions: {catalog: [], results: $extensionRows, summary: {ok: ([ $extensionRows[] | select(.state == "ok") ] | length), requiredOk: ([ $extensionRows[] | select(.required and .state == "ok") ] | length), requiredMissing: ([ $extensionRows[] | select(.required and .state != "ok") ] | length), available: ([ $extensionRows[] | select(.state == "available") ] | length), unavailable: ([ $extensionRows[] | select(.state == "unavailable") ] | length), disabled: ([ $extensionRows[] | select(.state == "disabled") ] | length)}}}' \
      --argjson extensions "$extensions_json" \
      --argjson ports "$(port_records_json)"
  else
    printf '%s\n' "$apply_output"
  fi
}

cmd_down() {
  require_root
  validate_static_env
  local docker_rc=0 before_containers="[]" before_networks="[]" before_generated
  before_generated="$(generated_files_json)"
  if docker_ready; then
    acquire_endpoint_lock
    assert_owned_project cleanup
    before_containers="$(owned_containers_json)"
    before_networks="$(owned_networks_json)"
    cleanup_runtime_docker_resources || docker_rc=$?
    cleanup_runtime_assets_preserve_state
    cleanup_empty_parents_after_lock=true
  else
    docker_rc=1
    cleanup_transient_assets
    cleanup_empty_parents_after_lock=true
    warn "Docker unavailable or rejected; transient generated files were cleaned and durable state retained for reconciliation"
  fi
  if [[ "$output_json" == true ]]; then
    # shellcheck disable=SC2016
    emit_stack_json down "$([[ "$docker_rc" -eq 0 ]] && printf true || printf false)" \
      '. + {
        error: (if $dockerAvailable then null else {code: "docker-unavailable", message: "Docker unavailable or rejected during down", exitCode: 1} end),
        resources: (.resources + {owned: {containers: $containers, volumes: [], networks: $networks}, runtime: {dockerAvailable: $dockerAvailable, cleanupPolicy: "preserve-volumes"}}),
        artifacts: (.artifacts + {generated: $generated})
      }' \
      --argjson dockerAvailable "$([[ "$docker_rc" -eq 0 ]] && printf true || printf false)" \
      --argjson containers "$before_containers" \
      --argjson networks "$before_networks" \
      --argjson generated "$before_generated"
  fi
  return "$docker_rc"
}

emit_extension_run_json() {
  local command="$1"
  local rows="$2"
  local ok_json="${3:-}"
  local extensions_json
  extensions_json="$(printf '%s\n' "$rows" | apply_rows_json)"
  [[ -n "$ok_json" ]] || ok_json="$(jq -r 'all(.[]; (.required | not) or .state == "ok")' <<<"$extensions_json")"
  # shellcheck disable=SC2016
  emit_stack_json "$command" "$ok_json" \
    '($extensions | flatten) as $extensionRows
    | . + {
      extensions: {
        catalog: [],
        results: $extensionRows,
        summary: {
          ok: ([ $extensionRows[] | select(.state == "ok") ] | length),
          requiredOk: ([ $extensionRows[] | select(.required and .state == "ok") ] | length),
          requiredMissing: ([ $extensionRows[] | select(.required and .state != "ok") ] | length),
          available: ([ $extensionRows[] | select(.state == "available") ] | length),
          unavailable: ([ $extensionRows[] | select(.state == "unavailable") ] | length),
          disabled: ([ $extensionRows[] | select(.state == "disabled") ] | length)
        }
      }
    } + if $ok then {} else {error: {code: "required-extension-unavailable", message: "required extension check failed", exitCode: 1}} end' \
    --argjson extensions "$extensions_json"
  json_result_emitted=true
}

cmd_check() {
  local json=false
  command_wants_json check "$@" && json=true
  require_root
  validate_static_env
  require_docker
  assert_owned_project
  require_enabled_services
  if [[ "$json" == true ]]; then
    wait_services >/dev/null
  else
    wait_services
  fi
  local rows ok_json
  rows="$(check_rows)"
  apply_required_rows_ok "$rows" || ok_json=false
  if [[ "$json" == true ]]; then
    emit_extension_run_json check "$rows" "${ok_json:-}"
    if [[ "${ok_json:-true}" == false ]]; then
      exit 1
    fi
    return 0
  else
    printf '%s\n' "$rows"
    apply_required_rows_ok "$rows" || die "required extension check failed"
  fi
}

cmd_apply() {
  local json=false
  command_wants_json apply "$@" && json=true
  require_root
  validate_static_env
  require_mutating_docker
  assert_owned_project
  require_enabled_services
  if [[ "$json" == true ]]; then
    wait_services >/dev/null
  else
    wait_services
  fi
  local rows ok_json
  rows="$(apply_rows)"
  apply_required_rows_ok "$rows" || ok_json=false
  if [[ "$json" == true ]]; then
    emit_extension_run_json apply "$rows" "${ok_json:-}"
    if [[ "${ok_json:-true}" == false ]]; then
      exit 1
    fi
    return 0
  else
    printf '%s\n' "$rows"
    apply_required_rows_ok "$rows" || die "required extension apply failed"
  fi
}

cmd_psql_service() {
  local service="$1"
  shift
  require_root
  validate_static_env
  assert_no_active_mutation_for_psql
  require_docker
  local rc=0 cleanup_rc=0
  acquire_psql_session_lock "$service"
  trap 'rc=$?; release_psql_session_locks || true; exit "$rc"' EXIT
  trap 'trap - INT; forward_foreground_child INT; release_psql_session_locks || true; kill -INT "$$"' INT
  trap 'trap - TERM; forward_foreground_child TERM; release_psql_session_locks || true; kill -TERM "$$"' TERM
  trap 'trap - HUP; forward_foreground_child HUP; release_psql_session_locks || true; kill -HUP "$$"' HUP
  trap 'trap - QUIT; forward_foreground_child QUIT; release_psql_session_locks || true; kill -QUIT "$$"' QUIT
  psql_exec "$service" "$@" || rc=$?
  release_psql_session_locks || cleanup_rc=$?
  trap - EXIT INT TERM HUP QUIT
  ((rc == 0)) || return "$rc"
  ((cleanup_rc == 0)) || return "$cleanup_rc"
}

cmd_psql() {
  local service="${1:-}"
  [[ -n "$service" ]] || die_usage "psql requires a service: timescale, search, or pgduckdb"
  known_service "$service" || die_usage "unknown psql service: $service"
  shift
  [[ "${1:-}" == "--" ]] && shift
  cmd_psql_service "$service" "$@"
}

cmd_status() {
  require_root
  validate_static_env
  local docker_ok=false docker_issue="Docker unavailable or rejected" containers_json="[]" ports_json="[]" lock_state
  if docker_ready; then
    docker_ok=true
    containers_json="$(owned_containers_json)"
    ports_json="$(port_records_json)"
  else
    ports_json="$(port_records_offline_json)"
  fi
  lock_state="$(lock_json)"
  if command_wants_json status "$@"; then
    # shellcheck disable=SC2016
    emit_stack_json status true \
      '. + {
        ports: $ports,
        resources: (.resources + {owned: {containers: $containers, volumes: [], networks: []}, runtime: {dockerAvailable: $dockerAvailable, dockerIssue: (if $dockerAvailable then null else $dockerIssue end), lock: $lock}}),
        state: (
          ($services | to_entries | map(.value)) as $serviceList
          | if ($dockerAvailable | not) then "docker-unavailable"
            elif ($containers | length) == 0 then "empty"
            elif any($containers[]; .identityOk == false) then "stale"
            elif any($containers[]; (($services[.service].enabled // false) | not)) then "stale"
            elif any($serviceList[]; . as $svc | $svc.enabled and ([ $containers[] | select(.service == $svc.key and .status == "running") ] | length) != 1) then "partial"
            elif any($containers[]; .status != "running") then "partial"
            else "present"
            end
        )
      }' \
      --argjson dockerAvailable "$docker_ok" \
      --arg dockerIssue "$docker_issue" \
      --argjson containers "$containers_json" \
      --argjson ports "$ports_json" \
      --argjson lock "$lock_state"
    return 0
  fi
  local ids=()
  local id service name image state health ports identity_json identity_ok identity_issue
  if [[ "$docker_ok" != true ]]; then
    printf 'status\tstate=docker-unavailable\tproject=%s\troot=%s\treason=%s\n' "$project_name" "$root_key" "$docker_issue"
    return 0
  fi
  collect_owned_container_ids ids
  if ((${#ids[@]} == 0)); then
    printf 'status\tstate=empty\tproject=%s\troot=%s\n' "$project_name" "$root_key"
    return 0
  fi
  for id in "${ids[@]}"; do
    service="$(inspect_label "$id" "$service_label")"
    name="$(inspect_name "$id" || printf '-')"
    image="$(docker inspect --format '{{ .Config.Image }}' "$id" || printf '-')"
    state="$(docker inspect --format '{{ .State.Status }}' "$id" || printf '-')"
    health="$(docker inspect --format '{{ if .State.Health }}{{ .State.Health.Status }}{{ else }}none{{ end }}' "$id" || printf '-')"
    ports="$(published_ports "$id")"
    identity_json="$(docker inspect "$id" | jq -r \
      --arg service "$service" \
      --arg image "$(service_image "$service")" \
      --arg net "$(network_name)" \
      --arg volume "$(service_volume_name "$service")" \
      --arg mount "${service_volume_mount[$service]}" '
        .[0] as $container
        | ($container.Config.Image == $image
          and ($container.NetworkSettings.Networks[$net] != null)
          and any($container.Mounts[]?; .Name == $volume and .Destination == $mount)) as $ok
        | [$ok, (if $ok then "-" elif $container.Config.Image != $image then "image-mismatch" elif ($container.NetworkSettings.Networks[$net] == null) then "network-mismatch" else "volume-mount-mismatch" end)]
        | @tsv
      ')"
    IFS=$'\t' read -r identity_ok identity_issue <<<"$identity_json"
    printf 'status\tservice=%s\tcontainer_id=%s\tname=%s\timage=%s\tdocker_status=%s\thealth=%s\tports=%s\tidentity_ok=%s\tidentity_issue=%s\tproject=%s\troot=%s\n' \
      "$service" "$id" "$name" "$image" "$state" "$health" "$ports" "$identity_ok" "$identity_issue" "$project_name" "$root_key"
  done
}

cmd_env() {
  require_root
  validate_static_env
  if command_wants_json env "$@"; then
    emit_stack_json env true '.'
    return 0
  fi
  printf 'export FORGE_PROVISION_ROOT=%q\n' "$forge_root"
  printf 'export FORGE_PROVISION_PROJECT=%q\n' "$project_key"
  printf 'export FORGE_PROVISION_INSTANCE=%q\n' "$instance_name"
  printf 'export FORGE_PROVISION_COMPOSE_PROJECT=%q\n' "$project_name"
  printf 'export FORGE_PROVISION_DIR=%q\n' "$provisioning_dir"
  printf 'export FORGE_PROVISION_COMPOSE=%q\n' "$compose_file"
  printf 'export FORGE_PROVISION_ENV=%q\n' "$env_file"
  local service
  for service in "${service_order[@]}"; do
    if service_enabled "$service"; then
      printf 'export %s=%q\n' "${service_dsn_env[$service]}" "$(service_dsn "$service")"
    else
      printf 'unset %s\n' "${service_dsn_env[$service]}"
    fi
  done
  printf 'export FORGE_PROVISION_PGDUCKDB=%q\n' "$(service_enabled_value pgduckdb)"
}

cmd_paths() {
  require_root
  if command_wants_json paths "$@"; then
    emit_stack_json paths true '.'
    return 0
  fi
  printf 'path\tname=forge_root\tvalue=%s\texists=%s\n' "$forge_root" "$([[ -d "$forge_root" ]] && printf true || printf false)"
  printf 'path\tname=provisioning_root\tvalue=%s\texists=%s\n' "$provisioning_root_dir" "$([[ -d "$provisioning_root_dir" ]] && printf true || printf false)"
  printf 'path\tname=provisioning_dir\tvalue=%s\texists=%s\tparent_writable=%s\n' "$provisioning_dir" "$([[ -d "$provisioning_dir" ]] && printf true || printf false)" "$([[ -w "$forge_root" ]] && printf true || printf false)"
  printf 'path\tname=current\tvalue=%s\texists=%s\texpected_written_by=up\n' "$current_link" "$([[ -e "$current_link" ]] && printf true || printf false)"
  printf 'path\tname=compose\tvalue=%s\texists=%s\texpected_written_by=up\n' "$compose_file" "$([[ -f "$compose_file" ]] && printf true || printf false)"
  printf 'path\tname=env\tvalue=%s\texists=%s\texpected_written_by=up\n' "$env_file" "$([[ -f "$env_file" ]] && printf true || printf false)"
  printf 'path\tname=docker_config\tvalue=%s\texists=%s\texpected_written_by=up\n' "$docker_config_dir" "$([[ -d "$docker_config_dir" ]] && printf true || printf false)"
}

cmd_plan() {
  require_root
  validate_static_env
  if command_wants_json plan "$@"; then
    # shellcheck disable=SC2016
    emit_stack_json plan true \
      '. + {artifacts: (.artifacts + {plan: {composeYaml: "redacted", authMode: .auth.mode, cleanupPolicy: "down-preserves-volumes", rollbackPolicy: "best-effort-compose-generation", imageStability: "best-effort-image-tag"}}), ports: ([.services | to_entries[] | {service: .key, value: .value.port, env: .value.portEnv, portSource: .value.portSource}])}'
    return 0
  fi
  render_compose
}

cmd_extensions() {
  require_root
  validate_static_env
  if command_wants_json extensions "$@"; then
    # shellcheck disable=SC2016
    emit_stack_json extensions true '. + {extensions: {catalog: $catalog, results: [], summary: {catalog: ($catalog | length)}}}' \
      --argjson catalog "$(provision_extension_catalog_json)"
    return 0
  fi
  local service ext category required create_on_apply enabled required_bool create_bool
  for service in "${service_order[@]}"; do
    enabled="$(service_enabled_value "$service")"
    while IFS=$'\t' read -r ext category required create_on_apply _create_policy _load_policy _probe_kind _probe_sql_key _requires_shared_preload _shared_preload_library extra; do
      [[ -n "$ext" ]] || continue
      [[ -z "${extra:-}" ]] || die "extension catalog row has too many fields service=$service extension=$ext"
      required_bool=false
      create_bool=false
      [[ "$required" == 1 ]] && required_bool=true
      [[ "$create_on_apply" == 1 ]] && create_bool=true
      printf 'extension\tservice=%s\tname=%s\tcategory=%s\trequired=%s\tcreate_on_apply=%s\tenabled=%s\n' \
        "$service" "$ext" "$category" "$required_bool" "$create_bool" "$enabled"
    done < <(extension_catalog_rows "$service")
  done
  return 0
}

cmd_tools() {
  require_root
  validate_static_env
  local surfaces_json ok_json=true
  if ! surfaces_json="$(tool_surfaces_json)"; then
    ok_json=false
    surfaces_json="{}"
  fi
  if command_wants_json tools "$@"; then
    # shellcheck disable=SC2016
    emit_stack_json tools "$ok_json" \
      '. + {
        tools: {
          surfaces: $surfaces,
          summary: {
            selectedSurface: $selected,
            surfaceCount: ($surfaces | keys | length),
            catalogRows: ([ $surfaces[]?.catalog[]? ] | length),
            ok: $ok
          }
        }
      } + if $ok then {} else {error: {code: "tool-probe-failed", message: "selected Forge tool surface probe failed", exitCode: 1}} end' \
      --arg selected "$tool_surface_selector" \
      --argjson ok "$ok_json" \
      --argjson surfaces "$surfaces_json"
    [[ "$ok_json" == true ]] || exit 1
    return 0
  fi
  jq -r '
    to_entries[]
    | "tool\tsurface=\(.key)\tok=\(.value.ok)\tcatalog_rows=\((.value.catalog // []) | length)"
  ' <<<"$surfaces_json"
  [[ "$ok_json" == true ]] || return 1
}

cmd_ports() {
  require_root
  validate_static_env
  local docker_ok=false docker_issue="Docker unavailable or rejected" ports_json
  if docker_ready; then
    docker_ok=true
    ports_json="$(port_records_json)"
  else
    ports_json="$(port_records_offline_json)"
  fi
  if command_wants_json ports "$@"; then
    # shellcheck disable=SC2016
    emit_stack_json ports true \
      '. + {ports: $ports, resources: (.resources + {runtime: {dockerAvailable: $dockerAvailable, dockerIssue: (if $dockerAvailable then null else $dockerIssue end)}})}' \
      --argjson dockerAvailable "$docker_ok" \
      --arg dockerIssue "$docker_issue" \
      --argjson ports "$ports_json"
    return 0
  fi
  emit_ports_text "$ports_json"
}

listener_probe_method() {
  if command -v lsof >/dev/null 2>&1; then
    printf 'lsof'
  elif command -v ss >/dev/null 2>&1; then
    printf 'ss'
  elif [[ -r /proc/net/tcp || -r /proc/net/tcp6 ]]; then
    printf 'proc-net'
  else
    printf 'unavailable'
  fi
}

cmd_doctor() {
  require_root
  validate_static_env
  local json=false
  if command_wants_json doctor "$@"; then
    json=true
  fi
  local docker_path="-" policy_status="ok" policy_reason="" incoming_host="${DOCKER_HOST:-}" incoming_context="${DOCKER_CONTEXT:-}"
  local host_docker_config="${DOCKER_CONFIG:-$HOME/.docker}/config.json" host_creds_store="none" host_cred_helpers="0"
  local compose_version="unavailable" docker_server="unavailable" ports_available=false ports_json="[]" anonymous_config_exists=false issue="" listener_method
  listener_method="$(listener_probe_method)"
  resolve_docker_endpoint
  if ! issue="$(docker_runtime_issue)"; then
    policy_status="rejected"
    policy_reason="$issue"
  else
    apply_docker_endpoint
  fi
  [[ -f "$host_docker_config" ]] && host_creds_store="$(jq -r '.credsStore // .credStore // "none"' "$host_docker_config" 2>/dev/null || printf 'unreadable')"
  [[ -f "$host_docker_config" ]] && host_cred_helpers="$(jq -r '(.credHelpers // {}) | length' "$host_docker_config" 2>/dev/null || printf 'unreadable')"
  [[ -f "$docker_config_dir/config.json" ]] && anonymous_config_exists=true
  docker_path="$(command -v docker || printf '-')"
  if [[ "$policy_status" == "ok" ]] && docker info >/dev/null 2>&1; then
    compose_version="$(docker_compose_version)"
    docker_server="$(docker info --format '{{.ServerVersion}}' 2>/dev/null || printf 'unavailable')"
    ports_available=true
    ports_json="$(port_records_json)"
  fi
  if [[ "$json" == true ]]; then
    # shellcheck disable=SC2016
    emit_stack_json doctor true \
      '. + {
        ports: $ports,
        resources: (.resources + {
          runtime: {
            forgeProvision: {present: true, schemaVersion: $schemaVersion},
            docker: {
              present: ($dockerPath != "-"),
              executableKind: (if $dockerPath == "-" then null elif ($dockerPath | startswith("/nix/store/")) then "nix-store" else "host-path" end),
              policy: {status: $policyStatus, reason: (if $policyReason == "" then null else $policyReason end)},
              endpointKind: (if $resolvedEndpoint | startswith("unix://") then "unix" elif $resolvedEndpoint | startswith("tcp://") then "tcp" elif $resolvedEndpoint | startswith("ssh://") then "ssh" else "unknown" end),
              compose: $composeVersion,
              server: $dockerServer,
              hostConfig: {
                credentialHelperPresent: ($hostCredsStore != "none" or $hostCredHelpers != "0"),
                credHelpers: (try ($hostCredHelpers | tonumber) catch null),
                warning: (if $hostCredsStore != "none" or $hostCredHelpers != "0" then "credential-helper-present-for-host-config" else null end)
              },
              anonymousPullConfig: {exists: $anonymousConfigExists}
            },
            compose: {present: ($composeVersion != "unavailable"), version: (if $composeVersion == "unavailable" then null else $composeVersion end)},
            jq: {present: true},
            listenerProbeMethod: $listenerProbeMethod,
            portsInspectable: $portsInspectable,
            portsUsable: ($portsInspectable and all($ports[]; .state == "disabled" or .owner == "none" or .owner == "provision:this-project")),
            blockedPorts: [$ports[] | select(.state != "disabled" and .owner != "none" and .owner != "provision:this-project")],
            lock: $lock,
            colima: $colima,
            anonymousDockerConfig: $anonymousConfigExists,
            hostCredentialHelperPresent: ($hostCredsStore != "none" or $hostCredHelpers != "0")
          }
        })
      }
      + if $diagnostic then {diagnostic: {endpointFingerprint: (if $endpointFingerprint == "" then null else $endpointFingerprint end), dockerEndpointRedacted: true, dockerPathRedacted: true}} else {} end' \
      --arg dockerPath "$docker_path" \
      --arg policyStatus "$policy_status" \
      --arg policyReason "$policy_reason" \
      --arg resolvedEndpoint "$docker_endpoint" \
      --arg endpointFingerprint "$(docker_endpoint_hash 2>/dev/null || true)" \
      --arg hostCredsStore "$host_creds_store" \
      --arg hostCredHelpers "$host_cred_helpers" \
      --argjson anonymousConfigExists "$anonymous_config_exists" \
      --arg composeVersion "$compose_version" \
      --arg dockerServer "$docker_server" \
      --arg listenerProbeMethod "$listener_method" \
      --argjson portsInspectable "$ports_available" \
      --argjson ports "$ports_json" \
      --argjson lock "$(lock_json)" \
      --argjson colima "$(colima_json)" \
      --argjson diagnostic "$([[ "$diagnostic_json" == true ]] && printf true || printf false)" \
      --argjson schemaVersion "$schema_version"
    return 0
  fi
  printf 'doctor\tcommand=forge-provision\n'
  printf 'doctor\tforge_root=%s\n' "$forge_root"
  printf 'doctor\tproject=%s\n' "$project_name"
  printf 'doctor\troot_key=%s\n' "$root_key"
  printf 'doctor\tdocker=%s\n' "$docker_path"
  printf 'doctor\tdocker_policy=%s\n' "$policy_status"
  [[ -z "$policy_reason" ]] || printf 'doctor\tdocker_policy_reason=%s\n' "$policy_reason"
  printf 'doctor\tresolved_endpoint=%s\n' "$docker_endpoint"
  printf 'doctor\tincoming_docker_host=%s\n' "$incoming_host"
  printf 'doctor\tincoming_docker_context=%s\n' "$incoming_context"
  printf 'doctor\tactive_docker_host=%s\n' "${DOCKER_HOST:-}"
  printf 'doctor\tactive_docker_context=%s\n' "${DOCKER_CONTEXT:-}"
  printf 'doctor\tdocker_config=%s\n' "${DOCKER_CONFIG:-$HOME/.docker}"
  printf 'doctor\thost_docker_config=%s\n' "$host_docker_config"
  printf 'doctor\thost_docker_config_credsStore=%s\n' "$host_creds_store"
  printf 'doctor\thost_docker_config_credHelpers=%s\n' "$host_cred_helpers"
  printf 'doctor\tanonymous_pull_config=%s\texists=%s\n' "$docker_config_dir/config.json" "$anonymous_config_exists"
  printf 'doctor\tdocker_compose=%s\n' "$compose_version"
  printf 'doctor\tdocker_server=%s\n' "$docker_server"
  printf 'doctor\tports_inspectable=%s\n' "$ports_available"
  printf 'doctor\tports_usable=%s\n' "$(jq -r 'all(.[]; .state == "disabled" or .owner == "none" or .owner == "provision:this-project")' <<<"$ports_json")"
  if [[ "$ports_available" == true ]]; then
    emit_ports_text "$ports_json"
  else
    printf 'doctor\tports=skipped\treason=docker-unavailable-or-policy-failed\n'
  fi
}

cmd_inventory() {
  require_root
  validate_static_env
  local json=false
  if command_wants_json inventory "$@"; then
    json=true
  fi
  local docker_ok=false containers_json="[]" volumes_json="[]" networks_json="[]" images_json="[]" docker_disk="[]" ports_json="[]"
  if docker_ready; then
    docker_ok=true
    containers_json="$(owned_containers_json)"
    volumes_json="$(owned_volumes_json)"
    networks_json="$(owned_networks_json)"
    images_json="$(relevant_images_json)"
    docker_disk="$(docker_disk_json)"
    ports_json="$(port_records_json)"
  fi
  if [[ "$json" == true ]]; then
    # shellcheck disable=SC2016
    emit_stack_json inventory true \
      '. + {
        ports: $ports,
        resources: {
          counts: $counts,
          owned: {containers: $containers, volumes: $volumes, networks: $networks},
          images: $images,
          dockerDisk: $dockerDisk,
          runtime: {
            dockerAvailable: $dockerAvailable,
            configuredImages: $configuredImages,
            lock: $lock,
            colima: $colima,
            nonOwnedCleanupPolicy: "diagnostic-only"
          }
        },
        artifacts: (.artifacts + {generated: $generated})
      }' \
      --argjson dockerAvailable "$docker_ok" \
      --argjson containers "$containers_json" \
      --argjson volumes "$volumes_json" \
      --argjson networks "$networks_json" \
      --argjson generated "$(generated_files_json)" \
      --argjson counts "$(resource_counts_json "$containers_json" "$volumes_json" "$networks_json" "$(generated_files_json)")" \
      --argjson configuredImages "$(configured_images_json)" \
      --argjson images "$images_json" \
      --argjson dockerDisk "$docker_disk" \
      --argjson ports "$ports_json" \
      --argjson lock "$(lock_json)" \
      --argjson colima "$(colima_json)"
    return 0
  fi
  printf 'inventory\tproject=%s\troot=%s\tpolicy=owned-only\tdocker_available=%s\n' "$project_name" "$root_key" "$docker_ok"
  printf 'inventory\towned_containers=%s\n' "$(jq -r length <<<"$containers_json")"
  printf 'inventory\towned_volumes=%s\n' "$(jq -r length <<<"$volumes_json")"
  printf 'inventory\towned_networks=%s\n' "$(jq -r length <<<"$networks_json")"
  printf 'inventory\trelevant_images=%s\n' "$(jq -r length <<<"$images_json")"
  printf 'inventory\tdocker_disk_rows=%s\n' "$(jq -r length <<<"$docker_disk")"
  printf 'inventory\tnon_owned_cleanup_policy=diagnostic-only\n'
}

cmd_prune() {
  local json=false include_volumes=false arg
  [[ "$output_json" == true ]] && json=true
  for arg in "$@"; do
    case "$arg" in
      --owned) ;;
      --volumes) include_volumes=true ;;
      *) die_usage "prune requires --owned and accepts optional --volumes and --json" ;;
    esac
  done
  require_root
  validate_static_env
  local docker_ok=false before_containers="[]" before_volumes="[]" before_networks="[]" before_generated rc=0
  before_generated="$(generated_files_json)"
  if docker_ready; then
    docker_ok=true
    acquire_endpoint_lock
    assert_owned_project cleanup
    before_containers="$(owned_containers_json)"
    before_volumes="$(owned_volumes_json)"
    before_networks="$(owned_networks_json)"
    remove_owned_containers || rc=$?
    if [[ "$include_volumes" == true ]]; then
      remove_owned_volumes || rc=$?
    fi
    remove_owned_networks || rc=$?
    if [[ "$include_volumes" == true ]]; then
      cleanup_assets
    else
      cleanup_runtime_assets_preserve_state
    fi
    cleanup_empty_parents_after_lock=true
  else
    rc=1
    cleanup_transient_assets
    cleanup_empty_parents_after_lock=true
    warn "Docker unavailable or rejected; transient generated files were cleaned and durable state retained for reconciliation"
  fi
  if [[ "$json" == true ]]; then
    # shellcheck disable=SC2016
    emit_stack_json prune "$([[ "$rc" -eq 0 ]] && printf true || printf false)" \
      '. + {
        error: (if $ok then null else {code: "docker-unavailable", message: "Docker unavailable or rejected during prune", exitCode: 1} end),
        resources: (.resources + {owned: {containers: $containers, volumes: $volumes, networks: $networks}, runtime: {dockerAvailable: $dockerAvailable, includeVolumes: $includeVolumes}}),
        artifacts: (.artifacts + {generated: $generated})
      }' \
      --argjson dockerAvailable "$docker_ok" \
      --argjson containers "$before_containers" \
      --argjson volumes "$before_volumes" \
      --argjson networks "$before_networks" \
      --argjson generated "$before_generated" \
      --argjson includeVolumes "$include_volumes"
  else
    printf 'prune\towned\tok=%s\tproject=%s\troot=%s\n' "$([[ "$rc" -eq 0 ]] && printf true || printf false)" "$project_name" "$root_key"
  fi
  return "$rc"
}

cmd_self_test() {
  require_root
  validate_static_env
  local command service port ext category required create_on_apply extra tmp_dir tmp_src tmp_dst
  local -A seen_commands=() seen_order=() seen_ports=()
  local -A seen_extensions=()
  [[ "$schema_version" == 3 ]] || die "unexpected Forge schema version: $schema_version"
  [[ -z "${command_handler["forge-spike-stack"]+x}" ]] || die "retired forge-spike-stack command is still registered"
  [[ -z "${command_handler["psql-timescale"]+x}" ]] || die "retired psql-timescale command is still registered"
  [[ -z "${command_handler["psql-search"]+x}" ]] || die "retired psql-search command is still registered"
  [[ -z "${command_handler["psql-pgduckdb"]+x}" ]] || die "retired psql-pgduckdb command is still registered"
  for command in "${!command_handler[@]}"; do
    [[ -n "${command_desc[$command]:-}" ]] || die "command missing description: $command"
    [[ -n "${command_argspec[$command]:-}" ]] || die "command missing argspec: $command"
    [[ -n "${command_required_root[$command]:-}" ]] || die "command missing root policy: $command"
    [[ -n "${command_required_docker[$command]:-}" ]] || die "command missing docker policy: $command"
    [[ -n "${command_lock_mode[$command]:-}" ]] || die "command missing lock mode: $command"
    declare -F "${command_handler[$command]}" >/dev/null || die "command handler function missing: $command -> ${command_handler[$command]}"
    seen_commands[$command]=1
  done
  for command in "${command_order[@]}"; do
    [[ -n "${command_handler[$command]:-}" ]] || die "ordered command missing handler: $command"
    [[ -n "${seen_order[$command]:-}" ]] && die "duplicate command_order entry: $command"
    seen_order[$command]=1
  done
  for command in "${!command_handler[@]}"; do
    [[ -n "${seen_order[$command]:-}" ]] || die "command handler missing command_order entry: $command"
  done
  for command in "${!command_desc[@]}"; do
    [[ -n "${seen_commands[$command]:-}" ]] || die "description missing handler: $command"
  done
  for command in "${!command_mutates[@]}"; do
    [[ -n "${command_handler[$command]:-}" ]] || die "mutating command missing handler: $command"
    [[ "${command_lock_mode[$command]}" == "mutation" ]] || die "mutating command must use mutation lock mode: $command"
  done
  for service in "${service_order[@]}"; do
    known_service "$service" || die "unknown service in service_order: $service"
    [[ -n "${service_role[$service]}" ]] || die "service missing role: $service"
    [[ -n "${service_profile[$service]}" ]] || die "service missing profile: $service"
    [[ -n "${service_image_env[$service]}" ]] || die "service missing image env: $service"
    [[ -n "${service_port_env[$service]}" ]] || die "service missing port env: $service"
    [[ -n "${service_dsn_env[$service]}" ]] || die "service missing dsn env: $service"
    [[ -n "${service_apply_handler[$service]}" ]] || die "service missing apply handler: $service"
    [[ -n "${service_apply_sql_key[$service]}" ]] || die "service missing apply SQL key: $service"
    port="$(service_port "$service")"
    if service_enabled "$service"; then
      [[ -z "${seen_ports[$port]:-}" ]] || die "enabled service port collision: $service and ${seen_ports[$port]}"
      seen_ports[$port]="$service"
    fi
    seen_extensions=()
    while IFS=$'\t' read -r ext category required create_on_apply _create_policy _load_policy _probe_kind _probe_sql_key _requires_shared_preload _shared_preload_library extra; do
      [[ -n "$ext" ]] || continue
      [[ -z "${extra:-}" ]] || die "extension catalog row has too many fields service=$service extension=$ext"
      [[ "$ext" =~ ^[A-Za-z0-9_][A-Za-z0-9_-]*$ ]] || die "invalid extension name service=$service extension=$ext"
      [[ "$category" =~ ^[a-z][a-z0-9-]*$ ]] || die "invalid extension category service=$service extension=$ext category=$category"
      [[ "$required" =~ ^[01]$ ]] || die "invalid extension required flag service=$service extension=$ext required=$required"
      [[ "$create_on_apply" =~ ^[01]$ ]] || die "invalid extension create flag service=$service extension=$ext create_on_apply=$create_on_apply"
      [[ "$required" == "$create_on_apply" ]] || die "required extensions are the only create-on-apply targets service=$service extension=$ext required=$required create_on_apply=$create_on_apply"
      [[ -z "${seen_extensions[$ext]:-}" ]] || die "duplicate extension catalog row service=$service extension=$ext"
      seen_extensions[$ext]=1
    done < <(extension_catalog_rows "$service")
    ((${#seen_extensions[@]} > 0)) || die "service missing extension catalog rows: $service"
  done
  tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/forge-provision-self-test.XXXXXX")" || die "mktemp failed for self-test"
  tmp_src="$tmp_dir/source"
  tmp_dst="$tmp_dir/dest"
  mkdir -p "$tmp_src"
  if ! mv -T "$tmp_src" "$tmp_dst" 2>/dev/null; then
    rm -rf -- "$tmp_dir"
    die "GNU mv -T unavailable in current PATH; run the packaged Nix forge-provision command, not the raw source script"
  fi
  rm -rf -- "$tmp_dir"
  validate_forge_root "$forge_root"
  if [[ "$output_json" == true ]]; then
    emit_stack_json self-test true '. + {checks: {commands: true, services: true, extensions: true, root: true, gnuCoreutils: true}}'
  else
    printf 'self-test\tok\t%s\n' "$forge_root"
  fi
}

main() {
  while (($# > 0)); do
    case "${1:-}" in
      --json)
        if [[ "$output_json" == true ]]; then
          [[ "$diagnostic_json" == true ]] && die_usage "--json and --diagnostic-json are mutually exclusive"
          die_usage "duplicate --json"
        fi
        output_json=true
        shift
        ;;
      --diagnostic-json)
        if [[ "$output_json" == true ]]; then
          [[ "$diagnostic_json" == true ]] && die_usage "duplicate --diagnostic-json"
          die_usage "--json and --diagnostic-json are mutually exclusive"
        fi
        output_json=true
        diagnostic_json=true
        shift
        ;;
      --)
        shift
        break
        ;;
      *)
        break
        ;;
    esac
  done
  local command="${1:-}"
  shift || true
  current_command="$command"
  case "$command" in
    verify)
      die_usage "verify is retired; use check for read-only verification or apply for mutating extension creation"
      ;;
  esac
  if [[ "$output_json" == true && -n "$command" ]]; then
    command_supports_json "$command" || die_usage "$command does not support JSON output"
  fi
  case "$command" in
    help | --help | -h | "")
      usage
      return 0
      ;;
  esac
  [[ -v command_handler["$command"] ]] || {
    usage >&2
    die_usage "unknown command: $command"
  }
  current_command="$command"
  if [[ "$diagnostic_json" == true ]] && ! command_supports_diagnostic_json "$command"; then
    die_usage "--diagnostic-json is allowed only for doctor, paths, and inventory"
  fi
  normalize_command_args "$command" "$@"
  if [[ -v command_mutates["$command"] ]]; then
    with_mutation_lock "$command" "${command_handler[$command]}" "${parsed_args[@]}"
  else
    "${command_handler[$command]}" "${parsed_args[@]}"
  fi
}

main "$@"
