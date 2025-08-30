# Title         : ui-daemon.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /00.system/darwin/services/ui-daemon.nix
# ----------------------------------------------------------------------------
# UI services using built-in nix-darwin service modules.

{
  pkgs,
  lib,
  context,
  ...
}:

{
  # --- SketchyBar Status Bar ------------------------------------------------
  services.sketchybar = {
    enable = lib.mkDefault context.isDarwin;
    package = pkgs.sketchybar;
    extraPackages = [
      pkgs.sbarlua # Lua interface for SketchyBar
      pkgs.sketchybar-app-font # App icon font
    ];
    # Configuration managed via ~/.config/sketchybar/sketchybarrc (deployed by home-manager)
  };
}
