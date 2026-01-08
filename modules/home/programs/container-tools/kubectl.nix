# Title         : kubectl.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/container-tools/kubectl.nix
# ----------------------------------------------------------------------------
# Kubernetes CLI with colorized output and context switching
{
  pkgs,
  lib,
  ...
}: {
  home.packages = with pkgs; [
    kubectl # Kubernetes CLI
    kubecolor # Colorized kubectl output
    kubectx # Context/namespace switcher (includes kubens)
  ];

  # Delegate kubecolor completions to kubectl (after carapace loads kubectl completions)
  programs.zsh.initContent = lib.mkAfter ''
    # --- Kubecolor Completion Delegation ----------------------------------------
    compdef kubecolor=kubectl
  '';
}
