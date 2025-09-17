-- Title         : mouse.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/wezterm/mouse.lua
-- ----------------------------------------------------------------------------
-- Mouse bindings and behavior configuration

local wezterm = require("wezterm")

local M = {}

function M.setup(config)
    local act = wezterm.action

    -- Mouse Configuration ──────────────────────────────────────────────────────
    config.bypass_mouse_reporting_modifiers = "SHIFT"
    config.mouse_bindings = {
        {
            event = { Up = { streak = 1, button = "Left" } },
            mods = "CMD",
            action = act.OpenLinkAtMouseCursor,
        },
        {
            event = { Down = { streak = 1, button = { WheelUp = 1 } } },
            mods = "CMD",
            action = act.IncreaseFontSize,
        },
        {
            event = { Down = { streak = 1, button = { WheelDown = 1 } } },
            mods = "CMD",
            action = act.DecreaseFontSize,
        },
        {
            event = { Down = { streak = 1, button = { WheelUp = 1 } } },
            mods = "NONE",
            action = act.ScrollByLine(-3),
        },
        {
            event = { Down = { streak = 1, button = "Middle" } },
            mods = "NONE",
            action = act.PasteFrom("PrimarySelection"),
        },
        {
            event = { Up = { streak = 1, button = "Right" } },
            mods = "NONE",
            action = act.CopyTo("ClipboardAndPrimarySelection"),
        },
        {
            event = { Down = { streak = 3, button = "Left" } },
            mods = "NONE",
            action = act.SelectTextAtMouseCursor("Line"),
        },
        {
            event = { Down = { streak = 2, button = "Left" } },
            mods = "NONE",
            action = act.SelectTextAtMouseCursor("Word"),
        },
    }
end

return M
