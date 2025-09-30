# Title         : bottom.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/shell-tools/bottom.nix
# ----------------------------------------------------------------------------
# Resource monitor with Dracula theme using native home-manager module

{ config, lib, pkgs, ... }:

{
  programs.bottom = {
    enable = true;
    settings = {
      # --- General Flags -------------------------------------------------------
      flags = {
        # Display Performance
        avg_cpu = true;              # Show average CPU in addition to per-core
        temperature_type = "c";      # Celsius for temperature
        rate = 2000;                 # Update rate in milliseconds (2 seconds - balanced)
        left_legend = false;         # Legend on right side for better readability
        current_usage = true;        # Show current usage in process widget
        group_processes = true;      # Group processes with same name for clarity
        tree = false;                # Start with flat view (toggle with 't')
        hide_table_gap = true;       # Cleaner look without gaps
        disable_click = false;       # Enable mouse support
        enable_cache_memory = true;  # Show cache for complete memory picture
        enable_gpu = false;          # Disable GPU (enable if needed)
        mem_as_value = true;         # Show memory as values, not just %

        # Search & Filter
        case_sensitive = false;            # Case-insensitive process search
        whole_word = false;                # Partial word matching in search
        regex = false;                     # Simple search by default
        show_table_scroll_position = true; # Show scroll position indicator
        process_command = false;           # Show process name for clarity
        disable_advanced_kill = false;     # Enable advanced kill options

        # Network Display
        network_use_binary_prefix = true;  # Use MiB/s (more accurate)
        network_use_bytes = false;         # Use bits for network
        network_use_log = false;           # Linear scale is more intuitive

        # Data & Performance
        retention = "5m";                  # 5 minutes (balanced memory usage)
        time_delta = 15000;                # 15 second time delta in graphs

        # Initial View
        default_widget_type = "process";  # Start with process view
        default_widget_count = 1;         # Single focused widget
        expanded = false;                 # Compact view initially
        basic = false;                    # Full mode for power users
        use_old_network_legend = false;   # Modern network legend
        hide_table_count = false;         # Show row counts for context
        battery = true;                   # Show battery if available
      };

      # Dracula theme color reference
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

      # --- Style Configuration (Professional Dracula) ------------------------
      styles = {
        widgets = {
          border_color = "#94F2E8";             # Cyan - default borders
          selected_border_color = "#d82f94";    # Magenta - focused widget
          widget_title = {
            color = "#94F2E8";                  # Cyan - consistent with borders
          };
          table_header = {
            color = "#94F2E8";                  # Cyan headers
            bold = true;                          # Bold for emphasis
          };
          text = {
            color = "#F8F8F2";                  # Bright - primary text
          };
          selected_text = {
            color = "#F8F8F2";                  # Bright text when selected
            bg_color = "#44475a";               # Selection background
          };
          disabled_text = {
            color = "#7A71AA";                  # Muted - inactive items
          };
          thread_text = {
            color = "#A072C6";                  # Purple - thread indicators
            bold = false;                         # Not bold for subtlety
          };
        };
        tables = {
          headers = {
            color = "#94F2E8";                  # Cyan headers (matches borders)
            bold = true;                          # Bold for emphasis
          };
        };
        graphs = {
          graph_color = "#44475a";              # Subtle grid lines
          legend_text = {
            color = "#94F2E8";                  # Cyan legend text (for inline tables)
            bold = false;                         # Not bold for cleaner look
          };
        };
        cpu = {
          all_entry_color = "#94F2E8";          # Cyan - ALL CPU label
          avg_entry_color = "#E98FBE";          # Pink - AVG CPU (important metric)
          cpu_core_colors = [
            "#50FA7B"  # Green - Core 0
            "#94F2E8"  # Cyan - Core 1
            "#F1FA8C"  # Yellow - Core 2
            "#F97359"  # Orange - Core 3
            "#E98FBE"  # Pink - Core 4
            "#A072C6"  # Purple - Core 5
            "#ff5555"  # Red - Core 6
            "#d82f94"  # Magenta - Core 7+
          ];
        };
        memory = {
          ram = "#50FA7B";          # Green - RAM (primary memory)
          swap = "#F97359";         # Orange - swap (warning state)
          cache = "#94F2E8";        # Cyan - cache (secondary)
          arc = "#A072C6";          # Purple - ARC cache
          gpu_colors = [              # GPU memory colors
            "#E98FBE"               # Pink - GPU 0
            "#94F2E8"               # Cyan - GPU 1
            "#50FA7B"               # Green - GPU 2
            "#F97359"               # Orange - GPU 3
          ];
        };
        network = {
          rx = "#50FA7B";             # Green - download (incoming)
          tx = "#E98FBE";             # Pink - upload (outgoing)
          rx_total = "#94F2E8";       # Cyan - total received
          tx_total = "#F97359";       # Orange - total transmitted
        };
        battery = {
          high_battery = "#50FA7B";   # Green - healthy (50%+)
          medium_battery = "#F1FA8C"; # Yellow - caution (10-50%)
          low_battery = "#ff5555";    # Red - critical (<10%)
        };
      };
      # --- Process Configuration -----------------------------------------------
      processes = {
        columns = [
          "PID"
          "Name"
          "CPU%"
          "Mem%"
          "User"
          "State"
        ];
      };
      # --- Disk Configuration --------------------------------------------------
      disk = {
        columns = [ "Disk" "Mount" "Used%" "Free" "R/s" "W/s" ];
        name_filter = {
          is_list_ignored = true;
          list = [ "/dev/loop*" "devfs" "devtmpfs" "tmpfs" "overlay" "run" ];
          regex = true;
          case_sensitive = false;
          whole_word = false;
        };
        mount_filter = {
          is_list_ignored = true;
          list = [ "/boot" "/boot/efi" "/var/snap" "/var/lib/docker" ];
          regex = false;
          case_sensitive = false;
          whole_word = false;
        };
      };
      # --- Temperature Configuration -------------------------------------------
      # Note: macOS temperature sensors may not be accessible to bottom
      temperature = {
        sensor_filter = {
          is_list_ignored = true;   # Ignore items in list (show everything else)
          list = [];                # No sensors to ignore
          regex = false;
          case_sensitive = false;
          whole_word = false;
        };
      };
      # --- Network Filter ------------------------------------------------------
      network = {
        interface_filter = {
          is_list_ignored = true;
          list = [ "lo" "lo0" ];   # Ignore loopback interfaces
          regex = false;
          case_sensitive = false;
          whole_word = true;
        };
      };
      # --- CPU Configuration ---------------------------------------------------
      cpu = {
        default = "all"; # Show all cores
      };
    };
  };
}
