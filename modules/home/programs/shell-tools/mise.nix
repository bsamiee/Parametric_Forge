# Title         : mise.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/mise.nix
# ----------------------------------------------------------------------------
# Polyglot runtime manager (Node, Python, Ruby, etc.) and task runner
{pkgs, ...}: let
  miseForge = pkgs.mise.overrideAttrs (old: {
    checkFlags =
      (old.checkFlags or [])
      ++ [
        # Same sandboxed special-permission-bit failure nixpkgs already skips on Linux.
        "--skip=oci::layer::tests::preserve_metadata_dir_layer_keeps_special_permission_bits"
      ];
  });
in {
  home.packages = [miseForge];
}
