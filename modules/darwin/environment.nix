# Title         : environment.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/darwin/environment.nix
# ----------------------------------------------------------------------------
# System-wide environment bridging so GUI and CLI processes agree on PATH.

{ lib, config, ... }:

let
  inherit (lib) concatLists concatStringsSep mkBefore optional unique;

  primaryHome = config.system.primaryUserHome;
  xdgDataHome = if primaryHome != null then "${primaryHome}/Library/Application Support" else null;

  userPaths = concatLists [
    optional (primaryHome != null) "${primaryHome}/.nix-profile/bin"
    optional (primaryHome != null) "${primaryHome}/.local/bin"
    optional (primaryHome != null) "${primaryHome}/bin"
    optional (xdgDataHome != null) "${xdgDataHome}/cargo/bin"
    optional (xdgDataHome != null) "${xdgDataHome}/go/bin"
    optional (xdgDataHome != null) "${xdgDataHome}/pnpm"
    optional (xdgDataHome != null) "${xdgDataHome}/npm/bin"
  ];

  sharedPaths = [
    "/run/current-system/sw/bin"
    "/nix/var/nix/profiles/default/bin"
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
    "/usr/local/bin"
    "/usr/local/sbin"
    "/usr/bin"
    "/bin"
    "/usr/sbin"
    "/sbin"
    "/opt/homebrew/opt/dotnet@8/bin"
    "/Applications/Rhino 8.app/Contents/Resources/bin"
  ];

  pathEntries = unique (userPaths ++ sharedPaths);
  renderedPath = concatStringsSep ":" pathEntries;
in {
  environment.systemPath = mkBefore pathEntries;

  launchd.user.envVariables = {
    PATH = renderedPath;
  };
}
