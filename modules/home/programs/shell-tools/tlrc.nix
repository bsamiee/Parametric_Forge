{
  config,
  pkgs,
  theme,
  ...
}: let
  inherit (theme) palette;
  toml = pkgs.formats.toml {};
  configToml = toml.generate "tlrc-config.toml" {
    cache = {
      dir = "${config.xdg.cacheHome}/tlrc";
      languages = ["en"];
      defer_auto_update = true;
    };
    output = {
      show_hyphens = true;
      compact = true;
    };
    style = {
      title.color.hex = palette.magenta.hex;
      description.color.hex = palette.purple.hex;
      bullet.color.hex = palette.green.hex;
      example.color.hex = palette.cyan.hex;
      url.color.hex = palette.orange.hex;
      inline_code.color.hex = palette.yellow.hex;
      placeholder.color.hex = palette.red.hex;
    };
  };
in {
  home.packages = [pkgs.tlrc];

  xdg.configFile."tlrc/config.toml".source = configToml;
}
