{
  config,
  lib,
  pkgs,
  theme,
  ...
}: {
  programs.bat = {
    enable = true;

    config = {
      theme = "dracula";
      style = "numbers,changes,header,grid";
      wrap = "character";
      italic-text = "always";
    };

    themes."dracula".src = theme.projections.tmThemeFile;
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
