{
  config,
  pkgs,
  toolchainEnv,
  ...
}: {
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
      dir = toolchainEnv.fontDirectories;
      cachedir = "${config.xdg.cacheHome}/fontconfig";
      selectfont.rejectfont.glob = "${config.home.homeDirectory}/Library/Fonts/HomeManager/*";
    };
  };
}
