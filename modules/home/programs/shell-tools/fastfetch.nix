{
  theme,
  typography,
  ...
}: let
  inherit (theme) roles;
in {
  programs.fastfetch = {
    enable = true;

    settings = {
      "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";

      # --- [DISPLAY_CONFIGURATION]
      display = {
        size.ndigits = 1;
        separator = " ";
        key.width = 6;
        bar = {
          char = {
            elapsed = "━";
            total = "─";
          };
          width = 18;
          color = {
            elapsed = roles.state.success.hex;
            total = roles.surface.selected.hex;
          };
        };
        percent = {
          type = 3;
          color = {
            green = roles.state.success.hex;
            yellow = roles.state.warning.hex;
            red = roles.state.danger.hex;
          };
        };
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
        source = "${../../assets/ascii/irgc-ascii-art.txt}";
        padding = {
          top = 1;
          right = 3;
          left = 0;
        };
      };

      # --- [MODULES_CONFIGURATION]
      modules = [
        {type = "break";}
        {
          type = "title";
          format = "{user-name-colored}";
          color = {user = roles.state.success.hex;};
        }
        {type = "break";}

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
          format = "{nix-all} (nix), {brew} (brew), {brew-cask} (cask)";
        }
        {type = "break";}

        {
          type = "wm";
          key = "UI   ";
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
          type = "shell";
          key = " ├   ";
          format = "{pretty-name} {version}";
        }
        {
          type = "terminal";
          key = " ├ 󰕰  ";
          format = "{pretty-name}";
        }
        {
          type = "terminalfont";
          key = " └   ";
          format = typography.projections.fastfetchLabel;
        }
        {type = "break";}

        {
          type = "chassis";
          key = "HW   ";
        }
        {
          type = "cpu";
          key = " ├   ";
          format = "{name} ({cores-physical}) @ {freq-max}";
        }
        {
          type = "memory";
          key = " ├   ";
          format = "{used} / {total}";
        }
        {
          type = "swap";
          key = " ├ 󰓡  ";
          format = "{used} / {total} ({percentage})";
        }
        {
          type = "disk";
          key = " ├ 󰋊  ";
          folders = "/";
          format = "{size-used} / {size-total} ({size-percentage})";
        }
        {
          type = "display";
          key = " ├ 󰍹  ";
          format = "{width}x{height} @ {refresh-rate}Hz";
        }
        {
          type = "gpu";
          key = " └ 󰍛  ";
          format = "{name} ({core-count})";
        }
        {type = "break";}

        {
          type = "wifi";
          key = "NET  ";
          format = "{ssid}";
        }
        {
          type = "localip";
          key = " ├   ";
          format = "{ipv4}";
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

        {
          type = "colors";
          symbol = "circle";
          paddingLeft = 8;
        }
      ];
    };
  };
}
