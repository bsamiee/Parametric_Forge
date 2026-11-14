{config, ...}: {
  programs.gallery-dl = {
    enable = true;
    settings.extractor = {
      cookies = ["chrome" "Default"];
      archive = "${config.xdg.dataHome}/gallery-dl/archive.sqlite3";
      postprocessors = [
        {
          name = "metadata";
          mode = "json";
        }
      ];
    };
  };
}
