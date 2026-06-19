# Title         : static.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : flake-modules/qa/static.nix
# ----------------------------------------------------------------------------
# Formatting and Nix static checks.
{self, ...}: {
  perSystem = {
    config,
    forgePkgs,
    ...
  }: {
    checks = {
      formatting = config.treefmt.build.check self;

      nix-static = forgePkgs.runCommand "forge-nix-static" {nativeBuildInputs = [forgePkgs.deadnix forgePkgs.statix];} ''
        for target in ${../../flake.nix} ${../../flake-modules} ${../../hosts} ${../../modules} ${../../overlays}; do
          deadnix --fail "$target"
          statix check "$target"
        done
        touch "$out"
      '';
    };
  };
}
