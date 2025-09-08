-- Title         : state.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/forge/state.lua
-- ----------------------------------------------------------------------------
-- Shared in-memory state and coalescing buckets for operations

local M = {}

M.windows = {} -- cache by win:id() -> { app, title, role, subrole, lastOps = {}, ts = number }
M.spaces = {} -- cache by spaceId -> { lastNormalizedAt = 0 }
M.pending = { -- coalesced operations
    window = {}, -- winId -> { ops = {}, timer = hs.timer }
    space = {}, -- spaceId -> { ops = {}, timer = hs.timer }
}

M.scratch = { -- label -> winId
}

function M.reset()
    M.windows, M.spaces, M.pending, M.scratch = {}, {}, { window = {}, space = {} }, {}
end

function M.windowEntry(winId)
    local e = M.windows[winId]
    if not e then
        e = { lastOps = {}, ts = hs.timer.absoluteTime() }
        M.windows[winId] = e
    end
    return e
end

function M.spaceEntry(spaceId)
    local e = M.spaces[spaceId]
    if not e then
        e = { lastNormalizedAt = 0 }
        M.spaces[spaceId] = e
    end
    return e
end

return M
