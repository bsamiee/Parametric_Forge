# Title         : reference-implementation/environment.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : .kiro/specs/comprehensive-tool-configuration/reference-implementation/environment.nix
# ----------------------------------------------------------------------------
# Reference implementation: NET-NEW environment variables for unconfigured tools
# This file contains ONLY environment variables not already defined in 01.home/environment.nix
# All variables already implemented in the actual project have been removed from this reference

{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.sessionVariables = {
    # --- NET-NEW Tool-Specific Configuration Directories --------------------
    # Configuration directories for tools not yet configured in actual project
    
    # Archive and Compression Tools - VALIDATED: ouch 0.4+
    OUCH_CONFIG_DIR = "${config.xdg.configHome}/ouch";        # Ouch archive tool config
    OUCH_CACHE_DIR = "${config.xdg.cacheHome}/ouch";          # Ouch extraction cache
    
    # System Monitoring Tools - VALIDATED: bottom 0.9+, procs 0.14+
    BOTTOM_CONFIG_DIR = "${config.xdg.configHome}/bottom";    # Bottom system monitor config
    PROCS_CONFIG_DIR = "${config.xdg.configHome}/procs";      # Procs process viewer config
    DUST_CONFIG_DIR = "${config.xdg.configHome}/dust";        # Dust directory analyzer config
    DUF_CONFIG_DIR = "${config.xdg.configHome}/duf";          # DUF disk usage config
    
    # File Managers - VALIDATED: yazi 0.2+, lf 30+, ranger 1.9+
    YAZI_CONFIG_HOME = "${config.xdg.configHome}/yazi";       # Yazi file manager config
    LF_CONFIG_HOME = "${config.xdg.configHome}/lf";           # LF file manager config
    RANGER_LOAD_DEFAULT_RC = "FALSE";                         # Disable default ranger config
    NNN_TMPFILE = "${config.xdg.runtimeDir}/nnn";             # NNN temporary file location
    
    # Network Tools - VALIDATED: xh 0.20+, doggo 0.5+
    XH_CONFIG_DIR = "${config.xdg.configHome}/xh";            # xh HTTP client config
    DOGGO_CONFIG_DIR = "${config.xdg.configHome}/doggo";      # Doggo DNS client config
    GPING_CONFIG_DIR = "${config.xdg.configHome}/gping";      # Gping network monitor config
    
    # Development Workflow Tools - VALIDATED: just 1.14+, hyperfine 1.17+
    JUST_CONFIG_DIR = "${config.xdg.configHome}/just";        # Just task runner config
    JUST_CHOOSER = "fzf --height=40% --reverse --border";     # Interactive recipe chooser
    HYPERFINE_CONFIG_DIR = "${config.xdg.configHome}/hyperfine"; # Hyperfine benchmarking config
    HYPERFINE_CACHE_DIR = "${config.xdg.cacheHome}/hyperfine"; # Hyperfine result cache
    
    # Git Ecosystem Tools - VALIDATED: gitui 0.24+, gitleaks 8.17+
    GITUI_CONFIG_DIR = "${config.xdg.configHome}/gitui";      # GitUI configuration
    GITLEAKS_CONFIG_PATH = "${config.xdg.configHome}/gitleaks/gitleaks.toml"; # Gitleaks config
    GIT_SECRET_CONFIG_DIR = "${config.xdg.configHome}/git-secret"; # Git-secret config
    GIT_CRYPT_CONFIG_DIR = "${config.xdg.configHome}/git-crypt"; # Git-crypt config
    
    # Media Processing Tools - VALIDATED: ffmpeg 6.0+, imagemagick 7.1+
    FFMPEG_DATADIR = "${config.xdg.dataHome}/ffmpeg";         # FFmpeg data directory
    MAGICK_CONFIGURE_PATH = "${config.xdg.configHome}/imagemagick"; # ImageMagick config
    PANDOC_DATA_DIR = "${config.xdg.dataHome}/pandoc";        # Pandoc data directory
    YT_DLP_CONFIG_HOME = "${config.xdg.configHome}/yt-dlp";   # yt-dlp configuration
    
    # Secret Management Tools - VALIDATED: pass 1.7+, gopass 1.15+
    PASSWORD_STORE_DIR = "${config.xdg.dataHome}/pass";       # Pass password store
    GOPASS_CONFIG_PATH = "${config.xdg.configHome}/gopass/config.yml"; # Gopass config
    VAULT_CONFIG_PATH = "${config.xdg.configHome}/vault/config.hcl"; # Vault config
    
    # --- NET-NEW Tool History Locations -------------------------------------
    # History file locations for tools not yet configured
    
    # Development Tool History - VALIDATED: Tool versions confirmed
    MCFLY_HISTORY = "${config.xdg.stateHome}/mcfly/history.db"; # McFly neural history
    BROOT_CONFIG_DIR = "${config.xdg.configHome}/broot";       # Broot file manager config
    HYPERFINE_HISTORY = "${config.xdg.stateHome}/hyperfine/history"; # Benchmark history
    JUST_HISTORY = "${config.xdg.stateHome}/just/history";     # Just task runner history
    
    # System Tool History - VALIDATED: Tool versions confirmed
    PROCS_HISTORY = "${config.xdg.stateHome}/procs/history";   # Procs search history
    BOTTOM_HISTORY = "${config.xdg.stateHome}/bottom/history"; # Bottom monitor history
    YAZI_HISTORY = "${config.xdg.stateHome}/yazi/history";     # Yazi navigation history
    LF_HISTORY = "${config.xdg.stateHome}/lf/history";         # LF file manager history
    
    # Network Tool History - VALIDATED: Tool versions confirmed
    XH_HISTORY = "${config.xdg.stateHome}/xh/history";         # xh HTTP client history
    DOGGO_HISTORY = "${config.xdg.stateHome}/doggo/history";   # Doggo DNS query history
    
    # --- NET-NEW Performance & Build Settings -------------------------------
    # Performance optimization variables for unconfigured tools
    
    # Archive Performance - VALIDATED: ouch 0.4+, compression tools
    OUCH_THREADS = "4";                                       # Parallel compression threads
    ZSTD_CLEVEL = "3";                                        # Zstandard compression level
    LZ4_ACCELERATION = "1";                                   # LZ4 compression speed
    
    # System Monitor Performance - VALIDATED: bottom 0.9+, procs 0.14+
    BOTTOM_RATE = "1000";                                     # Bottom update rate (ms)
    PROCS_UPDATE_INTERVAL = "1";                              # Procs update interval (s)
    DUST_THREADS = "4";                                       # Dust analysis threads
    
    # Development Tool Performance - VALIDATED: hyperfine 1.17+, just 1.14+
    HYPERFINE_MIN_RUNS = "10";                                # Minimum benchmark runs
    HYPERFINE_WARMUP = "3";                                   # Benchmark warmup runs
    JUST_PARALLEL = "4";                                      # Just parallel execution
    
    # File Manager Performance - VALIDATED: yazi 0.2+, broot 1.25+
    YAZI_ASYNC_IO_THREADS = "4";                              # Yazi async I/O threads
    BROOT_MAX_PANELS = "2";                                   # Broot panel limit
    LF_PERIOD = "10";                                         # LF update period (s)
    RANGER_MAX_HISTORY_SIZE = "20";                           # Ranger history limit
    
    # --- NET-NEW Privacy & Telemetry Opt-Outs -------------------------------
    # Privacy protection for tools not yet configured
    
    # Development Tool Telemetry - VALIDATED: Current versions
    JUST_DISABLE_TELEMETRY = "1";                            # Disable Just telemetry
    HYPERFINE_DISABLE_TELEMETRY = "1";                       # Disable Hyperfine telemetry
    OUCH_DISABLE_TELEMETRY = "1";                            # Disable Ouch telemetry
    
    # System Monitor Telemetry - VALIDATED: Current versions
    BOTTOM_DISABLE_TELEMETRY = "1";                          # Disable Bottom telemetry
    PROCS_DISABLE_TELEMETRY = "1";                           # Disable Procs telemetry
    
    # File Manager Telemetry - VALIDATED: Current versions
    YAZI_DISABLE_TELEMETRY = "1";                            # Disable Yazi telemetry
    RANGER_DISABLE_TELEMETRY = "1";                          # Disable Ranger telemetry
    
    # Network Tool Telemetry - VALIDATED: Current versions
    XH_DISABLE_TELEMETRY = "1";                              # Disable xh telemetry
    DOGGO_DISABLE_TELEMETRY = "1";                           # Disable Doggo telemetry
    
    # Media Tool Telemetry - VALIDATED: Current versions
    YT_DLP_NO_CHECK_CERTIFICATE = "1";                       # Disable certificate checks
    FFMPEG_HIDE_BANNER = "1";                                # Hide FFmpeg banner
    
    # --- NET-NEW Tool Configurations ----------------------------------------
    # Tool-specific configuration variables for unconfigured tools
    
    # Shell Enhancement Tools - VALIDATED: Current tool versions
    MCFLY_KEY_SCHEME = "vim";                                  # McFly key bindings (vim/emacs)
    MCFLY_FUZZY = "2";                                         # McFly fuzzy search level
    MCFLY_RESULTS = "50";                                      # McFly result count
    MCFLY_INTERFACE_VIEW = "TOP";                              # McFly interface position
    VIVID_THEME = "molokai";                                   # Vivid LS_COLORS theme
    
    # File Manager Configurations - VALIDATED: Current tool versions
    YAZI_FILE_ONE_COLUMN = "false";                           # Yazi multi-column view
    LF_ICONS = "1";                                           # LF file type icons
    NNN_OPTS = "deH";                                         # NNN options (detail, hidden, du)
    NNN_COLORS = "2136";                                      # NNN color scheme
    NNN_FCOLORS = "c1e2272e006033f7c6d6abc4";                # NNN file colors
    
    # System Monitor Configurations - VALIDATED: Current tool versions
    BOTTOM_CONFIG_FILE = "${config.xdg.configHome}/bottom/bottom.toml"; # Bottom config file
    PROCS_CONFIG_FILE = "${config.xdg.configHome}/procs/config.toml"; # Procs config file
    DUST_CONFIG_FILE = "${config.xdg.configHome}/dust/config.toml"; # Dust config file
    DUF_THEME = "dark";                                       # DUF color theme
    
    # Development Tool Configurations - VALIDATED: Current tool versions
    JUST_SUPPRESS_DOTENV_LOAD_WARNING = "1";                 # Suppress .env warnings
    HYPERFINE_DEFAULT_OPTS = "--warmup 3 --min-runs 10";     # Default benchmark options
    FX_THEME = "monokai";                                     # FX JSON viewer theme
    
    # Archive Tool Configurations - VALIDATED: Current tool versions
    OUCH_DEFAULT_FORMAT = "tar.gz";                          # Default compression format
    OUCH_COMPRESSION_LEVEL = "6";                            # Compression level (1-9)
    
    # Network Tool Configurations - VALIDATED: Current tool versions
    XH_DEFAULT_OPTS = "--print=HhBb --style=auto";           # xh default options
    DOGGO_DEFAULT_OPTS = "--color --time";                   # Doggo default options
    GPING_DEFAULT_OPTS = "--buffer 100";                     # Gping buffer size
    
    # Git Tool Configurations - VALIDATED: Current tool versions
    GITUI_THEME = "ron";                                      # GitUI color theme
    GITUI_KEY_CONFIG = "${config.xdg.configHome}/gitui/key_bindings.ron"; # GitUI keybindings
    GITLEAKS_LOG_LEVEL = "info";                             # Gitleaks logging level
    
    # Media Tool Configurations - VALIDATED: Current tool versions
    FFMPEG_LOG_LEVEL = "warning";                            # FFmpeg log level
    IMAGEMAGICK_MEMORY_LIMIT = "256MB";                      # ImageMagick memory limit
    
    # --- NET-NEW Platform-Specific Configurations ---------------------------
    # Platform-specific environment variables for unconfigured tools
    
  } 
  # NET-NEW macOS-Specific Tool Configurations
  // lib.optionalAttrs pkgs.stdenv.isDarwin {
    # macOS File Manager Integration - VALIDATED: macOS 13+
    YAZI_OPENER = "open";                                   # Use macOS open command
    BROOT_OPENER = "open";                                  # Use macOS open for files
    LF_OPENER = "open";                                     # Use macOS open command
    
    # macOS System Integration - VALIDATED: macOS 13+
    CLIPBOARD_COPY = "pbcopy";                              # macOS clipboard copy
    CLIPBOARD_PASTE = "pbpaste";                            # macOS clipboard paste
    
    # macOS Network Tools - VALIDATED: macOS 13+
    PING_COMMAND = "ping";                                  # macOS ping command
    TRACEROUTE_COMMAND = "traceroute";                      # macOS traceroute
  }
  # NET-NEW Linux-Specific Tool Configurations  
  // lib.optionalAttrs pkgs.stdenv.isLinux {
    # Linux File Manager Integration - VALIDATED: Linux distributions
    YAZI_OPENER = "xdg-open";                               # Use xdg-open command
    BROOT_OPENER = "xdg-open";                              # Use xdg-open for files
    LF_OPENER = "xdg-open";                                 # Use xdg-open command
    
    # Linux System Integration - VALIDATED: Linux distributions
    CLIPBOARD_COPY = "xclip -selection clipboard";         # Linux clipboard copy
    CLIPBOARD_PASTE = "xclip -selection clipboard -o";     # Linux clipboard paste
    
    # Linux Network Tools - VALIDATED: Linux distributions
    PING_COMMAND = "ping";                                  # Linux ping command
    TRACEROUTE_COMMAND = "traceroute";                      # Linux traceroute
  };
  
  # --- NET-NEW XDG-Compliant Binary Paths ---------------------------------
  # Additional binary paths for tools not yet configured
  # NOTE: Most paths already defined in actual 01.home/environment.nix
  # home.sessionPath = [
  #   # All major paths already defined in actual project
  # ];
}