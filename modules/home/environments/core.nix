# Title         : core.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/environments/core.nix
# ----------------------------------------------------------------------------
# Core system environment variables
{pkgs, ...}: {
  home.sessionVariables = {
    # --- Locale & Time ------------------------------------------------------
    TZ = "America/Chicago";
    LANG = "en_US.UTF-8";
    LC_ALL = "";

    # --- Editor  ------------------------------------------------------------
    EDITOR = "nvim";
    VISUAL = "code --wait";

    # --- File Type Detection ------------------------------------------------
    MAGIC = "${pkgs.file}/share/misc/magic.mgc";

    # --- Privacy & Telemetry Opt-Outs ---------------------------------------
    CARGO_BINSTALL_DISABLE_TELEMETRY = "1";
    AZURE_CORE_COLLECT_TELEMETRY = "0";
    POWERSHELL_TELEMETRY_OPTOUT = "1";
    GITLEAKS_NO_UPDATE_CHECK = "true";
    BINSTALL_DISABLE_TELEMETRY = "1";
    GATSBY_TELEMETRY_DISABLED = "1";
    NEXT_TELEMETRY_DISABLED = "1";
    SAM_CLI_TELEMETRY = "0";
    DO_NOT_TRACK = "1";
  };
}
