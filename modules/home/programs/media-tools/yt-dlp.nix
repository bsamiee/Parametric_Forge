{pkgs, ...}: {
  programs.yt-dlp = {
    enable = true;
    package = pkgs.yt-dlp-current;
    settings = {
      alias = [
        ''asr "--write-auto-subs --sub-langs en-orig,fa-orig,ar-orig --sub-format json3/vtt"''
        ''subs "--write-subs --sub-langs all,-live_chat --sub-format vtt/best"''
        ''recent "--lazy-playlist --break-match-filters upload_date>={0}"''
      ];
      cookies-from-browser = "chrome";
      output = "'%(title).180B [%(id)s].%(ext)s'";
      write-info-json = true;
      parse-metadata = "'video::(?P<automatic_captions>)'";
      embed-metadata = true;
      embed-chapters = true;
      extractor-args = [
        "youtubetab:approximate_date"
        "'youtube:max_comments=500,all,100,10;comment_sort=top'"
      ];
      concurrent-fragments = 4;
      newline = true;
      progress-delta = 10;
    };
  };
}
