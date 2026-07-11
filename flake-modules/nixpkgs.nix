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
  perSystem = {system, ...}: {
    _module.args.forgePkgs = import inputs.nixpkgs {
      inherit system;
      overlays = [self.overlays.default];
    };
  };
}
