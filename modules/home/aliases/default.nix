# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/aliases/default.nix
# ----------------------------------------------------------------------------
# Alias register owner: sibling files are category-keyed row tables; this module folds each tuple into a typed row, stamps
# owner_file and the risk default, and projects the shell surface.
{lib, ...}: let
  # --- [ROW_GRAMMAR]
  # Row tuple [alias expansion desc risk?]: category is the group key, owner_file the source file, risk pads to none.
  mkRow = owner: category: t: {
    inherit category;
    alias = lib.elemAt t 0;
    expansion = lib.elemAt t 1;
    desc = lib.elemAt t 2;
    risk = lib.elemAt (t ++ ["none"]) 3;
    owner_file = "aliases/${owner}.nix";
  };
  files = ["core" "git" "macos" "media" "nix"];
  rows = lib.concatMap (f: lib.concatLists (lib.mapAttrsToList (c: ts: map (mkRow f c) ts) (import ./${f}.nix))) files;
in {
  programs.zsh.shellAliases =
    lib.listToAttrs (map (r: lib.nameValuePair r.alias r.expansion) rows);
}
