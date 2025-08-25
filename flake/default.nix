# Title         : flake/default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /flake/default.nix
# ----------------------------------------------------------------------------
# Central import for all flake-parts modules

{ inputs, ... }:

{
  # --- Import Flake Modules -------------------------------------------------
  imports = [
    ./systems.nix
    ./devshells.nix
    ./packages.nix
    ./formatting.nix
    ./checks.nix
  ];
  # --- Global Configuration -------------------------------------------------
  systems = [
    "aarch64-darwin"
    "x86_64-darwin"
    "aarch64-linux"
    "x86_64-linux"
  ];
  # --- Module Arguments -----------------------------------------------------
  _module.args = {
    # Custom library functions available to all modules
    myLib = import ../lib { inherit (inputs) nixpkgs; };
  };

  # --- Flake Outputs --------------------------------------------------------
  flake.lib = import ../lib { inherit (inputs) nixpkgs; };
}
