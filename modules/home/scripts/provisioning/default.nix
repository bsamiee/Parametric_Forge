# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/scripts/provisioning/default.nix
# ----------------------------------------------------------------------------
# Local provisioning scripts for disposable project spike infrastructure.
{...}: {
  imports = [
    ./rasm-spike-stack
  ];
}
