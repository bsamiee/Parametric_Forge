-- Title         : core.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/forge/core.lua
-- ----------------------------------------------------------------------------
-- Consolidated core infrastructure: state, config, and bus modules

-- --- state module (from state.lua) ---------------------------------------------
-- Shared in-memory state and coalescing buckets for operations

local state = {}

state.windows = {} -- cache by win:id() -> { app, title, role, subrole, lastOps = {}, ts = number }
state.spaces = {} -- cache by spaceId -> { lastNormalizedAt = 0 }
state.pending = { -- coalesced operations
    window = {}, -- winId -> { ops = {}, timer = hs.timer }
    space = {}, -- spaceId -> { ops = {}, timer = hs.timer }
}

state.scratch = { -- label -> winId
}

function state.reset()
    state.windows, state.spaces, state.pending, state.scratch = {}, {}, { window = {}, space = {} }, {}
end

function state.windowEntry(winId)
    local e = state.windows[winId]
    if not e then
        e = { lastOps = {}, ts = hs.timer.absoluteTime() }
        state.windows[winId] = e
    end
    return e
end

function state.spaceEntry(spaceId)
    local e = state.spaces[spaceId]
    if not e then
        e = { lastNormalizedAt = 0 }
        state.spaces[spaceId] = e
    end
    return e
end

-- --- config module (from config.lua) -------------------------------------------
-- Config and policy definitions for Hammerspoon policy engine

local config = {}

-- Debounce windows/spaces/display updates (milliseconds)
config.debounce = {
    window = 80,
    space = 120,
    screen = 150,
    state = 120,
}

-- Float policy thresholds
config.floatThreshold = { minW = 400, minH = 260 }

-- Grid anchors via external script (avoid duplicating grids)
do
    local xdg = os.getenv("XDG_CONFIG_HOME")
    local home = os.getenv("HOME") or "/tmp"
    local base = xdg and (xdg .. "/yabai") or (home .. "/.config/yabai")
    config.gridScript = base .. "/grid-anchors.sh"
end

-- Space normalization policy
config.space = {
    layout = "bsp",
    padding = { top = 4, bottom = 4, left = 4, right = 4 },
    gap = 4,
    autoBalance = true,
}

-- Avoid overlap: let Yabai handle app-level float/sticky/sublayer/grid.
-- If you need Hammerspoon to enforce floats, set this to true.
config.enforceFloatInHS = false

-- App rules (subset of your Yabai rules, centralized here)
-- Each rule: { app="^Name$", title="optional regex", manage=false, sticky=true|false, subLayer="above|below|normal", gridAnchor="center_square|right_half|..." }
-- Remove duplication: Yabai owns app rules (float/sticky/grid).
-- Keep empty unless Hammerspoon must enforce policies explicitly.
config.appRules = {}

-- UI options
config.ui = {
    spaceOverlay = true, -- show persistent space/layout overlay
}

-- --- bus module (from bus.lua) ----------------------------------------------
-- Ultra-light event bus to coordinate modules without polling.

local bus = {}

local subs = {}

function bus.on(event, fn)
    if not event or type(fn) ~= "function" then
        return function() end
    end
    subs[event] = subs[event] or {}
    table.insert(subs[event], fn)
    local idx = #subs[event]
    return function()
        if subs[event] and subs[event][idx] == fn then
            table.remove(subs[event], idx)
        end
    end
end

function bus.emit(event, payload)
    local list = subs[event]
    if not list then
        return
    end
    for _, fn in ipairs(list) do
        pcall(fn, payload)
    end
end


-- --- module exports ----------------------------------------------------------

local M = {}

-- Export sub-modules
M.state = state
M.config = config  
M.bus = bus

return M