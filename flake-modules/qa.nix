# Title         : qa.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : flake-modules/qa.nix
# ----------------------------------------------------------------------------
# The one lint gate treefmt cannot carry: treefmt-nix runs `statix fix`, which exits 0 on lints it cannot rewrite (W20 repeated keys), so
# `statix check` stays a flake check. deadnix, nixf-diagnose, and the formatters gate through treefmt-nix's own `treefmt` check; host eval is
# proven by `redeploy build`.
{self, ...}: {
  perSystem = {pkgs, ...}: {
    checks.statix = pkgs.runCommand "statix" {nativeBuildInputs = [pkgs.statix];} ''
      statix check --ignore 'overlays/_sources/**' ${self}
      touch "$out"
    '';
  };
}
