# Title         : rasm-spike-stack/default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/scripts/provisioning/rasm-spike-stack/default.nix
# ----------------------------------------------------------------------------
# Disposable Rasm spike services under the target repo's .artifacts tree.
{pkgs, ...}: {
  home.packages = [
    (pkgs.writeShellApplication {
      name = "rasm-spike-stack";
      runtimeInputs = with pkgs; [
        coreutils
        docker-client
        docker-compose
        gawk
        gnused
        gnugrep
        lsof
        postgresql_18
      ];
      bashOptions = ["errexit" "errtrace" "nounset" "pipefail"];
      text = ''
        shopt -s inherit_errexit

        readonly owner_label="dev.bsamiee.rasm-spike-stack"
        readonly service_label="dev.bsamiee.rasm.service"
        readonly root_label="dev.bsamiee.rasm.root"
        readonly project_name="''${RASM_SPIKE_PROJECT:-rasm-spike}"
        readonly timescale_image="''${RASM_TIMESCALE_IMAGE:-timescale/timescaledb-ha:pg18.4-ts2.27.2-all}"
        readonly paradedb_image="''${RASM_PARADEDB_IMAGE:-paradedb/paradedb:pg18}"
        readonly pgduckdb_image="''${RASM_PGDUCKDB_IMAGE:-pgduckdb/pgduckdb:18-v1.1.1}"
        readonly timescale_port="''${RASM_TIMESCALE_PORT:-55432}"
        readonly search_port="''${RASM_SEARCH_PORT:-55433}"
        readonly pgduckdb_port="''${RASM_PGDUCKDB_PORT:-55434}"
        readonly pgduckdb_enabled="''${RASM_SPIKE_PGDUCKDB:-0}"
        readonly commands=$'up\tStart Timescale and ParadeDB spike services\ndown\tStop owned services and remove script-owned data/status files\nstatus\tShow owned spike service status without writing files\nenv\tPrint derived paths and connection environment without writing files\nverify\tVerify owned PostgreSQL spike extensions only\nverify-extensions\tVerify owned PostgreSQL spike extensions only\npsql-timescale\tOpen psql against the owned Timescale service\npsql-search\tOpen psql against the owned ParadeDB service\nself-test\tValidate local script configuration'

        on_err() {
          local rc=$?
          printf 'rasm-spike-stack: error: command failed rc=%s line=%s command=%s\n' "$rc" "''${BASH_LINENO[0]:-?}" "$BASH_COMMAND" >&2
          exit "$rc"
        }
        trap on_err ERR

        die() {
          printf 'rasm-spike-stack: %s\n' "$*" >&2
          exit 1
        }

        list_commands() {
          printf '%s\n' "$commands"
        }

        usage() {
          local command description
          printf 'Usage: rasm-spike-stack <command> [args]\n\n'
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
            printf '%s\n' "$(cd "$candidate" && pwd -P)"
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

          candidate="/Users/bardiasamiee/Documents/99.Github/Rasm"
          [[ -d "$candidate" ]] || die "cannot find Rasm root; set RASM_ROOT"
          printf '%s\n' "$candidate"
        }

        validate_rasm_root() {
          local root="$1"
          [[ -f "$root/pyproject.toml" ]] || die "Rasm root missing pyproject.toml: $root"
          [[ -f "$root/Directory.Packages.props" ]] || die "Rasm root missing Directory.Packages.props: $root"
          [[ -d "$root/libs/csharp" ]] || die "Rasm root missing libs/csharp: $root"
        }

        rasm_root="$(find_rasm_root)"
        readonly rasm_root
        validate_rasm_root "$rasm_root"
        readonly provisioning_dir="$rasm_root/.artifacts/spikes/provisioning"
        readonly data_dir="$provisioning_dir/data"
        readonly env_file="$provisioning_dir/.env"
        readonly compose_file="$provisioning_dir/compose.yaml"
        root_fingerprint="$(${pkgs.coreutils}/bin/printf '%s' "$rasm_root" | ${pkgs.coreutils}/bin/sha256sum)"
        readonly root_fingerprint="''${root_fingerprint%% *}"

        validate_static_env() {
          validate_port RASM_TIMESCALE_PORT "$timescale_port"
          validate_port RASM_SEARCH_PORT "$search_port"
          validate_port RASM_PGDUCKDB_PORT "$pgduckdb_port"
          validate_image RASM_TIMESCALE_IMAGE "$timescale_image"
          validate_image RASM_PARADEDB_IMAGE "$paradedb_image"
          validate_image RASM_PGDUCKDB_IMAGE "$pgduckdb_image"
          [[ "$project_name" =~ ^[a-z0-9][a-z0-9_-]*$ ]] || die "RASM_SPIKE_PROJECT must match ^[a-z0-9][a-z0-9_-]*$: $project_name"
          [[ "$pgduckdb_enabled" == "0" || "$pgduckdb_enabled" == "1" ]] || die "RASM_SPIKE_PGDUCKDB must be 0 or 1"
        }

        docker_compose() {
          if docker compose version >/dev/null 2>&1; then
            docker compose -f "$compose_file" --project-name "$project_name" "$@"
          elif command -v docker-compose >/dev/null 2>&1; then
            docker-compose -f "$compose_file" --project-name "$project_name" "$@"
          else
            die "docker compose is unavailable"
          fi
        }

        ensure_docker_config() {
          local clean="$provisioning_dir/docker-config"
          mkdir -p "$clean"
          atomic_render "$clean/config.json" render_empty_json
          export DOCKER_CONFIG="$clean"
          printf 'docker-credentials\tmode=anonymous\treason=agent-local-public-images\tconfig=%s\n' "$clean" >&2
        }

        render_empty_json() {
          printf '{}\n'
        }

        inspect_label() {
          local id="$1"
          local label="$2"
          docker inspect --format "{{ index .Config.Labels \"$label\" }}" "$id" 2>/dev/null || true
        }

        owned_service_running() {
          local service="$1"
          local ids
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
          local ids
          ids="$(docker ps -q \
            --filter "publish=$port" \
            --filter "label=com.docker.compose.project=$project_name" \
            --filter "label=$owner_label=1" \
            --filter "label=$service_label=$service" \
            --filter "label=$root_label=$root_fingerprint")"
          [[ -n "$ids" ]]
        }

        classify_owner() {
          local id="$1"
          local compose_project="$2"
          local spike_owner="$3"
          local spike_root="$4"
          if [[ "$spike_owner" == "1" && "$spike_root" == "$root_fingerprint" ]]; then
            printf 'spike:this-root'
          elif [[ "$spike_owner" == "1" && -n "$spike_root" && "$spike_root" != "$root_fingerprint" ]]; then
            printf 'spike:other-root'
          elif [[ "$spike_owner" == "1" ]]; then
            printf 'spike:unknown-root'
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
          id="$(docker ps -aq --filter "publish=$port" | head -n 1)"
          [[ -n "$id" ]] || id="-"

          local name="-" image="-" status="-" published="-" compose_project="-" compose_service="-" spike_owner="-" spike_service="-" spike_root="-"
          if [[ "$id" != "-" ]]; then
            name="$(docker inspect --format '{{ .Name }}' "$id" 2>/dev/null || printf '-')"
            name="''${name#/}"
            image="$(docker inspect --format '{{ .Config.Image }}' "$id" 2>/dev/null || printf '-')"
            status="$(docker inspect --format '{{ .State.Status }}' "$id" 2>/dev/null || printf '-')"
            published="$(docker port "$id" 2>/dev/null | tr '\n' ',' | sed 's/,$//' || printf '-')"
            compose_project="$(inspect_label "$id" "com.docker.compose.project")"
            compose_service="$(inspect_label "$id" "com.docker.compose.service")"
            spike_owner="$(inspect_label "$id" "$owner_label")"
            spike_service="$(inspect_label "$id" "$service_label")"
            spike_root="$(inspect_label "$id" "$root_label")"
            [[ -n "$compose_project" ]] || compose_project="-"
            [[ -n "$compose_service" ]] || compose_service="-"
            [[ -n "$spike_owner" ]] || spike_owner="-"
            [[ -n "$spike_service" ]] || spike_service="-"
            [[ -n "$spike_root" ]] || spike_root="-"
          fi

          local owner pid command action
          owner="$(classify_owner "$id" "$compose_project" "$spike_owner" "$spike_root")"
          pid="$(host_listener_field "$port" pid)"
          command="$(host_listener_field "$port" command)"
          [[ -n "$pid" ]] || pid="-"
          [[ -n "$command" ]] || command="-"
          action="set $env_var to a free port or stop the non-owned listener outside rasm-spike-stack"

          printf 'port-collision\tservice=%s\tenv=%s\thost=127.0.0.1\trequested=%s\tcontainer_port=%s\towner=%s\tcontainer_id=%s\tname=%s\timage=%s\tstatus=%s\tpublished=%s\tcompose_project=%s\tcompose_service=%s\tspike_owner_label=%s\tspike_service_label=%s\tspike_root_label=%s\tcurrent_root_label=%s\thost_listener_pid=%s\thost_listener_command=%s\taction=%s\n' \
            "$service" "$env_var" "$port" "$container_port" "$owner" "$id" "$name" "$image" "$status" "$published" "$compose_project" "$compose_service" "$spike_owner" "$spike_service" "$spike_root" "$root_fingerprint" "$pid" "$command" "$action" >&2
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

          local docker_config="$provisioning_dir/docker-config"
          case "$docker_config" in
            "$provisioning_dir"/docker-config) rm -rf "$docker_config" ;;
            *) die "refusing to remove unexpected docker config dir: $docker_config" ;;
          esac

          rmdir "$provisioning_dir" 2>/dev/null || true
        }

        stop_owned_without_compose() {
          local ids=()
          mapfile -t ids < <(docker ps -aq \
            --filter "label=com.docker.compose.project=$project_name" \
            --filter "label=$owner_label=1" \
            --filter "label=$root_label=$root_fingerprint")
          ((''${#ids[@]} > 0)) || return 0
          docker rm -f "''${ids[@]}" >/dev/null
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
          docker info >/dev/null 2>&1 || die "docker daemon is unavailable"
        }

        prepare_docker_for_pull() {
          ensure_docker_config
        }

        port_busy() {
          local port="$1"
          if docker ps -q --filter "publish=$port" | grep -q .; then
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
          local dir tmp old_umask
          dir="$(dirname "$target")"
          mkdir -p "$dir"
          old_umask="$(umask)"
          umask 077
          tmp="$(mktemp "$dir/.tmp.XXXXXX")"
          umask "$old_umask"
          if "$renderer" > "$tmp"; then
            chmod 600 "$tmp"
            mv "$tmp" "$target"
          else
            rm -f "$tmp"
            return 1
          fi
        }

        render_env() {
          cat <<EOF
        RASM_ROOT=$rasm_root
        RASM_SPIKE_PROJECT=$project_name
        RASM_TIMESCALE_IMAGE=$timescale_image
        RASM_PARADEDB_IMAGE=$paradedb_image
        RASM_PGDUCKDB_IMAGE=$pgduckdb_image
        RASM_TIMESCALE_PORT=$timescale_port
        RASM_SEARCH_PORT=$search_port
        RASM_PGDUCKDB_PORT=$pgduckdb_port
        RASM_SPIKE_PGDUCKDB=$pgduckdb_enabled
        EOF
        }

        render_compose() {
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
            user: "0:0"
            labels:
              $owner_label: "1"
              $service_label: timescale
              $root_label: "$root_fingerprint"
            healthcheck:
              test: ["CMD-SHELL", "pg_isready -U postgres -d rasm"]
              interval: 5s
              timeout: 5s
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
            user: "0:0"
            labels:
              $owner_label: "1"
              $service_label: search
              $root_label: "$root_fingerprint"
            healthcheck:
              test: ["CMD-SHELL", "pg_isready -U postgres -d rasm"]
              interval: 5s
              timeout: 5s
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
            user: "0:0"
            labels:
              $owner_label: "1"
              $service_label: pgduckdb
              $root_label: "$root_fingerprint"
            healthcheck:
              test: ["CMD-SHELL", "pg_isready -U postgres -d rasm"]
              interval: 5s
              timeout: 5s
              retries: 30
        EOF
          fi

          cat <<EOF

        volumes:
          timescale-data: {}
          search-data: {}
        EOF

          if [[ "$pgduckdb_enabled" == "1" ]]; then
            cat <<EOF
          pgduckdb-data: {}
        EOF
          fi
        }

        write_assets() {
          validate_static_env
          mkdir -p "$provisioning_dir"
          atomic_render "$env_file" render_env
          atomic_render "$compose_file" render_compose
          docker_compose config >/dev/null
        }

        wait_port() {
          local service="$1"
          local port="$2"
          local attempt=1
          while ((attempt <= 90)); do
            if pg_isready -h 127.0.0.1 -p "$port" -U postgres -d rasm >/dev/null 2>&1; then
              printf '%s\tready\t%s\n' "$service" "$port"
              return 0
            fi
            sleep 1
            ((attempt++))
          done
          die "$service did not become ready on port $port"
        }

        wait_services() {
          wait_port timescale "$timescale_port"
          wait_port search "$search_port"
          if [[ "$pgduckdb_enabled" == "1" ]]; then
            wait_port pgduckdb "$pgduckdb_port"
          fi
        }

        psql_service() {
          local port="$1"
          shift
          psql -h 127.0.0.1 -p "$port" -U postgres -d rasm "$@"
        }

        psql_tsv() {
          local port="$1"
          shift
          psql -h 127.0.0.1 -p "$port" -U postgres -d rasm -X -v ON_ERROR_STOP=1 -A -F $'\t' -t "$@"
        }

        verify_timescale() {
          psql_tsv "$timescale_port" <<'SQL'
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
          psql_tsv "$search_port" <<'SQL'
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

          psql_tsv "$pgduckdb_port" <<'SQL'
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
          write_assets
          prepare_docker_for_pull
          assert_owned_project
          preflight_ports
          docker_compose up -d
          wait_services
          cmd_verify_extensions
        }

        cmd_down() {
          require_docker
          assert_owned_project
          if [[ -f "$compose_file" ]]; then
            docker_compose down --volumes --remove-orphans
          else
            stop_owned_without_compose
          fi
          cleanup_assets
        }

        cmd_status() {
          require_docker
          if [[ -f "$compose_file" ]]; then
            docker_compose ps
          else
            docker ps -a \
              --filter "label=com.docker.compose.project=$project_name" \
              --filter "label=$owner_label=1" \
              --filter "label=$root_label=$root_fingerprint" \
              --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
          fi
        }

        cmd_env() {
          validate_static_env
          cat <<EOF
        RASM_ROOT=$rasm_root
        RASM_SPIKE_PROVISIONING=$provisioning_dir
        RASM_SPIKE_COMPOSE=$compose_file
        RASM_SPIKE_ENV=$env_file
        RASM_TIMESCALE_DSN=postgres://postgres@127.0.0.1:$timescale_port/rasm
        RASM_SEARCH_DSN=postgres://postgres@127.0.0.1:$search_port/rasm
        RASM_PGDUCKDB_DSN=postgres://postgres@127.0.0.1:$pgduckdb_port/rasm
        RASM_SPIKE_PGDUCKDB=$pgduckdb_enabled
        EOF
        }

        cmd_verify_extensions() {
          require_docker
          write_assets
          assert_owned_project
          require_owned_services
          wait_services
          verify_timescale
          verify_search
          verify_pgduckdb
        }

        cmd_psql_timescale() {
          validate_static_env
          require_docker
          require_owned_services
          psql_service "$timescale_port" "$@"
        }

        cmd_psql_search() {
          validate_static_env
          require_docker
          require_owned_services
          psql_service "$search_port" "$@"
        }

        cmd_self_test() {
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

        main() {
          local command="''${1:-}"
          shift || true
          case "$command" in
            up) cmd_up "$@" ;;
            down) cmd_down "$@" ;;
            status) cmd_status "$@" ;;
            env) cmd_env "$@" ;;
            verify | verify-extensions) cmd_verify_extensions "$@" ;;
            psql-timescale) cmd_psql_timescale "$@" ;;
            psql-search) cmd_psql_search "$@" ;;
            self-test | --self-test) cmd_self_test "$@" ;;
            help | --help | -h | "") usage ;;
            *) usage >&2; die "unknown command: $command" ;;
          esac
        }

        main "$@"
      '';
    })
  ];
}
