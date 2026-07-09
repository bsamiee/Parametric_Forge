# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : hosts/nixos/default.nix
# ----------------------------------------------------------------------------
# NixOS host configurations projected from the host-context factory; every
# `os == "nixos"` context row becomes a nixosSystem with the shared module
# graph. Bootstrap is nixos-anywhere + disko; day-2 is forge-redeploy.
{
  inputs,
  home-manager,
}: let
  context = import ../context.nix;

  mkNixosHost = host:
    inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs host;};

      modules = [
        # Determinate Nix owner: generates /etc/nix/nix.custom.conf
        inputs.determinate.nixosModules.default

        # Declarative disk layout (nixos-anywhere consumes this at bootstrap)
        inputs.disko.nixosModules.disko

        # Common configuration (Nix settings + toolchain env factory)
        ../../modules/common

        # NixOS-specific system surface
        ../../modules/nixos

        # Home Manager integration
        home-manager.nixosModules.home-manager

        # --- Host-specific configuration ------------------------------------
        ({forgeToolchainEnvFor, ...}: {
          nixpkgs.hostPlatform = host.system;
          nixpkgs.overlays = [inputs.self.overlays.default];

          networking.hostName = host.name;

          system = {
            configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
            stateVersion = host.stateVersion.system;
          };

          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "backup";
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
in
  builtins.mapAttrs (_: mkNixosHost)
  (inputs.nixpkgs.lib.filterAttrs (_: host: host.os == "nixos") context)
