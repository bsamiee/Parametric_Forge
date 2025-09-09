-- Title         : leaders.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/forge/leaders.lua
-- ----------------------------------------------------------------------------
-- Leader key detection and OSD notifications for Karabiner-Elements leaders

local osd = require("forge.osd")

local M = {}

-- Leader key definitions matching karabiner.edn
local leaders = {
  hyper = { mods = {"cmd", "alt", "ctrl", "shift"}, symbol = "⌘⌥⌃⇧", name = "Hyper" },
  super = { mods = {"cmd", "alt", "ctrl"},           symbol = "⌘⌥⌃",   name = "Super" },
  power = { mods = {"alt", "ctrl", "shift"},         symbol = "⌥⌃⇧",   name = "Power" }
}

-- Track active leader states
local activeLeaders = {}
local leaderTimers = {}

-- Check if specific modifier combination is active
local function checkLeaderActive(leader)
  local currentMods = hs.eventtap.checkKeyboardModifiers()
  if not currentMods then return false end

  local requiredMods = leader.mods
  local allRequired = true

  -- Check all required modifiers are pressed
  for _, mod in ipairs(requiredMods) do
    if not currentMods[mod] then
      allRequired = false
      break
    end
  end

  if not allRequired then return false end

  -- Check no extra modifiers are pressed (exact match)
  for mod, pressed in pairs(currentMods) do
    if pressed then
      local found = false
      for _, required in ipairs(requiredMods) do
        if mod == required then
          found = true
          break
        end
      end
      if not found then
        return false  -- Extra modifier found
      end
    end
  end

  return true
end

-- Show OSD notification for leader
local function showLeaderNotification(leaderName, leader)
  local message = string.format("%s %s - active", leader.symbol, leader.name)
  osd.show(message, {
    duration = 0.8,
    style = {
      bgColor = { black = 0, alpha = 0.85 },
      textColor = { white = 1, alpha = 1.0 },
      font = { name = "Geist", size = 18 }
    }
  })
end

-- Event tap to monitor modifier changes
local flagsWatcher
local function onModifierChange()
  for leaderName, leader in pairs(leaders) do
    local wasActive = activeLeaders[leaderName] 
    local isActive = checkLeaderActive(leader)

    if isActive and not wasActive then
      -- Leader just became active
      activeLeaders[leaderName] = true

      -- Cancel any existing timer for this leader
      if leaderTimers[leaderName] then
        leaderTimers[leaderName]:stop()
        leaderTimers[leaderName] = nil
      end

      -- Show notification after brief delay to avoid spam
      leaderTimers[leaderName] = hs.timer.doAfter(0.1, function()
        if activeLeaders[leaderName] then  -- Still active
          showLeaderNotification(leaderName, leader)
        end
      end)

    elseif not isActive and wasActive then
      -- Leader just became inactive
      activeLeaders[leaderName] = false

      -- Cancel notification timer if pending
      if leaderTimers[leaderName] then
        leaderTimers[leaderName]:stop()
        leaderTimers[leaderName] = nil
      end
    end
  end

  return false -- Don't consume the event
end

function M.start()
  if flagsWatcher then return end

  flagsWatcher = hs.eventtap.new({hs.eventtap.event.types.flagsChanged}, onModifierChange)
  flagsWatcher:start()

  print("Leader key OSD notifications started")
end

function M.stop()
  if flagsWatcher then
    flagsWatcher:stop()
    flagsWatcher = nil
  end

  -- Stop all timers
  for _, timer in pairs(leaderTimers) do
    if timer then timer:stop() end
  end
  leaderTimers = {}
  activeLeaders = {}
end

return M