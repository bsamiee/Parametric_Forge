# Title         : argocd.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/container-tools/argocd.nix
# ----------------------------------------------------------------------------
# GitOps continuous delivery CLI
{pkgs, ...}: {
  home.packages = [pkgs.argocd];
}
