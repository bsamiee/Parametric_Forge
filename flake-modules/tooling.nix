_: {
  perSystem = _: let
    style = import ../modules/style.nix;
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
        oxfmt = {
          enable = true;
          includes = ["*.ts" "*.js" "*.json" "*.jsonc"];
        };
      };
    };
  };
}
