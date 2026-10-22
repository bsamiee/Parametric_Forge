# Title         : flake.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /flake.nix
# ----------------------------------------------------------------------------
# Flake entrypoint.
{
  description = "nix-darwin + Home Manager for the Mac";

  inputs = {
    # Hydra-gated channel tarball: locks rev and lastModified through its immutable Link URL and resolves without api.github.com.
    nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.xz";

    # Supplies darwinModules.default alone, a configuration-only module; its own inputs are fetched only when its packages are forced.
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.treefmt-nix.flakeModule
        inputs.nix-darwin.flakeModules.default
        ./flake-modules/nixpkgs.nix
        ./flake-modules/hosts.nix
        ./flake-modules/packages.nix
        ./flake-modules/qa.nix
        ./flake-modules/tooling.nix
      ];

      flake.overlays.default = import ./overlays;
    };
}
