# Title         : pik.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/pik.nix
# ----------------------------------------------------------------------------
# Process Interactive Kill - fuzzy process finder and killer

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
  home.packages = [ pkgs.pik ];

  home.file."Library/Application Support/pik/config.toml".text = ''
    screen_size = "fullscreen"

    [search]
    case_sensitive = false
    whole_word = false

    [ignore]
    threads = true
    other_users = false
    paths = [
      "^/System/.*",                        # macOS system processes
      "^/usr/libexec/.*",                   # System helpers
      "^/nix/store/.*/systemd.*",           # Systemd services
      ".*kworker.*",                        # Kernel workers
      ".*ksoftirqd.*"                       # Kernel soft IRQ
    ]

    [ui]
    icons = "nerd_font_v3"

    [ui.process_table]
    title = { alignment = "center", position = "top" }

    [ui.process_table.border]
    type = "rounded"

    [ui.process_table.border.style]
    fg = "#94F2E8"

    [ui.process_table.row]
    selected_symbol = "▶"
    even = { fg = "#F8F8F2" }                             # Normal foreground
    odd = { fg = "#F8F8F2", bg = "#2A2640" }            # Subtle background for zebra striping
    selected = { fg = "#15131F", bg = "#94F2E8", add_modifier = "BOLD" }  # Selection without BOLD

    [ui.process_table.cell]
    highlighted = { fg = "#50FA7B", bg = "#15131F" }    # Green for search matches

    [ui.process_table.scrollbar]
    track_symbol = "│"
    thumb_symbol = "█"
    begin_symbol = "▲"
    end_symbol = "▼"
    margin = { horizontal = 0, vertical = 1 }

    [ui.process_details]
    title = { alignment = "center", position = "top" }

    [ui.process_details.border]
    type = "rounded"

    [ui.process_details.border.style]
    fg = "#d82f94"

    [ui.process_details.scrollbar]
    track_symbol = "│"
    thumb_symbol = "█"
    begin_symbol = "▲"
    end_symbol = "▼"
    margin = { horizontal = 0, vertical = 1 }

    [ui.search_bar]
    cursor_style = { fg = "#F8F8F2", bg = "#d82f94", add_modifier = "REVERSED" }

    [ui.popups]
    selected_row = { fg = "#44475A", bg = "#94F2E8" }
    primary = { fg = "#94F2E8" }

    [ui.popups.border]
    type = "rounded"

    [ui.popups.border.style]
    fg = "#F97359"
  '';
}
