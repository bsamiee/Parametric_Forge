# Title         : xdg.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/xdg.nix
# ----------------------------------------------------------------------------
# XDG hygiene owner: base-directory env, Linux user dirs and desktop shims, and permission-classed directory rows for tools that expect their target
# directory ahead of first run. Runtime forge projections (~/.config/forge, ~/.local/state/forge*) are owner-created; only ahead-of-run rows live here.
{
  config,
  host,
  lib,
  ...
}: let
  # One row per mode class; the activation script is a fold over the rows. 700: SSH key/socket custody, the 1Password CLI config dir
  # (shell-tools/1password.nix links the secret template into it) and the operator-private LaunchAgents dir home-manager installs plists into on
  # Darwin. 755: PATH bins (toolchain-env vectors), media/doc tool homes
  # wired by environments/media.nix env keys, and the history home of the one tool that never creates its target directory (sqlite3, the
  # SQLITE_HISTORY session row of modules/common/toolchain-env.nix).
  dirRows = {
    "700" =
      [
        "${config.home.homeDirectory}/.ssh"
        "${config.home.homeDirectory}/.ssh/sockets"
        "${config.xdg.configHome}/op"
      ]
      ++ lib.optional (host.os == "darwin") "${config.home.homeDirectory}/Library/LaunchAgents";
    "755" = [
      "${config.home.homeDirectory}/.local/bin"
      "${config.home.homeDirectory}/bin"
      "${config.xdg.stateHome}/ffmpeg"
      "${config.xdg.stateHome}/sqlite"
      "${config.xdg.cacheHome}/ImageMagick"
      "${config.xdg.configHome}/ImageMagick"
      "${config.xdg.dataHome}/pandoc"
    ];
  };
in {
  xdg = {
    enable = true;

    # Linux user directories and desktop integration; Darwin owns its own.
    userDirs = lib.mkIf (host.os == "nixos") {
      enable = true;
      createDirectories = true;
    };
    dataFile = lib.mkIf (host.os == "nixos") {
      "applications/.keep".text = "";
      "icons/.keep".text = "";
      "Trash/files/.keep".text = "";
      "Trash/info/.keep".text = "";
    };
  };

  # chmod runs on every activation, not only creation: mkdir -pm leaves a pre-existing loose directory untouched, and the 700 class is custody.
  # The rows precede linkGeneration and setupLaunchAgents, which otherwise create the directories they populate at the default mode.
  home.activation.forgeDirRows = lib.hm.dag.entryBetween ["linkGeneration" "setupLaunchAgents"] ["writeBoundary"] (
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList (mode: dirs: "mkdir -p ${lib.escapeShellArgs dirs} && chmod ${mode} ${lib.escapeShellArgs dirs}") dirRows
    )
  );
}
