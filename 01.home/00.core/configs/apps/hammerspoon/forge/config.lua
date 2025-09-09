-- Title         : config.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/forge/config.lua
-- ----------------------------------------------------------------------------
-- Config and policy definitions for Hammerspoon policy engine

local M = {}

-- Debounce windows/spaces/display updates (milliseconds)
M.debounce = {
    window = 80,
    space = 120,
    screen = 150,
    state = 120,
}

-- Float policy thresholds
M.floatThreshold = { minW = 400, minH = 260 }

-- Grid anchors via external script (avoid duplicating grids)
do
    local xdg = os.getenv("XDG_CONFIG_HOME")
    local home = os.getenv("HOME") or "/tmp"
    local base = xdg and (xdg .. "/yabai") or (home .. "/.config/yabai")
    M.gridScript = base .. "/grid-anchors.sh"
end

-- Space normalization policy
M.space = {
    layout = "bsp",
    padding = { top = 4, bottom = 4, left = 4, right = 4 },
    gap = 4,
    autoBalance = true,
}

-- Avoid overlap: let Yabai handle app-level float/sticky/sublayer/grid.
-- If you need Hammerspoon to enforce floats, set this to true.
M.enforceFloatInHS = false

-- App rules (subset of your Yabai rules, centralized here)
-- Each rule: { app="^Name$", title="optional regex", manage=false, sticky=true|false, subLayer="above|below|normal", gridAnchor="center_square|right_half|..." }
M.appRules = {
    -- System applications
    { app = "^System Settings$", manage = false, subLayer = "below" },
    { app = "^System Preferences$", manage = false, subLayer = "below" },
    { app = "^System Information$", manage = false, subLayer = "below" },
    { app = "^Activity Monitor$", manage = false, subLayer = "below" },
    { app = "^Archive Utility$", manage = false, subLayer = "below" },
    { app = "^Installer$", manage = false, subLayer = "below" },
    { app = "^Software Update$", manage = false, subLayer = "below" },
    { app = "^Finder$", manage = false, subLayer = "below", gridAnchor = "left_half" },
    { app = "^Migration Assistant$", manage = false, subLayer = "below" },
    { app = "^Disk Utility$", manage = false, subLayer = "below" },

    -- Utilities
    { app = "^Calculator$", manage = false, subLayer = "below", gridAnchor = "top_right_quarter" },
    { app = "^Dictionary$", manage = false, subLayer = "below", gridAnchor = "center" },
    { app = "^Karabiner%-Elements$", manage = false, subLayer = "below", gridAnchor = "center" },
    { app = "^QuickTime Player$", manage = false, subLayer = "below", gridAnchor = "center" },
    { app = "^Preview$", manage = false, subLayer = "below", gridAnchor = "center" },
    { app = "^1Password$", manage = false, sticky = true, subLayer = "above", gridAnchor = "center" },
    { app = "^Digital Colormeter$", manage = false, subLayer = "below", gridAnchor = "top_right_quarter" },
    { app = "^ColorSync Utility$", manage = false, subLayer = "below", gridAnchor = "center" },
    { app = "^Font File Browser$", manage = false, subLayer = "below", gridAnchor = "center" },

    -- Browsers - Arc
    { app = "^Arc$", manage = false },
    { app = "^Arc$", title = "^Little Arc$", manage = false, sticky = true, subLayer = "above" },
    { app = "^Arc$", title = ".*[Nn]otification.*", manage = false, sticky = true, subLayer = "above" },

    -- Productivity / Tools
    { app = "^Raycast$", manage = false, subLayer = "below", gridAnchor = "center" },
    { app = "^CleanShot X$", manage = false, subLayer = "above" },
    { app = "^BetterTouchTool$", manage = false, subLayer = "below", gridAnchor = "center" },
    { app = "^Docker Desktop$", manage = false, subLayer = "below", gridAnchor = "center" },
    { app = "^Hammerspoon$", manage = false, subLayer = "below", gridAnchor = "center" },

    -- Communication & Media
    { app = "^Discord$", manage = false, subLayer = "below", gridAnchor = "right_half" },
    { app = "^Messages$", manage = false, subLayer = "below", gridAnchor = "right_half" },
    { app = "^Telegram$", manage = false, subLayer = "below", gridAnchor = "right_half" },
    { app = "^WhatsApp$", manage = false, subLayer = "below", gridAnchor = "right_half" },
    { app = "^FaceTime$", manage = false, subLayer = "below", gridAnchor = "right_third" },
    { app = "^zoom%.us$", manage = false, subLayer = "below", gridAnchor = "center" },
    { app = "^Spotify$", manage = false, subLayer = "below", gridAnchor = "bottom" },

    -- Creative & Design
    { app = "^Blender$", manage = false, subLayer = "below" },
    { app = "^Adobe Photoshop 202[0-9]$", manage = false, subLayer = "below", gridAnchor = "full" },
    { app = "^Adobe Illustrator 202[0-9]$", manage = false, subLayer = "below", gridAnchor = "full" },
    { app = "^Adobe After Effects 202[0-9]$", manage = false, subLayer = "below", gridAnchor = "full" },

    -- Development Tools
    { app = "^Console$", manage = false, subLayer = "below" },
    { app = "^WezTerm$", manage = true },
    { app = "^Visual Studio Code$", manage = true },
    { app = "^Adobe Creative Cloud$", manage = false, subLayer = "below", gridAnchor = "center" },
}

-- UI options
M.ui = {
    spaceOverlay = true, -- show persistent space/layout overlay
}

return M
