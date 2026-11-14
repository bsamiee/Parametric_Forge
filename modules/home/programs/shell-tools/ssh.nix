{
  config,
  host,
  lib,
  pkgs,
  ...
}: let
  homeDir = config.home.homeDirectory;
  tailnetHostKeys = pkgs.writeShellScript "tailnet-host-keys" ''
    ${config.forge.tailnet.cli} status --json \
      | ${lib.getExe pkgs.jq} -r --arg host "$1" --arg name "$2" '.Peer[] | select(.HostName == $host) | .sshHostKeys[] | "\($name) \(.)"'
  '';
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
      package = pkgs.openssh;
      enableDefaultConfig = false;
      settings = {
        ${lib.concatStringsSep " " host.tailnet.servers} = {
          User = "root";
          KnownHostsCommand = "${tailnetHostKeys} %n %H";
          StrictHostKeyChecking = "yes";
          BatchMode = true;
          ForwardAgent = true;
        };
        "github.com" = {
          User = "git";
          HostName = "github.com";
          IdentitiesOnly = true;
          BatchMode = true;
        };
        "*" = {
          IdentityAgent = "\"${config.forge.ssh.identityAgent}\"";
          KexAlgorithms = "^mlkem768x25519-sha256,sntrup761x25519-sha512";
          StrictHostKeyChecking = "accept-new";
          ConnectTimeout = 10;
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
