-- Title         : init.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : modules/home/programs/apps/yazi/init.lua
-- ----------------------------------------------------------------------------
-- Initialize Yazi plugins for status bar cleanup and responsive layout

-- Custom Plugins -------------------------------------------------------------
require("sidebar_status"):setup()
require("auto_layout").setup()

-- Official Plugins -----------------------------------------------------------
require("full-border"):setup {
	type = ui.Border.ROUNDED,     -- Available values: ui.Border.PLAIN, ui.Border.ROUNDED
}
