-- Title         : behavior.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : modules/home/programs/apps/wezterm/behavior.lua
-- ----------------------------------------------------------------------------
-- Terminal behavior, performance, and general settings

local wezterm = require("wezterm")

local M = {}

-- Single nightly predicate: every nightly-only field in any module gates on
-- this. Threshold is the pinned build date where each adopted field is
-- verified; earlier nightlies and any stable load the config warning-free.
M.has_nightly = wezterm.version:sub(1, 8) >= "20260707"

wezterm.on("gui-startup", function(cmd)
  local _, _, window = wezterm.mux.spawn_window(cmd or {})
  window:gui_window():maximize()
end)

function M.apply(config, theme)
    local palette = theme and theme.colors or {}
    local font = theme and theme.font or {}

    -- Command Palette --------------------------------------------------------
    config.command_palette_bg_color = palette.current_line or palette.background
    config.command_palette_fg_color = palette.cyan or palette.foreground
    config.command_palette_rows = 10
    config.command_palette_font_size = font.size or config.font_size or 10
    if M.has_nightly then
      config.command_palette_font = font.family
      -- Quick Select strips pane styling before matching; Dracula contrast
      -- stays legible under the overlay highlights.
      config.quick_select_remove_styling = true
    end

    -- Behaviour --------------------------------------------------------------
    config.automatically_reload_config = true
    config.native_macos_fullscreen_mode = true
    config.enable_kitty_keyboard = true
    config.switch_to_last_active_tab_when_closing_tab = true
    config.adjust_window_size_when_changing_font_size = false
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

    -- Terminal Type Configuration --------------------------------------------
    config.hyperlink_rules = wezterm.default_hyperlink_rules()
    config.window_close_confirmation = "NeverPrompt"

    -- Performance ------------------------------------------------------------
    config.front_end = "WebGpu"
    config.max_fps = 120
    config.animation_fps = 120
    config.scrollback_lines = 5000
end

return M
