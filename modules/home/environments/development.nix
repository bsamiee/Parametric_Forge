# Title         : development.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/environments/development.nix
# ----------------------------------------------------------------------------
# Development tools and version control
_: {
  # Homebrew's own variables live in /etc/homebrew/brew.env (modules/darwin/homebrew), which brew reads in every context, the sudo activation
  # included.
  home.sessionVariables = {
    # --- [CLOUD_IAC]
    # PULUMI_HOME and DOPPLER_CONFIG_DIR are cross-surface rows of modules/common/toolchain-env.nix.

    # --- [AI_CLAUDE]
    CLAUDE_CODE_DISABLE_AUTO_MEMORY = "0"; # defined-falsy resolves to forced_on: overrides autoMemoryEnabled and the server gate
  };
}
