-- Title         : appearance.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/wezterm/appearance.lua
-- ----------------------------------------------------------------------------
-- Appearance configuration including colors, themes, fonts, and cursor

local wezterm = require("wezterm")

local M = {}

-- Appearance Constants ────────────────────────────────────────────────────
local APPEARANCE = {
    color_scheme = "Dracula (base16)",
    background_opacity = 1.00,
    blur_radius = 20,
    inactive_pane = { saturation = 0.75, brightness = 0.8 },
}

-- Font Configuration ───────────────────────────────────────────────────────
-- Note: All fonts listed below are available via Nix packages in darwin/modules/fonts.nix
local FONT = {
    family = wezterm.font_with_fallback({
        { family = "GeistMono Nerd Font", weight = "Regular" }, -- Primary: Correct name from font-patcher
        { family = "Iosevka Nerd Font", weight = "Regular" }, -- Fallback mono
        "Symbols Nerd Font Mono", -- Icon fallback: prefer Mono variant
        "Symbols Nerd Font", -- Secondary fallback
    }),
    size = 12,
    line_height = 0.85,
}

function M.setup(config)
    -- Appearance ───────────────────────────────────────────────────────────────
    config.color_scheme = APPEARANCE.color_scheme
    config.window_background_opacity = APPEARANCE.background_opacity
    config.macos_window_background_blur = APPEARANCE.blur_radius
    config.inactive_pane_hsb = APPEARANCE.inactive_pane

    local palette = wezterm.color.get_builtin_schemes()[APPEARANCE.color_scheme]

    local colors = {
        bg = palette.background, -- #282a36
        fg = palette.foreground, -- #f8f8f2
        red = "#ff5555",
        green = "#50fa7b",
        yellow = "#f1fa8c",
        blue = "#6272a4",
        cyan = "#8be9fd",
        purple = "#bd93f9",
        orange = "#ffb86c",
        pink = "#ff79c6",
    }

    -- Fonts & Cursor ───────────────────────────────────────────────────────────
    config.font = FONT.family
    config.font_size = FONT.size
    config.line_height = FONT.line_height

    config.force_reverse_video_cursor = true
    config.default_cursor_style = "BlinkingBar"
    config.cursor_thickness = 2
    config.cursor_blink_rate = 250

    -- Frame ────────────────────────────────────────────────────────────────────
    config.window_decorations = "RESIZE"
    config.window_padding = { left = 15, right = 15, top = 5, bottom = 5 }

    config.initial_cols = 120
    config.initial_rows = 34

    -- Tab‑bar ──────────────────────────────────────────────────────────────────
    local invisible = "rgba(0,0,0,0)"
    local window_bg = "rgba(40, 42, 54, 0.75)"

    config.use_fancy_tab_bar = false
    config.show_tabs_in_tab_bar = true
    config.tab_max_width = 120

    config.window_frame = {
        active_titlebar_bg = invisible,
        inactive_titlebar_bg = invisible,
    }

    config.colors = {
        tab_bar = {
            background = window_bg,
            inactive_tab_edge = invisible,
            active_tab = { bg_color = colors.cyan, fg_color = "#282a36" }, --- Explicit fg for editors contrast
            inactive_tab = { bg_color = window_bg, fg_color = colors.fg },
            inactive_tab_hover = { bg_color = colors.blue, fg_color = colors.fg },
            new_tab = { bg_color = window_bg, fg_color = colors.pink },
            new_tab_hover = { bg_color = colors.pink, fg_color = colors.fg },
        },
    }

    --- Host-specific colors
    local host_bg = {
        prod = colors.red,
        staging = colors.yellow,
        dev = colors.green,
    }

    return colors, FONT, invisible, window_bg, host_bg
end

return M
