# Title         : nix.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/aliases/nix.nix
# ----------------------------------------------------------------------------
# Nix and Darwin register rows: deploy rail, nix ops, flake ops.
{
  darwin = [
    ["drs" "forge-redeploy --switch" "Check, build, diff, switch"]
    ["drb" "forge-redeploy --build" "Check and build"]
    ["drc" "forge-redeploy --check-only" "Check config and build proof"]
    ["drr" "forge-redeploy --rollback" "Reactivate previous generation" "destructive"]
    ["drg" "forge-redeploy --generations" "List system generations"]
    ["ngc" "forge-nix-maintenance" "Generation trim + GC + optimise" "destructive"]
  ];
  flake = [
    ["nfu" "nix flake update && nix flake check --all-systems --no-build && nix flake check" "Update all inputs + validate"]
    ["nfn" "nix flake update nixpkgs && forge-redeploy --check-only" "Update nixpkgs + validate"]
    ["nfl" "nix flake lock" "Lock missing inputs"]
    ["nfc" "nix flake check && nix flake show" "Validate + explore outputs"]
  ];
  nix = [
    ["ns" "nix search nixpkgs" "Search packages"]
    ["nw" "nix-locate -w" "Find package providing command"]
    ["nconfig" "nix config show" "Show Nix configuration"]
    ["ncheck" "nix config check" "Check Nix config health"]
    ["nparse" "nix-instantiate --parse" "Parse Nix expressions"]
    ["nfetch" "nix-prefetch-github --nix" "Prefetch GitHub repo (Nix output)"]
    ["nfetchj" "nix-prefetch-github --json" "Prefetch GitHub repo (JSON output)"]
    ["nhash" "nix hash convert --to sri" "Convert hash to SRI"]
    ["nversion" "determinate-nixd version" "Show determinate-nixd version"]
    ["nupdate" "sudo determinate-nixd upgrade" "Upgrade determinate-nixd" "sudo"]
  ];
}
