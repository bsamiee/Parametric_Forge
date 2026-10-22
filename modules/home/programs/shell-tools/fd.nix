# Title         : fd.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/fd.nix
# ----------------------------------------------------------------------------
# The ignore file every fd reads. The fd binary is a project's mise.toml row, and each project's .gitignore names its own outputs.
_: {
  programs.fd = {
    enable = true;
    package = null;
    # fd descends into `.git` under --hidden: `.git/` prunes the directory during traversal; `.git/**` also empties a search rooted at a `.git`
    # directory, which the walker never prunes.
    ignores = [
      ".git/"
      ".git/**"
    ];
  };
}
