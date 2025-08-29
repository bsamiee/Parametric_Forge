-- Title         : init.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/sketchybar/init.lua
-- ----------------------------------------------------------------------------
-- SbarLua main entry point - High performance Lua-based SketchyBar config

-- Initialize SbarLua with error handling
local ok, sbar_module = pcall(require, "sketchybar")
if not ok then
    print("ERROR: SketchyBar SbarLua module not found")
    os.exit(1)
end
sbar = sbar_module

-- Initialize Tier 1 foundation systems
events = require("modules.core.events")
performance = require("modules.core.performance")
interactions = require("modules.core.interactions")

-- Initialize Tier 2 ecosystem systems
ecosystem = require("modules.core.ecosystem")
context = require("modules.core.context")

-- Initialize all systems in dependency order
events.init()
performance.init = performance.init or function() end -- Safe init
interactions.init()
ecosystem.init()
context.init()

-- Register cross-system event handlers after all systems are ready
interactions.register_events()

-- Import configuration modules
require("modules.bar")
require("modules.colors")
require("modules.icons")

-- Import item modules
require("modules.items.spaces")
require("modules.items.battery")
require("modules.items.clock")
require("modules.items.cpu")
require("modules.items.volume")

-- Validate yabai integration before starting
local yabai_ok = false
sbar.exec("command -v yabai", function(result)
    yabai_ok = result and result ~= ""
end)

if not yabai_ok then
    print("WARNING: yabai not found - some features may not work")
end

-- Start event loop and finalize setup
sbar.run()

print("SketchyBar: SbarLua configuration loaded successfully")
print("SketchyBar: Height 32px - aligned with yabai external bar")
if yabai_ok then
    print("SketchyBar: Yabai integration active")
end
