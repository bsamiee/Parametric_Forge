-- Title         : wezterm.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : modules/home/programs/apps/wezterm/wezterm.lua
-- ----------------------------------------------------------------------------
-- WezTerm entry point with shared appearance and Zellij integration

local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Import Modules -------------------------------------------------------------
local appearance = require("appearance")
local behavior = require("behavior")
local keys = require("keys")
local mouse = require("mouse")
local integration = require("integration")

-- Setup Configuration --------------------------------------------------------
local theme = appearance.setup(config)
behavior.apply(config, theme)
keys.setup(config)
mouse.setup(config)
integration.setup(config)

return config
