# Title         : redeploy.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/redeploy.nix
# ----------------------------------------------------------------------------
# redeploy, the only activation path: `redeploy build|switch [nh args]` runs `nh darwin` on the host flake (nom progress, dix diff, system
# profile set, elevated activation) under `cachix watch-exec`, whose post-build hook pushes each locally built path as it lands, so a failed
# build retries from the cache. The push token is the ambient CACHIX_AUTH_TOKEN that every zsh (.zshenv) and GUI session (gui-op-secrets)
# carries from the op session cache.
{
  config,
  host,
  osConfig,
  pkgs,
  ...
}: let
  redeploy = pkgs.writeShellApplication {
    name = "redeploy";
    runtimeInputs = [pkgs.cachix config.programs.nh.package];
    text = ''
      exec cachix watch-exec ${osConfig.cachix.cache} -- nh darwin "$1" ${host.flakeRoot} -H ${host.name} --show-activation-logs "''${@:2}"
    '';
  };
in {
  home.packages = [redeploy];
}
