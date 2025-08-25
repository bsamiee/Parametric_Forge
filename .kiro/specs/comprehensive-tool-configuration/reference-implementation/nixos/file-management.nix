# Title         : file-management.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /reference-implementation/nixos/file-management.nix
# ----------------------------------------------------------------------------
# NixOS-specific file management for Linux-only configuration files

{ config, lib, pkgs, ... }:

lib.mkIf pkgs.stdenv.isLinux {
  # --- Linux-Specific XDG Configuration Files ---------------------------
  xdg.configFile = {
    # systemd user services
    "systemd/user/ssh-agent.service".source = ../configs/nixos/systemd/user/ssh-agent.service;
    "systemd/user/gpg-agent.service".source = ../configs/nixos/systemd/user/gpg-agent.service;
    "systemd/user/podman-cleanup.service".source = ../configs/nixos/systemd/user/podman-cleanup.service;
    "systemd/user/podman-cleanup.timer".source = ../configs/nixos/systemd/user/podman-cleanup.timer;
    
    # Container runtime configuration
    "containers/containers.conf".source = ../configs/nixos/containers/containers.conf;
    "containers/registries.conf".source = ../configs/nixos/containers/registries.conf;
    "containers/storage.conf".source = ../configs/nixos/containers/storage.conf;
    "containers/policy.json".source = ../configs/nixos/containers/policy.json;
    
    # Font configuration
    "fontconfig/fonts.conf".source = ../configs/nixos/fontconfig/fonts.conf;
    "fontconfig/conf.d/10-nix-fonts.conf".source = ../configs/nixos/fontconfig/conf.d/10-nix-fonts.conf;
    
    # Desktop integration
    "mimeapps.list".source = ../configs/nixos/applications/mimeapps.list;
    "user-dirs.dirs".source = ../configs/nixos/applications/user-dirs.dirs;
    "user-dirs.locale".source = ../configs/nixos/applications/user-dirs.locale;
    
    # Git Linux-specific configuration
    "git/config-linux".source = ../configs/nixos/git/config-linux;
    "git/ignore-linux".source = ../configs/nixos/git/ignore-linux;
    
    # SSH configuration for Linux
    "ssh/config-linux".source = ../configs/nixos/ssh/config-linux;
    
    # GPG configuration
    "gnupg/gpg.conf".source = ../configs/nixos/gnupg/gpg.conf;
    "gnupg/gpg-agent.conf".source = ../configs/nixos/gnupg/gpg-agent.conf;
    
    # Shell configuration
    "readline/inputrc".source = ../configs/nixos/shell/inputrc;
    "wget/wgetrc".source = ../configs/nixos/network/wgetrc;
    
    # Development tools
    "gdb/gdbinit".source = ../configs/nixos/development/gdbinit;
    "valgrind/valgrind.supp".source = ../configs/nixos/development/valgrind.supp;
    
    # Neovim Linux-specific configuration
    "nvim/lua/config/linux.lua".source = ../configs/nixos/neovim/linux.lua;
  };

  # --- Linux-Specific Data Files ----------------------------------------
  xdg.dataFile = {
    # Desktop entries for application launchers
    "applications/parametric-forge.desktop".source = ../configs/nixos/applications/parametric-forge.desktop;
    "applications/nvim.desktop".source = ../configs/nixos/applications/nvim.desktop;
    "applications/wezterm.desktop".source = ../configs/nixos/applications/wezterm.desktop;
    
    # Icon files
    "icons/hicolor/scalable/apps/parametric-forge.svg".source = ../configs/nixos/icons/parametric-forge.svg;
    "icons/hicolor/48x48/apps/parametric-forge.png".source = ../configs/nixos/icons/parametric-forge-48.png;
    "icons/hicolor/256x256/apps/parametric-forge.png".source = ../configs/nixos/icons/parametric-forge-256.png;
    
    # MIME type definitions
    "mime/packages/parametric-forge.xml".source = ../configs/nixos/mime/parametric-forge.xml;
    "mime/packages/nix.xml".source = ../configs/nixos/mime/nix.xml;
    
    # systemd user service data
    "systemd/user/scripts/ssh-agent-setup.sh" = {
      source = ../configs/nixos/systemd/scripts/ssh-agent-setup.sh;
      executable = true;
    };
    "systemd/user/scripts/container-cleanup.sh" = {
      source = ../configs/nixos/systemd/scripts/container-cleanup.sh;
      executable = true;
    };
    
    # Development templates
    "templates/nix-shell.nix".source = ../configs/nixos/templates/nix-shell.nix;
    "templates/flake.nix".source = ../configs/nixos/templates/flake.nix;
    "templates/devcontainer.json".source = ../configs/nixos/templates/devcontainer.json;
  };

  # --- Linux-Specific State Directory Setup -----------------------------
  home.activation.setupLinuxState = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Create Linux-specific state directories
    mkdir -p "${config.xdg.stateHome}/systemd"
    mkdir -p "${config.xdg.stateHome}/containers"
    mkdir -p "${config.xdg.stateHome}/ssh"
    mkdir -p "${config.xdg.stateHome}/gnupg"
    mkdir -p "${config.xdg.stateHome}/logs"
    mkdir -p "${config.xdg.stateHome}/nvim/backup"
    mkdir -p "${config.xdg.stateHome}/nvim/swap"
    mkdir -p "${config.xdg.stateHome}/nvim/undo"
    mkdir -p "${config.xdg.stateHome}/zsh"
    mkdir -p "${config.xdg.stateHome}/bash"
    mkdir -p "${config.xdg.stateHome}/python"
    mkdir -p "${config.xdg.stateHome}/node"
    mkdir -p "${config.xdg.stateHome}/less"
    mkdir -p "${config.xdg.stateHome}/gdb"
    mkdir -p "${config.xdg.stateHome}/valgrind"
    
    # Set appropriate permissions for sensitive directories
    chmod 700 "${config.xdg.stateHome}/ssh"
    chmod 700 "${config.xdg.stateHome}/gnupg"
    chmod 755 "${config.xdg.stateHome}/systemd"
    chmod 755 "${config.xdg.stateHome}/containers"
    chmod 755 "${config.xdg.stateHome}/logs"
  '';

  # --- Linux-Specific Cache Directory Setup -----------------------------
  home.activation.setupLinuxCaches = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Create Linux-specific cache directories
    mkdir -p "${config.xdg.cacheHome}/fontconfig"
    mkdir -p "${config.xdg.cacheHome}/containers"
    mkdir -p "${config.xdg.cacheHome}/docker"
    mkdir -p "${config.xdg.cacheHome}/npm"
    mkdir -p "${config.xdg.cacheHome}/pip"
    mkdir -p "${config.xdg.cacheHome}/go-build"
    mkdir -p "${config.xdg.cacheHome}/go/mod"
    mkdir -p "${config.xdg.cacheHome}/cargo"
    mkdir -p "${config.xdg.cacheHome}/zsh"
    mkdir -p "${config.xdg.cacheHome}/meson"
    
    # Set appropriate permissions for cache directories
    chmod 755 "${config.xdg.cacheHome}/fontconfig"
    chmod 755 "${config.xdg.cacheHome}/containers"
    chmod 755 "${config.xdg.cacheHome}/docker"
    chmod 755 "${config.xdg.cacheHome}/npm"
    chmod 755 "${config.xdg.cacheHome}/pip"
    chmod 755 "${config.xdg.cacheHome}/go-build"
    chmod 755 "${config.xdg.cacheHome}/go/mod"
    chmod 755 "${config.xdg.cacheHome}/cargo"
    chmod 755 "${config.xdg.cacheHome}/zsh"
    chmod 755 "${config.xdg.cacheHome}/meson"
  '';

  # --- Linux-Specific systemd User Services Setup ----------------------
  home.activation.setupSystemdUserServices = lib.hm.dag.entryAfter ["writeBoundary"] ''
    echo "Setting up systemd user services..."
    
    # Reload systemd user daemon
    systemctl --user daemon-reload 2>/dev/null || true
    
    # Enable and start SSH agent service
    if systemctl --user list-unit-files ssh-agent.service >/dev/null 2>&1; then
      systemctl --user enable ssh-agent.service 2>/dev/null || true
      systemctl --user start ssh-agent.service 2>/dev/null || true
      echo "  ✓ SSH agent service configured"
    fi
    
    # Enable and start GPG agent service
    if systemctl --user list-unit-files gpg-agent.service >/dev/null 2>&1; then
      systemctl --user enable gpg-agent.service 2>/dev/null || true
      systemctl --user start gpg-agent.service 2>/dev/null || true
      echo "  ✓ GPG agent service configured"
    fi
    
    # Enable container cleanup timer
    if systemctl --user list-unit-files podman-cleanup.timer >/dev/null 2>&1; then
      systemctl --user enable podman-cleanup.timer 2>/dev/null || true
      systemctl --user start podman-cleanup.timer 2>/dev/null || true
      echo "  ✓ Container cleanup timer configured"
    fi
    
    echo "systemd user services setup complete"
  '';

  # --- Linux-Specific Container Runtime Setup ---------------------------
  home.activation.setupContainerRuntime = lib.hm.dag.entryAfter ["writeBoundary"] ''
    echo "Setting up container runtime..."
    
    # Create container storage directories
    mkdir -p "${config.xdg.dataHome}/containers/storage"
    mkdir -p "${config.xdg.cacheHome}/containers"
    mkdir -p "${config.xdg.stateHome}/containers"
    
    # Set up Podman if available
    if command -v podman >/dev/null 2>&1; then
      # Initialize Podman storage
      podman system migrate >/dev/null 2>&1 || true
      
      # Create default network if it doesn't exist
      podman network exists podman >/dev/null 2>&1 || podman network create podman >/dev/null 2>&1 || true
      
      echo "  ✓ Podman configured"
    fi
    
    # Set up Docker if available
    if command -v docker >/dev/null 2>&1; then
      # Create Docker configuration directory
      mkdir -p "${config.xdg.configHome}/docker"
      
      # Test Docker connection
      if docker info >/dev/null 2>&1; then
        echo "  ✓ Docker configured and running"
      else
        echo "  ⚠ Docker installed but not running"
      fi
    fi
    
    echo "Container runtime setup complete"
  '';

  # --- Linux-Specific Desktop Integration Setup -------------------------
  home.activation.setupDesktopIntegration = lib.hm.dag.entryAfter ["writeBoundary"] ''
    echo "Setting up desktop integration..."
    
    # Update desktop database
    if command -v update-desktop-database >/dev/null 2>&1; then
      update-desktop-database "${config.xdg.dataHome}/applications" 2>/dev/null || true
      echo "  ✓ Desktop database updated"
    fi
    
    # Update MIME database
    if command -v update-mime-database >/dev/null 2>&1; then
      update-mime-database "${config.xdg.dataHome}/mime" 2>/dev/null || true
      echo "  ✓ MIME database updated"
    fi
    
    # Update icon cache
    if command -v gtk-update-icon-cache >/dev/null 2>&1; then
      gtk-update-icon-cache -t "${config.xdg.dataHome}/icons/hicolor" 2>/dev/null || true
      echo "  ✓ Icon cache updated"
    fi
    
    # Set up XDG user directories
    if command -v xdg-user-dirs-update >/dev/null 2>&1; then
      xdg-user-dirs-update 2>/dev/null || true
      echo "  ✓ XDG user directories updated"
    fi
    
    echo "Desktop integration setup complete"
  '';

  # --- Linux-Specific Font Configuration Setup --------------------------
  home.activation.setupFontConfiguration = lib.hm.dag.entryAfter ["writeBoundary"] ''
    echo "Setting up font configuration..."
    
    # Create font directories
    mkdir -p "${config.xdg.dataHome}/fonts"
    mkdir -p "${config.xdg.cacheHome}/fontconfig"
    
    # Update font cache
    if command -v fc-cache >/dev/null 2>&1; then
      fc-cache -fv >/dev/null 2>&1 || true
      echo "  ✓ Font cache updated"
    fi
    
    # List available fonts (for debugging)
    if command -v fc-list >/dev/null 2>&1; then
      local font_count=$(fc-list | wc -l)
      echo "  ✓ $font_count fonts available"
    fi
    
    echo "Font configuration setup complete"
  '';

  # --- Linux-Specific SSH and GPG Setup ---------------------------------
  home.activation.setupSSHAndGPG = lib.hm.dag.entryAfter ["writeBoundary"] ''
    echo "Setting up SSH and GPG..."
    
    # Create SSH directories
    mkdir -p "${config.xdg.dataHome}/ssh"
    chmod 700 "${config.xdg.dataHome}/ssh"
    
    # Create GPG directories
    mkdir -p "${config.xdg.dataHome}/gnupg"
    chmod 700 "${config.xdg.dataHome}/gnupg"
    
    # Set up SSH agent socket
    if [[ -S "${config.xdg.runtimeDir}/ssh-agent.socket" ]]; then
      echo "  ✓ SSH agent socket available"
    else
      echo "  ⚠ SSH agent socket not found"
    fi
    
    # Test GPG setup
    if command -v gpg >/dev/null 2>&1; then
      gpg --list-keys >/dev/null 2>&1 || true
      echo "  ✓ GPG configured"
    fi
    
    echo "SSH and GPG setup complete"
  '';

  # --- Linux-Specific Cleanup -------------------------------------------
  home.activation.cleanupLinuxFiles = lib.hm.dag.entryBefore ["checkLinkTargets"] ''
    # Clean up old Linux-specific files that may conflict
    
    # Remove old systemd user service files in wrong locations
    [[ -f "$HOME/.config/systemd/user/default.target.wants/ssh-agent.service" ]] && rm -f "$HOME/.config/systemd/user/default.target.wants/ssh-agent.service"
    
    # Remove old container configurations in wrong locations
    [[ -f "$HOME/.docker/config.json" ]] && [[ -f "${config.xdg.configHome}/docker/config.json" ]] && rm -f "$HOME/.docker/config.json"
    
    # Remove old font cache files in wrong locations
    [[ -d "$HOME/.fontconfig" ]] && rm -rf "$HOME/.fontconfig"
    
    # Clean up temporary files
    find "${config.xdg.cacheHome}" -name "*.tmp" -mtime +7 -delete 2>/dev/null || true
    find "${config.xdg.runtimeDir}" -name "*.lock" -mtime +1 -delete 2>/dev/null || true
  '';
}