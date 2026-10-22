# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/aliases/default.nix
# ----------------------------------------------------------------------------
# Alias register: sibling files are category-keyed tables of [alias expansion] rows; this module projects them into the shell surface.
{lib, ...}: {
  programs.zsh.shellAliases = lib.listToAttrs (lib.concatMap (f:
    lib.concatMap (map (t: lib.nameValuePair (lib.elemAt t 0) (lib.elemAt t 1))) (lib.attrValues (import ./${f}.nix)))
  ["core" "git" "macos" "media" "nix"]);
}
