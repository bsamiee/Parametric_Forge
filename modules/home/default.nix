# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/default.nix
# ----------------------------------------------------------------------------
# Home Manager module aggregator
_: {
  imports = [
    ./environments
    ./fonts.nix
    ./theme.nix
    ./programs
    ./scripts
    ./xdg.nix
  ];

  # Modules with a choice write under the XDG roots in place of a dotfile in $HOME.
  home.preferXdgDirectories = true;

  # The App Management probe resets SystemPolicyAppBundles for every app (WezTerm's grant included) when one .DS_Store touch fails; the
  # copy reports a real permission error itself.
  targets.darwin.copyApps.enableChecks = false;
}
