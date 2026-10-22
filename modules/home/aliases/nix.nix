# Title         : nix.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/aliases/nix.nix
# ----------------------------------------------------------------------------
# Nix and Darwin register rows: deploy rail, nix ops, flake ops.
{
  darwin = [
    ["drs" "redeploy --switch" "Activate the last build, else check, build, diff, activate"]
    ["drb" "redeploy --build" "Check, build, diff"]
  ];
  flake = [
    ["nfu" "nix flake update && nix flake check" "Update all inputs + validate"]
    ["nfn" "nix flake update nixpkgs && redeploy --build" "Update nixpkgs + build"]
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
