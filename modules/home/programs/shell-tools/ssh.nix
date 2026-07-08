# Title         : ssh.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/ssh.nix
# ----------------------------------------------------------------------------
# SSH client configuration with GitHub integration and Maghz VPS loopback tunnels.
{
  config,
  lib,
  pkgs,
  ...
}: let
  # Maghz VPS loopback forwards: webhook (9000), aria2 RPC (6800), Codex OAuth
  # (1455), Postgres (15435), Ollama (11434), n8n (5678).
  maghzLocalForwards = map (port: {
    bind.port = port;
    host.address = "localhost";
    host.port = port;
  }) [9000 6800 1455 15435 11434 5678];
in {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false; # Explicitly disable default config to suppress warning

    # Use 1Password's stable socket on macOS so SSH pulls keys from the agent
    extraConfig = lib.mkBefore ''
      Host *
        IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    '';

    settings = {
      # --- GitHub Configuration ---------------------------------------------
      "github.com" = {
        User = "git";
        HostName = "github.com";
        IdentitiesOnly = true;
        AddKeysToAgent = "yes";
      };

      # --- Hostinger VPS (Maghz remote operator) ----------------------------
      "maghz-vps maghz" = {
        User = "maghz-agent";
        HostName = "31.97.131.41";
        IdentitiesOnly = true;
        AddKeysToAgent = "yes";
        LocalForward = maghzLocalForwards;
      };

      # --- Maghz transport-only tunnel (launchd-managed) --------------------
      # Fail-fast forwards + tight keepalives; launchd owns restart policy.
      "maghz-tunnel" = {
        User = "maghz-agent";
        HostName = "31.97.131.41";
        IdentitiesOnly = true;
        AddKeysToAgent = "yes";
        BatchMode = true;
        Compression = false;
        ControlMaster = "no";
        ExitOnForwardFailure = true;
        LocalForward = maghzLocalForwards;
        ServerAliveInterval = 15;
        ServerAliveCountMax = 3;
        SessionType = "none";
        StdinNull = true;
        TCPKeepAlive = false;
      };

      # --- Default Optimizations for All Hosts ------------------------------
      "*" = {
        # Connection multiplexing for performance
        ControlMaster = "auto";
        ControlPath = "${config.home.homeDirectory}/.ssh/sockets/%C";
        ControlPersist = "10m";

        # Keep-alive settings
        ServerAliveInterval = 60;
        ServerAliveCountMax = 3;

        # Security and convenience
        AddKeysToAgent = "yes";
        HashKnownHosts = true;

        # Performance
        Compression = true;
      };
    };
  };

  # Durable Maghz tunnel: remote-primary mode kickstarts it; local parity mode
  # boots it out before compose binds the same loopback ports.
  launchd.agents.maghz-vps-tunnel = {
    enable = true;
    config = {
      ProgramArguments = ["${pkgs.openssh}/bin/ssh" "-N" "maghz-tunnel"];
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 30;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/maghz-vps-tunnel.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/maghz-vps-tunnel.log";
    };
  };
}
