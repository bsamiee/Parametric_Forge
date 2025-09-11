-- Title         : events.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/forge/events.lua
-- ----------------------------------------------------------------------------
-- Window/space/screen/wake event subscriptions and handlers

local core = require("forge.core")
local config = core.config

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

    -- Passive OSD hint when entering skhd float modal (cmd+shift+return)
    -- This does not consume the event; skhd still handles the modal switch.
    local osd = require("forge.osd")
    local lastHintAt = 0
    M.tap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(evt)
        local code = evt:getKeyCode()
        local mods = evt:getFlags()
        -- keycode 36 is Return/Enter on macOS
        if code == hs.keycodes.map.return and mods.cmd and mods.shift and not (mods.alt or mods.ctrl or mods.fn) then
            local t = hs.timer.secondsSinceEpoch()
            if t - lastHintAt > 0.3 then
                lastHintAt = t
                osd.show("Float Mode", { duration = 1.2 })
            end
        end
        return false -- do not consume
    end)
    M.tap:start()

    log.i("forge.events started (wake + modal hint)")
end

return M
