-- Title         : events.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/forge/events.lua
-- ----------------------------------------------------------------------------
-- Window/space/screen/wake event subscriptions and handlers

local policy = require("forge.policy")
local config = require("forge.config")
local exec = require("forge.executor")
local shlib = require("forge.sh")

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

local wf -- created on start only when needed

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
    -- Windows: only subscribe if HS is enforcing float policy
    if config.enforceFloatInHS then
        wf = hs.window.filter.new()
        wf:setDefaultFilter({ visible = true })
        -- Use literal event names for broader compatibility across HS versions
        wf:subscribe("windowCreated", handleCreated)
        -- windowMoved also covers resize events in hs.window.filter
        wf:subscribe("windowMoved", handleMoved)
        wf:subscribe("windowTitleChanged", handleTitleChanged)
        wf:subscribe("windowUnminimized", handleUnminimized)
    end

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
            -- Normalize spaces
            onSpacesEvent()
            -- Refresh SA availability and re-apply minor visuals (if applicable)
            exec.refreshSa()
            if shlib.isProcessRunning("yabai") and exec.sa.available then
                shlib.sh("yabai -m config window_opacity_duration 0.25")
            end
        end
    end)
    M.caff:start()

    -- Initial normalize pass (active spaces only)
    onSpacesEvent()

    log.i("forge.events started")
end

return M
