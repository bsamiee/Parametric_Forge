local wezterm = require("wezterm")
local deck = require("deck")

local M = {}

local handlers = {
    ["gui-startup"] = function(cmd)
        local _, _, window = wezterm.mux.spawn_window(cmd or {})
        local gui = window:gui_window()
        if gui then
            gui:maximize()
        end
    end,

    ["format-window-title"] = function(tab, _, tabs)
        local ok, mux_window = pcall(wezterm.mux.get_window, tab.window_id)
        local workspace = ok and mux_window and mux_window:get_workspace() or wezterm.mux.get_active_workspace()
        return string.format("%s — %d/%d", workspace, tab.tab_index + 1, #tabs)
    end,

    ["augment-command-palette"] = function()
        return deck.palette
    end,
}

function M.apply()
    for name, handler in pairs(handlers) do
        wezterm.on(name, handler)
    end
end

return M
