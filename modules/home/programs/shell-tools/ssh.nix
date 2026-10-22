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
  ...
}: let
  homeDir = config.home.homeDirectory;
in {
  options.forge.ssh.identityAgent = lib.mkOption {
    type = lib.types.str;
    readOnly = true;
    default = "${homeDir}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
    description = "1Password agent socket every SSH client pins.";
  };

  config = {
    home.file.".ssh/id_ed25519.pub".text = host.ssh.publicKey + "\n";

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
          HashKnownHosts = true;
        };
      };
    };
  };
}
