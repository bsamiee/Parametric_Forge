# Title         : security.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/darwin/settings/security.nix
# ----------------------------------------------------------------------------
# Developer-tool authorization, Gatekeeper, SSH host trust, and the passwordless sudo row.
{config, ...}: {
  # Debugger/developer-tool authorization without per-launch prompts: developer mode is a root activation, and the admin group already nests
  # into _developer. Every write is idempotent. TCC stays reset-only (tccutil); no TCC.db writes, no PPPC on this unmanaged host.
  system.activationScripts.postActivation.text = ''
    /usr/sbin/DevToolsSecurity -enable >/dev/null
  '';

  # --- [GATEKEEPER]
  # "Allow applications from → Anywhere" is a one-time bootstrap step: `sudo spctl --global-disable` only reveals the option and exits 1 until
  # it is confirmed in System Settings, whose SystemPolicy-prefs.plist write is SIP-restricted. Once chosen, syspolicyd's daily rearm activity
  # would restore assessments after 30 days unless GKAutoRearm is false; the domain is the absolute /Library path because nix-darwin writes
  # CustomSystemPreferences as root.
  system.defaults.CustomSystemPreferences."/Library/Preferences/com.apple.security".GKAutoRearm = false;

  # --- [SSH_KNOWN_HOSTS]
  # /etc/ssh/ssh_known_hosts, which every ssh client reads beside ~/.ssh/known_hosts: GitHub's published ed25519 host key (api.github.com/meta).
  programs.ssh.knownHosts."github.com".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";

  # --- [SUDOERS_CONFIGURATION]
  # The primary user, the only admin, runs every command as any user without a password: every shell, agent, and nh's elevated activation.
  security.sudo.extraConfig = ''
    ${config.system.primaryUser} ALL=(ALL) NOPASSWD: ALL
  '';
}
