-- Title         : automations_menu.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/modules/automations_menu.lua
-- ----------------------------------------------------------------------------
-- File automations toggle menu using native hs.menubar

local automations = require("modules.automations")
local assets = require("utils.assets")

local M = {}
local log = hs.logger.new("automations_menu", hs.logger.info)

local menuItem

-- Set dynamic icon based on automation status
local function updateIcon()
    if not menuItem then
        return
    end
    local status = automations.getStatus()
    local anyEnabled = status.unzip or status.webp2png or status.pdf
    local iconName = anyEnabled and "automations-on" or "automations-off"
    local icon = assets.image(iconName, { w = 18, h = 18 })
    if icon then
        menuItem:setIcon(icon)
        menuItem:setTooltip("Automations")
    else
        menuItem:setTitle(anyEnabled and "A*" or "A")
        menuItem:setTooltip("File Automations")
    end
end

local function buildMenu()
    local status = automations.getStatus()

    return {
        {
            title = "File Automations",
            disabled = true,
        },
        {
            title = "Auto Unzip: " .. (status.unzip and "Enabled" or "Disabled"),
            checked = status.unzip,
            image = assets.image(status.unzip and "unzip-on" or "unzip-off", { w = 16, h = 16 }),
            fn = function()
                automations.toggle("unzip")
                updateIcon()
            end,
        },
        {
            title = "Auto WebP→PNG: " .. (status.webp2png and "Enabled" or "Disabled"),
            checked = status.webp2png,
            image = assets.image(status.webp2png and "webp2png-on" or "webp2png-off", { w = 16, h = 16 }),
            fn = function()
                automations.toggle("webp2png")
                updateIcon()
            end,
        },
        {
            title = "Auto PDF OCR+Optimize: " .. (status.pdf and "Enabled" or "Disabled"),
            checked = status.pdf,
            image = assets.image(status.pdf and "pdf-on" or "pdf-off", { w = 16, h = 16 }),
            fn = function()
                automations.toggle("pdf")
                updateIcon()
            end,
        },
        { title = "-" },
        {
            title = "Hammerspoon",
            disabled = true,
        },
        {
            title = "Hammerspoon Console",
            image = assets.image("forge-menu", { w = 18, h = 18 }),
            fn = function()
                hs.openConsole()
            end,
        },
    }
end

function M.init()
    if menuItem then
        return
    end

    menuItem = hs.menubar.new()
    if not menuItem then
        log.e("Failed to create automations menubar item")
        return false
    end

    menuItem:autosaveName("forge-menubar-automations")

    updateIcon()

    -- Set dynamic menu (rebuilds on each click, updates icon too)
    menuItem:setMenu(function()
        updateIcon()
        return buildMenu()
    end)

    log.i("Automations menu initialized")
    return true
end

function M.stop()
    if menuItem then
        menuItem:delete()
        menuItem = nil
    end
    log.i("Automations menu stopped")
end

return M
