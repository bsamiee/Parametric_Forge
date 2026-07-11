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
      # --- [GENERAL_FLAGS]
      flags = {
        # Display Performance
        temperature_type = "c";
        rate = 2000;
        table_gap = "none";
        disable_click = false;
        show_table_scroll_position = true;
        disable_gpu = true;

        # Data & Performance
        retention = "5m";
        time_delta = 15000;

        # Initial View
        default_widget_type = "process";
        default_widget_count = 1;
        expanded = false;
        basic = false;
        use_old_network_legend = false;
        battery = true;
      };

      # --- [STYLE_CONFIGURATION]
      styles = {
        widgets = {
          border_color = palette.cyan.hex;
          selected_border_color = palette.magenta.hex;
          widget_title = {
            color = palette.cyan.hex;
          };
          table_header = {
            color = palette.cyan.hex;
            bold = true;
          };
          text = {
            color = palette.foreground.hex;
          };
          selected_text = {
            color = palette.background.hex;
            bg_color = palette.cyan.hex;
          };
          disabled_text = {
            color = palette.comment.hex;
          };
          thread_text = {
            color = palette.purple.hex;
            bold = false;
          };
        };
        tables = {
          headers = {
            color = palette.cyan.hex;
            bold = true;
          };
        };
        graphs = {
          graph_color = palette.selection.hex;
          legend_text = {
            color = palette.cyan.hex;
            bold = false;
          };
        };
        cpu = {
          all_entry_color = palette.cyan.hex;
          avg_entry_color = palette.pink.hex;
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
          ram = palette.green.hex;
          swap = palette.orange.hex;
          cache = palette.cyan.hex;
          arc = palette.purple.hex;
          gpu_colors = [
            palette.pink.hex # GPU 0
            palette.cyan.hex # GPU 1
            palette.green.hex # GPU 2
            palette.orange.hex # GPU 3
          ];
        };
        network = {
          rx = palette.green.hex;
          tx = palette.pink.hex;
          rx_total = palette.cyan.hex;
          tx_total = palette.orange.hex;
        };
        battery = {
          high_battery = palette.green.hex; # Healthy (50%+)
          medium_battery = palette.yellow.hex; # Caution (10-50%)
          low_battery = palette.red.hex; # Critical (<10%)
        };
      };
      # --- [PROCESS_CONFIGURATION]
      processes = {
        current_usage = true;
        default_grouped = true;
        default_tree = false;
        default_memory_value = true;
        case_sensitive = false;
        whole_word = false;
        regex = false;
        process_command = false;
        disable_advanced_kill = false;
        columns = [
          "PID"
          "Name"
          "CPU%"
          "Mem%"
          "User"
          "State"
        ];
      };
      # --- [DISK_CONFIGURATION]
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
      # --- [TEMPERATURE_CONFIGURATION]
      # macOS withholds temperature sensors from bottom.
      temperature = {
        sensor_filter = {
          is_list_ignored = true;
          list = [];
          regex = false;
          case_sensitive = false;
          whole_word = false;
        };
      };
      # --- [MEMORY_GRAPH_CONFIGURATION]
      memory_graph = {
        cache_memory = true;
      };
      # --- [NETWORK_GRAPH]
      network_graph = {
        use_binary_prefix = true;
        use_bytes = false;
        use_log = false;
        interface_filter = {
          is_list_ignored = true;
          list = ["lo" "lo0"];
          regex = false;
          case_sensitive = false;
          whole_word = true;
        };
      };
      # --- [CPU_CONFIGURATION]
      cpu = {
        default = "all";
        hide_avg_cpu = false;
        left_legend = false;
      };
    };
  };
}
