# Title         : ssh.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/ssh.nix
# ----------------------------------------------------------------------------
# SSH client configuration with GitHub integration and performance optimization
{
  config,
  lib,
  ...
}: {
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
        # Port forwards: webhook (9000), aria2 RPC (6800), Codex OAuth (1455)
        LocalForward = [
          {
            bind.port = 9000;
            host.address = "localhost";
            host.port = 9000;
          }
          {
            bind.port = 6800;
            host.address = "localhost";
            host.port = 6800;
          }
          {
            bind.port = 1455;
            host.address = "localhost";
            host.port = 1455;
          }
        ];
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
}
