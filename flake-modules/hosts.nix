# Title         : hosts.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : flake-modules/hosts.nix
# ----------------------------------------------------------------------------
# Host factory: every hosts/context.nix row becomes a darwinSystem on its system's perSystem pkgs, and the rows' systems are the flake's
# systems. A new machine is one context row; day-2 activation is redeploy.
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
          inputs.determinate.darwinModules.default # Determinate Nix owner: forces nix.enable = false, generates /etc/nix/nix.custom.conf
          inputs.home-manager.darwinModules.home-manager
          ../modules/common # Nix settings + toolchain env factory
          ../modules/darwin
          ({toolchainEnvFor, ...}: {
            nixpkgs.pkgs = pkgs;
            # Option docs are read at source and through nixd: no darwin manual, help, or configuration.nix(5) in the closure.
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

            # HM owns compinit (fingerprinted -C), the completion packages, and the prompt (starship); with completion off /etc/zshrc runs no
            # compinit, no bashcompinit, and no promptinit theme, and the system profile carries no second nix-zsh-completions. The zsh binary is
            # Apple's /bin/zsh (forge.shell); the pkgs.zsh this module still installs serves `#!/usr/bin/env zsh` scripts alone.
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
      }))
  hosts;
}
