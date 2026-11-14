{
  config,
  pkgs,
  toolchainEnvFor,
  ...
}: let
  inherit
    (toolchainEnvFor {
      home = config.home.homeDirectory;
      username = config.home.username;
      xdgCacheHome = config.xdg.cacheHome;
    })
    fontDirectories
    ;
in {
  xdg.configFile."fontconfig/fonts.conf".source = (pkgs.formats.xml {}).generate "fonts.conf" {
    fontconfig = {
      include =
        map (path: {
          "@ignore_missing" = "yes";
          "#text" = path;
        }) [
          "${pkgs.fontconfig.out}/etc/fonts/fonts.conf"
          "${pkgs.fontconfig.out}/etc/fonts/conf.d"
        ];
      dir = fontDirectories;
      cachedir = "${config.xdg.cacheHome}/fontconfig";
      selectfont.rejectfont.glob = "${config.home.homeDirectory}/Library/Fonts/HomeManager/*";
    };
  };
}
