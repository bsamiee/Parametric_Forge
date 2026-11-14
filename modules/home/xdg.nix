{
  config,
  lib,
  ...
}: let
  dirRows = {
    "700" = [
      "${config.home.homeDirectory}/.ssh"
      "${config.home.homeDirectory}/.ssh/sockets"
      "${config.xdg.configHome}/op"
      "${config.xdg.configHome}/pg"
      "${config.xdg.stateHome}/op"
      "${config.home.homeDirectory}/Library/LaunchAgents"
    ];
    "755" = [
      "${config.home.homeDirectory}/.local/bin"
      "${config.xdg.cacheHome}/ab-av1"
      "${config.xdg.cacheHome}/parallel"
      "${config.xdg.cacheHome}/zsh"
      "${config.xdg.stateHome}/psql"
      "${config.xdg.stateHome}/sqlite"
    ];
  };
in {
  xdg.enable = true;

  home.activation.dirRows = lib.hm.dag.entryBetween ["linkGeneration" "setupLaunchAgents"] ["writeBoundary"] (
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList (mode: dirs: "run mkdir -p ${lib.escapeShellArgs dirs}\nrun chmod ${mode} ${lib.escapeShellArgs dirs}") dirRows
    )
  );
}
