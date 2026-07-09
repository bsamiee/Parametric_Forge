# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : hosts/darwin/default.nix
# ----------------------------------------------------------------------------
# Darwin host configurations projected from the host-context factory.
{
  inputs,
  nix-darwin,
  home-manager,
}: let
  context = import ../context.nix;
  host = context.macbook;
in {
  ${host.name} = nix-darwin.lib.darwinSystem {
    specialArgs = {inherit inputs host;};

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
        nixpkgs.hostPlatform = host.system;
        nixpkgs.overlays = [inputs.self.overlays.default];

        networking.hostName = host.name;
        networking.computerName = "Bardia's MacBook Pro";

        time.timeZone = "America/Chicago";

        # HM owns compinit (fingerprinted -C); the stock /etc/zshrc global compinit double-inits every shell
        programs.zsh.enableGlobalCompInit = false;

        # System configuration
        system = {
          configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
          stateVersion = host.stateVersion.system;
          primaryUser = host.user.name;
        };

        # Primary user
        users.users.${host.user.name} = {
          inherit (host.user) name home;
        };

        # Home Manager configuration
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "backup"; # Backup conflicting files instead of failing
          extraSpecialArgs = {inherit inputs host forgeToolchainEnvFor;};
          users.${host.user.name} = {...}: {
            imports = [
              inputs.nix-index-database.homeModules.nix-index
              ../../modules/home
            ];
            home = {
              username = host.user.name;
              homeDirectory = host.user.home;
              stateVersion = host.stateVersion.home;
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
