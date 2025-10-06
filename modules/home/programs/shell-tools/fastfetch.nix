# Title         : fastfetch.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/fastfetch.nix
# ----------------------------------------------------------------------------
# System information display with Dracula theme

{ config, lib, pkgs, ... }:

# Dracula theme color reference
# background    #15131F
# current_line  #2A2640
# selection     #44475A
# foreground    #F8F8F2
# comment       #6272A4
# purple        #A072C6
# cyan          #94F2E8
# green         #50FA7B
# yellow        #F1FA8C
# orange        #F97359
# red           #FF5555
# magenta       #d82f94
# pink          #E98FBE

{
  programs.fastfetch = {
    enable = true;

    settings = {
      "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";

      # --- Display Configuration --------------------------------------------
      display = {
        size = {
          binaryPrefix = "iec";  # Use IEC (GiB, MiB) not SI (GB, MB)
          ndigits = 1;
        };
        separator = " ";
        key = {
          width = 6;
          type = "string";
        };
        bar = {
          char = {
            elapsed = "━";
            total = "─";
          };
          width = 18;
          border = {
            left = "[ ";
            right = " ]";
          };
          color = {
            elapsed = "#50FA7B";   # Dracula green
            total = "#44475A";      # Dracula selection
          };
        };
        percent = {
          type = 3;
          ndigits = 0;
          color = {
            green = "#50FA7B";      # Dracula green
            yellow = "#F1FA8C";     # Dracula yellow
            red = "#FF5555";        # Dracula red
          };
        };
        brightColor = true;
        color = {
          keys = "#94F2E8";         # Dracula cyan (brighter variant)
          title = "#E98FBE";        # Dracula pink (brighter variant)
          separator = "#6272a4";    # Dracula comment
          output = "#F8F8F2";       # Dracula foreground
        };
      };

      # --- Logo Configuration -----------------------------------------------
      logo = {
        type = "auto";
        width = 28;
        height = 16;
        padding = {
          top = 1;
          right = 3;
          left = 0;
        };
        printRemaining = true;
        preserveAspectRatio = true;
      };

      # --- Modules Configuration --------------------------------------------
      modules = [
        # Title and separator
        { type = "title"; format = "{user-name-colored}"; }
        { type = "break"; }

        # System Section
        { type = "os"; key = "OS   "; format = "{name} {version} {arch}"; }
        { type = "host"; key = " ├ 󰇅 "; format = "{name}"; }
        { type = "kernel"; key = " ├  "; format = "{sysname} {release}"; }
        { type = "uptime"; key = " ├  "; }
        { type = "packages"; key = " └ 󰏖 "; format = "{nix-default} (nix), {brew} (brew), {brew-cask} (cask)"; }
        { type = "break"; }

        # Desktop Section
        { type = "de"; key = "UI   "; format = "{pretty-name}"; }
        { type = "wm"; key = " ├ 󰧨 "; format = "{pretty-name}"; }
        { type = "lm"; key = " ├  "; }
        { type = "wmtheme"; key = " ├ 󰉼 "; }
        { type = "theme"; key = " ├ 󰉼 "; format = "Dracula"; }
        { type = "icons"; key = " ├ 󰀻 "; format = "Nerd Fonts"; }
        { type = "shell"; key = " ├  "; format = "{pretty-name} {version}"; }
        { type = "terminal"; key = " ├  "; format = "WezTerm"; }
        { type = "terminal"; key = " ├ 󰕰 "; format = "{pretty-name}"; }
        { type = "terminalfont"; key = " └  "; format = "GeistMono Nerd Font 10pt"; }
        { type = "break"; }

        # Hardware Section
        { type = "chassis"; key = "HW   "; }
        { type = "cpu"; key = " ├  "; temp = true; format = "{name} ({cores-physical}) @ {freqMax}"; }
        { type = "memory"; key = " ├  "; format = "{used} / {total}"; }
        { type = "swap"; key = " ├ 󰓡 "; format = "{used} / {total} ({percentage}%)"; }
        { type = "disk"; key = " ├ 󰋊 "; folders = "/"; format = "{size-used} / {size-total} ({size-percentage}%"; }
        { type = "display"; key = " ├ 󰍹 "; format = "{width}x{height} @ {refresh-rate}Hz"; }
        { type = "opengl"; key = " └ 󰍛 "; }
        { type = "break"; }

        # Network Section
        { type = "wifi"; key = "NET  "; format = "{ssid}"; }
        { type = "localip"; key = " ├  "; format = "{ipv4}"; showIpv6 = false; showLoop = false; compact = true; }
        { type = "publicip"; key = " ├  "; }
        { type = "netio"; key = " └  "; }
        { type = "break"; }

        # Colors display
        { type = "colors"; symbol = "circle"; paddingLeft = 16; }
      ];
    };
  };
}