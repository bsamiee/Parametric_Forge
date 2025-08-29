# Title         : window-manager.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /00.system/darwin/services/window-manager.nix
# ----------------------------------------------------------------------------
# System-level window management daemons using proper system patterns.

{ pkgs, myLib, ... }:

let
  # --- User Detection -----------------------------------------------------
  primaryUser = "bardiasamiee"; # System daemons need explicit user context
  userHome = "/Users/${primaryUser}";

  # --- Service Helper Functions -------------------------------------------
  inherit (myLib.launchd) mkLaunchdDaemon;

  # --- Build sketchybar-system-stats package -----------------------------
  sketchybar-system-stats = pkgs.rustPlatform.buildRustPackage rec {
    pname = "sketchybar-system-stats";
    version = "0.6.4";

    src = pkgs.fetchFromGitHub {
      owner = "joncrangle";
      repo = "sketchybar-system-stats";
      rev = version;
      sha256 = "sha256-HExdDDIgYF/DGOYmAT41iOkM+7L9TDxxMd/MWFhwlCM=";
    };

    cargoHash = "sha256-vRvfoHaz8BNIyXj1u69a9yr3fxgqz3TuquwoeMPpRwU=";

    meta = with pkgs.lib; {
      description = "System statistics provider for SketchyBar";
      homepage = "https://github.com/joncrangle/sketchybar-system-stats";
      license = licenses.gpl3Only;
      platforms = platforms.darwin;
    };
  };

  # --- Yabai System Daemon Script -----------------------------------------
  yabaiDaemon = myLib.launchd.mkNamedExecutable pkgs "yabai-system-daemon" ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail
    
    # Create system state directory
    mkdir -p /var/log/wm
    
    echo "$(date): yabai system daemon starting..."
    
    # Start yabai with user configuration
    echo "$(date): Starting yabai with config: ${userHome}/.config/yabai/yabairc"
    exec ${pkgs.yabai}/bin/yabai -c "${userHome}/.config/yabai/yabairc"
  '';

  # --- SKHD System Daemon Script ------------------------------------------
  skhdDaemon = myLib.launchd.mkNamedExecutable pkgs "skhd-system-daemon" ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail
    
    echo "$(date): skhd system daemon starting..."
    
    # Wait a moment for yabai to initialize
    sleep 2
    
    echo "$(date): Starting skhd with config: ${userHome}/.skhdrc"
    exec ${pkgs.skhd}/bin/skhd -c "${userHome}/.skhdrc"
  '';

in

{
  # --- System-Level Window Management Daemons ---------------------------
  # --- Foundation Layer: Core Window Management -------------------------
  launchd.daemons."org.nixos.yabai" = mkLaunchdDaemon pkgs {
    command = "${yabaiDaemon}/bin/yabai-system-daemon";
    label = "Yabai Window Manager";
    nice = -10; # Higher priority for system daemon
    processType = "Interactive"; # Needs interaction with windows
    runAtLoad = true;
    keepAlive = true;
    environmentVariables = {
      PATH = "/run/current-system/sw/bin:/usr/bin:/bin";
      USER = primaryUser;
      HOME = userHome;
    };
    workingDirectory = userHome;
    logBaseName = "/var/log/yabai";
  };

  # --- Integration Layer: Hotkey Management -----------------------------
  launchd.daemons."org.nixos.skhd" = mkLaunchdDaemon pkgs {
    command = "${skhdDaemon}/bin/skhd-system-daemon";
    label = "SKHD Hotkey Daemon";
    nice = -5; # High priority but after yabai
    processType = "Interactive"; # Needs keyboard access
    runAtLoad = true;
    keepAlive = true;
    environmentVariables = {
      PATH = "/run/current-system/sw/bin:/usr/bin:/bin";
      USER = primaryUser;
      HOME = userHome;
    };
    workingDirectory = userHome;
    logBaseName = "/var/log/skhd";
  };

  # --- Support Layer: System Statistics Provider -----------------------
  launchd.daemons."org.nixos.sketchybar-system-stats" = mkLaunchdDaemon pkgs {
    command = "${sketchybar-system-stats}/bin/sketchybar-system-stats";
    arguments = [
      "--cpu" "usage"
      "--memory" "ram_usage"
      "--disk" "usage"
      "--interval" "2"
    ];
    label = "SketchyBar System Stats";
    nice = 5; # Lower priority
    processType = "Background";
    runAtLoad = true;
    keepAlive = true;
    logBaseName = "/var/log/sketchybar-system-stats";
  };
  
  # --- Logging Configuration ---------------------------------------------
  system.activationScripts.windowManagerLogs = {
    text = ''
      mkdir -p /var/log/wm
      chown root:wheel /var/log/wm
      chmod 755 /var/log/wm
    '';
    deps = [];
  };
}