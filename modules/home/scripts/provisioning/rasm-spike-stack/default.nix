# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/scripts/provisioning/rasm-spike-stack/default.nix
# ----------------------------------------------------------------------------
# Disposable public-image services for Rasm tier-2 spike probes.
{pkgs, ...}: {
  home.file.".local/bin/rasm-spike-stack" = {
    executable = true;
    text = ''
      #!${pkgs.bash}/bin/bash
      # Title         : rasm-spike-stack
      # Author        : Bardia Samiee
      # Project       : Parametric Forge
      # License       : MIT
      # Path          : modules/home/scripts/provisioning/rasm-spike-stack
      # ----------------------------------------------------------------------------
      # Disposable Rasm PG18 spike services. Only labelled containers created by this
      # script are eligible for teardown.

      set -Eeuo pipefail
      shopt -s inherit_errexit

      readonly project_name="rasm-spike-provisioning"
      readonly owner_label="parametric-forge.rasm-spike-stack"
      readonly timescale_image="''${RASM_TIMESCALE_IMAGE:-timescale/timescaledb-ha:pg18.4-ts2.27.2-all}"
      readonly search_image="''${RASM_PARADEDB_IMAGE:-paradedb/paradedb:0.24.0}"
      readonly timescale_port="''${RASM_TIMESCALE_PORT:-55432}"
      readonly search_port="''${RASM_SEARCH_PORT:-55433}"
      readonly postgres_user="''${RASM_POSTGRES_USER:-rasm}"
      readonly postgres_password="''${RASM_POSTGRES_PASSWORD:-rasm}"
      readonly postgres_db="''${RASM_POSTGRES_DB:-rasm}"

      _usage() {
        cat >&2 <<'USAGE'
      usage: rasm-spike-stack <up|down|status|psql-timescale|psql-search|env> [psql-args...]

      Environment:
        RASM_ROOT              Optional Rasm checkout root override.
        RASM_TIMESCALE_IMAGE   Default: timescale/timescaledb-ha:pg18.4-ts2.27.2-all
        RASM_PARADEDB_IMAGE    Default: paradedb/paradedb:0.24.0
        RASM_TIMESCALE_PORT    Default: 55432
        RASM_SEARCH_PORT       Default: 55433
        RASM_POSTGRES_USER     Default: rasm
        RASM_POSTGRES_PASSWORD Default: rasm
        RASM_POSTGRES_DB       Default: rasm
      USAGE
      }

      _die() {
        printf 'rasm-spike-stack: %s\n' "$*" >&2
        exit 1
      }

      _docker() {
        ${pkgs.docker-client}/bin/docker "$@"
      }

      _compose() {
        if _docker compose version >/dev/null 2>&1; then
          _docker compose --project-name "$project_name" --file "$compose_file" "$@"
        else
          ${pkgs.docker-compose}/bin/docker-compose --project-name "$project_name" --file "$compose_file" "$@"
        fi
      }

      _find_rasm_root() {
        if [[ -n "''${RASM_ROOT:-}" ]]; then
          ${pkgs.coreutils}/bin/realpath "$RASM_ROOT"
          return 0
        fi

        local dir="$PWD"
        while [[ "$dir" != "/" ]]; do
          if [[ -f "$dir/pyproject.toml" && -f "$dir/Directory.Packages.props" && -d "$dir/libs/csharp" ]]; then
            printf '%s\n' "$dir"
            return 0
          fi
          dir="''${dir%/*}"
          [[ -n "$dir" ]] || dir="/"
        done

        local default_root="/Users/bardiasamiee/Documents/99.Github/Rasm"
        if [[ -f "$default_root/pyproject.toml" && -f "$default_root/Directory.Packages.props" ]]; then
          printf '%s\n' "$default_root"
          return 0
        fi

        return 1
      }

      rasm_root="$(_find_rasm_root)" || _die "could not find Rasm root; set RASM_ROOT"
      readonly rasm_root
      readonly spike_dir="$rasm_root/.artifacts/spikes/provisioning"
      readonly compose_file="$spike_dir/compose.yaml"
      readonly env_file="$spike_dir/.env"

      _write_assets() {
        ${pkgs.coreutils}/bin/mkdir -p "$spike_dir/data/timescale" "$spike_dir/data/search"
        ${pkgs.coreutils}/bin/cat >"$env_file" <<ENV
      RASM_ROOT=$rasm_root
      RASM_TIMESCALE_IMAGE=$timescale_image
      RASM_PARADEDB_IMAGE=$search_image
      RASM_TIMESCALE_PORT=$timescale_port
      RASM_SEARCH_PORT=$search_port
      RASM_POSTGRES_USER=$postgres_user
      RASM_POSTGRES_DB=$postgres_db
      ENV

        ${pkgs.coreutils}/bin/cat >"$compose_file" <<YAML
      services:
        timescale:
          image: $timescale_image
          labels:
            $owner_label: "true"
            parametric-forge.project: "Rasm"
          environment:
            POSTGRES_USER: $postgres_user
            POSTGRES_PASSWORD: $postgres_password
            POSTGRES_DB: $postgres_db
          ports:
            - "$timescale_port:5432"
          command:
            - postgres
            - -c
            - shared_preload_libraries=timescaledb
          volumes:
            - ./data/timescale:/home/postgres/pgdata/data

        search:
          image: $search_image
          labels:
            $owner_label: "true"
            parametric-forge.project: "Rasm"
          environment:
            POSTGRES_USER: $postgres_user
            POSTGRES_PASSWORD: $postgres_password
            POSTGRES_DB: $postgres_db
          ports:
            - "$search_port:5432"
          command:
            - postgres
            - -c
            - shared_preload_libraries=pg_search
          volumes:
            - ./data/search:/var/lib/postgresql/data
      YAML
      }

      _ensure_owned_project() {
        local ids id label
        ids="$(_docker ps -aq --filter "label=com.docker.compose.project=$project_name")"
        [[ -n "$ids" ]] || return 0

        while IFS= read -r id; do
          [[ -n "$id" ]] || continue
          label="$(_docker inspect --format "{{ index .Config.Labels \"$owner_label\" }}" "$id" 2>/dev/null || true)"
          [[ "$label" == "true" ]] || _die "refusing to touch unlabelled container $id in compose project $project_name"
        done <<<"$ids"
      }

      _wait_ready() {
        local service="$1"
        local attempt
        for attempt in {1..60}; do
          if _compose exec -T "$service" pg_isready -U "$postgres_user" -d "$postgres_db" >/dev/null 2>&1; then
            return 0
          fi
          ${pkgs.coreutils}/bin/sleep 1
        done
        _die "$service did not become ready"
      }

      _verify_timescale() {
        _compose exec -T timescale psql -v ON_ERROR_STOP=1 -U "$postgres_user" -d "$postgres_db" <<'SQL'
      CREATE EXTENSION IF NOT EXISTS timescaledb;
      SELECT extname FROM pg_extension WHERE extname = 'timescaledb';
      SQL
      }

      _verify_search() {
        _compose exec -T search psql -v ON_ERROR_STOP=1 -U "$postgres_user" -d "$postgres_db" <<'SQL'
      CREATE EXTENSION IF NOT EXISTS pg_search;
      SELECT extname FROM pg_extension WHERE extname = 'pg_search';
      SQL
      }

      _up() {
        _write_assets
        _ensure_owned_project
        _compose up -d
        _wait_ready timescale
        _wait_ready search
        _verify_timescale
        _verify_search
      }

      _down() {
        [[ -f "$compose_file" ]] || _write_assets
        _ensure_owned_project
        _compose down --volumes --remove-orphans
        ${pkgs.coreutils}/bin/rm -rf "$spike_dir/data"
      }

      _status() {
        [[ -f "$compose_file" ]] || _write_assets
        _ensure_owned_project
        _compose ps
      }

      _psql() {
        local service="$1"
        shift
        [[ -f "$compose_file" ]] || _write_assets
        _ensure_owned_project
        _compose exec -T "$service" psql -U "$postgres_user" -d "$postgres_db" "$@"
      }

      _env() {
        _write_assets
        cat <<ENV
      RASM_ROOT=$rasm_root
      RASM_SPIKE_DIR=$spike_dir
      RASM_SPIKE_COMPOSE=$compose_file
      RASM_TIMESCALE_DSN=postgresql://$postgres_user:$postgres_password@127.0.0.1:$timescale_port/$postgres_db
      RASM_SEARCH_DSN=postgresql://$postgres_user:$postgres_password@127.0.0.1:$search_port/$postgres_db
      ENV
      }

      command="''${1:-}"
      [[ -n "$command" ]] || {
        _usage
        exit 2
      }
      shift || true

      case "$command" in
        up) _up ;;
        down) _down ;;
        status) _status ;;
        psql-timescale) _psql timescale "$@" ;;
        psql-search) _psql search "$@" ;;
        env) _env ;;
        -h|--help|help) _usage ;;
        *) _usage; exit 2 ;;
      esac
    '';
  };
}
