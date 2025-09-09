-- Title         : bus.lua
-- Author        : Parametric Forge
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/forge/bus.lua
-- ----------------------------------------------------------------------------
-- Ultra-light event bus to coordinate modules without polling.

local M = {}

local subs = {}

function M.on(event, fn)
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

function M.emit(event, payload)
    local list = subs[event]
    if not list then
        return
    end
    for _, fn in ipairs(list) do
        pcall(fn, payload)
    end
end

return M

