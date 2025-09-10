-- Title         : events.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/forge/events.lua
-- ----------------------------------------------------------------------------
-- Window/space/screen/wake event subscriptions and handlers

local core = require("forge.core")
local exec = require("forge.executor")
local policy = require("forge.policy")
local shlib = require("forge.sh")
local config = core.config

local M = {}
local log = hs.logger.new("forge.events", hs.logger.info)

-- Spaces watcher -----------------------------------------------------------
local function safeActiveSpaces()
    if not hs.spaces or not hs.spaces.activeSpaces then
        return nil
    end
    local ok, res = pcall(function()
        return hs.spaces.activeSpaces()
    end)
    return ok and res or nil
end

local function onSpacesEvent()
    -- Update space overlay UI using live yabai query to avoid stale TMPDIR state
    local cfg = config
    if cfg.ui and cfg.ui.spaceOverlay then
        local label
        -- Prefer a direct query for the current space; this is fast and accurate
        local js = shlib.sh("yabai -m query --spaces --space 2>/dev/null")
        if js and js:match("^[%[{]") then
            local ok, s = pcall(hs.json.decode, js)
            if ok and type(s) == "table" then
                local idx = s.index or "?"
                local mode = s.type or "?"
                label = string.format("Space: %s • %s", tostring(idx), tostring(mode))
            end
        end
        -- Final fallback: scan all spaces for has-focus
        if not label then
            local all = shlib.sh("yabai -m query --spaces 2>/dev/null")
            if all and all:match("^[%[{]") then
                local ok, arr = pcall(hs.json.decode, all)
                if ok and type(arr) == "table" then
                    for _, sp in ipairs(arr) do
                        if sp["has-focus"] then
                            label = string.format("Space: %s • %s", tostring(sp.index or "?"), tostring(sp.type or "?"))
                            break
                        end
                    end
                end
            end
        end
        if not label then label = "Space: ?" end
        local osd = require("forge.osd")
        osd.show(label, { duration = 0.9 })
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
        local osd = require("forge.osd")
        pcall(function() osd.repositionAll() end)
    end)
    M.screenWatcher:start()

    -- After wake
    M.caff = hs.caffeinate.watcher.new(function(event)
        if event == hs.caffeinate.watcher.systemDidWake then
            -- Normalize spaces and ensure overlays are placed correctly after wake
            onSpacesEvent()
            local osd = require("forge.osd")
            pcall(function() osd.repositionAll() end)
            -- Refresh SA availability and re-apply minor visuals (if applicable)
            exec.refreshSa()
            if shlib.isProcessRunning("yabai") and exec.sa.available then
                shlib.sh("yabai -m config window_opacity_duration 0.25")
            end
        end
    end)
    M.caff:start()

    -- Initial normalize pass (active spaces only) — defer slightly to avoid notch/menubar geometry race at launch
    hs.timer.doAfter(0.10, function()
        onSpacesEvent()
    end)

    log.i("forge.events started")
end

return M
