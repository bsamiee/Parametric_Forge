{
  config,
  pkgs,
  ...
}: let
  chromeCookies = "browser-cookies/chrome";
in {
  programs.gallery-dl = {
    enable = true;
    package = pkgs.gallery-dl-current;
    settings.extractor = {
      cookies = ["chrome" "${config.xdg.stateHome}/${chromeCookies}"];
      archive = "${config.xdg.dataHome}/gallery-dl/archive.sqlite3";
      postprocessors = [
        {
          name = "metadata";
          mode = "json";
        }
      ];
    };
  };

  # --- [CHROME_COOKIES]
  xdg.stateFile."${chromeCookies}/Cookies".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Library/Application Support/Google/Chrome/Default/Cookies";
}
