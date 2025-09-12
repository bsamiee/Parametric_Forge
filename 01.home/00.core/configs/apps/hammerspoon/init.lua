-- Title         : init.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/init.lua
-- ----------------------------------------------------------------------------
-- Minimal bootstrap for new foundation architecture
-- Purpose: Initialize core systems using native Hammerspoon capabilities

-- Core Hammerspoon settings
hs.window.animationDuration = 0
hs.hints.showTitleThresh = 0
hs.hotkey.alertDuration = 0

local log = hs.logger.new("forge", hs.logger.info)

-- Ensure module discovery using our infrastructure
do
    local config = require("utils.config")
    local cfgdir = config.getConfigDir()
    package.path = string.format("%s/?.lua;%s/?/init.lua;%s", cfgdir, cfgdir, package.path)
end

-- Initialize foundation components
local canvas = require("notifications.canvas")
local yabai_bridge = require("integration.yabai_bridge")
local automations = require("modules.automations")
local caffeine = require("modules.caffeine")
local space_indicator = require("modules.space_indicator")
local services_menu = require("modules.services_menu")
local automations_menu = require("modules.automations_menu")

-- Initialize all systems
local ok1 = pcall(yabai_bridge.init)
local ok2 = pcall(automations.init)  
local ok3 = pcall(caffeine.init)
local ok4 = pcall(space_indicator.init)
local ok5 = pcall(services_menu.init)
local ok6 = pcall(automations_menu.init)

if ok1 and ok2 and ok3 and ok4 and ok5 and ok6 then
    canvas.show("HAMMERSPOON READY", 2.5)
    log.i("Hammerspoon foundation initialized")
else
    canvas.show("INIT ERROR - CHECK CONSOLE", 2.5)
    log.e("Failed to initialize some modules")
end
