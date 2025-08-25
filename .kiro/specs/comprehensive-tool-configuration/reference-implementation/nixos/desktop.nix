# Title         : desktop.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /reference-implementation/nixos/desktop.nix
# ----------------------------------------------------------------------------
# NixOS-specific desktop integration and XDG configuration

{ config, lib, pkgs, ... }:

lib.mkIf pkgs.stdenv.isLinux {
  # --- XDG User Directories Configuration -------------------------------
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    desktop = "${config.home.homeDirectory}/Desktop";
    documents = "${config.home.homeDirectory}/Documents";
    download = "${config.home.homeDirectory}/Downloads";
    music = "${config.home.homeDirectory}/Music";
    pictures = "${config.home.homeDirectory}/Pictures";
    videos = "${config.home.homeDirectory}/Videos";
    templates = "${config.home.homeDirectory}/Templates";
    publicShare = "${config.home.homeDirectory}/Public";
    
    # Additional development directories
    extraConfig = {
      XDG_PROJECTS_DIR = "${config.home.homeDirectory}/Projects";
      XDG_DEVELOPMENT_DIR = "${config.home.homeDirectory}/Development";
      XDG_WORKSPACE_DIR = "${config.home.homeDirectory}/Workspace";
    };
  };

  # --- MIME Type Associations --------------------------------------------
  xdg.mimeApps = {
    enable = true;
    
    defaultApplications = {
      # Text and source code files
      "text/plain" = "nvim.desktop";
      "text/x-shellscript" = "nvim.desktop";
      "text/x-python" = "nvim.desktop";
      "text/x-rust" = "nvim.desktop";
      "text/x-go" = "nvim.desktop";
      "text/x-javascript" = "nvim.desktop";
      "text/x-typescript" = "nvim.desktop";
      "text/x-c" = "nvim.desktop";
      "text/x-c++" = "nvim.desktop";
      "text/x-java" = "nvim.desktop";
      
      # Configuration files
      "application/json" = "nvim.desktop";
      "application/xml" = "nvim.desktop";
      "text/x-yaml" = "nvim.desktop";
      "text/x-toml" = "nvim.desktop";
      "text/x-ini" = "nvim.desktop";
      "text/x-conf" = "nvim.desktop";
      
      # Markup and documentation
      "text/markdown" = "nvim.desktop";
      "text/x-rst" = "nvim.desktop";
      "text/x-asciidoc" = "nvim.desktop";
      
      # Nix files
      "text/x-nix" = "nvim.desktop";
      
      # Images
      "image/png" = "org.gnome.eog.desktop";
      "image/jpeg" = "org.gnome.eog.desktop";
      "image/gif" = "org.gnome.eog.desktop";
      "image/bmp" = "org.gnome.eog.desktop";
      "image/tiff" = "org.gnome.eog.desktop";
      "image/webp" = "org.gnome.eog.desktop";
      "image/svg+xml" = "org.gnome.eog.desktop";
      
      # Documents
      "application/pdf" = "org.gnome.Evince.desktop";
      "application/postscript" = "org.gnome.Evince.desktop";
      
      # Archives
      "application/zip" = "org.gnome.FileRoller.desktop";
      "application/x-tar" = "org.gnome.FileRoller.desktop";
      "application/gzip" = "org.gnome.FileRoller.desktop";
      "application/x-bzip2" = "org.gnome.FileRoller.desktop";
      "application/x-7z-compressed" = "org.gnome.FileRoller.desktop";
      "application/x-rar-compressed" = "org.gnome.FileRoller.desktop";
      
      # Media files
      "video/mp4" = "org.gnome.Totem.desktop";
      "video/x-msvideo" = "org.gnome.Totem.desktop";
      "video/quicktime" = "org.gnome.Totem.desktop";
      "video/x-matroska" = "org.gnome.Totem.desktop";
      "video/webm" = "org.gnome.Totem.desktop";
      
      "audio/mpeg" = "org.gnome.Rhythmbox3.desktop";
      "audio/ogg" = "org.gnome.Rhythmbox3.desktop";
      "audio/flac" = "org.gnome.Rhythmbox3.desktop";
      "audio/wav" = "org.gnome.Rhythmbox3.desktop";
      "audio/mp4" = "org.gnome.Rhythmbox3.desktop";
      
      # Web content
      "text/html" = "firefox.desktop";
      "application/xhtml+xml" = "firefox.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "x-scheme-handler/ftp" = "firefox.desktop";
      
      # Email
      "x-scheme-handler/mailto" = "thunderbird.desktop";
      
      # Terminal
      "application/x-terminal-emulator" = "wezterm.desktop";
    };
    
    associations.added = {
      # Additional associations for development files
      "text/x-dockerfile" = "nvim.desktop";
      "text/x-makefile" = "nvim.desktop";
      "text/x-cmake" = "nvim.desktop";
      "application/x-yaml" = "nvim.desktop";
      "application/toml" = "nvim.desktop";
      
      # Container and virtualization files
      "application/x-docker-compose" = "nvim.desktop";
      "application/x-vagrant" = "nvim.desktop";
      
      # Database files
      "application/x-sqlite3" = "sqlitebrowser.desktop";
      "application/sql" = "nvim.desktop";
    };
  };

  # --- Desktop Entries for Custom Applications --------------------------
  xdg.desktopEntries = {
    # Parametric Forge interface
    parametric-forge = {
      name = "Parametric Forge";
      comment = "System configuration management interface";
      exec = "parametric-forge-interface";
      icon = "parametric-forge";
      terminal = true;
      categories = [ "Development" "System" "Settings" ];
      mimeType = [ "text/x-nix" ];
      keywords = [ "nix" "configuration" "system" "dotfiles" ];
      startupNotify = true;
    };
    
    # Neovim desktop entry
    nvim = {
      name = "Neovim";
      comment = "Hyperextensible Vim-based text editor";
      exec = "wezterm start -- nvim %F";
      icon = "nvim";
      terminal = false;
      categories = [ "Development" "TextEditor" ];
      mimeType = [
        "text/plain"
        "text/x-shellscript"
        "text/x-python"
        "text/x-rust"
        "text/x-go"
        "text/x-javascript"
        "text/x-typescript"
        "text/x-c"
        "text/x-c++"
        "text/x-java"
        "application/json"
        "application/xml"
        "text/x-yaml"
        "text/x-toml"
        "text/markdown"
        "text/x-nix"
      ];
      keywords = [ "vim" "editor" "text" "development" ];
      startupNotify = true;
    };
    
    # WezTerm desktop entry
    wezterm = {
      name = "WezTerm";
      comment = "A GPU-accelerated cross-platform terminal emulator";
      exec = "wezterm start";
      icon = "wezterm";
      terminal = false;
      categories = [ "System" "TerminalEmulator" ];
      keywords = [ "terminal" "shell" "console" ];
      startupNotify = true;
    };
    
    # Container management
    podman-desktop = {
      name = "Podman Desktop";
      comment = "Manage containers with Podman";
      exec = "wezterm start -- podman";
      icon = "podman";
      terminal = false;
      categories = [ "Development" "System" ];
      keywords = [ "container" "docker" "podman" ];
      startupNotify = true;
    };
    
    # System monitoring
    system-monitor = {
      name = "System Monitor";
      comment = "Monitor system resources and processes";
      exec = "wezterm start -- btm";
      icon = "utilities-system-monitor";
      terminal = false;
      categories = [ "System" "Monitor" ];
      keywords = [ "system" "monitor" "process" "resource" ];
      startupNotify = true;
    };
  };

  # --- Portal Configuration ----------------------------------------------
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
    ];
    config = {
      common = {
        default = [ "gtk" ];
      };
      gnome = {
        default = [ "gnome" "gtk" ];
        "org.freedesktop.impl.portal.FileChooser" = [ "gnome" ];
        "org.freedesktop.impl.portal.AppChooser" = [ "gnome" ];
        "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
        "org.freedesktop.impl.portal.Screencast" = [ "gnome" ];
      };
    };
  };

  # --- Desktop Environment Integration -----------------------------------
  # Session variables for desktop integration
  home.sessionVariables = {
    # Desktop environment detection
    XDG_CURRENT_DESKTOP = lib.mkDefault "GNOME";
    XDG_SESSION_TYPE = lib.mkDefault "wayland";
    XDG_SESSION_DESKTOP = lib.mkDefault "gnome";
    DESKTOP_SESSION = lib.mkDefault "gnome";
    
    # Application integration
    XDG_MENU_PREFIX = "gnome-";
    
    # File manager integration
    FILE_MANAGER = "nautilus";
    
    # Terminal integration
    TERMINAL = "wezterm";
    
    # Browser integration
    BROWSER = "firefox";
    
    # Editor integration
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  # --- Desktop Integration Scripts ---------------------------------------
  home.activation.setupDesktopScripts = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Create desktop integration helper scripts
    
    cat > "${config.home.homeDirectory}/.local/bin/desktop-integration" << 'EOF'
#!/usr/bin/env bash
# Desktop integration helper script

case "$1" in
  "update-all")
    echo "Updating desktop integration..."
    
    # Update desktop database
    if command -v update-desktop-database >/dev/null 2>&1; then
      update-desktop-database "${config.xdg.dataHome}/applications"
      echo "  ✓ Desktop database updated"
    fi
    
    # Update MIME database
    if command -v update-mime-database >/dev/null 2>&1; then
      update-mime-database "${config.xdg.dataHome}/mime"
      echo "  ✓ MIME database updated"
    fi
    
    # Update icon cache
    if command -v gtk-update-icon-cache >/dev/null 2>&1; then
      gtk-update-icon-cache -t "${config.xdg.dataHome}/icons/hicolor" 2>/dev/null || true
      echo "  ✓ Icon cache updated"
    fi
    
    # Update XDG user directories
    if command -v xdg-user-dirs-update >/dev/null 2>&1; then
      xdg-user-dirs-update
      echo "  ✓ XDG user directories updated"
    fi
    
    echo "Desktop integration update complete"
    ;;
    
  "open-file")
    if [[ -z "$2" ]]; then
      echo "Usage: desktop-integration open-file <file>"
      exit 1
    fi
    xdg-open "$2"
    ;;
    
  "open-folder")
    if [[ -z "$2" ]]; then
      folder="$PWD"
    else
      folder="$2"
    fi
    xdg-open "$folder"
    ;;
    
  "set-default")
    if [[ -z "$2" ]] || [[ -z "$3" ]]; then
      echo "Usage: desktop-integration set-default <mime-type> <application>"
      exit 1
    fi
    xdg-mime default "$3" "$2"
    echo "Set $3 as default for $2"
    ;;
    
  "get-default")
    if [[ -z "$2" ]]; then
      echo "Usage: desktop-integration get-default <mime-type>"
      exit 1
    fi
    xdg-mime query default "$2"
    ;;
    
  "list-apps")
    echo "Available applications:"
    find "${config.xdg.dataHome}/applications" /usr/share/applications -name "*.desktop" -exec basename {} \; 2>/dev/null | sort -u
    ;;
    
  "status")
    echo "Desktop Integration Status:"
    echo "=========================="
    
    echo ""
    echo "XDG User Directories:"
    for dir in DESKTOP DOCUMENTS DOWNLOAD MUSIC PICTURES VIDEOS TEMPLATES PUBLICSHARE; do
      var="XDG_''${dir}_DIR"
      path="$(xdg-user-dir ''${dir} 2>/dev/null || echo "not set")"
      if [[ -d "$path" ]]; then
        echo "  ✓ $dir: $path"
      else
        echo "  ✗ $dir: $path (missing)"
      fi
    done
    
    echo ""
    echo "Desktop Environment:"
    echo "  XDG_CURRENT_DESKTOP: ''${XDG_CURRENT_DESKTOP:-not set}"
    echo "  XDG_SESSION_TYPE: ''${XDG_SESSION_TYPE:-not set}"
    echo "  XDG_SESSION_DESKTOP: ''${XDG_SESSION_DESKTOP:-not set}"
    echo "  DESKTOP_SESSION: ''${DESKTOP_SESSION:-not set}"
    
    echo ""
    echo "Default Applications:"
    for mime in "text/plain" "image/png" "application/pdf" "x-scheme-handler/http"; do
      default="$(xdg-mime query default "$mime" 2>/dev/null || echo "not set")"
      echo "  $mime: $default"
    done
    
    echo ""
    echo "Portal Status:"
    if command -v xdg-desktop-portal >/dev/null 2>&1; then
      echo "  ✓ xdg-desktop-portal available"
    else
      echo "  ✗ xdg-desktop-portal not available"
    fi
    ;;
    
  *)
    echo "Usage: desktop-integration {update-all|open-file|open-folder|set-default|get-default|list-apps|status}"
    exit 1
    ;;
esac
EOF
    
    chmod +x "${config.home.homeDirectory}/.local/bin/desktop-integration"
  '';

  # --- Notification Integration ------------------------------------------
  home.activation.setupNotificationIntegration = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Create notification helper script
    
    cat > "${config.home.homeDirectory}/.local/bin/notify" << 'EOF'
#!/usr/bin/env bash
# Notification helper script

if command -v notify-send >/dev/null 2>&1; then
  # Use notify-send if available
  case "$1" in
    "info")
      notify-send -i "dialog-information" "Info" "$2"
      ;;
    "warning")
      notify-send -i "dialog-warning" "Warning" "$2"
      ;;
    "error")
      notify-send -i "dialog-error" "Error" "$2"
      ;;
    "success")
      notify-send -i "dialog-ok" "Success" "$2"
      ;;
    *)
      notify-send "$1" "$2"
      ;;
  esac
else
  # Fallback to echo
  echo "[$1] $2"
fi
EOF
    
    chmod +x "${config.home.homeDirectory}/.local/bin/notify"
  '';

  # --- Theme Integration -------------------------------------------------
  # GTK theme configuration
  gtk = {
    enable = true;
    
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome.gnome-themes-extra;
    };
    
    iconTheme = {
      name = "Adwaita";
      package = pkgs.gnome.adwaita-icon-theme;
    };
    
    cursorTheme = {
      name = "Adwaita";
      package = pkgs.gnome.adwaita-icon-theme;
      size = 24;
    };
    
    font = {
      name = "DejaVu Sans";
      size = 11;
    };
    
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
      gtk-button-images = true;
      gtk-menu-images = true;
      gtk-enable-event-sounds = false;
      gtk-enable-input-feedback-sounds = false;
      gtk-xft-antialias = 1;
      gtk-xft-hinting = 1;
      gtk-xft-hintstyle = "hintslight";
      gtk-xft-rgba = "rgb";
    };
    
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
      gtk-enable-event-sounds = false;
      gtk-enable-input-feedback-sounds = false;
    };
  };

  # Qt theme configuration
  qt = {
    enable = true;
    platformTheme = "gnome";
    style = {
      name = "adwaita-dark";
      package = pkgs.adwaita-qt;
    };
  };

  # --- Fonts Configuration -----------------------------------------------
  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      serif = [ "DejaVu Serif" "Liberation Serif" ];
      sansSerif = [ "DejaVu Sans" "Liberation Sans" ];
      monospace = [ "JetBrains Mono" "DejaVu Sans Mono" "Liberation Mono" ];
      emoji = [ "Noto Color Emoji" ];
    };
  };
}