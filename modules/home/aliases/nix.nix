# Title         : nix.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/aliases/nix.nix
# ----------------------------------------------------------------------------
# Nix and Darwin register rows: deploy rail, nix ops, flake ops.
[
  # --- [DARWIN]
  {
    alias = "drs";
    expansion = "forge-redeploy --switch";
    desc = "Check, build, diff, switch";
    category = "darwin";
  }
  {
    alias = "drb";
    expansion = "forge-redeploy --build";
    desc = "Check and build";
    category = "darwin";
  }
  {
    alias = "drc";
    expansion = "forge-redeploy --check-only";
    desc = "Check config and build proof";
    category = "darwin";
  }
  {
    alias = "drr";
    expansion = "forge-redeploy --rollback";
    desc = "Reactivate previous generation";
    category = "darwin";
    risk = "destructive";
  }
  {
    alias = "drg";
    expansion = "forge-redeploy --generations";
    desc = "List system generations";
    category = "darwin";
  }
  {
    alias = "ngc";
    expansion = "forge-nix-maintenance";
    desc = "Generation trim + GC + optimise";
    category = "darwin";
    risk = "destructive";
  }
  # --- [NIX]
  {
    alias = "ns";
    expansion = "nix search nixpkgs";
    desc = "Search packages";
    category = "nix";
  }
  {
    alias = "nw";
    expansion = "nix-locate -w";
    desc = "Find package providing command";
    category = "nix";
  }
  {
    alias = "nconfig";
    expansion = "nix config show";
    desc = "Show Nix configuration";
    category = "nix";
  }
  {
    alias = "ncheck";
    expansion = "nix config check";
    desc = "Check Nix config health";
    category = "nix";
  }
  {
    alias = "nparse";
    expansion = "nix-instantiate --parse";
    desc = "Parse Nix expressions";
    category = "nix";
  }
  {
    alias = "nfetch";
    expansion = "nix-prefetch-github --nix";
    desc = "Prefetch GitHub repo (Nix output)";
    category = "nix";
  }
  {
    alias = "nfetchj";
    expansion = "nix-prefetch-github --json";
    desc = "Prefetch GitHub repo (JSON output)";
    category = "nix";
  }
  {
    alias = "nhash";
    expansion = "nix hash convert --to sri";
    desc = "Convert hash to SRI";
    category = "nix";
  }
  {
    alias = "nversion";
    expansion = "determinate-nixd version";
    desc = "Show determinate-nixd version";
    category = "nix";
  }
  {
    alias = "nupdate";
    expansion = "sudo determinate-nixd upgrade";
    desc = "Upgrade determinate-nixd";
    category = "nix";
    risk = "sudo";
  }
  # --- [FLAKE]
  {
    alias = "nfu";
    expansion = "nix flake update && nix flake check --all-systems --no-build && nix flake check";
    desc = "Update all inputs + validate";
    category = "flake";
  }
  {
    alias = "nfn";
    expansion = "nix flake update nixpkgs && forge-redeploy --check-only";
    desc = "Update nixpkgs + validate";
    category = "flake";
  }
  {
    alias = "nfl";
    expansion = "nix flake lock";
    desc = "Lock missing inputs";
    category = "flake";
  }
  {
    alias = "nfc";
    expansion = "nix flake check && nix flake show";
    desc = "Validate + explore outputs";
    category = "flake";
  }
]
