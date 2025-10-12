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
  selection     = "#44475A",
  foreground    = "#F8F8F2",
  comment       = "#6272A4",
  purple        = "#A072C6",
  cyan          = "#94F2E8",
  green         = "#50FA7B",
  yellow        = "#F1FA8C",
  orange        = "#F97359",
  red           = "#FF5555",
  magenta       = "#d82f94",
  pink          = "#E98FBE",
}

-- Font Configuration ---------------------------------------------------------
local FONT = {
  family = wezterm.font_with_fallback({
    { family = "GeistMono Nerd Font", weight = "Regular" },   -- Primary
    { family = "Iosevka Nerd Font", weight = "Regular" },     -- Fallback 1
    { family = "Hack Nerd Font", weight = "Regular" },        -- Fallback 2
    "Symbols Nerd Font Mono",                                 -- Icon fallback
    -- Perso-Arabic font/ligature support
    "Scheherazade New",
    "Noto Naskh Arabic",
    "Noto Sans Arabic",
  }),
  size = 10,
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

    -- ANSI Colors (0-7)
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

    -- Bright ANSI Colors (8-15)
    brights = {
      dracula.selection,    -- 8: Bright Black
      dracula.red,          -- 9: Bright Red
      dracula.green,        -- 10: Bright Green
      dracula.yellow,       -- 11: Bright Yellow
      dracula.cyan,         -- 12: Bright Blue (mapped to cyan)
      dracula.magenta,      -- 13: Bright Magenta
      dracula.cyan,         -- 14: Bright Cyan
      dracula.foreground,   -- 15: Bright White
    },

  }

  -- Font Configuration
  config.font = FONT.family
  config.font_size = FONT.size
  config.line_height = FONT.line_height

  -- Fallback scaling and diagnostics
  config.use_cap_height_to_scale_fallback_fonts = true
  config.warn_about_missing_glyphs = true

  -- Window Appearance
  config.window_background_opacity = 0.85
  config.macos_window_background_blur = 20
  config.window_decorations = "RESIZE"
  config.window_padding = {
    left = 10,
    right = 10,
    top = 5,
    bottom = 10
  }
  config.initial_cols = 120
  config.initial_rows = 34

  -- Cursor
  config.default_cursor_style = "BlinkingBar"
  config.cursor_thickness = 2
  config.cursor_blink_rate = 250
  config.force_reverse_video_cursor = true

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
