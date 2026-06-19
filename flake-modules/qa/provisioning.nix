# Title         : provisioning.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : flake-modules/qa/provisioning.nix
# ----------------------------------------------------------------------------
# Forge provisioner checks.
_: {
  perSystem = {forgePkgs, ...}: {
    checks = {
      forge-provision-shell = forgePkgs.runCommand "forge-provision-shell" {nativeBuildInputs = [forgePkgs.bash forgePkgs.gawk forgePkgs.shellcheck];} ''
        bash -n ${../../overlays/forge-provision/forge-provision.sh}
        bash -n ${../../overlays/forge-provision/bash/docker-projection.sh}
        shellcheck ${../../overlays/forge-provision/forge-provision.sh}
        cp -R ${../../overlays/forge-provision} source-tree
        chmod -R u+w source-tree
        if bash source-tree/forge-provision.sh --json self-test >raw-source.out 2>raw-source.err; then
          echo "raw source execution unexpectedly succeeded" >&2
          exit 1
        fi
        grep -q 'source-tree execution is unsupported; use the packaged command' raw-source.err
        grep -q 'From a consumer repo: use that repo' raw-source.err
        awk -v projection=${../../overlays/forge-provision/bash/docker-projection.sh} '
          $0 == "source \"$(catalog_path bash/docker-projection.sh)\"" {
            while ((getline line < projection) > 0) print line
            close(projection)
            next
          }
          { print }
        ' ${../../overlays/forge-provision/forge-provision.sh} >composed.sh
        shellcheck composed.sh
        touch "$out"
      '';

      forge-provision-help = forgePkgs.runCommand "forge-provision-help" {} ''
        ${forgePkgs.forge-provision}/bin/forge-provision --help >out
        grep -q 'Usage: forge-provision' out
        grep -q 'psql <timescale|search|pgduckdb>' out
        ! grep -q 'psql-timescale' out
        ! grep -q 'psql-search' out
        ! grep -q 'psql-pgduckdb' out
        touch "$out"
      '';

      forge-provision-self-test = forgePkgs.runCommand "forge-provision-self-test" {} ''
        mkdir -p fake-root/libs/csharp
        touch fake-root/pyproject.toml fake-root/Directory.Packages.props
        FORGE_PROVISION_ROOT="$PWD/fake-root" FORGE_PROVISION_ALLOW_EPHEMERAL_PORTS=1 ${forgePkgs.forge-provision}/bin/forge-provision self-test >out
        FORGE_PROVISION_ROOT="$PWD/fake-root" FORGE_PROVISION_ALLOW_EPHEMERAL_PORTS=1 ${forgePkgs.forge-provision}/bin/forge-provision --json self-test >self-test.json
        grep -q $'self-test\tok' out
        ${forgePkgs.jq}/bin/jq -e '.schemaVersion == 3 and .command == "self-test" and .ok == true and .checks.gnuCoreutils == true' self-test.json >/dev/null
        touch "$out"
      '';

      forge-provision-readonly = forgePkgs.runCommand "forge-provision-readonly" {} ''
        mkdir -p fake-root/libs/csharp
        touch fake-root/pyproject.toml fake-root/Directory.Packages.props
        FORGE_PROVISION_ROOT="$PWD/fake-root" FORGE_PROVISION_ALLOW_EPHEMERAL_PORTS=1 ${forgePkgs.forge-provision}/bin/forge-provision --json env >env.json
        FORGE_PROVISION_ROOT="$PWD/fake-root" FORGE_PROVISION_ALLOW_EPHEMERAL_PORTS=1 ${forgePkgs.forge-provision}/bin/forge-provision --json plan >plan.json
        FORGE_PROVISION_ROOT="$PWD/fake-root" FORGE_PROVISION_ALLOW_EPHEMERAL_PORTS=1 ${forgePkgs.forge-provision}/bin/forge-provision plan >compose.yaml
        test ! -e fake-root/.artifacts
        ${forgePkgs.jq}/bin/jq -e '
          .schemaVersion == 3
          and .auth.mode == "auto-root"
          and .auth.agentPromptRequired == false
          and .portPolicy.mode == "auto"
          and (.services.timescale.dsnRedacted | contains("***"))
          and (.artifacts.generated | type == "array")
          and (has("FORGE_PROVISION_PROJECT") | not)
        ' env.json >/dev/null
        ${forgePkgs.jq}/bin/jq -e '
          .schemaVersion == 3
          and .command == "plan"
          and .ok == true
          and (.artifacts.generated | type == "array")
          and (.services.timescale.port | type == "number")
          and (.services.search.image == "paradedb/paradedb:0.24.0-pg18")
        ' plan.json >/dev/null
        ! grep -q 'POSTGRES_PASSWORD=' compose.yaml
        grep -q 'POSTGRES_PASSWORD_FILE' compose.yaml
        grep -q 'host_ip: 127.0.0.1' compose.yaml
        grep -q 'name: forge-' compose.yaml
        grep -q 'paradedb/paradedb:0.24.0-pg18' compose.yaml
        ${forgePkgs.docker-compose}/bin/docker-compose -f compose.yaml config >/dev/null
        touch "$out"
      '';

      forge-provision-extensions-readonly = forgePkgs.runCommand "forge-provision-extensions-readonly" {} ''
        mkdir -p fake-root/libs/csharp
        touch fake-root/pyproject.toml fake-root/Directory.Packages.props
        FORGE_PROVISION_ROOT="$PWD/fake-root" FORGE_PROVISION_ALLOW_EPHEMERAL_PORTS=1 FORGE_PROVISION_PGDUCKDB=1 FORGE_PROVISION_PG_CRON=1 ${forgePkgs.forge-provision}/bin/forge-provision --json extensions >extensions.json
        ${forgePkgs.jq}/bin/jq -e '
          . as $root
          |
          .ok == true
          and .schemaVersion == 3
          and (.extensions.catalog | length > 50)
          and ([.extensions.catalog[] | select(.required == true and .createOnApply == true)] | length >= 6)
          and ([.extensions.catalog[] | select(.service == "pgduckdb" and .extension == "pg_duckdb" and .required == true)] | length == 1)
          and ([.extensions.catalog[] | select(.service == "timescale" and .extension == "pg_cron" and .required == true and .createOnApply == true and .preloadRequired == true and .sourcePackage != null)] | length == 1)
          and ([.extensions.catalog[] | select(has("createPolicy") and has("riskClass") and has("sourcePackage"))] | length == ($root.extensions.catalog | length))
          and ([.extensions.catalog[] | select(has("sourceRoute") and has("nixStatus") and has("probeKind") and has("capabilityRank") and has("externalAccess") and has("restartClass") and has("serviceProfile") and has("loadPolicy"))] | length == ($root.extensions.catalog | length))
        ' extensions.json >/dev/null
        test ! -e fake-root/.artifacts
        touch "$out"
      '';

      forge-provision-pgduckdb-readonly = forgePkgs.runCommand "forge-provision-pgduckdb-readonly" {} ''
        mkdir -p fake-root/libs/csharp
        touch fake-root/pyproject.toml fake-root/Directory.Packages.props
        FORGE_PROVISION_ROOT="$PWD/fake-root" FORGE_PROVISION_ALLOW_EPHEMERAL_PORTS=1 FORGE_PROVISION_PGDUCKDB=1 ${forgePkgs.forge-provision}/bin/forge-provision --json env >env.json
        FORGE_PROVISION_ROOT="$PWD/fake-root" FORGE_PROVISION_ALLOW_EPHEMERAL_PORTS=1 FORGE_PROVISION_PGDUCKDB=1 ${forgePkgs.forge-provision}/bin/forge-provision plan >compose.yaml
        ${forgePkgs.jq}/bin/jq -e '.services.pgduckdb.enabled == true and (has("FORGE_PROVISION_PGDUCKDB") | not)' env.json >/dev/null
        ${forgePkgs.docker-compose}/bin/docker-compose -f compose.yaml config >/dev/null
        test ! -e fake-root/.artifacts
        touch "$out"
      '';

      forge-provision-tools-readonly = forgePkgs.runCommand "forge-provision-tools-readonly" {} ''
        mkdir -p fake-root/libs/csharp
        touch fake-root/pyproject.toml fake-root/Directory.Packages.props
        FORGE_PROVISION_ROOT="$PWD/fake-root" FORGE_PROVISION_ALLOW_EPHEMERAL_PORTS=1 ${forgePkgs.forge-provision}/bin/forge-provision --json tools >tools.json
        FORGE_PROVISION_ROOT="$PWD/fake-root" FORGE_PROVISION_ALLOW_EPHEMERAL_PORTS=1 ${forgePkgs.forge-provision}/bin/forge-provision tools --surface duckdb --json >duckdb.json
        FORGE_PROVISION_ROOT="$PWD/fake-root" FORGE_PROVISION_ALLOW_EPHEMERAL_PORTS=1 ${forgePkgs.forge-provision}/bin/forge-provision --json tools --surface sqlite >sqlite.json
        ${forgePkgs.jq}/bin/jq -e '
          .schemaVersion == 3
          and .command == "tools"
          and .ok == true
          and (.tools.surfaces.duckdb.ok == true)
          and (.tools.surfaces.sqlite.ok == true)
          and (.tools.summary.catalogRows >= 30)
          and (has("generated") | not)
          and (has("owned") | not)
          and (has("containers") | not)
        ' tools.json >/dev/null
        ${forgePkgs.jq}/bin/jq -e '.tools.surfaces | keys == ["duckdb"]' duckdb.json >/dev/null
        ${forgePkgs.jq}/bin/jq -e '.tools.surfaces | keys == ["sqlite"]' sqlite.json >/dev/null
        test ! -e fake-root/.artifacts
        touch "$out"
      '';

      forge-provision-assets = forgePkgs.runCommand "forge-provision-assets" {nativeBuildInputs = [forgePkgs.duckdb forgePkgs.jq forgePkgs.sqlfluff forgePkgs.sqlite-forge];} ''
        jq empty ${../../overlays/forge-provision/data}/*.json
        jq -s 'add | length == 36 and (map(.surface + ":" + .extension) | unique | length) == 36' \
          ${../../overlays/forge-provision/data/duckdb-extensions.json} \
          ${../../overlays/forge-provision/data/sqlite-extensions.json} >/dev/null
        printf 'timescale\ttime\t1\ttimescale\timage\t15432\tdsn\tFORGE_DSN\tFORGE_IMAGE\tFORGE_PORT\tauto\n' \
          | jq -Rsc -f ${../../overlays/forge-provision/jq/service-records.jq} >/dev/null
        printf 'timescale\ttime\t1\ttimescale\timage\t15432\tdsn\tFORGE_DSN\tFORGE_IMAGE\tFORGE_PORT\tauto\n' \
          | jq -Rsc -f ${../../overlays/forge-provision/jq/configured-images.jq} >/dev/null
        printf 'timescale\tpostgis\tok\t3.6\tgeospatial\trequired\n' \
          | jq -Rsc -f ${../../overlays/forge-provision/jq/apply-rows.jq} >/dev/null
        jq -s 'add | sort_by(.surface, .category, .extension) | all(.[]; .kind == "tool-extension" and .surface != null and .database != null)' \
          ${../../overlays/forge-provision/data/duckdb-extensions.json} \
          ${../../overlays/forge-provision/data/sqlite-extensions.json} >/dev/null
        jq -nc -f ${../../overlays/forge-provision/jq/port-record.jq} \
          --arg service timescale \
          --arg env FORGE_PROVISION_TIMESCALE_PORT \
          --arg port 15432 \
          --arg source auto \
          --arg state free \
          --argjson occupied false \
          --arg owner none \
          --arg container_id "" \
          --arg name "" \
          --arg image "" \
          --arg compose_project "" \
          --arg compose_service "" \
          --arg provision_project "" \
          --arg host_listener_pid "" >/dev/null
        printf 'POSTGRES_PASSWORD=x DOCKER_HOST=unix:///Users/a/.docker/docker.sock token ghp_abcdefghijklmnopqrstuvwxyz /tmp/file\n' \
          | jq -Rr -f ${../../overlays/forge-provision/jq/redact-message.jq} \
          | grep -qv '/Users\|/tmp\|docker.sock\|ghp_'
        jq -nc -f ${../../overlays/forge-provision/jq/colima-status.jq} \
          --argjson status '{"arch":"aarch64","runtime":"docker","driver":"vz","kubernetes":false,"docker_socket":"unix:///Users/a/.colima/docker.sock","containerd_socket":"unix:///Users/a/.colima/containerd.sock"}' \
          --argjson diagnostic true \
          | jq -e '.status.kubernetes == false and .status.dockerSocketRedacted == true and .status.containerdSocketRedacted == true and ([.. | scalars? | tostring | select(test("/Users|docker.sock"))] | length == 0)' >/dev/null
        duckdb :memory: <${../../overlays/forge-provision/sql/duckdb-extension-probe.sql} >/dev/null
        SQLITE_FORGE_PROFILE=safe sqlite-forge -bail :memory: <${../../overlays/forge-provision/sql/sqlite-extension-probe.sql} >/dev/null
        sed -e "s/__FORGE_EXTENSION_VALUES__/(1,'postgis','geospatial',true,true,'apply-create','apply-create','postgis-full-version','postgis-full-version',false)/" \
          -e "s/__FORGE_CONTEXT_SQL__/'ctx'/g" \
          -e "s/__FORGE_SERVICE_SQL__/'timescale'/g" \
          ${../../overlays/forge-provision/sql/apply-postgres.sql} >apply-postgres.sql
        sqlfluff parse --dialect postgres apply-postgres.sql >/dev/null
        sed -e "s/__FORGE_EXTENSION_VALUES__/(1,'postgis','geospatial',true,true,'apply-create','apply-create','postgis-full-version','postgis-full-version',false)/" \
          -e "s/__FORGE_SERVICE_SQL__/'timescale'/g" \
          ${../../overlays/forge-provision/sql/check-postgres.sql} >check-postgres.sql
        sqlfluff parse --dialect postgres check-postgres.sql >/dev/null
        touch "$out"
      '';

      forge-provision-bats = forgePkgs.runCommand "forge-provision-bats" {nativeBuildInputs = [forgePkgs.bash forgePkgs.bats forgePkgs.coreutils forgePkgs.jq];} ''
        export FORGE_PROVISION_BIN=${forgePkgs.forge-provision}/bin/forge-provision
        bats ${../../checks/forge-provision.bats}
        touch "$out"
      '';
    };
  };
}
