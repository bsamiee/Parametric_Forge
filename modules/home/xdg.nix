# Title         : xdg.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/xdg.nix
# ----------------------------------------------------------------------------
# XDG hygiene owner: base-directory env and permission-classed directory rows for tools that expect their target directory ahead of first
# run. Runtime projections (the services state under ~/.local/state) are owner-created; only ahead-of-run rows live here.
{
  config,
  lib,
  ...
}: let
  # One row per mode class; the activation script is a fold over the rows. 700: SSH key/socket custody, the 1Password CLI config dir
  # (shell-tools/1password.nix links the secret template into it) and the state dir holding its session cache, and the operator-private
  # LaunchAgents dir home-manager installs plists into. 755: the user bin of the toolchain-env PATH vector, the ImageMagick temporary path
  # environments/media.nix names, the zsh completion dump directory (zsh/completions.nix), and the history home of the one tool that never
  # creates its target directory (sqlite3, the SQLITE_HISTORY session row of modules/common/toolchain-env.nix).
  dirRows = {
    "700" = [
      "${config.home.homeDirectory}/.ssh"
      "${config.home.homeDirectory}/.ssh/sockets"
      "${config.xdg.configHome}/op"
      "${config.xdg.stateHome}/op"
      "${config.home.homeDirectory}/Library/LaunchAgents"
    ];
    "755" = [
      "${config.home.homeDirectory}/.local/bin"
      "${config.xdg.cacheHome}/ImageMagick"
      "${config.xdg.cacheHome}/zsh"
      "${config.xdg.stateHome}/sqlite"
    ];
  };
in {
  xdg.enable = true;

  # chmod runs on every activation, not only creation: mkdir -pm leaves a pre-existing loose directory untouched, and the 700 class is custody.
  # The rows precede linkGeneration and setupLaunchAgents, which otherwise create the directories they populate at the default mode.
  home.activation.dirRows = lib.hm.dag.entryBetween ["linkGeneration" "setupLaunchAgents"] ["writeBoundary"] (
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList (mode: dirs: "mkdir -p ${lib.escapeShellArgs dirs} && chmod ${mode} ${lib.escapeShellArgs dirs}") dirRows
    )
  );
}
