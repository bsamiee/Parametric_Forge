# Title         : nix.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/aliases/nix.nix
# ----------------------------------------------------------------------------
# Nix and Darwin-specific aliases
_: {
  programs.zsh.shellAliases = {
    # --- Darwin Operations --------------------------------------------------
    drs = "sudo darwin-rebuild switch --flake .#macbook |& nom"; # Switch to macbook config
    drb = "sudo darwin-rebuild build --flake .#macbook |& nom"; # Build macbook config
    drc = "darwin-rebuild check --flake .#macbook |& nom"; # Check macbook configuration

    # --- Nix Operations -----------------------------------------------------
    ns = "nix search nixpkgs"; # Search for packages
    nw = "nix-locate -w"; # Find package providing command
    nc = "sudo nix-collect-garbage -d && nix store optimise"; # Deep clean + optimize store
    nconfig = "nix config show"; # Show Nix configuration
    ncheck = "nix config check"; # Check Nix config for potential problems and print a PASS or FAIL for each check
    nparse = "nix-instantiate --parse"; # Parse Nix expressions
    nfetch = "nix-prefetch-github --nix"; # Prefetch GitHub repos (Nix code output)
    nfetchj = "nix-prefetch-github --json"; # Prefetch GitHub repos (JSON output)
    nhash = "nix hash convert --to-sri"; # Convert hash to modern SRI format
    nversion = "determinate-nixd version"; # Show determinate-nixd version
    nupdate = "sudo determinate-nixd upgrade"; # Upgrade determinate-nixd version

    # --- Flake Operations ---------------------------------------------------
    nfu = "nix flake update && nix flake check --all-systems"; # Update all inputs + validate
    nfn = "nix flake update nixpkgs && drs"; # Update nixpkgs + rebuild system
    nfl = "nix flake lock"; # Lock missing inputs (safe)
    nfc = "nix flake check && nix flake show"; # Validate + explore outputs
  };
}
