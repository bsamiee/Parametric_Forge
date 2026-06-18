# shellcheck shell=bash
set -Eeuo pipefail
shopt -s inherit_errexit array_expand_once nullglob

readonly schema_version=1
readonly owner_label="dev.bsamiee.rasm-provision"
readonly service_label="dev.bsamiee.rasm.service"
readonly root_label="dev.bsamiee.rasm.root"
readonly project_label="dev.bsamiee.rasm.project"
readonly resource_label="dev.bsamiee.rasm.resource"
readonly project_override="${RASM_PROVISION_PROJECT:-}"
readonly lock_wait_seconds="${RASM_PROVISION_LOCK_WAIT_SECONDS:-30}"
readonly default_colima_socket="$HOME/.local/share/colima/default/docker.sock"
host_os="$(uname -s 2>/dev/null || printf unknown)"
readonly host_os
readonly port_lock_root="${XDG_STATE_HOME:-$HOME/.local/state}/rasm-provision/port-locks"

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
  [psql-timescale]=cmd_psql_timescale
  [psql-search]=cmd_psql_search
  [psql-pgduckdb]=cmd_psql_pgduckdb
  [self-test]=cmd_self_test
)

declare -Ar command_desc=(
  [up]="Start enabled PostgreSQL provisioning services"
  [down]="Stop owned containers/networks and remove project generated files; preserve volumes"
  [status]="Show owned provisioning service status; accepts --json"
  [env]="Print derived paths and connection environment without writing files; accepts --json"
  [doctor]="Inspect Docker, Colima, paths, locks, and ports; accepts --json"
  [ports]="Report configured host ports and current listeners; accepts --json"
  [inventory]="Report owned resources, generated files, configured images, and Docker disk state; accepts --json"
  [prune]="Remove current-project owned containers, volumes, networks, and generated files with --owned; accepts --json"
  [paths]="Print derived provisioning paths"
  [plan]="Render the compose plan to stdout without writing files"
  [extensions]="Print the PostgreSQL extension target catalog; accepts --json"
  [verify]="Create and verify enabled PostgreSQL provisioning extensions; accepts --json"
  [psql-timescale]="Open psql inside the owned Timescale service"
  [psql-search]="Open psql inside the owned ParadeDB service"
  [psql-pgduckdb]="Open psql inside the owned pg_duckdb service when enabled"
  [self-test]="Validate local script metadata and configuration"
)

declare -Ar command_mutates=(
  [up]=1
  [down]=1
  [verify]=1
  [prune]=1
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
  psql-timescale
  psql-search
  psql-pgduckdb
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
  [search]="paradedb/paradedb:pg18"
  [pgduckdb]="pgduckdb/pgduckdb:18-v1.1.1"
)
declare -Ar service_port_env=(
  [timescale]="RASM_TIMESCALE_PORT"
  [search]="RASM_SEARCH_PORT"
  [pgduckdb]="RASM_PGDUCKDB_PORT"
)
declare -Ar service_port_default=(
  [timescale]=55432
  [search]=55433
  [pgduckdb]=55434
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
declare -Ar service_compose_command=(
  [timescale]=""
  [search]=""
  [pgduckdb]='["postgres", "-c", "shared_preload_libraries=pg_duckdb"]'
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
readonly extension_catalog_common_rows=$'pg_stat_statements\tobservability\t0\t0\npg_trgm\tsearch\t0\t0\nunaccent\tsearch\t0\t0\nbtree_gin\tindex\t0\t0\nbtree_gist\tindex\t0\t0\nbloom\tindex\t0\t0\nrum\tindex\t0\t0\nhypopg\tplanning\t0\t0\npg_qualstats\tobservability\t0\t0\npg_stat_kcache\tobservability\t0\t0\npg_wait_sampling\tobservability\t0\t0\npg_buffercache\tobservability\t0\t0\npg_prewarm\tperformance\t0\t0\npg_visibility\tobservability\t0\t0\npg_walinspect\tobservability\t0\t0\npg_freespacemap\tobservability\t0\t0\npg_logicalinspect\treplication\t0\t0\npgstattuple\tobservability\t0\t0\npageinspect\tobservability\t0\t0\npg_surgery\tmaintenance\t0\t0\npgrowlocks\tobservability\t0\t0\npg_overexplain\tobservability\t0\t0\namcheck\tmaintenance\t0\t0\npg_repack\tmaintenance\t0\t0\npg_partman\tpartitioning\t0\t0\npglogical\treplication\t0\t0\npg_cron\tautomation\t0\t0\npg_net\tintegration\t0\t0\npgaudit\tobservability\t0\t0\npgcrypto\tcrypto\t0\t0\ncitext\ttext\t0\t0\nltree\ttopology\t0\t0\nfuzzystrmatch\ttext\t0\t0\nintarray\tarray\t0\t0\ntablefunc\tanalytics\t0\t0\npostgres_fdw\tfdw\t0\t0\nfile_fdw\tfdw\t0\t0\nwrappers\tfdw\t0\t0\nogr_fdw\tfdw\t0\t0\npgtap\ttesting\t0\t0\nhll\tanalytics\t0\t0\nsemver\tdata\t0\t0\nunit\tdata\t0\t0\norafce\tcompatibility\t0\t0\npg_tle\textension-management\t0\t0\npg_jsonschema\tvalidation\t0\t0\npg_hashids\tidentity\t0\t0\npgmq\tqueue\t0\t0\npg_later\tautomation\t0\t0\ntsm_system_rows\tsampling\t0\t0\ntsm_system_time\tsampling\t0\t0'
declare -Ar service_extension_catalog=(
  [timescale]=$'timescaledb\ttime\t1\t1\ntimescaledb_toolkit\ttime\t0\t0\npostgis\tgeospatial\t1\t1\npostgis_topology\tgeospatial\t0\t0\npostgis_raster\tgeospatial\t0\t0\npostgis_sfcgal\tgeospatial\t0\t0\npostgis_tiger_geocoder\tgeospatial\t0\t0\naddress_standardizer\tgeospatial\t0\t0\naddress_standardizer_data_us\tgeospatial\t0\t0\npgrouting\tgeospatial\t0\t0\nh3\tgeospatial\t0\t0\nh3_postgis\tgeospatial\t0\t0\nmobilitydb\tgeospatial\t0\t0\npointcloud\tgeospatial\t0\t0\npointcloud_postgis\tgeospatial\t0\t0\nq3c\tgeospatial\t0\t0\nvector\tvector\t1\t1\nvectorscale\tvector\t1\t1\nvchord\tvector\t0\t0\npg_textsearch\tsearch\t0\t0\npgroonga\tsearch\t0\t0\npg_bigm\tsearch\t0\t0\nai\tai\t0\t0'
  [search]=$'pg_search\tsearch\t1\t1\npg_ivm\tmaterialization\t0\t0\npostgis\tgeospatial\t0\t0\npostgis_topology\tgeospatial\t0\t0\npostgis_tiger_geocoder\tgeospatial\t0\t0\npostgis_sfcgal\tgeospatial\t0\t0\npgrouting\tgeospatial\t0\t0\nh3\tgeospatial\t0\t0\nh3_postgis\tgeospatial\t0\t0\nvector\tvector\t1\t1\npgroonga\tsearch\t0\t0\npg_bigm\tsearch\t0\t0\nzhparser\tsearch\t0\t0'
  [pgduckdb]=$'pg_duckdb\tanalytics\t1\t1\nduckdb_fdw\tanalytics\t0\t0'
)

rasm_root=""
project_name=""
root_fingerprint=""
provisioning_root_dir=""
provisioning_dir=""
current_link=""
compose_file=""
env_file=""
docker_config_dir=""
lock_dir=""
lock_token=""
docker_endpoint=""
current_command=""
output_json=false
lock_owned=false
lock_releasing=false
declare -a json_warnings=()
declare -a compose_command=()
declare -a port_lock_dirs=()
unpublished_generation=""
unpublished_compose_file=""
cleanup_empty_parents_after_lock=false
cleanup_assets_on_failed_up=false

on_err() {
  local rc=$?
  local stack="${FUNCNAME[*]:-main}"
  if [[ "$output_json" == true ]]; then
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
  set +e
  jq -nc \
    --argjson schemaVersion "$schema_version" \
    --arg command "${current_command:-unknown}" \
    --arg code "$code" \
    --arg message "$message" \
    --argjson exitCode "$rc" \
    '{schemaVersion: $schemaVersion, command: $command, ok: false, error: {code: $code, message: $message, exitCode: $exitCode}}' \
    || printf 'rasm-provision: failed to emit JSON error code=%s rc=%s\n' "$code" "$rc" >&2
  set -e
}

die() {
  if [[ "$output_json" == true ]]; then
    emit_error_json "error" "$*" 1
  else
    printf 'rasm-provision: %s\n' "$*" >&2
  fi
  exit 1
}

warn() {
  if [[ "$output_json" == true ]]; then
    json_warnings+=("$*")
    return 0
  fi
  printf 'rasm-provision: warning: %s\n' "$*" >&2
}

detect_json_mode() {
  local arg
  output_json=false
  for arg in "$@"; do
    if [[ "$arg" == "--json" ]]; then
      output_json=true
      return 0
    fi
  done
}

warnings_json() {
  local warning
  for warning in "${json_warnings[@]}"; do
    jq -nc --arg message "$warning" '{message: $message}'
  done | jq -s .
}

usage() {
  local command
  printf 'Usage: rasm-provision <command> [args]\n\nCommands:\n'
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
  env_default "${service_port_env[$service]}" "${service_port_default[$service]}"
}

service_dsn() {
  local service="$1"
  printf 'postgres://postgres@127.0.0.1:%s/rasm' "$(service_port "$service")"
}

sql_quote() {
  local value="${1//\'/\'\'}"
  printf "'%s'" "$value"
}

extension_catalog_rows() {
  local service="$1"
  known_service "$service" || die "unknown service: $service"
  local catalog="${service_extension_catalog[$service]}"
  [[ -z "$catalog" ]] || printf '%s\n' "$catalog"
  printf '%s\n' "$extension_catalog_common_rows"
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

extension_catalog_json() {
  extension_catalog_tsv | jq -Rsc '
    split("\n")
    | map(select(length > 0) | split("\t"))
    | map({
        service: .[0],
        extension: .[1],
        category: .[2],
        required: (.[3] == "1"),
        createOnVerify: (.[4] == "1")
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
}

validate_project_slug() {
  local value="$1"
  [[ "$value" =~ ^[a-z0-9][a-z0-9_-]*$ ]] || die "RASM_PROVISION_PROJECT must match ^[a-z0-9][a-z0-9_-]*$: $value"
}

validate_static_env() {
  validate_lock_wait_seconds
  validate_project_slug "$project_name"

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
  fingerprint="$(printf '%s' "$rasm_root" | sha256sum)"
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
  docker_config_dir="$provisioning_dir/docker-config"
  lock_dir="$provisioning_root_dir/.locks/$project_name.lock.d"
  readonly rasm_root root_fingerprint project_name provisioning_root_dir provisioning_dir current_link compose_file env_file docker_config_dir lock_dir
}

require_root() {
  init_root
}

ensure_dir_component() {
  local path="$1"
  [[ ! -L "$path" ]] || die "refusing symlinked provisioning path component: $path"
  mkdir -p "$path"
  [[ -d "$path" && ! -L "$path" ]] || die "cannot create safe directory: $path"
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

write_lock_metadata() {
  local tmp started_at host
  host="${HOSTNAME:-unknown}"
  TZ=UTC printf -v started_at '%(%Y-%m-%dT%H:%M:%SZ)T' -1
  tmp="$(mktemp "$lock_dir/owner.XXXXXX")" || return
  {
    printf 'pid=%s\n' "$$"
    printf 'host=%s\n' "$host"
    printf 'started_at=%s\n' "$started_at"
    printf 'token=%s\n' "$lock_token"
    printf 'root=%s\n' "$rasm_root"
    printf 'project=%s\n' "$project_name"
    printf 'command=%s\n' "$current_command"
  } >"$tmp" || {
    rm -f "$tmp"
    return 1
  }
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
  local command_line
  command_line="$(ps -p "$pid" -o command= 2>/dev/null || true)"
  [[ "$command_line" == *rasm-provision* ]]
}

recover_ownerless_lock_dir() {
  local lock="$1"
  [[ -d "$lock" && ! -f "$lock/owner" ]] || return 1
  local mtime
  mtime="$(path_mtime_epoch "$lock")" || return 1
  ((EPOCHSECONDS - mtime >= lock_wait_seconds)) || return 1
  rm -f "$lock/token" "$lock"/owner.* 2>/dev/null || return 1
  rmdir "$lock" 2>/dev/null || return 1
}

try_recover_dead_lock() {
  local pid
  pid="$(lock_owner_field pid)"
  [[ -n "$pid" ]] || {
    recover_ownerless_lock_dir "$lock_dir"
    return
  }
  pid_looks_like_rasm_provision "$pid" && return 1
  rm -f "$lock_dir/token" "$lock_dir/owner" "$lock_dir"/owner.* 2>/dev/null || return 1
  rmdir "$lock_dir" 2>/dev/null || return 1
}

acquire_mutation_lock() {
  require_root
  ensure_provisioning_root
  local deadline
  ((deadline = EPOCHSECONDS + lock_wait_seconds))
  while true; do
    if mkdir "$lock_dir" 2>/dev/null; then
      lock_token="$$-${EPOCHREALTIME//[^0-9]/}-$SRANDOM"
      if ! printf '%s\n' "$lock_token" >"$lock_dir/token" || ! write_lock_metadata; then
        rm -f "$lock_dir/token" "$lock_dir/owner" "$lock_dir"/owner.* 2>/dev/null || true
        rmdir "$lock_dir" 2>/dev/null || true
        return 1
      fi
      lock_owned=true
      return 0
    fi
    try_recover_dead_lock && continue
    ((EPOCHSECONDS >= deadline)) && die "$(lock_active_message)"
    sleep 1
  done
}

release_mutation_lock() {
  local current_token rc=0
  [[ "$lock_releasing" == false ]] || return 0
  lock_releasing=true
  [[ -n "$lock_dir" && -d "$lock_dir" ]] || {
    lock_releasing=false
    return 0
  }
  cleanup_publication_artifacts || rc=1
  if [[ -n "$unpublished_compose_file" && -f "$unpublished_compose_file" ]]; then
    docker_compose_file "$unpublished_compose_file" down --remove-orphans >/dev/null 2>&1 || true
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
  current_token=""
  [[ -f "$lock_dir/token" ]] && current_token="$(<"$lock_dir/token")"
  if [[ "$lock_owned" == true && ( -z "$current_token" || "$current_token" == "$lock_token" ) ]]; then
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
  trap 'trap - INT; release_mutation_lock || true; kill -INT "$$"' INT
  trap 'trap - TERM; release_mutation_lock || true; kill -TERM "$$"' TERM
  trap 'trap - PIPE; release_mutation_lock || true; exit 141' PIPE
  acquire_mutation_lock
  "$@"
  release_mutation_lock || cleanup_rc=$?
  trap - EXIT INT TERM PIPE
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
  host="${HOSTNAME:-unknown}"
  TZ=UTC printf -v started_at '%(%Y-%m-%dT%H:%M:%SZ)T' -1
  tmp="$(mktemp "$lock/owner.XXXXXX")" || return
  {
    printf 'pid=%s\n' "$$"
    printf 'host=%s\n' "$host"
    printf 'started_at=%s\n' "$started_at"
    printf 'token=%s\n' "$lock_token"
    printf 'endpoint=%s\n' "$docker_endpoint"
    printf 'root=%s\n' "$rasm_root"
    printf 'project=%s\n' "$project_name"
    printf 'service=%s\n' "$service"
    printf 'port=%s\n' "$port"
  } >"$tmp" || {
    rm -f "$tmp"
    return 1
  }
  mv -f "$tmp" "$lock/owner"
}

recover_dead_port_lock() {
  local lock="$1"
  local pid
  pid="$(port_lock_owner_field "$lock" pid)"
  if [[ -n "$pid" ]]; then
    pid_looks_like_rasm_provision "$pid" && return 1
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
  [[ -d "$port_lock_root" && ! -L "$port_lock_root" ]] || die "cannot create safe port lock root: $port_lock_root"
  local endpoint_hash service port lock deadline pid host started_at lock_service
  endpoint_hash="$(printf '%s' "$docker_endpoint" | sha256sum)"
  endpoint_hash="${endpoint_hash%% *}"
  while IFS= read -r service; do
    port="$(service_port "$service")"
    lock="$port_lock_root/${endpoint_hash:0:16}-$port.lock.d"
    ((deadline = EPOCHSECONDS + lock_wait_seconds))
    while true; do
      if mkdir "$lock" 2>/dev/null; then
        if ! printf '%s\n' "$lock_token" >"$lock/token" || ! write_port_lock_metadata "$lock" "$service" "$port"; then
          rm -f "$lock/token" "$lock/owner" "$lock"/owner.* 2>/dev/null || true
          rmdir "$lock" 2>/dev/null || true
          return 1
        fi
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
  local lock current_token rc=0
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
  rmdir "$port_lock_root" "$HOME/.local/state/rasm-provision" 2>/dev/null || true
  return "$rc"
}

resolve_docker_endpoint() {
  local endpoint=""
  [[ -n "$docker_endpoint" ]] && return 0
  if [[ -n "${DOCKER_HOST:-}" ]]; then
    endpoint="$DOCKER_HOST"
  elif [[ -n "${DOCKER_CONTEXT:-}" ]]; then
    endpoint="$(env -u DOCKER_HOST docker context inspect "$DOCKER_CONTEXT" --format '{{ .Endpoints.docker.Host }}' 2>/dev/null)" \
      || die "cannot inspect explicit DOCKER_CONTEXT=$DOCKER_CONTEXT"
  elif [[ -S "$default_colima_socket" ]]; then
    endpoint="unix://$default_colima_socket"
  else
    endpoint="$(env -u DOCKER_HOST docker context inspect --format '{{ .Endpoints.docker.Host }}' 2>/dev/null || true)"
  fi
  [[ -n "$endpoint" ]] || endpoint="unix://$default_colima_socket"
  docker_endpoint="$endpoint"
}

docker_runtime_issue() {
  resolve_docker_endpoint
  if [[ "$docker_endpoint" == tcp://* || "$docker_endpoint" == ssh://* ]]; then
    printf 'remote Docker endpoint rejected for local provisioning; endpoint=%s' "$docker_endpoint"
    return 1
  fi
  [[ "$docker_endpoint" == unix://* ]] || {
    printf 'non-local Docker endpoint rejected: %s' "$docker_endpoint"
    return 1
  }
  if [[ "$host_os" == "Darwin" && "${RASM_PROVISION_ALLOW_NON_COLIMA_DOCKER:-0}" != "1" && "$docker_endpoint" != "unix://$default_colima_socket" ]]; then
    printf 'non-Colima Docker endpoint rejected: %s expected=unix://%s' "$docker_endpoint" "$default_colima_socket"
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
  docker info >/dev/null 2>&1 || die "docker daemon is unavailable endpoint=$docker_endpoint docker_config=${DOCKER_CONFIG:-}"
}

require_mutating_docker() {
  require_docker
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

docker_compose_file() {
  local compose="$1"
  shift
  select_compose_command
  "${compose_command[@]}" -f "$compose" --project-name "$project_name" "$@"
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
  printf 'docker-credentials\tmode=anonymous\treason=agent-local-public-images\tconfig=%s\n' "$docker_config_dir" >&2
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

render_common_labels() {
  local resource="$1"
  local service="$2"
  printf '      %s: "1"\n' "$owner_label"
  printf '      %s: %s\n' "$service_label" "$service"
  printf '      %s: "%s"\n' "$root_label" "$root_fingerprint"
  printf '      %s: "%s"\n' "$project_label" "$project_name"
  printf '      %s: %s\n' "$resource_label" "$resource"
}

render_compose_service() {
  local service="$1"
  local command="${service_compose_command[$service]}"
  printf '  %s:\n' "$service"
  printf '    image: %s\n' "$(service_image "$service")"
  [[ -z "$command" ]] || printf '    command: %s\n' "$command"
  printf '    ports:\n'
  printf '      - "127.0.0.1:%s:5432"\n' "$(service_port "$service")"
  printf '    environment:\n'
  printf '      POSTGRES_DB: rasm\n'
  printf '      POSTGRES_USER: postgres\n'
  printf '      POSTGRES_HOST_AUTH_METHOD: trust\n'
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

render_compose() {
  local service network
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
}

render_env() {
  local service
  printf 'RASM_ROOT=%s\n' "$rasm_root"
  printf 'RASM_PROVISION_PROJECT=%s\n' "$project_name"
  printf 'RASM_PROVISION_DIR=%s\n' "$provisioning_dir"
  printf 'RASM_PROVISION_COMPOSE=%s\n' "$compose_file"
  printf 'RASM_PROVISION_ENV=%s\n' "$env_file"
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
  local created_at
  TZ=UTC printf -v created_at '%(%Y-%m-%dT%H:%M:%SZ)T' -1
  jq -n \
    --argjson schemaVersion "$schema_version" \
    --arg generation "$generation_id" \
    --arg root "$rasm_root" \
    --arg project "$project_name" \
    --arg rootFingerprint "$root_fingerprint" \
    --arg createdAt "$created_at" \
    '{schemaVersion: $schemaVersion, generation: $generation, root: $root, project: $project, rootFingerprint: $rootFingerprint, createdAt: $createdAt}'
}

create_generation() {
  ensure_project_dir
  validate_static_env
  local generation_id staging generation rc
  generation_id="gen-${EPOCHREALTIME//[^0-9]/}-$SRANDOM"
  staging="$provisioning_dir/.staging-$generation_id"
  generation="$provisioning_dir/.$generation_id"
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

cleanup_publication_artifacts() {
  [[ -n "$provisioning_dir" && -d "$provisioning_dir" && ! -L "$provisioning_dir" ]] || return 0
  rm -f "$provisioning_dir/.current.next" "$docker_config_dir"/.tmp.* "$provisioning_dir"/.tmp.* 2>/dev/null || true
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
  while IFS= read -r line; do
    case "$line" in
      p*) [[ -z "$__pid" ]] && __pid="${line#p}" ;;
      c*) [[ -z "$__command" ]] && __command="${line#c}" ;;
    esac
  done < <(lsof -nP -iTCP:"$port" -sTCP:LISTEN -Fpc 2>/dev/null || true)
}

port_busy() {
  local port="$1"
  local ids=()
  collect_published_container_ids ids "$port" || die "docker port inspection failed for port=$port endpoint=$docker_endpoint"
  ((${#ids[@]} > 0)) && return 0
  lsof -nP -iTCP:"$port" -sTCP:LISTEN -t >/dev/null 2>&1
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
      [[ "$owner" == "1" && "$root" == "$root_fingerprint" && "$project" == "$project_name" && "$service_value" == "$service" ]] \
      || die "refusing to reuse volume with wrong labels: $volume"
    fi
  done < <(enabled_services)
  net="$(network_name)"
  if docker network inspect "$net" >/dev/null 2>&1; then
    owner="$(docker network inspect --format "{{ index .Labels \"$owner_label\" }}" "$net")"
    root="$(docker network inspect --format "{{ index .Labels \"$root_label\" }}" "$net")"
    project="$(docker network inspect --format "{{ index .Labels \"$project_label\" }}" "$net")"
    service_value="$(docker network inspect --format "{{ index .Labels \"$service_label\" }}" "$net")"
    name="$(docker network inspect --format '{{ .Name }}' "$net")"
    [[ "$owner" == "1" && "$root" == "$root_fingerprint" && "$project" == "$project_name" && "$service_value" == "network" && "$name" == "$net" ]] \
      || die "refusing to reuse network with wrong labels: $net"
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
  port_owned_by_service "$service" "$(service_port "$service")" \
    || die "configured port is not published by owned service service=$service port=$(service_port "$service") project=$project_name root=$root_fingerprint"
}

readiness_report() {
  local service="$1"
  local id name image state health ports
  id="$(container_id_for_service "$service")"
  if [[ -z "$id" ]]; then
    printf 'readiness\tservice=%s\tstatus=missing-container\tport=%s\tproject=%s\troot=%s\n' "$service" "$(service_port "$service")" "$project_name" "$root_fingerprint" >&2
    return 0
  fi
  name="$(inspect_name "$id" || printf '-')"
  image="$(docker inspect --format '{{ .Config.Image }}' "$id" || printf '-')"
  state="$(docker inspect --format '{{ .State.Status }}' "$id" || printf '-')"
  health="$(docker inspect --format '{{ if .State.Health }}{{ .State.Health.Status }}{{ else }}none{{ end }}' "$id" || printf '-')"
  ports="$(published_ports "$id")"
  printf 'readiness\tservice=%s\tstatus=timeout\tport=%s\tcontainer_id=%s\tname=%s\timage=%s\tdocker_status=%s\thealth=%s\tpublished=%s\n' \
    "$service" "$(service_port "$service")" "$id" "$name" "$image" "$state" "$health" "$ports" >&2
  while IFS= read -r line; do
    printf 'readiness-log\tservice=%s\t%s\n' "$service" "$line" >&2
  done < <(docker logs --tail 20 "$id" 2>&1 || true)
}

wait_service() {
  local service="$1"
  local id attempt=1
  while ((attempt <= 15)); do
    id="$(container_id_for_service "$service")"
    if [[ -n "$id" ]] && port_owned_by_service "$service" "$(service_port "$service")" \
      && docker exec "$id" pg_isready -U postgres -d rasm >/dev/null 2>&1; then
      printf '%s\tready\t%s\n' "$service" "$(service_port "$service")"
      return 0
    fi
    sleep 1
    ((attempt++))
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
  docker exec "${exec_args[@]}" "$id" psql -X -w -U postgres -d rasm "$@"
}

psql_tsv() {
  local service="$1"
  shift
  local id
  require_service_endpoint "$service"
  id="$(container_id_for_service "$service")"
  [[ -n "$id" ]] || die "missing container for service=$service"
  docker exec -i "$id" psql -X -q -w -U postgres -d rasm -v ON_ERROR_STOP=1 -A -F $'\t' -t "$@"
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
      WHEN insufficient_privilege OR feature_not_supported OR undefined_file OR undefined_object OR invalid_parameter_value THEN
        NULL;
    END;
  END LOOP;
END
\$\$;
SELECT $(sql_quote "$service"),
       t.name,
       CASE
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
  jq -nc --arg kind "$kind" --arg type "$type" --arg path "$path" --argjson exists "$exists" \
    '{kind: $kind, type: $type, path: $path, exists: $exists}'
}

generated_files_json() {
  {
    file_record_json provisioning_root directory "$provisioning_root_dir"
    file_record_json project_dir directory "$provisioning_dir"
    file_record_json current symlink "$current_link"
    file_record_json compose file "$compose_file"
    file_record_json env file "$env_file"
    file_record_json docker_config_dir directory "$docker_config_dir"
    file_record_json lock_dir directory "$lock_dir"
    if [[ -d "$provisioning_dir" && ! -L "$provisioning_dir" ]]; then
      local path
      for path in "$provisioning_dir"/.gen-* "$provisioning_dir"/.gen.* "$provisioning_dir"/.current.next "$docker_config_dir"/.tmp.*; do
        [[ -e "$path" ]] || continue
        file_record_json generated_artifact path "$path"
      done
    fi
  } | jq -s 'sort_by(.kind, .path)'
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
  docker volume inspect "${volumes[@]}" | jq -c --arg owner_label "$owner_label" --arg service_label "$service_label" --arg root_label "$root_label" --arg project_label "$project_label" '
    map({
      name: .Name,
      mountpoint: .Mountpoint,
      driver: .Driver,
      service: (.Labels[$service_label] // ""),
      owner: (.Labels[$owner_label] // ""),
      root: (.Labels[$root_label] // ""),
      project: (.Labels[$project_label] // "")
    }) | sort_by(.service, .name)
  '
}

owned_networks_json() {
  local networks=()
  collect_owned_network_names networks
  ((${#networks[@]} > 0)) || {
    printf '[]\n'
    return 0
  }
  docker network inspect "${networks[@]}" | jq -c --arg owner_label "$owner_label" --arg service_label "$service_label" --arg root_label "$root_label" --arg project_label "$project_label" '
    map({
      id: .Id,
      name: .Name,
      driver: .Driver,
      service: (.Labels[$service_label] // ""),
      owner: (.Labels[$owner_label] // ""),
      root: (.Labels[$root_label] // ""),
      project: (.Labels[$project_label] // ""),
      attachedContainers: (.Containers // {})
    }) | sort_by(.service, .name)
  '
}

service_records_tsv() {
  local service
  for service in "${service_order[@]}"; do
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$service" \
      "$(service_enabled_value "$service")" \
      "${service_profile[$service]}" \
      "$(service_image "$service")" \
      "$(service_port "$service")" \
      "$(service_dsn "$service")" \
      "${service_dsn_env[$service]}" \
      "${service_image_env[$service]}" \
      "${service_port_env[$service]}"
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
        containerPort: 5432,
        dsn: (if .[1] == "1" then .[5] else null end),
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
          containerPort,
          dsn,
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
  collect_published_container_ids ids "$port" || die "docker port inspection failed for port=$port endpoint=$docker_endpoint"
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
    --arg host_listener_command "$command" \
    'def noneish: if . == "" or . == "-" then null else . end;
    {
      service: $service,
      env: $env,
      value: ($port | tonumber),
      state: $state,
      occupied: $occupied,
      owner: $owner,
      containerId: ($container_id | noneish),
      name: ($name | noneish),
      image: ($image | noneish),
      composeProject: ($compose_project | noneish),
      composeService: ($compose_service | noneish),
      provisionProject: ($provision_project | noneish),
      hostListenerPid: ($host_listener_pid | noneish | if . == null then null else (try tonumber catch null) end),
      hostListenerCommand: ($host_listener_command | noneish)
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
    --arg state "$state" \
    --argjson occupied "$occupied" \
    --arg owner "$owner" \
    --arg host_listener_pid "$pid" \
    --arg host_listener_command "$command" \
    'def noneish: if . == "" or . == "-" then null else . end;
    {
      service: $service,
      env: $env,
      value: ($port | tonumber),
      state: $state,
      occupied: $occupied,
      owner: $owner,
      containerId: null,
      name: null,
      image: null,
      composeProject: null,
      composeService: null,
      provisionProject: null,
      hostListenerPid: ($host_listener_pid | noneish | if . == null then null else (try tonumber catch null) end),
      hostListenerCommand: ($host_listener_command | noneish)
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
        "host_listener_command=\(.hostListenerCommand // "-")"
      ]
    | join("\t")
  ' <<<"$records"
}

relevant_images_json() {
  local configured
  configured="$(configured_images_json)"
  docker image ls --format '{{json .}}' 2>/dev/null \
    | jq -s --argjson configured "$configured" '
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
  local active=false pid="" host="" started_at="" command=""
  if [[ -d "$lock_dir" ]]; then
    active=true
    pid="$(lock_owner_field pid)"
    host="$(lock_owner_field host)"
    started_at="$(lock_owner_field started_at)"
    command="$(lock_owner_field command)"
  fi
  jq -nc --argjson active "$active" --arg path "$lock_dir" --arg pid "$pid" --arg host "$host" --arg startedAt "$started_at" --arg command "$command" \
    'def empty_null: if . == "" then null else . end;
    {active: $active, path: $path, pid: ($pid | empty_null | if . == null then null else (try tonumber catch null) end), host: ($host | empty_null), startedAt: ($startedAt | empty_null), command: ($command | empty_null)}'
}

colima_json() {
  local status raw
  if command -v colima >/dev/null 2>&1; then
    if status="$(colima status --json 2>/dev/null)"; then
      jq -nc --argjson status "$status" '{available: true, status: $status, raw: null}'
    else
      raw="$(colima status 2>&1 || true)"
      jq -nc --arg raw "$raw" '{available: true, status: null, raw: $raw}'
    fi
  else
    jq -nc '{available: false, status: null, raw: null}'
  fi
}

cmd_up() {
  [[ "$#" -eq 0 ]] || die "up accepts no arguments"
  require_root
  validate_static_env
  ensure_docker_config
  cleanup_assets_on_failed_up=true
  require_mutating_docker
  assert_owned_project
  assert_owned_named_resources
  acquire_port_locks
  preflight_ports
  local generation verify_output
  generation="$(create_generation)"
  unpublished_generation="$generation"
  unpublished_compose_file="$generation/compose.yaml"
  if ! docker_compose_file "$generation/compose.yaml" up -d --remove-orphans --wait --wait-timeout 90; then
    local service
    while IFS= read -r service; do
      readiness_report "$service"
    done < <(enabled_services)
    return 1
  fi
  require_enabled_services
  wait_services
  if ! verify_output="$(verify_rows)"; then
    return 1
  fi
  if ! verify_required_rows_ok "$verify_output"; then
    printf '%s\n' "$verify_output" >&2
    die "required extension verification failed; generation was not published"
  fi
  publish_generation "$generation"
  unpublished_generation=""
  unpublished_compose_file=""
  cleanup_assets_on_failed_up=false
  cleanup_stale_generations
  printf '%s\n' "$verify_output"
}

cmd_down() {
  [[ "$#" -eq 0 ]] || die "down accepts no arguments"
  require_root
  validate_static_env
  local docker_rc=0
  if docker_ready; then
    assert_owned_project cleanup
    cleanup_runtime_docker_resources || docker_rc=$?
    cleanup_assets
    cleanup_empty_parents_after_lock=true
  else
    docker_rc=1
    warn "Docker unavailable or rejected; generated files retained for reconciliation"
  fi
  return "$docker_rc"
}

cmd_verify() {
  local json=false
  if [[ "${1:-}" == "--json" ]]; then
    [[ "$#" -eq 1 ]] || die "verify --json accepts no additional arguments"
    json=true
  else
    [[ "$#" -eq 0 ]] || die "verify accepts only --json or no arguments"
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
      --argjson extensions "$extensions_json" \
      '{schemaVersion: $schemaVersion, command: "verify", ok: $ok, project: $project, rootFingerprint: $rootFingerprint, extensions: $extensions, summary: {ok: ([ $extensions[] | select(.state == "ok") ] | length), requiredOk: ([ $extensions[] | select(.required and .state == "ok") ] | length), requiredMissing: ([ $extensions[] | select(.required and .state != "ok") ] | length), available: ([ $extensions[] | select(.state == "available") ] | length), unavailable: ([ $extensions[] | select(.state == "unavailable") ] | length), disabled: ([ $extensions[] | select(.state == "disabled") ] | length)}}'
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
  require_mutating_docker
  psql_exec "$service" "$@"
}

cmd_psql_timescale() {
  cmd_psql_service timescale "$@"
}

cmd_psql_search() {
  cmd_psql_service search "$@"
}

cmd_psql_pgduckdb() {
  cmd_psql_service pgduckdb "$@"
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
  if [[ "${1:-}" == "--json" ]]; then
    [[ "$#" -eq 1 ]] || die "status --json accepts no additional arguments"
    jq -n \
      --argjson schemaVersion "$schema_version" \
      --arg project "$project_name" \
      --arg rootFingerprint "$root_fingerprint" \
      --argjson dockerAvailable "$docker_ok" \
      --arg dockerIssue "$docker_issue" \
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
    return 0
  fi
  [[ "$#" -eq 0 ]] || die "status accepts only --json or no arguments"
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
  if [[ "${1:-}" == "--json" ]]; then
    [[ "$#" -eq 1 ]] || die "env --json accepts no additional arguments"
    jq -n \
      --argjson schemaVersion "$schema_version" \
      --arg root "$rasm_root" \
      --arg project "$project_name" \
      --arg rootFingerprint "$root_fingerprint" \
      --arg provisionRoot "$provisioning_root_dir" \
      --arg provisionDir "$provisioning_dir" \
      --arg compose "$compose_file" \
      --arg env "$env_file" \
      --arg dockerConfig "$docker_config_dir" \
      --arg ownerLabel "$owner_label" \
      --arg serviceLabel "$service_label" \
      --arg rootLabel "$root_label" \
      --arg projectLabel "$project_label" \
      --arg timescaleDsn "$(service_dsn timescale)" \
      --arg searchDsn "$(service_dsn search)" \
      --arg pgduckdbDsn "$(service_dsn pgduckdb)" \
      --arg pgduckdbEnabled "$(service_enabled_value pgduckdb)" \
      --argjson services "$(service_records_json)" \
      '{
        schemaVersion: $schemaVersion,
        command: "env",
        ok: true,
        project: $project,
        rootFingerprint: $rootFingerprint,
        paths: {
          root: $root,
          provisioningRoot: $provisionRoot,
          provisioning: $provisionDir,
          compose: $compose,
          env: $env,
          dockerConfig: $dockerConfig
        },
        labels: {owner: $ownerLabel, service: $serviceLabel, root: $rootLabel, project: $projectLabel},
        services: $services,
        RASM_ROOT: $root,
        RASM_PROVISION_PROJECT: $project,
        RASM_PROVISION_DIR: $provisionDir,
        RASM_PROVISION_COMPOSE: $compose,
        RASM_PROVISION_ENV: $env,
        RASM_TIMESCALE_DSN: $timescaleDsn,
        RASM_SEARCH_DSN: $searchDsn,
        RASM_PGDUCKDB_DSN: (if $pgduckdbEnabled == "1" then $pgduckdbDsn else null end),
        RASM_PROVISION_PGDUCKDB: $pgduckdbEnabled
      }'
    return 0
  fi
  [[ "$#" -eq 0 ]] || die "env accepts only --json or no arguments"
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
  [[ "$#" -eq 0 ]] || die "paths accepts no arguments"
  require_root
  printf 'path\tname=rasm_root\tvalue=%s\texists=%s\n' "$rasm_root" "$([[ -d "$rasm_root" ]] && printf true || printf false)"
  printf 'path\tname=provisioning_root\tvalue=%s\texists=%s\n' "$provisioning_root_dir" "$([[ -d "$provisioning_root_dir" ]] && printf true || printf false)"
  printf 'path\tname=provisioning_dir\tvalue=%s\texists=%s\tparent_writable=%s\n' "$provisioning_dir" "$([[ -d "$provisioning_dir" ]] && printf true || printf false)" "$([[ -w "$rasm_root" ]] && printf true || printf false)"
  printf 'path\tname=current\tvalue=%s\texists=%s\texpected_written_by=up\n' "$current_link" "$([[ -e "$current_link" ]] && printf true || printf false)"
  printf 'path\tname=compose\tvalue=%s\texists=%s\texpected_written_by=up\n' "$compose_file" "$([[ -f "$compose_file" ]] && printf true || printf false)"
  printf 'path\tname=env\tvalue=%s\texists=%s\texpected_written_by=up\n' "$env_file" "$([[ -f "$env_file" ]] && printf true || printf false)"
  printf 'path\tname=docker_config\tvalue=%s\texists=%s\texpected_written_by=up\n' "$docker_config_dir" "$([[ -d "$docker_config_dir" ]] && printf true || printf false)"
}

cmd_plan() {
  [[ "$#" -eq 0 ]] || die "plan accepts no arguments"
  require_root
  validate_static_env
  render_compose
}

cmd_extensions() {
  require_root
  validate_static_env
  if [[ "${1:-}" == "--json" ]]; then
    [[ "$#" -eq 1 ]] || die "extensions --json accepts no additional arguments"
    jq -n \
      --argjson schemaVersion "$schema_version" \
      --arg project "$project_name" \
      --arg rootFingerprint "$root_fingerprint" \
      --argjson services "$(service_records_json)" \
      --argjson extensions "$(extension_catalog_json)" \
      '{schemaVersion: $schemaVersion, command: "extensions", ok: true, project: $project, rootFingerprint: $rootFingerprint, services: $services, extensions: $extensions}'
    return 0
  fi
  [[ "$#" -eq 0 ]] || die "extensions accepts only --json or no arguments"
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
  if [[ "${1:-}" == "--json" ]]; then
    [[ "$#" -eq 1 ]] || die "ports --json accepts no additional arguments"
    jq -n \
      --argjson schemaVersion "$schema_version" \
      --arg project "$project_name" \
      --arg rootFingerprint "$root_fingerprint" \
      --argjson dockerAvailable "$docker_ok" \
      --arg dockerIssue "$docker_issue" \
      --argjson ports "$ports_json" \
      '{schemaVersion: $schemaVersion, command: "ports", ok: true, project: $project, rootFingerprint: $rootFingerprint, dockerAvailable: $dockerAvailable, dockerIssue: (if $dockerAvailable then null else $dockerIssue end), ports: $ports}'
    return 0
  fi
  [[ "$#" -eq 0 ]] || die "ports accepts only --json or no arguments"
  emit_ports_text "$ports_json"
}

cmd_doctor() {
  require_root
  validate_static_env
  local json=false
  if [[ "${1:-}" == "--json" ]]; then
    [[ "$#" -eq 1 ]] || die "doctor --json accepts no additional arguments"
    json=true
  else
    [[ "$#" -eq 0 ]] || die "doctor accepts only --json or no arguments"
  fi
  local docker_path="-" policy_status="ok" policy_reason="" incoming_host="${DOCKER_HOST:-}" incoming_context="${DOCKER_CONTEXT:-}"
  local host_docker_config="${DOCKER_CONFIG:-$HOME/.docker}/config.json" host_creds_store="none" host_cred_helpers="0"
  local compose_version="unavailable" docker_server="unavailable" ports_available=false ports_json="[]" anonymous_config_exists=false issue=""
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
      --arg root "$rasm_root" \
      --arg project "$project_name" \
      --arg rootFingerprint "$root_fingerprint" \
      --arg dockerPath "$docker_path" \
      --arg policyStatus "$policy_status" \
      --arg policyReason "$policy_reason" \
      --arg resolvedEndpoint "$docker_endpoint" \
      --arg incomingHost "$incoming_host" \
      --arg incomingContext "$incoming_context" \
      --arg activeHost "${DOCKER_HOST:-}" \
      --arg activeContext "${DOCKER_CONTEXT:-}" \
      --arg dockerConfig "${DOCKER_CONFIG:-$HOME/.docker}" \
      --arg hostDockerConfig "$host_docker_config" \
      --arg hostCredsStore "$host_creds_store" \
      --arg hostCredHelpers "$host_cred_helpers" \
      --arg anonymousPullConfig "$docker_config_dir/config.json" \
      --argjson anonymousConfigExists "$anonymous_config_exists" \
      --arg composeVersion "$compose_version" \
      --arg dockerServer "$docker_server" \
      --argjson portsInspectable "$ports_available" \
      --argjson ports "$ports_json" \
      --argjson lock "$(lock_json)" \
      --argjson colima "$(colima_json)" \
      '{
        schemaVersion: $schemaVersion,
        command: "doctor",
        ok: true,
        root: $root,
        project: $project,
        rootFingerprint: $rootFingerprint,
        docker: {
          path: $dockerPath,
          policy: {status: $policyStatus, reason: (if $policyReason == "" then null else $policyReason end)},
          resolvedEndpoint: $resolvedEndpoint,
          incomingHost: $incomingHost,
          incomingContext: $incomingContext,
          activeHost: $activeHost,
          activeContext: $activeContext,
          config: $dockerConfig,
          compose: $composeVersion,
          server: $dockerServer,
          hostConfig: {
            path: $hostDockerConfig,
            credsStore: $hostCredsStore,
            credHelpers: (try ($hostCredHelpers | tonumber) catch null),
            warning: (if $hostCredsStore != "none" or $hostCredHelpers != "0" then "credential-helper-present-for-host-config" else null end)
          },
          anonymousPullConfig: {path: $anonymousPullConfig, exists: $anonymousConfigExists}
        },
        portsInspectable: $portsInspectable,
        portsUsable: ($portsInspectable and all($ports[]; .state == "disabled" or .owner == "none" or .owner == "provision:this-project")),
        blockedPorts: [$ports[] | select(.state != "disabled" and .owner != "none" and .owner != "provision:this-project")],
        ports: $ports,
        lock: $lock,
        colima: $colima
      }'
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
  if [[ "${1:-}" == "--json" ]]; then
    [[ "$#" -eq 1 ]] || die "inventory --json accepts no additional arguments"
    json=true
  else
    [[ "$#" -eq 0 ]] || die "inventory accepts only --json or no arguments"
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
      --arg root "$rasm_root" \
      --arg project "$project_name" \
      --arg rootFingerprint "$root_fingerprint" \
      --arg ownerLabel "$owner_label" \
      --arg serviceLabel "$service_label" \
      --arg rootLabel "$root_label" \
      --arg projectLabel "$project_label" \
      --argjson dockerAvailable "$docker_ok" \
      --argjson services "$(service_records_json)" \
      --argjson containers "$containers_json" \
      --argjson volumes "$volumes_json" \
      --argjson networks "$networks_json" \
      --argjson generated "$(generated_files_json)" \
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
        root: $root,
        project: $project,
        rootFingerprint: $rootFingerprint,
        labels: {owner: $ownerLabel, service: $serviceLabel, root: $rootLabel, project: $projectLabel},
        dockerAvailable: $dockerAvailable,
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
  require_root
  validate_static_env
  local json=false
  if [[ "${1:-}" == "--owned" && "${2:-}" == "--json" && "$#" -eq 2 ]]; then
    json=true
  elif [[ "${1:-}" == "--json" && "${2:-}" == "--owned" && "$#" -eq 2 ]]; then
    json=true
  elif [[ "${1:-}" == "--owned" && "$#" -eq 1 ]]; then
    json=false
  else
    die "prune requires --owned and accepts optional --json"
  fi
  local docker_ok=false before_containers="[]" before_volumes="[]" before_networks="[]" before_generated rc=0
  before_generated="$(generated_files_json)"
  if docker_ready; then
    docker_ok=true
    assert_owned_project cleanup
    before_containers="$(owned_containers_json)"
    before_volumes="$(owned_volumes_json)"
    before_networks="$(owned_networks_json)"
    cleanup_owned_docker_resources || rc=$?
    cleanup_assets
    cleanup_empty_parents_after_lock=true
  else
    rc=1
    warn "Docker unavailable or rejected; generated files retained for reconciliation"
  fi
  if [[ "$json" == true ]]; then
    jq -n \
      --argjson schemaVersion "$schema_version" \
      --arg project "$project_name" \
      --arg rootFingerprint "$root_fingerprint" \
      --argjson ok "$([[ "$rc" -eq 0 ]] && printf true || printf false)" \
      --argjson dockerAvailable "$docker_ok" \
      --argjson containers "$before_containers" \
      --argjson volumes "$before_volumes" \
      --argjson networks "$before_networks" \
      --argjson generated "$before_generated" \
      --argjson warnings "$(warnings_json)" \
      '{schemaVersion: $schemaVersion, command: "prune", ok: $ok, project: $project, rootFingerprint: $rootFingerprint, dockerAvailable: $dockerAvailable, warnings: $warnings, matchedBeforePrune: {containers: $containers, volumes: $volumes, networks: $networks, generated: $generated}}'
  else
    printf 'prune\towned\tok=%s\tproject=%s\troot=%s\n' "$([[ "$rc" -eq 0 ]] && printf true || printf false)" "$project_name" "$root_fingerprint"
  fi
  return "$rc"
}

cmd_self_test() {
  [[ "$#" -eq 0 ]] || die "self-test accepts no arguments"
  require_root
  validate_static_env
  local command service port ext category required create_on_verify extra
  local -A seen_commands=() seen_order=() seen_ports=()
  local -A seen_extensions=()
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
  validate_rasm_root "$rasm_root"
  printf 'self-test\tok\t%s\n' "$rasm_root"
}

main() {
  local command="${1:-}"
  shift || true
  current_command="$command"
  detect_json_mode "$@"
  case "$command" in
    help | --help | -h | "")
      usage
      return 0
      ;;
    --self-test)
      command="self-test"
      ;;
  esac
  [[ -v command_handler["$command"] ]] || {
    usage >&2
    die "unknown command: $command"
  }
  current_command="$command"
  if [[ -v command_mutates["$command"] ]]; then
    with_mutation_lock "$command" "${command_handler[$command]}" "$@"
  else
    "${command_handler[$command]}" "$@"
  fi
}

main "$@"
