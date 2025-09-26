# Title         : nix.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/aliases/nix.nix
# ----------------------------------------------------------------------------
# Nix and Darwin-specific aliases

{ lib, config, ... }:

{
  programs.zsh.shellAliases = {
    # --- Darwin Rebuild Operations ------------------------------------------
    # dr = "sudo darwin-rebuild switch --flake .";
    # drs = "sudo darwin-rebuild switch --flake .";
    # drb = "sudo darwin-rebuild build --flake .";
    # drc = "sudo darwin-rebuild check --flake .";

    # --- Nix Operations -----------------------------------------------------
    # nix-gc = "sudo nix-collect-garbage -d";
    # nix-clean = "sudo nix-collect-garbage -d && nix-store --optimise";
    # nix-update = "nix flake update";

    # --- Flake Operations ---------------------------------------------------
    # nf = "nix flake";
    # nfs = "nix flake show";
    # nfu = "nix flake update";
    # nfc = "nix flake check";

    # --- Package Management ------------------------------------------------
    # ns = "nix search nixpkgs";
    # ni = "nix profile install";
    # nr = "nix profile remove";
    # nl = "nix profile list";

    # --- Development -------------------------------------------------------
    # ndev = "nix develop";
    # nrun = "nix run";
    # nbuild = "nix build";
  };
}
