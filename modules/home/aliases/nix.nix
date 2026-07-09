# Title         : nix.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/aliases/nix.nix
# ----------------------------------------------------------------------------
# Nix and Darwin-specific aliases
_: {
  programs.zsh.shellAliases = {
    # --- Darwin Operations --------------------------------------------------
    drs = "forge-redeploy --switch"; # Check, build, diff, then switch macbook config
    drb = "forge-redeploy --build"; # Check and build macbook config
    drc = "forge-redeploy --check-only"; # Check macbook configuration and build proof
    drr = "forge-redeploy --rollback"; # Reactivate the previous system generation
    drg = "forge-redeploy --generations"; # List system generations
    ngc = "forge-nix-maintenance"; # Generation trim + GC + store optimise via the rail

    # --- Nix Operations -----------------------------------------------------
    ns = "nix search nixpkgs"; # Search for packages
    nw = "nix-locate -w"; # Find package providing command
    nconfig = "nix config show"; # Show Nix configuration
    ncheck = "nix config check"; # Check Nix config for potential problems and print a PASS or FAIL for each check
    nparse = "nix-instantiate --parse"; # Parse Nix expressions
    nfetch = "nix-prefetch-github --nix"; # Prefetch GitHub repos (Nix code output)
    nfetchj = "nix-prefetch-github --json"; # Prefetch GitHub repos (JSON output)
    nhash = "nix hash convert --to sri"; # Convert hash to modern SRI format
    nversion = "determinate-nixd version"; # Show determinate-nixd version
    nupdate = "sudo determinate-nixd upgrade"; # Upgrade determinate-nixd version

    # --- Flake Operations ---------------------------------------------------
    nfu = "nix flake update && nix flake check --all-systems --no-build && nix flake check"; # Update all inputs + validate local builds
    nfn = "nix flake update nixpkgs && forge-redeploy --check-only"; # Update nixpkgs + validate before any switch
    nfl = "nix flake lock"; # Lock missing inputs (safe)
    nfc = "nix flake check && nix flake show"; # Validate + explore outputs
  };
}
