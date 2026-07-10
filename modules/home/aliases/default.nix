# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/aliases/default.nix
# ----------------------------------------------------------------------------
# Alias register owner: sibling files are typed row lists; this module stamps
# owner_file/risk, asserts alias uniqueness, exposes forge.registers.aliases,
# and projects the shell-alias terminal surface from the same rows.
{lib, ...}: let
  files = ["containers" "core" "git" "media" "nix"];
  rows =
    lib.concatMap (
      f:
        map (r: {risk = "none";} // r // {owner_file = "aliases/${f}.nix";})
        (import ./${f}.nix)
    )
    files;
  names = map (r: r.alias) rows;
  dupes = lib.attrNames (lib.filterAttrs (_: c: c > 1) (lib.foldl' (acc: n: acc // {${n} = (acc.${n} or 0) + 1;}) {} names));
in {
  options.forge.registers.aliases = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
    default = rows;
    description = "Typed alias register rows: alias, expansion, desc, category, owner_file, risk.";
  };

  config = {
    assertions = [
      {
        assertion = dupes == [];
        message = "forge.registers.aliases: duplicate alias rows: ${lib.concatStringsSep ", " dupes}";
      }
    ];
    programs.zsh.shellAliases =
      lib.listToAttrs (map (r: lib.nameValuePair r.alias r.expansion) rows);
  };
}
