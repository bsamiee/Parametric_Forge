{
  config,
  pkgs,
  ...
}: let
  inherit (config.forge.theme) palette;
  toml = pkgs.formats.toml {};
  rgb = c: {rgb = [c.r c.g c.b];};
  configToml = toml.generate "tlrc-config.toml" {
    cache = {
      dir = "${config.xdg.cacheHome}/tlrc";
      languages = ["en"];
    };
    output = {
      show_hyphens = true;
      compact = true;
    };
    style = {
      title = {
        color = rgb palette.magenta;
        bold = true;
      };
      description.color = rgb palette.purple;
      bullet.color = rgb palette.green;
      example.color = rgb palette.cyan;
      url = {
        color = rgb palette.orange;
        italic = true;
      };
      inline_code = {
        color = rgb palette.yellow;
        italic = true;
      };
      placeholder = {
        color = rgb palette.red;
        italic = true;
      };
    };
  };
in {
  home.packages = [pkgs.tlrc];

  home.file."Library/Application Support/tlrc/config.toml".source = configToml;
}
