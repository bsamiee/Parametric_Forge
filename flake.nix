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
    # Slow-scientific pin: the python-overlay env (vtk, openusd, OCCT+VTK, OCP — hours of uncached compile) rides this rev, so a nixpkgs move never
    # repays that lane. The rev in the URL is the pin — `nix flake update` leaves it — and it advances only by deliberate edit to the locked nixpkgs
    # rev, with `forge-python-overlay build` paying the rebuild once and pushing it to the forge cache (atlas [09]-[UPDATE_SEQUENCE]).
    nixpkgs-sci.url = "github:NixOS/nixpkgs/c8f90650c15282fa8656a041bfbbd2403997a9a7";

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

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
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

      flake =
        {
          # rust-overlay lands ahead of the Forge fold so the rust-toolchain row resolves `rust-bin` from its own `prev`; consumers keep taking
          # one `overlays.default`.
          overlays.default = inputs.nixpkgs.lib.composeManyExtensions [inputs.rust-overlay.overlays.default (import ./overlays)];
        }
        // import ./hosts {inherit inputs nix-darwin home-manager;};
    };
}
