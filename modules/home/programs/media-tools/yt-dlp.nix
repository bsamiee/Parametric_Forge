{
  config,
  pkgs,
  ...
}: let
  cookies = "${config.xdg.stateHome}/yt-dlp/youtube.cookies.txt";
  signin = pkgs.writeShellApplication {
    name = "yt-dlp-signin";
    runtimeInputs = [pkgs.jq config.programs.yt-dlp.package];
    text = ''
      state="$(mktemp)"
      trap 'rm -f "$state"' EXIT
      umask 077
      mkdir -p ${dirOf cookies}
      playwright cli -s=yt-dlp-signin attach --extension=chrome >/dev/null
      playwright cli -s=yt-dlp-signin state-save "$state" >/dev/null
      playwright cli -s=yt-dlp-signin detach --close-tabs >/dev/null
      {
        printf '# Netscape HTTP Cookie File\n'
        jq -r '.cookies[] | select(.domain | test("(^|\\.)youtube\\.com$"))
          | [(if .httpOnly then "#HttpOnly_" else "" end) + .domain, (.domain | startswith(".") | if . then "TRUE" else "FALSE" end), .path,
             (if .secure then "TRUE" else "FALSE" end), ([.expires // 0, 0] | max | floor | tostring), .name, .value] | @tsv' "$state"
      } > ${cookies}
      yt-dlp --cookies ${cookies} --simulate --print '%(playlist_count)s videos in Watch Later' -I 1 'https://www.youtube.com/playlist?list=WL'
    '';
  };
in {
  home.packages = [signin];

  programs.yt-dlp = {
    enable = true;
    package = pkgs.yt-dlp-current;
    settings = {
      alias = [
        ''account "--cookies ${cookies}"''
        ''asr "--write-auto-subs --sub-langs en-orig,fa-orig,ar-orig --sub-format json3/vtt"''
        ''subs "--write-subs --sub-langs all,-live_chat --sub-format vtt/best"''
        ''recent "--lazy-playlist --break-match-filters upload_date>={0}"''
      ];
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
