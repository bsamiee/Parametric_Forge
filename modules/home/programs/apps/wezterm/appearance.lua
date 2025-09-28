-- Title         : appearance.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : modules/home/programs/apps/wezterm/appearance.lua
-- ----------------------------------------------------------------------------
-- Appearance configuration with Dracula theme and proper ANSI mapping

local wezterm = require("wezterm")

local M = {}

-- Dracula Color Palette ------------------------------------------------------
local dracula = {
  background    = "#15131F",
  current_line  = "#2A2640",
  selection     = "#44475a",
  foreground    = "#F8F8F2",
  comment       = "#7A71AA",
  purple        = "#A072C6",
  cyan          = "#94F2E8",
  green         = "#50FA7B",
  yellow        = "#F1FA8C",
  orange        = "#F97359",
  red           = "#ff5555",
  magenta       = "#d82f94",
  pink          = "#E98FBE",
}

-- Font Configuration ---------------------------------------------------------
local FONT = {
  family = wezterm.font_with_fallback({
    { family = "GeistMono Nerd Font", weight = "Regular" },  -- Try with space
    { family = "GeistMono NF", weight = "Regular" },         -- Try abbreviated
    { family = "Iosevka Nerd Font", weight = "Regular" },   -- Fallback 1
    { family = "Hack Nerd Font", weight = "Regular" },      -- Fallback 2
    "Symbols Nerd Font Mono",                               -- Icon fallback
    "SF Mono",                                              -- System fallback
  }),
  size = 12,
  line_height = 0.85,
}

-- Appearance Configuration ---------------------------------------------------
function M.setup(config)
  -- Core Colors
  config.colors = {
    foreground = dracula.foreground,
    background = dracula.background,
    cursor_bg = dracula.foreground,
    cursor_fg = dracula.background,
    cursor_border = dracula.foreground,
    selection_fg = dracula.foreground,
    selection_bg = dracula.selection,

    -- ANSI Colors (0-7), These map to what tools like procs expect when using ANSI names
    ansi = {
      dracula.background,   -- 0: Black
      dracula.red,          -- 1: Red
      dracula.green,        -- 2: Green
      dracula.yellow,       -- 3: Yellow
      dracula.comment,      -- 4: Blue (using comment gray)
      dracula.magenta,      -- 5: Magenta
      dracula.cyan,         -- 6: Cyan
      dracula.foreground,   -- 7: White
    },

    -- Bright ANSI Colors (8-15), these map to "Bright" variants in tools (BrightGreen, BrightCyan, etc.)
    brights = {
      dracula.selection,    -- 8: Bright Black
      dracula.red,          -- 9: Bright Red (same as regular)
      dracula.green,        -- 10: Bright Green (same as regular)
      dracula.yellow,       -- 11: Bright Yellow (same as regular)
      dracula.cyan,         -- 12: Bright Blue (mapped to cyan for consistency)
      dracula.magenta,      -- 13: Bright Magenta (same as regular)
      dracula.cyan,         -- 14: Bright Cyan (same as regular)
      dracula.foreground,   -- 15: Bright White
    },

    -- Tab Bar
    tab_bar = {
      background = dracula.background,  -- Use same as main background
      active_tab = {
        bg_color = dracula.cyan,
        fg_color = dracula.background,
      },
      inactive_tab = {
        bg_color = dracula.current_line,
        fg_color = dracula.comment,
      },
      inactive_tab_hover = {
        bg_color = dracula.selection,
        fg_color = dracula.foreground,
      },
      new_tab = {
        bg_color = dracula.current_line,
        fg_color = dracula.pink,
      },
      new_tab_hover = {
        bg_color = dracula.pink,
        fg_color = dracula.background,
      },
    },
  }

  -- Font Configuration
  config.font = FONT.family
  config.font_size = FONT.size
  config.line_height = FONT.line_height

  -- Window Appearance
  config.window_background_opacity = 1.0
  config.macos_window_background_blur = 20
  config.window_decorations = "RESIZE"
  config.window_padding = {
    left = 15,
    right = 15,
    top = 5,
    bottom = 5
  }
  config.initial_cols = 120
  config.initial_rows = 34

  -- Cursor
  config.default_cursor_style = "BlinkingBar"
  config.cursor_thickness = 2
  config.cursor_blink_rate = 250
  config.force_reverse_video_cursor = true

  -- Tab Bar Style
  config.use_fancy_tab_bar = false
  config.show_tabs_in_tab_bar = true
  config.tab_max_width = 240
  config.hide_tab_bar_if_only_one_tab = false

  -- Inactive Pane Dimming
  config.inactive_pane_hsb = {
    saturation = 0.75,
    brightness = 0.75
  }

  -- Return values for future modules to use
  return {
    colors = dracula,
    font = FONT,
  }
end

return M
