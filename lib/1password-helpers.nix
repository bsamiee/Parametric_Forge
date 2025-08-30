# Title         : lib/1password-helpers.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /lib/1password-helpers.nix
# ----------------------------------------------------------------------------
# Helper functions for 1Password CLI interaction and secret management.

{ lib }:

rec {
  # --- Core Validation Helpers ----------------------------------------------
  opAvailable = "command -v op >/dev/null 2>&1";
  opAuthenticated = "op account get >/dev/null 2>&1";
  opReady = "${opAvailable} && ${opAuthenticated}";

  # --- SSH Agent Socket Path ------------------------------------------------
  opSSHSocket =
    ctx:
    let
      # Handle both string and context object inputs
      isDarwin =
        if builtins.isString ctx then
          lib.hasSuffix "darwin" ctx
        else
          ctx.isDarwin or (lib.hasSuffix "darwin" (ctx.system or ""));

      isLinux =
        if builtins.isString ctx then lib.hasSuffix "linux" ctx else ctx.isLinux or (lib.hasSuffix "linux" (ctx.system or ""));

      # WSL detection from context
      isWSL = if builtins.isAttrs ctx then ctx.isWSL or false else false;
    in
    if isDarwin then
      # macOS standard location
      "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    else if isWSL then
      # WSL2 can use Windows 1Password via npiperelay or socat bridge
      # User can set WSL_1PASSWORD_SOCKET environment variable to override
      "\${WSL_1PASSWORD_SOCKET:-/tmp/1password-agent.sock}"
    else if isLinux then
      # Standard Linux path (1Password 8.10.28+ with CLI 2.24.0+)
      "$HOME/.1password/agent.sock"
    else
      # Unknown platform - activation script will warn
      "";

  # --- Secret Fetching ------------------------------------------------------
  fetchSecret = ref: "if ${opReady}; then op read \"${ref}\" 2>/dev/null || echo \"\"; else echo \"\"; fi";

  # --- Cache Management -----------------------------------------------------
  checkCacheFresh =
    cacheFile: maxAgeMinutes:
    "[ -f \"${cacheFile}\" ] && [ -z \"$(find \"${cacheFile}\" -mmin +${toString maxAgeMinutes} 2>/dev/null)\" ]";
}
