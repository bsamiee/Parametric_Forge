# Title         : mpv.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/media-tools/mpv.nix
# ----------------------------------------------------------------------------
# High-performance media player with Dracula theme

{ config, lib, pkgs, ... }:

let
  ytdlpPackage = pkgs.yt-dlp;
  downloadsDir = "${config.home.homeDirectory}/Downloads";
  ytdlpFormat = "bv*[height<=?1080][fps<=?60]+ba/best[height<=?1080]";
  ytdlpFormatSort = "res:1080,fps,codec:h264:m4a,size,br,asr";
  downloadsDirEscaped = lib.escapeShellArg downloadsDir;
  ytdlpOutputTemplate = lib.escapeShellArg "${downloadsDir}/%(uploader)s/%(upload_date>%Y-%m-%d)s - %(title)s [%(id)s].%(ext)s";
  ytdlpArchivePath = lib.escapeShellArg "${downloadsDir}/.yt-dlp-archive.txt";
  ytdlpFormatEscaped = lib.escapeShellArg ytdlpFormat;
  ytdlpFormatSortEscaped = lib.escapeShellArg ytdlpFormatSort;
  ytdlpSubLangs = lib.escapeShellArg "en.*,live_chat";
  ytdlpUserAgent = lib.escapeShellArg "Mozilla/5.0 (compatible; ParametricForge-yt-dlp)";
  ytdlpRetrySleep = lib.escapeShellArg "1:5";
  ytdlpConfigLines = [
    "--paths ${downloadsDirEscaped}"
    "--output ${ytdlpOutputTemplate}"
    "--format ${ytdlpFormatEscaped}"
    "--format-sort ${ytdlpFormatSortEscaped}"
    "--merge-output-format mp4"
    "--write-info-json"
    "--write-description"
    "--write-thumbnail"
    "--embed-thumbnail"
    "--embed-metadata"
    "--write-subs"
    "--write-auto-subs"
    "--embed-subs"
    "--sub-langs ${ytdlpSubLangs}"
    "--sub-format best"
    "--download-archive ${ytdlpArchivePath}"
    "--no-overwrites"
    "--continue"
    "--concurrent-fragments 5"
    "--retries 3"
    "--retry-sleep ${ytdlpRetrySleep}"
    "--fragment-retries 3"
    "--limit-rate 8M"
    "--user-agent ${ytdlpUserAgent}"
    "--no-playlist"
    "--progress"
    "--newline"
  ];
  ytdlpConfig = lib.concatStringsSep "\n" (ytdlpConfigLines ++ [ "" ]);
in

# Dracula theme color reference
# background    #15131F
# current_line  #2A2640
# selection     #44475A
# foreground    #F8F8F2
# comment       #6272A4
# purple        #A072C6
# cyan          #94F2E8
# green         #50FA7B
# yellow        #F1FA8C
# orange        #F97359
# red           #FF5555
# magenta       #d82f94
# pink          #E98FBE

{
  home.packages = [ ytdlpPackage ];

  xdg.configFile."yt-dlp/config".text = ytdlpConfig;

  programs.mpv = {
    enable = true;
    config = {
      # --- Video Settings ---------------------------------------------------
      profile = "gpu-hq";                     # High quality GPU rendering
      vo = "gpu-next";                        # Modern GPU rendering (successor to gpu)
      gpu-api = "metal";                      # Apple Metal API for macOS
      hwdec = "videotoolbox";                 # Apple VideoToolbox hardware decoding
      video-sync = "display-resample";        # Smooth motion
      interpolation = true;                   # Motion interpolation
      tscale = "over";                        # Temporal scaling (oversample)

      # --- Audio Settings ---------------------------------------------------
      audio-file-auto = "fuzzy";              # Auto-load external audio
      audio-pitch-correction = true;          # Pitch correction when speed changes
      volume = 100;                           # Default volume
      volume-max = 200;                       # Max volume (200%)

      # --- Subtitle Settings ------------------------------------------------
      sub-auto = "fuzzy";                                 # Auto-load subtitles
      sub-file-paths = "subs:subtitles:Subs:Subtitles";   # Subtitle directories
      slang = "en,eng";                                   # Preferred subtitle languages
      alang = "en,eng,jpn,ja";                            # Preferred audio languages

      # --- UI Settings ------------------------------------------------------
      osc = true;                             # Enable OSC with custom settings
      osd-bar = true;                         # Show OSD bar
      osd-font = "GeistMono Nerd Font";       # Project standard font
      osd-font-size = 32;
      osd-color = "#F8F8F2";                # Dracula foreground
      osd-border-color = "#15131F";         # Dracula background
      osd-shadow-offset = 1;
      osd-bar-align-y = 1;
      osd-border-size = 2;
      osd-bar-h = 2;
      osd-bar-w = 60;

      # --- Window Settings --------------------------------------------------
      keep-open = true;                      # Don't close after playback
      force-window = true;                   # Always show window
      snap-window = true;                    # Snap to screen edges
      autofit-larger = "90%x90%";            # Max initial window size
      geometry = "50%:50%";                  # Center window

      # --- Cache Settings ---------------------------------------------------
      cache = true;
      cache-dir = "${config.xdg.cacheHome}/mpv";
      cache-default = 150000000;             # 150MB cache (in bytes)
      cache-backbuffer = 25000000;           # 25MB backbuffer (in bytes)
      cache-secs = 10;

      # --- Network Settings -------------------------------------------------
      ytdl = true;                           # Enable yt-dlp
      ytdl-path = "${ytdlpPackage}/bin/yt-dlp"; # Use yt-dlp from Nix
      ytdl-format = ytdlpFormat;
      ytdl-raw-options = "ignore-config=,no-playlist=,sub-langs=en.*,live_chat";

      # --- Screenshot Settings ----------------------------------------------
      screenshot-format = "png";
      screenshot-png-compression = 8;
      screenshot-directory = "${config.home.homeDirectory}/Pictures/mpv";
      screenshot-template = "%F-%P-%n";

      # --- Other Settings ---------------------------------------------------
      save-position-on-quit = true;          # Remember playback position
      watch-later-directory = "${config.xdg.dataHome}/mpv/watch_later";
      input-ipc-server = "/tmp/mpvsocket";   # IPC for external control
    };

    # --- Key Bindings -------------------------------------------------------
    bindings = {
      # Playback control
      SPACE = "cycle pause";
      "Alt+SPACE" = "cycle pause";          # Alternative pause
      q = "quit";
      Q = "quit-watch-later";                # Quit and save position

      # Seeking
      RIGHT = "seek  5";
      LEFT = "seek -5";
      UP = "seek  60";
      DOWN = "seek -60";
      "Shift+RIGHT" = "seek  1 exact";      # Frame-by-frame
      "Shift+LEFT" = "seek -1 exact";
      "Ctrl+RIGHT" = "seek  10";
      "Ctrl+LEFT" = "seek -10";

      # Speed control
      "[" = "multiply speed 0.9091";        # Slow down
      "]" = "multiply speed 1.1";           # Speed up
      "{" = "multiply speed 0.5";           # Half speed
      "}" = "multiply speed 2.0";           # Double speed
      BACKSPACE = "set speed 1.0";          # Reset speed

      # Volume control
      m = "cycle mute";
      "9" = "add volume -2";
      "0" = "add volume 2";
      "/" = "add volume -2";
      "*" = "add volume 2";

      # Subtitle control
      v = "cycle sub-visibility";
      j = "cycle sub";                       # Cycle through subtitles
      J = "cycle sub down";                  # Previous subtitle
      z = "add sub-delay -0.1";              # Subtitle delay -100ms
      Z = "add sub-delay +0.1";              # Subtitle delay +100ms
      x = "set sub-delay 0";                 # Reset subtitle delay

      # Audio control
      "#" = "cycle audio";                   # Cycle through audio tracks
      "Shift+a" = "cycle audio down";        # Previous audio track
      "+" = "add audio-delay 0.100";         # Audio delay +100ms
      "-" = "add audio-delay -0.100";        # Audio delay -100ms
      "=" = "set audio-delay 0";             # Reset audio delay

      # Video control
      w = "add panscan -0.1";                # Zoom out
      W = "add panscan +0.1";                # Zoom in
      A = "cycle-values video-aspect-override 16:9 4:3 2.35:1 -1"; # Cycle aspect ratios
      d = "cycle deinterlace";               # Toggle deinterlace
      f = "cycle fullscreen";                # Toggle fullscreen

      # Screenshot
      s = "screenshot";                      # Take screenshot
      S = "screenshot video";                # Screenshot without subtitles
      "Ctrl+s" = "screenshot window";        # Screenshot window

      # Playlist
      ">" = "playlist-next";
      "<" = "playlist-prev";
      ENTER = "playlist-next";
      p = "show-progress";

      # Information
      i = "script-binding stats/display-stats";
      I = "script-binding stats/display-stats-toggle";
      "`" = "script-binding console/enable"; # Open console

      # Chapter navigation
      "!" = "add chapter -1";                # Previous chapter
      "@" = "add chapter 1";                 # Next chapter

      # Looping
      l = "cycle-values loop-file inf no";   # Loop current file
      L = "cycle-values loop-playlist inf no"; # Loop playlist
    };

    # --- Profiles -----------------------------------------------------------
    profiles = {
      fast = {
        # Inherits from base 'fast' profile
        vo = "gpu-next";
        hwdec = "auto";
        deband = false;
        interpolation = false;
      };

      "ultra-quality" = {
        profile = "gpu-hq";
        scale = "ewa_lanczossharp";
        cscale = "ewa_lanczossharp";
        dscale = "mitchell";
        deband = true;
        deband-iterations = 4;
        deband-threshold = 48;
        deband-range = 16;
        deband-grain = 48;
      };

      "web" = {
        profile = "gpu-hq";
        ytdl-format = ytdlpFormat;
        cache = true;
        cache-secs = 300;
      };
    };

    # --- Scripts ------------------------------------------------------------
    scripts = with pkgs.mpvScripts; [
      # Add useful scripts here as needed
      # mpris         # Media player integration
      # thumbnail     # Thumbnail previews
    ];

    # --- Script Options -----------------------------------------------------
    scriptOpts = {
      # OSC (On Screen Controller) customization with Dracula theme
      osc = {
        # Layout
        layout = "bottombar";                # Modern bottom bar
        seekbarstyle = "bar";                # Bar style seekbar
        deadzonesize = 0.5;                  # Deadzone size
        minmousemove = 0;                     # Minimum mouse movement

        # Visibility
        fadeduration = 200;                   # Fade animation duration
        idlescreen = true;                    # Hide when idle
        hidetimeout = 500;                    # Hide timeout
        visibility = "auto";                  # Auto hide/show

        # Sizing
        scalewindowed = 1.0;                  # Scale in windowed mode
        scalefullscreen = 1.0;                # Scale in fullscreen
        barmargin = 0;                        # Bar margin
        boxalpha = 80;                        # Box transparency

        # Features
        seekrangestyle = "inverted";          # Seek range style
        tooltipborder = 1;                    # Tooltip border
        timetotal = false;                    # Show total time
        timems = false;                       # Show milliseconds
        tcspace = 100;                        # Timecode spacing
      };

      # Stats display configuration
      stats = {
        duration = 4;
        redraw_delay = 1;
        persistent_overlay = false;
        plot_perfdata = true;
        plot_vsync_ratio = true;
        plot_vsync_jitter = true;
        timing_warning = true;
        timing_warning_th = 0.85;
        font = "GeistMono Nerd Font";
        font_mono = "GeistMono Nerd Font";
        font_size = 8;
        font_color = "F8F8F2";               # Dracula foreground
        border_size = 0.8;
        border_color = "94F2E8";             # Dracula Cyan
        alpha = 0;
        plot_bg_border_color = "44475a";     # Dracula selection
        plot_bg_color = "15131F";            # Dracula background
      };
    };
  };
}
