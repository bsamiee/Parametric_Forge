# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : hosts/default.nix
# ----------------------------------------------------------------------------
# Host factory: every context row becomes a darwinSystem carrying the shared module set and the Home Manager projection. A new machine is one
# context row; day-2 activation is redeploy.
{
  inputs,
  nix-darwin,
  home-manager,
}: let
  inherit (inputs.nixpkgs) lib;

  mkHost = host:
    nix-darwin.lib.darwinSystem {
      specialArgs = {inherit inputs host;};
      modules = [
        inputs.determinate.darwinModules.default # Determinate Nix owner: forces nix.enable = false, generates /etc/nix/nix.custom.conf
        ../modules/common # Nix settings + toolchain env factory
        ../modules/darwin
        home-manager.darwinModules.home-manager
        ({toolchainEnvFor, ...}: {
          nixpkgs.hostPlatform = host.system;
          nixpkgs.overlays = [inputs.self.overlays.default];

          networking = {
            hostName = host.name;
            computerName = host.label;
          };

          system = {
            configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
            stateVersion = host.stateVersion.system;
            primaryUser = host.user.name;
          };

          # HM owns compinit (fingerprinted -C) and the prompt (starship); /etc/zshrc would otherwise run compinit, bashcompinit, and the suse
          # promptinit theme in every interactive shell ahead of them.
          programs.zsh = {
            enableGlobalCompInit = false;
            enableBashCompletion = false;
            promptInit = "";
          };

          users.users.${host.user.name} = {inherit (host.user) name home;};

          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "backup"; # Backup conflicting files instead of failing
            extraSpecialArgs = {inherit inputs host toolchainEnvFor;};
            users.${host.user.name} = {
              imports = [
                inputs.nix-index-database.homeModules.nix-index
                ../modules/home
              ];
              home = {
                username = host.user.name;
                homeDirectory = host.user.home;
                stateVersion = host.stateVersion.home;
              };
              # No generated manual: option docs are read at source and through nixd
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
in {
  darwinConfigurations = lib.mapAttrs (_: mkHost) (import ./context.nix);
}
