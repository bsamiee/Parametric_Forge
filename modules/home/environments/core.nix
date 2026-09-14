# Title         : core.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/environments/core.nix
# ----------------------------------------------------------------------------
# Core system environment variables
{host, ...}: {
  home.sessionVariables = {
    # --- [LOCALE_TIME]
    TZ = host.timeZone;
    LANG = "en_US.UTF-8";
    LC_ALL = "";

    # EDITOR/VISUAL are owned by programs.neovim.defaultEditor.

    # --- [PRIVACY_TELEMETRY_OPT_OUTS]
    GITLEAKS_NO_UPDATE_CHECK = "true";
  };
}
