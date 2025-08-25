# Title         : flake.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /flake.nix
# ----------------------------------------------------------------------------
# Pure entry point - delegates all logic to modules

{
  description = "Parametric Forge • Multi-platform configuration management";

  nixConfig = {
    warn-dirty = false; # Don't warn about uncommitted changes
    accept-flake-config = true; # Accept flake config from dependencies
    # Experimental features are configured system-wide in 00.system/nix.nix
  };

  # --- Inputs ---------------------------------------------------------------
  inputs = {
    # Primary input
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # Flake framework
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    # Platform-specific
    darwin.url = "github:LnL7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    # Configuration management
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    # macOS integration
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    # Development tools
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    # Rust toolchain
    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
  };
  # --- Outputs --------------------------------------------------------------
  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ ./flake ];
    };
}
