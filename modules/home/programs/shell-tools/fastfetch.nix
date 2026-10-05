# Title         : fastfetch.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/fastfetch.nix
# ----------------------------------------------------------------------------
# System information display themed from the estate palette owner
{config, ...}: let
  inherit (config.estate.theme) roles;
in {
  programs.fastfetch = {
    enable = true;

    settings = {
      "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";

      # --- [DISPLAY_CONFIGURATION]
      display = {
        size = {
          binaryPrefix = "iec"; # Use IEC (GiB, MiB) not SI (GB, MB)
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
            elapsed = roles.state.success.hex;
            total = roles.surface.selected.hex;
          };
        };
        percent = {
          type = 3;
          ndigits = 0;
          # Traffic-light health thresholds ride the state ladder; the `yellow` key carries the warning role (amber), never string-yellow.
          color = {
            green = roles.state.success.hex;
            yellow = roles.state.warning.hex;
            red = roles.state.danger.hex;
          };
        };
        brightColor = true;
        color = {
          keys = roles.accent.primary.hex;
          title = roles.accent.tertiary.hex;
          separator = roles.text.muted.hex;
          output = roles.text.primary.hex;
        };
      };

      # --- [LOGO_CONFIGURATION]
      logo = {
        type = "file";
        source = "${config.xdg.configHome}/fastfetch/logo.txt";
        padding = {
          top = 1;
          right = 3;
          left = 0;
        };
        printRemaining = true;
        preserveAspectRatio = true;
      };

      # --- [MODULES_CONFIGURATION]
      modules = [
        # Title and separator
        {type = "break";}
        {
          type = "title";
          format = "{user-name-colored}";
          color = {user = roles.state.success.hex;};
        }
        {type = "break";}

        # System Section
        {
          type = "os";
          key = "OS   ";
          format = "{name} {version} {arch}";
        }
        {
          type = "host";
          key = " ├ 󰇅  ";
          format = "{name}";
        }
        {
          type = "kernel";
          key = " ├   ";
          format = "{sysname} {release}";
        }
        {
          type = "uptime";
          key = " ├   ";
        }
        {
          type = "packages";
          key = " └ 󰏖  ";
          format = "{nix-default} (nix), {brew} (brew), {brew-cask} (cask)";
        }
        {type = "break";}

        # Desktop Section
        {
          type = "de";
          key = "UI   ";
          format = "{pretty-name}";
        }
        {
          type = "wm";
          key = " ├ 󰧨  ";
          format = "{pretty-name}";
        }
        {
          type = "lm";
          key = " ├   ";
        }
        {
          type = "wmtheme";
          key = " ├ 󰉼  ";
        }
        {
          type = "theme";
          key = " ├ 󰉼  ";
          format = "Dracula";
        }
        {
          type = "icons";
          key = " ├ 󰀻  ";
          format = "Nerd Fonts";
        }
        {
          type = "shell";
          key = " ├   ";
          format = "{pretty-name} {version}";
        }
        {
          type = "terminal";
          key = " ├   ";
          format = "WezTerm";
        }
        {
          type = "terminal";
          key = " ├ 󰕰  ";
          format = "{pretty-name}";
        }
        {
          type = "terminalfont";
          key = " └   ";
          format = config.estate.fonts.projections.fastfetchLabel;
        }
        {type = "break";}

        # Hardware Section
        {
          type = "chassis";
          key = "HW   ";
        }
        {
          type = "cpu";
          key = " ├   ";
          temp = true;
          format = "{name} ({cores-physical}) @ {freqMax}";
        }
        {
          type = "memory";
          key = " ├   ";
          format = "{used} / {total}";
        }
        {
          type = "swap";
          key = " ├ 󰓡  ";
          format = "{used} / {total} ({percentage}%)";
        }
        {
          type = "disk";
          key = " ├ 󰋊  ";
          folders = "/";
          format = "{size-used} / {size-total} ({size-percentage}%)";
        }
        {
          type = "display";
          key = " ├ 󰍹  ";
          format = "{width}x{height} @ {refresh-rate}Hz";
        }
        {
          type = "opengl";
          key = " └ 󰍛  ";
        }
        {type = "break";}

        # Network Section
        {
          type = "wifi";
          key = "NET  ";
          format = "{ssid}";
        }
        {
          type = "localip";
          key = " ├   ";
          format = "{ipv4}";
          showIpv6 = false;
          showLoop = false;
          compact = true;
        }
        {
          type = "publicip";
          key = " ├   ";
        }
        {
          type = "netio";
          key = " └   ";
        }
        {type = "break";}

        # Colors display
        {
          type = "colors";
          symbol = "circle";
          paddingLeft = 8;
        }
      ];
    };
  };
}
