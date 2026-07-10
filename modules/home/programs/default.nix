# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/default.nix
# ----------------------------------------------------------------------------
# Home Manager programs aggregator; GUI/mac surfaces gate on the host context.

{
  host,
  lib,
  ...
}: {
  imports =
    [
      ./container-tools
      ./git-tools
      ./languages
      ./media-tools
      ./nix-tools
      ./shell-tools
      ./zsh
    ]
    ++ lib.optionals (host.os == "darwin") [
      ./apps
      ./mac-tools
    ];
}
