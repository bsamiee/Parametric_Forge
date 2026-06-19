# Title         : inspection.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/nix-tools/inspection.nix
# ----------------------------------------------------------------------------
# Nix closure and generation inspection tools.
{
  pkgs,
  lib,
  ...
}: let
  optionalTool = name: lib.optionals (builtins.hasAttr name pkgs) [pkgs.${name}];
  nixDiff =
    if builtins.hasAttr "nix-diff-rs" pkgs
    then [pkgs.nix-diff-rs]
    else optionalTool "nix-diff";
in {
  home.packages =
    optionalTool "nvd"
    ++ optionalTool "nh"
    ++ optionalTool "flake-checker"
    ++ optionalTool "nix-tree"
    ++ nixDiff;
}
