# Title         : bottom.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/bottom.nix
# ----------------------------------------------------------------------------
# Resource monitor themed from the estate palette owner
{config, ...}: let
  # palette retained for the categorical per-core / per-GPU rainbows — a chromatic spectrum wants stable distinct hues, not semantic roles.
  inherit (config.estate.theme) roles palette;
in {
  programs.bottom = {
    enable = true;
    # Rows differ from bottom's defaults; a key bottom does not declare is dropped without a diagnostic.
    settings = {
      # --- [GENERAL_FLAGS]
      flags = {
        rate = 2000;
        table_gap = "none";
        show_table_scroll_position = true;
        disable_gpu = true;
        retention = "5m";
        battery = true;
      };

      # --- [STYLE_CONFIGURATION]
      styles = {
        widgets = {
          # Focus pair owns the widget-frame active/inactive derivation: the selected frame reads focus.active, every other frame reads inactive.
          border_color = roles.focus.inactive.hex;
          selected_border_color = roles.focus.active.hex;
          widget_title = {
            color = roles.accent.primary.hex;
          };
          text = {
            color = roles.text.primary.hex;
          };
          # Selection rides the focus fill with inverse text.
          selected_text = {
            color = roles.text.inverse.hex;
            bg_color = roles.focus.active.hex;
          };
          disabled_text = {
            color = roles.text.muted.hex;
          };
          thread_text = {
            color = roles.accent.structural.hex;
          };
        };
        tables = {
          headers = {
            color = roles.accent.primary.hex;
            bold = true;
          };
        };
        graphs = {
          graph_color = roles.surface.selected.hex;
          legend_text = {
            color = roles.accent.primary.hex;
          };
        };
        cpu = {
          all_entry_color = roles.accent.primary.hex;
          avg_entry_color = roles.accent.tertiary.hex;
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
          ram_color = roles.state.success.hex;
          swap_color = roles.state.attention.hex;
          cache_color = roles.accent.primary.hex;
          arc_color = roles.accent.structural.hex;
          gpu_colors = [
            palette.pink.hex # GPU 0
            palette.cyan.hex # GPU 1
            palette.green.hex # GPU 2
            palette.orange.hex # GPU 3
          ];
        };
        network = {
          rx_color = roles.state.success.hex;
          tx_color = roles.accent.tertiary.hex;
          rx_total_color = roles.accent.primary.hex;
          tx_total_color = roles.state.attention.hex;
        };
        battery = {
          high_battery_color = roles.state.success.hex; # Healthy (50%+)
          medium_battery_color = roles.state.warning.hex; # Caution (10-50%) — warning role (amber)
          low_battery_color = roles.state.danger.hex; # Critical (<10%)
        };
      };
      # --- [PROCESS_CONFIGURATION]
      processes = {
        current_usage = true;
        default_grouped = true;
        default_memory_value = true;
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
      # Each filter list is a deny list, bottom's default.
      disk = {
        columns = ["Disk" "Mount" "Used%" "Free" "R/s" "W/s"];
        name_filter = {
          list = ["/dev/loop*" "devfs" "devtmpfs" "tmpfs" "overlay" "run"];
          regex = true;
        };
        mount_filter.list = ["/boot" "/boot/efi" "/var/snap" "/var/lib/docker"];
      };
      # --- [MEMORY_GRAPH_CONFIGURATION]
      memory_graph = {
        cache_memory = true;
      };
      # --- [NETWORK_GRAPH]
      network_graph = {
        use_binary_prefix = true;
        interface_filter = {
          list = ["lo" "lo0"];
          whole_word = true;
        };
      };
    };
  };
}
