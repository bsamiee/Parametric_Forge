-- Title         : leaders.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/forge/leaders.lua
-- ----------------------------------------------------------------------------
-- Leader key detection and OSD notifications for Karabiner-Elements leaders

local osd = require("forge.osd")

local M = {}

-- Presentable labels for leader names coming from Karabiner URL events
local leaderMeta = {
    hyper = { symbol = "⌘⌥⌃⇧", name = "Hyper" },
    super = { symbol = "⌘⌥⌃", name = "Super" },
    power = { symbol = "⌥⌃⇧", name = "Power" },
}

local bound = false
local tap = nil
local currentLeader = nil

local function labelFor(name)
    local meta = name and leaderMeta[name]
    if not meta then return nil end
    return string.format("%s %s", meta.symbol, meta.name)
end

local function setLeaderActive(name, isDown)
    -- Normalize transitions and avoid duplicate draw/hide
    if isDown then
        if currentLeader ~= name then
            if currentLeader then osd.hidePersistent("leader_" .. currentLeader) end
            local label = labelFor(name)
            if label then osd.showPersistent("leader_" .. name, label) end
            currentLeader = name
        end
    else
        if currentLeader == name then
            osd.hidePersistent("leader_" .. name)
            currentLeader = nil
        else
            -- Defensive: ensure no stale overlays
            if name then osd.hidePersistent("leader_" .. name) end
        end
    end
end

local function leaderFromFlags(flags)
    local f = flags or {}
    local cmd = f.cmd or false
    local alt = f.alt or f.option or false
    local ctrl = f.ctrl or false
    local shift = f.shift or false
    -- Prefer highest cardinality: Hyper > Super > Power(Meh)
    if cmd and alt and ctrl and shift then return "hyper" end
    if cmd and alt and ctrl and (not shift) then return "super" end
    if (not cmd) and alt and ctrl and shift then return "power" end
    return nil
end

local function onLeaderEvent(_, params)
    local name = params and params.name or nil
    local down = params and params.down == "1"
    if not name or not leaderMeta[name] then
        return
    end
    setLeaderActive(name, down)
end

function M.start()
    if bound then
        return
    end
    hs.urlevent.bind("forge/leader", onLeaderEvent)
    -- Lightweight, robust detection via flagsChanged to avoid URL handling issues
    tap = hs.eventtap.new({ hs.eventtap.event.types.flagsChanged }, function(ev)
        local nextLeader = leaderFromFlags(ev:getFlags())
        if nextLeader ~= currentLeader then
            -- Hide previous overlay (if any)
            if currentLeader then osd.hidePersistent("leader_" .. currentLeader) end
            currentLeader = nil
            -- Show new overlay (if any)
            if nextLeader then
                local label = labelFor(nextLeader)
                if label then osd.showPersistent("leader_" .. nextLeader, label) end
                currentLeader = nextLeader
            end
        end
        return false
    end)
    tap:start()
    bound = true
end

function M.stop()
    -- hs.urlevent.bind cannot be unbound individually; leaving bound is OK.
    -- Hide any visible overlays
    if tap then pcall(function() tap:stop() end) tap = nil end
    if currentLeader then osd.hidePersistent("leader_" .. currentLeader) end
    for k, _ in pairs(leaderMeta) do osd.hidePersistent("leader_" .. k) end
    currentLeader = nil
end

return M
