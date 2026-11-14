{
  config,
  host,
  lib,
  osConfig,
  pkgs,
  ...
}: let
  homeDir = config.home.homeDirectory;
  tailnetHostKeys = lib.getExe (pkgs.writeShellApplication {
    name = "tailnet-host-keys";
    runtimeInputs = [pkgs.jq];
    text = ''
      ${config.forge.tailnet.cli} status --json \
        | jq -r --arg host "$1" --arg name "$2" '.Peer[] | select(.HostName == $host) | .sshHostKeys[] | "\($name) \(.)"'
    '';
  });
in {
  options.forge.ssh.identityAgent = lib.mkOption {
    type = lib.types.str;
    readOnly = true;
    default = "${homeDir}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
    description = "1Password agent socket every SSH client pins.";
  };

  config = {
    home.file.".ssh/id_ed25519.pub".text = host.ssh.publicKey + "\n";

    # --- [DOCKER_CONTEXTS]
    home.activation.dockerContexts = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if docker="$(PATH="$PATH:${osConfig.homebrew.prefix}/bin" command -v docker)"; then
        for server in ${lib.escapeShellArgs host.tailnet.servers}; do
          "$docker" context inspect "$server" >/dev/null 2>&1 || run "$docker" context create "$server" --docker "host=ssh://$server" >/dev/null || echo "docker context $server not created" >&2
        done
      fi
    '';

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
          ControlPersist = "8h";
          ServerAliveInterval = 15;
          ServerAliveCountMax = 4;
        };
        "Match host ${lib.concatStringsSep "," host.tailnet.servers} sessiontype shell" = {
          ForwardAgent = true;
          ControlPath = "${homeDir}/.ssh/sockets/%C-shell";
        };
        "Match host ${lib.concatStringsSep "," host.tailnet.serverPublicNames}".RefuseConnection = "\"dial the tailnet name: ${toString host.tailnet.servers}\"";
        ${host.name} = {
          HostName = host.tailnet.node;
          User = host.user.name;
        };
        "github.com" = {
          User = "git";
          IdentitiesOnly = true;
          BatchMode = true;
        };
        "*" = {
          IdentityAgent = "\"${config.forge.ssh.identityAgent}\"";
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
