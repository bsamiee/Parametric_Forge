# Title         : services.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /reference-implementation/darwin/services.nix
# ----------------------------------------------------------------------------
# Darwin-specific launchd services for macOS integration

{ config, lib, pkgs, ... }:

lib.mkIf pkgs.stdenv.isDarwin {
  # --- 1Password CLI Service --------------------------------------------
  launchd.agents.op-cli-daemon = {
    enable = false;  # Disabled by default, enable manually if needed
    config = {
      Label = "com.1password.cli.daemon";
      ProgramArguments = [
        "${pkgs._1password-cli}/bin/op"
        "signin"
        "--account"
        "personal"
      ];
      RunAtLoad = false;
      KeepAlive = false;
      StandardOutPath = "${config.xdg.stateHome}/op/daemon.log";
      StandardErrorPath = "${config.xdg.stateHome}/op/daemon.log";
      EnvironmentVariables = {
        OP_CONFIG_DIR = "${config.xdg.configHome}/op";
        OP_CACHE_DIR = "${config.xdg.cacheHome}/op";
        OP_DATA_DIR = "${config.xdg.dataHome}/op";
        OP_BIOMETRIC_UNLOCK_ENABLED = "true";
      };
    };
  };

  # --- macOS System Maintenance Service ---------------------------------
  launchd.agents.macos-maintenance = {
    enable = true;
    config = {
      Label = "com.parametricforge.macos.maintenance";
      ProgramArguments = [
        "${pkgs.bash}/bin/bash"
        "-c"
        ''
          # Clean up system caches and temporary files
          find "$HOME/Library/Caches" -type f -atime +7 -delete 2>/dev/null || true
          find "$HOME/.cache" -type f -atime +7 -delete 2>/dev/null || true
          
          # Clean up .DS_Store files
          find "$HOME" -name ".DS_Store" -delete 2>/dev/null || true
          
          # Clean up ._* files
          find "$HOME" -name "._*" -delete 2>/dev/null || true
          
          # Update locate database if available
          if command -v updatedb >/dev/null 2>&1; then
            updatedb --localpaths="$HOME" --output="$HOME/.local/share/locate/home.db" 2>/dev/null || true
          fi
        ''
      ];
      StartCalendarInterval = [
        {
          Hour = 2;
          Minute = 0;
          Weekday = 0;  # Sunday
        }
      ];
      StandardOutPath = "${config.xdg.stateHome}/maintenance/macos-maintenance.log";
      StandardErrorPath = "${config.xdg.stateHome}/maintenance/macos-maintenance.log";
    };
  };

  # --- Dock Configuration Service ---------------------------------------
  launchd.agents.dock-setup = {
    enable = false;  # Disabled by default, enable manually if needed
    config = {
      Label = "com.parametricforge.dock.setup";
      ProgramArguments = [
        "${config.home.homeDirectory}/.local/bin/dock-setup"
      ];
      RunAtLoad = false;
      KeepAlive = false;
      StandardOutPath = "${config.xdg.stateHome}/dock/setup.log";
      StandardErrorPath = "${config.xdg.stateHome}/dock/setup.log";
      EnvironmentVariables = {
        HOME = config.home.homeDirectory;
        PATH = "/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/opt/homebrew/bin";
      };
    };
  };

  # --- Default Applications Service -------------------------------------
  launchd.agents.default-apps-setup = {
    enable = false;  # Disabled by default, enable manually if needed
    config = {
      Label = "com.parametricforge.defaultapps.setup";
      ProgramArguments = [
        "${pkgs.duti}/bin/duti"
        "${config.home.homeDirectory}/.duti"
      ];
      RunAtLoad = false;
      KeepAlive = false;
      StandardOutPath = "${config.xdg.stateHome}/defaults/apps-setup.log";
      StandardErrorPath = "${config.xdg.stateHome}/defaults/apps-setup.log";
      EnvironmentVariables = {
        HOME = config.home.homeDirectory;
      };
    };
  };

  # --- SSH Agent Service (1Password Integration) ------------------------
  launchd.agents.ssh-agent-1password = {
    enable = false;  # Disabled by default, enable if using 1Password SSH agent
    config = {
      Label = "com.1password.ssh-agent";
      ProgramArguments = [
        "${pkgs.bash}/bin/bash"
        "-c"
        ''
          # Set up SSH agent socket for 1Password
          export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
          
          # Test SSH agent connection
          if [[ -S "$SSH_AUTH_SOCK" ]]; then
            ssh-add -l >/dev/null 2>&1 && echo "1Password SSH agent is working"
          else
            echo "1Password SSH agent socket not found"
          fi
        ''
      ];
      RunAtLoad = true;
      KeepAlive = false;
      StandardOutPath = "${config.xdg.stateHome}/ssh/1password-agent.log";
      StandardErrorPath = "${config.xdg.stateHome}/ssh/1password-agent.log";
      EnvironmentVariables = {
        HOME = config.home.homeDirectory;
        SSH_AUTH_SOCK = "${config.home.homeDirectory}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
      };
    };
  };

  # --- macOS Notification Service ---------------------------------------
  launchd.agents.notification-helper = {
    enable = false;  # Disabled by default, enable if using terminal notifications
    config = {
      Label = "com.parametricforge.notifications";
      ProgramArguments = [
        "${pkgs.bash}/bin/bash"
        "-c"
        ''
          # Set up notification helper for terminal applications
          # This service can be used by other applications to send macOS notifications
          
          while read -r line; do
            if command -v terminal-notifier >/dev/null 2>&1; then
              terminal-notifier -message "$line" -title "Terminal Notification"
            else
              osascript -e "display notification \"$line\" with title \"Terminal Notification\""
            fi
          done < "${config.xdg.runtimeDir}/notifications.fifo"
        ''
      ];
      RunAtLoad = false;
      KeepAlive = true;
      StandardOutPath = "${config.xdg.stateHome}/notifications/helper.log";
      StandardErrorPath = "${config.xdg.stateHome}/notifications/helper.log";
    };
  };

  # --- Service Directory Setup ------------------------------------------
  home.activation.setupDarwinServices = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Create service-related directories
    mkdir -p "${config.xdg.stateHome}/op"
    mkdir -p "${config.xdg.stateHome}/maintenance"
    mkdir -p "${config.xdg.stateHome}/dock"
    mkdir -p "${config.xdg.stateHome}/defaults"
    mkdir -p "${config.xdg.stateHome}/ssh"
    mkdir -p "${config.xdg.stateHome}/notifications"
    
    # Create notification FIFO if notification service is enabled
    if [[ ! -p "${config.xdg.runtimeDir}/notifications.fifo" ]]; then
      mkfifo "${config.xdg.runtimeDir}/notifications.fifo" 2>/dev/null || true
    fi
    
    # Set appropriate permissions
    chmod 700 "${config.xdg.stateHome}/op"
    chmod 755 "${config.xdg.stateHome}/maintenance"
    chmod 755 "${config.xdg.stateHome}/dock"
    chmod 755 "${config.xdg.stateHome}/defaults"
    chmod 700 "${config.xdg.stateHome}/ssh"
    chmod 755 "${config.xdg.stateHome}/notifications"
  '';

  # --- Service Helper Functions -----------------------------------------
  home.activation.setupDarwinServiceHelpers = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Create helper functions for managing Darwin services
    
    cat > "${config.home.homeDirectory}/.local/bin/darwin-services" << 'EOF'
#!/usr/bin/env bash
# Darwin service management helper

case "$1" in
  "start-op")
    launchctl load ~/Library/LaunchAgents/com.1password.cli.daemon.plist 2>/dev/null || true
    ;;
  "stop-op")
    launchctl unload ~/Library/LaunchAgents/com.1password.cli.daemon.plist 2>/dev/null || true
    ;;
  "start-dock")
    launchctl load ~/Library/LaunchAgents/com.parametricforge.dock.setup.plist 2>/dev/null || true
    ;;
  "setup-defaults")
    launchctl load ~/Library/LaunchAgents/com.parametricforge.defaultapps.setup.plist 2>/dev/null || true
    ;;
  "status")
    echo "Darwin Services Status:"
    launchctl list | grep -E "(1password|parametricforge)" || echo "No services running"
    ;;
  "logs")
    echo "Recent service logs:"
    tail -n 20 "${config.xdg.stateHome}"/*/*.log 2>/dev/null || echo "No logs found"
    ;;
  *)
    echo "Usage: darwin-services {start-op|stop-op|start-dock|setup-defaults|status|logs}"
    exit 1
    ;;
esac
EOF
    
    chmod +x "${config.home.homeDirectory}/.local/bin/darwin-services"
  '';
}