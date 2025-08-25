# Title         : services.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /reference-implementation/nixos/services.nix
# ----------------------------------------------------------------------------
# NixOS-specific systemd user services for Linux integration

{ config, lib, pkgs, ... }:

lib.mkIf pkgs.stdenv.isLinux {
  # --- SSH Agent systemd User Service -----------------------------------
  systemd.user.services.ssh-agent = {
    Unit = {
      Description = "SSH Agent";
      Documentation = "man:ssh-agent(1)";
      Wants = "ssh-agent.socket";
    };
    
    Service = {
      Type = "simple";
      Environment = "SSH_AUTH_SOCK=%t/ssh-agent.socket";
      ExecStart = "${pkgs.openssh}/bin/ssh-agent -D -a $SSH_AUTH_SOCK";
      ExecStartPost = "${pkgs.bash}/bin/bash -c '${pkgs.openssh}/bin/ssh-add ${config.xdg.dataHome}/ssh/id_* 2>/dev/null || true'";
      Restart = "on-failure";
      RestartSec = 5;
      TimeoutStopSec = 10;
    };
    
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  # --- SSH Agent Socket --------------------------------------------------
  systemd.user.sockets.ssh-agent = {
    Unit = {
      Description = "SSH Agent Socket";
      Documentation = "man:ssh-agent(1)";
    };
    
    Socket = {
      ListenStream = "%t/ssh-agent.socket";
      SocketMode = "0600";
      Service = "ssh-agent.service";
    };
    
    Install = {
      WantedBy = [ "sockets.target" ];
    };
  };

  # --- GPG Agent systemd User Service -----------------------------------
  systemd.user.services.gpg-agent = {
    Unit = {
      Description = "GnuPG Agent";
      Documentation = "man:gpg-agent(1)";
      Requires = "gpg-agent.socket";
      After = "gpg-agent.socket";
      RefuseManualStart = true;
    };
    
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.gnupg}/bin/gpg-agent --supervised";
      ExecReload = "${pkgs.gnupg}/bin/gpgconf --reload gpg-agent";
      Environment = [
        "GNUPGHOME=${config.xdg.dataHome}/gnupg"
        "GPG_TTY=$(tty)"
      ];
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  # --- GPG Agent Socket --------------------------------------------------
  systemd.user.sockets.gpg-agent = {
    Unit = {
      Description = "GnuPG Agent Socket";
      Documentation = "man:gpg-agent(1)";
    };
    
    Socket = {
      ListenStream = "%t/gnupg/S.gpg-agent";
      SocketMode = "0600";
      DirectoryMode = "0700";
    };
    
    Install = {
      WantedBy = [ "sockets.target" ];
    };
  };

  # --- Container Cleanup Service -----------------------------------------
  systemd.user.services.podman-cleanup = {
    Unit = {
      Description = "Podman Container Cleanup";
      Documentation = "man:podman(1)";
    };
    
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.podman}/bin/podman system prune -af --volumes 2>/dev/null || true'";
      Environment = [
        "CONTAINERS_CONF=${config.xdg.configHome}/containers/containers.conf"
        "XDG_RUNTIME_DIR=%t"
      ];
      StandardOutput = "journal";
      StandardError = "journal";
    };
  };

  # --- Container Cleanup Timer -------------------------------------------
  systemd.user.timers.podman-cleanup = {
    Unit = {
      Description = "Podman Container Cleanup Timer";
      Requires = "podman-cleanup.service";
    };
    
    Timer = {
      OnCalendar = "weekly";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
    
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };

  # --- Font Cache Update Service -----------------------------------------
  systemd.user.services.fontconfig-cache = {
    Unit = {
      Description = "Update Fontconfig Cache";
      Documentation = "man:fc-cache(1)";
    };
    
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.fontconfig}/bin/fc-cache -fv";
      Environment = [
        "FONTCONFIG_PATH=${config.xdg.configHome}/fontconfig"
        "FONTCONFIG_FILE=${config.xdg.configHome}/fontconfig/fonts.conf"
        "FONTCONFIG_CACHE=${config.xdg.cacheHome}/fontconfig"
      ];
      StandardOutput = "journal";
      StandardError = "journal";
    };
  };

  # --- Desktop Database Update Service -----------------------------------
  systemd.user.services.desktop-database-update = {
    Unit = {
      Description = "Update Desktop Database";
      Documentation = "man:update-desktop-database(1)";
    };
    
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.desktop-file-utils}/bin/update-desktop-database ${config.xdg.dataHome}/applications";
      ExecStartPost = "${pkgs.shared-mime-info}/bin/update-mime-database ${config.xdg.dataHome}/mime";
      StandardOutput = "journal";
      StandardError = "journal";
    };
  };

  # --- System Maintenance Service ----------------------------------------
  systemd.user.services.system-maintenance = {
    Unit = {
      Description = "User System Maintenance";
      Documentation = "Cleanup temporary files and caches";
    };
    
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c '''
        # Clean up old cache files
        find "${config.xdg.cacheHome}" -type f -atime +30 -delete 2>/dev/null || true
        
        # Clean up old log files
        find "${config.xdg.stateHome}/logs" -name "*.log" -mtime +30 -delete 2>/dev/null || true
        
        # Clean up old temporary files
        find "${config.xdg.runtimeDir}" -name "*.tmp" -mtime +1 -delete 2>/dev/null || true
        
        # Clean up old backup files
        find "${config.xdg.stateHome}" -name "*~" -mtime +7 -delete 2>/dev/null || true
        find "${config.xdg.stateHome}" -name "*.bak" -mtime +7 -delete 2>/dev/null || true
        
        # Update locate database if available
        if command -v updatedb >/dev/null 2>&1; then
          updatedb --localpaths="${config.home.homeDirectory}" --output="${config.xdg.dataHome}/locate/home.db" 2>/dev/null || true
        fi
        
        echo "System maintenance completed"
      ''';
      StandardOutput = "journal";
      StandardError = "journal";
    };
  };

  # --- System Maintenance Timer ------------------------------------------
  systemd.user.timers.system-maintenance = {
    Unit = {
      Description = "System Maintenance Timer";
      Requires = "system-maintenance.service";
    };
    
    Timer = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "30m";
    };
    
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };

  # --- Development Environment Service -----------------------------------
  systemd.user.services.dev-env-setup = {
    Unit = {
      Description = "Development Environment Setup";
      Documentation = "Setup development tools and environment";
    };
    
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.bash}/bin/bash -c '''
        # Ensure development directories exist
        mkdir -p "${config.home.homeDirectory}/Development"
        mkdir -p "${config.home.homeDirectory}/Projects"
        mkdir -p "${config.xdg.dataHome}/cargo/bin"
        mkdir -p "${config.xdg.dataHome}/go/bin"
        mkdir -p "${config.xdg.dataHome}/npm/bin"
        
        # Set up Git configuration if not already done
        if [[ ! -f "${config.xdg.configHome}/git/config" ]]; then
          ${pkgs.git}/bin/git config --global init.defaultBranch main
          ${pkgs.git}/bin/git config --global pull.rebase true
          ${pkgs.git}/bin/git config --global push.autoSetupRemote true
        fi
        
        # Set up development tools
        if command -v rustup >/dev/null 2>&1; then
          rustup default stable 2>/dev/null || true
        fi
        
        echo "Development environment setup completed"
      ''';
      StandardOutput = "journal";
      StandardError = "journal";
    };
    
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  # --- Container Registry Login Service ----------------------------------
  systemd.user.services.container-registry-login = {
    Unit = {
      Description = "Container Registry Login";
      Documentation = "Login to container registries";
      After = "network-online.target";
      Wants = "network-online.target";
    };
    
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.bash}/bin/bash -c '''
        # Login to container registries if credentials are available
        if command -v podman >/dev/null 2>&1; then
          # Check if registry credentials exist
          if [[ -f "${config.xdg.configHome}/containers/auth.json" ]]; then
            echo "Container registry credentials found"
          else
            echo "No container registry credentials found"
          fi
        fi
        
        if command -v docker >/dev/null 2>&1; then
          # Check if Docker is running
          if docker info >/dev/null 2>&1; then
            echo "Docker is running"
          else
            echo "Docker is not running"
          fi
        fi
      ''';
      StandardOutput = "journal";
      StandardError = "journal";
    };
  };

  # --- Service Helper Functions ------------------------------------------
  home.activation.setupLinuxServiceHelpers = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Create helper functions for managing Linux services
    
    cat > "${config.home.homeDirectory}/.local/bin/linux-services" << 'EOF'
#!/usr/bin/env bash
# Linux systemd user service management helper

case "$1" in
  "start-ssh")
    systemctl --user start ssh-agent.service
    systemctl --user start ssh-agent.socket
    ;;
  "stop-ssh")
    systemctl --user stop ssh-agent.service
    systemctl --user stop ssh-agent.socket
    ;;
  "start-gpg")
    systemctl --user start gpg-agent.service
    systemctl --user start gpg-agent.socket
    ;;
  "stop-gpg")
    systemctl --user stop gpg-agent.service
    systemctl --user stop gpg-agent.socket
    ;;
  "cleanup-containers")
    systemctl --user start podman-cleanup.service
    ;;
  "update-fonts")
    systemctl --user start fontconfig-cache.service
    ;;
  "update-desktop")
    systemctl --user start desktop-database-update.service
    ;;
  "maintenance")
    systemctl --user start system-maintenance.service
    ;;
  "setup-dev")
    systemctl --user start dev-env-setup.service
    ;;
  "status")
    echo "Linux User Services Status:"
    systemctl --user status ssh-agent.service gpg-agent.service podman-cleanup.timer system-maintenance.timer 2>/dev/null || true
    ;;
  "logs")
    echo "Recent service logs:"
    journalctl --user -n 50 -u ssh-agent.service -u gpg-agent.service -u podman-cleanup.service -u system-maintenance.service 2>/dev/null || true
    ;;
  "enable-all")
    systemctl --user enable ssh-agent.service ssh-agent.socket
    systemctl --user enable gpg-agent.service gpg-agent.socket
    systemctl --user enable podman-cleanup.timer
    systemctl --user enable system-maintenance.timer
    systemctl --user enable dev-env-setup.service
    echo "All services enabled"
    ;;
  "disable-all")
    systemctl --user disable ssh-agent.service ssh-agent.socket
    systemctl --user disable gpg-agent.service gpg-agent.socket
    systemctl --user disable podman-cleanup.timer
    systemctl --user disable system-maintenance.timer
    systemctl --user disable dev-env-setup.service
    echo "All services disabled"
    ;;
  *)
    echo "Usage: linux-services {start-ssh|stop-ssh|start-gpg|stop-gpg|cleanup-containers|update-fonts|update-desktop|maintenance|setup-dev|status|logs|enable-all|disable-all}"
    exit 1
    ;;
esac
EOF
    
    chmod +x "${config.home.homeDirectory}/.local/bin/linux-services"
  '';

  # --- Service Status Check Script ---------------------------------------
  home.activation.setupLinuxServiceStatus = lib.hm.dag.entryAfter ["writeBoundary"] ''
    cat > "${config.home.homeDirectory}/.local/bin/linux-status" << 'EOF'
#!/usr/bin/env bash
# Check Linux system and service status

echo "Linux System Status Check"
echo "========================="

# Check system information
echo ""
echo "System Information:"
hostnamectl 2>/dev/null || echo "hostnamectl not available"

# Check systemd user services
echo ""
echo "User Services Status:"
if command -v systemctl >/dev/null 2>&1; then
  systemctl --user is-system-running 2>/dev/null || echo "systemd user session not running"
  
  echo ""
  echo "Key Services:"
  for service in ssh-agent gpg-agent podman-cleanup system-maintenance dev-env-setup; do
    if systemctl --user list-unit-files "$service.service" >/dev/null 2>&1; then
      status=$(systemctl --user is-active "$service.service" 2>/dev/null || echo "inactive")
      enabled=$(systemctl --user is-enabled "$service.service" 2>/dev/null || echo "disabled")
      echo "  $service: $status ($enabled)"
    fi
  done
  
  echo ""
  echo "Timers:"
  for timer in podman-cleanup system-maintenance; do
    if systemctl --user list-unit-files "$timer.timer" >/dev/null 2>&1; then
      status=$(systemctl --user is-active "$timer.timer" 2>/dev/null || echo "inactive")
      enabled=$(systemctl --user is-enabled "$timer.timer" 2>/dev/null || echo "disabled")
      echo "  $timer: $status ($enabled)"
    fi
  done
else
  echo "systemctl not available"
fi

# Check container runtimes
echo ""
echo "Container Runtimes:"
if command -v podman >/dev/null 2>&1; then
  echo "✓ Podman installed: $(podman --version)"
  containers=$(podman ps -q | wc -l)
  images=$(podman images -q | wc -l)
  echo "  Containers: $containers running"
  echo "  Images: $images available"
else
  echo "✗ Podman not installed"
fi

if command -v docker >/dev/null 2>&1; then
  echo "✓ Docker installed: $(docker --version)"
  if docker info >/dev/null 2>&1; then
    containers=$(docker ps -q | wc -l)
    images=$(docker images -q | wc -l)
    echo "  Containers: $containers running"
    echo "  Images: $images available"
  else
    echo "  Docker daemon not running"
  fi
else
  echo "✗ Docker not installed"
fi

# Check development tools
echo ""
echo "Development Tools:"
for tool in git ssh-agent gpg nvim; do
  if command -v "$tool" >/dev/null 2>&1; then
    echo "✓ $tool available"
  else
    echo "✗ $tool not available"
  fi
done

# Check XDG directories
echo ""
echo "XDG Directories:"
for dir in CONFIG DATA CACHE STATE RUNTIME; do
  var="XDG_${dir}_HOME"
  if [[ "$dir" == "RUNTIME" ]]; then
    var="XDG_RUNTIME_DIR"
  fi
  path="${!var:-not set}"
  if [[ -d "$path" ]]; then
    echo "✓ $var: $path"
  else
    echo "✗ $var: $path (missing)"
  fi
done

# Check fonts
echo ""
echo "Font Configuration:"
if command -v fc-list >/dev/null 2>&1; then
  font_count=$(fc-list | wc -l)
  echo "✓ $font_count fonts available"
else
  echo "✗ fontconfig not available"
fi

EOF
    
    chmod +x "${config.home.homeDirectory}/.local/bin/linux-status"
  '';
}