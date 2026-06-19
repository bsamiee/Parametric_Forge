# Title         : qa.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : flake-modules/qa.nix
# ----------------------------------------------------------------------------
# Flake checks and pure output-shape guards.
{
  inputs,
  self,
  ...
}: {
  perSystem = {
    config,
    system,
    ...
  }: let
    overlayPkgs = import inputs.nixpkgs {
      inherit system;
      overlays = [self.overlays.default];
    };
    requiredCheckNames = [
      "formatting"
      "nix-unit"
      "nix-static"
      "rasm-provision-shell"
      "rasm-provision-help"
      "rasm-provision-self-test"
      "rasm-provision-readonly"
      "rasm-provision-extensions-readonly"
      "rasm-provision-pgduckdb-readonly"
      "rasm-provision-bats"
      "duckdb-smoke"
      "sqlite-extension-smoke"
      "forge-new-tool-smoke"
    ];
  in {
    checks = {
      formatting = config.treefmt.build.check self;

      nix-static = overlayPkgs.runCommand "forge-nix-static" {nativeBuildInputs = [overlayPkgs.deadnix overlayPkgs.statix];} ''
        for target in ${../flake.nix} ${../flake-modules} ${../hosts} ${../modules} ${../overlays}; do
          deadnix --fail "$target"
          statix check "$target"
        done
        touch "$out"
      '';

      rasm-provision-shell = overlayPkgs.runCommand "rasm-provision-shell" {nativeBuildInputs = [overlayPkgs.bash overlayPkgs.shellcheck overlayPkgs.shfmt];} ''
        bash -n ${../overlays/rasm-provision/rasm-provision.sh}
        shellcheck ${../overlays/rasm-provision/rasm-provision.sh}
        shfmt -d -i 2 -ci ${../overlays/rasm-provision/rasm-provision.sh} ${../checks/rasm-provision.bats}
        touch "$out"
      '';

      rasm-provision-help = overlayPkgs.runCommand "rasm-provision-help" {} ''
        ${overlayPkgs.rasm-provision}/bin/rasm-provision --help >out
        grep -q 'Usage: rasm-provision' out
        grep -q 'psql <timescale|search|pgduckdb>' out
        ! grep -q 'psql-timescale' out
        ! grep -q 'psql-search' out
        ! grep -q 'psql-pgduckdb' out
        touch "$out"
      '';

      rasm-provision-self-test = overlayPkgs.runCommand "rasm-provision-self-test" {} ''
        mkdir -p fake-root/libs/csharp
        touch fake-root/pyproject.toml fake-root/Directory.Packages.props
        RASM_ROOT="$PWD/fake-root" RASM_PROVISION_ALLOW_EPHEMERAL_PORTS=1 ${overlayPkgs.rasm-provision}/bin/rasm-provision self-test >out
        RASM_ROOT="$PWD/fake-root" RASM_PROVISION_ALLOW_EPHEMERAL_PORTS=1 ${overlayPkgs.rasm-provision}/bin/rasm-provision --json self-test >self-test.json
        grep -q $'self-test\tok' out
        ${overlayPkgs.jq}/bin/jq -e '.schemaVersion == 2 and .command == "self-test" and .ok == true and .checks.gnuCoreutils == true' self-test.json >/dev/null
        touch "$out"
      '';

      rasm-provision-readonly = overlayPkgs.runCommand "rasm-provision-readonly" {} ''
        mkdir -p fake-root/libs/csharp
        touch fake-root/pyproject.toml fake-root/Directory.Packages.props
        RASM_ROOT="$PWD/fake-root" RASM_PROVISION_ALLOW_EPHEMERAL_PORTS=1 ${overlayPkgs.rasm-provision}/bin/rasm-provision --json env >env.json
        RASM_ROOT="$PWD/fake-root" RASM_PROVISION_ALLOW_EPHEMERAL_PORTS=1 ${overlayPkgs.rasm-provision}/bin/rasm-provision --json plan >plan.json
        RASM_ROOT="$PWD/fake-root" RASM_PROVISION_ALLOW_EPHEMERAL_PORTS=1 ${overlayPkgs.rasm-provision}/bin/rasm-provision plan >compose.yaml
        test ! -e fake-root/.artifacts
        ${overlayPkgs.jq}/bin/jq -e '
          .schemaVersion == 2
          and .auth.mode == "auto-root"
          and .auth.agentPromptRequired == false
          and .portPolicy.mode == "auto"
          and (.services.timescale.dsnRedacted | contains("***"))
          and (.paths.redacted == true)
        ' env.json >/dev/null
        ${overlayPkgs.jq}/bin/jq -e '
          .schemaVersion == 2
          and .command == "plan"
          and .ok == true
          and (.artifacts.generated | type == "array")
          and (.services.timescale.port | type == "number")
          and (.services.search.image == "paradedb/paradedb:0.24.0-pg18")
        ' plan.json >/dev/null
        ! grep -q 'POSTGRES_PASSWORD=' compose.yaml
        grep -q 'POSTGRES_PASSWORD_FILE' compose.yaml
        grep -q 'host_ip: 127.0.0.1' compose.yaml
        grep -q 'name: rasm-provision-' compose.yaml
        grep -q 'paradedb/paradedb:0.24.0-pg18' compose.yaml
        ${overlayPkgs.docker-compose}/bin/docker-compose -f compose.yaml config >/dev/null
        touch "$out"
      '';

      rasm-provision-extensions-readonly = overlayPkgs.runCommand "rasm-provision-extensions-readonly" {} ''
        mkdir -p fake-root/libs/csharp
        touch fake-root/pyproject.toml fake-root/Directory.Packages.props
        RASM_ROOT="$PWD/fake-root" RASM_PROVISION_ALLOW_EPHEMERAL_PORTS=1 RASM_PROVISION_PGDUCKDB=1 RASM_PROVISION_PG_CRON=1 ${overlayPkgs.rasm-provision}/bin/rasm-provision --json extensions >extensions.json
        ${overlayPkgs.jq}/bin/jq -e '
          . as $root
          |
          .ok == true
          and .schemaVersion == 2
          and (.extensions | length > 50)
          and ([.extensions[] | select(.required == true and .createOnVerify == true)] | length >= 7)
          and ([.extensions[] | select(.service == "pgduckdb" and .extension == "pg_duckdb" and .required == true)] | length == 1)
          and ([.extensions[] | select(.service == "timescale" and .extension == "pg_cron" and .required == true and .createOnVerify == true and .preloadRequired == true and .sourcePackage != null)] | length == 1)
          and ([.extensions[] | select(has("createPolicy") and has("riskClass") and has("sourcePackage"))] | length == ($root.extensions | length))
          and ([.extensions[] | select(has("sourceRoute") and has("nixStatus") and has("probeKind") and has("capabilityRank") and has("externalAccess") and has("restartClass") and has("serviceProfile") and has("loadPolicy"))] | length == ($root.extensions | length))
        ' extensions.json >/dev/null
        test ! -e fake-root/.artifacts
        touch "$out"
      '';

      rasm-provision-pgduckdb-readonly = overlayPkgs.runCommand "rasm-provision-pgduckdb-readonly" {} ''
        mkdir -p fake-root/libs/csharp
        touch fake-root/pyproject.toml fake-root/Directory.Packages.props
        RASM_ROOT="$PWD/fake-root" RASM_PROVISION_ALLOW_EPHEMERAL_PORTS=1 RASM_PROVISION_PGDUCKDB=1 ${overlayPkgs.rasm-provision}/bin/rasm-provision --json env >env.json
        RASM_ROOT="$PWD/fake-root" RASM_PROVISION_ALLOW_EPHEMERAL_PORTS=1 RASM_PROVISION_PGDUCKDB=1 ${overlayPkgs.rasm-provision}/bin/rasm-provision plan >compose.yaml
        ${overlayPkgs.jq}/bin/jq -e '.services.pgduckdb.enabled == true and .RASM_PROVISION_PGDUCKDB == "1"' env.json >/dev/null
        ${overlayPkgs.docker-compose}/bin/docker-compose -f compose.yaml config >/dev/null
        test ! -e fake-root/.artifacts
        touch "$out"
      '';

      rasm-provision-bats = overlayPkgs.runCommand "rasm-provision-bats" {nativeBuildInputs = [overlayPkgs.bats overlayPkgs.jq];} ''
        export RASM_PROVISION_BIN=${overlayPkgs.rasm-provision}/bin/rasm-provision
        bats ${../checks/rasm-provision.bats}
        touch "$out"
      '';

      duckdb-smoke = overlayPkgs.testers.testVersion {
        package = overlayPkgs.duckdb;
        command = "duckdb --version";
        version = "v1.5.4";
      };

      sqlite-extension-smoke = overlayPkgs.runCommand "sqlite-extension-smoke" {} ''
        rc="$TMPDIR/sqliterc"
        cat >"$rc" <<'SQLITERC'
        .load ${overlayPkgs.sqlean}/lib/regexp${overlayPkgs.stdenv.hostPlatform.extensions.sharedLibrary}
        .load ${overlayPkgs.sqlean}/lib/uuid${overlayPkgs.stdenv.hostPlatform.extensions.sharedLibrary}
        .load ${overlayPkgs.sqlean}/lib/stats${overlayPkgs.stdenv.hostPlatform.extensions.sharedLibrary}
        .load ${overlayPkgs.sqlean}/lib/text${overlayPkgs.stdenv.hostPlatform.extensions.sharedLibrary}
        .load ${overlayPkgs.sqlean}/lib/time${overlayPkgs.stdenv.hostPlatform.extensions.sharedLibrary}
        .load ${overlayPkgs.sqlean}/lib/crypto${overlayPkgs.stdenv.hostPlatform.extensions.sharedLibrary}
        .load ${overlayPkgs.sqlean}/lib/math${overlayPkgs.stdenv.hostPlatform.extensions.sharedLibrary}
        .load ${overlayPkgs.sqlite-vec}/lib/vec0${overlayPkgs.stdenv.hostPlatform.extensions.sharedLibrary}
        .load ${overlayPkgs.libspatialite}/lib/mod_spatialite${overlayPkgs.stdenv.hostPlatform.extensions.sharedLibrary}
        SQLITERC
        ${overlayPkgs.sqlite-interactive}/bin/sqlite3 -init "$rc" :memory: \
          "select regexp_like('abc','a.c'); select vec_version(); select spatialite_version();" >/dev/null
        touch "$out"
      '';

      forge-new-tool-smoke =
        overlayPkgs.runCommand "forge-new-tool-smoke" {
          nativeBuildInputs = with overlayPkgs; [
            usql
            pgcli
            litecli
            sqruff
            pgformatter
            pg_activity
            pgmetrics
            qsv
            hurl
            grpcurl
            taplo
            typos
            cosign
            notation
            oras
            regctl
            syft
            trivy
            grype
          ];
        } ''
          usql --version >/dev/null
          pgcli --version >/dev/null
          litecli --version >/dev/null
          sqruff --version >/dev/null
          pg_format --version >/dev/null
          pg_activity --version >/dev/null
          pgmetrics --version >/dev/null
          qsv --version >/dev/null
          hurl --version >/dev/null
          grpcurl --version >/dev/null
          taplo --version >/dev/null
          typos --version >/dev/null
          cosign version >/dev/null
          notation version >/dev/null
          oras version >/dev/null
          regctl version >/dev/null
          syft version >/dev/null
          trivy --version >/dev/null
          grype version >/dev/null
          touch "$out"
        '';
    };

    nix-unit.inputs = {
      inherit (inputs) flake-parts nix-unit nixpkgs;
      forge = self;
    };
    nix-unit.tests = {
      packagesExposePublicTools = {
        expr = ''
          let
            names = builtins.attrNames forge.packages."${system}";
          in builtins.all (name: builtins.elem name names) ["duckdb" "rasm-provision" "sqlean" "default"]
        '';
        expected = "true";
      };
      defaultPackageAliasesRasmProvision = {
        expr = ''forge.packages."${system}".default.outPath == forge.packages."${system}".rasm-provision.outPath'';
        expected = "true";
      };
      defaultAppAliasesRasmProvision = {
        expr = ''forge.apps."${system}".default.program == forge.apps."${system}".rasm-provision.program'';
        expected = "true";
      };
      packagePassthruTestsPreservePublicNames = {
        expr = ''
          let
            tests = builtins.attrNames (forge.packages."${system}".rasm-provision.passthru.tests or {});
            expected = ["bats" "extensions-readonly" "help" "pgduckdb-readonly" "readonly" "self-test" "shell"];
          in tests == expected
        '';
        expected = "true";
      };
      checksPreservePublicNames = {
        expr = ''
          builtins.attrNames forge.checks."${system}" == builtins.sort builtins.lessThan ${builtins.toJSON requiredCheckNames}
        '';
        expected = "true";
      };
      overlayExposesProvisioningAttrs = {
        expr = ''
          let
            pkgs = import nixpkgs {
              system = "${system}";
              overlays = [forge.overlays.default];
            };
          in builtins.all (name: builtins.hasAttr name pkgs) ["duckdb" "rasm-provision" "sqlean"]
        '';
        expected = "true";
      };
      darwinMacbookConfigurationExists = {
        expr = ''builtins.hasAttr "macbook" forge.darwinConfigurations'';
        expected = "true";
      };
      noRejectedFlakeInputs = {
        expr = ''
          let
            nodes = builtins.attrNames (builtins.fromJSON (builtins.readFile ${../flake.lock})).nodes;
          in !(builtins.elem "devenv" nodes)
            && !(builtins.elem "services-flake" nodes)
            && !(builtins.elem "arion" nodes)
            && !(builtins.elem "process-compose" nodes)
            && !(builtins.elem "crane" nodes)
        '';
        expected = "true";
      };
    };
  };
}
