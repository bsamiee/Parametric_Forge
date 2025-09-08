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
local function safeActiveSpaces()
    if not hs.spaces or not hs.spaces.activeSpaces then return nil end
    local ok, res = pcall(function() return hs.spaces.activeSpaces() end)
    return ok and res or nil
end

local function onSpacesEvent()
    -- Normalize active spaces across displays (guard older builds without hs.spaces)
    local active = safeActiveSpaces()
    if active and type(active) == "table" then
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

-- Note: removed explicit resize handler; windowMoved covers resize in hs.window.filter

local function handleTitleChanged(win)
    -- Some title-based rules (e.g. Arc notifications) apply here
    policy.applyWindowPolicy(win)
end

local function handleUnminimized(win)
    policy.applyWindowPolicy(win)
end

function M.start()
    -- Windows
    -- Use literal event names for broader compatibility across HS versions
    wf:subscribe("windowCreated", handleCreated)
    -- windowMoved also covers resize events in hs.window.filter
    wf:subscribe("windowMoved", handleMoved)
    wf:subscribe("windowTitleChanged", handleTitleChanged)
    wf:subscribe("windowUnminimized", handleUnminimized)

    -- Spaces (only if available in this Hammerspoon build)
    if hs.spaces and hs.spaces.watcher and hs.spaces.watcher.new then
        M.spacesWatcher = hs.spaces.watcher.new(onSpacesEvent)
        M.spacesWatcher:start()
    end

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
