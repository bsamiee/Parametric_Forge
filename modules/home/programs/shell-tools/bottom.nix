# Title         : bottom.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/bottom.nix
# ----------------------------------------------------------------------------
# Resource monitor themed from the estate palette owner
{config, ...}: let
  inherit (config.forge.theme) palette;
in {
  programs.bottom = {
    enable = true;
    settings = {
      # --- General Flags ----------------------------------------------------
      flags = {
        # Display Performance
        temperature_type = "c"; # Celsius for temperature
        rate = 2000; # Update rate in milliseconds (2 seconds - balanced)
        table_gap = "none"; # Cleaner look without table header gaps
        disable_click = false; # Enable mouse support
        show_table_scroll_position = true; # Show scroll position indicator
        disable_gpu = true; # Disable GPU collection (enable if needed)

        # Data & Performance
        retention = "5m"; # 5 minutes (balanced memory usage)
        time_delta = 15000; # 15 second time delta in graphs

        # Initial View
        default_widget_type = "process"; # Start with process view
        default_widget_count = 1; # Single focused widget
        expanded = false; # Compact view initially
        basic = false; # Full mode for power users
        use_old_network_legend = false; # Modern network legend
        battery = true; # Show battery if available
      };

      # --- Style Configuration ----------------------------------------------
      styles = {
        widgets = {
          border_color = palette.cyan.hex; # Default borders
          selected_border_color = palette.magenta.hex; # Focused widget
          widget_title = {
            color = palette.cyan.hex; # Consistent with borders
          };
          table_header = {
            color = palette.cyan.hex;
            bold = true; # Bold for emphasis
          };
          text = {
            color = palette.foreground.hex; # Primary text
          };
          selected_text = {
            color = palette.background.hex; # Inverse text when selected
            bg_color = palette.cyan.hex; # Selection background
          };
          disabled_text = {
            color = palette.comment.hex; # Muted - inactive items
          };
          thread_text = {
            color = palette.purple.hex; # Thread indicators
            bold = false; # Not bold for subtlety
          };
        };
        tables = {
          headers = {
            color = palette.cyan.hex; # Matches borders
            bold = true; # Bold for emphasis
          };
        };
        graphs = {
          graph_color = palette.selection.hex; # Subtle grid lines
          legend_text = {
            color = palette.cyan.hex; # Legend text (for inline tables)
            bold = false; # Not bold for cleaner look
          };
        };
        cpu = {
          all_entry_color = palette.cyan.hex; # ALL CPU label
          avg_entry_color = palette.pink.hex; # AVG CPU (important metric)
          cpu_core_colors = [
            palette.green.hex # Core 0
            palette.cyan.hex # Core 1
            palette.yellow.hex # Core 2
            palette.orange.hex # Core 3
            palette.pink.hex # Core 4
            palette.purple.hex # Core 5
            palette.red.hex # Core 6
            palette.magenta.hex # Core 7+
          ];
        };
        memory = {
          ram = palette.green.hex; # RAM (primary memory)
          swap = palette.orange.hex; # Swap (warning state)
          cache = palette.cyan.hex; # Cache (secondary)
          arc = palette.purple.hex; # ARC cache
          gpu_colors = [
            # GPU memory colors
            palette.pink.hex # GPU 0
            palette.cyan.hex # GPU 1
            palette.green.hex # GPU 2
            palette.orange.hex # GPU 3
          ];
        };
        network = {
          rx = palette.green.hex; # Download (incoming)
          tx = palette.pink.hex; # Upload (outgoing)
          rx_total = palette.cyan.hex; # Total received
          tx_total = palette.orange.hex; # Total transmitted
        };
        battery = {
          high_battery = palette.green.hex; # Healthy (50%+)
          medium_battery = palette.yellow.hex; # Caution (10-50%)
          low_battery = palette.red.hex; # Critical (<10%)
        };
      };
      # --- Process Configuration --------------------------------------------
      processes = {
        current_usage = true; # Show current usage in process widget
        default_grouped = true; # Group processes with same name for clarity
        default_tree = false; # Start with flat view (toggle with 't')
        default_memory_value = true; # Show memory as values, not just %
        case_sensitive = false; # Case-insensitive process search
        whole_word = false; # Partial word matching in search
        regex = false; # Simple search by default
        process_command = false; # Show process name for clarity
        disable_advanced_kill = false; # Enable advanced kill options
        columns = [
          "PID"
          "Name"
          "CPU%"
          "Mem%"
          "User"
          "State"
        ];
      };
      # --- Disk Configuration -----------------------------------------------
      disk = {
        columns = ["Disk" "Mount" "Used%" "Free" "R/s" "W/s"];
        name_filter = {
          is_list_ignored = true;
          list = ["/dev/loop*" "devfs" "devtmpfs" "tmpfs" "overlay" "run"];
          regex = true;
          case_sensitive = false;
          whole_word = false;
        };
        mount_filter = {
          is_list_ignored = true;
          list = ["/boot" "/boot/efi" "/var/snap" "/var/lib/docker"];
          regex = false;
          case_sensitive = false;
          whole_word = false;
        };
      };
      # --- Temperature Configuration ----------------------------------------
      # Note: macOS temperature sensors may not be accessible to bottom
      temperature = {
        sensor_filter = {
          is_list_ignored = true; # Ignore items in list (show everything else)
          list = []; # No sensors to ignore
          regex = false;
          case_sensitive = false;
          whole_word = false;
        };
      };
      # --- Memory Graph Configuration ---------------------------------------
      memory_graph = {
        cache_memory = true; # Show cache for complete memory picture
      };
      # --- Network Filter ---------------------------------------------------
      network_graph = {
        use_binary_prefix = true; # Use MiB/s (more accurate)
        use_bytes = false; # Use bits for network
        use_log = false; # Linear scale is more intuitive
        interface_filter = {
          is_list_ignored = true;
          list = ["lo" "lo0"]; # Ignore loopback interfaces
          regex = false;
          case_sensitive = false;
          whole_word = true;
        };
      };
      # --- CPU Configuration ------------------------------------------------
      cpu = {
        default = "all"; # Show all cores
        hide_avg_cpu = false; # Show average CPU in addition to per-core
        left_legend = false; # Legend on right side for better readability
      };
    };
  };
}
