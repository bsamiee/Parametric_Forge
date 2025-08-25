# Title         : file-management.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /reference-implementation/darwin/file-management.nix
# ----------------------------------------------------------------------------
# Darwin-specific file management for macOS-only configuration files

{ config, lib, pkgs, ... }:

lib.mkIf pkgs.stdenv.isDarwin {
  # --- Darwin-Specific XDG Configuration Files --------------------------
  xdg.configFile = {
    # 1Password CLI configuration
    "op/config.json".source = ../configs/darwin/1password/config.json;
    
    # ImageMagick configuration (macOS-specific policies)
    "ImageMagick/policy.xml".source = ../configs/darwin/imagemagick/policy.xml;
    "ImageMagick/delegates.xml".source = ../configs/darwin/imagemagick/delegates.xml;
    
    # Neovim macOS-specific configuration
    "nvim/lua/config/darwin.lua".source = ../configs/darwin/neovim/darwin.lua;
    
    # FFmpeg macOS-specific configuration
    "ffmpeg/config".source = ../configs/darwin/ffmpeg/config;
    
    # macOS-specific git configuration
    "git/config.darwin".source = ../configs/darwin/git/config.darwin;
    
    # SSH configuration for macOS (1Password integration)
    "ssh/config.darwin".source = ../configs/darwin/ssh/config.darwin;
  };

  # --- Darwin-Specific Home Files ---------------------------------------
  home.file = {
    # duti configuration (must be in home directory for duti to find it)
    ".duti".source = ../configs/darwin/duti/settings;
    
    # macOS-specific shell scripts
    ".local/bin/dock-setup" = {
      source = ../configs/darwin/scripts/dock-setup.sh;
      executable = true;
    };
    
    ".local/bin/macos-defaults" = {
      source = ../configs/darwin/scripts/macos-defaults.sh;
      executable = true;
    };
    
    ".local/bin/1password-setup" = {
      source = ../configs/darwin/scripts/1password-setup.sh;
      executable = true;
    };
    
    # macOS-specific application support files
    "Library/Application Support/1Password CLI/config.json".source = ../configs/darwin/1password/app-support-config.json;
    
    # iTerm2 shell integration (if using iTerm2)
    ".iterm2_shell_integration.zsh".source = ../configs/darwin/iterm2/shell_integration.zsh;
    ".iterm2_shell_integration.bash".source = ../configs/darwin/iterm2/shell_integration.bash;
  };

  # --- Darwin-Specific Data Files ---------------------------------------
  xdg.dataFile = {
    # 1Password CLI data files
    "op/accounts.json".source = ../configs/darwin/1password/accounts.json;
    
    # macOS-specific application data
    "applications/darwin-apps.json".source = ../configs/darwin/applications/darwin-apps.json;
    
    # macOS-specific fonts (if any custom fonts are needed)
    "fonts/SF-Mono-Powerline.otf".source = ../configs/darwin/fonts/SF-Mono-Powerline.otf;
  };

  # --- Darwin-Specific Cache Directory Setup ----------------------------
  home.activation.setupDarwinCaches = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Create macOS-specific cache directories
    mkdir -p "${config.xdg.cacheHome}/op"
    mkdir -p "${config.xdg.cacheHome}/ImageMagick"
    mkdir -p "${config.xdg.cacheHome}/ffmpeg"
    mkdir -p "${config.home.homeDirectory}/Library/Caches/TemporaryItems"
    
    # Set appropriate permissions for cache directories
    chmod 700 "${config.xdg.cacheHome}/op"
    chmod 755 "${config.xdg.cacheHome}/ImageMagick"
    chmod 755 "${config.xdg.cacheHome}/ffmpeg"
  '';

  # --- Darwin-Specific State Directory Setup ----------------------------
  home.activation.setupDarwinState = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Create macOS-specific state directories
    mkdir -p "${config.xdg.stateHome}/op"
    mkdir -p "${config.xdg.stateHome}/dock"
    mkdir -p "${config.xdg.stateHome}/defaults"
    
    # Set appropriate permissions for state directories
    chmod 700 "${config.xdg.stateHome}/op"
    chmod 755 "${config.xdg.stateHome}/dock"
    chmod 755 "${config.xdg.stateHome}/defaults"
  '';

  # --- Darwin-Specific Application Setup --------------------------------
  home.activation.setupDarwinApplications = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Set up default applications using duti (if available)
    if command -v duti >/dev/null 2>&1 && [[ -f "$HOME/.duti" ]]; then
      echo "Setting up default applications..."
      duti "$HOME/.duti" 2>/dev/null || echo "Warning: Some default applications could not be set"
    fi
    
    # Set up 1Password CLI (if available)
    if command -v op >/dev/null 2>&1; then
      echo "Setting up 1Password CLI..."
      
      # Create necessary directories
      mkdir -p "${config.xdg.configHome}/op"
      mkdir -p "${config.xdg.cacheHome}/op"
      mkdir -p "${config.xdg.dataHome}/op"
      
      # Check if 1Password CLI is configured
      if ! op account list >/dev/null 2>&1; then
        echo "1Password CLI is not configured. Run 'op account add' to set up your account."
      else
        echo "1Password CLI is configured and ready to use."
      fi
    fi
    
    # Set up ImageMagick (if available)
    if command -v magick >/dev/null 2>&1; then
      echo "Setting up ImageMagick..."
      
      # Create ImageMagick cache directory
      mkdir -p "${config.xdg.cacheHome}/ImageMagick"
      
      # Test ImageMagick configuration
      magick -list configure >/dev/null 2>&1 || echo "Warning: ImageMagick configuration may have issues"
    fi
  '';

  # --- Darwin-Specific Cleanup ------------------------------------------
  home.activation.cleanupDarwinFiles = lib.hm.dag.entryBefore ["checkLinkTargets"] ''
    # Clean up old Darwin-specific files that may conflict
    
    # Remove old 1Password CLI configurations in wrong locations
    [[ -f "$HOME/.op/config" ]] && rm -f "$HOME/.op/config"
    [[ -d "$HOME/.op" ]] && rmdir "$HOME/.op" 2>/dev/null || true
    
    # Remove old ImageMagick configurations in wrong locations
    [[ -f "$HOME/.magick/policy.xml" ]] && rm -f "$HOME/.magick/policy.xml"
    [[ -d "$HOME/.magick" ]] && rmdir "$HOME/.magick" 2>/dev/null || true
    
    # Clean up macOS-specific temporary files
    find "${config.home.homeDirectory}" -name ".DS_Store" -delete 2>/dev/null || true
    find "${config.home.homeDirectory}" -name "._*" -delete 2>/dev/null || true
  '';
}