# Title         : contracts.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : flake-modules/qa/contracts.nix
# ----------------------------------------------------------------------------
# Public flake and tool contract checks.
{
  inputs,
  self,
  ...
}: {
  perSystem = {
    forgePkgs,
    forgeRequiredCheckNames,
    system,
    ...
  }: {
    checks = {
      duckdb-smoke = forgePkgs.testers.testVersion {
        package = forgePkgs.duckdb;
        command = "duckdb --version";
        version = "v1.5.4";
      };

      duckdb-extension-smoke = forgePkgs.runCommand "duckdb-extension-smoke" {nativeBuildInputs = [forgePkgs.duckdb forgePkgs.jq];} ''
        duckdb :memory: <${../../overlays/forge-provision/sql/duckdb-extension-probe.sql} >duckdb-extensions.tsv
        grep -q 'ducklake' duckdb-extensions.tsv
        grep -q 'spatial' duckdb-extensions.tsv
        grep -Eq 'postgres(_scanner)?' duckdb-extensions.tsv
        touch "$out"
      '';

      sqlite-extension-smoke = forgePkgs.runCommand "sqlite-extension-smoke" {} ''
        rc="$TMPDIR/sqliterc"
        cat >"$rc" <<'SQLITERC'
        .load ${forgePkgs.sqlean}/lib/regexp${forgePkgs.stdenv.hostPlatform.extensions.sharedLibrary}
        .load ${forgePkgs.sqlean}/lib/uuid${forgePkgs.stdenv.hostPlatform.extensions.sharedLibrary}
        .load ${forgePkgs.sqlean}/lib/stats${forgePkgs.stdenv.hostPlatform.extensions.sharedLibrary}
        .load ${forgePkgs.sqlean}/lib/text${forgePkgs.stdenv.hostPlatform.extensions.sharedLibrary}
        .load ${forgePkgs.sqlean}/lib/time${forgePkgs.stdenv.hostPlatform.extensions.sharedLibrary}
        .load ${forgePkgs.sqlean}/lib/crypto${forgePkgs.stdenv.hostPlatform.extensions.sharedLibrary}
        .load ${forgePkgs.sqlean}/lib/math${forgePkgs.stdenv.hostPlatform.extensions.sharedLibrary}
        .load ${forgePkgs.sqlite-vec}/lib/vec0${forgePkgs.stdenv.hostPlatform.extensions.sharedLibrary}
        .load ${forgePkgs.libspatialite}/lib/mod_spatialite${forgePkgs.stdenv.hostPlatform.extensions.sharedLibrary}
        SQLITERC
        ${forgePkgs.sqlite-interactive}/bin/sqlite3 -init "$rc" :memory: \
          "select regexp_like('abc','a.c'); select vec_version(); select spatialite_version();" >/dev/null
        touch "$out"
      '';

      forge-new-tool-smoke =
        forgePkgs.runCommand "forge-new-tool-smoke" {
          nativeBuildInputs = with forgePkgs; [
            usql
            pgcli
            litecli
            sqruff
            pgformatter
            pg_activity
            pgmetrics
            qsv
            miller
            csvlens
            atlas
            pgroll
            pgloader
            pgbadger
            parquet-tools
            minio-client
            s5cmd
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
            docker-buildx
            kind
            kubectl-cnpg
            pluto
            kubent
            conftest
            kube-score
            kubescape
            kube-linter
            gmsh
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
           mlr --version >/dev/null
           csvlens --version >/dev/null
           atlas version >/dev/null
           pgroll --version >/dev/null
           pgloader --version >/dev/null
           pgbadger --version >/dev/null
           command -v parquet-tools >/dev/null
           mc --version >/dev/null
           s5cmd version >/dev/null
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
           docker-buildx version >/dev/null
           kind version >/dev/null
           command -v kubectl-cnpg >/dev/null
           pluto version >/dev/null
           kubent --version >/dev/null
           conftest --version >/dev/null
           command -v kube-score >/dev/null
           kubescape version >/dev/null
           kube-linter version >/dev/null
           gmsh -version >/dev/null
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
          in builtins.all (name: builtins.elem name names) ["duckdb" "forge-provision" "sqlean" "default"]
        '';
        expected = "true";
      };
      defaultPackageAliasesForgeProvision = {
        expr = ''forge.packages."${system}".default.outPath == forge.packages."${system}".forge-provision.outPath'';
        expected = "true";
      };
      defaultAppAliasesForgeProvision = {
        expr = ''forge.apps."${system}".default.program == forge.apps."${system}".forge-provision.program'';
        expected = "true";
      };
      packagePassthruTestsPreservePublicNames = {
        expr = ''
          let
            tests = builtins.attrNames (forge.packages."${system}".forge-provision.passthru.tests or {});
            expected = ["bats" "extensions-readonly" "help" "pgduckdb-readonly" "readonly" "self-test" "shell"];
          in tests == expected
        '';
        expected = "true";
      };
      checksPreservePublicNames = {
        expr = ''
          builtins.attrNames forge.checks."${system}" == builtins.sort builtins.lessThan ${builtins.toJSON forgeRequiredCheckNames}
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
          in builtins.all (name: builtins.hasAttr name pkgs) ["duckdb" "forge-provision" "sqlean"]
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
            nodes = builtins.attrNames (builtins.fromJSON (builtins.readFile ${../../flake.lock})).nodes;
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
