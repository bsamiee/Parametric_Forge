# Title         : flake/systems.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /flake/systems.nix
# ----------------------------------------------------------------------------
# System configurations (Darwin and NixOS)

{ inputs, myLib, ... }:

let
  inherit (inputs.nixpkgs) lib;

  # --- Universal System Builder ---------------------------------------------
  mkSystem =
    {
      system,
      user ? "user",
      extraModules ? [ ],
    }:
    let
      # --- Context Detection ------------------------------------------------
      ctx = myLib.detectContext system user;

      # --- Platform-Specific Builder Selection ------------------------------
      systemBuilder = if ctx.isDarwin then inputs.darwin.lib.darwinSystem else inputs.nixpkgs.lib.nixosSystem;

      # --- Platform-Specific Modules ----------------------------------------
      platformModule = if ctx.isDarwin then ../00.system/darwin else ../00.system/nixos;
      homeManagerModule =
        if ctx.isDarwin then inputs.home-manager.darwinModules.home-manager else inputs.home-manager.nixosModules.home-manager;
    in
    systemBuilder {
      inherit system;
      specialArgs = {
        inherit inputs myLib;
        flakePath = inputs.self;
        context = ctx;
      };
      # --- Modules ----------------------------------------------------------
      modules = lib.flatten [
        # Core modules
        platformModule
        homeManagerModule
        # Platform-specific modules
        (lib.optionals ctx.isDarwin [
          inputs.nix-homebrew.darwinModules.nix-homebrew
        ])
        # --- Configuration --------------------------------------------------
        {
          nixpkgs.hostPlatform = system;
          users.users.${ctx.user} = lib.mkIf ctx.isDarwin {
            name = ctx.user;
            home = ctx.userHome;
          };
          # --- Home Manager Integration -------------------------------------
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "backup";
            extraSpecialArgs = {
              inherit inputs myLib;
              context = ctx;
            };
            users.${ctx.user} = {
              imports = [ (import ../01.home) ];
              home.stateVersion = "25.05";
            };
          };
          # --- Registry Pinning ---------------------------------------------
          nix.registry.nixpkgs.flake = inputs.nixpkgs;
        }
        # User-provided extra modules
        extraModules
      ];
    };
in
{
  flake = {
    # --- Darwin Configurations ----------------------------------------------
    darwinConfigurations = {
      default = mkSystem {
        system = "aarch64-darwin";
        user = "bardiasamiee";
      };
      x86_64 = mkSystem {
        system = "x86_64-darwin";
        user = "bardiasamiee";
      };
      # TODO: Remove hostname-specific config once host-file-less deployment working
      MacBook-Pro-412 = mkSystem {
        system = "aarch64-darwin";
        user = "bardiasamiee";
      };
    };
    # --- NixOS Configurations -----------------------------------------------
    # TODO: Fix Darwin-specific package conflicts in NixOS configurations
    # nixosConfigurations = {
    #   vm = mkSystem {
    #     system = "x86_64-linux";
    #     user = "bardiasamiee";
    #     extraModules = [
    #       {
    #         virtualisation.vmVariant = {
    #           virtualisation = {
    #             memorySize = 4096;
    #             cores = 2;
    #           };
    #         };
    #       }
    #     ];
    #   };
    #   container = mkSystem {
    #     system = "x86_64-linux";
    #     user = "bardiasamiee";
    #     extraModules = [
    #       ../00.system/nixos/containers.nix
    #       {
    #         # Container-optimized settings
    #         boot.isContainer = true;
    #       }
    #     ];
    #   };
    #   aarch64-vm = mkSystem {
    #     system = "aarch64-linux";
    #     user = "bardiasamiee";
    #     extraModules = [
    #       {
    #         virtualisation.vmVariant = {
    #           virtualisation = {
    #             memorySize = 4096;
    #             cores = 2;
    #           };
    #         };
    #       }
    #     ];
    #   };
    # };
  };
}
