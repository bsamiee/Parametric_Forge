-- Title         : wezterm.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : modules/home/programs/apps/wezterm/wezterm.lua
-- ----------------------------------------------------------------------------
-- WezTerm entry point - minimal configuration with appearance module

local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Import appearance module ---------------------------------------------------
local appearance = require("appearance")

-- Setup appearance and get shared values for future modules
local theme = appearance.setup(config)

return config
