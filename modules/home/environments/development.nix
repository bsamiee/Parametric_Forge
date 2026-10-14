# Title         : development.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/environments/development.nix
# ----------------------------------------------------------------------------
# Development tools and version control
{config, ...}: {
  # Homebrew's own variables live in $XDG_CONFIG_HOME/homebrew/brew.env (modules/home/programs/shell-tools/redeploy.nix), which brew
  # reads in every context, the sudo activation included.
  home.sessionVariables = {
    # --- [GIT_VERSION_CONTROL]
    # GITLEAKS_CONFIG is a cross-surface row of modules/common/toolchain-env.nix.
    # Difftastic brightness follows the estate surface luminance, not a mode literal
    DFT_BACKGROUND = let
      surface = config.estate.theme.palette.background;
    in
      if surface.r + surface.g + surface.b < 384
      then "dark"
      else "light";

    # --- [CLOUD_IAC]
    # PULUMI_HOME is a cross-surface row of modules/common/toolchain-env.nix.

    # --- [AI_CLAUDE]
    CLAUDE_CODE_DISABLE_AUTO_MEMORY = "0"; # Force auto-memory on (double-negative: DISABLE=0)
  };
}
