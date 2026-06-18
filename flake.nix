# Title         : flake.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /flake.nix
# ----------------------------------------------------------------------------
# Pure entry point - delegates all logic to modules
{
  description = "Unified NixOS + nix-darwin + Home Manager";

  # --- Inputs ---------------------------------------------------------------
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # 1Password Shell Plugins - biometric auth for CLI tools (gh, aws, etc.)
    shell-plugins = {
      url = "github:1Password/shell-plugins";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # --- Outputs ----------------------------------------------------------------
  outputs = inputs @ {
    self,
    nixpkgs,
    nix-darwin,
    home-manager,
    ...
  }: let
    systems = ["aarch64-darwin" "x86_64-linux" "aarch64-linux"];
    forAllSystems = nixpkgs.lib.genAttrs systems;
  in {
    overlays.default = import ./overlays;
    darwinConfigurations = import ./hosts/darwin {inherit inputs nix-darwin home-manager;};
    # NixOS configurations (placeholder for future)
    nixosConfigurations = {};
    # Standalone home configurations (placeholder for future)
    homeConfigurations = {};

    packages = forAllSystems (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [self.overlays.default];
      };
    in {
      inherit (pkgs) duckdb rasm-provision sqlean;
      default = pkgs.rasm-provision;
    });

    apps = forAllSystems (system: {
      rasm-provision = {
        type = "app";
        program = nixpkgs.lib.getExe self.packages.${system}.rasm-provision;
      };
      default = self.apps.${system}.rasm-provision;
    });

    checks = forAllSystems (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [self.overlays.default];
      };
    in {
      rasm-provision-help = pkgs.runCommand "rasm-provision-help" {} ''
        ${pkgs.rasm-provision}/bin/rasm-provision --help >out
        grep -q 'Usage: rasm-provision' out
        touch "$out"
      '';
      rasm-provision-self-test = pkgs.runCommand "rasm-provision-self-test" {} ''
        mkdir -p fake-root/libs/csharp
        touch fake-root/pyproject.toml fake-root/Directory.Packages.props
        RASM_ROOT="$PWD/fake-root" ${pkgs.rasm-provision}/bin/rasm-provision self-test >out
        grep -q $'self-test\tok' out
        touch "$out"
      '';
      rasm-provision-readonly = pkgs.runCommand "rasm-provision-readonly" {} ''
        mkdir -p fake-root/libs/csharp
        touch fake-root/pyproject.toml fake-root/Directory.Packages.props
        RASM_ROOT="$PWD/fake-root" ${pkgs.rasm-provision}/bin/rasm-provision env --json >env.json
        RASM_ROOT="$PWD/fake-root" ${pkgs.rasm-provision}/bin/rasm-provision plan >compose.yaml
        test ! -e fake-root/.artifacts
        grep -q '"schemaVersion"' env.json
        grep -q '"RASM_PROVISION_DIR"' env.json
        grep -q '"services"' env.json
        grep -q '.artifacts/provisioning/rasm' env.json
        grep -q 'name: rasm-provision-' compose.yaml
        touch "$out"
      '';
      rasm-provision-extensions-readonly = pkgs.runCommand "rasm-provision-extensions-readonly" {} ''
        mkdir -p fake-root/libs/csharp
        touch fake-root/pyproject.toml fake-root/Directory.Packages.props
        RASM_ROOT="$PWD/fake-root" RASM_PROVISION_PGDUCKDB=1 ${pkgs.rasm-provision}/bin/rasm-provision extensions --json >extensions.json
        ${pkgs.jq}/bin/jq -e '
          .ok == true
          and (.extensions | length > 50)
          and ([.extensions[] | select(.required == true and .createOnVerify == true)] | length >= 7)
          and ([.extensions[] | select(.service == "pgduckdb" and .extension == "pg_duckdb" and .required == true)] | length == 1)
        ' extensions.json >/dev/null
        test ! -e fake-root/.artifacts
        touch "$out"
      '';
      rasm-provision-pgduckdb-readonly = pkgs.runCommand "rasm-provision-pgduckdb-readonly" {} ''
        mkdir -p fake-root/libs/csharp
        touch fake-root/pyproject.toml fake-root/Directory.Packages.props
        RASM_ROOT="$PWD/fake-root" RASM_PROVISION_PGDUCKDB=1 ${pkgs.rasm-provision}/bin/rasm-provision env --json >env.json
        RASM_ROOT="$PWD/fake-root" RASM_PROVISION_PGDUCKDB=1 ${pkgs.rasm-provision}/bin/rasm-provision plan >compose.yaml
        ${pkgs.jq}/bin/jq -e '.services.pgduckdb.enabled == true and .RASM_PROVISION_PGDUCKDB == "1"' env.json >/dev/null
        ${pkgs.docker-compose}/bin/docker-compose -f compose.yaml config >/dev/null
        test ! -e fake-root/.artifacts
        touch "$out"
      '';
      duckdb-smoke = pkgs.runCommand "duckdb-smoke" {} ''
        ${pkgs.duckdb}/bin/duckdb --version | grep -q 'v1.5.3'
        touch "$out"
      '';
      sqlite-extension-smoke = pkgs.runCommand "sqlite-extension-smoke" {} ''
        rc="$TMPDIR/sqliterc"
        cat >"$rc" <<'SQLITERC'
        .load ${pkgs.sqlean}/lib/regexp${pkgs.stdenv.hostPlatform.extensions.sharedLibrary}
        .load ${pkgs.sqlite-vec}/lib/vec0${pkgs.stdenv.hostPlatform.extensions.sharedLibrary}
        .load ${pkgs.libspatialite}/lib/mod_spatialite${pkgs.stdenv.hostPlatform.extensions.sharedLibrary}
        SQLITERC
        ${pkgs.sqlite-interactive}/bin/sqlite3 -init "$rc" :memory: \
          "select regexp_like('abc','a.c'); select vec_version(); select spatialite_version();" >/dev/null
        touch "$out"
      '';
    });

    devShells = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      default = pkgs.mkShell {
        packages = with pkgs; [git alejandra statix deadnix nix-output-monitor];
      };
    });

    formatter = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in
      pkgs.writeShellApplication {
        name = "forge-fmt";
        runtimeInputs = [pkgs.alejandra];
        text = ''
          if [ "$#" -eq 0 ]; then
            set -- .
          fi

          exec alejandra "$@"
        '';
      });
  };
}
