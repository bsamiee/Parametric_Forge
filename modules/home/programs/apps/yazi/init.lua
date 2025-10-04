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
	type = ui.Border.PLAIN,     -- Available values: ui.Border.PLAIN, ui.Border.ROUNDED
}
require("starship"):setup({
    -- Hide flags (such as filter, find and search). This is recommended for starship themes which
    -- are intended to go across the entire width of the terminal.
    hide_flags = false, -- Default: false
    -- Whether to place flags after the starship prompt. False means the flags will be placed before the prompt.
    flags_after_prompt = true, -- Default: true
    -- Custom starship configuration file to use
    config_file = "~/.config/starship.toml",
})
