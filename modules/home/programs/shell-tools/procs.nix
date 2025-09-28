# Title         : procs.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/shell-tools/procs.nix
# ----------------------------------------------------------------------------
# Modern ps replacement with Dracula theme

{ config, lib, pkgs, ... }:

# Dracula theme color reference (for understanding color mappings)
# background    #15131F
# current_line  #2A2640
# selection     #44475a
# foreground    #F8F8F2
# comment       #7A71AA
# purple        #A072C6
# cyan          #94F2E8
# green         #50FA7B
# yellow        #F1FA8C
# orange        #F97359
# red           #ff5555
# magenta       #d82f94
# pink          #E98FBE

let
  tomlFormat = pkgs.formats.toml { };

  procsConfig = {
    # --- Column Configuration (based on official CONFIG_LARGE) -------------
    columns = [
      {
        kind = "Pid";
        style = "BrightYellow|Yellow";
        numeric_search = true;
        nonnumeric_search = false;
        align = "Left";
      }
      {
        kind = "User";
        style = "BrightGreen|Green";
        numeric_search = false;
        nonnumeric_search = true;
        align = "Left";
        min_width = 8;
      }
      {
        kind = "Separator";
        style = "White|BrightBlack";
        numeric_search = false;
        nonnumeric_search = false;
        align = "Left";
      }
      {
        kind = "State";
        style = "ByState";
        numeric_search = false;
        nonnumeric_search = false;
        align = "Left";
      }
      {
        kind = "UsageCpu";
        style = "ByPercentage";
        numeric_search = false;
        nonnumeric_search = false;
        align = "Right";
      }
      {
        kind = "UsageMem";
        style = "ByPercentage";
        numeric_search = false;
        nonnumeric_search = false;
        align = "Right";
      }
      {
        kind = "VmSize";
        style = "ByUnit";
        numeric_search = false;
        nonnumeric_search = false;
        align = "Right";
      }
      {
        kind = "VmRss";
        style = "ByUnit";
        numeric_search = false;
        nonnumeric_search = false;
        align = "Right";
      }
      {
        kind = "TcpPort";
        style = "BrightCyan|Cyan";
        numeric_search = true;
        nonnumeric_search = false;
        align = "Left";
        max_width = 20;
      }
      {
        kind = "UdpPort";
        style = "BrightCyan|Cyan";
        numeric_search = true;
        nonnumeric_search = false;
        align = "Left";
        max_width = 20;
      }
      {
        kind = "ReadBytes";
        style = "ByUnit";
        numeric_search = false;
        nonnumeric_search = false;
        align = "Right";
      }
      {
        kind = "WriteBytes";
        style = "ByUnit";
        numeric_search = false;
        nonnumeric_search = false;
        align = "Right";
      }
      {
        kind = "Separator";
        style = "White|BrightBlack";
        numeric_search = false;
        nonnumeric_search = false;
        align = "Left";
      }
      {
        kind = "CpuTime";
        style = "BrightCyan|Cyan";
        numeric_search = false;
        nonnumeric_search = false;
        align = "Left";
      }
      {
        kind = "Command";
        style = "BrightWhite|Black";
        numeric_search = false;
        nonnumeric_search = true;
        align = "Left";
      }
    ];

    # --- Style Configuration (Dracula theme-aware) -------------------------
    style = {
      header = "BrightWhite|Black";
      unit = "Blue|Black";
      tree = "Cyan|Black";

      by_percentage = {
        color_000 = "BrightGreen|Green";       # 0% - Green
        color_025 = "Green|Green";             # 25% - Darker green
        color_050 = "BrightYellow|Yellow";     # 50% - Yellow
        color_075 = "Yellow|Yellow";           # 75% - Orange-ish
        color_100 = "BrightRed|Red";           # 100% - Red
      };

      by_state = {
        color_d = "Blue|Blue";                 # Uninterruptible sleep (disk)
        color_r = "BrightGreen|Green";         # Running
        color_s = "BrightCyan|Cyan";           # Sleeping
        color_t = "BrightYellow|Yellow";       # Stopped
        color_z = "BrightRed|Red";             # Zombie
        color_x = "BrightMagenta|Magenta";     # Dead
        color_k = "Yellow|Yellow";             # Wakekill
        color_w = "BrightBlue|Blue";           # Waking
        color_p = "BrightYellow|Yellow";       # Parked
      };

      by_unit = {
        color_k = "BrightBlue|Blue";           # Kilo
        color_m = "BrightGreen|Green";         # Mega
        color_g = "BrightYellow|Yellow";       # Giga
        color_t = "BrightRed|Red";             # Tera
        color_p = "BrightRed|Red";             # Peta
        color_x = "BrightBlue|Blue";           # Other
      };
    };

    # --- Search Configuration ----------------------------------------------
    search = {
      numeric_search = "Exact";
      nonnumeric_search = "Partial";
      logic = "And";
      case = "Smart";
    };

    # --- Display Configuration ---------------------------------------------
    display = {
      show_self = false;
      show_self_parents = false;
      show_thread = false;
      show_thread_in_tree = true;
      show_parent_in_tree = true;
      show_children_in_tree = true;
      show_header = true;
      show_footer = false;
      cut_to_terminal = true;
      cut_to_pager = false;
      cut_to_pipe = false;
      color_mode = "Auto";
      separator = "│";
      ascending = "▲";
      descending = "▼";
      tree_symbols = [ "│" "─" "┬" "├" "└" ];
      abbr_sid = true;
      theme = "Auto";
      show_kthreads = false;
    };

    # --- Sort Configuration (sort by CPU usage, high to low) ---------------
    sort = {
      column = 4;
      order = "Descending";
    };

    # --- Docker Configuration ----------------------------------------------
    docker = {
      path = "unix:///var/run/docker.sock";
    };

    # --- Pager Configuration (with horizontal scrolling) -------------------
    pager = {
      mode = "Auto";
      detect_width = true;
      use_builtin = false;
      command = "less -SR";
    };
  };
in
{
  home.packages = [ pkgs.procs ];
  xdg.configFile."procs/config.toml".source = tomlFormat.generate "procs-config" procsConfig;
}
