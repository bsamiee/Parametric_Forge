# Title         : theme.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/common/theme.nix
# ----------------------------------------------------------------------------
# Universal Dracula theme configuration via Stylix

{ config, lib, pkgs, ... }:

{
  stylix = {
    enable = true;
    autoEnable = true; # By default, all installed apps are themed automatically
    base16Scheme = {
      base00 = "282a36"; # #282a36 Background
      base01 = "363447"; # #363447 Lighter background
      base02 = "44475a"; # #44475a Selection background
      base03 = "6272a4"; # #6272a4 Comments
      base04 = "9ea8c7"; # #9ea8c7 Dark foreground
      base05 = "f8f8f2"; # #f8f8f2 Default foreground
      base06 = "f0f1f4"; # #f0f1f4 Light foreground
      base07 = "ffffff"; # #ffffff Light background
      base08 = "ff5555"; # #ff5555 Red
      base09 = "ffb86c"; # #ffb86c Orange
      base0A = "f1fa8c"; # #f1fa8c Yellow
      base0B = "50fa7b"; # #50fa7b Green
      base0C = "8be9fd"; # #8be9fd Cyan
      base0D = "80bfff"; # #80bfff Blue
      base0E = "ff79c6"; # #ff79c6 Magenta
      base0F = "bd93f9"; # #bd93f9 Purple
    };

    # Required: Stylix needs an image for two purposes:
    # 1. Generate color scheme (if base16Scheme not provided)
    # 2. Set as wallpaper (if autoEnable is true)
    # Using 1x1 pixel = solid color background, no actual image
    image = pkgs.runCommand "dracula-bg.png" {} ''
      ${pkgs.imagemagick}/bin/magick -size 1x1 xc:'#282a36' $out
    '';

    # Terminal opacity (applies to all terminals)
    opacity = {
      terminal = 0.95;
      popups = 0.95;
    };

    # Disable specific targets:
    targets = {
      # Disable specific app theming
      # firefox.enable = false;
      # vscode.enable = false;
    };

    # --- Font configuration -------------------------------------------------
    # Stylix automatically applies the right font type to each app:
    # - monospace: terminals, editors, code viewers
    # - sansSerif: browsers, GUI apps, system UI
    # - serif: document viewers, reading apps (rarely used, but required by Stylix)
    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.geist-mono;
        name = "GeistMono Nerd Font Mono";
      };
      sansSerif = {
        package = pkgs.geist-font;
        name = "Geist";
      };
      serif = {
        package = pkgs.inter;
        name = "Inter";
      };
      sizes = {
        applications = 10;  # GUI apps like Firefox, VSCode UI
        terminal = 10;      # Terminal emulators and text editors
        desktop = 10;       # Desktop environment elements (panels, menus)
        popups = 10;        # Notifications, tooltips, popups
      };
    };
  };
}
