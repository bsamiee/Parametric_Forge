# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : hosts/default.nix
# ----------------------------------------------------------------------------
# Host factory: every context row becomes a system through one OS dispatch table; the per-host module and Home Manager projection are shared verbatim
# across OS classes. A new machine is one context row — nothing here changes shape.
# Bootstrap for NixOS rows is nixos-anywhere + disko; day-2 for every row is forge-redeploy.

{
  inputs,
  nix-darwin,
  home-manager,
}: let
  inherit (inputs.nixpkgs) lib;
  context = import ./context.nix;

  # Shared per-host module: platform, overlay admission, identity, and the Home Manager projection every OS carries identically.
  hostModule = host: {forgeToolchainEnvFor, ...}: {
    nixpkgs.hostPlatform = host.system;
    nixpkgs.overlays = [inputs.self.overlays.default];

    networking.hostName = host.name;
    time.timeZone = host.timeZone;

    system = {
      configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
      stateVersion = host.stateVersion.system;
    };

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "backup"; # Backup conflicting files instead of failing
      extraSpecialArgs = {inherit inputs host forgeToolchainEnvFor;};
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
  };

  # OS dispatch rows: the system builder plus the module set an OS admits; Darwin rides its own per-host row for surfaces NixOS never grows.
  os = {
    darwin = {
      mkSystem = nix-darwin.lib.darwinSystem;
      modules = host: [
        inputs.determinate.darwinModules.default # Determinate Nix owner: forces nix.enable = false, generates /etc/nix/nix.custom.conf
        ../modules/common # Common config: Nix settings + toolchain env factory
        ../modules/darwin
        home-manager.darwinModules.home-manager
        {
          networking.computerName = host.label;
          programs.zsh.enableGlobalCompInit = false; # HM owns compinit (fingerprinted -C); stock /etc/zshrc global compinit double-inits every shell
          system.primaryUser = host.user.name;
          users.users.${host.user.name} = {inherit (host.user) name home;};
        }
      ];
    };
    nixos = {
      mkSystem = lib.nixosSystem;
      modules = _: [
        inputs.determinate.nixosModules.default # Determinate Nix owner: generates /etc/nix/nix.custom.conf
        inputs.disko.nixosModules.disko # Declarative disk layout; nixos-anywhere consumes this at bootstrap
        ../modules/common # Common config: Nix settings + toolchain env factory
        ../modules/nixos
        home-manager.nixosModules.home-manager
      ];
    };
  };

  mkHost = host: let
    class = os.${host.os} or (throw "hosts/context.nix: host '${host.name}' names unknown os '${host.os}' — add a dispatch row in hosts/default.nix");
  in
    class.mkSystem {
      specialArgs = {inherit inputs host;};
      modules = class.modules host ++ [(hostModule host)];
    };
in
  # One flake output attr per dispatch row: a new OS class lands its `<os>Configurations` output from its row alone — zero shape edits here.
  lib.mapAttrs' (
    osName: _:
      lib.nameValuePair "${osName}Configurations"
      (lib.mapAttrs (_: mkHost) (lib.filterAttrs (_: host: host.os == osName) context))
  )
  os
