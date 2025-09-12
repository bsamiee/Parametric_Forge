-- Title         : space_indicator.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/modules/space_indicator.lua
-- ----------------------------------------------------------------------------
-- Simple menubar space indicator using reliable hs.spaces.watcher (proven working pattern)

local process = require("utils.process")
local config = require("utils.config")
local styles = require("notifications.styles")

local M = {}
local log = hs.logger.new("space_indicator", hs.logger.info)

local menuItem
local spacesWatcher

-- Use shared colors from styles (matching forge-backup pattern)
local CYAN = styles.menubarColors.cyan
local YELLOW = styles.menubarColors.yellow
local WHITE = styles.menubarColors.white

local function updateDisplay()
    if not menuItem then return end

    -- Get current space info from yabai (using direct hs.execute like working version)
    local json = hs.execute(config.getYabaiPath() .. " -m query --spaces 2>/dev/null", true)
    if not json or not json:match("^%s*%[") then
        menuItem:setTitle("[?]")
        return
    end

    local ok, spaces = pcall(hs.json.decode, json)
    if not ok or type(spaces) ~= "table" then
        menuItem:setTitle("[?]")
        return
    end

    -- Find focused space and its display
    local focusedSpace, displayId
    for _, space in ipairs(spaces) do
        if space["has-focus"] then
            focusedSpace = space
            displayId = space.display
            break
        end
    end

    if not focusedSpace then
        menuItem:setTitle("[?]")
        return
    end

    -- Get all spaces for the focused display, sorted by index
    local displaySpaces = {}
    for _, space in ipairs(spaces) do
        if space.display == displayId and not space["is-native-fullscreen"] then
            table.insert(displaySpaces, space)
        end
    end
    table.sort(displaySpaces, function(a, b) return a.index < b.index end)

    -- Build display: "1 2 [ 3 ] 4" with styled text (exact forge-backup pattern)
    if hs.styledtext then
        local styled = hs.styledtext.new("")
        for i, space in ipairs(displaySpaces) do
            local num = tostring(i)

            if space["has-focus"] then
                -- Focused space: yellow brackets with spaces, cyan number
                styled = styled .. hs.styledtext.new("[ ", YELLOW)
                styled = styled .. hs.styledtext.new(num, CYAN)
                styled = styled .. hs.styledtext.new(" ]", YELLOW)
            else
                -- Inactive space: white number only
                styled = styled .. hs.styledtext.new(num, WHITE)
            end

            if i < #displaySpaces then
                styled = styled .. hs.styledtext.new(" ", WHITE)
            end
        end
        menuItem:setTitle(styled)
    else
        -- Fallback without styling
        local parts = {}
        for i, space in ipairs(displaySpaces) do
            table.insert(parts, space["has-focus"] and ("[ " .. i .. " ]") or tostring(i))
        end
        menuItem:setTitle(table.concat(parts, " "))
    end
end

function M.init()
    if menuItem then return end

    menuItem = hs.menubar.new()
    if not menuItem then
        log.e("Failed to create space indicator menubar item")
        return false
    end

    menuItem:setTitle("[1]")

    -- Watch for space changes using hs.spaces.watcher (proven working pattern from forge-backup)
    if hs.spaces and hs.spaces.watcher and hs.spaces.watcher.new then
        spacesWatcher = hs.spaces.watcher.new(updateDisplay)
        spacesWatcher:start()
    end

    -- Initial update
    updateDisplay()

    log.i("Space indicator initialized")
    return true
end

function M.stop()
    if spacesWatcher then
        spacesWatcher:stop()
        spacesWatcher = nil
    end
    if menuItem then
        menuItem:delete()
        menuItem = nil
    end
    log.i("Space indicator stopped")
end

return M
