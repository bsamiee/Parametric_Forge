# Title         : ssh.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/ssh.nix
# ----------------------------------------------------------------------------
# SSH client configuration: the 1Password agent socket, the public half of the signing key, and OpenSSH client defaults.
{
  config,
  host,
  lib,
  pkgs,
  ...
}: let
  homeDir = config.home.homeDirectory;
  knownHostsFile = pkgs.writeText "known-hosts" ''
    github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
  '';
in {
  options.forge.ssh.identityAgent = lib.mkOption {
    type = lib.types.str;
    readOnly = true;
    default = "${homeDir}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
    description = "1Password agent socket every SSH client pins.";
  };

  config = {
    home.file.".ssh/id_ed25519.pub".text = lib.head host.ssh.authorizedKeys + "\n";

    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings = {
        "github.com" = {
          User = "git";
          HostName = "github.com";
          IdentitiesOnly = true;
        };
        "*" = {
          IdentityAgent = "\"${config.forge.ssh.identityAgent}\"";
          ControlMaster = "auto";
          ControlPath = "${homeDir}/.ssh/sockets/%C";
          ControlPersist = "10m";
          ServerAliveInterval = 60;
          AddKeysToAgent = "yes";
          HashKnownHosts = true;
          UserKnownHostsFile = "${homeDir}/.ssh/known_hosts ${knownHostsFile}";
          Compression = true;
        };
      };
    };
  };
}
