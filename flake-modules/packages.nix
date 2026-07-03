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
  }: {
    packages = {
      inherit (forgePkgs) duckdb forge-provision sqlite-forge sqlean;
      default = forgePkgs.forge-provision;
    };

    apps = {
      forge-provision = {
        type = "app";
        program = forgePkgs.lib.getExe forgePkgs.forge-provision;
      };
      default = self.apps.${system}.forge-provision;
    };
  };
}
