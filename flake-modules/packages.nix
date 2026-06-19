# Title         : packages.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : flake-modules/packages.nix
# ----------------------------------------------------------------------------
# Public packages and apps.
{self, ...}: {
  perSystem = {
    forgePkgs,
    system,
    ...
  }: let
    forgeProvisionWithTests = forgePkgs.forge-provision.overrideAttrs (old: {
      passthru =
        (old.passthru or {})
        // {
          tests = {
            shell = self.checks.${system}.forge-provision-shell;
            help = self.checks.${system}.forge-provision-help;
            self-test = self.checks.${system}.forge-provision-self-test;
            readonly = self.checks.${system}.forge-provision-readonly;
            extensions-readonly = self.checks.${system}.forge-provision-extensions-readonly;
            pgduckdb-readonly = self.checks.${system}.forge-provision-pgduckdb-readonly;
            bats = self.checks.${system}.forge-provision-bats;
          };
        };
    });
    duckdbWithTests = forgePkgs.duckdb.overrideAttrs (old: {
      passthru =
        (old.passthru or {})
        // {
          tests.smoke = self.checks.${system}.duckdb-smoke;
        };
    });
    sqleanWithTests = forgePkgs.sqlean.overrideAttrs (old: {
      passthru =
        (old.passthru or {})
        // {
          tests.sqlite-extension-smoke = self.checks.${system}.sqlite-extension-smoke;
        };
    });
  in {
    packages = {
      duckdb = duckdbWithTests;
      forge-provision = forgeProvisionWithTests;
      sqlean = sqleanWithTests;
      default = forgeProvisionWithTests;
    };

    apps = {
      forge-provision = {
        type = "app";
        program = forgePkgs.lib.getExe self.packages.${system}.forge-provision;
      };
      default = self.apps.${system}.forge-provision;
    };
  };
}
