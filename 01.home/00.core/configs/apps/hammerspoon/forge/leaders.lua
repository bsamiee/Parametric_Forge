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

local function onLeaderEvent(_, params)
    local name = params and params.name or nil
    local down = params and params.down == "1"
    if not name or not leaderMeta[name] then
        return
    end
    local meta = leaderMeta[name]
    if down then
        osd.showPersistent("leader_" .. name, string.format("%s %s", meta.symbol, meta.name))
    else
        osd.hidePersistent("leader_" .. name)
    end
end

function M.start()
    if bound then
        return
    end
    hs.urlevent.bind("forge/leader", onLeaderEvent)
    bound = true
end

function M.stop()
    -- hs.urlevent.bind cannot be unbound individually; leaving bound is OK.
    -- Hide any visible overlays
    for k, _ in pairs(leaderMeta) do
        osd.hidePersistent("leader_" .. k)
    end
end

return M
