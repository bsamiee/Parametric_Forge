# Title         : nix.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/aliases/nix.nix
# ----------------------------------------------------------------------------
# Nix and Darwin register rows: deploy rail, nix ops, flake ops.
{
  darwin = [
    ["drs" "redeploy switch"]
    ["drb" "redeploy build"]
  ];
  flake = [
    ["nfu" "nix flake update && redeploy build"]
    ["nfn" "nix flake update nixpkgs && redeploy build"]
    ["nfl" "nix flake lock"]
    ["nfc" "nix flake check && nix flake show"]
  ];
  nix = [
    ["ns" "nix search nixpkgs"]
    ["nw" "nix-locate -w"]
    ["nps" "nix ps"]
    ["nconfig" "nix config show"]
    ["ncheck" "nix config check"]
    ["nparse" "nix-instantiate --parse"]
    ["nfetch" "nurl"]
    ["nfetchj" "nurl --json"]
    ["nhash" "nix hash convert --to sri"]
    ["nversion" "determinate-nixd version"]
    ["nupdate" "sudo determinate-nixd upgrade"]
  ];
}
