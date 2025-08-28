-- Title         : init.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/sketchybar/init.lua
-- ----------------------------------------------------------------------------
-- SbarLua main entry point - High performance Lua-based SketchyBar config

-- Initialize SbarLua
sbar = require("sketchybar")

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

-- Start event loop and finalize setup
sbar.run()

print("SketchyBar: SbarLua configuration loaded...")
