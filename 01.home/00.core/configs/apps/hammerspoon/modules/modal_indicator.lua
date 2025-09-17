-- Title         : modal_indicator.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/modules/modal_indicator.lua
-- ----------------------------------------------------------------------------
-- Native Hammerspoon float modal with persistent indicator

local M = {}
local log = hs.logger.new("modal_indicator", hs.logger.info)

local persistent = require("notifications.persistent_canvas")
local config = require("utils.config")
local floatModal = nil

-- Non-blocking yabai helper for instant responsiveness
local function yabai(args)
    hs.task.new(config.getYabaiPath(), nil, args):start()
end

function M.init()
    if floatModal then
        return true
    end

    persistent.init()

    floatModal = hs.hotkey.modal.new({ "shift", "cmd" }, "return")

    floatModal.entered = function()
        persistent.set("float_mode", { text = "[FLOAT MODE]" })
    end

    floatModal.exited = function()
        persistent.remove("float_mode")
    end

    -- Float actions (all auto-exit)
    floatModal:bind({}, "left", function()
        yabai({ "-m", "window", "--grid", "1:2:0:0:1:1", "--manage", "off" })
        floatModal:exit()
    end)

    floatModal:bind({}, "right", function()
        yabai({ "-m", "window", "--grid", "1:2:1:0:1:1", "--manage", "off" })
        floatModal:exit()
    end)

    floatModal:bind({}, "up", function()
        yabai({ "-m", "window", "--grid", "2:1:0:0:1:1", "--manage", "off" })
        floatModal:exit()
    end)

    floatModal:bind({}, "down", function()
        yabai({ "-m", "window", "--grid", "2:1:0:1:1:1", "--manage", "off" })
        floatModal:exit()
    end)

    -- Thirds
    floatModal:bind({}, "q", function()
        yabai({ "-m", "window", "--grid", "1:3:0:0:1:1", "--manage", "off" })
        floatModal:exit()
    end)

    floatModal:bind({}, "w", function()
        yabai({ "-m", "window", "--grid", "1:3:1:0:1:1", "--manage", "off" })
        floatModal:exit()
    end)

    floatModal:bind({}, "e", function()
        yabai({ "-m", "window", "--grid", "1:3:2:0:1:1", "--manage", "off" })
        floatModal:exit()
    end)

    -- Quarters
    floatModal:bind({}, "1", function()
        yabai({ "-m", "window", "--grid", "2:2:0:0:1:1", "--manage", "off" })
        floatModal:exit()
    end)

    floatModal:bind({}, "2", function()
        yabai({ "-m", "window", "--grid", "2:2:1:0:1:1", "--manage", "off" })
        floatModal:exit()
    end)

    floatModal:bind({}, "3", function()
        yabai({ "-m", "window", "--grid", "2:2:0:1:1:1", "--manage", "off" })
        floatModal:exit()
    end)

    floatModal:bind({}, "4", function()
        yabai({ "-m", "window", "--grid", "2:2:1:1:1:1", "--manage", "off" })
        floatModal:exit()
    end)

    -- Center and full
    floatModal:bind({}, "c", function()
        yabai({ "-m", "window", "--grid", "6:6:1:1:4:4", "--manage", "off" })
        floatModal:exit()
    end)

    floatModal:bind({}, "f", function()
        yabai({ "-m", "window", "--grid", "1:1:0:0:1:1", "--manage", "off" })
        floatModal:exit()
    end)

    floatModal:bind({}, "escape", function()
        floatModal:exit()
    end)
    floatModal:bind({}, "return", function()
        floatModal:exit()
    end)

    log.i("Float modal initialized")
    return true
end

function M.stop()
    if floatModal then
        floatModal:exit()
        floatModal = nil
    end
    persistent.remove("float_mode")
    log.i("Float modal stopped")
end

return M
