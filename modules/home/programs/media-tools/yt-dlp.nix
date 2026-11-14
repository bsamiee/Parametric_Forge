_: {
  programs.yt-dlp = {
    enable = true;
    settings = {
      cookies-from-browser = "chrome:Default";
      output = "'%(title).180B [%(id)s].%(ext)s'";
      write-info-json = true;
      embed-metadata = true;
      embed-chapters = true;
      sub-langs = "fa.*,en.*,ar.*,-live_chat";
      concurrent-fragments = 4;
      newline = true;
      progress-delta = 10;
    };
  };
}
