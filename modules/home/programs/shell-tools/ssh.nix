{
  config,
  host,
  lib,
  pkgs,
  sshAgentSocket,
  ...
}: let
  homeDir = config.home.homeDirectory;
in {
  config = {
    _module.args.sshAgentSocket = "${homeDir}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
    home.file.".ssh/id_ed25519.pub".text = host.ssh.publicKey + "\n";

    programs.ssh = {
      enable = true;
      package = pkgs.openssh;
      enableDefaultConfig = false;
      settings = {
        ${lib.concatStringsSep " " host.tailnet.servers}.User = "root";
        "github.com" = {
          User = "git";
          IdentitiesOnly = true;
          BatchMode = true;
        };
        "*" = {
          IdentityAgent = "\"${sshAgentSocket}\"";
          KexAlgorithms = "^mlkem768x25519-sha256,sntrup761x25519-sha512";
          StrictHostKeyChecking = "accept-new";
          ConnectTimeout = 10;
          TCPKeepAlive = "all";
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
