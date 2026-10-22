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
    # Difftastic brightness follows the theme surface luminance, not a mode literal
    DFT_BACKGROUND = let
      surface = config.forge.theme.palette.background;
    in
      if surface.r + surface.g + surface.b < 384
      then "dark"
      else "light";

    # --- [CLOUD_IAC]
    # PULUMI_HOME and DOPPLER_CONFIG_DIR are cross-surface rows of modules/common/toolchain-env.nix.

    # --- [AI_CLAUDE]
    CLAUDE_CODE_DISABLE_AUTO_MEMORY = "0"; # Force auto-memory on (double-negative: DISABLE=0)
  };
}
