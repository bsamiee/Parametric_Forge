# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : hosts/darwin/default.nix
# ----------------------------------------------------------------------------
# Darwin host configurations
{
  inputs,
  nix-darwin,
  home-manager,
}: let
  username = "bardiasamiee";
in {
  macbook = nix-darwin.lib.darwinSystem {
    system = "aarch64-darwin";
    specialArgs = {inherit inputs;}; # Pass inputs to modules

    modules = [
      # Common configuration (includes Nix and Theme)
      ../../modules/common

      # Darwin-specific modules
      ../../modules/darwin

      # Home Manager integration
      home-manager.darwinModules.home-manager

      # --- Host-specific configuration --------------------------------------
      {
        nixpkgs.overlays = [inputs.self.overlays.default];

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
          backupFileExtension = "backup"; # Backup conflicting files instead of failing
          extraSpecialArgs = {inherit inputs;}; # Pass inputs to home-manager
          users.${username} = {...}: {
            imports = [../../modules/home];
            home.stateVersion = "26.05";
            programs.home-manager.enable = true;

            # Disable manual generation to avoid builtins.toFile warnings
            manual.html.enable = false;
            manual.json.enable = false;
            manual.manpages.enable = false;
            news.display = "silent";
          };
        };
      }
    ];
  };
}
