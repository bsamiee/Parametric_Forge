{
  inputs,
  lib,
  self,
  withSystem,
  ...
}: let
  hosts = import ../hosts/context.nix;
in {
  systems = lib.unique (lib.mapAttrsToList (_: host: host.system) hosts);

  flake.darwinConfigurations = lib.mapAttrs (_: host:
    withSystem host.system ({pkgs, ...}:
      inputs.nix-darwin.lib.darwinSystem {
        specialArgs = {inherit inputs host;};
        modules = [
          inputs.determinate.darwinModules.default
          inputs.home-manager.darwinModules.home-manager
          ../modules/common
          ../modules/darwin
          ({toolchainEnvFor, ...}: {
            nixpkgs.pkgs = pkgs;
            documentation.enable = false;

            networking = {
              hostName = host.name;
              computerName = host.label;
            };

            system = {
              configurationRevision = self.rev or self.dirtyRev or null;
              stateVersion = host.stateVersion.system;
              primaryUser = host.user.name;
            };

            programs.zsh = {
              enableCompletion = false;
              enableBashCompletion = false;
              promptInit = "";
            };

            users.users.${host.user.name}.home = host.user.home;

            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = {inherit inputs host toolchainEnvFor;};
              users.${host.user.name} = {
                imports = [
                  inputs.nix-index-database.homeModules.nix-index
                  ../modules/home
                ];
                home.stateVersion = host.stateVersion.home;
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
      }))
  hosts;
}
