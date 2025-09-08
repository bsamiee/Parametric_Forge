-- Config and policy definitions for Hammerspoon policy engine
local M = {}

-- Debounce windows/spaces/display updates (milliseconds)
M.debounce = {
  window = 80,
  space  = 120,
  screen = 150,
}

-- Float policy thresholds
M.floatThreshold = { minW = 400, minH = 260 }

-- Grid anchors via external script (avoid duplicating grids)
M.gridScript = os.getenv("HOME") .. "/.config/yabai/grid-anchors.sh"

-- Space normalization policy
M.space = {
  layout = "bsp",
  padding = { top = 4, bottom = 4, left = 4, right = 4 },
  gap = 4,
  autoBalance = true,
}

-- App rules (subset of your Yabai rules, centralized here)
-- Each rule: { app="^Name$", title="optional regex", manage=false, sticky=true|false, subLayer="above|below|normal", gridAnchor="center_square|right_half|..." }
M.appRules = {
  -- System applications
  { app = "^System Settings$",       manage = false, subLayer = "below", gridAnchor = "center_square" },
  { app = "^System Preferences$",    manage = false, subLayer = "below", gridAnchor = "center_square" },
  { app = "^System Information$",    manage = false, subLayer = "below", gridAnchor = "center_square" },
  { app = "^Activity Monitor$",      manage = false, subLayer = "below", gridAnchor = "center_square" },
  { app = "^Archive Utility$",       manage = false, subLayer = "below", gridAnchor = "center_square" },
  { app = "^Installer$",             manage = false, subLayer = "below", gridAnchor = "center_square" },
  { app = "^Software Update$",       manage = false, subLayer = "below", gridAnchor = "center_square" },
  { app = "^Finder$",                manage = false, subLayer = "below", gridAnchor = "center_square" },
  { app = "^Migration Assistant$",   manage = false, subLayer = "below", gridAnchor = "center_square" },
  { app = "^Disk Utility$",          manage = false, subLayer = "below", gridAnchor = "center_square" },

  -- Utilities
  { app = "^Calculator$",            manage = false, subLayer = "below", gridAnchor = "top_right_3x3" },
  { app = "^Dictionary$",            manage = false, subLayer = "below", gridAnchor = "center_square" },
  { app = "^Karabiner%-Elements$",   manage = false, subLayer = "below", gridAnchor = "center_square" },
  { app = "^QuickTime Player$",      manage = false, subLayer = "below", gridAnchor = "center_square" },
  { app = "^Preview$",               manage = false, subLayer = "below", gridAnchor = "center_square" },
  { app = "^1Password$",             manage = false, sticky = true, subLayer = "above", gridAnchor = "center_square" },
  { app = "^Digital Colormeter$",    manage = false, subLayer = "below", gridAnchor = "top_right_3x3" },
  { app = "^ColorSync Utility$",     manage = false, subLayer = "below", gridAnchor = "center_square" },
  { app = "^Font File Browser$",     manage = false, subLayer = "below", gridAnchor = "center_square" },

  -- Browsers - Arc
  { app = "^Arc$",                    manage = false },
  { app = "^Arc$", title = "^Little Arc$", manage = false, sticky = true, subLayer = "above" },
  { app = "^Arc$", title = ".*[Nn]otification.*", manage = false, sticky = true, subLayer = "above" },

  -- Productivity / Tools
  { app = "^Raycast$",               manage = false, subLayer = "below", gridAnchor = "middle_center_3x3" },
  { app = "^CleanShot X$",           manage = false, subLayer = "above" },
  { app = "^BetterTouchTool$",       manage = false, subLayer = "below", gridAnchor = "center_square" },
  { app = "^Docker Desktop$",        manage = false, subLayer = "below", gridAnchor = "center_square" },
  { app = "^Hammerspoon$",           manage = false, subLayer = "below", gridAnchor = "center_square" },

  -- Communication & Media
  { app = "^Discord$",               manage = false, subLayer = "below", gridAnchor = "right_half" },
  { app = "^Messages$",              manage = false, subLayer = "below", gridAnchor = "right_half" },
  { app = "^Telegram$",              manage = false, subLayer = "below", gridAnchor = "right_half" },
  { app = "^WhatsApp$",              manage = false, subLayer = "below", gridAnchor = "right_half" },
  { app = "^FaceTime$",              manage = false, subLayer = "below", gridAnchor = "right_third" },
  { app = "^zoom%.us$",              manage = false, subLayer = "below", gridAnchor = "center_square" },
  { app = "^Spotify$",               manage = false, subLayer = "below", gridAnchor = "bottom_center_3x3" },

  -- Creative & Design
  { app = "^Blender$",               manage = false, subLayer = "below" },
  { app = "^Adobe Photoshop 202[0-9]$",    manage = false, subLayer = "below", gridAnchor = "full" },
  { app = "^Adobe Illustrator 202[0-9]$",  manage = false, subLayer = "below", gridAnchor = "full" },
  { app = "^Adobe After Effects 202[0-9]$",manage = false, subLayer = "below", gridAnchor = "full" },

  -- Development Tools
  { app = "^Console$",               manage = false, subLayer = "below" },
  { app = "^WezTerm$",               manage = true },
  { app = "^Visual Studio Code$",    manage = true },
  { app = "^Adobe Creative Cloud$",  manage = false, subLayer = "below", gridAnchor = "center_square" },
}

return M

