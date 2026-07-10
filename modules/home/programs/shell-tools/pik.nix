# Title         : pik.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/pik.nix
# ----------------------------------------------------------------------------
# Process Interactive Kill - fuzzy process finder and killer
{
  config,
  pkgs,
  ...
}: let
  inherit (config.forge.theme) palette;
in {
  home.packages = [pkgs.pik];

  home.file."Library/Application Support/pik/config.toml".text = ''
    screen_size = "fullscreen"

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
    fg = "${palette.cyan.hex}"

    [ui.process_table.row]
    selected_symbol = "▶"
    even = { fg = "${palette.foreground.hex}" } # Normal foreground
    odd = { fg = "${palette.foreground.hex}", bg = "${palette.current_line.hex}" } # Subtle background for zebra striping
    selected = { fg = "${palette.background.hex}", bg = "${palette.cyan.hex}", add_modifier = "BOLD" }

    [ui.process_table.cell]
    highlighted = { fg = "${palette.green.hex}", bg = "${palette.background.hex}" } # Green for search matches

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
    fg = "${palette.magenta.hex}"

    [ui.process_details.scrollbar]
    track_symbol = "│"
    thumb_symbol = "█"
    begin_symbol = "▲"
    end_symbol = "▼"
    margin = { horizontal = 0, vertical = 1 }

    [ui.search_bar]
    cursor_style = { fg = "${palette.foreground.hex}", bg = "${palette.magenta.hex}", add_modifier = "REVERSED" }

    [ui.popups]
    selected_row = { fg = "${palette.selection.hex}", bg = "${palette.cyan.hex}" }
    primary = { fg = "${palette.cyan.hex}" }

    [ui.popups.border]
    type = "rounded"

    [ui.popups.border.style]
    fg = "${palette.orange.hex}"
  '';
}
