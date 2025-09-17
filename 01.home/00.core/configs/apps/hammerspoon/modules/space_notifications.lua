-- Title         : space_notifications.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/modules/space_notifications.lua
-- ----------------------------------------------------------------------------
-- Independent space change notifications using canvas system
-- Operates separately from space_indicator menubar item

local canvas = require("notifications.canvas")

local M = {}
local log = hs.logger.new("space_notifications", hs.logger.info)

local spacesWatcher

local function onSpaceChange()
    -- Get current space info
    local currentSpace = hs.spaces.focusedSpace()
    if not currentSpace then
        return
    end

    -- Get all spaces to find the index
    local allSpaces = hs.spaces.allSpaces()
    local spaceIndex = 1

    -- Find the index of current space across all displays
    for displayId, spaces in pairs(allSpaces) do
        for i, spaceId in ipairs(spaces) do
            if spaceId == currentSpace then
                spaceIndex = i
                break
            end
        end
    end

    -- Show notification
    canvas.show("SPACE " .. spaceIndex, 1.5)
end

function M.init()
    if spacesWatcher then
        return true
    end

    -- Create independent spaces watcher
    if hs.spaces and hs.spaces.watcher and hs.spaces.watcher.new then
        spacesWatcher = hs.spaces.watcher.new(onSpaceChange)
        spacesWatcher:start()

        log.i("Space notifications initialized")
        return true
    else
        log.e("hs.spaces.watcher not available")
        return false
    end
end

function M.stop()
    if spacesWatcher then
        spacesWatcher:stop()
        spacesWatcher = nil
        log.i("Space notifications stopped")
    end
end

return M
