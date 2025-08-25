# Title         : environment.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /reference-implementation/darwin/environment.nix
# ----------------------------------------------------------------------------
# Darwin-specific environment variables and paths for macOS integration

{ config, lib, pkgs, ... }:

lib.mkIf pkgs.stdenv.isDarwin {
  home.sessionVariables = {
    # --- macOS System Integration -----------------------------------------
    # Use macOS-specific browser command
    BROWSER = "open";
    
    # macOS-specific temporary directory (secure)
    TMPDIR = "${config.home.homeDirectory}/Library/Caches/TemporaryItems";
    
    # macOS-specific editor integration
    EDITOR = lib.mkDefault "nvim";
    VISUAL = lib.mkDefault "nvim";
    
    # --- 1Password CLI Configuration --------------------------------------
    # Enable biometric unlock (Touch ID/Face ID)
    OP_BIOMETRIC_UNLOCK_ENABLED = "true";
    
    # 1Password CLI XDG-compliant paths
    OP_CONFIG_DIR = "${config.xdg.configHome}/op";
    OP_CACHE_DIR = "${config.xdg.cacheHome}/op";
    OP_DATA_DIR = "${config.xdg.dataHome}/op";
    
    # --- Media Tools (macOS-Specific Features) ----------------------------
    # FFmpeg macOS-specific features
    FFMPEG_DATADIR = "${config.xdg.dataHome}/ffmpeg";
    FFMPEG_AVFOUNDATION_ENABLED = "1";    # AVFoundation support
    FFMPEG_VIDEOTOOLBOX_ENABLED = "1";    # VideoToolbox hardware acceleration
    
    # ImageMagick macOS-specific configuration
    MAGICK_CONFIGURE_PATH = "${config.xdg.configHome}/ImageMagick";
    MAGICK_HOME = if pkgs.stdenv.isAarch64 then "/opt/homebrew" else "/usr/local";
    
    # --- macOS Development Environment ------------------------------------
    # Homebrew paths (architecture-specific)
    HOMEBREW_PREFIX = if pkgs.stdenv.isAarch64 then "/opt/homebrew" else "/usr/local";
    HOMEBREW_CELLAR = if pkgs.stdenv.isAarch64 then "/opt/homebrew/Cellar" else "/usr/local/Cellar";
    HOMEBREW_REPOSITORY = if pkgs.stdenv.isAarch64 then "/opt/homebrew" else "/usr/local/Homebrew";
    
    # macOS-specific compiler flags
    CPPFLAGS = "-I${if pkgs.stdenv.isAarch64 then "/opt/homebrew" else "/usr/local"}/include";
    LDFLAGS = "-L${if pkgs.stdenv.isAarch64 then "/opt/homebrew" else "/usr/local"}/lib";
    
    # --- macOS XDG Runtime Directory --------------------------------------
    # Use macOS-appropriate runtime directory
    XDG_RUNTIME_DIR = "${config.home.homeDirectory}/Library/Caches/TemporaryItems";
    
    # --- macOS-Specific Tool Configuration --------------------------------
    # Neovim application name for config isolation
    NVIM_APPNAME = "nvim";
    
    # macOS-specific less configuration
    LESS = "-R --use-color -Dd+r$Du+b$";
    
    # macOS-specific man page configuration
    MANPAGER = "nvim +Man!";
    MANWIDTH = "80";
    
    # --- macOS Security and Privacy ---------------------------------------
    # Disable telemetry for various tools (macOS-specific)
    HOMEBREW_NO_ANALYTICS = "1";
    HOMEBREW_NO_INSECURE_REDIRECT = "1";
    HOMEBREW_CASK_OPTS = "--require-sha";
    
    # --- macOS Terminal Integration ---------------------------------------
    # Terminal-specific configuration
    TERM_PROGRAM_VERSION = lib.mkDefault (builtins.getEnv "TERM_PROGRAM_VERSION");
    
    # macOS-specific color support
    COLORTERM = "truecolor";
    FORCE_COLOR = "1";
    
    # --- macOS File System Integration -----------------------------------
    # macOS-specific file operations
    COPYFILE_DISABLE = "1";  # Disable ._* files in tar archives
    
    # macOS-specific locale (if not set)
    LC_ALL = lib.mkDefault "en_US.UTF-8";
    LANG = lib.mkDefault "en_US.UTF-8";
  };

  # --- macOS-Specific PATH Extensions ------------------------------------
  home.sessionPath = [
    # Homebrew binary paths (architecture-specific)
    "${if pkgs.stdenv.isAarch64 then "/opt/homebrew" else "/usr/local"}/bin"
    "${if pkgs.stdenv.isAarch64 then "/opt/homebrew" else "/usr/local"}/sbin"
    
    # macOS system paths
    "/usr/local/bin"
    "/usr/local/sbin"
    
    # User-specific binary paths
    "${config.home.homeDirectory}/.local/bin"
    
    # 1Password CLI path (if installed via direct download)
    "${config.home.homeDirectory}/.local/share/op"
  ];

  # --- macOS-Specific Shell Integration ---------------------------------
  programs.zsh.initExtra = lib.mkIf config.programs.zsh.enable ''
    # macOS-specific zsh configuration
    
    # Enable macOS-specific completions
    if [[ -d /usr/local/share/zsh-completions ]]; then
      fpath=(/usr/local/share/zsh-completions $fpath)
    fi
    
    if [[ -d /opt/homebrew/share/zsh-completions ]]; then
      fpath=(/opt/homebrew/share/zsh-completions $fpath)
    fi
    
    # macOS-specific key bindings
    bindkey "^[[1;5C" forward-word      # Ctrl+Right
    bindkey "^[[1;5D" backward-word     # Ctrl+Left
    bindkey "^[[1;3C" forward-word      # Alt+Right
    bindkey "^[[1;3D" backward-word     # Alt+Left
    
    # macOS Terminal.app specific fixes
    if [[ "$TERM_PROGRAM" == "Apple_Terminal" ]]; then
      # Fix for Terminal.app color support
      export TERM="xterm-256color"
    fi
    
    # WezTerm specific configuration
    if [[ "$TERM_PROGRAM" == "WezTerm" ]]; then
      # Enable WezTerm-specific features
      export TERM="wezterm"
    fi
    
    # iTerm2 specific configuration
    if [[ "$TERM_PROGRAM" == "iTerm.app" ]]; then
      # Enable iTerm2 shell integration if available
      test -e "${config.home.homeDirectory}/.iterm2_shell_integration.zsh" && source "${config.home.homeDirectory}/.iterm2_shell_integration.zsh"
    fi
  '';

  programs.bash.initExtra = lib.mkIf config.programs.bash.enable ''
    # macOS-specific bash configuration
    
    # Enable macOS-specific completions
    if [[ -d /usr/local/etc/bash_completion.d ]]; then
      for completion in /usr/local/etc/bash_completion.d/*; do
        [[ -r "$completion" ]] && source "$completion"
      done
    fi
    
    if [[ -d /opt/homebrew/etc/bash_completion.d ]]; then
      for completion in /opt/homebrew/etc/bash_completion.d/*; do
        [[ -r "$completion" ]] && source "$completion"
      done
    fi
    
    # macOS-specific prompt configuration
    if [[ "$TERM_PROGRAM" == "Apple_Terminal" ]]; then
      export TERM="xterm-256color"
    fi
  '';
}