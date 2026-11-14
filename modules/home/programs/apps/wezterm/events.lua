local wezterm = require("wezterm")
local rows = require("rows")
local deck = require("deck")

local M = {}

local roles = rows.theme.roles

local function cell(fg, text)
    return {
        { Attribute = { Intensity = "Bold" } },
        { Foreground = { Color = fg } },
        { Text = " " .. text .. " " },
    }
end

local handlers = {
    ["gui-startup"] = function(cmd)
        local _, _, window = wezterm.mux.spawn_window(cmd or {})
        local gui = window:gui_window()
        if gui then
            gui:maximize()
        end
    end,

    ["update-status"] = function(window)
        local items = {}
        local function push(fragments)
            for _, fragment in ipairs(fragments) do
                items[#items + 1] = fragment
            end
        end

        local key_table = window:active_key_table()
        if key_table then
            push(cell(roles.state.danger, "[" .. key_table:upper() .. "]"))
        end

        window:set_right_status(wezterm.format(items))
        window:set_left_status("")
    end,

    ["format-tab-title"] = function(tab)
        local pane = tab.active_pane
        local title = pane.title or ""
        title = title ~= "" and title or "wezterm"
        return string.format(" %d:%s ", tab.tab_index + 1, title)
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
