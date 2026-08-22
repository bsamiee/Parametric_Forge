# Title         : ssh.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/ssh.nix
# ----------------------------------------------------------------------------
# SSH client configuration with one generic VPS projection from the host register.
{
  config,
  host,
  lib,
  pkgs,
  ...
}: let
  homeDir = config.home.homeDirectory;
  identityAgent = "${homeDir}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
  hostContext = import ../../../../hosts/context.nix;
  inherit (hostContext) vps;
  sshHosts = {
    vps = {
      name = "vps";
      user = vps.user.name;
      inherit (vps.ssh) hostName;
      aliases = ["vps"];
    };
  };
  knownHostsFile = pkgs.writeText "forge-known-hosts" (lib.concatLines [
    "${vps.ssh.hostName} ${vps.ssh.hostKey}"
    "github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl"
  ]);
  interactiveHosts = lib.mapAttrs' (_: remote:
    lib.nameValuePair "${lib.concatStringsSep " " (remote.aliases ++ [remote.hostName])}" {
      User = remote.user;
      HostName = remote.hostName;
      IdentitiesOnly = true;
      AddKeysToAgent = "yes";
      ConnectTimeout = 10;
    })
  sshHosts;
in {
  options.forge.ssh = {
    hosts = lib.mkOption {
      type = lib.types.raw;
      readOnly = true;
      default = sshHosts;
      description = "SSH estate host rows for interactive, WezTerm, and Yazi SFTP clients.";
    };
    identityAgent = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = identityAgent;
      description = "1Password agent socket every remote client pins.";
    };
  };

  config = {
    home.file.".ssh/id_ed25519.pub".text = lib.head host.ssh.authorizedKeys + "\n";

    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings =
        {
          "github.com" = {
            User = "git";
            HostName = "github.com";
            IdentitiesOnly = true;
            AddKeysToAgent = "yes";
          };
          "*" =
            lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {IdentityAgent = "\"${identityAgent}\"";}
            // {
              ControlMaster = "auto";
              ControlPath = "${homeDir}/.ssh/sockets/%C";
              ControlPersist = "10m";
              ServerAliveInterval = 60;
              ServerAliveCountMax = 3;
              AddKeysToAgent = "yes";
              HashKnownHosts = true;
              UserKnownHostsFile = "${homeDir}/.ssh/known_hosts ${knownHostsFile}";
              Compression = true;
            };
        }
        // interactiveHosts;
    };
  };
}
