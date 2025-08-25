# Linux/NixOS-Specific Configuration Requirements

## Overview

This document provides comprehensive documentation for Linux/NixOS-specific configuration requirements, including tools that require Linux-specific handling, Linux-specific file paths and environment variables, and integration patterns with existing NixOS configuration structures.

## Linux/NixOS-Specific Tools Analysis

### Tools Requiring Linux-Specific Configuration

Based on the tool inventory and research, the following tools require Linux-specific configuration handling:

#### Linux-Only Tools (8 tools)
1. **systemd** - System and service manager (built into NixOS)
2. **NetworkManager** - Network connection manager
3. **openssh** - SSH daemon and client (Linux-specific service configuration)
4. **dbus** - Inter-process communication system
5. **fontconfig** - Font configuration and customization library
6. **xdg-utils** - Desktop integration utilities (xdg-open, xdg-mime, etc.)
7. **desktop file utilities** - .desktop file management for application launchers
8. **container runtimes** - Docker, Podman, containerd (Linux-specific features)

#### Cross-Platform Tools with Linux-Specific Requirements (12 tools)
1. **neovim** - Text editor (Linux-specific clipboard and desktop integration)
2. **git** - Version control (Linux-specific credential helpers and SSH agent integration)
3. **docker** - Container runtime (Linux-specific daemon configuration)
4. **podman** - Rootless container runtime (Linux-specific)
5. **colima** - Container runtime (primarily for macOS, limited Linux support)
6. **gnupg** - Encryption and signing (Linux-specific agent configuration)
7. **zsh** - Shell (Linux-specific completion and integration)
8. **starship** - Shell prompt (Linux-specific terminal detection)
9. **direnv** - Environment variable management (Linux-specific shell integration)
10. **fzf** - Fuzzy finder (Linux-specific key bindings and integration)
11. **bat** - Syntax highlighter (Linux-specific pager integration)
12. **ripgrep** - Text search (Linux-specific file system integration)

## Linux/NixOS-Specific File Paths and Environment Variables

### System-Level Paths

#### Linux System Directories
```bash
# System configuration directories
/etc/                     # System-wide configuration files
/etc/nixos/               # NixOS system configuration
/etc/systemd/             # systemd configuration
/usr/share/               # Shared data files
/usr/local/               # Local system binaries and data
/var/lib/                 # Variable state information
/var/log/                 # System log files
/run/                     # Runtime data (tmpfs)
/run/user/$UID/           # User runtime directory (XDG_RUNTIME_DIR)

# User-specific Linux directories
~/.local/                 # User-local files (XDG-compliant)
~/.local/bin/             # User binaries
~/.local/share/           # User data files (XDG_DATA_HOME)
~/.local/state/           # User state files (XDG_STATE_HOME)
~/.config/                # User configuration files (XDG_CONFIG_HOME)
~/.cache/                 # User cache files (XDG_CACHE_HOME)
```

#### XDG Base Directory Implementation for Linux
```bash
# Standard XDG Base Directory specification (Linux native)
XDG_CONFIG_HOME="$HOME/.config"           # User configuration files
XDG_DATA_HOME="$HOME/.local/share"        # User data files
XDG_CACHE_HOME="$HOME/.cache"             # User cache files
XDG_STATE_HOME="$HOME/.local/state"       # User state files
XDG_RUNTIME_DIR="/run/user/$UID"          # User runtime files (tmpfs)

# Additional XDG directories for desktop integration
XDG_DATA_DIRS="/usr/local/share:/usr/share"  # System data directories
XDG_CONFIG_DIRS="/etc/xdg"                   # System configuration directories
XDG_DESKTOP_DIR="$HOME/Desktop"              # Desktop directory
XDG_DOWNLOAD_DIR="$HOME/Downloads"           # Downloads directory
XDG_TEMPLATES_DIR="$HOME/Templates"          # Templates directory
XDG_PUBLICSHARE_DIR="$HOME/Public"           # Public share directory
XDG_DOCUMENTS_DIR="$HOME/Documents"          # Documents directory
XDG_MUSIC_DIR="$HOME/Music"                  # Music directory
XDG_PICTURES_DIR="$HOME/Pictures"            # Pictures directory
XDG_VIDEOS_DIR="$HOME/Videos"                # Videos directory
```

### Tool-Specific Linux Environment Variables

#### systemd Integration
```bash
# systemd user service environment
SYSTEMD_USER_CONFIG_DIR="$XDG_CONFIG_HOME/systemd/user"
SYSTEMD_USER_DATA_DIR="$XDG_DATA_HOME/systemd/user"
SYSTEMD_USER_RUNTIME_DIR="$XDG_RUNTIME_DIR/systemd"
SYSTEMD_LOG_LEVEL="info"                     # Logging level for user services
SYSTEMD_LOG_TARGET="journal"                 # Log target (journal, console, syslog)
```

#### Desktop Integration
```bash
# Desktop environment integration
XDG_CURRENT_DESKTOP="GNOME"                  # Current desktop environment (varies)
XDG_SESSION_TYPE="wayland"                   # Session type (wayland, x11)
XDG_SESSION_DESKTOP="gnome"                  # Session desktop (varies)
DESKTOP_SESSION="gnome"                      # Desktop session (legacy)

# Application launcher integration
XDG_MENU_PREFIX="gnome-"                     # Menu prefix for desktop files
XDG_APPLICATIONS_DIRS="$XDG_DATA_HOME/applications:/usr/local/share/applications:/usr/share/applications"
```

#### Container Runtime (Linux-Specific)
```bash
# Docker Linux-specific
DOCKER_HOST="unix:///var/run/docker.sock"    # Docker daemon socket
DOCKER_CONFIG="$XDG_CONFIG_HOME/docker"      # Docker client configuration
DOCKER_BUILDKIT="1"                          # Enable BuildKit
COMPOSE_DOCKER_CLI_BUILD="1"                 # Use Docker CLI for builds

# Podman Linux-specific
CONTAINERS_CONF="$XDG_CONFIG_HOME/containers/containers.conf"
CONTAINERS_REGISTRIES_CONF="$XDG_CONFIG_HOME/containers/registries.conf"
CONTAINERS_STORAGE_CONF="$XDG_CONFIG_HOME/containers/storage.conf"
PODMAN_USERNS="keep-id"                      # User namespace handling
```

#### Font Configuration (Linux-Specific)
```bash
# Fontconfig Linux-specific
FONTCONFIG_PATH="$XDG_CONFIG_HOME/fontconfig"
FONTCONFIG_FILE="$XDG_CONFIG_HOME/fontconfig/fonts.conf"
FONTCONFIG_CACHE="$XDG_CACHE_HOME/fontconfig"
FC_DEBUG="0"                                 # Fontconfig debug level
FC_LANG="en"                                 # Font language preference
```

#### SSH and GPG Integration (Linux-Specific)
```bash
# SSH agent integration
SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"  # SSH agent socket
SSH_AGENT_PID="$(pgrep -u $USER ssh-agent)"        # SSH agent process ID

# GPG agent integration
GNUPGHOME="$XDG_DATA_HOME/gnupg"             # GPG home directory
GPG_TTY="$(tty)"                             # GPG TTY for pinentry
GPG_AGENT_INFO="$XDG_RUNTIME_DIR/gnupg/S.gpg-agent:$(pgrep -u $USER gpg-agent):1"
```

#### Development Tools (Linux-Specific Features)
```bash
# Neovim Linux-specific
NVIM_APPNAME="nvim"                          # Application name
NVIM_LOG_FILE="$XDG_STATE_HOME/nvim/log"     # Log file location
# Linux clipboard integration (automatic via xclip/wl-clipboard)

# Git Linux-specific
GIT_SSH_COMMAND="ssh -o ControlMaster=auto -o ControlPersist=60s"  # SSH multiplexing
GIT_ASKPASS="/usr/bin/ssh-askpass"           # SSH password prompt (if available)

# Shell integration (Linux-specific)
SHELL="/run/current-system/sw/bin/zsh"       # NixOS shell path
TERM="xterm-256color"                        # Terminal type
COLORTERM="truecolor"                        # Color support
```

## Conditional Configuration Examples

### Programs Configuration (Linux-Specific)

#### Example: Linux-Specific Program Configuration
```nix
# Title         : linux-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/programs/linux-tools.nix
# ----------------------------------------------------------------------------
# Linux-specific tool configurations using home-manager programs

{ config, lib, pkgs, ... }:

lib.mkIf pkgs.stdenv.isLinux {
  # --- Git Configuration (Linux-Specific) -----------------------------------
  programs.git = {
    extraConfig = {
      # Linux-specific credential helper
      credential.helper = lib.mkIf (pkgs.stdenv.isLinux) "store";
      
      # SSH multiplexing for better performance
      core.sshCommand = "ssh -o ControlMaster=auto -o ControlPersist=60s";
      
      # Linux-specific diff and merge tools
      diff.tool = "vimdiff";
      merge.tool = "vimdiff";
      
      # Linux-specific pager configuration
      core.pager = "delta --features=side-by-side";
    };
  };

  # --- SSH Configuration (Linux-Specific) -----------------------------------
  programs.ssh = {
    enable = true;
    controlMaster = "auto";
    controlPersist = "60s";
    controlPath = "${config.xdg.runtimeDir}/ssh-%r@%h:%p";
    
    # Linux-specific SSH configuration
    extraConfig = ''
      # Use system SSH agent
      AddKeysToAgent yes
      IdentityAgent $SSH_AUTH_SOCK
      
      # Linux-specific security settings
      HashKnownHosts yes
      VerifyHostKeyDNS ask
      
      # Performance optimizations for Linux
      Compression yes
      ServerAliveInterval 60
      ServerAliveCountMax 3
    '';
  };

  # --- GPG Configuration (Linux-Specific) -----------------------------------
  programs.gpg = {
    enable = true;
    homedir = "${config.xdg.dataHome}/gnupg";
    
    settings = {
      # Linux-specific GPG settings
      use-agent = true;
      charset = "utf-8";
      fixed-list-mode = true;
      keyid-format = "0xlong";
      list-options = "show-uid-validity";
      verify-options = "show-uid-validity";
      with-fingerprint = true;
      
      # Linux-specific keyserver configuration
      keyserver = "hkps://keys.openpgp.org";
      keyserver-options = "auto-key-retrieve";
    };
  };

  # --- Shell Configuration (Linux-Specific) ---------------------------------
  programs.zsh = {
    initExtra = lib.mkAfter ''
      # Linux-specific shell configuration
      
      # Set up SSH agent if not already running
      if [[ -z "$SSH_AUTH_SOCK" ]]; then
        eval "$(ssh-agent -s)" >/dev/null 2>&1
        ssh-add ~/.ssh/id_* >/dev/null 2>&1
      fi
      
      # Linux-specific aliases
      alias open='xdg-open'
      alias pbcopy='xclip -selection clipboard'
      alias pbpaste='xclip -selection clipboard -o'
      
      # systemd user service management
      alias user-services='systemctl --user list-units --type=service'
      alias user-start='systemctl --user start'
      alias user-stop='systemctl --user stop'
      alias user-restart='systemctl --user restart'
      alias user-status='systemctl --user status'
      alias user-enable='systemctl --user enable'
      alias user-disable='systemctl --user disable'
      
      # Container management (Linux-specific)
      alias docker-clean='docker system prune -af'
      alias podman-clean='podman system prune -af'
      
      # Linux system information
      alias sysinfo='hostnamectl && echo && systemctl status'
      alias diskinfo='df -h && echo && lsblk'
      alias meminfo='free -h && echo && cat /proc/meminfo | head -10'
    '';
  };

  # --- Direnv Configuration (Linux-Specific) --------------------------------
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
    
    config = {
      # Linux-specific direnv configuration
      global = {
        hide_env_diff = true;
        strict_env = true;
      };
    };
  };

  # --- Linux-Specific Environment Variables ---------------------------------
  home.sessionVariables = {
    # Desktop integration
    XDG_CURRENT_DESKTOP = "GNOME";  # Adjust based on actual desktop
    
    # Container runtime
    DOCKER_HOST = "unix:///var/run/docker.sock";
    CONTAINERS_CONF = "${config.xdg.configHome}/containers/containers.conf";
    
    # SSH and GPG integration
    SSH_AUTH_SOCK = "${config.xdg.runtimeDir}/ssh-agent.socket";
    GNUPGHOME = "${config.xdg.dataHome}/gnupg";
    GPG_TTY = "$(tty)";
    
    # Font configuration
    FONTCONFIG_PATH = "${config.xdg.configHome}/fontconfig";
    FONTCONFIG_FILE = "${config.xdg.configHome}/fontconfig/fonts.conf";
    FONTCONFIG_CACHE = "${config.xdg.cacheHome}/fontconfig";
    
    # systemd integration
    SYSTEMD_USER_CONFIG_DIR = "${config.xdg.configHome}/systemd/user";
    SYSTEMD_USER_DATA_DIR = "${config.xdg.dataHome}/systemd/user";
    
    # Linux-specific browser
    BROWSER = "xdg-open";
    
    # Terminal integration
    TERM = "xterm-256color";
    COLORTERM = "truecolor";
  };
}
```

### Static Configuration Files (Linux-Specific)

#### systemd User Service Configuration
```ini
# Title         : ssh-agent.service
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : 01.home/00.core/configs/systemd/user/ssh-agent.service
# ----------------------------------------------------------------------------
# systemd user service for SSH agent management

[Unit]
Description=SSH Agent
Documentation=man:ssh-agent(1)

[Service]
Type=simple
Environment=SSH_AUTH_SOCK=%t/ssh-agent.socket
ExecStart=/usr/bin/ssh-agent -D -a $SSH_AUTH_SOCK
ExecStartPost=/usr/bin/ssh-add %h/.ssh/id_*
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
```

#### Container Configuration (Podman)
```toml
# Title         : containers.conf
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : 01.home/00.core/configs/containers/containers.conf
# ----------------------------------------------------------------------------
# Podman container runtime configuration for Linux

[containers]
# Default user namespace mode
userns = "keep-id"

# Default network mode
netns = "bridge"

# Default logging driver
log_driver = "journald"

# Default log size limit
log_size_max = "10MB"

# Default security options
seccomp_profile = "/usr/share/containers/seccomp.json"
apparmor_profile = "containers-default-0.44.0"

# Default capabilities
default_capabilities = [
    "CHOWN",
    "DAC_OVERRIDE", 
    "FOWNER",
    "FSETID",
    "KILL",
    "NET_BIND_SERVICE",
    "SETFCAP",
    "SETGID",
    "SETPCAP",
    "SETUID",
    "SYS_CHROOT"
]

# Default ulimits
default_ulimits = [
    "nofile=65536:65536",
    "nproc=4096:4096"
]

# Container init
init = true
init_path = "/usr/bin/catatonit"

# Timezone
tz = "local"

[engine]
# Container engine configuration
runtime = "crun"
runtime_path = "/usr/bin/crun"

# Image storage
image_default_transport = "docker://"
image_parallel_copies = 0

# Network configuration
network_cmd_path = "/usr/bin/netavark"
network_cmd_options = []

# Volume configuration
volume_path = "/var/lib/containers/storage/volumes"

[network]
# Network configuration
network_backend = "netavark"
dns_bind_port = 53

[secrets]
# Secrets configuration
driver = "file"

[machine]
# Machine configuration (for podman machine)
cpus = 2
memory = 2048
disk_size = 20
```

#### Fontconfig Configuration
```xml
<!-- Title         : fonts.conf -->
<!-- Author        : Bardia Samiee -->
<!-- Project       : Parametric Forge -->
<!-- License       : MIT -->
<!-- Path          : 01.home/00.core/configs/fontconfig/fonts.conf -->
<!-- -------------------------------------------------------------------------- -->
<!-- Fontconfig configuration for Linux font rendering -->

<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <!-- Font directories -->
  <dir>~/.local/share/fonts</dir>
  <dir>/usr/share/fonts</dir>
  <dir>/usr/local/share/fonts</dir>
  
  <!-- Cache directory -->
  <cachedir>~/.cache/fontconfig</cachedir>
  
  <!-- Font preferences -->
  <alias>
    <family>serif</family>
    <prefer>
      <family>DejaVu Serif</family>
      <family>Liberation Serif</family>
      <family>Times New Roman</family>
    </prefer>
  </alias>
  
  <alias>
    <family>sans-serif</family>
    <prefer>
      <family>DejaVu Sans</family>
      <family>Liberation Sans</family>
      <family>Arial</family>
    </prefer>
  </alias>
  
  <alias>
    <family>monospace</family>
    <prefer>
      <family>JetBrains Mono</family>
      <family>DejaVu Sans Mono</family>
      <family>Liberation Mono</family>
      <family>Consolas</family>
    </prefer>
  </alias>
  
  <!-- Font rendering settings -->
  <match target="font">
    <edit name="antialias" mode="assign">
      <bool>true</bool>
    </edit>
    <edit name="hinting" mode="assign">
      <bool>true</bool>
    </edit>
    <edit name="hintstyle" mode="assign">
      <const>hintslight</const>
    </edit>
    <edit name="rgba" mode="assign">
      <const>rgb</const>
    </edit>
    <edit name="lcdfilter" mode="assign">
      <const>lcddefault</const>
    </edit>
  </match>
  
  <!-- Emoji font configuration -->
  <alias>
    <family>emoji</family>
    <prefer>
      <family>Noto Color Emoji</family>
      <family>Apple Color Emoji</family>
      <family>Segoe UI Emoji</family>
    </prefer>
  </alias>
  
  <!-- Disable bitmap fonts -->
  <selectfont>
    <rejectfont>
      <pattern>
        <patelt name="scalable">
          <bool>false</bool>
        </patelt>
      </pattern>
    </rejectfont>
  </selectfont>
</fontconfig>
```

#### Desktop Entry Configuration
```desktop
# Title         : parametric-forge.desktop
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : 01.home/00.core/configs/applications/parametric-forge.desktop
# ----------------------------------------------------------------------------
# Desktop entry for Parametric Forge interface

[Desktop Entry]
Type=Application
Version=1.0
Name=Parametric Forge
Comment=System configuration management interface
GenericName=Configuration Manager
Keywords=nix;configuration;system;dotfiles;
Icon=parametric-forge
Exec=parametric-forge-interface
Terminal=true
Categories=Development;System;Settings;
MimeType=text/x-nix;
StartupNotify=true
StartupWMClass=parametric-forge-interface
```

### File Management Integration (Linux-Specific)

#### Linux-Specific File Deployment
```nix
# Addition to 01.home/file-management.nix for Linux-specific files

# --- Linux-Specific XDG Configuration Files -------------------------------
xdg.configFile = lib.mkIf pkgs.stdenv.isLinux {
  # systemd user services
  "systemd/user/ssh-agent.service".source = ./00.core/configs/systemd/user/ssh-agent.service;
  "systemd/user/gpg-agent.service".source = ./00.core/configs/systemd/user/gpg-agent.service;
  
  # Container runtime configuration
  "containers/containers.conf".source = ./00.core/configs/containers/containers.conf;
  "containers/registries.conf".source = ./00.core/configs/containers/registries.conf;
  "containers/storage.conf".source = ./00.core/configs/containers/storage.conf;
  
  # Font configuration
  "fontconfig/fonts.conf".source = ./00.core/configs/fontconfig/fonts.conf;
  
  # Desktop integration
  "mimeapps.list".source = ./00.core/configs/applications/mimeapps.list;
  
  # Git Linux-specific configuration
  "git/config-linux".source = ./00.core/configs/git/config-linux;
};

# --- Linux-Specific Data Files --------------------------------------------
xdg.dataFile = lib.mkIf pkgs.stdenv.isLinux {
  # Desktop entries for application launchers
  "applications/parametric-forge.desktop".source = ./00.core/configs/applications/parametric-forge.desktop;
  "applications/code.desktop".source = ./00.core/configs/applications/code.desktop;
  "applications/wezterm.desktop".source = ./00.core/configs/applications/wezterm.desktop;
  
  # Icon files
  "icons/hicolor/scalable/apps/parametric-forge.svg".source = ./00.core/configs/icons/parametric-forge.svg;
  
  # MIME type definitions
  "mime/packages/parametric-forge.xml".source = ./00.core/configs/mime/parametric-forge.xml;
};

# --- Linux-Specific Runtime Files -----------------------------------------
# Note: XDG_RUNTIME_DIR files are typically managed by systemd user services
# and don't need explicit deployment through home-manager
```

## Integration with Existing NixOS Configuration Patterns

### Current NixOS Configuration Structure

The existing system has a well-organized NixOS configuration structure:

```
00.system/nixos/           # System-level NixOS configuration
├── default.nix           # Core NixOS system configuration
└── containers.nix        # Container-specific overrides

01.home/nixos/             # User-level NixOS configuration
└── default.nix           # NixOS-specific home-manager config
```

### Integration Patterns

#### 1. Platform Detection Integration
```nix
# Use existing platform detection patterns
{ lib, pkgs, context, ... }:

lib.mkIf pkgs.stdenv.isLinux {
  # Linux-specific configuration here
}

# Alternative using context (when available)
lib.mkIf (context != null && context.isLinux) {
  # Linux-specific configuration here
}
```

#### 2. systemd User Service Integration
```nix
# Example: SSH agent systemd user service
# File: 01.home/nixos/services/ssh-agent.nix

{ config, lib, pkgs, ... }:

lib.mkIf pkgs.stdenv.isLinux {
  systemd.user.services.ssh-agent = {
    Unit = {
      Description = "SSH Agent";
      Documentation = "man:ssh-agent(1)";
    };
    
    Service = {
      Type = "simple";
      Environment = "SSH_AUTH_SOCK=%t/ssh-agent.socket";
      ExecStart = "${pkgs.openssh}/bin/ssh-agent -D -a $SSH_AUTH_SOCK";
      ExecStartPost = "${pkgs.openssh}/bin/ssh-add %h/.ssh/id_*";
      Restart = "on-failure";
      RestartSec = 5;
    };
    
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
  
  # Set SSH_AUTH_SOCK environment variable
  home.sessionVariables.SSH_AUTH_SOCK = "${config.xdg.runtimeDir}/ssh-agent.socket";
}
```

#### 3. Container Runtime Integration
```nix
# Example: Podman configuration integration
# File: 01.home/nixos/services/podman.nix

{ config, lib, pkgs, ... }:

lib.mkIf pkgs.stdenv.isLinux {
  # Enable podman for rootless containers
  home.packages = with pkgs; [
    podman
    buildah
    skopeo
    crun
    netavark
    aardvark-dns
  ];
  
  # Podman configuration
  xdg.configFile."containers/containers.conf".text = ''
    [containers]
    userns = "keep-id"
    netns = "bridge"
    log_driver = "journald"
    
    [engine]
    runtime = "crun"
    runtime_path = "${pkgs.crun}/bin/crun"
    
    [network]
    network_backend = "netavark"
  '';
  
  # Container registries configuration
  xdg.configFile."containers/registries.conf".text = ''
    [registries.search]
    registries = ['docker.io', 'quay.io', 'registry.fedoraproject.org']
    
    [registries.insecure]
    registries = []
    
    [registries.block]
    registries = []
  '';
}
```

#### 4. Desktop Integration Pattern
```nix
# Example: Desktop environment integration
# File: 01.home/nixos/desktop.nix

{ config, lib, pkgs, ... }:

lib.mkIf pkgs.stdenv.isLinux {
  # XDG user directories (Linux-specific)
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
  };
  
  # MIME type associations
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/plain" = "code.desktop";
      "text/x-shellscript" = "code.desktop";
      "application/json" = "code.desktop";
      "text/markdown" = "code.desktop";
      "image/png" = "org.gnome.eog.desktop";
      "image/jpeg" = "org.gnome.eog.desktop";
      "application/pdf" = "org.gnome.Evince.desktop";
      "video/mp4" = "org.gnome.Totem.desktop";
      "audio/mpeg" = "org.gnome.Rhythmbox3.desktop";
    };
  };
  
  # Desktop entries for custom applications
  xdg.desktopEntries = {
    parametric-forge = {
      name = "Parametric Forge";
      comment = "System configuration management";
      exec = "parametric-forge-interface";
      icon = "parametric-forge";
      terminal = true;
      categories = [ "Development" "System" "Settings" ];
      mimeType = [ "text/x-nix" ];
    };
  };
}
```

### Activation Script Integration

#### Linux-Specific Activation Scripts
```nix
# Addition to 01.home/nixos/default.nix

home.activation = lib.mkIf pkgs.stdenv.isLinux {
  # Set up systemd user services
  setupSystemdUserServices = lib.hm.dag.entryAfter ["writeBoundary"] ''
    echo "Setting up systemd user services..."
    
    # Reload systemd user daemon
    systemctl --user daemon-reload
    
    # Enable and start SSH agent service
    systemctl --user enable ssh-agent.service
    systemctl --user start ssh-agent.service
    
    # Enable and start GPG agent service
    systemctl --user enable gpg-agent.service
    systemctl --user start gpg-agent.service
    
    echo "  ✓ systemd user services configured"
  '';
  
  # Set up container runtime
  setupContainerRuntime = lib.hm.dag.entryAfter ["writeBoundary"] ''
    echo "Setting up container runtime..."
    
    # Create container storage directories
    mkdir -p "${config.xdg.dataHome}/containers/storage"
    mkdir -p "${config.xdg.cacheHome}/containers"
    
    # Set up Podman if available
    if command -v podman >/dev/null 2>&1; then
      # Initialize Podman storage
      podman system migrate >/dev/null 2>&1 || true
      
      # Pull essential container images
      podman pull docker.io/library/alpine:latest >/dev/null 2>&1 || true
      podman pull docker.io/library/ubuntu:latest >/dev/null 2>&1 || true
    fi
    
    echo "  ✓ Container runtime configured"
  '';
  
  # Set up desktop integration
  setupDesktopIntegration = lib.hm.dag.entryAfter ["writeBoundary"] ''
    echo "Setting up desktop integration..."
    
    # Update desktop database
    if command -v update-desktop-database >/dev/null 2>&1; then
      update-desktop-database "${config.xdg.dataHome}/applications"
    fi
    
    # Update MIME database
    if command -v update-mime-database >/dev/null 2>&1; then
      update-mime-database "${config.xdg.dataHome}/mime"
    fi
    
    # Update icon cache
    if command -v gtk-update-icon-cache >/dev/null 2>&1; then
      gtk-update-icon-cache -t "${config.xdg.dataHome}/icons/hicolor" >/dev/null 2>&1 || true
    fi
    
    echo "  ✓ Desktop integration configured"
  '';
  
  # Set up font configuration
  setupFontConfiguration = lib.hm.dag.entryAfter ["writeBoundary"] ''
    echo "Setting up font configuration..."
    
    # Create font directories
    mkdir -p "${config.xdg.dataHome}/fonts"
    mkdir -p "${config.xdg.cacheHome}/fontconfig"
    
    # Update font cache
    if command -v fc-cache >/dev/null 2>&1; then
      fc-cache -fv >/dev/null 2>&1
    fi
    
    echo "  ✓ Font configuration updated"
  '';
};
```

## Implementation Recommendations

### High Priority Linux-Specific Configurations

1. **systemd User Services** - Essential for service management and integration
   - SSH agent service for key management
   - GPG agent service for encryption
   - Custom application services

2. **Container Runtime Configuration** - Critical for development workflows
   - Podman rootless container configuration
   - Container registry and storage configuration
   - Docker daemon configuration (if used)

3. **Desktop Integration** - Important for GUI application integration
   - XDG user directories setup
   - MIME type associations
   - Desktop entry files for custom applications

### Medium Priority Linux-Specific Configurations

1. **Font Configuration** - Important for consistent text rendering
   - Fontconfig configuration for font rendering
   - Font preference and substitution rules
   - Font cache management

2. **SSH and GPG Integration** - Important for security and development
   - SSH agent configuration and key management
   - GPG agent configuration and key handling
   - Integration with desktop keyring services

### Low Priority Linux-Specific Configurations

1. **Network Configuration** - System-level configuration typically handled by NixOS
   - NetworkManager integration (if needed)
   - VPN configuration helpers
   - Network diagnostic tools

2. **System Monitoring** - Useful for system administration
   - systemd journal integration
   - System resource monitoring
   - Log file management

### Integration Testing Strategy

1. **Platform Detection Testing**
   - Verify configurations only apply on Linux systems
   - Test conditional logic with different system types
   - Validate environment variable platform detection

2. **systemd Integration Testing**
   - Test user service startup and management
   - Verify service dependencies and ordering
   - Test service restart and failure handling

3. **Container Runtime Testing**
   - Test rootless container functionality
   - Verify container image management
   - Test container networking and storage

4. **Desktop Integration Testing**
   - Test application launcher integration
   - Verify MIME type associations
   - Test file manager integration

## Security Considerations

### systemd User Services Security
- Service isolation and sandboxing
- Resource limits and security policies
- Secure service communication

### Container Runtime Security
- Rootless container configuration
- Security profiles and capabilities
- Image signature verification

### Desktop Integration Security
- Secure MIME type handling
- Application sandboxing considerations
- File association security

### SSH and GPG Security
- Secure key storage and management
- Agent timeout and security policies
- Integration with system keyring services

## Maintenance and Updates

### Regular Maintenance Tasks
1. Update systemd user service configurations
2. Review and update container runtime configurations
3. Update desktop integration files for new applications
4. Review and update font configurations

### Version Compatibility
1. Monitor systemd API changes and service configuration updates
2. Track container runtime updates and configuration changes
3. Update desktop integration standards and specifications
4. Maintain compatibility with home-manager updates

### Documentation Updates
1. Document new Linux-specific tools as they're added
2. Update configuration examples for tool updates
3. Maintain integration pattern documentation
4. Update security recommendations as needed