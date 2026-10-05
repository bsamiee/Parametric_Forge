# Title         : security.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/darwin/settings/security.nix
# ----------------------------------------------------------------------------
# Developer-tool authorization, Touch ID for sudo, and the primary user's passwordless sudo row for Darwin.
{config, ...}: {
  # Debugger/developer-tool authorization without per-launch prompts: developer mode plus _developer membership are idempotent root activations. TCC
  # stays reset-only (tccutil); no TCC.db writes, no PPPC on this unmanaged host.
  system.activationScripts.postActivation.text = ''
    /usr/sbin/DevToolsSecurity -status | grep -q "currently enabled" \
      || /usr/sbin/DevToolsSecurity -enable
    dsmemberutil checkmembership -U ${config.system.primaryUser} -G _developer | grep -q "^user is a member" \
      || /usr/sbin/dseditgroup -o edit -t user -a ${config.system.primaryUser} _developer
    # Authorization rights behind the System Settings unlock, installer, network, and launchd daemon dialogs: allow without a prompt, idempotent
    for right in system.preferences system.preferences.security system.preferences.network system.privilege.admin system.install.software com.apple.ServiceManagement.daemons.modify; do
      /usr/bin/security authorizationdb read "$right" 2>/dev/null | grep -q "<string>allow</string>" \
        || /usr/bin/security authorizationdb write "$right" allow
    done
  '';

  # --- [PAM_AUTHENTICATION]
  security.pam.services.sudo_local.touchIdAuth = true;
  # --- [SUDOERS_CONFIGURATION]
  # The primary user runs every command as any user without a password, so every shell, agent, and the deploy rail's `sudo -n` pass; Touch ID
  # (sudo_local above) serves every other admin account.
  security.sudo.extraConfig = ''
    ${config.system.primaryUser} ALL=(ALL) NOPASSWD: ALL
  '';
}
