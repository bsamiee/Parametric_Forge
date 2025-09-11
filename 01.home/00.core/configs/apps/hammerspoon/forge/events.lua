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
    -- After wake - refresh SA and opacity settings
    M.caff = hs.caffeinate.watcher.new(function(event)
        if event == hs.caffeinate.watcher.systemDidWake then
            core.refreshSa()
            if core.isProcessRunning("yabai") and core.sa.available then
                core.sh("yabai -m config window_opacity_duration 0.25")
            end
        end
    end)
    M.caff:start()

    log.i("forge.events started (wake watcher)")
end

return M
