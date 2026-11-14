{pkgs, ...}: let
  jsonFormat = pkgs.formats.json {};

  xhConfig = {
    default_options = [
      "--follow"
      "--ignore-stdin"
      "--timeout=30"
      "--max-redirects=5"
    ];
  };
in {
  home.packages = [pkgs.xh];
  xdg.configFile."xh/config.json".source = jsonFormat.generate "xh-config" xhConfig;
}
