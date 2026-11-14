_: {
  perSystem = {
    pkgs,
    lib,
    ...
  }: let
    style = import ../modules/style.nix;
    biomeLaw = builtins.fromJSON (builtins.readFile ../biome.json);
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
    treefmt = {
      settings.excludes = ["overlays/_sources/**"];
      programs = {
        alejandra.enable = true;
        deadnix.enable = true;
        statix.enable = true;
        nixf-diagnose.enable = true;
        stylua = {
          enable = true;
          settings = {
            indent_type = "Spaces";
            indent_width = style.indent;
            column_width = style.width;
          };
        };
        biome = {
          enable = true;
          package = pkgs.biome-current;
          formatCommand = "format";
          settings = biomeLaw;
        };
      };
      settings.formatter.biome.excludes = biomeExcludes;
    };
  };
}
