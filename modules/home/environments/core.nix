# Title         : core.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/environments/core.nix
# ----------------------------------------------------------------------------
# Core system environment variables
_: {
  home.sessionVariables = {
    # --- [LOCALE]
    # The time zone is macOS's automatic zone through /etc/localtime, never a TZ row.
    LANG = "en_US.UTF-8";

    # EDITOR/VISUAL are cross-surface rows of modules/common/toolchain-env.nix.
  };
}
