# shellcheck shell=bash
set -Eeuo pipefail
shopt -s inherit_errexit array_expand_once nullglob

readonly schema_version=2
readonly owner_label="dev.bsamiee.rasm-provision"
readonly service_label="dev.bsamiee.rasm.service"
readonly root_label="dev.bsamiee.rasm.root"
readonly project_label="dev.bsamiee.rasm.project"
readonly resource_label="dev.bsamiee.rasm.resource"
readonly generation_label="dev.bsamiee.rasm.generation"
readonly project_override="${RASM_PROVISION_PROJECT:-}"
readonly lock_wait_seconds="${RASM_PROVISION_LOCK_WAIT_SECONDS:-30}"
readonly lock_ttl_seconds="${RASM_PROVISION_LOCK_TTL_SECONDS:-900}"
readonly compose_parallel_limit="${RASM_PROVISION_COMPOSE_PARALLEL_LIMIT:-1}"
readonly max_active_projects="${RASM_PROVISION_MAX_ACTIVE_PROJECTS:-4}"
readonly default_colima_socket="$HOME/.local/share/colima/default/docker.sock"
readonly default_port_range="15364-15554,25010-25099,25101-25470,25472-25575"
readonly fixed_port_base="${RASM_PROVISION_PORT_BASE:-}"
readonly port_policy_requested="${RASM_PROVISION_PORT_POLICY:-auto}"
readonly port_range_requested="${RASM_PROVISION_PORT_RANGE:-$default_port_range}"
readonly port_exclude_requested="${RASM_PROVISION_PORT_EXCLUDE:-}"
readonly auth_mode_requested="${RASM_PROVISION_AUTH:-auto-root}"
readonly pg_cron_requested="${RASM_PROVISION_PG_CRON:-auto}"
host_os="$(uname -s 2>/dev/null || printf unknown)"
readonly host_os
readonly port_lock_root="${XDG_STATE_HOME:-$HOME/.local/state}/rasm-provision/port-locks"
readonly session_lock_root="${XDG_STATE_HOME:-$HOME/.local/state}/rasm-provision/sessions"

declare -Ar command_handler=(
  [up]=cmd_up
  [down]=cmd_down
  [status]=cmd_status
  [env]=cmd_env
  [doctor]=cmd_doctor
  [ports]=cmd_ports
  [inventory]=cmd_inventory
  [prune]=cmd_prune
  [paths]=cmd_paths
  [plan]=cmd_plan
  [extensions]=cmd_extensions
  [verify]=cmd_verify
  [psql]=cmd_psql
  ["self-test"]=cmd_self_test
)

declare -Ar command_desc=(
  [up]="Start enabled PostgreSQL provisioning services; accepts --json"
  [down]="Stop owned containers/networks and remove project generated files; preserve volumes; accepts --json"
  [status]="Show owned provisioning service status; accepts --json"
  [env]="Print derived paths and connection environment without writing files; accepts --json"
  [doctor]="Inspect Docker, Colima, paths, locks, and ports; accepts --json"
  [ports]="Report configured host ports and current listeners; accepts --json"
  [inventory]="Report owned resources, generated files, configured images, and Docker disk state; accepts --json"
  [prune]="Remove current-project owned containers, volumes, networks, and generated files with --owned; accepts --json"
  [paths]="Print derived provisioning paths; accepts --json"
  [plan]="Render the compose plan to stdout without writing files; accepts --json"
  [extensions]="Print the PostgreSQL extension target catalog; accepts --json"
  [verify]="Create and verify enabled PostgreSQL provisioning extensions; accepts --json"
  [psql]="Open psql inside an owned service: psql <timescale|search|pgduckdb> [-- <psql-args>]"
  ["self-test"]="Validate local script metadata and configuration; accepts --json"
)

declare -Ar command_mutates=(
  [up]=1
  [down]=1
  [verify]=1
  [prune]=1
)

declare -Ar command_json=(
  [up]=1
  [down]=1
  [status]=1
  [env]=1
  [doctor]=1
  [ports]=1
  [inventory]=1
  [prune]=1
  [paths]=1
  [plan]=1
  [extensions]=1
  [verify]=1
  ["self-test"]=1
)

declare -ar command_order=(
  up
  down
  status
  env
  doctor
  ports
  inventory
  prune
  paths
  plan
  extensions
  verify
  psql
  self-test
)

declare -ar service_order=(timescale search pgduckdb)
declare -Ar service_profile=(
  [timescale]="timescale"
  [search]="pg_search"
  [pgduckdb]="analytics-probe"
)
declare -Ar service_enabled_env=(
  [timescale]=""
  [search]=""
  [pgduckdb]="RASM_PROVISION_PGDUCKDB"
)
declare -Ar service_enabled_default=(
  [timescale]=1
  [search]=1
  [pgduckdb]=0
)
declare -Ar service_image_env=(
  [timescale]="RASM_TIMESCALE_IMAGE"
  [search]="RASM_PARADEDB_IMAGE"
  [pgduckdb]="RASM_PGDUCKDB_IMAGE"
)
declare -Ar service_image_default=(
  [timescale]="timescale/timescaledb-ha:pg18.4-ts2.27.2-all"
  [search]="paradedb/paradedb:0.24.0-pg18"
  [pgduckdb]="pgduckdb/pgduckdb:18-v1.1.1"
)
declare -Ar service_port_env=(
  [timescale]="RASM_TIMESCALE_PORT"
  [search]="RASM_SEARCH_PORT"
  [pgduckdb]="RASM_PGDUCKDB_PORT"
)
declare -Ar service_port_default=(
  [timescale]=15432
  [search]=15433
  [pgduckdb]=15434
)
declare -Ar service_dsn_env=(
  [timescale]="RASM_TIMESCALE_DSN"
  [search]="RASM_SEARCH_DSN"
  [pgduckdb]="RASM_PGDUCKDB_DSN"
)
declare -Ar service_volume_mount=(
  [timescale]="/home/postgres/pgdata/data"
  [search]="/var/lib/postgresql"
  [pgduckdb]="/var/lib/postgresql"
)
declare -Ar service_preload_base=(
  [timescale]="timescaledb"
  [search]="pg_search"
  [pgduckdb]="pg_duckdb"
)
declare -Ar service_verify_handler=(
  [timescale]="verify_service_extensions"
  [search]="verify_service_extensions"
  [pgduckdb]="verify_service_extensions"
)
declare -Ar service_disabled_verify_row=(
  [timescale]=""
  [search]=""
  [pgduckdb]=$'pgduckdb\tpg_duckdb\tdisabled\t-\tanalytics\toptional'
)
readonly extension_catalog_common_rows=$'pg_stat_statements\tobservability\t0\t0\nauto_explain\tobservability\t0\t0\npg_trgm\tsearch\t0\t0\nunaccent\tsearch\t0\t0\nbtree_gin\tindex\t0\t0\nbtree_gist\tindex\t0\t0\nbloom\tindex\t0\t0\nrum\tindex\t0\t0\nhypopg\tplanning\t0\t0\npg_qualstats\tobservability\t0\t0\npg_stat_kcache\tobservability\t0\t0\npg_wait_sampling\tobservability\t0\t0\npg_buffercache\tobservability\t0\t0\npg_prewarm\tperformance\t0\t0\npg_visibility\tobservability\t0\t0\npg_walinspect\tobservability\t0\t0\npg_freespacemap\tobservability\t0\t0\npg_logicalinspect\treplication\t0\t0\npgstattuple\tobservability\t0\t0\npageinspect\tobservability\t0\t0\npg_surgery\tmaintenance\t0\t0\npgrowlocks\tobservability\t0\t0\npg_overexplain\tobservability\t0\t0\namcheck\tmaintenance\t0\t0\npg_repack\tmaintenance\t0\t0\npg_partman\tpartitioning\t0\t0\npg_partman_bgw\tpartitioning\t0\t0\npg_squeeze\tmaintenance\t0\t0\npglogical\treplication\t0\t0\npg_net\tintegration\t0\t0\npgaudit\tobservability\t0\t0\npgcrypto\tcrypto\t0\t0\ncitext\ttext\t0\t0\nltree\ttopology\t0\t0\nfuzzystrmatch\ttext\t0\t0\nintarray\tarray\t0\t0\ntablefunc\tanalytics\t0\t0\npostgres_fdw\tfdw\t0\t0\nfile_fdw\tfdw\t0\t0\nwrappers\tfdw\t0\t0\nogr_fdw\tfdw\t0\t0\npgtap\ttesting\t0\t0\nhll\tanalytics\t0\t0\nsemver\tdata\t0\t0\nunit\tdata\t0\t0\norafce\tcompatibility\t0\t0\npg_tle\textension-management\t0\t0\npg_jsonschema\tvalidation\t0\t0\npg_hashids\tidentity\t0\t0\npgmq\tqueue\t0\t0\npg_later\tautomation\t0\t0\ntsm_system_rows\tsampling\t0\t0\ntsm_system_time\tsampling\t0\t0'
declare -Ar service_extension_catalog=(
  [timescale]=$'timescaledb\ttime\t1\t1\ntimescaledb_toolkit\ttime\t0\t0\npg_cron\tautomation\t1\t1\npostgis\tgeospatial\t1\t1\npostgis_topology\tgeospatial\t0\t0\npostgis_raster\tgeospatial\t0\t0\npostgis_sfcgal\tgeospatial\t0\t0\npostgis_tiger_geocoder\tgeospatial\t0\t0\naddress_standardizer\tgeospatial\t0\t0\naddress_standardizer_data_us\tgeospatial\t0\t0\npgrouting\tgeospatial\t0\t0\nh3\tgeospatial\t0\t0\nh3_postgis\tgeospatial\t0\t0\nmobilitydb\tgeospatial\t0\t0\npointcloud\tgeospatial\t0\t0\npointcloud_postgis\tgeospatial\t0\t0\nq3c\tgeospatial\t0\t0\nvector\tvector\t1\t1\nvectorscale\tvector\t1\t1\nvchord\tvector\t0\t0\npg_textsearch\tsearch\t0\t0\npgroonga\tsearch\t0\t0\npg_bigm\tsearch\t0\t0\nai\tai\t0\t0'
  [search]=$'pg_search\tsearch\t1\t1\npg_ivm\tmaterialization\t0\t0\npostgis\tgeospatial\t0\t0\npostgis_topology\tgeospatial\t0\t0\npostgis_tiger_geocoder\tgeospatial\t0\t0\npostgis_sfcgal\tgeospatial\t0\t0\npgrouting\tgeospatial\t0\t0\nh3\tgeospatial\t0\t0\nh3_postgis\tgeospatial\t0\t0\nvector\tvector\t1\t1\npgroonga\tsearch\t0\t0\npg_bigm\tsearch\t0\t0\nzhparser\tsearch\t0\t0'
  [pgduckdb]=$'pg_duckdb\tanalytics\t1\t1\nduckdb_fdw\tanalytics\t0\t0'
)
# shellcheck disable=SC2034
declare -Ar extension_source_package_map=(
  [timescaledb]="image:timescale/timescaledb-ha"
  [timescaledb_toolkit]="image:timescale/timescaledb-ha"
  [postgis]="image:timescale/timescaledb-ha|image:paradedb/paradedb|nixpkgs.postgresql_18.pkgs.postgis"
  [vector]="image:timescale/timescaledb-ha|image:paradedb/paradedb|nixpkgs.postgresql_18.pkgs.pgvector"
  [vectorscale]="image:timescale/timescaledb-ha|nixpkgs.postgresql_18.pkgs.pgvectorscale"
  [pg_search]="image:paradedb/paradedb"
  [pg_duckdb]="image:pgduckdb/pgduckdb|nixpkgs.postgresql_18.pkgs.pg_duckdb"
  [pg_cron]="image:timescale/timescaledb-ha|nixpkgs.postgresql_18.pkgs.pg_cron"
  [pgaudit]="nixpkgs.postgresql_18.pkgs.pgaudit"
  [pg_partman]="nixpkgs.postgresql_18.pkgs.pg_partman"
  [pg_partman_bgw]="nixpkgs.postgresql_18.pkgs.pg_partman"
  [pg_repack]="nixpkgs.postgresql_18.pkgs.pg_repack"
  [hypopg]="nixpkgs.postgresql_18.pkgs.hypopg"
  [rum]="nixpkgs.postgresql_18.pkgs.rum"
  [pg_textsearch]="nixpkgs.postgresql_18.pkgs.pg_textsearch"
  [pgroonga]="nixpkgs.postgresql_18.pkgs.pgroonga"
  [pg_bigm]="nixpkgs.postgresql_18.pkgs.pg_bigm"
  [pg_ivm]="image:paradedb/paradedb|nixpkgs.postgresql_18.pkgs.pg_ivm"
)
# shellcheck disable=SC2034
declare -Ar extension_risk_class_map=(
  [file_fdw]="external-access"
  [wrappers]="external-access"
  [ogr_fdw]="external-access"
  [pg_net]="external-access"
  [pg_cron]="background-worker"
  [pg_partman_bgw]="background-worker"
  [pg_squeeze]="background-worker"
  [pgaudit]="observability"
  [auto_explain]="observability"
  [pg_stat_statements]="observability"
)
readonly extension_preload_required_set="timescaledb pg_search auto_explain pg_stat_statements pg_partman_bgw pgaudit pg_cron pg_duckdb"
readonly extension_requires_superuser_set="timescaledb postgis vectorscale pg_search pg_duckdb file_fdw pg_cron pgaudit"
readonly extension_file_access_set="file_fdw pg_read_file"
readonly extension_network_access_set="postgres_fdw ogr_fdw wrappers pg_net"
readonly extension_background_worker_set="pg_cron pg_partman_bgw pg_squeeze"

rasm_root=""
project_name=""
root_fingerprint=""
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
declare -a port_lock_dirs=()
declare -a auto_port_blacklist=()
declare -a psql_session_locks=()
declare -A resolved_service_port=()
declare -A resolved_service_port_source=()
unpublished_generation=""
unpublished_compose_file=""
cleanup_empty_parents_after_lock=false
cleanup_assets_on_failed_up=false

on_err() {
  local rc=$?
  local stack="${FUNCNAME[*]:-main}"
  if [[ "$output_json" == true ]]; then
    [[ "$json_result_emitted" == false ]] || exit "$rc"
    emit_error_json "internal-error" "command failed rc=$rc line=${BASH_LINENO[0]:-?} stack=$stack" "$rc"
  else
    printf 'rasm-provision: error: command failed rc=%s line=%s stack=%s\n' "$rc" "${BASH_LINENO[0]:-?}" "$stack" >&2
  fi
  exit "$rc"
}
trap on_err ERR

emit_error_json() {
  local code="$1"
  local message="$2"
  local rc="${3:-1}"
  message="$(redact_message "$message")"
  set +e
  jq -nc \
    --argjson schemaVersion "$schema_version" \
    --arg command "${current_command:-unknown}" \
    --arg code "$code" \
    --arg message "$message" \
    --argjson exitCode "$rc" \
    '{schemaVersion: $schemaVersion, command: $command, ok: false, error: {code: $code, message: $message, exitCode: $exitCode}}' ||
    printf 'rasm-provision: failed to emit JSON error code=%s rc=%s\n' "$code" "$rc" >&2
  json_result_emitted=true
  set -e
}

die() {
  local message
  message="$(redact_message "$*")"
  if [[ "$output_json" == true ]]; then
    emit_error_json "error" "$message" 1
  else
    stderr_line "rasm-provision: $message"
  fi
  exit 1
}

die_usage() {
  local message
  message="$(redact_message "$*")"
  if [[ "$output_json" == true ]]; then
    emit_error_json "usage" "$message" 2
  else
    stderr_line "rasm-provision: usage: $message"
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
  stderr_line "rasm-provision: warning: $message"
}

redact_message() {
  local text="$*"
  local needle
  for needle in "$auth_secret_dir" "$docker_config_dir" "$provisioning_dir" "$provisioning_root_dir" "$rasm_root" "$default_colima_socket" "$docker_endpoint" "${DOCKER_CONFIG:-}" "${DOCKER_HOST:-}"; do
    [[ -n "$needle" ]] || continue
    text="${text//"$needle"/[redacted]}"
  done
  text="${text//POSTGRES_PASSWORD=*/POSTGRES_PASSWORD=[redacted]}"
  text="${text//PGPASSFILE=*/PGPASSFILE=[redacted]}"
  text="${text//DOCKER_CONFIG=*/DOCKER_CONFIG=[redacted]}"
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

parse_json_args() {
  local command="$1"
  shift
  if [[ "${1:-}" == "--json" ]]; then
    [[ "$output_json" == false ]] || die_usage "$command received --json both globally and locally"
    command_supports_json "$command" || die_usage "$command does not support JSON output"
    output_json=true
    shift
  fi
  if (($# > 0)); then
    die_usage "$command accepts only --json or no arguments"
  fi
}

command_wants_json() {
  local command="$1"
  shift
  if [[ "$output_json" == true ]]; then
    (($# == 0)) || die_usage "$command accepts no arguments when --json is global"
    return 0
  fi
  if [[ "${1:-}" == "--json" ]]; then
    command_supports_json "$command" || die_usage "$command does not support JSON output"
    (($# == 1)) || die_usage "$command --json accepts no additional arguments"
    output_json=true
    return 0
  fi
  (($# == 0)) || die_usage "$command accepts only --json or no arguments"
  return 1
}

prevalidate_mutating_args() {
  local command="$1"
  shift
  local arg seen_owned=false
  case "$command" in
    up | down)
      if [[ "$output_json" == true ]]; then
        (($# == 0)) || die_usage "$command accepts no arguments when --json is global"
      elif [[ "${1:-}" == "--json" ]]; then
        (($# == 1)) || die_usage "$command --json accepts no additional arguments"
      else
        (($# == 0)) || die_usage "$command accepts only --json or no arguments"
      fi
      ;;
    verify)
      if [[ "$output_json" == true ]]; then
        (($# == 0)) || die_usage "verify accepts no arguments when --json is global"
      elif [[ "${1:-}" == "--json" ]]; then
        (($# == 1)) || die_usage "verify --json accepts no additional arguments"
      else
        (($# == 0)) || die_usage "verify accepts only --json or no arguments"
      fi
      ;;
    prune)
      for arg in "$@"; do
        case "$arg" in
          --owned) seen_owned=true ;;
          --volumes) ;;
          --json) [[ "$output_json" == false ]] || die_usage "prune received --json both globally and locally" ;;
          *) die_usage "prune requires --owned and accepts optional --volumes and --json" ;;
        esac
      done
      [[ "$seen_owned" == true ]] || die_usage "prune requires --owned"
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
  printf 'Usage: rasm-provision [--json | --diagnostic-json] <command> [args]\n\nCommands:\n'
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
  printf 'postgres://postgres@127.0.0.1:%s/rasm' "$(service_port "$service")"
}

service_dsn_redacted() {
  local service="$1"
  if [[ "$auth_mode" == "auto-root" ]]; then
    printf 'postgres://postgres:***@127.0.0.1:%s/rasm' "$(service_port "$service")"
  else
    service_dsn "$service"
  fi
}

hash_text() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum
  else
    shasum -a 256
  fi
}

hash_prefix_decimal() {
  local text="$1"
  local digest
  digest="$(printf '%s' "$text" | hash_text)"
  digest="${digest%% *}"
  printf '%d\n' "$((16#${digest:0:8}))"
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
      die "RASM_PROVISION_AUTH must be auto-root or trust-loopback: $auth_mode_requested"
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
  if [[ "${RASM_PROVISION_ALLOW_EPHEMERAL_PORTS:-0}" == "1" ]]; then
    printf '\n'
    return 0
  fi
  case "$host_os" in
    Linux)
      if [[ -r /proc/sys/net/ipv4/ip_local_port_range ]]; then
        local first last reserved
        read -r first last </proc/sys/net/ipv4/ip_local_port_range
        reserved=""
        [[ -r /proc/sys/net/ipv4/ip_local_reserved_ports ]] && reserved="$(</proc/sys/net/ipv4/ip_local_reserved_ports)"
        printf '%s-%s%s%s\n' "$first" "$last" "${reserved:+,}" "$reserved"
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
  local i port
  for ((i = 0; i < ${#service_order[@]}; i++)); do
    port=$((base + i))
    ((port >= 1024 && port <= 49151)) || return 1
    port_in_csv_ranges "$port" "$port_range_requested" || return 1
    [[ "$excluded" == "probe-unavailable" ]] && return 1
    port_in_csv_ranges "$port" "$excluded" && return 1
  done
  return 0
}

port_lock_busy() {
  local port="$1"
  [[ -n "$docker_endpoint" ]] || return 1
  local endpoint_hash lock
  endpoint_hash="$(printf '%s' "$docker_endpoint" | hash_text)"
  endpoint_hash="${endpoint_hash%% *}"
  lock="$port_lock_root/${endpoint_hash:0:16}-$port.lock.d"
  [[ -d "$lock" ]]
}

auto_block_busy() {
  local base="$1"
  local i port
  for ((i = 0; i < ${#service_order[@]}; i++)); do
    port=$((base + i))
    port_lock_busy "$port" && return 0
    port_busy "$port" && return 0
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
  local i service
  for ((i = 0; i < ${#service_order[@]}; i++)); do
    service="${service_order[$i]}"
    resolved_service_port[$service]=$((base + i))
    resolved_service_port_source[$service]="$source"
  done
}

set_resolved_manifest_ports() {
  local service port
  for service in "${service_order[@]}"; do
    port="$(manifest_port_for_service "$service")" || return 1
    validate_port "manifest port for $service" "$port"
    resolved_service_port[$service]="$port"
    resolved_service_port_source[$service]="current-manifest"
  done
}

set_resolved_individual_ports() {
  local service env_name port
  for service in "${service_order[@]}"; do
    env_name="${service_port_env[$service]}"
    port="${!env_name}"
    validate_port "$env_name" "$port"
    resolved_service_port[$service]="$port"
    resolved_service_port_source[$service]="$env_name"
  done
}

resolve_auto_ports() {
  local busy_aware="$1"
  local excluded hash offset bases=() base range_start range_end spec start end count i service port
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
      die "cannot probe OS ephemeral port range for auto allocation; set explicit fixed ports or RASM_PROVISION_ALLOW_EPHEMERAL_PORTS=1"
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
  for spec in "${__candidate_ranges[@]}"; do
    [[ "$spec" =~ ^([0-9]+)-([0-9]+)$ ]] || die "invalid RASM_PROVISION_PORT_RANGE segment: $spec"
    range_start="${BASH_REMATCH[1]}"
    range_end="${BASH_REMATCH[2]}"
    for ((base = range_start; base <= range_end - 2; base++)); do
      port_allowed_for_auto "$base" "$excluded" && bases+=("$base")
    done
  done
  ((${#bases[@]} > 0)) || die "no usable auto port blocks in RASM_PROVISION_PORT_RANGE after exclusions"
  port_policy_seed="rasm-provision:v2:$(docker_endpoint_hash):$root_fingerprint:$project_name:service-order-1"
  hash="$(hash_prefix_decimal "$port_policy_seed")"
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
    set_resolved_block "$base" "auto"
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
  local explicit_count=0 service env_name base
  for service in "${service_order[@]}"; do
    env_name="${service_port_env[$service]}"
    [[ -n "${!env_name:-}" ]] && ((explicit_count += 1))
  done
  [[ -z "$fixed_port_base" || "$explicit_count" -eq 0 ]] || die_usage "RASM_PROVISION_PORT_BASE conflicts with individual service port env vars"
  if [[ -n "$fixed_port_base" ]]; then
    validate_port "RASM_PROVISION_PORT_BASE" "$fixed_port_base"
    set_resolved_block "$fixed_port_base" "RASM_PROVISION_PORT_BASE"
    port_policy_mode="fixed-block"
    port_policy_source="RASM_PROVISION_PORT_BASE"
  elif ((explicit_count == ${#service_order[@]})); then
    set_resolved_individual_ports
    port_policy_mode="fixed-individual"
    port_policy_source="service-env"
  elif ((explicit_count > 0)); then
    die_usage "partial service port overrides are not supported; set all three service ports or RASM_PROVISION_PORT_BASE"
  elif [[ "$port_policy_requested" == "auto" ]]; then
    resolve_auto_ports "$busy_aware"
  elif [[ "$port_policy_requested" == "fixed" ]]; then
    base="${service_port_default[timescale]}"
    set_resolved_block "$base" "RASM_PROVISION_PORT_POLICY=fixed"
    port_policy_mode="fixed-block"
    port_policy_source="policy-default"
  else
    die_usage "RASM_PROVISION_PORT_POLICY must be auto or fixed: $port_policy_requested"
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

current_auto_base() {
  local first_service="${service_order[0]}"
  printf '%s\n' "${resolved_service_port[$first_service]}"
}

compose_bind_failed() {
  local log="$1"
  [[ -f "$log" ]] || return 1
  local line lower
  while IFS= read -r line; do
    lower="${line,,}"
    [[ "$lower" =~ port[[:space:]]is[[:space:]]already[[:space:]]allocated ]] && return 0
    [[ "$lower" =~ ports[[:space:]]are[[:space:]]not[[:space:]]available ]] && return 0
    [[ "$lower" =~ bind:[[:space:]]address[[:space:]]already[[:space:]]in[[:space:]]use ]] && return 0
    [[ "$lower" =~ bind[[:space:]]for[[:space:]].*failed ]] && return 0
    [[ "$lower" =~ listen[[:space:]]tcp.*:[[:space:]]bind ]] && return 0
  done <"$log"
  return 1
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

sql_quote() {
  local value="${1//\'/\'\'}"
  printf "'%s'" "$value"
}

extension_catalog_rows() {
  local service="$1"
  known_service "$service" || die "unknown service: $service"
  local catalog="${service_extension_catalog[$service]}"
  [[ -z "$catalog" ]] || emit_extension_catalog_block "$catalog"
  emit_extension_catalog_block "$extension_catalog_common_rows"
}

pg_cron_catalog_flag() {
  [[ "$pg_cron_requested" != "0" ]] && printf '1' || printf '0'
}

emit_extension_catalog_block() {
  local block="$1"
  local ext category required create_on_verify extra
  while IFS=$'\t' read -r ext category required create_on_verify extra; do
    [[ -n "$ext" ]] || continue
    if [[ "$ext" == "pg_cron" ]]; then
      required="$(pg_cron_catalog_flag)"
      create_on_verify="$required"
    fi
    printf '%s\t%s\t%s\t%s%s\n' "$ext" "$category" "$required" "$create_on_verify" "${extra:+	$extra}"
  done <<<"$block"
}

extension_sql_values() {
  local service="$1"
  local ext category required create_on_verify first=true ordinal=0
  while IFS=$'\t' read -r ext category required create_on_verify; do
    [[ -n "$ext" ]] || continue
    ((++ordinal))
    if [[ "$first" == true ]]; then
      first=false
    else
      printf ',\n'
    fi
    printf '(%s,%s,%s,%s,%s)' "$ordinal" "$(sql_quote "$ext")" "$(sql_quote "$category")" "$([[ "$required" == 1 ]] && printf true || printf false)" "$([[ "$create_on_verify" == 1 ]] && printf true || printf false)"
  done < <(extension_catalog_rows "$service")
  return 0
}

extension_catalog_tsv() {
  local service ext category required create_on_verify
  for service in "${service_order[@]}"; do
    while IFS=$'\t' read -r ext category required create_on_verify; do
      [[ -n "$ext" ]] || continue
      printf '%s\t%s\t%s\t%s\t%s\n' "$service" "$ext" "$category" "$required" "$create_on_verify"
    done < <(extension_catalog_rows "$service")
  done
  return 0
}

assoc_value() {
  local table_name="$1"
  local key="$2"
  local default="$3"
  local -n table="$table_name"
  printf '%s' "${table[$key]:-$default}"
}

set_contains_word() {
  local word="$1"
  local set="$2"
  case " $set " in
    *" $word "*) printf '1' ;;
    *) printf '0' ;;
  esac
}

extension_catalog_enriched_tsv() {
  local service ext category required create_on_verify source risk preload superuser shared_preload file_access network_access background_worker create_policy
  while IFS=$'\t' read -r service ext category required create_on_verify; do
    [[ -n "$ext" ]] || continue
    source="$(assoc_value extension_source_package_map "$ext" "postgresql-contrib-or-image-probed")"
    risk="$(assoc_value extension_risk_class_map "$ext" "local-extension")"
    preload="$(set_contains_word "$ext" "$extension_preload_required_set")"
    superuser="$(set_contains_word "$ext" "$extension_requires_superuser_set")"
    shared_preload="$preload"
    file_access="$(set_contains_word "$ext" "$extension_file_access_set")"
    network_access="$(set_contains_word "$ext" "$extension_network_access_set")"
    background_worker="$(set_contains_word "$ext" "$extension_background_worker_set")"
    [[ "$create_on_verify" == 1 ]] && create_policy="verify-create" || create_policy="probe-only"
    printf '%s\t%s\t%s\t%s\t%s\textension\t%s\t%s\t1\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$service" \
      "$ext" \
      "$category" \
      "$required" \
      "$create_on_verify" \
      "$source" \
      "$preload" \
      "$([[ "$service" == "pgduckdb" ]] && printf '1' || printf '0')" \
      "$service" \
      "$risk" \
      "$superuser" \
      "$shared_preload" \
      "$file_access" \
      "$network_access" \
      "$background_worker" \
      "$create_policy"
  done < <(extension_catalog_tsv)
  return 0
}

extension_catalog_json() {
  extension_catalog_enriched_tsv | jq -Rsc '
    split("\n")
    | map(select(length > 0) | split("\t"))
    | map({
        service: .[0],
        extension: .[1],
        category: .[2],
        required: (.[3] == "1"),
        createOnVerify: (.[4] == "1"),
        kind: .[5],
        sourcePackage: .[6],
        preloadRequired: (.[7] == "1"),
        selfProvisioned: (.[8] == "1"),
        devGated: (.[9] == "1"),
        expectedService: .[10],
        riskClass: .[11],
        requiresSuperuser: (.[12] == "1"),
        requiresSharedPreload: (.[13] == "1"),
        fileAccess: (.[14] == "1"),
        networkAccess: (.[15] == "1"),
        backgroundWorker: (.[16] == "1"),
        createPolicy: .[17]
      })
    | sort_by(.service, .category, .extension)
  '
}

enabled_services() {
  local service
  for service in "${service_order[@]}"; do
    service_enabled "$service" && printf '%s\n' "$service"
  done
  return 0
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
  [[ "$lock_wait_seconds" =~ ^[0-9]+$ ]] || die "RASM_PROVISION_LOCK_WAIT_SECONDS must be a non-negative integer: $lock_wait_seconds"
  ((lock_wait_seconds <= 3600)) || die "RASM_PROVISION_LOCK_WAIT_SECONDS must be <= 3600: $lock_wait_seconds"
  [[ "$lock_ttl_seconds" =~ ^[0-9]+$ ]] || die "RASM_PROVISION_LOCK_TTL_SECONDS must be a non-negative integer: $lock_ttl_seconds"
  ((lock_ttl_seconds >= 60 && lock_ttl_seconds <= 86400)) || die "RASM_PROVISION_LOCK_TTL_SECONDS must be between 60 and 86400: $lock_ttl_seconds"
  [[ "$compose_parallel_limit" =~ ^[0-9]+$ ]] || die "RASM_PROVISION_COMPOSE_PARALLEL_LIMIT must be a non-negative integer: $compose_parallel_limit"
  ((compose_parallel_limit <= 32)) || die "RASM_PROVISION_COMPOSE_PARALLEL_LIMIT must be <= 32: $compose_parallel_limit"
  [[ "$max_active_projects" =~ ^[0-9]+$ ]] || die "RASM_PROVISION_MAX_ACTIVE_PROJECTS must be a non-negative integer: $max_active_projects"
  ((max_active_projects <= 64)) || die "RASM_PROVISION_MAX_ACTIVE_PROJECTS must be <= 64: $max_active_projects"
}

validate_project_slug() {
  local value="$1"
  [[ "$value" =~ ^[a-z0-9][a-z0-9_-]*$ ]] || die "RASM_PROVISION_PROJECT must match ^[a-z0-9][a-z0-9_-]*$: $value"
}

validate_static_env() {
  validate_lock_wait_seconds
  validate_project_slug "$project_name"
  [[ "$pg_cron_requested" == "auto" || "$pg_cron_requested" == "0" || "$pg_cron_requested" == "1" ]] ||
    die "RASM_PROVISION_PG_CRON must be auto, 0, or 1: $pg_cron_requested"
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

find_rasm_root() {
  local candidate
  if [[ -n "${RASM_ROOT:-}" ]]; then
    candidate="$RASM_ROOT"
    [[ -d "$candidate" ]] || die "RASM_ROOT is not a directory: $candidate"
    candidate="$(cd "$candidate" && pwd -P)" || die "cannot resolve RASM_ROOT: $candidate"
    printf '%s\n' "$candidate"
    return
  fi

  candidate="$PWD"
  while [[ "$candidate" != "/" ]]; do
    if [[ -f "$candidate/pyproject.toml" && -f "$candidate/Directory.Packages.props" && -d "$candidate/libs/csharp" ]]; then
      candidate="$(cd "$candidate" && pwd -P)" || die "cannot resolve discovered Rasm root: $candidate"
      printf '%s\n' "$candidate"
      return
    fi
    candidate="${candidate%/*}"
    [[ -n "$candidate" ]] || candidate="/"
  done
  die "cannot find Rasm root from PWD; run inside Rasm or set RASM_ROOT"
}

validate_rasm_root() {
  local root="$1"
  [[ -f "$root/pyproject.toml" ]] || die "Rasm root missing pyproject.toml: $root"
  [[ -f "$root/Directory.Packages.props" ]] || die "Rasm root missing Directory.Packages.props: $root"
  [[ -d "$root/libs/csharp" ]] || die "Rasm root missing libs/csharp: $root"
}

init_root() {
  local fingerprint
  [[ -n "$rasm_root" ]] && return 0
  validate_lock_wait_seconds
  rasm_root="$(find_rasm_root)"
  validate_rasm_root "$rasm_root"
  fingerprint="$(printf '%s' "$rasm_root" | hash_text)"
  root_fingerprint="${fingerprint%% *}"
  if [[ -n "$project_override" ]]; then
    validate_project_slug "$project_override"
    project_name="rasm-provision-${root_fingerprint:0:12}-$project_override"
  else
    project_name="rasm-provision-${root_fingerprint:0:12}"
  fi
  validate_project_slug "$project_name"
  provisioning_root_dir="$rasm_root/.artifacts/provisioning/rasm"
  provisioning_dir="$provisioning_root_dir/$project_name"
  current_link="$provisioning_dir/current"
  compose_file="$current_link/compose.yaml"
  env_file="$current_link/.env"
  volume_ledger_file="$provisioning_dir/volume-ledger.json"
  docker_config_dir="$provisioning_dir/docker-config"
  lock_dir="$provisioning_root_dir/.locks/$project_name.lock.d"
  readonly rasm_root root_fingerprint project_name provisioning_root_dir provisioning_dir current_link compose_file env_file volume_ledger_file docker_config_dir lock_dir
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

ensure_provisioning_root() {
  require_root
  ensure_dir_component "$rasm_root/.artifacts"
  ensure_dir_component "$rasm_root/.artifacts/provisioning"
  ensure_dir_component "$provisioning_root_dir"
  ensure_dir_component "$provisioning_root_dir/.locks"
}

ensure_project_dir() {
  ensure_provisioning_root
  ensure_dir_component "$provisioning_dir"
}

assert_safe_project_dir_for_cleanup() {
  require_root
  [[ "$provisioning_dir" == "$provisioning_root_dir/$project_name" ]] || die "unexpected project provisioning dir: $provisioning_dir"
  [[ ! -L "$provisioning_dir" ]] || die "refusing symlinked project provisioning dir: $provisioning_dir"
  if [[ -d "$provisioning_dir" ]]; then
    local real
    real="$(cd "$provisioning_dir" && pwd -P)" || die "cannot resolve project provisioning dir: $provisioning_dir"
    [[ "$real" == "$provisioning_root_dir/$project_name" ]] || die "project provisioning dir escapes canonical root: $real"
  fi
}

lock_owner_field() {
  local key="$1"
  local line
  [[ -f "$lock_dir/owner" ]] || return 0
  while IFS= read -r line; do
    [[ "${line%%=*}" == "$key" ]] || continue
    printf '%s\n' "${line#*=}"
    return 0
  done <"$lock_dir/owner"
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

write_lock_metadata() {
  local tmp started_at host
  host="$(current_host)"
  started_at="$(lock_owner_field started_at)"
  [[ -n "$started_at" ]] || TZ=UTC printf -v started_at '%(%Y-%m-%dT%H:%M:%SZ)T' -1
  tmp="$(mktemp "$lock_dir/owner.XXXXXX")" || return
  {
    printf 'pid=%s\n' "$$"
    printf 'host=%s\n' "$host"
    printf 'started_at=%s\n' "$started_at"
    printf 'last_heartbeat_epoch=%s\n' "$EPOCHSECONDS"
    printf 'token=%s\n' "$lock_token"
    printf 'root_fingerprint=%s\n' "$root_fingerprint"
    printf 'project=%s\n' "$project_name"
    printf 'command=%s\n' "$current_command"
    printf 'docker_endpoint_hash=%s\n' "$(docker_endpoint_hash)"
  } >"$tmp" || {
    rm -f "$tmp"
    return 1
  }
  chmod 600 "$tmp" || return 1
  mv -f "$tmp" "$lock_dir/owner"
}

lock_active_message() {
  local pid host started_at command
  pid="$(lock_owner_field pid)"
  host="$(lock_owner_field host)"
  started_at="$(lock_owner_field started_at)"
  command="$(lock_owner_field command)"
  printf 'another rasm-provision mutating command is active: lock=%s pid=%s host=%s command=%s started_at=%s' \
    "$lock_dir" "${pid:-unknown}" "${host:-unknown}" "${command:-unknown}" "${started_at:-unknown}"
}

path_mtime_epoch() {
  local path="$1"
  stat -c %Y "$path" 2>/dev/null || stat -f %m "$path" 2>/dev/null
}

pid_looks_like_rasm_provision() {
  local pid="$1"
  [[ "$pid" =~ ^[0-9]+$ ]] || return 1
  kill -0 "$pid" 2>/dev/null || return 1
  command -v ps >/dev/null 2>&1 || return 0
  local command_line
  command_line="$(ps -p "$pid" -o command= 2>/dev/null || printf rasm-provision)"
  [[ "$command_line" == *rasm-provision* ]]
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
  pid_looks_like_rasm_provision "$pid" && return 1
  host="$(lock_owner_field host)"
  [[ "$host" == "$(current_host)" ]] || return 1
  token_file_matches_owner "$lock_dir" || return 1
  rm -f "$lock_dir/token" "$lock_dir/owner" "$lock_dir"/owner.* 2>/dev/null || return 1
  rmdir "$lock_dir" 2>/dev/null || return 1
}

acquire_mutation_lock() {
  require_root
  ensure_provisioning_root
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
  local lock="$1"
  local key="$2"
  local line
  [[ -f "$lock/owner" ]] || return 0
  while IFS= read -r line; do
    [[ "${line%%=*}" == "$key" ]] || continue
    printf '%s\n' "${line#*=}"
    return 0
  done <"$lock/owner"
}

write_psql_session_metadata() {
  local lock="$1"
  local service="$2"
  local tmp started_at host
  host="$(current_host)"
  TZ=UTC printf -v started_at '%(%Y-%m-%dT%H:%M:%SZ)T' -1
  tmp="$(mktemp "$lock/owner.XXXXXX")" || return
  {
    printf 'pid=%s\n' "$$"
    printf 'host=%s\n' "$host"
    printf 'started_at=%s\n' "$started_at"
    printf 'token=%s\n' "$lock_token"
    printf 'root_fingerprint=%s\n' "$root_fingerprint"
    printf 'project=%s\n' "$project_name"
    printf 'command=psql\n'
    printf 'service=%s\n' "$service"
  } >"$tmp" || {
    rm -f "$tmp"
    return 1
  }
  chmod 600 "$tmp" || return 1
  mv -f "$tmp" "$lock/owner"
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
  local lock
  [[ -d "$session_lock_root" ]] || return 0
  for lock in "$session_lock_root"/*.lock; do
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
  local lock
  cleanup_stale_psql_session_locks
  [[ -d "$session_lock_root" ]] || return 0
  for lock in "$session_lock_root"/"$root_fingerprint"-"$project_name"-*.lock; do
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
  local lock
  assert_no_active_mutation_for_psql
  mkdir -p "$session_lock_root"
  chmod 700 "$session_lock_root"
  lock_token="$$-${EPOCHREALTIME//[^0-9]/}-$SRANDOM"
  lock="$session_lock_root/$root_fingerprint-$project_name-$service-$lock_token.lock"
  mkdir -m 700 "$lock" || die "cannot create psql session lock: service=$service"
  if ! printf '%s\n' "$lock_token" >"$lock/token" || ! write_psql_session_metadata "$lock" "$service"; then
    rm -f "$lock/token" "$lock/owner" "$lock"/owner.* 2>/dev/null || true
    rmdir "$lock" 2>/dev/null || true
    die "cannot write psql session lock metadata: service=$service"
  fi
  chmod 600 "$lock/token"
  psql_session_locks+=("$lock")
  if mutation_lock_blocks_psql; then
    local message
    message="$(lock_active_message)"
    release_psql_session_locks || true
    die "$message"
  fi
}

release_psql_session_locks() {
  local lock current_token rc=0 state_root
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
  state_root="${XDG_STATE_HOME:-$HOME/.local/state}"
  rmdir "$session_lock_root" "$state_root/rasm-provision" 2>/dev/null || true
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
  lock_releasing=false
  return "$rc"
}

with_mutation_lock() {
  current_command="$1"
  shift
  local cleanup_rc=0
  trap 'rc=$?; release_mutation_lock || true; exit "$rc"' EXIT
  trap 'trap - INT; forward_foreground_child INT; release_mutation_lock || true; kill -INT "$$"' INT
  trap 'trap - TERM; forward_foreground_child TERM; release_mutation_lock || true; kill -TERM "$$"' TERM
  trap 'trap - HUP; forward_foreground_child HUP; release_mutation_lock || true; kill -HUP "$$"' HUP
  trap 'trap - QUIT; forward_foreground_child QUIT; release_mutation_lock || true; kill -QUIT "$$"' QUIT
  trap 'trap - PIPE; release_mutation_lock || true; exit 141' PIPE
  acquire_mutation_lock
  assert_no_active_psql_sessions
  "$@"
  release_mutation_lock || cleanup_rc=$?
  trap - EXIT INT TERM HUP QUIT PIPE
  ((cleanup_rc == 0)) || exit "$cleanup_rc"
  return 0
}

port_lock_owner_field() {
  local lock="$1"
  local key="$2"
  local line
  [[ -f "$lock/owner" ]] || return 0
  while IFS= read -r line; do
    [[ "${line%%=*}" == "$key" ]] || continue
    printf '%s\n' "${line#*=}"
    return 0
  done <"$lock/owner"
}

write_port_lock_metadata() {
  local lock="$1"
  local service="$2"
  local port="$3"
  local tmp started_at host
  host="$(current_host)"
  started_at="$(port_lock_owner_field "$lock" started_at)"
  [[ -n "$started_at" ]] || TZ=UTC printf -v started_at '%(%Y-%m-%dT%H:%M:%SZ)T' -1
  tmp="$(mktemp "$lock/owner.XXXXXX")" || return
  {
    printf 'pid=%s\n' "$$"
    printf 'host=%s\n' "$host"
    printf 'started_at=%s\n' "$started_at"
    printf 'last_heartbeat_epoch=%s\n' "$EPOCHSECONDS"
    printf 'token=%s\n' "$lock_token"
    printf 'docker_endpoint_hash=%s\n' "$(docker_endpoint_hash)"
    printf 'root_fingerprint=%s\n' "$root_fingerprint"
    printf 'project=%s\n' "$project_name"
    printf 'service=%s\n' "$service"
    printf 'port=%s\n' "$port"
  } >"$tmp" || {
    rm -f "$tmp"
    return 1
  }
  chmod 600 "$tmp" || return 1
  mv -f "$tmp" "$lock/owner"
}

recover_dead_port_lock() {
  local lock="$1"
  local pid host
  pid="$(port_lock_owner_field "$lock" pid)"
  if [[ -n "$pid" ]]; then
    pid_looks_like_rasm_provision "$pid" && return 1
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
  mkdir -p "$port_lock_root"
  chmod 700 "$port_lock_root" 2>/dev/null || true
  [[ -d "$port_lock_root" && ! -L "$port_lock_root" ]] || die "cannot create safe port lock root: $port_lock_root"
  local endpoint_hash service port lock deadline pid host started_at lock_service
  endpoint_hash="$(printf '%s' "$docker_endpoint" | hash_text)"
  endpoint_hash="${endpoint_hash%% *}"
  while IFS= read -r service; do
    port="$(service_port "$service")"
    lock="$port_lock_root/${endpoint_hash:0:16}-$port.lock.d"
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
  local lock current_token rc=0 state_root
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
  state_root="${XDG_STATE_HOME:-$HOME/.local/state}"
  rmdir "$port_lock_root" "$state_root/rasm-provision" 2>/dev/null || true
  return "$rc"
}

write_endpoint_lock_metadata() {
  local tmp started_at host
  host="$(current_host)"
  started_at="$(port_lock_owner_field "$endpoint_lock_dir" started_at)"
  [[ -n "$started_at" ]] || TZ=UTC printf -v started_at '%(%Y-%m-%dT%H:%M:%SZ)T' -1
  tmp="$(mktemp "$endpoint_lock_dir/owner.XXXXXX")" || return
  {
    printf 'pid=%s\n' "$$"
    printf 'host=%s\n' "$host"
    printf 'started_at=%s\n' "$started_at"
    printf 'last_heartbeat_epoch=%s\n' "$EPOCHSECONDS"
    printf 'token=%s\n' "$lock_token"
    printf 'docker_endpoint_hash=%s\n' "$(docker_endpoint_hash)"
    printf 'root_fingerprint=%s\n' "$root_fingerprint"
    printf 'project=%s\n' "$project_name"
    printf 'command=%s\n' "$current_command"
    printf 'service=%s\n' "endpoint"
  } >"$tmp" || {
    rm -f "$tmp"
    return 1
  }
  chmod 600 "$tmp" || return 1
  mv -f "$tmp" "$endpoint_lock_dir/owner"
}

recover_dead_endpoint_lock() {
  local pid host
  pid="$(port_lock_owner_field "$endpoint_lock_dir" pid)"
  if [[ -n "$pid" ]]; then
    pid_looks_like_rasm_provision "$pid" && return 1
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
  local endpoint_hash deadline pid host started_at owner_project
  endpoint_hash="$(docker_endpoint_hash)"
  endpoint_lock_dir="$provisioning_root_dir/.locks/endpoint-${endpoint_hash:0:16}.lock.d"
  ensure_provisioning_root
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
  return "$rc"
}

resolve_docker_endpoint() {
  local endpoint=""
  [[ -n "$docker_endpoint" ]] && return 0
  if [[ -n "${DOCKER_HOST:-}" ]]; then
    endpoint="$DOCKER_HOST"
  elif [[ -n "${DOCKER_CONTEXT:-}" ]]; then
    endpoint="$(env -u DOCKER_HOST docker context inspect "$DOCKER_CONTEXT" --format '{{ .Endpoints.docker.Host }}' 2>/dev/null)" ||
      die "cannot inspect explicit DOCKER_CONTEXT=$DOCKER_CONTEXT"
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
  if [[ "$docker_endpoint" == tcp://* || "$docker_endpoint" == ssh://* ]]; then
    printf 'remote Docker endpoint rejected for local provisioning'
    return 1
  fi
  [[ "$docker_endpoint" == unix://* ]] || {
    printf 'non-local Docker endpoint rejected'
    return 1
  }
  if [[ "$host_os" == "Darwin" && "${RASM_PROVISION_ALLOW_NON_COLIMA_DOCKER:-0}" != "1" && "$docker_endpoint" != "unix://$default_colima_socket" ]]; then
    printf 'non-Colima Docker endpoint rejected; set RASM_PROVISION_ALLOW_NON_COLIMA_DOCKER=1 to override'
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

render_empty_json() {
  printf '{}\n'
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

ensure_docker_config() {
  ensure_project_dir
  atomic_render "$docker_config_dir/config.json" render_empty_json
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
  local enable_cron=false
  [[ "$service" == "timescale" && "$pg_cron_requested" != "0" ]] && enable_cron=true
  [[ "$service" == "pgduckdb" || "$enable_cron" == true ]] || return 0
  if [[ "$enable_cron" == true && "$preload" != *pg_cron* ]]; then
    preload="${preload}${preload:+,}pg_cron"
  fi
  if [[ "$enable_cron" == true ]]; then
    printf '["postgres","-c","shared_preload_libraries=%s","-c","cron.database_name=rasm","-c","cron.use_background_workers=on","-c","max_worker_processes=20"]\n' "$preload"
  else
    printf '["postgres","-c","shared_preload_libraries=%s"]\n' "$preload"
  fi
}

render_common_labels() {
  local resource="$1"
  local service="$2"
  printf '      %s: "1"\n' "$owner_label"
  printf '      %s: %s\n' "$service_label" "$service"
  printf '      %s: "%s"\n' "$root_label" "$root_fingerprint"
  printf '      %s: "%s"\n' "$project_label" "$project_name"
  printf '      %s: %s\n' "$resource_label" "$resource"
  [[ -z "${unpublished_generation##*/}" ]] || printf '      %s: "%s"\n' "$generation_label" "${unpublished_generation##*/}"
}

render_auth_environment() {
  local service="$1"
  resolve_auth
  printf '      POSTGRES_DB: rasm\n'
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
  printf '      test: ["CMD-SHELL", "pg_isready -U postgres -d rasm"]\n'
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
  [[ -f "$source" ]] || source=/dev/null
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
  printf 'RASM_ROOT=%s\n' "$rasm_root"
  printf 'RASM_PROVISION_PROJECT=%s\n' "$project_name"
  printf 'RASM_PROVISION_DIR=%s\n' "$provisioning_dir"
  printf 'RASM_PROVISION_COMPOSE=%s\n' "$compose_file"
  printf 'RASM_PROVISION_ENV=%s\n' "$env_file"
  printf 'RASM_PROVISION_AUTH=%s\n' "$auth_mode"
  printf 'RASM_PROVISION_PORT_POLICY=%s\n' "$port_policy_mode"
  for service in "${service_order[@]}"; do
    printf '%s=%s\n' "${service_image_env[$service]}" "$(service_image "$service")"
    printf '%s=%s\n' "${service_port_env[$service]}" "$(service_port "$service")"
    if service_enabled "$service"; then
      printf '%s=%s\n' "${service_dsn_env[$service]}" "$(service_dsn "$service")"
    fi
  done
  printf 'RASM_PROVISION_PGDUCKDB=%s\n' "$(service_enabled_value pgduckdb)"
}

render_generation_manifest() {
  local generation_id="$1"
  local created_at services_json
  TZ=UTC printf -v created_at '%(%Y-%m-%dT%H:%M:%SZ)T' -1
  services_json="$(service_records_json)"
  jq -n \
    --argjson schemaVersion "$schema_version" \
    --arg generation "$generation_id" \
    --arg root "$rasm_root" \
    --arg project "$project_name" \
    --arg rootFingerprint "$root_fingerprint" \
    --arg createdAt "$created_at" \
    --argjson auth "$(auth_json)" \
    --argjson portPolicy "$(port_policy_json)" \
    --argjson services "$services_json" \
    --arg dockerEndpointHash "$(docker_endpoint_hash)" \
    --arg hostOs "$host_os" \
    '{schemaVersion: $schemaVersion, generation: $generation, root: $root, project: $project, rootFingerprint: $rootFingerprint, createdAt: $createdAt, dockerEndpointHash: $dockerEndpointHash, hostOs: $hostOs, auth: $auth, portPolicy: $portPolicy, services: $services}'
}

render_volume_ledger() {
  local generation_id="$1"
  local created_at
  TZ=UTC printf -v created_at '%(%Y-%m-%dT%H:%M:%SZ)T' -1
  jq -n \
    --argjson schemaVersion "$schema_version" \
    --arg generation "$generation_id" \
    --arg project "$project_name" \
    --arg rootFingerprint "$root_fingerprint" \
    --arg createdAt "$created_at" \
    --arg authMode "$auth_mode" \
    --arg authRisk "$auth_risk" \
    --argjson services "$(service_records_json)" \
    --arg volumePrefix "$(volume_prefix)" \
    '{
      schemaVersion: $schemaVersion,
      project: $project,
      rootFingerprint: $rootFingerprint,
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
  rmdir "$provisioning_root_dir/.locks" "$provisioning_root_dir" "$rasm_root/.artifacts/provisioning" "$rasm_root/.artifacts" 2>/dev/null || true
}

inspect_label() {
  local id="$1"
  local label="$2"
  docker inspect --format "{{ index .Config.Labels \"$label\" }}" "$id" 2>/dev/null || true
}

inspect_name() {
  local id="$1"
  local name
  name="$(docker inspect --format '{{ .Name }}' "$id")" || return
  printf '%s\n' "${name#/}"
}

validate_owned_container_identity() {
  local id="$1"
  local service="$2"
  local mode="${3:-strict}"
  local owned root project compose_project compose_service image expected_image net volume mount
  known_service "$service" || die "refusing unknown provision container service=$service id=$id"
  owned="$(inspect_label "$id" "$owner_label")"
  root="$(inspect_label "$id" "$root_label")"
  project="$(inspect_label "$id" "$project_label")"
  compose_project="$(inspect_label "$id" "com.docker.compose.project")"
  compose_service="$(inspect_label "$id" "com.docker.compose.service")"
  [[ "$owned" == "1" ]] || die "refusing unowned container id=$id"
  [[ "$root" == "$root_fingerprint" ]] || die "refusing container from another Rasm root id=$id root=$root"
  [[ "$project" == "$project_name" ]] || die "refusing container from another provision project id=$id provision_project=$project"
  [[ "$compose_project" == "$project_name" ]] || die "refusing container from another Compose project id=$id compose_project=$compose_project"
  [[ "$compose_service" == "$service" ]] || die "refusing container with wrong Compose service id=$id service=$compose_service expected=$service"
  [[ "$mode" == "cleanup" ]] && return 0
  image="$(docker inspect --format '{{ .Config.Image }}' "$id")" || die "cannot inspect container image id=$id"
  expected_image="$(service_image "$service")"
  [[ "$image" == "$expected_image" ]] || die "refusing container with wrong image id=$id image=$image expected=$expected_image"
  net="$(network_name)"
  volume="$(service_volume_name "$service")"
  mount="${service_volume_mount[$service]}"
  docker inspect "$id" | jq -e --arg net "$net" --arg volume "$volume" --arg mount "$mount" '
    .[0] as $container
    | ($container.NetworkSettings.Networks[$net] != null)
    and any($container.Mounts[]?; .Name == $volume and .Destination == $mount)
  ' >/dev/null || die "refusing container with wrong network or volume mount id=$id service=$service"
}

collect_owned_container_ids() {
  # shellcheck disable=SC2178
  local -n _out="$1"
  local raw
  _out=()
  raw="$(docker ps -aq \
    --filter "label=com.docker.compose.project=$project_name" \
    --filter "label=$owner_label=1" \
    --filter "label=$root_label=$root_fingerprint" \
    --filter "label=$project_label=$project_name")" || return
  [[ -z "$raw" ]] || mapfile -t _out <<<"$raw"
}

collect_owned_volume_names() {
  # shellcheck disable=SC2178
  local -n _out="$1"
  local raw
  _out=()
  raw="$(docker volume ls -q \
    --filter "label=$owner_label=1" \
    --filter "label=$root_label=$root_fingerprint" \
    --filter "label=$project_label=$project_name")" || return
  [[ -z "$raw" ]] || mapfile -t _out <<<"$raw"
}

collect_owned_network_names() {
  # shellcheck disable=SC2178
  local -n _out="$1"
  local raw
  _out=()
  raw="$(docker network ls -q \
    --filter "label=$owner_label=1" \
    --filter "label=$root_label=$root_fingerprint" \
    --filter "label=$project_label=$project_name")" || return
  [[ -z "$raw" ]] || mapfile -t _out <<<"$raw"
}

active_other_project_count() {
  local raw
  local ids=()
  raw="$(docker ps -q \
    --filter "label=$owner_label=1" \
    --filter "label=$root_label=$root_fingerprint")" || return
  [[ -z "$raw" ]] || mapfile -t ids <<<"$raw"
  ((${#ids[@]} > 0)) || {
    printf '0\n'
    return 0
  }
  docker inspect "${ids[@]}" | jq -r --arg project_label "$project_label" --arg current "$project_name" '
    [.[] | .Config.Labels[$project_label] // empty | select(. != $current)]
    | unique
    | length
  '
}

enforce_max_active_projects() {
  ((max_active_projects == 0)) && return 0
  local count
  count="$(active_other_project_count)" || die "cannot inspect active provisioning projects"
  ((count < max_active_projects)) || die "active provisioning project cap reached: active_other_projects=$count max=$max_active_projects"
}

service_identity_json() {
  local service
  for service in "${service_order[@]}"; do
    jq -nc \
      --arg service "$service" \
      --arg image "$(service_image "$service")" \
      --arg volume "$(service_volume_name "$service")" \
      --arg mount "${service_volume_mount[$service]}" \
      '{key: $service, image: $image, volume: $volume, mount: $mount}'
  done | jq -s 'map({(.key): {image, volume, mount}}) | add'
}

container_id_for_service() {
  local service="$1"
  local raw
  raw="$(docker ps -aq \
    --filter "label=com.docker.compose.project=$project_name" \
    --filter "label=$owner_label=1" \
    --filter "label=$service_label=$service" \
    --filter "label=$root_label=$root_fingerprint" \
    --filter "label=$project_label=$project_name")" || return
  printf '%s\n' "${raw%%$'\n'*}"
}

container_running_for_service() {
  local service="$1"
  [[ -n "$(docker ps -q \
    --filter "label=com.docker.compose.project=$project_name" \
    --filter "label=$owner_label=1" \
    --filter "label=$service_label=$service" \
    --filter "label=$root_label=$root_fingerprint" \
    --filter "label=$project_label=$project_name")" ]]
}

container_publishes_loopback_host_port() {
  local id="$1"
  local port="$2"
  docker inspect "$id" | jq -e --arg port "$port" '
    .[0].NetworkSettings.Ports[]?[]?
    | select(.HostPort == $port and (.HostIp == "127.0.0.1" or .HostIp == "::1"))
  ' >/dev/null
}

containers_publishing_host_port() {
  local port="$1"
  local raw
  local ids=()
  raw="$(docker ps -q)" || return
  [[ -z "$raw" ]] || mapfile -t ids <<<"$raw"
  ((${#ids[@]} > 0)) || return 0
  docker inspect "${ids[@]}" | jq -r --arg port "$port" '
    .[]
    | select([
        .NetworkSettings.Ports[]?[]?
        | select(.HostPort == $port and (.HostIp == "127.0.0.1" or .HostIp == "::1" or .HostIp == "0.0.0.0" or .HostIp == "::" or .HostIp == ""))
      ] | length > 0)
    | .Id
  '
}

collect_published_container_ids() {
  # shellcheck disable=SC2178
  local -n _out="$1"
  local port="$2"
  local raw
  _out=()
  raw="$(containers_publishing_host_port "$port")" || return
  [[ -z "$raw" ]] || mapfile -t _out <<<"$raw"
}

port_owned_by_service() {
  local service="$1"
  local port="$2"
  local ids=()
  local id owned root project compose_project service_value
  collect_published_container_ids ids "$port"
  ((${#ids[@]} > 0)) || return 1
  for id in "${ids[@]}"; do
    owned="$(inspect_label "$id" "$owner_label")"
    root="$(inspect_label "$id" "$root_label")"
    project="$(inspect_label "$id" "$project_label")"
    service_value="$(inspect_label "$id" "$service_label")"
    compose_project="$(inspect_label "$id" "com.docker.compose.project")"
    [[ "$owned" == "1" && "$root" == "$root_fingerprint" && "$project" == "$project_name" && "$service_value" == "$service" && "$compose_project" == "$project_name" ]] || continue
    validate_owned_container_identity "$id" "$service"
    container_publishes_loopback_host_port "$id" "$port" && return 0
  done
  return 1
}

host_listener_pair() {
  local port="$1"
  local -n __pid="$2"
  local -n __command="$3"
  local line
  __pid=""
  __command=""
  if command -v lsof >/dev/null 2>&1; then
    while IFS= read -r line; do
      case "$line" in
        p*) [[ -z "$__pid" ]] && __pid="${line#p}" ;;
        c*) [[ -z "$__command" ]] && __command="${line#c}" ;;
      esac
    done < <(lsof -nP -iTCP:"$port" -sTCP:LISTEN -Fpc 2>/dev/null || true)
    return 0
  fi
  if command -v ss >/dev/null 2>&1; then
    line="$(ss -H -ltnp 2>/dev/null | awk -v suffix=":$port" '$4 == suffix || $4 ~ suffix "$" {print; exit}')"
    if [[ "$line" =~ pid=([0-9]+) ]]; then
      __pid="${BASH_REMATCH[1]}"
    fi
    if [[ "$line" =~ users:\(\(\"([^\"]+)\" ]]; then
      __command="${BASH_REMATCH[1]}"
    fi
    return 0
  fi
  if proc_net_port_busy "$port"; then
    __pid="-"
    __command="/proc/net/tcp"
  fi
}

port_busy() {
  local port="$1"
  local ids=()
  collect_published_container_ids ids "$port" || die "docker port inspection failed for port=$port"
  ((${#ids[@]} > 0)) && return 0
  host_port_busy "$port"
}

classify_owner() {
  local id="$1"
  local compose_project="$2"
  local provision_owner="$3"
  local provision_root="$4"
  local provision_project="$5"
  if [[ "$provision_owner" == "1" && "$provision_root" == "$root_fingerprint" && "$provision_project" == "$project_name" ]]; then
    printf 'provision:this-project'
  elif [[ "$provision_owner" == "1" && "$provision_root" == "$root_fingerprint" ]]; then
    printf 'provision:this-root-other-project'
  elif [[ "$provision_owner" == "1" && -n "$provision_root" ]]; then
    printf 'provision:other-root'
  elif [[ "$compose_project" == "$project_name" ]]; then
    printf 'project:unowned'
  elif [[ -n "$id" && "$id" != "-" ]]; then
    printf 'external:docker'
  else
    printf 'external:host-listener'
  fi
}

published_ports() {
  local id="$1"
  local lines=()
  mapfile -t lines < <(docker port "$id" 2>/dev/null || true)
  if ((${#lines[@]} == 0)); then
    printf '-'
  else
    local IFS=,
    printf '%s' "${lines[*]}"
  fi
}

port_collision_report() {
  local service="$1"
  local env_var="${service_port_env[$service]}"
  local port
  port="$(service_port "$service")"
  local ids=()
  local id="-" name="-" image="-" compose_project="-" compose_service="-" provision_owner="-" provision_root="-" provision_project="-" owner pid command
  collect_published_container_ids ids "$port"
  ((${#ids[@]} == 0)) || id="${ids[0]}"
  if [[ "$id" != "-" ]]; then
    name="$(inspect_name "$id" || printf '-')"
    image="$(docker inspect --format '{{ .Config.Image }}' "$id" || printf '-')"
    compose_project="$(inspect_label "$id" "com.docker.compose.project")"
    compose_service="$(inspect_label "$id" "com.docker.compose.service")"
    provision_owner="$(inspect_label "$id" "$owner_label")"
    provision_root="$(inspect_label "$id" "$root_label")"
    provision_project="$(inspect_label "$id" "$project_label")"
    [[ -n "$compose_project" ]] || compose_project="-"
    [[ -n "$compose_service" ]] || compose_service="-"
    [[ -n "$provision_owner" ]] || provision_owner="-"
    [[ -n "$provision_root" ]] || provision_root="-"
    [[ -n "$provision_project" ]] || provision_project="-"
  fi
  owner="$(classify_owner "$id" "$compose_project" "$provision_owner" "$provision_root" "$provision_project")"
  host_listener_pair "$port" pid command
  [[ -n "$pid" ]] || pid="-"
  [[ -n "$command" ]] || command="-"
  printf 'port-collision\tservice=%s\tenv=%s\tport=%s\towner=%s\tcontainer_id=%s\tname=%s\timage=%s\tcompose_project=%s\tcompose_service=%s\tprovision_project=%s\thost_listener_pid=%s\thost_listener_command=%s\taction=%s\n' \
    "$service" "$env_var" "$port" "$owner" "$id" "$name" "$image" "$compose_project" "$compose_service" "$provision_project" "$pid" "$command" "set $env_var to a free port or stop the non-owned listener outside rasm-provision" >&2
}

preflight_ports() {
  local service failed=0
  while IFS= read -r service; do
    if port_busy "$(service_port "$service")" && ! port_owned_by_service "$service" "$(service_port "$service")"; then
      port_collision_report "$service"
      failed=1
    fi
  done < <(enabled_services)
  ((failed == 0)) || die "host port(s) already allocated; see port-collision row(s) above"
}

assert_owned_project() {
  local mode="${1:-strict}"
  local ids id owned root project service
  ids="$(docker ps -aq --filter "label=com.docker.compose.project=$project_name")"
  [[ -n "$ids" ]] || return 0
  while IFS= read -r id; do
    [[ -n "$id" ]] || continue
    owned="$(inspect_label "$id" "$owner_label")"
    [[ "$owned" == "1" ]] || die "refusing to manage unlabeled container in project $project_name: $id"
    root="$(inspect_label "$id" "$root_label")"
    [[ "$root" == "$root_fingerprint" ]] || die "refusing to manage container from another Rasm root in project $project_name: $id root=$root"
    project="$(inspect_label "$id" "$project_label")"
    [[ "$project" == "$project_name" ]] || die "refusing to manage container from another provision project in project $project_name: $id provision_project=$project"
    service="$(inspect_label "$id" "$service_label")"
    validate_owned_container_identity "$id" "$service" "$mode"
  done <<<"$ids"
}

assert_owned_named_resources() {
  local service volume owner root project service_value net name
  while IFS= read -r service; do
    volume="$(service_volume_name "$service")"
    if docker volume inspect "$volume" >/dev/null 2>&1; then
      owner="$(docker volume inspect --format "{{ index .Labels \"$owner_label\" }}" "$volume")"
      root="$(docker volume inspect --format "{{ index .Labels \"$root_label\" }}" "$volume")"
      project="$(docker volume inspect --format "{{ index .Labels \"$project_label\" }}" "$volume")"
      service_value="$(docker volume inspect --format "{{ index .Labels \"$service_label\" }}" "$volume")"
      [[ "$owner" == "1" && "$root" == "$root_fingerprint" && "$project" == "$project_name" && "$service_value" == "$service" ]] ||
        die "refusing to reuse volume with wrong labels: $volume"
    fi
  done < <(enabled_services)
  net="$(network_name)"
  if docker network inspect "$net" >/dev/null 2>&1; then
    owner="$(docker network inspect --format "{{ index .Labels \"$owner_label\" }}" "$net")"
    root="$(docker network inspect --format "{{ index .Labels \"$root_label\" }}" "$net")"
    project="$(docker network inspect --format "{{ index .Labels \"$project_label\" }}" "$net")"
    service_value="$(docker network inspect --format "{{ index .Labels \"$service_label\" }}" "$net")"
    name="$(docker network inspect --format '{{ .Name }}' "$net")"
    [[ "$owner" == "1" && "$root" == "$root_fingerprint" && "$project" == "$project_name" && "$service_value" == "network" && "$name" == "$net" ]] ||
      die "refusing to reuse network with wrong labels: $net"
  fi
}

require_enabled_service_running() {
  local service="$1"
  local id
  container_running_for_service "$service" || die "owned service is not running service=$service project=$project_name root=$root_fingerprint"
  id="$(container_id_for_service "$service")"
  [[ -n "$id" ]] || die "owned service is missing container service=$service project=$project_name"
  validate_owned_container_identity "$id" "$service"
}

require_enabled_services() {
  local service
  while IFS= read -r service; do
    require_enabled_service_running "$service"
  done < <(enabled_services)
  return 0
}

require_service_endpoint() {
  local service="$1"
  known_service "$service" || die "unknown service: $service"
  service_enabled "$service" || die "$service is disabled for project=$project_name"
  port_owned_by_service "$service" "$(service_port "$service")" ||
    die "configured port is not published by owned service service=$service port=$(service_port "$service") project=$project_name root=$root_fingerprint"
}

readiness_report() {
  local service="$1"
  local id name image state health ports
  id="$(container_id_for_service "$service")"
  if [[ -z "$id" ]]; then
    stderr_line "$(printf 'readiness\tservice=%s\tstatus=missing-container\tport=%s\tproject=%s\troot=%s' "$service" "$(service_port "$service")" "$project_name" "$root_fingerprint")"
    return 0
  fi
  name="$(inspect_name "$id" || printf '-')"
  image="$(docker inspect --format '{{ .Config.Image }}' "$id" || printf '-')"
  state="$(docker inspect --format '{{ .State.Status }}' "$id" || printf '-')"
  health="$(docker inspect --format '{{ if .State.Health }}{{ .State.Health.Status }}{{ else }}none{{ end }}' "$id" || printf '-')"
  ports="$(published_ports "$id")"
  stderr_line "$(printf 'readiness\tservice=%s\tstatus=timeout\tport=%s\tcontainer_id=%s\tname=%s\timage=%s\tdocker_status=%s\thealth=%s\tpublished=%s' \
    "$service" "$(service_port "$service")" "$id" "$name" "$image" "$state" "$health" "$ports")"
  while IFS= read -r line; do
    stderr_line "$(printf 'readiness-log\tservice=%s\t%s' "$service" "$line")"
  done < <(docker logs --tail 20 "$id" 2>&1 || true)
}

wait_service() {
  local service="$1"
  local id attempt=1
  while ((attempt <= 15)); do
    id="$(container_id_for_service "$service")"
    if [[ -n "$id" ]] && port_owned_by_service "$service" "$(service_port "$service")" &&
      docker exec "$id" pg_isready -U postgres -d rasm >/dev/null 2>&1; then
      if [[ "$output_json" == true ]]; then
        stderr_line "$(printf 'readiness\tservice=%s\tstatus=ready\tport=%s' "$service" "$(service_port "$service")")"
      else
        printf '%s\tready\t%s\n' "$service" "$(service_port "$service")"
      fi
      return 0
    fi
    sleep 1
    ((attempt += 1))
  done
  readiness_report "$service"
  die "$service did not become ready on port $(service_port "$service")"
}

wait_services() {
  local service
  while IFS= read -r service; do
    wait_service "$service"
  done < <(enabled_services)
  return 0
}

psql_exec() {
  local service="$1"
  shift
  local id
  require_service_endpoint "$service"
  id="$(container_id_for_service "$service")"
  [[ -n "$id" ]] || die "missing container for service=$service"
  local -a exec_args=()
  if [[ -t 0 && -t 1 ]]; then
    exec_args=(-it)
  else
    exec_args=(-i)
  fi
  if [[ "$auth_mode" == "auto-root" ]]; then
    # shellcheck disable=SC2016
    run_foreground_child docker exec "${exec_args[@]}" "$id" sh -c 'PGPASSWORD="$(cat "$1")"; export PGPASSWORD; shift; exec psql "$@"' \
      sh "/run/secrets/$(auth_secret_name "$service")" -X -w -U postgres -d rasm "$@"
  else
    run_foreground_child docker exec "${exec_args[@]}" "$id" psql -X -w -U postgres -d rasm "$@"
  fi
}

psql_tsv() {
  local service="$1"
  shift
  local id
  require_service_endpoint "$service"
  id="$(container_id_for_service "$service")"
  [[ -n "$id" ]] || die "missing container for service=$service"
  if [[ "$auth_mode" == "auto-root" ]]; then
    docker exec -i "$id" sh -c 'PGPASSWORD="$(cat "$1")"; export PGPASSWORD; shift; exec psql "$@"' \
      sh "/run/secrets/$(auth_secret_name "$service")" -X -q -w -U postgres -d rasm -v ON_ERROR_STOP=1 -A -F $'\t' -t "$@"
  else
    docker exec -i "$id" psql -X -q -w -U postgres -d rasm -v ON_ERROR_STOP=1 -A -F $'\t' -t "$@"
  fi
}

verify_service_extensions() {
  local service="$1"
  local values
  values="$(extension_sql_values "$service")"
  [[ -n "$values" ]] || return 0
  psql_tsv "$service" <<SQL
SET client_min_messages TO warning;
CREATE TEMP TABLE rasm_extension_target(
  ordinal integer NOT NULL,
  name text PRIMARY KEY,
  category text NOT NULL,
  required boolean NOT NULL,
  create_on_verify boolean NOT NULL
);
CREATE TEMP TABLE rasm_extension_runtime(
  name text PRIMARY KEY,
  state text NOT NULL
);
INSERT INTO rasm_extension_target(ordinal, name, category, required, create_on_verify) VALUES
$values;
DO \$\$
DECLARE target record;
BEGIN
  FOR target IN
    SELECT name
    FROM rasm_extension_target
    WHERE create_on_verify
      AND EXISTS (SELECT 1 FROM pg_available_extensions WHERE name = rasm_extension_target.name)
    ORDER BY ordinal
  LOOP
    BEGIN
      EXECUTE format('CREATE EXTENSION IF NOT EXISTS %I', target.name);
    EXCEPTION
      WHEN insufficient_privilege OR feature_not_supported OR undefined_file OR undefined_object OR invalid_parameter_value OR object_not_in_prerequisite_state THEN
        NULL;
    END;
  END LOOP;
END
\$\$;
CREATE TEMP TABLE rasm_pg_cron_probe_context(
  probe_id text PRIMARY KEY,
  job_name text NOT NULL
);
CREATE TEMP TABLE rasm_pg_cron_job(
  job_id bigint
);
INSERT INTO rasm_pg_cron_probe_context(probe_id, job_name)
SELECT probe_id, 'rasm_pg_cron_' || probe_id
FROM (SELECT 'probe_' || md5(clock_timestamp()::text || random()::text) AS probe_id) seed
WHERE EXISTS (SELECT 1 FROM rasm_extension_target WHERE name = 'pg_cron' AND required)
  AND EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron');
DO \$\$
DECLARE
  job_id bigint;
  probe_id text;
BEGIN
  SELECT c.probe_id
  INTO probe_id
  FROM rasm_pg_cron_probe_context c
  LIMIT 1;

  IF probe_id IS NULL THEN
    RETURN;
  END IF;

  CREATE TABLE IF NOT EXISTS public.rasm_pg_cron_probe(
    id text PRIMARY KEY,
    observed_at timestamptz NOT NULL DEFAULT clock_timestamp()
  );

  SELECT cron.schedule(
           c.job_name,
           '1 seconds',
           format('INSERT INTO public.rasm_pg_cron_probe(id) VALUES (%L) ON CONFLICT DO NOTHING', c.probe_id)
         )
  INTO job_id
  FROM rasm_pg_cron_probe_context c
  LIMIT 1;

  IF job_id IS NOT NULL THEN
    INSERT INTO rasm_pg_cron_job(job_id) VALUES (job_id);
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    BEGIN
      DROP TABLE IF EXISTS public.rasm_pg_cron_probe;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    INSERT INTO rasm_extension_runtime(name, state) VALUES ('pg_cron', 'scheduler-failed')
    ON CONFLICT (name) DO UPDATE SET state = excluded.state;
END
\$\$;
DO \$\$
DECLARE
  probe_id text;
  job_id bigint;
  deadline timestamptz := clock_timestamp() + interval '20 seconds';
BEGIN
  SELECT c.probe_id, j.job_id
  INTO probe_id, job_id
  FROM rasm_pg_cron_probe_context c
  CROSS JOIN rasm_pg_cron_job j
  LIMIT 1;

  IF job_id IS NULL THEN
    DROP TABLE IF EXISTS public.rasm_pg_cron_probe;
    RETURN;
  END IF;

  LOOP
    EXIT WHEN EXISTS (SELECT 1 FROM public.rasm_pg_cron_probe WHERE id = probe_id);
    EXIT WHEN clock_timestamp() >= deadline;
    PERFORM pg_sleep(1);
  END LOOP;

  PERFORM cron.unschedule(job_id);

  IF EXISTS (SELECT 1 FROM public.rasm_pg_cron_probe WHERE id = probe_id) THEN
    INSERT INTO rasm_extension_runtime(name, state) VALUES ('pg_cron', 'ok')
    ON CONFLICT (name) DO UPDATE SET state = excluded.state;
  ELSE
    INSERT INTO rasm_extension_runtime(name, state) VALUES ('pg_cron', 'scheduler-timeout')
    ON CONFLICT (name) DO UPDATE SET state = excluded.state;
  END IF;

  DELETE FROM public.rasm_pg_cron_probe WHERE id = probe_id;
  DROP TABLE IF EXISTS public.rasm_pg_cron_probe;
EXCEPTION
  WHEN OTHERS THEN
    BEGIN
      IF job_id IS NOT NULL THEN
        PERFORM cron.unschedule(job_id);
      END IF;
      DELETE FROM public.rasm_pg_cron_probe WHERE id = probe_id;
      DROP TABLE IF EXISTS public.rasm_pg_cron_probe;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    INSERT INTO rasm_extension_runtime(name, state) VALUES ('pg_cron', 'scheduler-failed')
    ON CONFLICT (name) DO UPDATE SET state = excluded.state;
END
\$\$;
SELECT $(sql_quote "$service"),
       t.name,
       CASE
         WHEN t.name = 'pg_cron'
              AND t.required
              AND e.extname IS NOT NULL
              AND (
                current_setting('cron.database_name', true) IS DISTINCT FROM current_database()
                OR current_setting('cron.use_background_workers', true) IS DISTINCT FROM 'on'
              ) THEN 'misconfigured'
         WHEN t.name = 'pg_cron'
              AND t.required
              AND e.extname IS NOT NULL
              AND COALESCE(r.state, 'scheduler-not-run') != 'ok' THEN COALESCE(r.state, 'scheduler-not-run')
         WHEN e.extname IS NOT NULL THEN 'ok'
         WHEN a.name IS NULL AND t.required THEN 'missing'
         WHEN a.name IS NULL THEN 'unavailable'
         WHEN t.create_on_verify THEN 'not-created'
         ELSE 'available'
       END,
       COALESCE(e.extversion, a.default_version, '-'),
       t.category,
       CASE WHEN t.required THEN 'required' ELSE 'optional' END
FROM rasm_extension_target t
LEFT JOIN pg_available_extensions a ON a.name = t.name
LEFT JOIN pg_extension e ON e.extname = t.name
LEFT JOIN rasm_extension_runtime r ON r.name = t.name
ORDER BY t.ordinal;
SQL
}

verify_rows() {
  local service handler disabled_row
  for service in "${service_order[@]}"; do
    if service_enabled "$service"; then
      handler="${service_verify_handler[$service]}"
      "$handler" "$service"
    else
      disabled_row="${service_disabled_verify_row[$service]}"
      [[ -z "$disabled_row" ]] || printf '%s\n' "$disabled_row"
    fi
  done
  return 0
}

verify_required_rows_ok() {
  local rows="$1"
  local service state version category required
  while IFS=$'\t' read -r service _extension state version category required; do
    [[ -n "$service" ]] || continue
    [[ "$required" == "required" && "$state" != "ok" ]] && return 1
  done <<<"$rows"
  return 0
}

verify_rows_json() {
  jq -Rsc '
    def dashnull: if . == null or . == "" or . == "-" then null else . end;
    split("\n")
    | map(select(length > 0) | split("\t") | select(length >= 4))
    | map({service: .[0], extension: .[1], state: .[2], version: (.[3] | dashnull), category: (.[4] // null | dashnull), required: ((.[5] // "optional") == "required")})
  '
}

remove_owned_containers() {
  local ids=()
  local id service project
  collect_owned_container_ids ids
  ((${#ids[@]} > 0)) || return 0
  for id in "${ids[@]}"; do
    service="$(inspect_label "$id" "$service_label")"
    project="$(inspect_label "$id" "$project_label")"
    [[ "$project" == "$project_name" ]] || die "refusing to remove owned container from different project label=$project id=$id"
    validate_owned_container_identity "$id" "$service" cleanup
  done
  docker rm -f "${ids[@]}" >/dev/null
}

remove_owned_volumes() {
  local volumes=()
  local volume service project root
  collect_owned_volume_names volumes
  ((${#volumes[@]} > 0)) || return 0
  for volume in "${volumes[@]}"; do
    service="$(docker volume inspect --format "{{ index .Labels \"$service_label\" }}" "$volume")" || return
    root="$(docker volume inspect --format "{{ index .Labels \"$root_label\" }}" "$volume")" || return
    project="$(docker volume inspect --format "{{ index .Labels \"$project_label\" }}" "$volume")" || return
    known_service "$service" || die "refusing to remove unexpected owned volume service=$service name=$volume"
    [[ "$root" == "$root_fingerprint" && "$project" == "$project_name" ]] || die "refusing to remove volume outside current root/project name=$volume root=$root project=$project"
    docker volume rm "$volume" >/dev/null || return
  done
}

remove_owned_networks() {
  local networks=()
  local network service root project
  collect_owned_network_names networks
  ((${#networks[@]} > 0)) || return 0
  for network in "${networks[@]}"; do
    service="$(docker network inspect --format "{{ index .Labels \"$service_label\" }}" "$network")" || return
    root="$(docker network inspect --format "{{ index .Labels \"$root_label\" }}" "$network")" || return
    project="$(docker network inspect --format "{{ index .Labels \"$project_label\" }}" "$network")" || return
    [[ "$service" == "network" ]] || die "refusing to remove unexpected owned network service=$service name=$network"
    [[ "$root" == "$root_fingerprint" && "$project" == "$project_name" ]] || die "refusing to remove network outside current root/project name=$network root=$root project=$project"
    docker network rm "$network" >/dev/null || return
  done
}

cleanup_runtime_docker_resources() {
  remove_owned_containers
  remove_owned_networks
}

cleanup_owned_docker_resources() {
  remove_owned_containers
  remove_owned_volumes
  remove_owned_networks
}

file_record_json() {
  local kind="$1"
  local type="$2"
  local path="$3"
  local exists=false
  [[ -e "$path" ]] && exists=true
  if [[ "$diagnostic_json" == true ]]; then
    jq -nc --arg kind "$kind" --arg type "$type" --arg path "$path" --argjson exists "$exists" \
      '{kind: $kind, type: $type, path: $path, exists: $exists}'
  else
    jq -nc --arg kind "$kind" --arg type "$type" --argjson exists "$exists" \
      '{kind: $kind, type: $type, exists: $exists}'
  fi
}

generated_files_json() {
  {
    file_record_json provisioning_root directory "$provisioning_root_dir"
    file_record_json project_dir directory "$provisioning_dir"
    file_record_json current symlink "$current_link"
    file_record_json compose file "$compose_file"
    file_record_json env file "$env_file"
    file_record_json volume_ledger file "$volume_ledger_file"
    file_record_json docker_config_dir directory "$docker_config_dir"
    file_record_json lock_dir directory "$lock_dir"
    if [[ -d "$provisioning_dir" && ! -L "$provisioning_dir" ]]; then
      local path
      for path in "$provisioning_dir"/.gen-* "$provisioning_dir"/.gen.* "$provisioning_dir"/.current.next "$docker_config_dir"/.tmp.*; do
        [[ -e "$path" ]] || continue
        file_record_json generated_artifact path "$path"
      done
    fi
  } | jq -s 'sort_by(.kind, (.path // ""))'
}

generated_artifacts_json() {
  jq -nc --argjson generated "$(generated_files_json)" '{generated: $generated}'
}

owned_containers_json() {
  local ids=()
  collect_owned_container_ids ids
  ((${#ids[@]} > 0)) || {
    printf '[]\n'
    return 0
  }
  docker inspect "${ids[@]}" | jq -c \
    --arg owner_label "$owner_label" \
    --arg service_label "$service_label" \
    --arg root_label "$root_label" \
    --arg project_label "$project_label" \
    --arg net "$(network_name)" \
    --argjson identities "$(service_identity_json)" '
    map(
      (.Config.Labels[$service_label] // "") as $service
      | ($identities[$service] // null) as $expected
      | (($expected != null)
          and (.Config.Image == $expected.image)
          and ((.NetworkSettings.Networks // {})[$net] != null)
          and any(.Mounts[]?; .Name == $expected.volume and .Destination == $expected.mount)) as $identityOk
      | {
          id: .Id,
          name: (.Name | ltrimstr("/")),
          image: .Config.Image,
          service: $service,
          owner: (.Config.Labels[$owner_label] // ""),
          root: (.Config.Labels[$root_label] // ""),
          project: (.Config.Labels[$project_label] // ""),
          status: .State.Status,
          health: (if .State.Health then .State.Health.Status else "none" end),
          ports: (.NetworkSettings.Ports // {}),
          identityOk: $identityOk,
          identityIssue: (
            if $identityOk then null
            elif $expected == null then "unknown-service"
            elif .Config.Image != $expected.image then "image-mismatch"
            elif ((.NetworkSettings.Networks // {})[$net] == null) then "network-mismatch"
            else "volume-mount-mismatch"
            end
          )
        }
    ) | sort_by(.service, .name, .id)
  '
}

owned_volumes_json() {
  local volumes=()
  collect_owned_volume_names volumes
  ((${#volumes[@]} > 0)) || {
    printf '[]\n'
    return 0
  }
  docker volume inspect "${volumes[@]}" | jq -c --arg owner_label "$owner_label" --arg service_label "$service_label" --arg root_label "$root_label" --arg project_label "$project_label" --argjson diagnostic "$([[ "$diagnostic_json" == true ]] && printf true || printf false)" '
    map({
      name: .Name,
      driver: .Driver,
      service: (.Labels[$service_label] // ""),
      owner: (.Labels[$owner_label] // ""),
      root: (.Labels[$root_label] // ""),
      project: (.Labels[$project_label] // "")
    } + if $diagnostic then {mountpoint: .Mountpoint} else {} end) | sort_by(.service, .name)
  '
}

owned_networks_json() {
  local networks=()
  collect_owned_network_names networks
  ((${#networks[@]} > 0)) || {
    printf '[]\n'
    return 0
  }
  docker network inspect "${networks[@]}" | jq -c --arg owner_label "$owner_label" --arg service_label "$service_label" --arg root_label "$root_label" --arg project_label "$project_label" --argjson diagnostic "$([[ "$diagnostic_json" == true ]] && printf true || printf false)" '
    map({
      id: .Id,
      name: .Name,
      driver: .Driver,
      service: (.Labels[$service_label] // ""),
      owner: (.Labels[$owner_label] // ""),
      root: (.Labels[$root_label] // ""),
      project: (.Labels[$project_label] // ""),
      attachedContainerCount: ((.Containers // {}) | length)
    } + if $diagnostic then {attachedContainers: (.Containers // {})} else {} end) | sort_by(.service, .name)
  '
}

service_records_tsv() {
  local service
  resolve_auth
  resolve_ports false
  for service in "${service_order[@]}"; do
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$service" \
      "$(service_enabled_value "$service")" \
      "${service_profile[$service]}" \
      "$(service_image "$service")" \
      "$(service_port "$service")" \
      "$(service_dsn_redacted "$service")" \
      "${service_dsn_env[$service]}" \
      "${service_image_env[$service]}" \
      "${service_port_env[$service]}" \
      "$(service_port_source "$service")"
  done
}

service_records_json() {
  service_records_tsv | jq -Rsc '
    split("\n")
    | map(select(length > 0) | split("\t"))
    | map({
        key: .[0],
        enabled: (.[1] == "1"),
        connectable: (.[1] == "1"),
        profile: .[2],
        image: .[3],
        imageEnv: .[7],
        host: "127.0.0.1",
        port: (.[4] | tonumber),
        portEnv: .[8],
        portSource: .[9],
        containerPort: 5432,
        dsnRedacted: (if .[1] == "1" then .[5] else null end),
        dsnEnv: .[6],
        composeService: .[0]
      })
    | map({
        (.key): {
          key,
          enabled,
          connectable,
          profile,
          image,
          imageEnv,
          host,
          port,
          portEnv,
          portSource,
          containerPort,
          dsnRedacted,
          dsnEnv,
          composeService
        }
      })
    | add // {}
  '
}

configured_images_json() {
  service_records_tsv | jq -Rsc '
    split("\n")
    | map(select(length > 0) | split("\t"))
    | map({
        service: .[0],
        image: .[3],
        enabled: (.[1] == "1")
      })
    | sort_by(.service)
  '
}

port_record_json() {
  local service="$1"
  local port ids=() id="-" name="-" image="-" compose_project="-" compose_service="-" provision_owner="-" provision_root="-" provision_project="-" owner="none" pid command state occupied=false
  port="$(service_port "$service")"
  state="free"
  service_enabled "$service" || state="disabled"
  collect_published_container_ids ids "$port" || die "docker port inspection failed for port=$port"
  host_listener_pair "$port" pid command
  [[ -n "$pid" ]] || pid="-"
  [[ -n "$command" ]] || command="-"
  if ((${#ids[@]} > 0)); then
    id="${ids[0]}"
    name="$(inspect_name "$id" || printf '-')"
    image="$(docker inspect --format '{{ .Config.Image }}' "$id" || printf '-')"
    compose_project="$(inspect_label "$id" "com.docker.compose.project")"
    compose_service="$(inspect_label "$id" "com.docker.compose.service")"
    provision_owner="$(inspect_label "$id" "$owner_label")"
    provision_root="$(inspect_label "$id" "$root_label")"
    provision_project="$(inspect_label "$id" "$project_label")"
    owner="$(classify_owner "$id" "$compose_project" "$provision_owner" "$provision_root" "$provision_project")"
    occupied=true
    [[ "$state" == "disabled" ]] || state="busy"
  elif [[ "$pid" != "-" ]]; then
    owner="external:host-listener"
    occupied=true
    [[ "$state" == "disabled" ]] || state="busy"
  fi
  jq -nc \
    --arg service "$service" \
    --arg env "${service_port_env[$service]}" \
    --arg port "$port" \
    --arg source "$(service_port_source "$service")" \
    --arg state "$state" \
    --argjson occupied "$occupied" \
    --arg owner "$owner" \
    --arg container_id "$id" \
    --arg name "$name" \
    --arg image "$image" \
    --arg compose_project "$compose_project" \
    --arg compose_service "$compose_service" \
    --arg provision_project "$provision_project" \
    --arg host_listener_pid "$pid" \
    'def noneish: if . == "" or . == "-" then null else . end;
    {
      service: $service,
      env: $env,
      value: ($port | tonumber),
      portSource: $source,
      state: $state,
      occupied: $occupied,
      owner: $owner,
      ownerClass: $owner,
      containerId: ($container_id | noneish),
      name: ($name | noneish),
      image: ($image | noneish),
      composeProject: ($compose_project | noneish),
      composeService: ($compose_service | noneish),
      provisionProject: ($provision_project | noneish),
      hostListenerPid: ($host_listener_pid | noneish | if . == null then null else (try tonumber catch null) end)
    }'
}

port_record_offline_json() {
  local service="$1"
  local port pid command owner="none" state="free" occupied=false
  port="$(service_port "$service")"
  service_enabled "$service" || state="disabled"
  host_listener_pair "$port" pid command
  [[ -n "$pid" ]] || pid="-"
  [[ -n "$command" ]] || command="-"
  if [[ "$pid" != "-" ]]; then
    owner="external:host-listener"
    occupied=true
    [[ "$state" == "disabled" ]] || state="busy"
  fi
  jq -nc \
    --arg service "$service" \
    --arg env "${service_port_env[$service]}" \
    --arg port "$port" \
    --arg source "$(service_port_source "$service")" \
    --arg state "$state" \
    --argjson occupied "$occupied" \
    --arg owner "$owner" \
    --arg host_listener_pid "$pid" \
    'def noneish: if . == "" or . == "-" then null else . end;
    {
      service: $service,
      env: $env,
      value: ($port | tonumber),
      portSource: $source,
      state: $state,
      occupied: $occupied,
      owner: $owner,
      ownerClass: $owner,
      containerId: null,
      name: null,
      image: null,
      composeProject: null,
      composeService: null,
      provisionProject: null,
      hostListenerPid: ($host_listener_pid | noneish | if . == null then null else (try tonumber catch null) end)
    }'
}

port_records_json() {
  local service
  for service in "${service_order[@]}"; do
    port_record_json "$service"
  done | jq -s 'sort_by(.service)'
}

port_records_offline_json() {
  local service
  for service in "${service_order[@]}"; do
    port_record_offline_json "$service"
  done | jq -s 'sort_by(.service)'
}

resource_counts_json() {
  local containers_json="${1:-[]}"
  local volumes_json="${2:-[]}"
  local networks_json="${3:-[]}"
  local generated_json="${4:-[]}"
  jq -n \
    --argjson containers "$containers_json" \
    --argjson volumes "$volumes_json" \
    --argjson networks "$networks_json" \
    --argjson generated "$generated_json" \
    '{containers: ($containers | length), volumes: ($volumes | length), networks: ($networks | length), generated: ([ $generated[] | select(.exists == true) ] | length), expectedGenerated: ($generated | length)}'
}

emit_stack_json() {
  local command="$1"
  local ok="$2"
  local extra_filter="${3:-.}"
  shift 3 || true
  jq -n \
    --argjson schemaVersion "$schema_version" \
    --arg command "$command" \
    --argjson ok "$ok" \
    --arg project "$project_name" \
    --arg rootFingerprint "$root_fingerprint" \
    --argjson auth "$(auth_json)" \
    --argjson portPolicy "$(port_policy_json)" \
    --argjson services "$(service_records_json)" \
    --argjson warnings "$(warnings_json)" \
    --argjson artifacts "$(generated_artifacts_json)" \
    "$@" \
    "{schemaVersion: \$schemaVersion, command: \$command, ok: \$ok, project: \$project, rootFingerprint: \$rootFingerprint, auth: \$auth, portPolicy: \$portPolicy, services: \$services, warnings: \$warnings, artifacts: \$artifacts} | $extra_filter"
  json_result_emitted=true
}

emit_ports_text() {
  local records="$1"
  jq -r '
    .[]
    | [
        "port",
        "service=\(.service)",
        "env=\(.env)",
        "value=\(.value)",
        "state=\(.state)",
        "occupied=\(.occupied)",
        "owner=\(.owner)",
        "container_id=\(.containerId // "-")",
        "name=\(.name // "-")",
        "image=\(.image // "-")",
        "compose_project=\(.composeProject // "-")",
        "compose_service=\(.composeService // "-")",
        "provision_project=\(.provisionProject // "-")",
        "host_listener_pid=\(.hostListenerPid // "-")",
        "host_listener_command=redacted"
      ]
    | join("\t")
  ' <<<"$records"
}

relevant_images_json() {
  local configured
  configured="$(configured_images_json)"
  docker image ls --format '{{json .}}' 2>/dev/null |
    jq -s --argjson configured "$configured" '
      def ref: .Repository + ":" + .Tag;
      map({repository: .Repository, tag: .Tag, id: (.ID // null), size: (.Size // null), ref: ref})
      | map(select(.ref as $ref | any($configured[]; .image == $ref or (.image | startswith($ref + "@")))))
      | sort_by(.repository, .tag)
    '
}

docker_disk_json() {
  docker system df --format '{{json .}}' 2>/dev/null | jq -s 'sort_by(.Type // "")'
}

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
  jq -nc --argjson present "$present" --argjson active "$active" --arg state "$state" --argjson pidAlive "$pid_alive" --argjson heartbeatStale "$heartbeat_stale" --arg path "$lock_dir" --arg pid "$pid" --arg host "$host" --arg startedAt "$started_at" --arg heartbeat "$heartbeat" --arg command "$command" --argjson diagnostic "$([[ "$diagnostic_json" == true ]] && printf true || printf false)" \
    'def empty_null: if . == "" then null else . end;
    {present: $present, active: $active, state: $state, pid: ($pid | empty_null | if . == null then null else (try tonumber catch null) end), pidAlive: $pidAlive, host: ($host | empty_null), startedAt: ($startedAt | empty_null), lastHeartbeatEpoch: ($heartbeat | empty_null | if . == null then null else (try tonumber catch null) end), heartbeatStale: $heartbeatStale, command: ($command | empty_null)}
    + if $diagnostic then {path: $path} else {} end'
}

colima_json() {
  local status raw
  if command -v colima >/dev/null 2>&1; then
    if status="$(colima status --json 2>/dev/null)"; then
      if [[ "$diagnostic_json" == true ]]; then
        jq -nc --argjson status "$status" '{available: true, status: $status, raw: null}'
      else
        jq -nc --argjson status "$status" '{available: true, status: {running: ($status.running // null), arch: ($status.arch // null), runtime: ($status.runtime // null)}, raw: null}'
      fi
    else
      raw="$(colima status 2>&1 || true)"
      jq -nc --arg raw "$raw" --argjson diagnostic "$([[ "$diagnostic_json" == true ]] && printf true || printf false)" '{available: true, status: null, raw: (if $diagnostic then $raw else null end)}'
    fi
  else
    jq -nc '{available: false, status: null, raw: null}'
  fi
}

cmd_up() {
  parse_json_args up "$@"
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
  local generation verify_output extensions_json compose_up_log service
  local auto_retry_count=0
  while true; do
    generation="$(create_generation)"
    unpublished_generation="$generation"
    unpublished_compose_file="$generation/compose.yaml"
    compose_up_log="$provisioning_dir/.tmp.compose-up-$SRANDOM.log"
    if docker_compose_file "$generation/compose.yaml" up -d --remove-orphans --wait --wait-timeout 180 >"$compose_up_log" 2>&1; then
      rm -f "$compose_up_log"
      break
    fi
    while IFS= read -r line; do
      stderr_line "$line"
    done <"$compose_up_log"
    if [[ "$port_policy_mode" == "auto" ]] && compose_bind_failed "$compose_up_log" && ((auto_retry_count < 8)); then
      auto_port_blacklist+=("$(current_auto_base)")
      ((auto_retry_count += 1))
      warn "auto port block conflicted during Docker bind; retrying deterministic next block attempt=$auto_retry_count"
      docker_compose_file "$generation/compose.yaml" down --remove-orphans >/dev/null 2>&1 || true
      rm -rf -- "$generation" "$compose_up_log"
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
    rm -f "$compose_up_log"
    restore_previous_generation "$previous_compose" "$generation/compose.yaml" || true
    return 1
  done
  require_enabled_services
  wait_services
  release_port_locks || true
  if ! verify_output="$(verify_rows)"; then
    restore_previous_generation "$previous_compose" "$generation/compose.yaml" || true
    return 1
  fi
  if ! verify_required_rows_ok "$verify_output"; then
    if [[ "$output_json" != true || "$diagnostic_json" == true ]]; then
      printf '%s\n' "$verify_output" >&2
    fi
    restore_previous_generation "$previous_compose" "$generation/compose.yaml" || true
    die "required extension verification failed; generation was not published"
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
    extensions_json="$(printf '%s\n' "$verify_output" | verify_rows_json)"
    # shellcheck disable=SC2016
    emit_stack_json up true \
      '. + {extensions: $extensions, ports: $ports, summary: {requiredOk: ([ $extensions[] | select(.required and .state == "ok") ] | length), requiredMissing: ([ $extensions[] | select(.required and .state != "ok") ] | length)}}' \
      --argjson extensions "$extensions_json" \
      --argjson ports "$(port_records_json)"
  else
    printf '%s\n' "$verify_output"
  fi
}

cmd_down() {
  parse_json_args down "$@"
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
      '. + {dockerAvailable: $dockerAvailable, matchedBeforeDown: {containers: $containers, networks: $networks, generated: $generated}, cleanupPolicy: "preserve-volumes"}' \
      --argjson dockerAvailable "$([[ "$docker_rc" -eq 0 ]] && printf true || printf false)" \
      --argjson containers "$before_containers" \
      --argjson networks "$before_networks" \
      --argjson generated "$before_generated"
  fi
  return "$docker_rc"
}

cmd_verify() {
  local json=false
  if [[ "$output_json" == true ]]; then
    [[ "$#" -eq 0 ]] || die_usage "verify accepts no arguments when --json is global"
    json=true
  elif [[ "${1:-}" == "--json" ]]; then
    [[ "$#" -eq 1 ]] || die_usage "verify --json accepts no additional arguments"
    output_json=true
    json=true
  else
    [[ "$#" -eq 0 ]] || die_usage "verify accepts only --json or no arguments"
  fi
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
  local rows extensions_json ok_json
  rows="$(verify_rows)"
  verify_required_rows_ok "$rows" || ok_json=false
  if [[ "$json" == true ]]; then
    extensions_json="$(printf '%s\n' "$rows" | verify_rows_json)"
    [[ "${ok_json:-}" == false ]] || ok_json="$(jq -r 'all(.[]; (.required | not) or .state == "ok")' <<<"$extensions_json")"
    jq -n \
      --argjson schemaVersion "$schema_version" \
      --arg project "$project_name" \
      --arg rootFingerprint "$root_fingerprint" \
      --argjson ok "$ok_json" \
      --argjson auth "$(auth_json)" \
      --argjson portPolicy "$(port_policy_json)" \
      --argjson services "$(service_records_json)" \
      --argjson extensions "$extensions_json" \
      '{schemaVersion: $schemaVersion, command: "verify", ok: $ok, project: $project, rootFingerprint: $rootFingerprint, auth: $auth, portPolicy: $portPolicy, services: $services, extensions: $extensions, summary: {ok: ([ $extensions[] | select(.state == "ok") ] | length), requiredOk: ([ $extensions[] | select(.required and .state == "ok") ] | length), requiredMissing: ([ $extensions[] | select(.required and .state != "ok") ] | length), available: ([ $extensions[] | select(.state == "available") ] | length), unavailable: ([ $extensions[] | select(.state == "unavailable") ] | length), disabled: ([ $extensions[] | select(.state == "disabled") ] | length)}}'
    json_result_emitted=true
    [[ "$ok_json" == true ]] || exit 1
  else
    printf '%s\n' "$rows"
    verify_required_rows_ok "$rows" || die "required extension verification failed"
  fi
}

cmd_psql_service() {
  local service="$1"
  shift
  require_root
  validate_static_env
  assert_no_active_mutation_for_psql
  require_mutating_docker
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
    jq -n \
      --argjson schemaVersion "$schema_version" \
      --arg project "$project_name" \
      --arg rootFingerprint "$root_fingerprint" \
      --argjson dockerAvailable "$docker_ok" \
      --arg dockerIssue "$docker_issue" \
      --argjson auth "$(auth_json)" \
      --argjson portPolicy "$(port_policy_json)" \
      --argjson services "$(service_records_json)" \
      --argjson containers "$containers_json" \
      --argjson ports "$ports_json" \
      --argjson lock "$lock_state" \
      '{
        schemaVersion: $schemaVersion,
        command: "status",
        ok: true,
        project: $project,
        rootFingerprint: $rootFingerprint,
        auth: $auth,
        portPolicy: $portPolicy,
        dockerAvailable: $dockerAvailable,
        dockerIssue: (if $dockerAvailable then null else $dockerIssue end),
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
        ),
        services: $services,
        containers: $containers,
        ports: $ports,
        lock: $lock
      }'
    json_result_emitted=true
    return 0
  fi
  local ids=()
  local id service name image state health ports identity_json identity_ok identity_issue
  if [[ "$docker_ok" != true ]]; then
    printf 'status\tstate=docker-unavailable\tproject=%s\troot=%s\treason=%s\n' "$project_name" "$root_fingerprint" "$docker_issue"
    return 0
  fi
  collect_owned_container_ids ids
  if ((${#ids[@]} == 0)); then
    printf 'status\tstate=empty\tproject=%s\troot=%s\n' "$project_name" "$root_fingerprint"
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
      "$service" "$id" "$name" "$image" "$state" "$health" "$ports" "$identity_ok" "$identity_issue" "$project_name" "$root_fingerprint"
  done
}

cmd_env() {
  require_root
  validate_static_env
  if command_wants_json env "$@"; then
    jq -n \
      --argjson schemaVersion "$schema_version" \
      --arg project "$project_name" \
      --arg rootFingerprint "$root_fingerprint" \
      --arg ownerLabel "$owner_label" \
      --arg serviceLabel "$service_label" \
      --arg rootLabel "$root_label" \
      --arg projectLabel "$project_label" \
      --arg timescaleDsn "$(service_dsn_redacted timescale)" \
      --arg searchDsn "$(service_dsn_redacted search)" \
      --arg pgduckdbDsn "$(service_dsn_redacted pgduckdb)" \
      --arg pgduckdbEnabled "$(service_enabled_value pgduckdb)" \
      --argjson auth "$(auth_json)" \
      --argjson portPolicy "$(port_policy_json)" \
      --argjson services "$(service_records_json)" \
      '{
        schemaVersion: $schemaVersion,
        command: "env",
        ok: true,
        project: $project,
        rootFingerprint: $rootFingerprint,
        auth: $auth,
        portPolicy: $portPolicy,
        paths: {redacted: true},
        labels: {owner: $ownerLabel, service: $serviceLabel, root: $rootLabel, project: $projectLabel},
        services: $services,
        RASM_PROVISION_PROJECT: $project,
        RASM_TIMESCALE_DSN: $timescaleDsn,
        RASM_SEARCH_DSN: $searchDsn,
        RASM_PGDUCKDB_DSN: (if $pgduckdbEnabled == "1" then $pgduckdbDsn else null end),
        RASM_PROVISION_PGDUCKDB: $pgduckdbEnabled
      }'
    json_result_emitted=true
    return 0
  fi
  printf 'export RASM_ROOT=%q\n' "$rasm_root"
  printf 'export RASM_PROVISION_PROJECT=%q\n' "$project_name"
  printf 'export RASM_PROVISION_DIR=%q\n' "$provisioning_dir"
  printf 'export RASM_PROVISION_COMPOSE=%q\n' "$compose_file"
  printf 'export RASM_PROVISION_ENV=%q\n' "$env_file"
  local service
  for service in "${service_order[@]}"; do
    if service_enabled "$service"; then
      printf 'export %s=%q\n' "${service_dsn_env[$service]}" "$(service_dsn "$service")"
    else
      printf 'unset %s\n' "${service_dsn_env[$service]}"
    fi
  done
  printf 'export RASM_PROVISION_PGDUCKDB=%q\n' "$(service_enabled_value pgduckdb)"
}

cmd_paths() {
  require_root
  if command_wants_json paths "$@"; then
    jq -n \
      --argjson schemaVersion "$schema_version" \
      --arg project "$project_name" \
      --arg rootFingerprint "$root_fingerprint" \
      --argjson generated "$(generated_files_json)" \
      '{schemaVersion: $schemaVersion, command: "paths", ok: true, project: $project, rootFingerprint: $rootFingerprint, generated: $generated}'
    json_result_emitted=true
    return 0
  fi
  printf 'path\tname=rasm_root\tvalue=%s\texists=%s\n' "$rasm_root" "$([[ -d "$rasm_root" ]] && printf true || printf false)"
  printf 'path\tname=provisioning_root\tvalue=%s\texists=%s\n' "$provisioning_root_dir" "$([[ -d "$provisioning_root_dir" ]] && printf true || printf false)"
  printf 'path\tname=provisioning_dir\tvalue=%s\texists=%s\tparent_writable=%s\n' "$provisioning_dir" "$([[ -d "$provisioning_dir" ]] && printf true || printf false)" "$([[ -w "$rasm_root" ]] && printf true || printf false)"
  printf 'path\tname=current\tvalue=%s\texists=%s\texpected_written_by=up\n' "$current_link" "$([[ -e "$current_link" ]] && printf true || printf false)"
  printf 'path\tname=compose\tvalue=%s\texists=%s\texpected_written_by=up\n' "$compose_file" "$([[ -f "$compose_file" ]] && printf true || printf false)"
  printf 'path\tname=env\tvalue=%s\texists=%s\texpected_written_by=up\n' "$env_file" "$([[ -f "$env_file" ]] && printf true || printf false)"
  printf 'path\tname=docker_config\tvalue=%s\texists=%s\texpected_written_by=up\n' "$docker_config_dir" "$([[ -d "$docker_config_dir" ]] && printf true || printf false)"
}

cmd_plan() {
  require_root
  validate_static_env
  if command_wants_json plan "$@"; then
    emit_stack_json plan true \
      '. + {plan: {composeYaml: "redacted", authMode: .auth.mode, cleanupPolicy: "down-preserves-volumes", rollbackPolicy: "best-effort-compose-generation", imageStability: "best-effort-image-tag"}, ports: ([.services | to_entries[] | {service: .key, value: .value.port, env: .value.portEnv, portSource: .value.portSource}])}'
    return 0
  fi
  render_compose
}

cmd_extensions() {
  require_root
  validate_static_env
  if command_wants_json extensions "$@"; then
    jq -n \
      --argjson schemaVersion "$schema_version" \
      --arg project "$project_name" \
      --arg rootFingerprint "$root_fingerprint" \
      --argjson auth "$(auth_json)" \
      --argjson portPolicy "$(port_policy_json)" \
      --argjson services "$(service_records_json)" \
      --argjson extensions "$(extension_catalog_json)" \
      '{schemaVersion: $schemaVersion, command: "extensions", ok: true, project: $project, rootFingerprint: $rootFingerprint, auth: $auth, portPolicy: $portPolicy, services: $services, extensions: $extensions}'
    json_result_emitted=true
    return 0
  fi
  local service ext category required create_on_verify enabled required_bool create_bool
  for service in "${service_order[@]}"; do
    enabled="$(service_enabled_value "$service")"
    while IFS=$'\t' read -r ext category required create_on_verify; do
      [[ -n "$ext" ]] || continue
      required_bool=false
      create_bool=false
      [[ "$required" == 1 ]] && required_bool=true
      [[ "$create_on_verify" == 1 ]] && create_bool=true
      printf 'extension\tservice=%s\tname=%s\tcategory=%s\trequired=%s\tcreate_on_verify=%s\tenabled=%s\n' \
        "$service" "$ext" "$category" "$required_bool" "$create_bool" "$enabled"
    done < <(extension_catalog_rows "$service")
  done
  return 0
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
    jq -n \
      --argjson schemaVersion "$schema_version" \
      --arg project "$project_name" \
      --arg rootFingerprint "$root_fingerprint" \
      --argjson auth "$(auth_json)" \
      --argjson portPolicy "$(port_policy_json)" \
      --argjson dockerAvailable "$docker_ok" \
      --arg dockerIssue "$docker_issue" \
      --argjson ports "$ports_json" \
      '{schemaVersion: $schemaVersion, command: "ports", ok: true, project: $project, rootFingerprint: $rootFingerprint, auth: $auth, portPolicy: $portPolicy, dockerAvailable: $dockerAvailable, dockerIssue: (if $dockerAvailable then null else $dockerIssue end), ports: $ports}'
    json_result_emitted=true
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
    jq -n \
      --argjson schemaVersion "$schema_version" \
      --arg project "$project_name" \
      --arg rootFingerprint "$root_fingerprint" \
      --arg dockerPath "$docker_path" \
      --arg policyStatus "$policy_status" \
      --arg policyReason "$policy_reason" \
      --arg resolvedEndpoint "$docker_endpoint" \
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
      --argjson auth "$(auth_json)" \
      --argjson portPolicy "$(port_policy_json)" \
      --argjson diagnostic "$([[ "$diagnostic_json" == true ]] && printf true || printf false)" \
      '{
        schemaVersion: $schemaVersion,
        command: "doctor",
        ok: true,
        project: $project,
        rootFingerprint: $rootFingerprint,
        auth: $auth,
        portPolicy: $portPolicy,
        docker: {
          executablePresent: ($dockerPath != "-"),
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
        runtime: {
          rasmProvision: {present: true, schemaVersion: $schemaVersion},
          docker: {present: ($dockerPath != "-")},
          compose: {present: ($composeVersion != "unavailable"), version: (if $composeVersion == "unavailable" then null else $composeVersion end)},
          jq: {present: true},
          listenerProbeMethod: $listenerProbeMethod,
          anonymousDockerConfig: $anonymousConfigExists,
          hostCredentialHelperPresent: ($hostCredsStore != "none" or $hostCredHelpers != "0")
        },
        portsInspectable: $portsInspectable,
        portsUsable: ($portsInspectable and all($ports[]; .state == "disabled" or .owner == "none" or .owner == "provision:this-project")),
        blockedPorts: [$ports[] | select(.state != "disabled" and .owner != "none" and .owner != "provision:this-project")],
        ports: $ports,
        lock: $lock,
        colima: $colima
      }
      + if $diagnostic then {diagnostic: {resolvedEndpoint: $resolvedEndpoint, dockerPath: $dockerPath}} else {} end'
    json_result_emitted=true
    return 0
  fi
  printf 'doctor\tcommand=rasm-provision\n'
  printf 'doctor\trasm_root=%s\n' "$rasm_root"
  printf 'doctor\tproject=%s\n' "$project_name"
  printf 'doctor\troot_fingerprint=%s\n' "$root_fingerprint"
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
    jq -n \
      --argjson schemaVersion "$schema_version" \
      --arg project "$project_name" \
      --arg rootFingerprint "$root_fingerprint" \
      --arg ownerLabel "$owner_label" \
      --arg serviceLabel "$service_label" \
      --arg rootLabel "$root_label" \
      --arg projectLabel "$project_label" \
      --argjson dockerAvailable "$docker_ok" \
      --argjson auth "$(auth_json)" \
      --argjson portPolicy "$(port_policy_json)" \
      --argjson services "$(service_records_json)" \
      --argjson containers "$containers_json" \
      --argjson volumes "$volumes_json" \
      --argjson networks "$networks_json" \
      --argjson generated "$(generated_files_json)" \
      --argjson resources "$(resource_counts_json "$containers_json" "$volumes_json" "$networks_json" "$(generated_files_json)")" \
      --argjson configuredImages "$(configured_images_json)" \
      --argjson images "$images_json" \
      --argjson dockerDisk "$docker_disk" \
      --argjson ports "$ports_json" \
      --argjson lock "$(lock_json)" \
      --argjson colima "$(colima_json)" \
      '{
        schemaVersion: $schemaVersion,
        command: "inventory",
        ok: true,
        project: $project,
        rootFingerprint: $rootFingerprint,
        auth: $auth,
        portPolicy: $portPolicy,
        labels: {owner: $ownerLabel, service: $serviceLabel, root: $rootLabel, project: $projectLabel},
        dockerAvailable: $dockerAvailable,
        resources: $resources,
        services: $services,
        owned: {containers: $containers, volumes: $volumes, networks: $networks},
        generated: $generated,
        configuredImages: $configuredImages,
        images: $images,
        dockerDisk: $dockerDisk,
        ports: $ports,
        lock: $lock,
        colima: $colima,
        nonOwnedCleanupPolicy: "diagnostic-only"
      }'
    json_result_emitted=true
    return 0
  fi
  printf 'inventory\tproject=%s\troot=%s\tpolicy=owned-only\tdocker_available=%s\n' "$project_name" "$root_fingerprint" "$docker_ok"
  printf 'inventory\towned_containers=%s\n' "$(jq -r length <<<"$containers_json")"
  printf 'inventory\towned_volumes=%s\n' "$(jq -r length <<<"$volumes_json")"
  printf 'inventory\towned_networks=%s\n' "$(jq -r length <<<"$networks_json")"
  printf 'inventory\trelevant_images=%s\n' "$(jq -r length <<<"$images_json")"
  printf 'inventory\tdocker_disk_rows=%s\n' "$(jq -r length <<<"$docker_disk")"
  printf 'inventory\tnon_owned_cleanup_policy=diagnostic-only\n'
}

cmd_prune() {
  local json=false include_volumes=false has_owned=false arg
  [[ "$output_json" == true ]] && json=true
  for arg in "$@"; do
    case "$arg" in
      --owned) has_owned=true ;;
      --volumes) include_volumes=true ;;
      --json)
        [[ "$output_json" == false ]] || die_usage "prune received --json both globally and locally"
        command_supports_json prune || die_usage "prune does not support JSON output"
        output_json=true
        json=true
        ;;
      *) die_usage "prune requires --owned and accepts optional --volumes and --json" ;;
    esac
  done
  [[ "$has_owned" == true ]] || die_usage "prune requires --owned"
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
    jq -n \
      --argjson schemaVersion "$schema_version" \
      --arg project "$project_name" \
      --arg rootFingerprint "$root_fingerprint" \
      --argjson ok "$([[ "$rc" -eq 0 ]] && printf true || printf false)" \
      --argjson dockerAvailable "$docker_ok" \
      --argjson auth "$(auth_json)" \
      --argjson portPolicy "$(port_policy_json)" \
      --argjson containers "$before_containers" \
      --argjson volumes "$before_volumes" \
      --argjson networks "$before_networks" \
      --argjson generated "$before_generated" \
      --argjson warnings "$(warnings_json)" \
      --argjson includeVolumes "$include_volumes" \
      '{schemaVersion: $schemaVersion, command: "prune", ok: $ok, project: $project, rootFingerprint: $rootFingerprint, auth: $auth, portPolicy: $portPolicy, dockerAvailable: $dockerAvailable, includeVolumes: $includeVolumes, warnings: $warnings, matchedBeforePrune: {containers: $containers, volumes: $volumes, networks: $networks, generated: $generated}}'
    json_result_emitted=true
  else
    printf 'prune\towned\tok=%s\tproject=%s\troot=%s\n' "$([[ "$rc" -eq 0 ]] && printf true || printf false)" "$project_name" "$root_fingerprint"
  fi
  return "$rc"
}

cmd_self_test() {
  parse_json_args self-test "$@"
  require_root
  validate_static_env
  local command service port ext category required create_on_verify extra tmp_dir tmp_src tmp_dst
  local -A seen_commands=() seen_order=() seen_ports=()
  local -A seen_extensions=()
  [[ "$schema_version" == 2 ]] || die "unexpected Forge schema version: $schema_version"
  [[ -z "${command_handler["rasm-spike-stack"]+x}" ]] || die "retired rasm-spike-stack command is still registered"
  [[ -z "${command_handler["psql-timescale"]+x}" ]] || die "retired psql-timescale command is still registered"
  [[ -z "${command_handler["psql-search"]+x}" ]] || die "retired psql-search command is still registered"
  [[ -z "${command_handler["psql-pgduckdb"]+x}" ]] || die "retired psql-pgduckdb command is still registered"
  for command in "${!command_handler[@]}"; do
    [[ -n "${command_desc[$command]:-}" ]] || die "command missing description: $command"
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
  done
  for service in "${service_order[@]}"; do
    known_service "$service" || die "unknown service in service_order: $service"
    [[ -n "${service_image_env[$service]}" ]] || die "service missing image env: $service"
    [[ -n "${service_port_env[$service]}" ]] || die "service missing port env: $service"
    [[ -n "${service_dsn_env[$service]}" ]] || die "service missing dsn env: $service"
    [[ -n "${service_verify_handler[$service]}" ]] || die "service missing verify handler: $service"
    port="$(service_port "$service")"
    if service_enabled "$service"; then
      [[ -z "${seen_ports[$port]:-}" ]] || die "enabled service port collision: $service and ${seen_ports[$port]}"
      seen_ports[$port]="$service"
    fi
    seen_extensions=()
    while IFS=$'\t' read -r ext category required create_on_verify extra; do
      [[ -n "$ext" ]] || continue
      [[ -z "${extra:-}" ]] || die "extension catalog row has too many fields service=$service extension=$ext"
      [[ "$ext" =~ ^[A-Za-z0-9_][A-Za-z0-9_-]*$ ]] || die "invalid extension name service=$service extension=$ext"
      [[ "$category" =~ ^[a-z][a-z0-9-]*$ ]] || die "invalid extension category service=$service extension=$ext category=$category"
      [[ "$required" =~ ^[01]$ ]] || die "invalid extension required flag service=$service extension=$ext required=$required"
      [[ "$create_on_verify" =~ ^[01]$ ]] || die "invalid extension create flag service=$service extension=$ext create_on_verify=$create_on_verify"
      [[ "$required" == "$create_on_verify" ]] || die "required extensions are the only create-on-verify targets service=$service extension=$ext required=$required create_on_verify=$create_on_verify"
      [[ -z "${seen_extensions[$ext]:-}" ]] || die "duplicate extension catalog row service=$service extension=$ext"
      seen_extensions[$ext]=1
    done < <(extension_catalog_rows "$service")
    ((${#seen_extensions[@]} > 0)) || die "service missing extension catalog rows: $service"
  done
  tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/rasm-provision-self-test.XXXXXX")" || die "mktemp failed for self-test"
  tmp_src="$tmp_dir/source"
  tmp_dst="$tmp_dir/dest"
  mkdir -p "$tmp_src"
  if ! mv -T "$tmp_src" "$tmp_dst" 2>/dev/null; then
    rm -rf -- "$tmp_dir"
    die "GNU mv -T unavailable in packaged runtime"
  fi
  rm -rf -- "$tmp_dir"
  validate_rasm_root "$rasm_root"
  if [[ "$output_json" == true ]]; then
    emit_stack_json self-test true '. + {checks: {commands: true, services: true, extensions: true, root: true, gnuCoreutils: true}}'
  else
    printf 'self-test\tok\t%s\n' "$rasm_root"
  fi
}

main() {
  while (($# > 0)); do
    case "${1:-}" in
      --json)
        [[ "$output_json" == false ]] || die_usage "--json and --diagnostic-json are mutually exclusive"
        output_json=true
        shift
        ;;
      --diagnostic-json)
        [[ "$output_json" == false ]] || die_usage "--json and --diagnostic-json are mutually exclusive"
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
  if [[ -v command_mutates["$command"] ]]; then
    prevalidate_mutating_args "$command" "$@"
    with_mutation_lock "$command" "${command_handler[$command]}" "$@"
  else
    "${command_handler[$command]}" "$@"
  fi
}

main "$@"
