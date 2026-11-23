local wezterm = require("wezterm")
local deck = require("deck")
local rows = require("rows")

local M = {}

-- Zellij attention → Notification Center while WezTerm is not the focused window.
-- Workspace names are Zellij session names; `seen` asks never ping.
local KINDS = { Question = "question", Permission = "permission", Auth = "login" }
local SOURCES = { Bell = "bell", Notification = "notice", Watch = "watch" }
local pinged, landing, polling = {}, {}, false

local function zellij(session, ...)
    return wezterm.run_child_process({ rows.paths.zellij, "--session", session, "action", ... })
end

local function asks(session)
    local ok, out = zellij(session, "list-panes", "--json")
    if not ok then
        return {}
    end
    local found = {}
    for _, pane in ipairs(wezterm.serde.json_decode(out)) do
        local a = pane.attention
        if not pane.is_plugin and a and a.status == "NeedsYou" and not a.muted then
            found[pane.id] = { pane = pane, attention = a }
        end
    end
    return found
end

local function ping(window)
    local session = window:active_workspace()
    local seen = pinged[session] or {}
    local now = {}
    for id, ask in pairs(asks(session)) do
        local a = ask.attention
        if seen[id] or not a.seen then
            now[id] = true
        end
        if not seen[id] and not a.seen then
            local kind = KINDS[a.detail and a.detail.kind] or SOURCES[a.source] or "input"
            window:toast_notification(
                string.format("%s · %s", kind, ask.pane.title),
                string.format("tab %d · %s", ask.pane.tab_position + 1, a.text ~= "" and a.text or session)
            )
            landing[session] = landing[session] or id
        end
    end
    pinged[session] = now
end

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

    ["update-status"] = function(window)
        -- set_*_status is what re-arms the status_update_interval timer.
        window:set_right_status("")
        if polling or window:is_focused() then
            return
        end
        polling = true
        pcall(ping, window)
        polling = false
    end,

    ["window-focus-changed"] = function(window)
        local session = window:active_workspace()
        local id = landing[session]
        if window:is_focused() and id then
            landing[session] = nil
            zellij(session, "focus-pane-id", "terminal_" .. id)
        end
    end,
}

function M.apply()
    for name, handler in pairs(handlers) do
        wezterm.on(name, handler)
    end
end

return M
