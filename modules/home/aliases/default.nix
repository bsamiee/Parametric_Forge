# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/aliases/default.nix
# ----------------------------------------------------------------------------
# Alias register owner: sibling files are category-keyed row tables; this module folds each tuple into a typed row, stamps
# owner_file and the risk default, asserts alias uniqueness, exposes forge.registers.aliases, and projects the shell surface.
{
  host,
  lib,
  ...
}: let
  # --- [ROW_GRAMMAR]
  # Row tuple [alias expansion desc risk?]: category is the group key, owner_file the source file, risk pads to none.
  # An oversized tuple faults rather than dropping its tail, because elemAt reads a fixed arity and would ignore the excess.
  schema = ["alias" "expansion" "desc" "risk"];
  mkRow = owner: category: t:
    lib.throwIf (lib.length t > lib.length schema)
    "aliases/${owner}.nix: row ${builtins.toJSON t} exceeds schema [${lib.concatStringsSep " " schema}]"
    {
      inherit category;
      alias = lib.elemAt t 0;
      expansion = lib.elemAt t 1;
      desc = lib.elemAt t 2;
      risk = lib.elemAt (t ++ ["none"]) 3;
      owner_file = "aliases/${owner}.nix";
    };
  files = ["containers" "core" "git" "media" "nix"] ++ lib.optionals (host.os == "darwin") ["macos"];
  rows = lib.concatMap (f: lib.concatLists (lib.mapAttrsToList (c: ts: map (mkRow f c) ts) (import ./${f}.nix))) files;
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
