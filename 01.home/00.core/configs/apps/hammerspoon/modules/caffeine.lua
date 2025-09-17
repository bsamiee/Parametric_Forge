-- Title         : caffeine.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/modules/caffeine.lua
-- ----------------------------------------------------------------------------
-- Caffeine menubar with state-based icons (from working backup pattern)

local canvas = require("notifications.canvas")
local assets = require("utils.assets")

local M = {}
local log = hs.logger.new("caffeine", hs.logger.info)

local menuItem

-- Set icon based on caffeine state (from working backup pattern)
local function updateIcon()
    if not menuItem then
        return
    end

    local isActive = hs.caffeinate.get("displayIdle")
    local iconName = isActive and "caffeine-on" or "caffeine-off"
    local icon = assets.image(iconName, { w = 18, h = 18 })

    if icon then
        menuItem:setIcon(icon)
        menuItem:setTooltip("Caffeine: " .. (isActive and "Display awake" or "Off"))
    else
        menuItem:setTitle(isActive and "C*" or "C")
        menuItem:setTooltip("Caffeine")
    end
end

function M.toggle()
    hs.caffeinate.toggle("displayIdle")
    local isActive = hs.caffeinate.get("displayIdle")

    updateIcon()
    canvas.show("CAFFEINE: " .. (isActive and "ON" or "OFF"))
    log.i("Caffeine toggled: " .. (isActive and "ON" or "OFF"))

    return isActive
end

function M.isActive()
    return hs.caffeinate.get("displayIdle")
end

local function buildMenu()
    local isActive = hs.caffeinate.get("displayIdle")
    return {
        {
            title = isActive and "Turn Caffeine Off" or "Turn Caffeine On",
            fn = M.toggle,
        },
        { title = "-" },
        {
            title = "Prevent: Display Sleep",
            checked = isActive,
            disabled = true,
        },
    }
end

function M.init()
    if menuItem then
        return
    end

    menuItem = hs.menubar.new()
    if not menuItem then
        log.e("Failed to create caffeine menubar item")
        return false
    end

    menuItem:autosaveName("forge-caffeine")
    menuItem:setClickCallback(M.toggle)
    menuItem:setMenu(buildMenu)

    updateIcon()
    log.i("Caffeine menubar initialized")
    return true
end

function M.stop()
    if menuItem then
        menuItem:delete()
        menuItem = nil
    end
    log.i("Caffeine menubar stopped")
end

return M
