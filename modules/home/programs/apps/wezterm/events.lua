-- Title         : events.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : modules/home/programs/apps/wezterm/events.lua
-- ----------------------------------------------------------------------------
-- Event plane: one handler row per event, registered in a single fold. Status reads cheap pane/window state only; every probe writes elsewhere.
-- Bodies read deck state at fire time, so registration never races the deck build.

local wezterm = require("wezterm")
local rows = require("rows")
local deck = require("deck")

local M = {}

local roles = rows.theme.roles

local function cell(fg, text)
    return {
        { Foreground = { Color = fg } },
        { Text = " " .. text .. " " },
    }
end

local handlers = {
    -- Session persistence is code-defined: GUI and auto-spawned mux servers land the default workspace's slug session at its name-policy cwd; an
    -- explicit `wezterm start -- prog` keeps its own args untouched.
    ["gui-startup"] = function(cmd)
        local spawn = cmd or {}
        local ws = wezterm.mux.get_active_workspace()
        spawn.cwd = spawn.cwd or deck.workspace_cwd(ws)
        spawn.args = spawn.args or deck.session_args(ws)
        local _, _, window = wezterm.mux.spawn_window(spawn)
        local gui = window:gui_window()
        if gui then
            gui:maximize()
        end
    end,

    ["mux-startup"] = function()
        local ws = wezterm.mux.get_active_workspace()
        wezterm.mux.spawn_window({ cwd = deck.workspace_cwd(ws), args = deck.session_args(ws) })
    end,

    -- Domain attach shaping: one launch receipt per attach.
    ["gui-attached"] = function(domain)
        deck.receipt({ action = "attach", domain = domain:name(), result = "ok" })
    end,

    -- Bell rings are structured attention: a receipt row always; a toast plus an attention-feed row only when the ring lands outside the focused
    -- view (background pane or unfocused window) — a watched pane's bell is already seen. audible_bell is Disabled; this arm is the surface. The
    -- feed row makes any process ending with \a a first-class attention emitter: the collector folds it,
    -- the bar counts it, `forge-agents focus` routes it.
    ["bell"] = function(window, pane)
        local background = not window:is_focused() or pane:pane_id() ~= window:active_pane():pane_id()
        if background then
            window:toast_notification("forge bell", "bell: " .. pane:get_title(), nil, 4000)
            local cwd = pane:get_current_working_dir()
            deck.attention({
                wezterm_pane = tostring(pane:pane_id()),
                cwd = cwd and cwd.file_path or "-",
            })
        end
        deck.receipt({
            action = "bell",
            pane_id = pane:pane_id(),
            domain = pane:get_domain_name(),
            background = background,
            result = "ok",
        })
    end,

    -- Outer facts only: key table, sync state, non-local domain. Agent/quota cells and location live on the zellij zjstatus bar — the one top
    -- bar; this strip surfaces only when a second WezTerm tab raises the tab bar.
    ["update-status"] = function(window, pane)
        local items = {}
        local function push(fragments)
            for _, fragment in ipairs(fragments) do
                items[#items + 1] = fragment
            end
        end

        local key_table = window:active_key_table()
        if key_table then
            push(cell(roles.state.attention, "[" .. key_table:upper() .. "]"))
        end
        if deck.sync and deck.sync.is_synced(window) then
            push(cell(roles.state.danger, "[SYNC]"))
        end

        local domain = pane and pane:get_domain_name() or "local"
        if domain ~= "local" then
            push(cell(roles.state.info, domain))
        end

        window:set_right_status(wezterm.format(items))
        window:set_left_status("")
    end,

    ["format-tab-title"] = function(tab)
        local pane = tab.active_pane
        local proc = (pane.foreground_process_name or ""):gsub(".*/", "")
        local title = proc ~= "" and proc or pane.title
        return string.format(" %d:%s ", tab.tab_index + 1, title)
    end,

    ["format-window-title"] = function(tab, _, tabs)
        -- Per-window truth: a window parked in a background workspace titles as its own workspace, never the globally active one.
        local ok, mux_window = pcall(wezterm.mux.get_window, tab.window_id)
        local workspace = ok and mux_window and mux_window:get_workspace() or wezterm.mux.get_active_workspace()
        return string.format("%s — %d/%d", workspace, tab.tab_index + 1, #tabs)
    end,

    -- Command deck rows land in the native palette without replacing it; the deck builds the entry table once per generation and this replays it.
    ["augment-command-palette"] = function()
        return deck.palette
    end,

    -- forge://<register-domain>[/...] opens the register browser float scoped to the domain (forge-browse takes one DOMAIN argument).
    ["open-uri"] = function(_, _, uri)
        local domain = uri:match("^forge://([%w-]+)")
        local browse = domain and deck.commands["browse-registers"]
        if not browse then
            return
        end
        deck.spawn_float({ id = browse.id, float = browse.float, args = { browse.args[1], domain } })
        return false
    end,
}

function M.apply(config) -- luacheck: no unused args
    for name, handler in pairs(handlers) do
        wezterm.on(name, handler)
    end
end

return M
