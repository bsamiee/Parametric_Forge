# Title         : zoxide.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/shell-tools/zoxide.nix
# ----------------------------------------------------------------------------
# Smart directory navigation with frecency-based learning
_: {
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;

    options = [
      "--cmd=cd" # Replace cd command entirely
      "--hook=prompt" # Update frecency based on time spent (better than pwd)
    ];
  };
}
