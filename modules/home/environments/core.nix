# Title         : core.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/environments/core.nix
# ----------------------------------------------------------------------------
# Core system environment variables

{ config, pkgs, ... }:

{
  home.sessionVariables = {
    # --- Locale & Time -------------------------------------------------------
    TZ = "America/Chicago";
    LANG = "en_US.UTF-8";
    LC_ALL = "";

    # --- Editor & Pager ------------------------------------------------------
    EDITOR = "nvim";
    VISUAL = "code --wait";
    PAGER = "delta";
    LESS = "-FRX";
    LESSOPEN = "|batpipe %s";
    BATPIPE = "color";  # Enable colors in less
    MANPAGER = "batman";
    MANROFFOPT = "-c";

    # --- Git & Version Control -----------------------------------------------
    GITLEAKS_CONFIG = "${config.xdg.configHome}/gitleaks/gitleaks.toml";
    GH_CONFIG_DIR = "${config.xdg.configHome}/gh";
    GH_PAGER = "delta";
    # GIT_PAGER handled by programs.git.delta.enable

    # --- File Type Detection -------------------------------------------------
    MAGIC = "${pkgs.file}/share/misc/magic.mgc";

    # --- Privacy & Telemetry Opt-Outs ----------------------------------------
    CARGO_BINSTALL_DISABLE_TELEMETRY = "1";
    AZURE_CORE_COLLECT_TELEMETRY = "0";
    POWERSHELL_TELEMETRY_OPTOUT = "1";
    DOTNET_CLI_TELEMETRY_OPTOUT = "1";
    GITLEAKS_NO_UPDATE_CHECK = "true";
    BINSTALL_DISABLE_TELEMETRY = "1";
    GATSBY_TELEMETRY_DISABLED = "1";
    NEXT_TELEMETRY_DISABLED = "1";
    SAM_CLI_TELEMETRY = "0";
    DO_NOT_TRACK = "1";
  };
}
