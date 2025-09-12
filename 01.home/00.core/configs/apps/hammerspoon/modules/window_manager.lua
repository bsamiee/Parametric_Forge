-- Title         : window_manager.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/modules/window_manager.lua
-- ----------------------------------------------------------------------------
-- Modern, unified window switcher - single command, all spaces, smart ordering
-- Uses shared infrastructure for consistent styling

local styles = require("notifications.styles")

local M = {}
local log = hs.logger.new("window_switcher", hs.logger.info)

-- Single reusable switcher (create once, use forever)
local switcher

function M.init()
    -- Smart window filter: All standard windows, ordered by recent use
    local windowFilter = hs.window.filter.new(function(win)
        return win:isStandard() and win:isVisible()
    end)
    
    -- Configure ordering: most recently used first
    windowFilter:setSortOrder(hs.window.filter.sortByFocusedLast)
    
    -- Create single switcher instance with consistent styling
    switcher = hs.window.switcher.new(windowFilter, {
        showTitles = true,
        showThumbnails = false,  -- No expensive snapshots
        selectedThumbnailSize = 284,
        -- Use shared color scheme for consistency
        backgroundColor = styles.colors.bg,
        highlightColor = styles.colors.text,
        fontName = styles.font.name,
        fontSize = styles.font.size,
    })

    -- Single binding: CMD+TAB cycles through ALL windows smartly
    hs.hotkey.bind({'cmd'}, 'tab', function() 
        switcher:next()
    end)
    
    -- Optional: CMD+Shift+TAB for reverse
    hs.hotkey.bind({'cmd', 'shift'}, 'tab', function() 
        switcher:previous() 
    end)

    log.i("Unified window switcher initialized")
    return true
end

function M.stop()
    switcher = nil
    log.i("Window switcher stopped")
end

return M