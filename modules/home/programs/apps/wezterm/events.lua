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

local gated = {}

local handlers = {
    ["gui-startup"] = function(cmd)
        local spawn = cmd or {}
        local ws = wezterm.mux.get_active_workspace()
        local gate = spawn.args == nil
        if gate then
            spawn.args = deck.session_args(ws, true)
            spawn.cwd = wezterm.home_dir
        end
        local _, pane, window = wezterm.mux.spawn_window(spawn)
        local gui = window:gui_window()
        if gate then
            local size = pane:get_dimensions()
            gated[pane:pane_id()] = { cols = size.cols, rows = size.viewport_rows }
        end
        if gui then
            gui:maximize()
        end
    end,

    ["window-resized"] = function(_, pane)
        local spawned = gated[pane:pane_id()]
        local size = pane:get_dimensions()
        if spawned and (size.cols ~= spawned.cols or size.viewport_rows ~= spawned.rows) then
            gated[pane:pane_id()] = nil
            pane:send_text("\n")
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
