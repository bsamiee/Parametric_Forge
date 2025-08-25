# Title         : lib/git-status.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /lib/git-status.nix
# ----------------------------------------------------------------------------
# Git status utilities for both Nix and Rust consumption.

_:

rec {
  # --- Git Status Detection (Build Time) ------------------------------------
  getRepoStatus = path: if builtins.pathExists "${path}/.git" then builtins.readFile "${path}/.git/HEAD" else null;

  # --- Runtime Git Commands -------------------------------------------------
  # Generate git status JSON for runtime consumption
  statusCommand = ''
    git status --porcelain=v2 --branch --ignored 2>/dev/null | \
    jq -Rs 'split("\n") | map(select(. != "")) |
    map(if startswith("1 ") or startswith("2 ") then
      split(" ") | {
        status: .[1],
        path: .[8]
      }
    elif startswith("? ") then
      {status: "?", path: .[2:]}
    elif startswith("! ") then
      {status: "!", path: .[2:]}
    else . end)'
  '';

  # --- Status Character Mapping ---------------------------------------------
  statusChars = {
    modified = "M";
    added = "A";
    deleted = "D";
    renamed = "R";
    copied = "C";
    untracked = "?";
    ignored = "!";
  };
}
