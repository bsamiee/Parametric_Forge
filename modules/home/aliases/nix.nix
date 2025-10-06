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
    # --- Darwin Operations --------------------------------------------------
    drs = "sudo darwin-rebuild switch --flake .#macbook |& nom";  # Switch to macbook config
    drb = "sudo darwin-rebuild build --flake .#macbook |& nom";   # Build macbook config
    drc = "darwin-rebuild check --flake .#macbook |& nom";        # Check macbook configuration

    # --- Nix Operations -----------------------------------------------------
    ns = "nix search nixpkgs";                                    # Search for packages
    nw = "nix-locate -w";                                         # Find package providing command
    nc = "sudo nix-collect-garbage -d && nix store optimise";     # Deep clean + optimize store
    nfetch = "nix-prefetch-github --nix";                       # Prefetch GitHub repos (Nix code output)
    nfetchj = "nix-prefetch-github --json";                     # Prefetch GitHub repos (JSON output)

    # --- Flake Operations ---------------------------------------------------
    nfu = "nix flake update && nix flake check";                  # Update all inputs + validate
    nfn = "nix flake lock --update-input nixpkgs && drs";         # Update nixpkgs + rebuild system
    nfl = "nix flake lock";                                       # Lock missing inputs (safe)
    nfc = "nix flake check && nix flake show";                    # Validate + explore outputs
  };
}
