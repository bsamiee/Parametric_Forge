{lib, ...}: {
  programs.zsh.shellAliases = lib.listToAttrs (lib.concatMap (f:
    lib.concatMap (map (t: lib.nameValuePair (lib.elemAt t 0) (lib.elemAt t 1))) (lib.attrValues (import ./${f}.nix)))
  ["core" "git" "macos" "media" "nix"]);
}
