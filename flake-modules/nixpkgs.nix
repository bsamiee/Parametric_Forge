# Title         : nixpkgs.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : flake-modules/nixpkgs.nix
# ----------------------------------------------------------------------------
# Overlay-aware package set shared by flake modules.
{
  inputs,
  self,
  ...
}: {
  perSystem = {system, ...}: let
    forgePkgs = import inputs.nixpkgs {
      inherit system;
      overlays = [self.overlays.default];
    };
  in {
    _module.args.forgePkgs = forgePkgs;
    # Overlaid set as legacyPackages: `nix build .#<attr>` reaches overlay attrs without a public-package projection, and flake check never
    # recurses legacyPackages — uncached-by-design attrs (forge-python-overlay-env) stay out of the qa build smoke.
    legacyPackages = forgePkgs;
  };
}
