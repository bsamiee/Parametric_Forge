{
  config,
  host,
  pkgs,
  ...
}: {
  config = {
    _module.args.sshAgentSocket = "${config.home.homeDirectory}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
    home.packages = [pkgs.openssh];
    xdg.configFile."ssh/id_ed25519.pub".text = host.ssh.publicKey + "\n";
  };
}
