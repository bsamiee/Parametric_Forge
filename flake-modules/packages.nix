# Title         : packages.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : flake-modules/packages.nix
# ----------------------------------------------------------------------------
# Public packages and apps.
{
  inputs,
  self,
  ...
}: {
  perSystem = {system, ...}: let
    overlayPkgs = import inputs.nixpkgs {
      inherit system;
      overlays = [self.overlays.default];
    };
    rasmProvisionWithTests = overlayPkgs.rasm-provision.overrideAttrs (old: {
      passthru =
        (old.passthru or {})
        // {
          tests = {
            shell = self.checks.${system}.rasm-provision-shell;
            help = self.checks.${system}.rasm-provision-help;
            self-test = self.checks.${system}.rasm-provision-self-test;
            readonly = self.checks.${system}.rasm-provision-readonly;
            extensions-readonly = self.checks.${system}.rasm-provision-extensions-readonly;
            pgduckdb-readonly = self.checks.${system}.rasm-provision-pgduckdb-readonly;
            bats = self.checks.${system}.rasm-provision-bats;
          };
        };
    });
    duckdbWithTests = overlayPkgs.duckdb.overrideAttrs (old: {
      passthru =
        (old.passthru or {})
        // {
          tests.smoke = self.checks.${system}.duckdb-smoke;
        };
    });
    sqleanWithTests = overlayPkgs.sqlean.overrideAttrs (old: {
      passthru =
        (old.passthru or {})
        // {
          tests.sqlite-extension-smoke = self.checks.${system}.sqlite-extension-smoke;
        };
    });
  in {
    packages = {
      duckdb = duckdbWithTests;
      rasm-provision = rasmProvisionWithTests;
      sqlean = sqleanWithTests;
      default = rasmProvisionWithTests;
    };

    apps = {
      rasm-provision = {
        type = "app";
        program = inputs.nixpkgs.lib.getExe self.packages.${system}.rasm-provision;
      };
      default = self.apps.${system}.rasm-provision;
    };
  };
}
