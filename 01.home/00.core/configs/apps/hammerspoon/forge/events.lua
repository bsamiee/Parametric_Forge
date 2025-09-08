-- Title         : events.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/forge/events.lua
-- ----------------------------------------------------------------------------
-- Window/space/screen/wake event subscriptions and handlers
local policy = require("forge.policy")

local M = {}
local log = hs.logger.new("forge.events", hs.logger.info)

-- Spaces watcher -----------------------------------------------------------
local function onSpacesEvent()
    -- Normalize active spaces across displays
    local ok, active = pcall(hs.spaces.activeSpaces)
    if ok and type(active) == "table" then
        for _, spaceId in pairs(active) do
            policy.applySpacePolicy(spaceId)
        end
    end
end

-- Window filter ------------------------------------------------------------
local wf = hs.window.filter.new()
wf:setDefaultFilter({ visible = true })

local function handleCreated(win)
    policy.applyWindowPolicy(win)
end

local function handleMoved(win)
    -- Debounce is in executor; we just re-apply float small windows if needed
    policy.applyWindowPolicy(win)
end

local function handleResized(win)
    policy.applyWindowPolicy(win)
end

local function handleTitleChanged(win)
    -- Some title-based rules (e.g. Arc notifications) apply here
    policy.applyWindowPolicy(win)
end

local function handleUnminimized(win)
    policy.applyWindowPolicy(win)
end

function M.start()
    -- Windows
    wf:subscribe(hs.window.filter.windowCreated, handleCreated)
    wf:subscribe(hs.window.filter.windowMoved, handleMoved)
    wf:subscribe(hs.window.filter.windowResized, handleResized)
    wf:subscribe(hs.window.filter.windowTitleChanged, handleTitleChanged)
    wf:subscribe(hs.window.filter.windowUnminimized, handleUnminimized)

    -- Spaces
    M.spacesWatcher = hs.spaces.watcher.new(onSpacesEvent)
    M.spacesWatcher:start()

    -- Displays
    M.screenWatcher = hs.screen.watcher.new(function()
        onSpacesEvent()
    end)
    M.screenWatcher:start()

    -- After wake
    M.caff = hs.caffeinate.watcher.new(function(event)
        if event == hs.caffeinate.watcher.systemDidWake then
            onSpacesEvent()
        end
    end)
    M.caff:start()

    -- Initial normalize pass (active spaces only)
    onSpacesEvent()

    log.i("forge.events started")
end

return M
