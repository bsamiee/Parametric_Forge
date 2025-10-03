-- Title         : keys.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : modules/home/programs/apps/wezterm/keys.lua
-- ----------------------------------------------------------------------------
-- Key bindings and input configuration

local wezterm = require("wezterm")

local M = {}

function M.setup(config)
  -- Alt Key Configuration ----------------------------------------------------
  config.send_composed_key_when_left_alt_is_pressed = false
  config.send_composed_key_when_right_alt_is_pressed = false
  config.use_dead_keys = false

  -- Future key bindings can be added here
  -- config.keys = {}
end

return M
