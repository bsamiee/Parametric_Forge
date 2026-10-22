# Title         : bat.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/bat.nix
# ----------------------------------------------------------------------------
# Cat clone with syntax highlighting and Git integration
{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.bat = {
    enable = true;

    # Rows differ from bat's defaults (style drops snip, wrap is auto upstream); Nix, JSON with comments, and Jenkinsfiles map natively.
    config = {
      theme = "forge-dracula";
      style = "numbers,changes,header,grid";
      wrap = "character";
      tabs = "4";

      map-syntax = [".envrc:Bash"];
    };

    # tmTheme from modules/home/theme.nix; the activation cache build exposes it to bat and, through the bat cache, to delta's syntax-theme.
    themes."forge-dracula".src = config.forge.theme.projections.tmThemeFile;

    extraPackages = with pkgs.bat-extras; [
      batman # Colored man pages
      batgrep # Ripgrep wrapper with bat preview
    ];
  };

  # Home Manager's batCache step echoes every cache write and a "no syntaxes" notice into each switch; the same rebuild (empty working
  # directory for sharkdp/bat#1726) under `run --quiet` keeps stdout off the activation log while stderr still surfaces a failed build.
  home.activation.batCache = lib.mkForce (lib.hm.dag.entryAfter ["linkGeneration"] ''
    (
      export XDG_CACHE_HOME=${lib.escapeShellArg config.xdg.cacheHome}
      verboseEcho "Rebuilding bat theme cache"
      cd "${pkgs.emptyDirectory}"
      run --quiet ${lib.getExe config.programs.bat.package} cache --build
    )
  '');
}
