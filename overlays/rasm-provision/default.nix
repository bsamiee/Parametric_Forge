# Title         : rasm-provision/default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : overlays/rasm-provision/default.nix
# ----------------------------------------------------------------------------
# Rasm local provisioning command.
{
  coreutils,
  docker-client,
  docker-compose,
  gawk,
  gnugrep,
  gnused,
  jq,
  lib,
  lsof,
  postgresql_18,
  writeShellApplication,
}:
writeShellApplication {
  name = "rasm-provision";
  runtimeInputs = [
    coreutils
    docker-client
    docker-compose
    gawk
    gnugrep
    gnused
    jq
    lsof
    postgresql_18
  ];
  bashOptions = ["errexit" "errtrace" "nounset" "pipefail"];
  meta = {
    description = "Local Rasm PostgreSQL provisioning command";
    mainProgram = "rasm-provision";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
  text = ''
    shopt -s inherit_errexit

    readonly owner_label="dev.bsamiee.rasm-provision"
    readonly service_label="dev.bsamiee.rasm.service"
    readonly root_label="dev.bsamiee.rasm.root"
    readonly project_override="''${RASM_PROVISION_PROJECT:-}"
    readonly timescale_image="''${RASM_TIMESCALE_IMAGE:-timescale/timescaledb-ha:pg18.4-ts2.27.2-all}"
    readonly paradedb_image="''${RASM_PARADEDB_IMAGE:-paradedb/paradedb:pg18}"
    readonly pgduckdb_image="''${RASM_PGDUCKDB_IMAGE:-pgduckdb/pgduckdb:18-v1.1.1}"
    readonly timescale_port="''${RASM_TIMESCALE_PORT:-55432}"
    readonly search_port="''${RASM_SEARCH_PORT:-55433}"
    readonly pgduckdb_port="''${RASM_PGDUCKDB_PORT:-55434}"
    readonly pgduckdb_enabled="''${RASM_PROVISION_PGDUCKDB:-0}"
    readonly commands=$'up\tStart Timescale and ParadeDB provisioning services\ndown\tStop owned services and remove script-owned data/status files\nstatus\tShow owned provisioning service status without writing files\nenv\tPrint derived paths and connection environment without writing files\ndoctor\tInspect Docker, Colima, paths, and ports\nports\tReport configured host ports and current listeners\npaths\tPrint derived provisioning paths\nplan\tRender the compose plan to stdout without writing files\nverify\tVerify owned PostgreSQL provisioning extensions only\npsql-timescale\tOpen psql against the owned Timescale service\npsql-search\tOpen psql against the owned ParadeDB service\nself-test\tValidate local script configuration'
    declare -Ar command_handlers=(
      [up]=cmd_up
      [down]=cmd_down
      [status]=cmd_status
      [env]=cmd_env
      [doctor]=cmd_doctor
      [ports]=cmd_ports
      [paths]=cmd_paths
      [plan]=cmd_plan
      [verify]=cmd_verify
      [psql-timescale]=cmd_psql_timescale
      [psql-search]=cmd_psql_search
      [self-test]=cmd_self_test
    )
    declare -Ar mutating_commands=(
      [up]=1
      [down]=1
      [verify]=1
    )

    rasm_root=""
    project_name=""
    provisioning_dir=""
    data_dir=""
    env_file=""
    compose_file=""
    docker_config_dir=""
    root_fingerprint=""
    docker_endpoint=""
    lock_dir=""

    on_err() {
      local rc=$?
      if [[ "''${RASM_PROVISION_DEBUG:-0}" == "1" ]]; then
        printf 'rasm-provision: error: command failed rc=%s line=%s command=%s\n' "$rc" "''${BASH_LINENO[0]:-?}" "$BASH_COMMAND" >&2
      else
        printf 'rasm-provision: error: command failed rc=%s line=%s\n' "$rc" "''${BASH_LINENO[0]:-?}" >&2
      fi
      exit "$rc"
    }
    trap on_err ERR

    die() {
      printf 'rasm-provision: %s\n' "$*" >&2
      exit 1
    }

    list_commands() {
      printf '%s\n' "$commands"
    }

    usage() {
      local command description
      printf 'Usage: rasm-provision <command> [args]\n\n'
      printf 'Commands:\n'
      while IFS=$'\t' read -r command description; do
        [ -n "$command" ] || continue
        printf '  %-18s %s\n' "$command" "$description"
      done <<< "$commands"
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
    }

    find_rasm_root() {
      local candidate
      if [[ -n "''${RASM_ROOT:-}" ]]; then
        candidate="$RASM_ROOT"
        [[ -d "$candidate" ]] || die "RASM_ROOT is not a directory: $candidate"
        candidate="$(cd "$candidate" && pwd -P)" || die "cannot resolve RASM_ROOT: $candidate"
        printf '%s\n' "$candidate"
        return
      fi

      candidate="$PWD"
      while [[ "$candidate" != "/" ]]; do
        if [[ -f "$candidate/pyproject.toml" && -f "$candidate/Directory.Packages.props" && -d "$candidate/libs/csharp" ]]; then
          printf '%s\n' "$candidate"
          return
        fi
        candidate="$(dirname "$candidate")"
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
      rasm_root="$(find_rasm_root)"
      validate_rasm_root "$rasm_root"
      provisioning_dir="$rasm_root/.artifacts/provisioning/rasm"
      data_dir="$provisioning_dir/data"
      env_file="$provisioning_dir/.env"
      compose_file="$provisioning_dir/compose.yaml"
      docker_config_dir="$provisioning_dir/docker-config"
      fingerprint="$(printf '%s' "$rasm_root" | sha256sum)"
      root_fingerprint="''${fingerprint%% *}"
      if [[ -n "$project_override" ]]; then
        project_name="$project_override"
      else
        project_name="rasm-provision-''${root_fingerprint:0:12}"
      fi
      lock_dir="''${TMPDIR:-/tmp}/rasm-provision-locks/$root_fingerprint.lock.d"
      readonly rasm_root project_name provisioning_dir data_dir env_file compose_file docker_config_dir root_fingerprint lock_dir
    }

    require_root() {
      init_root
    }

    with_mutation_lock() {
      require_root
      mkdir -p "$(dirname "$lock_dir")"
      if ! mkdir "$lock_dir" 2>/dev/null; then
        recover_or_report_lock
      fi
      write_lock_metadata
      trap 'rc=$?; release_mutation_lock; exit "$rc"' EXIT
      "$@"
      local rc=$?
      release_mutation_lock
      trap - EXIT
      return "$rc"
    }

    write_lock_metadata() {
      {
        printf 'pid=%s\n' "$$"
        printf 'host=%s\n' "$(hostname 2>/dev/null || printf unknown)"
        printf 'started_at=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        printf 'root=%s\n' "$rasm_root"
        printf 'project=%s\n' "$project_name"
      } >"$lock_dir/owner"
    }

    lock_owner_field() {
      local key="$1"
      awk -F= -v key="$key" '$1 == key { print substr($0, length(key) + 2); exit }' "$lock_dir/owner" 2>/dev/null || true
    }

    recover_or_report_lock() {
      local pid host started_at
      pid="$(lock_owner_field pid)"
      host="$(lock_owner_field host)"
      started_at="$(lock_owner_field started_at)"
      if [[ -z "$pid" && ! -e "$lock_dir/owner" ]]; then
        sleep 0.2
        pid="$(lock_owner_field pid)"
        if [[ -z "$pid" && ! -e "$lock_dir/owner" ]] && rmdir "$lock_dir" 2>/dev/null; then
          if mkdir "$lock_dir" 2>/dev/null; then
            return 0
          fi
        fi
      fi
      if [[ -n "$pid" ]] && ! kill -0 "$pid" 2>/dev/null; then
        rm -rf "$lock_dir"
        if mkdir "$lock_dir" 2>/dev/null; then
          return 0
        fi
      fi
      die "another rasm-provision mutating command is active: lock=$lock_dir pid=''${pid:-unknown} host=''${host:-unknown} started_at=''${started_at:-unknown}"
    }

    release_mutation_lock() {
      [[ -n "$lock_dir" ]] || return 0
      case "$lock_dir" in
        "''${TMPDIR:-/tmp}"/rasm-provision-locks/*.lock.d) rm -rf "$lock_dir" ;;
        /tmp/rasm-provision-locks/*.lock.d) rm -rf "$lock_dir" ;;
        *) rmdir "$lock_dir" 2>/dev/null || true ;;
      esac
    }

    docker_runtime_issue() {
      local host
      resolve_docker_endpoint
      host="$docker_endpoint"
      if [[ "''${RASM_PROVISION_ALLOW_REMOTE_DOCKER:-0}" == "1" ]]; then
        return 0
      fi
      if [[ "$host" == tcp://* || "$host" == ssh://* ]]; then
        printf 'remote Docker endpoint rejected; set RASM_PROVISION_ALLOW_REMOTE_DOCKER=1 to override'
        return 1
      fi
      [[ "$host" == unix://* ]] || {
        printf 'non-local Docker endpoint rejected: %s' "$host"
        return 1
      }
      return 0
    }

    validate_static_env() {
      validate_port RASM_TIMESCALE_PORT "$timescale_port"
      validate_port RASM_SEARCH_PORT "$search_port"
      validate_port RASM_PGDUCKDB_PORT "$pgduckdb_port"
      [[ "$timescale_port" != "$search_port" ]] || die "RASM_TIMESCALE_PORT and RASM_SEARCH_PORT must be distinct: $timescale_port"
      [[ "$timescale_port" != "$pgduckdb_port" ]] || die "RASM_TIMESCALE_PORT and RASM_PGDUCKDB_PORT must be distinct: $timescale_port"
      [[ "$search_port" != "$pgduckdb_port" ]] || die "RASM_SEARCH_PORT and RASM_PGDUCKDB_PORT must be distinct: $search_port"
      validate_image RASM_TIMESCALE_IMAGE "$timescale_image"
      validate_image RASM_PARADEDB_IMAGE "$paradedb_image"
      validate_image RASM_PGDUCKDB_IMAGE "$pgduckdb_image"
      [[ "$project_name" =~ ^[a-z0-9][a-z0-9_-]*$ ]] || die "RASM_PROVISION_PROJECT must match ^[a-z0-9][a-z0-9_-]*$: $project_name"
      [[ "$pgduckdb_enabled" == "0" || "$pgduckdb_enabled" == "1" ]] || die "RASM_PROVISION_PGDUCKDB must be 0 or 1"
    }

    docker_compose_file() {
      local compose="$1"
      shift
      docker compose version >/dev/null 2>&1 || die "docker compose v2 is unavailable"
      docker compose -f "$compose" --project-name "$project_name" "$@"
    }

    docker_compose() {
      docker_compose_file "$compose_file" "$@"
    }

    ensure_docker_config() {
      require_root
      mkdir -p "$docker_config_dir"
      atomic_render "$docker_config_dir/config.json" render_empty_json
      export DOCKER_CONFIG="$docker_config_dir"
      printf 'docker-credentials\tmode=anonymous\treason=agent-local-public-images\tconfig=%s\n' "$docker_config_dir" >&2
    }

    render_empty_json() {
      printf '{}\n'
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
      printf '%s\n' "''${name#/}"
    }

    owned_service_running() {
      local service="$1"
      local ids
      require_root
      ids="$(docker ps -q \
        --filter "label=com.docker.compose.project=$project_name" \
        --filter "label=$owner_label=1" \
        --filter "label=$service_label=$service" \
        --filter "label=$root_label=$root_fingerprint")"
      [[ -n "$ids" ]]
    }

    port_owned_by_service() {
      local service="$1"
      local port="$2"
      local ids id owned service_label_value root compose_project
      collect_published_container_ids ids "$port"
      ((''${#ids[@]} > 0)) || return 1
      for id in "''${ids[@]}"; do
        owned="$(inspect_label "$id" "$owner_label")"
        service_label_value="$(inspect_label "$id" "$service_label")"
        root="$(inspect_label "$id" "$root_label")"
        compose_project="$(inspect_label "$id" "com.docker.compose.project")"
        [[ "$owned" == "1" && "$service_label_value" == "$service" && "$root" == "$root_fingerprint" && "$compose_project" == "$project_name" ]] && return 0
      done
      return 1
    }

    containers_publishing_host_port() {
      local port="$1"
      local ids_raw
      local ids=()
      ids_raw="$(docker ps -q)" || return
      [[ -z "$ids_raw" ]] || mapfile -t ids <<< "$ids_raw"
      ((''${#ids[@]} > 0)) || return 0
      docker inspect "''${ids[@]}" \
        | jq -r --arg port "$port" '
          .[]
          | select(
              [ .NetworkSettings.Ports[]?[]?
                | select(.HostPort == $port and (.HostIp == "127.0.0.1" or .HostIp == "::1" or .HostIp == "0.0.0.0" or .HostIp == "::" or .HostIp == ""))
              ] | length > 0
            )
          | .Id
        '
    }

    collect_published_container_ids() {
      # shellcheck disable=SC2178  # nameref binds the caller's array by name.
      local -n _out="$1"
      local port="$2"
      local raw
      _out=()
      raw="$(containers_publishing_host_port "$port")" || return
      [[ -z "$raw" ]] || mapfile -t _out <<< "$raw"
    }

    collect_owned_container_ids() {
      # shellcheck disable=SC2178  # nameref binds the caller's array by name.
      local -n _out="$1"
      local raw
      _out=()
      raw="$(docker ps -aq \
        --filter "label=com.docker.compose.project=$project_name" \
        --filter "label=$owner_label=1" \
        --filter "label=$root_label=$root_fingerprint")" || return
      [[ -z "$raw" ]] || mapfile -t _out <<< "$raw"
    }

    collect_owned_volume_names() {
      # shellcheck disable=SC2178  # nameref binds the caller's array by name.
      local -n _out="$1"
      local raw
      _out=()
      raw="$(docker volume ls -q \
        --filter "label=$owner_label=1" \
        --filter "label=$root_label=$root_fingerprint")" || return
      [[ -z "$raw" ]] || mapfile -t _out <<< "$raw"
    }

    collect_owned_network_names() {
      # shellcheck disable=SC2178  # nameref binds the caller's array by name.
      local -n _out="$1"
      local raw
      _out=()
      raw="$(docker network ls -q \
        --filter "label=$owner_label=1" \
        --filter "label=$root_label=$root_fingerprint")" || return
      [[ -z "$raw" ]] || mapfile -t _out <<< "$raw"
    }

    known_service() {
      case "$1" in
        timescale | search | pgduckdb | network) return 0 ;;
        *) return 1 ;;
      esac
    }

    volume_prefix() {
      printf 'rasm-provision-%s' "''${root_fingerprint:0:12}"
    }

    network_name() {
      printf '%s-net' "$(volume_prefix)"
    }

    classify_owner() {
      local id="$1"
      local compose_project="$2"
      local provision_owner="$3"
      local provision_root="$4"
      if [[ "$provision_owner" == "1" && "$provision_root" == "$root_fingerprint" ]]; then
        printf 'provision:this-root'
      elif [[ "$provision_owner" == "1" && -n "$provision_root" && "$provision_root" != "$root_fingerprint" ]]; then
        printf 'provision:other-root'
      elif [[ "$provision_owner" == "1" ]]; then
        printf 'provision:unknown-root'
      elif [[ "$compose_project" == "$project_name" ]]; then
        printf 'project:unowned'
      elif [[ -n "$id" ]]; then
        printf 'external:docker'
      else
        printf 'external:host-listener'
      fi
    }

    host_listener_field() {
      local port="$1"
      local field="$2"
      lsof -nP -iTCP:"$port" -sTCP:LISTEN -F pc 2>/dev/null \
        | awk -v field="$field" '
            field == "pid" && /^p/ { print substr($0, 2); exit }
            field == "command" && /^c/ { print substr($0, 2); exit }
          ' \
        || true
    }

    port_collision_report() {
      local service="$1"
      local env_var="$2"
      local port="$3"
      local container_port="$4"
      local id="-"
      local ids=()
      collect_published_container_ids ids "$port"
      ((''${#ids[@]} == 0)) || id="''${ids[0]}"

      local name="-" image="-" status="-" published="-" compose_project="-" compose_service="-" provision_owner="-" provision_service="-" provision_root="-"
      if [[ "$id" != "-" ]]; then
        name="$(inspect_name "$id" || printf '-')"
        image="$(docker inspect --format '{{ .Config.Image }}' "$id" || printf '-')"
        status="$(docker inspect --format '{{ .State.Status }}' "$id" || printf '-')"
        published="$(docker port "$id" | tr '\n' ',' | sed 's/,$//' || printf '-')"
        compose_project="$(inspect_label "$id" "com.docker.compose.project")"
        compose_service="$(inspect_label "$id" "com.docker.compose.service")"
        provision_owner="$(inspect_label "$id" "$owner_label")"
        provision_service="$(inspect_label "$id" "$service_label")"
        provision_root="$(inspect_label "$id" "$root_label")"
        [[ -n "$compose_project" ]] || compose_project="-"
        [[ -n "$compose_service" ]] || compose_service="-"
        [[ -n "$provision_owner" ]] || provision_owner="-"
        [[ -n "$provision_service" ]] || provision_service="-"
        [[ -n "$provision_root" ]] || provision_root="-"
      fi

      local owner pid command action
      owner="$(classify_owner "$id" "$compose_project" "$provision_owner" "$provision_root")"
      pid="$(host_listener_field "$port" pid)"
      command="$(host_listener_field "$port" command)"
      [[ -n "$pid" ]] || pid="-"
      [[ -n "$command" ]] || command="-"
      action="set $env_var to a free port or stop the non-owned listener outside rasm-provision"

      if [[ "''${RASM_PROVISION_DEBUG:-0}" == "1" ]]; then
        printf 'port-collision\tservice=%s\tenv=%s\thost=127.0.0.1\trequested=%s\tcontainer_port=%s\towner=%s\tcontainer_id=%s\tname=%s\timage=%s\tstatus=%s\tpublished=%s\tcompose_project=%s\tcompose_service=%s\tprovision_owner_label=%s\tprovision_service_label=%s\tprovision_root_label=%s\tcurrent_root_label=%s\thost_listener_pid=%s\thost_listener_command=%s\taction=%s\n' \
          "$service" "$env_var" "$port" "$container_port" "$owner" "$id" "$name" "$image" "$status" "$published" "$compose_project" "$compose_service" "$provision_owner" "$provision_service" "$provision_root" "$root_fingerprint" "$pid" "$command" "$action" >&2
      else
        printf 'port-collision\tservice=%s\tenv=%s\tport=%s\towner=%s\tcontainer_id=%s\tname=%s\timage=%s\tcompose_project=%s\tcompose_service=%s\thost_listener_pid=%s\thost_listener_command=%s\taction=%s\n' \
          "$service" "$env_var" "$port" "$owner" "$id" "$name" "$image" "$compose_project" "$compose_service" "$pid" "$command" "$action" >&2
      fi
    }

    preflight_service_port() {
      local service="$1"
      local env_var="$2"
      local port="$3"
      local container_port="$4"
      if ! port_busy "$port"; then
        return 0
      fi
      if port_owned_by_service "$service" "$port"; then
        return 0
      fi
      port_collision_report "$service" "$env_var" "$port" "$container_port"
      return 1
    }

    cleanup_assets() {
      case "$data_dir" in
        "$provisioning_dir"/data) rm -rf "$data_dir" ;;
        *) die "refusing to remove unexpected data dir: $data_dir" ;;
      esac

      case "$env_file" in
        "$provisioning_dir"/.env) rm -f "$env_file" ;;
        *) die "refusing to remove unexpected env file: $env_file" ;;
      esac

      case "$compose_file" in
        "$provisioning_dir"/compose.yaml) rm -f "$compose_file" ;;
        *) die "refusing to remove unexpected compose file: $compose_file" ;;
      esac

      case "$docker_config_dir" in
        "$provisioning_dir"/docker-config) rm -rf "$docker_config_dir" ;;
        *) die "refusing to remove unexpected docker config dir: $docker_config_dir" ;;
      esac

      rmdir "$provisioning_dir" "$rasm_root/.artifacts/provisioning" 2>/dev/null || true
    }

    remove_owned_containers() {
      local ids=()
      collect_owned_container_ids ids
      ((''${#ids[@]} > 0)) || return 0
      docker rm -f "''${ids[@]}" >/dev/null
    }

    remove_owned_volumes() {
      local volumes=()
      local volume service
      collect_owned_volume_names volumes
      ((''${#volumes[@]} > 0)) || return 0
      for volume in "''${volumes[@]}"; do
        service="$(docker volume inspect --format "{{ index .Labels \"$service_label\" }}" "$volume")" || return
        known_service "$service" || die "refusing to remove unexpected owned volume service=$service name=$volume"
        [[ "$service" != "network" ]] || die "refusing to remove network-labelled volume: $volume"
        docker volume rm "$volume" >/dev/null || return
      done
    }

    remove_owned_networks() {
      local networks=()
      local network service
      collect_owned_network_names networks
      ((''${#networks[@]} > 0)) || return 0
      for network in "''${networks[@]}"; do
        service="$(docker network inspect --format "{{ index .Labels \"$service_label\" }}" "$network")" || return
        [[ "$service" == "network" ]] || die "refusing to remove unexpected owned network service=$service name=$network"
        docker network rm "$network" >/dev/null || return
      done
    }

    cleanup_owned_docker_resources() {
      remove_owned_containers
      remove_owned_volumes
      remove_owned_networks
    }

    assert_owned_named_resources() {
      local prefix net volume service volume_root volume_owner volume_service
      prefix="$(volume_prefix)"
      for service in timescale search pgduckdb; do
        volume="$prefix-$service-data"
        if docker volume inspect "$volume" >/dev/null 2>&1; then
          volume_owner="$(docker volume inspect --format "{{ index .Labels \"$owner_label\" }}" "$volume")" || return
          volume_root="$(docker volume inspect --format "{{ index .Labels \"$root_label\" }}" "$volume")" || return
          volume_service="$(docker volume inspect --format "{{ index .Labels \"$service_label\" }}" "$volume")" || return
          [[ "$volume_owner" == "1" && "$volume_root" == "$root_fingerprint" && "$volume_service" == "$service" ]] \
            || die "refusing to reuse volume with wrong labels: $volume"
        fi
      done
      net="$(network_name)"
      if docker network inspect "$net" >/dev/null 2>&1; then
        volume_owner="$(docker network inspect --format "{{ index .Labels \"$owner_label\" }}" "$net")" || return
        volume_root="$(docker network inspect --format "{{ index .Labels \"$root_label\" }}" "$net")" || return
        volume_service="$(docker network inspect --format "{{ index .Labels \"$service_label\" }}" "$net")" || return
        [[ "$volume_owner" == "1" && "$volume_root" == "$root_fingerprint" && "$volume_service" == "network" ]] \
          || die "refusing to reuse network with wrong labels: $net"
      fi
    }

    require_owned_services() {
      owned_service_running timescale || die "owned timescale service is not running for project=$project_name root=$root_fingerprint"
      owned_service_running search || die "owned search service is not running for project=$project_name root=$root_fingerprint"
      if [[ "$pgduckdb_enabled" == "1" ]]; then
        owned_service_running pgduckdb || die "owned pgduckdb service is not running for project=$project_name root=$root_fingerprint"
      fi
    }

    require_docker() {
      command -v docker >/dev/null 2>&1 || die "docker is unavailable"
      reject_remote_docker
      export DOCKER_HOST="$docker_endpoint"
      unset DOCKER_CONTEXT
      docker info >/dev/null 2>&1 || die "docker daemon is unavailable endpoint=$docker_endpoint docker_config=''${DOCKER_CONFIG:-}"
    }

    resolve_docker_endpoint() {
      local endpoint=""
      [[ -n "$docker_endpoint" ]] && return 0
      if [[ -n "''${DOCKER_CONTEXT:-}" ]]; then
        endpoint="$(docker context inspect "$DOCKER_CONTEXT" --format '{{ .Endpoints.docker.Host }}' 2>/dev/null || true)"
      elif [[ -n "''${DOCKER_HOST:-}" ]]; then
        endpoint="$DOCKER_HOST"
      else
        endpoint="$(docker context inspect --format '{{ .Endpoints.docker.Host }}' 2>/dev/null || true)"
      fi
      if [[ -z "$endpoint" ]]; then
        endpoint="unix://''${COLIMA_HOME:-$HOME/.local/share/colima}/default/docker.sock"
      fi
      docker_endpoint="$endpoint"
    }

    reject_remote_docker() {
      local issue
      resolve_docker_endpoint
      if ! issue="$(docker_runtime_issue)"; then
        die "$issue"
      fi
    }

    prepare_docker_for_pull() {
      ensure_docker_config
    }

    port_busy() {
      local port="$1"
      local ids=()
      collect_published_container_ids ids "$port" || die "docker port inspection failed for port=$port endpoint=$docker_endpoint"
      if ((''${#ids[@]} > 0)); then
        return 0
      fi
      if lsof -nP -iTCP:"$port" -sTCP:LISTEN -Fp 2>/dev/null | grep -q '^p'; then
        return 0
      fi
      return 1
    }

    preflight_ports() {
      local failed=0
      preflight_service_port timescale RASM_TIMESCALE_PORT "$timescale_port" 5432 || failed=1
      preflight_service_port search RASM_SEARCH_PORT "$search_port" 5432 || failed=1
      if [[ "$pgduckdb_enabled" == "1" ]]; then
        preflight_service_port pgduckdb RASM_PGDUCKDB_PORT "$pgduckdb_port" 5432 || failed=1
      fi
      ((failed == 0)) || die "host port(s) already allocated; see port-collision row(s) above"
    }

    atomic_render() {
      local target="$1"
      local renderer="$2"
      local dir tmp old_umask rc
      dir="$(dirname "$target")" || return
      mkdir -p "$dir" || return
      old_umask="$(umask)" || return
      umask 077 || return
      tmp="$(mktemp "$dir/.tmp.XXXXXX")" || {
        rc=$?
        umask "$old_umask" || true
        return "$rc"
      }
      umask "$old_umask" || {
        rc=$?
        rm -f "$tmp"
        return "$rc"
      }
      "$renderer" > "$tmp" || {
        rc=$?
        rm -f "$tmp"
        return "$rc"
      }
      if chmod 600 "$tmp" && mv "$tmp" "$target"; then
        return 0
      fi
      {
        rc=$?
        rm -f "$tmp"
        return "$rc"
      }
    }

    render_env() {
      cat <<EOF
    RASM_ROOT=$rasm_root
    RASM_PROVISION_PROJECT=$project_name
    RASM_TIMESCALE_IMAGE=$timescale_image
    RASM_PARADEDB_IMAGE=$paradedb_image
    RASM_PGDUCKDB_IMAGE=$pgduckdb_image
    RASM_TIMESCALE_PORT=$timescale_port
    RASM_SEARCH_PORT=$search_port
    RASM_PGDUCKDB_PORT=$pgduckdb_port
    RASM_PROVISION_PGDUCKDB=$pgduckdb_enabled
    EOF
    }

    render_compose() {
      local volume_prefix network
      volume_prefix="$(volume_prefix)"
      network="$(network_name)"
      cat <<EOF
    name: $project_name
    services:
      timescale:
        image: $timescale_image
        ports:
          - "127.0.0.1:$timescale_port:5432"
        environment:
          POSTGRES_DB: rasm
          POSTGRES_USER: postgres
          POSTGRES_HOST_AUTH_METHOD: trust
        volumes:
          - timescale-data:/home/postgres/pgdata/data
        networks:
          - provision-net
        user: "0:0"
        labels:
          $owner_label: "1"
          $service_label: timescale
          $root_label: "$root_fingerprint"
        healthcheck:
          test: ["CMD-SHELL", "pg_isready -U postgres -d rasm"]
          interval: 5s
          timeout: 5s
          start_period: 10s
          start_interval: 2s
          retries: 30

      search:
        image: $paradedb_image
        ports:
          - "127.0.0.1:$search_port:5432"
        environment:
          POSTGRES_DB: rasm
          POSTGRES_USER: postgres
          POSTGRES_HOST_AUTH_METHOD: trust
        volumes:
          - search-data:/var/lib/postgresql
        networks:
          - provision-net
        user: "0:0"
        labels:
          $owner_label: "1"
          $service_label: search
          $root_label: "$root_fingerprint"
        healthcheck:
          test: ["CMD-SHELL", "pg_isready -U postgres -d rasm"]
          interval: 5s
          timeout: 5s
          start_period: 10s
          start_interval: 2s
          retries: 30
    EOF

      if [[ "$pgduckdb_enabled" == "1" ]]; then
        cat <<EOF

      pgduckdb:
        image: $pgduckdb_image
        command: ["postgres", "-c", "shared_preload_libraries=pg_duckdb"]
        ports:
          - "127.0.0.1:$pgduckdb_port:5432"
        environment:
          POSTGRES_DB: rasm
          POSTGRES_USER: postgres
          POSTGRES_HOST_AUTH_METHOD: trust
        volumes:
          - pgduckdb-data:/var/lib/postgresql
        networks:
          - provision-net
        user: "0:0"
        labels:
          $owner_label: "1"
          $service_label: pgduckdb
          $root_label: "$root_fingerprint"
        healthcheck:
          test: ["CMD-SHELL", "pg_isready -U postgres -d rasm"]
          interval: 5s
          timeout: 5s
          start_period: 10s
          start_interval: 2s
          retries: 30
    EOF
      fi

      cat <<EOF

    volumes:
      timescale-data:
        name: "$volume_prefix-timescale-data"
        labels:
          $owner_label: "1"
          $service_label: timescale
          $root_label: "$root_fingerprint"
      search-data:
        name: "$volume_prefix-search-data"
        labels:
          $owner_label: "1"
          $service_label: search
          $root_label: "$root_fingerprint"
    EOF

      if [[ "$pgduckdb_enabled" == "1" ]]; then
        cat <<EOF
      pgduckdb-data:
        name: "$volume_prefix-pgduckdb-data"
        labels:
          $owner_label: "1"
          $service_label: pgduckdb
          $root_label: "$root_fingerprint"
    EOF
      fi

      cat <<EOF

    networks:
      provision-net:
        name: "$network"
        labels:
          $owner_label: "1"
          $service_label: network
          $root_label: "$root_fingerprint"
    EOF
    }

    write_assets() {
      require_root
      validate_static_env
      local staging
      mkdir -p "$provisioning_dir"
      staging="$(mktemp -d "$provisioning_dir/.staging.XXXXXX")"
      if atomic_render "$staging/.env" render_env \
        && atomic_render "$staging/compose.yaml" render_compose \
        && docker_compose_file "$staging/compose.yaml" config >/dev/null \
        && mv "$staging/compose.yaml" "$compose_file" \
        && mv "$staging/.env" "$env_file" \
        && rmdir "$staging"; then
        return 0
      fi
      rm -rf "$staging"
      return 1
    }

    container_id_for_service() {
      local service="$1"
      docker ps -aq \
        --filter "label=com.docker.compose.project=$project_name" \
        --filter "label=$owner_label=1" \
        --filter "label=$service_label=$service" \
        --filter "label=$root_label=$root_fingerprint" \
        | head -n 1
    }

    readiness_report() {
      local service="$1"
      local port="$2"
      local id name image state health published
      id="$(container_id_for_service "$service")"
      if [[ -z "$id" ]]; then
        printf 'readiness\tservice=%s\tstatus=missing-container\tport=%s\tproject=%s\troot=%s\n' "$service" "$port" "$project_name" "$root_fingerprint" >&2
        return 0
      fi
      name="$(inspect_name "$id" || printf '-')"
      image="$(docker inspect --format '{{ .Config.Image }}' "$id" || printf '-')"
      state="$(docker inspect --format '{{ .State.Status }}' "$id" || printf '-')"
      health="$(docker inspect --format '{{ if .State.Health }}{{ .State.Health.Status }}{{ else }}none{{ end }}' "$id" || printf '-')"
      published="$(docker port "$id" | tr '\n' ',' | sed 's/,$//' || printf '-')"
      printf 'readiness\tservice=%s\tstatus=timeout\tport=%s\tcontainer_id=%s\tname=%s\timage=%s\tdocker_status=%s\thealth=%s\tpublished=%s\n' \
        "$service" "$port" "$id" "$name" "$image" "$state" "$health" "$published" >&2
      docker logs --tail 20 "$id" 2>&1 | sed "s/^/readiness-log\tservice=$service\t/" >&2 || true
    }

    wait_port() {
      local service="$1"
      local port="$2"
      local attempt=1
      while ((attempt <= 90)); do
        if port_owned_by_service "$service" "$port" && pg_isready -h 127.0.0.1 -p "$port" -U postgres -d rasm >/dev/null 2>&1; then
          printf '%s\tready\t%s\n' "$service" "$port"
          return 0
        fi
        sleep 1
        ((attempt++))
      done
      readiness_report "$service" "$port"
      die "$service did not become ready on port $port"
    }

    wait_services() {
      wait_port timescale "$timescale_port"
      wait_port search "$search_port"
      if [[ "$pgduckdb_enabled" == "1" ]]; then
        wait_port pgduckdb "$pgduckdb_port"
      fi
    }

    require_service_endpoint() {
      local service="$1"
      local port="$2"
      port_owned_by_service "$service" "$port" \
        || die "configured port is not published by owned service service=$service port=$port project=$project_name root=$root_fingerprint"
    }

    psql_service() {
      local service="$1"
      shift
      local port="$1"
      shift
      require_service_endpoint "$service" "$port"
      psql -h 127.0.0.1 -p "$port" -U postgres -d rasm "$@"
    }

    psql_tsv() {
      local service="$1"
      shift
      local port="$1"
      shift
      require_service_endpoint "$service" "$port"
      psql -h 127.0.0.1 -p "$port" -U postgres -d rasm -X -v ON_ERROR_STOP=1 -A -F $'\t' -t "$@"
    }

    verify_timescale() {
      psql_tsv timescale "$timescale_port" <<'SQL'
    CREATE EXTENSION IF NOT EXISTS timescaledb;
    CREATE EXTENSION IF NOT EXISTS postgis;
    CREATE EXTENSION IF NOT EXISTS vector;
    DO $$
    BEGIN
      CREATE EXTENSION IF NOT EXISTS vectorscale;
    EXCEPTION
      WHEN undefined_file OR feature_not_supported OR insufficient_privilege THEN
        NULL;
    END $$;
    SELECT 'timescale', 'timescaledb', CASE WHEN e.extname IS NULL THEN 'missing' ELSE 'ok' END, COALESCE(e.extversion, '-') FROM (VALUES (1)) seed(id) LEFT JOIN pg_extension e ON e.extname = 'timescaledb'
    UNION ALL
    SELECT 'timescale', 'postgis', CASE WHEN e.extname IS NULL THEN 'missing' ELSE 'ok' END, COALESCE(e.extversion, '-') FROM (VALUES (1)) seed(id) LEFT JOIN pg_extension e ON e.extname = 'postgis'
    UNION ALL
    SELECT 'timescale', 'vector', CASE WHEN e.extname IS NULL THEN 'missing' ELSE 'ok' END, COALESCE(e.extversion, '-') FROM (VALUES (1)) seed(id) LEFT JOIN pg_extension e ON e.extname = 'vector'
    UNION ALL
    SELECT 'timescale', 'vectorscale', CASE WHEN e.extname IS NULL THEN 'unavailable:not-in-image' ELSE 'ok' END, COALESCE(e.extversion, '-') FROM (VALUES (1)) seed(id) LEFT JOIN pg_extension e ON e.extname = 'vectorscale'
    UNION ALL
    SELECT 'timescale', 'pg_duckdb', 'unavailable:not-in-default-image', '-';
    SQL
    }

    verify_search() {
      psql_tsv search "$search_port" <<'SQL'
    CREATE EXTENSION IF NOT EXISTS pg_search;
    CREATE EXTENSION IF NOT EXISTS vector;
    SELECT 'search', 'pg_search', CASE WHEN e.extname IS NULL THEN 'missing' ELSE 'ok' END, COALESCE(e.extversion, '-') FROM (VALUES (1)) seed(id) LEFT JOIN pg_extension e ON e.extname = 'pg_search'
    UNION ALL
    SELECT 'search', 'vector', CASE WHEN e.extname IS NULL THEN 'missing' ELSE 'ok' END, COALESCE(e.extversion, '-') FROM (VALUES (1)) seed(id) LEFT JOIN pg_extension e ON e.extname = 'vector'
    UNION ALL
    SELECT 'search', 'pg_duckdb', 'unavailable:not-in-default-image', '-';
    SQL
    }

    verify_pgduckdb() {
      if [[ "$pgduckdb_enabled" != "1" ]]; then
        printf 'pgduckdb\tpg_duckdb\tunavailable:not-in-default-image\t-\n'
        return 0
      fi

      psql_tsv pgduckdb "$pgduckdb_port" <<'SQL'
    CREATE EXTENSION IF NOT EXISTS pg_duckdb;
    SELECT 'pgduckdb', 'pg_duckdb', CASE WHEN e.extname IS NULL THEN 'missing' ELSE 'ok' END, COALESCE(e.extversion, '-') FROM (VALUES (1)) seed(id) LEFT JOIN pg_extension e ON e.extname = 'pg_duckdb';
    SQL
    }

    assert_owned_project() {
      local ids
      ids="$(docker ps -aq --filter "label=com.docker.compose.project=$project_name")"
      [[ -n "$ids" ]] || return 0

      local id
      while IFS= read -r id; do
        [[ -n "$id" ]] || continue
        local owned root
        owned="$(docker inspect --format "{{ index .Config.Labels \"$owner_label\" }}" "$id" 2>/dev/null || true)"
        [[ "$owned" == "1" ]] || die "refusing to manage unlabeled container in project $project_name: $id"
        root="$(docker inspect --format "{{ index .Config.Labels \"$root_label\" }}" "$id" 2>/dev/null || true)"
        [[ "$root" == "$root_fingerprint" ]] || die "refusing to manage container from another Rasm root in project $project_name: $id root=$root"
      done <<< "$ids"
    }

    cmd_up() {
      require_docker
      require_root
      validate_static_env
      assert_owned_project
      assert_owned_named_resources
      preflight_ports
      write_assets
      prepare_docker_for_pull
      if ! docker_compose up -d --wait --wait-timeout 90; then
        readiness_report timescale "$timescale_port"
        readiness_report search "$search_port"
        if [[ "$pgduckdb_enabled" == "1" ]]; then
          readiness_report pgduckdb "$pgduckdb_port"
        fi
        return 1
      fi
      wait_services
      cmd_verify
    }

    cmd_down() {
      require_root
      validate_static_env
      require_docker
      assert_owned_project
      cleanup_owned_docker_resources
      cleanup_assets
    }

    cmd_status() {
      require_root
      require_docker
      local ids=()
      local id service name image state health ports
      collect_owned_container_ids ids
      if ((''${#ids[@]} == 0)); then
        printf 'status\tstate=empty\tproject=%s\troot=%s\n' "$project_name" "$root_fingerprint"
        cmd_ports
        return 0
      fi
      for id in "''${ids[@]}"; do
        service="$(inspect_label "$id" "$service_label")"
        name="$(inspect_name "$id" || printf '-')"
        image="$(docker inspect --format '{{ .Config.Image }}' "$id" || printf '-')"
        state="$(docker inspect --format '{{ .State.Status }}' "$id" || printf '-')"
        health="$(docker inspect --format '{{ if .State.Health }}{{ .State.Health.Status }}{{ else }}none{{ end }}' "$id" || printf '-')"
        ports="$(docker port "$id" | tr '\n' ',' | sed 's/,$//' || printf '-')"
        printf 'status\tservice=%s\tcontainer_id=%s\tname=%s\timage=%s\tdocker_status=%s\thealth=%s\tports=%s\tproject=%s\troot=%s\n' \
          "$service" "$id" "$name" "$image" "$state" "$health" "$ports" "$project_name" "$root_fingerprint"
      done
      cmd_ports
    }

    cmd_env() {
      require_root
      validate_static_env
      if [[ "''${1:-}" == "--json" ]]; then
        [[ "$#" -eq 1 ]] || die "env --json accepts no additional arguments"
        jq -n \
          --arg schema_version "1" \
          --arg root "$rasm_root" \
          --arg project "$project_name" \
          --arg root_fingerprint "$root_fingerprint" \
          --arg provision_dir "$provisioning_dir" \
          --arg data_dir "$data_dir" \
          --arg compose "$compose_file" \
          --arg env "$env_file" \
          --arg docker_config "$docker_config_dir" \
          --arg owner_label "$owner_label" \
          --arg service_label "$service_label" \
          --arg root_label "$root_label" \
          --arg timescale_image "$timescale_image" \
          --arg search_image "$paradedb_image" \
          --arg pgduckdb_image "$pgduckdb_image" \
          --arg timescale_port "$timescale_port" \
          --arg search_port "$search_port" \
          --arg pgduckdb_port "$pgduckdb_port" \
          --arg timescale_dsn "postgres://postgres@127.0.0.1:$timescale_port/rasm" \
          --arg search_dsn "postgres://postgres@127.0.0.1:$search_port/rasm" \
          --arg pgduckdb_dsn "postgres://postgres@127.0.0.1:$pgduckdb_port/rasm" \
          --arg pgduckdb "$pgduckdb_enabled" \
          '{
            schemaVersion: ($schema_version | tonumber),
            project: $project,
            rootFingerprint: $root_fingerprint,
            paths: {
              root: $root,
              provisioning: $provision_dir,
              data: $data_dir,
              compose: $compose,
              env: $env,
              dockerConfig: $docker_config
            },
            labels: {
              owner: $owner_label,
              service: $service_label,
              root: $root_label
            },
            services: {
              timescale: {
                enabled: true,
                image: $timescale_image,
                host: "127.0.0.1",
                port: ($timescale_port | tonumber),
                containerPort: 5432,
                dsn: $timescale_dsn,
                composeService: "timescale",
                profile: "timescale"
              },
              search: {
                enabled: true,
                image: $search_image,
                host: "127.0.0.1",
                port: ($search_port | tonumber),
                containerPort: 5432,
                dsn: $search_dsn,
                composeService: "search",
                profile: "pg_search"
              },
              pgduckdb: {
                enabled: ($pgduckdb == "1"),
                connectable: ($pgduckdb == "1"),
                image: $pgduckdb_image,
                host: "127.0.0.1",
                port: ($pgduckdb_port | tonumber),
                containerPort: 5432,
                dsn: (if $pgduckdb == "1" then $pgduckdb_dsn else null end),
                composeService: "pgduckdb",
                profile: "analytics-probe"
              }
            },
            RASM_ROOT: $root,
            RASM_PROVISION_PROJECT: $project,
            RASM_PROVISION_DIR: $provision_dir,
            RASM_PROVISION_COMPOSE: $compose,
            RASM_PROVISION_ENV: $env,
            RASM_TIMESCALE_DSN: $timescale_dsn,
            RASM_SEARCH_DSN: $search_dsn,
            RASM_PGDUCKDB_DSN: $pgduckdb_dsn,
            RASM_PROVISION_PGDUCKDB: $pgduckdb
          }'
        return 0
      fi
      [[ "$#" -eq 0 ]] || die "env accepts only --json or no arguments"
      printf 'export RASM_ROOT=%q\n' "$rasm_root"
      printf 'export RASM_PROVISION_PROJECT=%q\n' "$project_name"
      printf 'export RASM_PROVISION_DIR=%q\n' "$provisioning_dir"
      printf 'export RASM_PROVISION_COMPOSE=%q\n' "$compose_file"
      printf 'export RASM_PROVISION_ENV=%q\n' "$env_file"
      printf 'export RASM_TIMESCALE_DSN=%q\n' "postgres://postgres@127.0.0.1:$timescale_port/rasm"
      printf 'export RASM_SEARCH_DSN=%q\n' "postgres://postgres@127.0.0.1:$search_port/rasm"
      printf 'export RASM_PGDUCKDB_DSN=%q\n' "postgres://postgres@127.0.0.1:$pgduckdb_port/rasm"
      printf 'export RASM_PROVISION_PGDUCKDB=%q\n' "$pgduckdb_enabled"
    }

    cmd_verify() {
      require_root
      validate_static_env
      require_docker
      assert_owned_project
      require_owned_services
      wait_services
      verify_timescale
      verify_search
      verify_pgduckdb
    }

    cmd_psql_timescale() {
      require_root
      validate_static_env
      require_docker
      require_owned_services
      psql_service timescale "$timescale_port" "$@"
    }

    cmd_psql_search() {
      require_root
      validate_static_env
      require_docker
      require_owned_services
      psql_service search "$search_port" "$@"
    }

    cmd_self_test() {
      require_root
      validate_static_env
      local seen=" "
      local command description
      while IFS=$'\t' read -r command description; do
        [[ -n "$command" ]] || die "empty command metadata row"
        [[ -n "$description" ]] || die "empty description for $command"
        [[ "$seen" != *" $command "* ]] || die "duplicate command metadata row: $command"
        seen+="$command "
      done <<< "$(list_commands)"
      validate_rasm_root "$rasm_root"
      printf 'self-test\tok\t%s\n' "$rasm_root"
    }

    cmd_paths() {
      require_root
      printf 'path\tname=rasm_root\tvalue=%s\texists=%s\n' "$rasm_root" "$([[ -d "$rasm_root" ]] && printf true || printf false)"
      printf 'path\tname=provisioning_dir\tvalue=%s\texists=%s\tparent_writable=%s\n' "$provisioning_dir" "$([[ -d "$provisioning_dir" ]] && printf true || printf false)" "$([[ -w "$rasm_root" ]] && printf true || printf false)"
      printf 'path\tname=compose\tvalue=%s\texists=%s\texpected_written_by=up\n' "$compose_file" "$([[ -f "$compose_file" ]] && printf true || printf false)"
      printf 'path\tname=env\tvalue=%s\texists=%s\texpected_written_by=up\n' "$env_file" "$([[ -f "$env_file" ]] && printf true || printf false)"
      printf 'path\tname=docker_config\tvalue=%s\texists=%s\texpected_written_by=up\n' "$docker_config_dir" "$([[ -d "$docker_config_dir" ]] && printf true || printf false)"
    }

    cmd_plan() {
      require_root
      validate_static_env
      render_compose
    }

    cmd_ports() {
      require_root
      validate_static_env
      require_docker
      local service env_var port state occupied ids id owner name image compose_project compose_service pid command
      for row in \
        "timescale RASM_TIMESCALE_PORT $timescale_port" \
        "search RASM_SEARCH_PORT $search_port" \
        "pgduckdb RASM_PGDUCKDB_PORT $pgduckdb_port"; do
        read -r service env_var port <<< "$row"
        ids=()
        collect_published_container_ids ids "$port" || die "docker port inspection failed for port=$port endpoint=$docker_endpoint"
        pid="$(host_listener_field "$port" pid)"
        command="$(host_listener_field "$port" command)"
        [[ -n "$pid" ]] || pid="-"
        [[ -n "$command" ]] || command="-"
        if [[ "$service" == "pgduckdb" && "$pgduckdb_enabled" != "1" ]]; then
          occupied=false
          ((''${#ids[@]} > 0)) || [[ "$pid" != "-" ]] && occupied=true
          if ((''${#ids[@]} > 0)); then
            id="''${ids[0]}"
            name="$(inspect_name "$id" || printf '-')"
            image="$(docker inspect --format '{{ .Config.Image }}' "$id" || printf '-')"
            compose_project="$(inspect_label "$id" "com.docker.compose.project")"
            compose_service="$(inspect_label "$id" "com.docker.compose.service")"
            owner="$(classify_owner "$id" "$compose_project" "$(inspect_label "$id" "$owner_label")" "$(inspect_label "$id" "$root_label")")"
            printf 'port\tservice=%s\tenv=%s\tvalue=%s\tstate=disabled\toccupied=%s\towner=%s\tcontainer_id=%s\tname=%s\timage=%s\tcompose_project=%s\tcompose_service=%s\thost_listener_pid=%s\thost_listener_command=%s\n' \
              "$service" "$env_var" "$port" "$occupied" "$owner" "$id" "$name" "$image" "''${compose_project:--}" "''${compose_service:--}" "$pid" "$command"
          elif [[ "$pid" != "-" ]]; then
            printf 'port\tservice=%s\tenv=%s\tvalue=%s\tstate=disabled\toccupied=%s\towner=external:host-listener\tcontainer_id=-\tname=-\timage=-\tcompose_project=-\tcompose_service=-\thost_listener_pid=%s\thost_listener_command=%s\n' \
              "$service" "$env_var" "$port" "$occupied" "$pid" "$command"
          else
            printf 'port\tservice=%s\tenv=%s\tvalue=%s\tstate=disabled\toccupied=%s\towner=none\tcontainer_id=-\tname=-\timage=-\tcompose_project=-\tcompose_service=-\thost_listener_pid=-\thost_listener_command=-\n' \
              "$service" "$env_var" "$port" "$occupied"
          fi
          continue
        fi
        if ((''${#ids[@]} > 0)); then
          id="''${ids[0]}"
          name="$(inspect_name "$id" || printf '-')"
          image="$(docker inspect --format '{{ .Config.Image }}' "$id" || printf '-')"
          compose_project="$(inspect_label "$id" "com.docker.compose.project")"
          compose_service="$(inspect_label "$id" "com.docker.compose.service")"
          owner="$(classify_owner "$id" "$compose_project" "$(inspect_label "$id" "$owner_label")" "$(inspect_label "$id" "$root_label")")"
          state=busy
          printf 'port\tservice=%s\tenv=%s\tvalue=%s\tstate=%s\toccupied=true\towner=%s\tcontainer_id=%s\tname=%s\timage=%s\tcompose_project=%s\tcompose_service=%s\thost_listener_pid=%s\thost_listener_command=%s\n' \
            "$service" "$env_var" "$port" "$state" "$owner" "$id" "$name" "$image" "''${compose_project:--}" "''${compose_service:--}" "$pid" "$command"
        elif [[ "$pid" != "-" ]]; then
          printf 'port\tservice=%s\tenv=%s\tvalue=%s\tstate=busy\toccupied=true\towner=external:host-listener\tcontainer_id=-\tname=-\timage=-\tcompose_project=-\tcompose_service=-\thost_listener_pid=%s\thost_listener_command=%s\n' \
            "$service" "$env_var" "$port" "$pid" "$command"
        else
          printf 'port\tservice=%s\tenv=%s\tvalue=%s\tstate=free\toccupied=false\towner=none\tcontainer_id=-\tname=-\timage=-\tcompose_project=-\tcompose_service=-\thost_listener_pid=-\thost_listener_command=-\n' "$service" "$env_var" "$port"
        fi
      done
    }

    cmd_doctor() {
      require_root
      validate_static_env
      local docker_path="-"
      local policy="ok"
      local policy_issue=""
      local socket="-"
      local host_docker_config="''${DOCKER_CONFIG:-$HOME/.docker}/config.json"
      local host_creds_store="none"
      local host_cred_helpers="0"
      resolve_docker_endpoint
      if ! policy_issue="$(docker_runtime_issue)"; then
        policy="$policy_issue"
      fi
      if [[ -f "$host_docker_config" ]]; then
        host_creds_store="$(jq -r '.credsStore // .credStore // "none"' "$host_docker_config" 2>/dev/null || printf 'unreadable')"
        host_cred_helpers="$(jq -r '(.credHelpers // {}) | length' "$host_docker_config" 2>/dev/null || printf 'unreadable')"
      fi
      docker_path="$(command -v docker || printf '-')"
      socket="$(docker context inspect --format '{{ .Endpoints.docker.Host }}' 2>/dev/null || printf '-')"
      printf 'doctor\tcommand=rasm-provision\n'
      printf 'doctor\trasm_root=%s\n' "$rasm_root"
      printf 'doctor\tproject=%s\n' "$project_name"
      printf 'doctor\troot_fingerprint=%s\n' "$root_fingerprint"
      printf 'doctor\tdocker=%s\n' "$docker_path"
      printf 'doctor\tdocker_policy=%s\n' "$policy"
      printf 'doctor\tresolved_endpoint=%s\n' "$docker_endpoint"
      printf 'doctor\tdocker_host=%s\n' "''${DOCKER_HOST:-}"
      printf 'doctor\tdocker_context=%s\n' "''${DOCKER_CONTEXT:-}"
      printf 'doctor\tdocker_socket=%s\n' "$socket"
      printf 'doctor\tdocker_config=%s\n' "''${DOCKER_CONFIG:-$docker_config_dir}"
      printf 'doctor\thost_docker_config=%s\n' "$host_docker_config"
      printf 'doctor\thost_docker_config_credsStore=%s\n' "$host_creds_store"
      printf 'doctor\thost_docker_config_credHelpers=%s\n' "$host_cred_helpers"
      printf 'doctor\tanonymous_pull_config=%s\texists=%s\n' "$docker_config_dir/config.json" "$([[ -f "$docker_config_dir/config.json" ]] && printf true || printf false)"
      docker compose version --short 2>/dev/null | awk '{ printf "doctor\tdocker_compose=%s\n", $0 }' || printf 'doctor\tdocker_compose=unavailable\n'
      docker info --format 'doctor	docker_server={{.ServerVersion}}' 2>/dev/null || printf 'doctor\tdocker_server=unavailable\n'
      if [[ "$policy" == "ok" ]] && docker info >/dev/null 2>&1; then
        cmd_ports
      else
        printf 'doctor\tports=skipped\treason=docker-unavailable-or-policy-failed\n'
      fi
      if command -v colima >/dev/null 2>&1; then
        local colima_output
        colima_output="$(colima status 2>&1 || true)"
        if [[ -n "$colima_output" ]]; then
          awk '{ print "doctor\tcolima=" $0 }' <<< "$colima_output"
        else
          printf 'doctor\tcolima=empty-or-unavailable\n'
        fi
      else
        printf 'doctor\tcolima=not-on-path\n'
      fi
    }

    main() {
      local command="''${1:-}"
      shift || true
      case "$command" in
        help | --help | -h | "") usage; return 0 ;;
        --self-test) command="self-test" ;;
      esac

      [[ -v command_handlers["$command"] ]] || {
        usage >&2
        die "unknown command: $command"
      }

      if [[ -v mutating_commands["$command"] ]]; then
        with_mutation_lock "''${command_handlers[$command]}" "$@"
      else
        "''${command_handlers[$command]}" "$@"
      fi
    }

    main "$@"
  '';
}
