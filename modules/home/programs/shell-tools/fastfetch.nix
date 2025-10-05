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
        separator = ": ";
        key = {
          width = 16;
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
        { type = "title"; format = "{user-name-colored}@{host-name-colored}"; }
        { type = "separator"; string = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; }

        # System Section
        { type = "custom"; format = "── System ───────────────────────"; }
        { type = "os"; key = "{icon} OS"; format = "{name} {version} {arch}"; }
        { type = "host"; key = "󰇅 Host"; format = "{name}"; }
        { type = "kernel"; key = " Kernel"; format = "{sysname} {release}"; }
        { type = "uptime"; key = " Uptime"; }
        { type = "packages"; key = "󰏖 Packages"; format = "{nix-default} (nix), {brew} (brew), {brew-cask} (cask)"; }
        { type = "break"; }

        # Desktop Section
        { type = "custom"; format = "── Desktop ──────────────────────"; }
        { type = "de"; key = " DE"; format = "{pretty-name}"; }
        { type = "wm"; key = "󰧨 WM"; format = "{pretty-name}"; }
        { type = "lm"; key = " Login Manager"; }
        { type = "wmtheme"; key = "󰉼 WM Theme"; }
        { type = "theme"; key = " Theme"; }
        { type = "icons"; key = "󰀻 Icons"; }
        { type = "shell"; key = " Shell"; format = "{pretty-name} {version}"; }
        { type = "terminal"; key = " Terminal"; format = "{pretty-name}"; }
        { type = "terminalfont"; key = " UI Font"; format = "{name} {size}pt"; }
        { type = "break"; }

        # Hardware Section
        { type = "custom"; format = "── Hardware ─────────────────────"; }
        { type = "chassis"; key = "󰌢 Chassis"; }
        { type = "board"; key = " Board"; }
        { type = "bios"; key = "󰨇 BIOS"; }
        { type = "cpu"; key = " CPU"; temp = true; format = "{name} ({cores-physical}) @ {freqMax}"; }
        { type = "cpuusage"; key = " CPU Usage"; }
        { type = "gpu"; key = "󰍛 GPU"; temp = true; format = "{name}"; }
        { type = "memory"; key = " Memory"; format = "{used} / {total}"; }
        { type = "memory"; key = " Memory Usage"; format = "{percentage-bar} ({percentage}%)"; }
        { type = "swap"; key = "󰓡 Swap"; format = "{used} / {total} ({percentage}%)"; }
        { type = "disk"; key = " Disk"; folders = "/"; format = "{size-used} / {size-total}"; }
        { type = "disk"; key = " Disk Usage"; folders = "/"; format = "{size-percentage-bar} ({size-percentage}%)"; }
        { type = "display"; key = "󰍹 Display"; format = "{width}x{height} @ {refresh-rate}Hz"; }
        { type = "opengl"; key = "󰍛 OpenGL"; }
        { type = "vulkan"; key = "󰍛 Vulkan"; }
        { type = "break"; }

        # Network Section
        { type = "custom"; format = "── Network ──────────────────────"; }
        { type = "wifi"; key = " WiFi"; format = "{ssid}"; }
        { type = "localip"; key = " Local IP"; format = "{ipv4}"; showIpv6 = false; showLoop = false; compact = true; }
        { type = "publicip"; key = " Public IP"; }
        { type = "netio"; key = " Net IO"; }
        { type = "bluetooth"; key = " Bluetooth"; }
        { type = "break"; }

        # Software Section
        { type = "custom"; format = "── Software ─────────────────────"; }
        {
          type = "command";
          key = "󰊢 Git Status";
          text = "if git rev-parse --git-dir > /dev/null 2>&1; then changes=$(git status --porcelain | wc -l | tr -d ' '); if [ \"$changes\" -eq 0 ]; then echo 'Clean'; else echo \"$changes changes\"; fi; else echo 'Not a repo'; fi";
        }
        {
          type = "command";
          key = "󰎙 Node";
          text = "node --version 2>/dev/null | sed 's/v//' || echo 'Not installed'";
        }
        {
          type = "command";
          key = "󰌠 Python";
          text = "python3 --version 2>/dev/null | cut -d' ' -f2 || echo 'Not installed'";
        }
        { type = "break"; }

        # Media Section
        { type = "custom"; format = "── Media ───────────────────────"; }
        { type = "media"; key = " Now Playing"; }
        { type = "break"; }

        # Status Section
        { type = "custom"; format = "── Status ──────────────────────"; }
        { type = "battery"; key = "󰂄 Battery"; format = "{capacity}% ({status})"; }
        { type = "locale"; key = " Locale"; }
        { type = "datetime"; key = " Time"; format = "{month-name-short} {day-pretty}, {year} {hour-pretty}:{minute-pretty}"; }
        { type = "break"; }

        # Colors display
        { type = "colors"; symbol = "circle"; paddingLeft = 16; }
      ];
    };
  };
}
