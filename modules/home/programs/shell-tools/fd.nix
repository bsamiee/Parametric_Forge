# Title         : fd.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/fd.nix
# ----------------------------------------------------------------------------
# fd on every PATH with the ignore file it reads; a project's mise pin shadows the binary inside its tree, and each project's .gitignore names its own outputs.
_: {
  programs.fd = {
    enable = true;
    # fd descends into `.git` under --hidden: `.git/` prunes the directory during traversal; `.git/**` also empties a search rooted at a `.git`
    # directory, which the walker never prunes.
    ignores = [
      ".git/"
      ".git/**"
    ];
  };
}
