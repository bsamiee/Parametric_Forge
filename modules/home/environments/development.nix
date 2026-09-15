# Title         : development.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/environments/development.nix
# ----------------------------------------------------------------------------
# Development tools and version control
{config, ...}: {
  # Homebrew's own variables live in $XDG_CONFIG_HOME/homebrew/brew.env (modules/home/programs/shell-tools/forge-tools/default.nix), which brew
  # reads in every context, the sudo activation included.
  home.sessionVariables = {
    # --- [NIX]
    CACHIX_CACHE = "bsamiee";
    NIX_REMOTE = "daemon";

    # --- [GIT_VERSION_CONTROL]
    GITLEAKS_CONFIG = "${config.xdg.configHome}/gitleaks/gitleaks.toml";
    # Difftastic brightness follows the estate surface luminance, not a mode literal
    DFT_BACKGROUND = let
      surface = config.forge.theme.palette.background;
    in
      if surface.r + surface.g + surface.b < 384
      then "dark"
      else "light";

    # --- [BUILD_PRE_COMMIT]
    PRE_COMMIT_HOME = "${config.xdg.dataHome}/pre-commit";

    # --- [CLOUD_IAC]
    # Plugins, workspaces, credentials, and logs of the Pulumi CLI (a project's mise.toml row); the default is ~/.pulumi.
    PULUMI_HOME = "${config.xdg.dataHome}/pulumi";

    # --- [AI_CLAUDE]
    CLAUDE_CODE_DISABLE_AUTO_MEMORY = "0"; # Force auto-memory on (double-negative: DISABLE=0)
  };
}
