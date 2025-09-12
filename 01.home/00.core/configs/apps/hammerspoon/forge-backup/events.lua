-- Title         : events.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/forge/events.lua
-- ----------------------------------------------------------------------------
-- Window/space/screen/wake event subscriptions and handlers

local core = require("forge.core")

local M = {}
local log = hs.logger.new("forge.events", hs.logger.info)

-- Minimal event handling (window policy disabled)

function M.start()
    M.caff = hs.caffeinate.watcher.new(function(event)
        if event == hs.caffeinate.watcher.systemDidWake then
            if core.isProcessRunning("yabai") then
                hs.execute("/opt/homebrew/bin/yabai -m config window_opacity_duration 0.25", true)
            end
        end
    end)
    M.caff:start()

    log.i("forge.events started (wake watcher)")
end

return M
