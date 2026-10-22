# Title         : nixpkgs.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : flake-modules/nixpkgs.nix
# ----------------------------------------------------------------------------
# The one nixpkgs instantiation: perSystem `pkgs` (overlay + unfree) feeds packages, checks, treefmt, legacyPackages, and every host through
# nixpkgs.pkgs (flake-modules/hosts.nix).
{
  inputs,
  self,
  ...
}: {
  perSystem = {system, ...}: let
    pkgs = import inputs.nixpkgs {
      inherit system;
      overlays = [self.overlays.default];
      config.allowUnfree = true;
    };
  in {
    _module.args.pkgs = pkgs;
    # `nix build .#<attr>` and `nix shell .#<attr>` reach overlay attrs without a public-package projection; flake check never recurses it.
    legacyPackages = pkgs;
  };
}
