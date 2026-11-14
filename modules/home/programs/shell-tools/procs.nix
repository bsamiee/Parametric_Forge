{pkgs, ...}: let
  tomlFormat = pkgs.formats.toml {};
  separator = {
    kind = "Separator";
    style = "White|BrightBlack";
  };

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
    style = {
      unit = "Blue|Black";
      tree = "Cyan|Black";

      by_percentage = {
        color_000 = "BrightGreen|Green";
        color_025 = "Green|Green";
        color_050 = "BrightYellow|Yellow";
        color_075 = "Yellow|Yellow";
        color_100 = "BrightRed|Red";
      };

      by_state = {
        color_d = "Blue|Blue";
        color_r = "BrightGreen|Green";
        color_s = "BrightCyan|Cyan";
        color_t = "BrightYellow|Yellow";
        color_z = "BrightRed|Red";
        color_x = "BrightMagenta|Magenta";
        color_k = "Yellow|Yellow";
        color_w = "BrightBlue|Blue";
        color_p = "BrightYellow|Yellow";
      };
    };

    # --- [DISPLAY_CONFIGURATION]
    display = {
      show_footer = true;
    };

    # --- [SORT_CONFIGURATION]
    sort = {
      column = 5;
      order = "Descending";
    };

    # --- [PAGER_CONFIGURATION]
    pager = {
      detect_width = true;
      command = "less -SRX";
    };
  };
in {
  home.packages = [pkgs.procs];
  xdg.configFile."procs/config.toml".source = tomlFormat.generate "procs-config" procsConfig;
}
