# shellcheck shell=bash
inspect_label() {
  local id="$1"
  local label="$2"
  local value
  value="$(docker inspect --format "{{ with index .Config.Labels \"$label\" }}{{ . }}{{ end }}" "$id" 2>/dev/null || true)"
  [[ "$value" == "<no value>" ]] && value=""
  printf '%s\n' "$value"
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
  if ! known_service "$service"; then
    [[ "$mode" == "cleanup" ]] || die "refusing unknown provision container service=$service id=$id"
    service=""
  fi
  owned="$(inspect_label "$id" "$owner_label")"
  root="$(inspect_label "$id" "$root_label")"
  project="$(inspect_label "$id" "$project_label")"
  compose_project="$(inspect_label "$id" "com.docker.compose.project")"
  compose_service="$(inspect_label "$id" "com.docker.compose.service")"
  [[ "$owned" == "1" ]] || die "refusing unowned container id=$id"
  [[ "$root" == "$root_key" ]] || die "refusing container from another Rasm root id=$id root=$root"
  [[ "$project" == "$project_name" ]] || die "refusing container from another provision project id=$id provision_project=$project"
  [[ "$compose_project" == "$project_name" ]] || die "refusing container from another Compose project id=$id compose_project=$compose_project"
  [[ -z "$service" || "$compose_service" == "$service" ]] || die "refusing container with wrong Compose service id=$id service=$compose_service expected=$service"
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
    --filter "label=$root_label=$root_key" \
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
    --filter "label=$root_label=$root_key" \
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
    --filter "label=$root_label=$root_key" \
    --filter "label=$project_label=$project_name")" || return
  [[ -z "$raw" ]] || mapfile -t _out <<<"$raw"
}

active_other_project_count() {
  local raw
  local ids=()
  raw="$(docker ps -q \
    --filter "label=$owner_label=1" \
    --filter "label=$root_label=$root_key")" || return
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
    --filter "label=$root_label=$root_key" \
    --filter "label=$project_label=$project_name")" || return
  printf '%s\n' "${raw%%$'\n'*}"
}

container_running_for_service() {
  local service="$1"
  [[ -n "$(docker ps -q \
    --filter "label=com.docker.compose.project=$project_name" \
    --filter "label=$owner_label=1" \
    --filter "label=$service_label=$service" \
    --filter "label=$root_label=$root_key" \
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
    [[ "$owned" == "1" && "$root" == "$root_key" && "$project" == "$project_name" && "$service_value" == "$service" && "$compose_project" == "$project_name" ]] || continue
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
  if [[ "$provision_owner" == "1" && "$provision_root" == "$root_key" && "$provision_project" == "$project_name" ]]; then
    printf 'provision:this-project'
  elif [[ "$provision_owner" == "1" && "$provision_root" == "$root_key" ]]; then
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
  stderr_line "$(printf 'port-collision\tservice=%s\tenv=%s\tport=%s\towner=%s\taction=%s' \
    "$service" "$env_var" "$port" "$owner" "set $env_var to a free port or stop the non-owned listener outside forge-provision")"
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
    [[ "$root" == "$root_key" ]] || die "refusing to manage container from another Rasm root in project $project_name: $id root=$root"
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
      [[ "$owner" == "1" && "$root" == "$root_key" && "$project" == "$project_name" && "$service_value" == "$service" ]] ||
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
    [[ "$owner" == "1" && "$root" == "$root_key" && "$project" == "$project_name" && "$service_value" == "network" && "$name" == "$net" ]] ||
      die "refusing to reuse network with wrong labels: $net"
  fi
}

require_enabled_service_running() {
  local service="$1"
  local id
  container_running_for_service "$service" || die "owned service is not running service=$service project=$project_name root=$root_key"
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
    die "configured port is not published by owned service service=$service port=$(service_port "$service") project=$project_name root=$root_key"
}

readiness_report() {
  local service="$1"
  local id name image state health ports
  id="$(container_id_for_service "$service")"
  if [[ -z "$id" ]]; then
    stderr_line "$(printf 'readiness\tservice=%s\tstatus=missing-container\tport=%s\tproject=%s\troot=%s' "$service" "$(service_port "$service")" "$project_name" "$root_key")"
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
      docker exec "$id" pg_isready -U postgres -d forge >/dev/null 2>&1; then
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
      sh "/run/secrets/$(auth_secret_name "$service")" -X -w -U postgres -d forge "$@"
  else
    run_foreground_child docker exec "${exec_args[@]}" "$id" psql -X -w -U postgres -d forge "$@"
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
      sh "/run/secrets/$(auth_secret_name "$service")" -X -q -w -U postgres -d forge -v ON_ERROR_STOP=1 -A -F $'\t' -t "$@"
  else
    docker exec -i "$id" psql -X -q -w -U postgres -d forge -v ON_ERROR_STOP=1 -A -F $'\t' -t "$@"
  fi
}

service_extension_sql() {
  local service="$1"
  local sql_file="$2"
  local values sql
  values="$(extension_sql_values "$service")"
  [[ -n "$values" ]] || return 0
  sql="$(<"$(catalog_path "sql/$sql_file")")"
  sql="${sql//__FORGE_EXTENSION_VALUES__/$values}"
  sql="${sql//__FORGE_CONTEXT_SQL__/$(sql_quote "$root_key:$project_key:$instance_name")}"
  sql="${sql//__FORGE_SERVICE_SQL__/$(sql_quote "$service")}"
  psql_tsv "$service" <<<"$sql"
}

check_service_extensions() {
  service_extension_sql "$1" check-postgres.sql
}

apply_service_extensions() {
  service_extension_sql "$1" apply-postgres.sql
}

check_rows() {
  local service
  for service in "${service_order[@]}"; do
    if service_enabled "$service"; then
      check_service_extensions "$service"
    else
      disabled_service_apply_rows "$service"
    fi
  done
  return 0
}

apply_rows() {
  local service handler
  for service in "${service_order[@]}"; do
    if service_enabled "$service"; then
      handler="${service_apply_handler[$service]}"
      "$handler" "$service"
    else
      disabled_service_apply_rows "$service"
    fi
  done
  return 0
}

apply_required_rows_ok() {
  local rows="$1"
  local service state version category required
  while IFS=$'\t' read -r service _extension state version category required; do
    [[ -n "$service" ]] || continue
    [[ "$required" == "required" && "$state" != "ok" ]] && return 1
  done <<<"$rows"
  return 0
}

apply_rows_json() {
  jq -Rsc -f "$(catalog_path jq/apply-rows.jq)"
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
    [[ "$root" == "$root_key" && "$project" == "$project_name" ]] || die "refusing to remove volume outside current root/project name=$volume root=$root project=$project"
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
    [[ "$root" == "$root_key" && "$project" == "$project_name" ]] || die "refusing to remove network outside current root/project name=$network root=$root project=$project"
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
    jq -nc --arg kind "$kind" --arg type "$type" --argjson exists "$exists" \
      '{kind: $kind, type: $type, exists: $exists, pathRedacted: true}'
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
  jq -nc --argjson generated "$(generated_files_json)" '{generated: $generated, plan: null}'
}

empty_resources_json() {
  jq -nc '{counts: {}, owned: {containers: [], volumes: [], networks: []}, images: [], dockerDisk: [], runtime: {}}'
}

extension_envelope_json() {
  local catalog="${1:-[]}"
  local results="${2:-[]}"
  local summary="${3:-{}}"
  jq -nc --argjson catalog "$catalog" --argjson results "$results" --argjson summary "$summary" \
    '{catalog: $catalog, results: $results, summary: $summary}'
}

tools_envelope_json() {
  local surfaces="${1:-{}}"
  local summary="${2:-{}}"
  jq -nc --argjson surfaces "$surfaces" --argjson summary "$summary" '{surfaces: $surfaces, summary: $summary}'
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
    } + if $diagnostic then {mountpointRedacted: true} else {} end) | sort_by(.service, .name)
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
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$service" \
      "${service_role[$service]}" \
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
  service_records_tsv | jq -Rsc -f "$(catalog_path jq/service-records.jq)"
}

configured_images_json() {
  service_records_tsv | jq -Rsc -f "$(catalog_path jq/configured-images.jq)"
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
  if [[ "$owner" != "provision:this-project" ]]; then
    id="-"
    name="-"
    image="-"
    compose_project="-"
    compose_service="-"
    provision_project="-"
  fi
  jq -nc -f "$(catalog_path jq/port-record.jq)" \
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
    --arg host_listener_pid ""
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
  jq -nc -f "$(catalog_path jq/port-record.jq)" \
    --arg service "$service" \
    --arg env "${service_port_env[$service]}" \
    --arg port "$port" \
    --arg source "$(service_port_source "$service")" \
    --arg state "$state" \
    --argjson occupied "$occupied" \
    --arg owner "$owner" \
    --arg container_id "" \
    --arg name "" \
    --arg image "" \
    --arg compose_project "" \
    --arg compose_service "" \
    --arg provision_project "" \
    --arg host_listener_pid ""
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
    --argjson project "$(project_json)" \
    --argjson auth "$(auth_json)" \
    --argjson portPolicy "$(port_policy_json)" \
    --argjson services "$(service_records_json)" \
    --argjson warnings "$(warnings_json)" \
    --argjson resources "$(empty_resources_json)" \
    --argjson artifacts "$(generated_artifacts_json)" \
    --argjson extensionsEnvelope "$(extension_envelope_json)" \
    --argjson toolsEnvelope "$(tools_envelope_json)" \
    "$@" \
    "{schemaVersion: \$schemaVersion, command: \$command, ok: \$ok, warnings: \$warnings, error: null, project: \$project, auth: \$auth, portPolicy: \$portPolicy, services: \$services, ports: [], resources: \$resources, artifacts: \$artifacts, extensions: \$extensionsEnvelope, tools: \$toolsEnvelope} | $extra_filter"
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
