{
  config,
  host,
  lib,
  ...
}: let
  inherit (config.system) primaryUser;
in {
  system.activationScripts.postActivation.text = ''
    /usr/sbin/DevToolsSecurity -enable >/dev/null
    /bin/mkdir -p '/Library/Application Support/Adobe/UXP/Developer'
    printf '%s\n' '{"developer": true}' > '/Library/Application Support/Adobe/UXP/Developer/settings.json'
    if [ -d '/Applications/Adobe Illustrator (Beta)' ]; then
      printf '%s\n' '<?xml version="1.0" encoding="utf-8"?>' '<Features>' '<Feature name="EnableThirdPartyUXP" enabled="1" configurableInRelease="1"/>' '<Feature name="UXPPluginRuntimeGroupFor3P" enabled="1" configurableInRelease="1"/>' '</Features>' > '/Applications/Adobe Illustrator (Beta)/AIFeatures.cfg'
    fi
  '';

  # --- [UNIFIED_LOG_PRIVATE_DATA]
  environment.etc."mobileconfig/unified-log-private-data.mobileconfig".text = lib.generators.toPlist {escape = true;} {
    PayloadType = "Configuration";
    PayloadVersion = 1;
    PayloadIdentifier = "dev.bsamiee.logging.private-data";
    PayloadUUID = "6F0D3C1E-5B7A-4E2C-9A41-3D8E2F7B9C10";
    PayloadDisplayName = "Unified log private data";
    PayloadScope = "System";
    PayloadContent = [
      {
        PayloadType = "com.apple.system.logging";
        PayloadVersion = 1;
        PayloadIdentifier = "dev.bsamiee.logging.private-data.system";
        PayloadUUID = "A2B4C6D8-1E3F-4A5B-8C7D-9E0F1A2B3C4D";
        System."Enable-Private-Data" = true;
      }
    ];
  };

  # --- [GATEKEEPER]
  system.defaults.CustomSystemPreferences."/Library/Preferences/com.apple.security".GKAutoRearm = false;

  # --- [SSH_CLIENT]
  programs.ssh.knownHosts."github.com".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
  environment.etc."ssh/ssh_config.d/000-forge.conf".text = ''
    Host ${lib.concatStringsSep " " host.tailnet.servers}
      User root

    Host github.com
      User git
      IdentitiesOnly yes
      IdentityFile ~/.config/ssh/id_ed25519.pub
      BatchMode yes

    Host *
      IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
      KexAlgorithms ^mlkem768x25519-sha256,sntrup761x25519-sha512
      StrictHostKeyChecking accept-new
      ConnectTimeout 10
      TCPKeepAlive yes
      ControlMaster auto
      ControlPath ~/.ssh/sockets/%C
      ControlPersist 10m
      ServerAliveInterval 60
      HashKnownHosts yes
  '';

  # --- [REMOTE_LOGIN]
  services.openssh = {
    enable = true;
    extraConfig = ''
      AllowUsers ${lib.concatMapStringsSep " " (range: "${primaryUser}@${range}") host.tailnet.range}
      PerSourcePenaltyExemptList ${lib.concatStringsSep "," host.tailnet.range}
    '';
  };
  users.users.${primaryUser}.openssh.authorizedKeys.keys = [host.ssh.publicKey];

  # --- [SUDOERS_CONFIGURATION]
  security.sudo.extraConfig = ''
    ${primaryUser} ALL=(ALL) NOPASSWD: ALL
  '';
}
