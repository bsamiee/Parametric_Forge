-- Title         : behavior.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/wezterm/behavior.lua
-- ----------------------------------------------------------------------------
-- Terminal behavior, performance, and general settings

local wezterm = require("wezterm")

local M = {}

function M.setup(config, colors, FONT)
    -- Command Palette ──────────────────────────────────────────────────────────
    config.command_palette_bg_color = colors.bg
    config.command_palette_fg_color = colors.cyan
    config.command_palette_rows = 10
    config.command_palette_font_size = FONT.size

    -- Behaviour ────────────────────────────────────────────────────────────────
    config.default_prog = { "/bin/zsh", "-l" }
    config.automatically_reload_config = true
    config.native_macos_fullscreen_mode = true
    config.enable_kitty_keyboard = true
    config.switch_to_last_active_tab_when_closing_tab = true
    config.hide_mouse_cursor_when_typing = true
    config.adjust_window_size_when_changing_font_size = false

    -- Terminal Type Configuration ───────────────────────────────────────────────
    -- Use default TERM (xterm-256color) - Yazi detects WezTerm via TERM_PROGRAM

    config.hyperlink_rules = wezterm.default_hyperlink_rules()
    config.window_close_confirmation = "NeverPrompt"
    config.freetype_load_target = "Normal"
    config.freetype_render_target = "Normal"
    config.audible_bell = "Disabled"
    config.visual_bell = {
        fade_in_function = "EaseIn",
        fade_in_duration_ms = 150,
        fade_out_function = "EaseOut",
        fade_out_duration_ms = 150,
        target = "BackgroundColor",
    }

    -- Set default workspace
    config.default_workspace = "default"
    config.skip_close_confirmation_for_processes_named = {
        "bash",
        "sh",
        "zsh",
        "fish",
        "tmux",
        "nu",
        "cmd.exe",
        "pwsh.exe",
        "powershell.exe",
    }

    -- Performance ──────────────────────────────────────────────────────────────
    config.front_end = "WebGpu"
    -- config.front_end = "OpenGL"
    config.max_fps = 120
    config.animation_fps = 120
    config.scrollback_lines = 5000
end

return M
