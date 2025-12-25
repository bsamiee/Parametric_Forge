# Title         : kubeseal.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/container-tools/kubeseal.nix
# ----------------------------------------------------------------------------
# Sealed Secrets CLI for encrypting secrets in git
{pkgs, ...}: {
  home.packages = [pkgs.kubeseal];
}
