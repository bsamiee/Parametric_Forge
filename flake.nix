# Title         : flake.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /flake.nix
# ----------------------------------------------------------------------------
# Pure entry point - delegates all logic to modules

{
  description = "Unified NixOS + nix-darwin + Home Manager";

  # --- Inputs ---------------------------------------------------------------
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  };

  # --- Outputs ----------------------------------------------------------------
  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager, ... }:
  let
    systems = [ "x86_64-darwin" "aarch64-darwin" "x86_64-linux" "aarch64-linux" ];
    forAllSystems = nixpkgs.lib.genAttrs systems;
  in {
    overlays.default = import ./overlays { inherit inputs; };
    darwinConfigurations = import ./hosts/darwin { inherit inputs nix-darwin home-manager; };
    # NixOS configurations (placeholder for future)
    nixosConfigurations = {};
    # Standalone home configurations (placeholder for future)
    homeConfigurations = {};

    packages = forAllSystems (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in {
        sqlean = pkgs.callPackage (self + "/overlays/sqlean") { };
        default = pkgs.callPackage (self + "/overlays/sqlean") { };
      });

    devShells = forAllSystems (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in {
        default = pkgs.mkShell {
          packages = with pkgs; [ git nixfmt-rfc-style statix deadnix nix-output-monitor ];
        };
      });

    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);
  };
}
