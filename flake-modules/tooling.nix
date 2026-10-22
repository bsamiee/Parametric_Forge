# Title         : tooling.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : flake-modules/tooling.nix
# ----------------------------------------------------------------------------
# Formatting and lint surfaces.
_: {
  perSystem = {
    pkgs,
    lib,
    ...
  }: let
    style = import ../modules/style.nix;
    # biome.json is the single source: the biome row carries its bytes and its treefmt excludes are the same file's negation rows, so a value
    # changed there busts the treefmt cache and lands in the row with zero edits here.
    biomeLaw = builtins.fromJSON (builtins.readFile ../biome.json);
    # Biome 2.2+ spells a folder ignore as `!dir` while treefmt's exclude globs need `dir/**`: a row whose basename carries a glob or a file
    # extension (a non-dot leading name with a dot) passes verbatim, every other row is a folder and gains the recursive suffix here.
    biomeExcludes = map (
      row: let
        path = lib.removePrefix "!" row;
        base = baseNameOf path;
        isFile = lib.hasInfix "*" base || (builtins.match "[^.].*[.].+" base != null);
      in
        if isFile
        then path
        else "${path}/**"
    ) (builtins.filter (lib.hasPrefix "!") biomeLaw.files.includes);
  in {
    # treefmt-nix owns the formatter and the `treefmt` flake check natively; `nix fmt -- --ci` is the proving spelling.
    treefmt = {
      settings.excludes = ["overlays/_sources/**"];
      # Rows carry the house style (4-space indent, 150 width) explicitly: the sandboxed formatting check cannot see machine-level XDG tool configs.
      programs = {
        alejandra.enable = true;
        # Nix static analysis rides the same cache and excludes: deadnix and statix fix in place under `nix fmt`, nixf-diagnose reports, and the
        # treefmt check fails on any diff they leave (statix's unfixable lints gate through flake-modules/qa.nix).
        deadnix.enable = true;
        statix.enable = true;
        nixf-diagnose.enable = true;
        # Native rows generate the config file and pin --config-path, which is what keeps the sandboxed check independent of any repo-root or
        # XDG config; simplify stays off because -s rewrites code, not layout.
        stylua = {
          enable = true;
          settings = {
            indent_type = "Spaces";
            indent_width = style.indent;
            column_width = style.width;
          };
        };
        shfmt = {
          enable = true;
          indent_size = style.indent;
          simplify = false;
        };
        # The repo-root biome.json is the single law for treefmt and the VSCode extension. The row must carry its bytes:
        # treefmt-nix always pins --config-path, which disables biome's own root discovery, and an out-of-row config never busts the cache.
        biome = {
          enable = true;
          formatCommand = "format";
          settings = biomeLaw;
        };
      };
      settings.formatter = {
        # biome.json's negation rows verbatim, so treefmt never offers biome the paths its own config ignores (an all-ignored batch is a biome error, not a no-op).
        biome.excludes = biomeExcludes;
        # The style vocabulary is the single law; its bytes ride the row so the sandboxed check needs no XDG config and the treefmt cache busts
        # whenever the law changes. pnpm owns its lockfile pair and rewrites both in its own layout.
        yamlfmt = {
          command = "${pkgs.yamlfmt}/bin/yamlfmt";
          options = ["-conf" (toString (pkgs.writeText "yamlfmt-conf" style.yamlfmt))];
          includes = ["*.yaml" "*.yml"];
          excludes = ["pnpm-workspace.yaml" "pnpm-lock.yaml"];
        };
        shfmt.options = ["-ci"];
      };
    };
  };
}
