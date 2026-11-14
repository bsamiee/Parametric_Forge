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
  '';

  # --- [GATEKEEPER]
  system.defaults.CustomSystemPreferences."/Library/Preferences/com.apple.security".GKAutoRearm = false;

  # --- [SSH_KNOWN_HOSTS]
  programs.ssh.knownHosts."github.com".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";

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
