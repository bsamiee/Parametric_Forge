-- Title         : window_picker.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/forge/window_picker.lua
-- ----------------------------------------------------------------------------
-- CMD+TAB replacement with window previews, space indicators, and window actions

local core = require("forge.core")
local osd = require("forge.osd")

local M = {}
local log = hs.logger.new("forge.picker", hs.logger.info)

local chooser
local actionHotkeys = {}

-- Get space info for window using existing core.yabai infrastructure
local function getWindowSpaceInfo(win)
    if not win then return "?", "" end

    local winId = win:id()
    local json = core.yabai("query --windows --window " .. winId .. " 2>/dev/null")
    if not json or not json:match("^%s*{") then
        return "?", ""
    end

    local ok, data = pcall(hs.json.decode, json)
    if not ok or not data or not data.space then
        return "?", ""
    end

    -- Get space label if available
    local spaceJson = core.yabai("query --spaces --space " .. data.space .. " 2>/dev/null")
    if spaceJson and spaceJson:match("^%s*{") then
        local spaceOk, spaceData = pcall(hs.json.decode, spaceJson)
        if spaceOk and spaceData and spaceData.label and #spaceData.label > 0 then
            return tostring(data.space), spaceData.label
        end
    end

    return tostring(data.space), ""
end

-- Create choice data for hs.chooser
local function createChoice(win, index)
    if not win then return nil end

    local app = win:application()
    local appName = app and app:name() or "Unknown"
    local title = win:title() or "Untitled"

    -- Get space info using existing infrastructure
    local spaceNum, spaceLabel = getWindowSpaceInfo(win)
    local spaceDisplay = spaceLabel ~= "" and (spaceNum .. "•" .. spaceLabel) or spaceNum

    -- Use window snapshot as image (key feature for thumbnails)
    local image = nil
    pcall(function() 
        image = win:snapshot()
        -- Resize snapshot to reasonable chooser size
        if image and image.setSize then
            image = image:setSize({ w = 64, h = 48 })
        end
    end)

    return {
        text = title,
        subText = appName .. " • Space " .. spaceDisplay,
        image = image, -- Window thumbnail, not app icon
        window = win,
        uuid = "win_" .. tostring(win:id()),
    }
end

-- Get all windows from current space only
local function getCurrentSpaceWindows()
    local allWindows = hs.window.orderedWindows()
    local filtered = {}

    -- Filter to current space only using yabai
    local currentSpaceJson = core.yabai("query --spaces --space 2>/dev/null")
    if not currentSpaceJson or not currentSpaceJson:match("^%s*{") then
        return filtered
    end

    local ok, currentSpace = pcall(hs.json.decode, currentSpaceJson)
    if not ok or not currentSpace or not currentSpace.index then
        return filtered
    end

    for _, win in ipairs(allWindows) do
        if win and win:isStandard() and win:isVisible() then
            local spaceNum, _ = getWindowSpaceInfo(win)
            if spaceNum == tostring(currentSpace.index) then
                table.insert(filtered, win)
            end
        end
    end

    return filtered
end

-- Window action handlers
local function performWindowAction(action)
    if not chooser or not chooser:isVisible() then return end

    local selected = chooser:selectedRowContents()
    if not selected or not selected.window then return end

    local win = selected.window
    if action == "close" then
        win:close()
    elseif action == "minimize" then
        win:minimize()
    elseif action == "hide" then
        win:application():hide()
    elseif action == "maximize" then
        win:maximize()
    end

    chooser:hide()
    osd.show(action:gsub("^%l", string.upper) .. ": " .. (win:title() or "window"))
end

-- Setup window action hotkeys (only active when chooser visible)
local function setupActionHotkeys()
    if #actionHotkeys > 0 then return end -- Already setup

    actionHotkeys = {
        hs.hotkey.bind({}, "w", nil, function() performWindowAction("close") end),
        hs.hotkey.bind({}, "q", nil, function() performWindowAction("minimize") end), 
        hs.hotkey.bind({}, "h", nil, function() performWindowAction("hide") end),
        hs.hotkey.bind({}, "m", nil, function() performWindowAction("maximize") end),
    }

    -- Disable hotkeys by default
    for _, hk in ipairs(actionHotkeys) do
        hk:disable()
    end
end

-- Show window picker
function M.show()
    if not chooser then
        chooser = hs.chooser.new(function(choice)
            if choice and choice.window then
                choice.window:focus()
            end
        end)

        -- Configure with Dracula theme using existing color system
        chooser:bgDark(true)
        chooser:fgColor(hs.drawing.color.x11.white)
        chooser:subTextColor(hs.drawing.color.x11.lightgray)
        chooser:width(25) -- Wider for thumbnails
        chooser:rows(6)
        chooser:placeholderText("Select window... (w=close q=minimize h=hide m=maximize)")

        -- Enable window actions when shown, disable when hidden
        chooser:showCallback(function() 
            for _, hk in ipairs(actionHotkeys) do hk:enable() end 
        end)
        chooser:hideCallback(function() 
            for _, hk in ipairs(actionHotkeys) do hk:disable() end 
        end)
    end

    setupActionHotkeys()

    -- Get current space windows and create choices
    local windows = getCurrentSpaceWindows()
    local choices = {}

    for i, win in ipairs(windows) do
        local choice = createChoice(win, i)
        if choice then
            table.insert(choices, choice)
        end
    end

    if #choices == 0 then
        osd.show("No windows in current space")
        return
    end

    chooser:choices(choices)
    chooser:show()
end

function M.hide()
    if chooser then
        chooser:hide()
    end
end

return M