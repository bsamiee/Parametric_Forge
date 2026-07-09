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
    specialArgs = {inherit inputs;};

    modules = [
      # Determinate Nix owner: forces nix.enable = false, generates /etc/nix/nix.custom.conf
      inputs.determinate.darwinModules.default

      # Common configuration (Nix settings + toolchain env factory)
      ../../modules/common

      # Darwin-specific modules
      ../../modules/darwin

      # Home Manager integration
      home-manager.darwinModules.home-manager

      # --- Host-specific configuration --------------------------------------
      ({forgeToolchainEnvFor, ...}: {
        nixpkgs.hostPlatform = "aarch64-darwin";
        nixpkgs.overlays = [inputs.self.overlays.default];

        networking.hostName = "macbook";
        networking.computerName = "Bardia's MacBook Pro";

        time.timeZone = "America/Chicago";

        # HM owns compinit (fingerprinted -C); the stock /etc/zshrc global compinit double-inits every shell
        programs.zsh.enableGlobalCompInit = false;

        # System configuration
        system = {
          configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
          stateVersion = 7;
          primaryUser = username;
        };

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
          extraSpecialArgs = {inherit inputs forgeToolchainEnvFor;};
          users.${username} = {...}: {
            imports = [
              inputs.nix-index-database.homeModules.nix-index
              ../../modules/home
            ];
            home = {
              inherit username;
              homeDirectory = "/Users/${username}";
              stateVersion = "26.05";
            };
            programs.home-manager.enable = true;

            # Disable manual generation to avoid builtins.toFile warnings
            manual = {
              html.enable = false;
              json.enable = false;
              manpages.enable = false;
            };
            news.display = "silent";
          };
        };
      })
    ];
  };
}
