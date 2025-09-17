-- Title         : yabai_notifications.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/modules/yabai_notifications.lua
-- ----------------------------------------------------------------------------
-- Yabai toggle notifications - simple and direct like space_notifications.lua

local canvas = require("notifications.canvas")

local M = {}
local log = hs.logger.new("yabai_notifications", hs.logger.info)

-- Layout toggle
local function toggleLayout()
    -- Get current layout
    local output = hs.execute("/opt/homebrew/bin/yabai -m query --spaces --space | jq -r '.type'", true)
    if output then
        local current = output:gsub("%s+", "")
        local newLayout = (current == "bsp") and "stack" or "bsp"

        -- Apply new layout
        hs.execute("/opt/homebrew/bin/yabai -m space --layout " .. newLayout)

        -- Show notification
        canvas.show("LAYOUT: " .. string.upper(newLayout), 2)
    end
end

-- Gaps toggle
local function toggleGaps()
    -- Get current gap setting
    local output = hs.execute("/opt/homebrew/bin/yabai -m config top_padding", true)
    local cleaned = (output or "0"):gsub("%s+", "")

    if cleaned == "0" then
        -- Enable gaps
        hs.execute("/opt/homebrew/bin/yabai -m config top_padding 4")
        hs.execute("/opt/homebrew/bin/yabai -m config bottom_padding 4")
        hs.execute("/opt/homebrew/bin/yabai -m config left_padding 4")
        hs.execute("/opt/homebrew/bin/yabai -m config right_padding 4")
        hs.execute("/opt/homebrew/bin/yabai -m config window_gap 4")
        hs.execute("/opt/homebrew/bin/yabai -m config external_bar all:4:4")
        canvas.show("GAPS: ON", 2)
    else
        -- Disable gaps
        hs.execute("/opt/homebrew/bin/yabai -m config top_padding 0")
        hs.execute("/opt/homebrew/bin/yabai -m config bottom_padding 0")
        hs.execute("/opt/homebrew/bin/yabai -m config left_padding 0")
        hs.execute("/opt/homebrew/bin/yabai -m config right_padding 0")
        hs.execute("/opt/homebrew/bin/yabai -m config window_gap 0")
        hs.execute("/opt/homebrew/bin/yabai -m config external_bar all:0:0")
        canvas.show("GAPS: OFF", 2)
    end
end

-- Opacity toggle
local function toggleOpacity()
    -- Get current opacity setting
    local output = hs.execute("/opt/homebrew/bin/yabai -m config window_opacity", true)
    local current = (output or ""):gsub("%s+", "")

    if current == "on" then
        hs.execute("/opt/homebrew/bin/yabai -m config window_opacity off")
        canvas.show("OPACITY: OFF", 2)
    else
        hs.execute("/opt/homebrew/bin/yabai -m config window_opacity on")
        canvas.show("OPACITY: ON", 2)
    end
end

-- Mouse drop toggle
local function toggleMouseDrop()
    -- Get current mouse drop action
    local output = hs.execute("/opt/homebrew/bin/yabai -m config mouse_drop_action", true)
    local current = (output or ""):gsub("%s+", "")

    if current == "swap" then
        hs.execute("/opt/homebrew/bin/yabai -m config mouse_drop_action stack")
        canvas.show("MOUSE DROP: STACK", 2)
    else
        hs.execute("/opt/homebrew/bin/yabai -m config mouse_drop_action swap")
        canvas.show("MOUSE DROP: SWAP", 2)
    end
end

function M.init()
    -- Register hotkeys
    hs.hotkey.bind({ "cmd", "ctrl", "alt", "shift" }, "t", toggleLayout)
    hs.hotkey.bind({ "cmd", "ctrl", "alt", "shift" }, "g", toggleGaps)
    hs.hotkey.bind({ "cmd", "ctrl", "alt", "shift" }, "o", toggleOpacity)
    hs.hotkey.bind({ "cmd", "ctrl", "alt", "shift" }, "m", toggleMouseDrop)

    log.i("Yabai notifications initialized")
    return true
end

function M.stop()
    log.i("Yabai notifications stopped")
end

return M
