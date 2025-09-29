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
        controlPath = "${config.xdg.stateHome}/ssh/master-%r@%n:%p";
        controlPersist = "10m";

        # Keep-alive settings
        serverAliveInterval = 60;
        serverAliveCountMax = 3;

        # Security and convenience
        addKeysToAgent = "yes";
        hashKnownHosts = true;
        userKnownHostsFile = "${config.xdg.configHome}/ssh/known_hosts";

        # Performance
        compression = true;
      };
    };
  };
}
