-- Title         : mouse.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : modules/home/programs/apps/wezterm/mouse.lua
-- ----------------------------------------------------------------------------
-- Mouse configuration and bindings

local wezterm = require("wezterm")

local M = {}

function M.setup(config)
  -- Mouse Behavior -----------------------------------------------------------
  config.hide_mouse_cursor_when_typing = true

  -- WezTerm handles hyperlinks, not Zellij
  config.bypass_mouse_reporting_modifiers = 'SHIFT'
  config.mouse_bindings = {
    {
      event = { Up = { streak = 1, button = 'Left' } },
      mods = 'CMD', -- Require CMD-click to open links to avoid accidental opens
      action = wezterm.action.OpenLinkAtMouseCursor,
    },
  }
end

return M
