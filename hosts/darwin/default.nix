# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : hosts/darwin/default.nix
# ----------------------------------------------------------------------------
# Darwin host configurations

{ inputs, nix-darwin, home-manager }:

let
  inherit (inputs) nixpkgs;
  username = "bardiasamiee";
in
{
  macbook = nix-darwin.lib.darwinSystem {
    system = "aarch64-darwin";
    specialArgs = { inherit inputs; };  # Pass inputs to modules

    modules = [
      # Common configuration (includes Nix and Theme)
      ../../modules/common

      # Darwin-specific modules
      ../../modules/darwin

      # Home Manager integration
      home-manager.darwinModules.home-manager

      # Nix-Homebrew integration
      inputs.nix-homebrew.darwinModules.nix-homebrew

      # --- Host-specific configuration --------------------------------------
      {
        networking.hostName = "macbook";
        networking.computerName = "Bardia's MacBook Pro";

        # System configuration
        system.stateVersion = 6;
        system.primaryUser = username;

        # Primary user
        users.users.${username} = {
          name = username;
          home = "/Users/${username}";
        };

        # Home Manager configuration
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = { inherit inputs; };  # Pass inputs to home-manager
          users.${username} = ({ inputs, ... }: {
            imports = [ ../../modules/home ];
            home.stateVersion = "24.05";
            programs.home-manager.enable = true;
          });
        };
      }
    ];
  };
}
