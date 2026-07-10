# Title         : core.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/environments/core.nix
# ----------------------------------------------------------------------------
# Core system environment variables
{pkgs, ...}: {
  # MAGIC below points at this package's magic.mgc; the binary must ride with it — /usr/bin/file 5.41 rejects v20 magic and floods every `file` call.
  home.packages = [pkgs.file];

  home.sessionVariables = {
    # --- [LOCALE_TIME]
    TZ = "America/Chicago";
    LANG = "en_US.UTF-8";
    LC_ALL = "";

    # EDITOR/VISUAL are owned by programs.neovim.defaultEditor (apps/nvim).

    # --- [FILE_TYPE_DETECTION]
    MAGIC = "${pkgs.file}/share/misc/magic.mgc";

    # --- [PRIVACY_TELEMETRY_OPT_OUTS]
    CARGO_BINSTALL_DISABLE_TELEMETRY = "1";
    AZURE_CORE_COLLECT_TELEMETRY = "0";
    POWERSHELL_TELEMETRY_OPTOUT = "1";
    GITLEAKS_NO_UPDATE_CHECK = "true";
    BINSTALL_DISABLE_TELEMETRY = "1";
    GATSBY_TELEMETRY_DISABLED = "1";
    NEXT_TELEMETRY_DISABLED = "1";
    SAM_CLI_TELEMETRY = "0";
  };
}
