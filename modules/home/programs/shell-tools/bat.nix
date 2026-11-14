{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.bat = {
    enable = true;

    config = {
      theme = "forge-dracula";
      style = "numbers,changes,header,grid";
      wrap = "character";
      tabs = "4";
    };

    themes."forge-dracula".src = config.forge.theme.projections.tmThemeFile;
  };

  home.activation.batCache = lib.mkForce (lib.hm.dag.entryAfter ["linkGeneration"] ''
    (
      export XDG_CACHE_HOME=${lib.escapeShellArg config.xdg.cacheHome}
      verboseEcho "Rebuilding bat theme cache"
      cd "${pkgs.emptyDirectory}"
      run --quiet ${lib.getExe config.programs.bat.package} cache --build
    )
  '');
}
