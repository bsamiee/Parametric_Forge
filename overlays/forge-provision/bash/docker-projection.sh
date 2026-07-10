# shellcheck shell=bash
# Sourced into forge-provision.sh; the entry script owns every referenced global.
# shellcheck disable=SC2154
inspect_label() {
    local id="$1"
    local label="$2"
    local value
    value="$(docker inspect --format "{{ with index .Config.Labels \"$label\" }}{{ . }}{{ end }}" "$id" 2>/dev/null || true)"
    [[ "$value" == "<no value>" ]] && value=""
    printf '%s\n' "$value"
}

# One docker inspect serves every requested container label as one row; absent labels and failed inspects project as empty fields. Unit-separator
# delimited: tab is IFS whitespace and read would collapse empty fields.
inspect_labels() {
    local id="$1" raw
    shift
    raw="$(docker inspect --format '{{ json .Config.Labels }}' "$id" 2>/dev/null)" || raw='{}'
    jq -r -f "$(catalog_path jq/label-fields.jq)" --args -- "$@" <<<"${raw:-null}"
}

validate_owned_container_identity() {
    local id="$1"
    local service="$2"
    local mode="${3:-strict}"
    local raw owned root project compose_project compose_service image expected_image net volume mount
    if ! known_service "$service"; then
        [[ "$mode" == "cleanup" ]] || die "refusing unknown provision container service=$service id=$id"
        service=""
    fi
    # One inspect snapshot backs every identity assertion for this container.
    raw="$(docker inspect "$id" 2>/dev/null)" || raw=""
    IFS=$'\x1f' read -r owned root project compose_project compose_service image < <(
        jq -r --arg owner "$owner_label" --arg root "$root_label" --arg project "$project_label" \
            '.[0] as $c | ($c.Config.Labels // {}) as $l
        | [($l[$owner] // ""), ($l[$root] // ""), ($l[$project] // ""),
           ($l["com.docker.compose.project"] // ""), ($l["com.docker.compose.service"] // ""),
           ($c.Config.Image // "")] | join("\u001f")' <<<"${raw:-[]}"
    )
    [[ "$owned" == "1" ]] || die "refusing unowned container id=$id"
    [[ "$root" == "$root_key" ]] || die "refusing container from another provision root id=$id root=$root"
    [[ "$project" == "$project_name" ]] || die "refusing container from another provision project id=$id provision_project=$project"
    [[ "$compose_project" == "$project_name" ]] || die "refusing container from another Compose project id=$id compose_project=$compose_project"
    [[ -z "$service" || "$compose_service" == "$service" ]] || die "refusing container with wrong Compose service id=$id service=$compose_service expected=$service"
    [[ "$mode" == "cleanup" ]] && return 0
    [[ -n "$image" ]] || die "cannot inspect container image id=$id"
    expected_image="$(service_image "$service")"
    [[ "$image" == "$expected_image" ]] || die "refusing container with wrong image id=$id image=$image expected=$expected_image"
    net="$(network_name)"
    volume="$(service_volume_name "$service")"
    mount="${service_volume_mount[$service]}"
    jq -e --arg mode identity --arg net "$net" --arg volume "$volume" --arg mount "$mount" -f "$(catalog_path jq/container-projection.jq)" <<<"$raw" >/dev/null ||
        die "refusing container with wrong network or volume mount id=$id service=$service"
}

# Owned-container docker-ps projection; optional service narrows to one Compose service.
owned_ps() {
    local flag="$1"
    local service="${2:-}"
    local -a args=(
        --filter "label=com.docker.compose.project=$project_name"
        --filter "label=$owner_label=1"
        --filter "label=$root_label=$root_key"
        --filter "label=$project_label=$project_name"
    )
    [[ -z "$service" ]] || args+=(--filter "label=$service_label=$service")
    docker ps "$flag" "${args[@]}"
}

collect_owned_container_ids() {
    # shellcheck disable=SC2178
    local -n _out="$1"
    local raw
    _out=()
    raw="$(owned_ps -aq)" || return
    [[ -z "$raw" ]] || mapfile -t _out <<<"$raw"
}

# Owned named-resource collector for volume/network listings.
collect_owned_names() {
    local kind="$1"
    # shellcheck disable=SC2178
    local -n _out="$2"
    local raw
    _out=()
    raw="$(docker "$kind" ls -q \
        --filter "label=$owner_label=1" \
        --filter "label=$root_label=$root_key" \
        --filter "label=$project_label=$project_name")" || return
    [[ -z "$raw" ]] || mapfile -t _out <<<"$raw"
}

active_other_project_count() {
    local raw
    local ids=()
    raw="$(docker ps -q \
        --filter "label=$owner_label=1")" || return
    [[ -z "$raw" ]] || mapfile -t ids <<<"$raw"
    ((${#ids[@]} > 0)) || {
        printf '0\n'
        return 0
    }
    docker inspect "${ids[@]}" | jq -r --arg project_label "$project_label" --arg current "$project_name" \
        -f "$(catalog_path jq/active-other-projects.jq)"
}

enforce_max_active_projects() {
    ((max_active_projects == 0)) && return 0
    local count
    count="$(active_other_project_count)" || die "cannot inspect active provisioning projects"
    ((count < max_active_projects)) || die "active provisioning project cap reached: active_other_projects=$count max=$max_active_projects"
}

service_identity_json() {
    local service
    local -a identity_args=()
    for service in "${service_order[@]}"; do
        identity_args+=("$service" "$(service_image "$service")" "$(service_volume_name "$service")" "${service_volume_mount[$service]}")
    done
    jq -nc \
        '[range(0; ($ARGS.positional | length); 4) as $i
          | {key: $ARGS.positional[$i], value: {image: $ARGS.positional[$i + 1], volume: $ARGS.positional[$i + 2], mount: $ARGS.positional[$i + 3]}}]
         | from_entries' \
        --args -- "${identity_args[@]}"
}

# One inspect snapshot projects service, name, image, state, health, and identity as one US-joined row.
container_report_row() {
    local raw="$1"
    jq -r --arg mode report-row --arg service_label "$service_label" --arg net "$(network_name)" \
        --argjson identities "$(service_identity_json)" \
        -f "$(catalog_path jq/container-projection.jq)" <<<"${raw:-[]}"
}

container_id_for_service() {
    local service="$1"
    local raw
    raw="$(owned_ps -aq "$service")" || return
    printf '%s\n' "${raw%%$'\n'*}"
}

container_running_for_service() {
    local service="$1"
    [[ -n "$(owned_ps -q "$service")" ]]
}

container_publishes_service_host_port() {
    local id="$1"
    local port="$2"
    local host="$3"
    docker inspect "$id" | jq -e --arg port "$port" --arg host "$host" -f "$(catalog_path jq/service-host-publisher.jq)" >/dev/null
}

containers_publishing_host_port() {
    local port="$1"
    local raw
    local ids=()
    raw="$(docker ps -q)" || return
    [[ -z "$raw" ]] || mapfile -t ids <<<"$raw"
    ((${#ids[@]} > 0)) || return 0
    docker inspect "${ids[@]}" | jq -r --arg port "$port" -f "$(catalog_path jq/port-publishers.jq)"
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
        IFS=$'\x1f' read -r owned root project service_value compose_project < <(
            inspect_labels "$id" "$owner_label" "$root_label" "$project_label" "$service_label" "com.docker.compose.project"
        )
        [[ "$owned" == "1" && "$root" == "$root_key" && "$project" == "$project_name" && "$service_value" == "$service" && "$compose_project" == "$project_name" ]] || continue
        validate_owned_container_identity "$id" "$service"
        container_publishes_service_host_port "$id" "$port" "${service_host[$service]}" && return 0
    done
    return 1
}

port_busy() {
    local port="$1"
    local ids=()
    collect_published_container_ids ids "$port" || die "docker port inspection failed for port=$port"
    ((${#ids[@]} > 0)) && return 0
    host_port_busy "$port"
}

# Reads one container's provenance labels into caller-scoped variables, empty fields normalized to "-".
read_container_provenance() {
    local id="$1"
    local raw var
    raw="$(docker inspect "$id" 2>/dev/null)" || raw=""
    IFS=$'\x1f' read -r name image compose_project compose_service provision_owner provision_root provision_project < <(
        jq -r --arg owner "$owner_label" --arg root "$root_label" --arg project "$project_label" \
            '.[0] as $c | ($c.Config.Labels // {}) as $l
        | [(($c.Name // "") | ltrimstr("/")), ($c.Config.Image // ""),
           ($l["com.docker.compose.project"] // ""), ($l["com.docker.compose.service"] // ""),
           ($l[$owner] // ""), ($l[$root] // ""), ($l[$project] // "")] | join("\u001f")' <<<"${raw:-[]}"
    )
    for var in name image compose_project compose_service provision_owner provision_root provision_project; do
        [[ -n "${!var}" ]] || printf -v "$var" '%s' '-'
    done
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
    local id="-" name="-" image="-" compose_project="-" compose_service="-" provision_owner="-" provision_root="-" provision_project="-" owner
    collect_published_container_ids ids "$port"
    ((${#ids[@]} == 0)) || id="${ids[0]}"
    [[ "$id" == "-" ]] || read_container_provenance "$id"
    owner="$(classify_owner "$id" "$compose_project" "$provision_owner" "$provision_root" "$provision_project")"
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
        IFS=$'\x1f' read -r owned root project service < <(
            inspect_labels "$id" "$owner_label" "$root_label" "$project_label" "$service_label"
        )
        [[ "$owned" == "1" ]] || die "refusing to manage unlabeled container in project $project_name: $id"
        [[ "$root" == "$root_key" ]] || die "refusing to manage container from another provision root in project $project_name: $id root=$root"
        [[ "$project" == "$project_name" ]] || die "refusing to manage container from another provision project in project $project_name: $id provision_project=$project"
        validate_owned_container_identity "$id" "$service" "$mode"
    done <<<"$ids"
}

assert_owned_named_resource() {
    local kind="$1"
    local name="$2"
    local expected_service="$3"
    local raw owner root project service_value
    raw="$(docker "$kind" inspect --format '{{ json .Labels }}' "$name" 2>/dev/null)" || return 0
    IFS=$'\x1f' read -r owner root project service_value < <(
        jq -r -f "$(catalog_path jq/label-fields.jq)" \
            --args -- "$owner_label" "$root_label" "$project_label" "$service_label" <<<"${raw:-null}"
    )
    [[ "$owner" == "1" && "$root" == "$root_key" && "$project" == "$project_name" && "$service_value" == "$expected_service" ]] ||
        die "refusing to reuse $kind with wrong labels: $name"
}

assert_owned_named_resources() {
    local service
    while IFS= read -r service; do
        assert_owned_named_resource volume "$(service_volume_name "$service")" "$service"
    done < <(enabled_services)
    assert_owned_named_resource network "$(network_name)" network
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
    local id raw name='-' image='-' state='-' health='-' ports
    id="$(container_id_for_service "$service")"
    if [[ -z "$id" ]]; then
        stderr_line "$(printf 'readiness\tservice=%s\tstatus=missing-container\tport=%s\tproject=%s\troot=%s' "$service" "$(service_port "$service")" "$project_name" "$root_key")"
        return 0
    fi
    raw="$(docker inspect "$id" 2>/dev/null)" || raw='[]'
    IFS=$'\x1f' read -r _ name image state health _ _ < <(container_report_row "$raw") || true
    ports="$(published_ports "$id")"
    stderr_line "$(printf 'readiness\tservice=%s\tstatus=timeout\tport=%s\tcontainer_id=%s\tname=%s\timage=%s\tdocker_status=%s\thealth=%s\tpublished=%s' \
        "$service" "$(service_port "$service")" "$id" "$name" "$image" "$state" "$health" "$ports")"
    local log_block
    log_block="$(docker logs --tail 20 "$id" 2>&1 | awk -v service="$service" '{ printf "readiness-log\tservice=%s\t%s\n", service, $0 }' || true)"
    [[ -z "$log_block" ]] || stderr_line "$log_block"
}

wait_service() {
    local service="$1"
    local id attempt=1
    while ((attempt <= service_ready_attempts)); do
        id="$(container_id_for_service "$service")"
        if [[ -n "$id" ]] && port_owned_by_service "$service" "$(service_port "$service")" &&
            docker exec "$id" pg_isready -U "${service_db_user[$service]}" -d "${service_db_name[$service]}" >/dev/null 2>&1; then
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

# One psql runner: foreground mode owns TTY/interrupt forwarding, batch mode streams TSV rows.
psql_in_container() {
    local service="$1"
    local foreground="$2"
    shift 2
    local id
    require_service_endpoint "$service"
    id="$(container_id_for_service "$service")"
    [[ -n "$id" ]] || die "missing container for service=$service"
    local -a exec_args=(-i) runner=()
    if [[ "$foreground" == true ]]; then
        runner=(run_foreground_child)
        [[ -t 0 && -t 1 ]] && exec_args=(-it)
    fi
    if [[ "$auth_mode" == "auto-root" ]]; then
        # shellcheck disable=SC2016
        "${runner[@]}" docker exec "${exec_args[@]}" "$id" sh -c 'PGPASSWORD="$(cat "$1")"; export PGPASSWORD; shift; exec psql "$@"' \
            sh "/run/secrets/$(auth_secret_name "$service")" -X -w -U "${service_db_user[$service]}" -d "${service_db_name[$service]}" "$@"
    else
        "${runner[@]}" docker exec "${exec_args[@]}" "$id" psql -X -w -U "${service_db_user[$service]}" -d "${service_db_name[$service]}" "$@"
    fi
}

psql_tsv() {
    local service="$1"
    shift
    psql_in_container "$service" false -q -v ON_ERROR_STOP=1 -A -F $'\t' -t "$@"
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

# One extension-row producer; mode selects the read-only probe or the mutating apply SQL. A failed per-service SQL run fails the whole producer:
# silently dropped rows would evade apply_required_rows_ok, which only inspects rows that exist.
extension_rows() {
    local mode="$1"
    local service rc=0
    for service in "${service_order[@]}"; do
        if ! service_enabled "$service"; then
            disabled_service_apply_rows "$service" || rc=1
        elif [[ "$mode" == "apply" ]]; then
            service_extension_sql "$service" apply-postgres.sql.tpl || rc=1
        else
            service_extension_sql "$service" check-postgres.sql.tpl || rc=1
        fi
    done
    return "$rc"
}

apply_required_rows_ok() {
    local rows="$1"
    local service state _version _category required
    while IFS=$'\t' read -r service _extension state _version _category required; do
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

# One owned-resource remover for the named kinds; per-kind service validation is the only variant row.
remove_owned_resources() {
    local kind="$1"
    local names=()
    local name service root project
    case "$kind" in
        volume | network) collect_owned_names "$kind" names ;;
        *) die "unknown owned resource kind: $kind" ;;
    esac
    ((${#names[@]} > 0)) || return 0
    for name in "${names[@]}"; do
        IFS=$'\x1f' read -r service root project < <(
            docker "$kind" inspect --format '{{ json .Labels }}' "$name" 2>/dev/null |
                jq -r -f "$(catalog_path jq/label-fields.jq)" --args -- "$service_label" "$root_label" "$project_label"
        ) || return
        case "$kind" in
            volume) known_service "$service" || die "refusing to remove unexpected owned volume service=$service name=$name" ;;
            network) [[ "$service" == "network" ]] || die "refusing to remove unexpected owned network service=$service name=$name" ;;
        esac
        [[ "$root" == "$root_key" && "$project" == "$project_name" ]] || die "refusing to remove $kind outside current root/project name=$name root=$root project=$project"
        docker "$kind" rm "$name" >/dev/null || return
    done
}

file_record_json() {
    local kind="$1"
    local type="$2"
    local path="$3"
    local exists=false
    [[ -e "$path" ]] && exists=true
    jq -nc --arg kind "$kind" --arg type "$type" --argjson exists "$exists" \
        --argjson diagnostic "$diagnostic_json" \
        '{kind: $kind, type: $type, exists: $exists} + if $diagnostic then {pathRedacted: true} else {} end'
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
            for path in "$provisioning_dir"/.gen-* "$provisioning_dir"/.staging-gen-* "$provisioning_dir"/.current.next "$docker_config_dir"/.tmp.*; do
                [[ -e "$path" ]] || continue
                file_record_json generated_artifact path "$path"
            done
        fi
    } | jq -s 'sort_by(.kind)'
}

owned_containers_json() {
    local ids=()
    collect_owned_container_ids ids
    ((${#ids[@]} > 0)) || {
        printf '[]\n'
        return 0
    }
    docker inspect "${ids[@]}" | jq -c \
        --arg mode owned \
        --arg owner_label "$owner_label" \
        --arg service_label "$service_label" \
        --arg root_label "$root_label" \
        --arg project_label "$project_label" \
        --arg net "$(network_name)" \
        --argjson identities "$(service_identity_json)" \
        -f "$(catalog_path jq/container-projection.jq)"
}

# One owned-resource projector for the named kinds; the kind selects its jq projection.
owned_resources_json() {
    local kind="$1"
    local names=()
    collect_owned_names "$kind" names
    ((${#names[@]} > 0)) || {
        printf '[]\n'
        return 0
    }
    docker "$kind" inspect "${names[@]}" | jq -c --arg owner_label "$owner_label" --arg service_label "$service_label" --arg root_label "$root_label" --arg project_label "$project_label" --argjson diagnostic "$diagnostic_json" \
        -f "$(catalog_path "jq/owned-${kind}s.jq")"
}

service_records_tsv() {
    local service
    resolve_auth
    resolve_ports false
    for service in "${service_order[@]}"; do
        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
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
            "$(service_port_source "$service")" \
            "${service_host[$service]}" \
            "${service_container_port[$service]}"
    done
}

service_records_json() {
    service_records_tsv | jq -Rsc -f "$(catalog_path jq/service-records.jq)"
}

configured_images_json() {
    service_records_tsv | jq -Rsc -f "$(catalog_path jq/configured-images.jq)"
}

# One port-record assembler: online mode inspects publishing containers, offline mode probes host listeners only.
port_record_json() {
    local service="$1"
    local online="${2:-true}"
    local port ids=() id="-" name="-" image="-" compose_project="-" compose_service="-" provision_owner="-" provision_root="-" provision_project="-" owner="none" host_listener=false state="free" occupied=false
    port="$(service_port "$service")"
    service_enabled "$service" || state="disabled"
    if [[ "$online" == true ]]; then
        collect_published_container_ids ids "$port" || die "docker port inspection failed for port=$port"
    fi
    if host_port_busy "$port"; then
        host_listener=true
    fi
    if ((${#ids[@]} > 0)); then
        id="${ids[0]}"
        read_container_provenance "$id"
        owner="$(classify_owner "$id" "$compose_project" "$provision_owner" "$provision_root" "$provision_project")"
        occupied=true
        [[ "$state" == "disabled" ]] || state="busy"
    elif [[ "$host_listener" == true ]]; then
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
        --arg provision_project "$provision_project"
}

port_records_json() {
    local online="${1:-true}"
    local service
    for service in "${service_order[@]}"; do
        port_record_json "$service" "$online"
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
        --argjson baseGenerated "$(generated_files_json)" \
        "$@" \
        "$(envelope_filter envelope-base.jq) | $extra_filter"
    # shellcheck disable=SC2034  # read by the entry script error rail
    json_result_emitted=true
}

emit_ports_text() {
    local records="$1"
    jq -r -f "$(catalog_path jq/ports-text.jq)" <<<"$records"
}

relevant_images_json() {
    local configured
    configured="$(configured_images_json)"
    docker image ls --format '{{json .}}' 2>/dev/null |
        jq -s --argjson configured "$configured" -f "$(catalog_path jq/relevant-images.jq)"
}

docker_disk_json() {
    docker system df --format '{{json .}}' 2>/dev/null | jq -s 'sort_by(.Type // "")'
}
