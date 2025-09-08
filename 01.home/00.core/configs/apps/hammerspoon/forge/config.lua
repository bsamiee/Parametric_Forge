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
}

-- Float policy thresholds
M.floatThreshold = { minW = 400, minH = 260 }

-- Grid anchors via external script (avoid duplicating grids)
-- Resolve grid script path from multiple common locations
do
    local home = os.getenv("HOME")
    local candidates = {
        home .. "/.config/yabai/grid-anchors.sh",
        home .. "/01.home/00.core/configs/apps/yabai/grid-anchors.sh",
        "01.home/00.core/configs/apps/yabai/grid-anchors.sh",
    }
    local function exists(p)
        return p and #p > 0 and (hs.fs.attributes(p) ~= nil)
    end
    for _, p in ipairs(candidates) do
        if exists(p) then
            M.gridScript = p
            break
        end
    end
    -- fallback to default even if not found (executor guards actual use)
    if not M.gridScript then
        M.gridScript = home .. "/.config/yabai/grid-anchors.sh"
    end
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
    { app = "^Dictionary$", manage = false, subLayer = "below", gridAnchor = "center_large" },
    { app = "^Karabiner%-Elements$", manage = false, subLayer = "below", gridAnchor = "center_large" },
    { app = "^QuickTime Player$", manage = false, subLayer = "below", gridAnchor = "center_large" },
    { app = "^Preview$", manage = false, subLayer = "below", gridAnchor = "center_large" },
    { app = "^1Password$", manage = false, sticky = true, subLayer = "above", gridAnchor = "center_large" },
    { app = "^Digital Colormeter$", manage = false, subLayer = "below", gridAnchor = "top_right_quarter" },
    { app = "^ColorSync Utility$", manage = false, subLayer = "below", gridAnchor = "center_large" },
    { app = "^Font File Browser$", manage = false, subLayer = "below", gridAnchor = "center_large" },

    -- Browsers - Arc
    { app = "^Arc$", manage = false },
    { app = "^Arc$", title = "^Little Arc$", manage = false, sticky = true, subLayer = "above" },
    { app = "^Arc$", title = ".*[Nn]otification.*", manage = false, sticky = true, subLayer = "above" },

    -- Productivity / Tools
    { app = "^Raycast$", manage = false, subLayer = "below", gridAnchor = "center_large" },
    { app = "^CleanShot X$", manage = false, subLayer = "above" },
    { app = "^BetterTouchTool$", manage = false, subLayer = "below", gridAnchor = "center_large" },
    { app = "^Docker Desktop$", manage = false, subLayer = "below", gridAnchor = "center_large" },
    { app = "^Hammerspoon$", manage = false, subLayer = "below", gridAnchor = "center_large" },

    -- Communication & Media
    { app = "^Discord$", manage = false, subLayer = "below", gridAnchor = "right_half" },
    { app = "^Messages$", manage = false, subLayer = "below", gridAnchor = "right_half" },
    { app = "^Telegram$", manage = false, subLayer = "below", gridAnchor = "right_half" },
    { app = "^WhatsApp$", manage = false, subLayer = "below", gridAnchor = "right_half" },
    { app = "^FaceTime$", manage = false, subLayer = "below", gridAnchor = "right_third" },
    { app = "^zoom%.us$", manage = false, subLayer = "below", gridAnchor = "center_large" },
    { app = "^Spotify$", manage = false, subLayer = "below", gridAnchor = "bottom_center_two_thirds" },

    -- Creative & Design
    { app = "^Blender$", manage = false, subLayer = "below" },
    { app = "^Adobe Photoshop 202[0-9]$", manage = false, subLayer = "below", gridAnchor = "full" },
    { app = "^Adobe Illustrator 202[0-9]$", manage = false, subLayer = "below", gridAnchor = "full" },
    { app = "^Adobe After Effects 202[0-9]$", manage = false, subLayer = "below", gridAnchor = "full" },

    -- Development Tools
    { app = "^Console$", manage = false, subLayer = "below" },
    { app = "^WezTerm$", manage = true },
    { app = "^Visual Studio Code$", manage = true },
    { app = "^Adobe Creative Cloud$", manage = false, subLayer = "below", gridAnchor = "center_large" },
}

return M
