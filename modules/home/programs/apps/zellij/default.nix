# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/zellij/default.nix
# ----------------------------------------------------------------------------
# Zellij terminal multiplexer configuration

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.zellij;
in
{
  imports = [
    ./config.nix                # Nix-generated main config
    ./themes/dracula.nix        # Nix-generated Dracula theme
    ./layouts/default.nix       # Vertical split with lazygit
    ./layouts/stacked.nix       # Stacked panes with lazygit
  ];

  options.programs.zellij = {
    colors = mkOption {         # Single source of truth for all Zellij color configuration
      type = types.attrs;
      default = {
        background = { hex = "#15131F"; r = 21; g = 19; b = 31; };
        current_line = { hex = "#2A2640"; r = 42; g = 38; b = 64; };
        selection = { hex = "#44475A"; r = 68; g = 71; b = 90; };
        foreground = { hex = "#F8F8F2"; r = 248; g = 248; b = 242; };
        comment = { hex = "#6272A4"; r = 122; g = 113; b = 170; };
        purple = { hex = "#A072C6"; r = 160; g = 114; b = 198; };
        cyan = { hex = "#94F2E8"; r = 148; g = 242; b = 232; };
        green = { hex = "#50FA7B"; r = 80; g = 250; b = 123; };
        yellow = { hex = "#F1FA8C"; r = 241; g = 250; b = 140; };
        orange = { hex = "#F97359"; r = 249; g = 115; b = 89; };
        red = { hex = "#FF5555"; r = 255; g = 85; b = 85; };
        magenta = { hex = "#d82f94"; r = 216; g = 47; b = 148; };
        pink = { hex = "#E98FBE"; r = 233; g = 143; b = 190; };
      };
      description = "Color palette for Zellij theme and plugins";
    };
  };

  config = {
    home.packages = [ pkgs.zellij ];

    # --- Plugin Installation ------------------------------------------------
    xdg.configFile = {
      #" zellij-pane-picker.wasm is called by the plugin via url as per documentation
      "zellij/plugins/zjstatus.wasm".source = pkgs.fetchurl {
        url = "https://github.com/dj95/zjstatus/releases/download/v0.21.1/zjstatus.wasm";
        hash = "sha256-3BmCogjCf2aHHmmBFFj7savbFeKGYv3bE2tXXWVkrho=";
      };
    };
  };
}
