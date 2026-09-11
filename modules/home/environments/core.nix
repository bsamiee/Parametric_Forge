# Title         : core.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/environments/core.nix
# ----------------------------------------------------------------------------
# Core system environment variables
_: {
  home.sessionVariables = {
    # --- [LOCALE_TIME]
    TZ = "America/Chicago";
    LANG = "en_US.UTF-8";
    LC_ALL = "";

    # EDITOR/VISUAL are owned by programs.neovim.defaultEditor.

    # --- [PRIVACY_TELEMETRY_OPT_OUTS]
    CARGO_BINSTALL_DISABLE_TELEMETRY = "1";
    GITLEAKS_NO_UPDATE_CHECK = "true";
    BINSTALL_DISABLE_TELEMETRY = "1";
  };
}
