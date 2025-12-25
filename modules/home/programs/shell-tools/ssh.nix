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

    matchBlocks = {
      # --- GitHub Configuration ---------------------------------------------
      "github.com" = {
        user = "git";
        hostname = "github.com";
        identitiesOnly = true;
        addKeysToAgent = "yes";
      };

      # --- Hostinger VPS (n8n PM Orchestration) -----------------------------
      "n8n" = {
        user = "n8n-agent";
        hostname = "31.97.131.41";
        identitiesOnly = true;
        addKeysToAgent = "yes";
        # Port forwards: webhook (9000), aria2 RPC (6800), Codex OAuth (1455)
        localForwards = [
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
        controlMaster = "auto";
        controlPath = "${config.home.homeDirectory}/.ssh/sockets/%C";
        controlPersist = "10m";

        # Keep-alive settings
        serverAliveInterval = 60;
        serverAliveCountMax = 3;

        # Security and convenience
        addKeysToAgent = "yes";
        hashKnownHosts = true;

        # Performance
        compression = true;
      };
    };
  };
}
