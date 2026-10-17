# Title         : procs.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/procs.nix
# ----------------------------------------------------------------------------
# ps replacement; renders process state, resource usage, and ports with estate-themed columns.
{pkgs, ...}: let
  # Styles are ANSI-16 slots; the terminal palette (estate.theme.ansi16 projected through WezTerm) resolves them to estate colors.
  tomlFormat = pkgs.formats.toml {};
  separator = {
    kind = "Separator";
    style = "White|BrightBlack";
  };

  # Rows differ from procs' defaults: a column's style is ByUnit, both searches false, and align Left unless a row says otherwise.
  procsConfig = {
    # --- [COLUMN_CONFIGURATION]
    columns = [
      {
        kind = "Pid";
        style = "BrightYellow|Yellow";
        numeric_search = true;
      }
      {
        kind = "Ppid";
        style = "Yellow|Yellow";
        numeric_search = true;
      }
      {
        kind = "User";
        style = "BrightGreen|Green";
        nonnumeric_search = true;
        min_width = 8;
      }
      separator
      {
        kind = "State";
        style = "ByState";
      }
      {
        kind = "UsageCpu";
        style = "ByPercentage";
        align = "Right";
      }
      {
        kind = "UsageMem";
        style = "ByPercentage";
        align = "Right";
      }
      {
        kind = "VmSize";
        align = "Right";
      }
      {
        kind = "VmRss";
        align = "Right";
      }
      {
        kind = "TcpPort";
        style = "BrightCyan|Cyan";
        numeric_search = true;
        max_width = 20;
      }
      {
        kind = "UdpPort";
        style = "BrightCyan|Cyan";
        numeric_search = true;
        max_width = 20;
      }
      {
        kind = "ReadBytes";
        align = "Right";
      }
      {
        kind = "WriteBytes";
        align = "Right";
      }
      separator
      {
        # Insertion slot: --sortd/--sorta/--insert land their column here and hard-fail without one.
        kind = "Slot";
        style = "BrightWhite|Black";
      }
      {
        kind = "CpuTime";
        style = "BrightCyan|Cyan";
      }
      {
        kind = "StartTime";
        style = "BrightMagenta|Magenta";
      }
      {
        kind = "ElapsedTime";
        style = "Magenta|Magenta";
      }
      {
        kind = "Command";
        style = "BrightWhite|Black";
        nonnumeric_search = true;
      }
    ];

    # --- [STYLE_CONFIGURATION]
    # A by_* table is read whole: procs gives its rows no per-row default.
    style = {
      unit = "Blue|Black";
      tree = "Cyan|Black";

      by_percentage = {
        color_000 = "BrightGreen|Green"; # 0% - Green
        color_025 = "Green|Green"; # 25% - Darker green
        color_050 = "BrightYellow|Yellow"; # 50% - Yellow
        color_075 = "Yellow|Yellow"; # 75% - Orange-ish
        color_100 = "BrightRed|Red"; # 100% - Red
      };

      by_state = {
        color_d = "Blue|Blue"; # Uninterruptible sleep (disk)
        color_r = "BrightGreen|Green"; # Running
        color_s = "BrightCyan|Cyan"; # Sleeping
        color_t = "BrightYellow|Yellow"; # Stopped
        color_z = "BrightRed|Red"; # Zombie
        color_x = "BrightMagenta|Magenta"; # Dead
        color_k = "Yellow|Yellow"; # Wakekill
        color_w = "BrightBlue|Blue"; # Waking
        color_p = "BrightYellow|Yellow"; # Parked
      };
    };

    # --- [DISPLAY_CONFIGURATION]
    display = {
      show_footer = true; # process counts
      show_kthreads = false;
    };

    # --- [SORT_CONFIGURATION]
    # Index counts every column row incl. separators: 5 = UsageCpu (top-CPU default).
    sort = {
      column = 5;
      order = "Descending";
    };

    # --- [PAGER_CONFIGURATION]
    pager = {
      detect_width = true;
      command = "less -SRX"; # -S no wrap, -R ANSI colors, -X no screen clear
    };
  };
in {
  home.packages = [pkgs.procs];
  xdg.configFile."procs/config.toml".source = tomlFormat.generate "procs-config" procsConfig;
}
