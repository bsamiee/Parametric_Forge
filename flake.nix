# Title         : flake.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /flake.nix
# ----------------------------------------------------------------------------
# Flake entrypoint.
{
  description = "Unified NixOS + nix-darwin + Home Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # No nixpkgs follows: pinning against Forge nixpkgs causes FlakeHub cache misses.
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
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

    shell-plugins = {
      url = "github:1Password/shell-plugins";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    flake-parts,
    nix-darwin,
    home-manager,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.treefmt-nix.flakeModule
        ./flake-modules/nixpkgs.nix
        ./flake-modules/packages.nix
        ./flake-modules/qa.nix
        ./flake-modules/tooling.nix
      ];

      systems = ["aarch64-darwin" "x86_64-linux" "aarch64-linux"];

      # Lazy debug output feeds the generated nixd flake-parts option rows
      # (modules/home/programs/nix-tools/nixd.nix); zero eval cost until read.
      debug = true;

      flake = {
        overlays.default = import ./overlays;
        darwinConfigurations = import ./hosts/darwin {inherit inputs nix-darwin home-manager;};
        nixosConfigurations = import ./hosts/nixos {inherit inputs home-manager;};
      };
    };
}
