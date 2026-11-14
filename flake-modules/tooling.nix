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
        shfmt = {
          enable = true;
          indent_size = style.indent;
          simplify = false;
        };
        biome = {
          enable = true;
          formatCommand = "format";
          settings = biomeLaw;
        };
      };
      settings.formatter = {
        biome.excludes = biomeExcludes;
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
