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

  -- SHIFT modifier: Bypasses Zellij mouse reporting
  -- Holding SHIFT + clicking/dragging lets WezTerm handle the event
  -- This is essential for text selection when Zellij has mouse_mode enabled
  config.bypass_mouse_reporting_modifiers = 'SHIFT'

  -- Mouse Bindings: Minimal approach - only hyperlink opening
  -- Zellij handles all text selection and copy-on-select
  config.mouse_bindings = {
    -- SHIFT+Left-Click: Open hyperlinks
    {
      event = { Up = { streak = 1, button = 'Left' } },
      mods = 'SHIFT',
      action = wezterm.action.OpenLinkAtMouseCursor,
    },
  }
end

return M
