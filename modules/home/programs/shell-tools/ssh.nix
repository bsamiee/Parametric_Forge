# Title         : ssh.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/ssh.nix
# ----------------------------------------------------------------------------
# SSH client configuration with GitHub integration and performance optimization

{ config, lib, pkgs, ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;  # Explicitly disable default config to suppress warning

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
        # SSH keys managed via 1Password (see environments/secrets.nix)
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
