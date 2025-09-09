-- Title         : caffeine.lua
-- Author        : Parametric Forge
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/forge/caffeine.lua
-- ----------------------------------------------------------------------------
-- Classic Caffeine-style display sleep inhibitor using Hammerspoon's hs.caffeinate.
-- No external apps required.

local M = {}

local osd = require("forge.osd")

local menubar
local STATE_KEY = "forge.caffeine.displayIdle"

local function isEnabled()
  local ok, val = pcall(hs.caffeinate.get, "displayIdle")
  if ok and type(val) == "boolean" then return val end
  -- fall back to stored state when API unavailable
  return hs.settings.get(STATE_KEY) == true
end

local function setEnabled(on)
  -- best-effort apply through hs.caffeinate
  pcall(hs.caffeinate.set, "displayIdle", on, true)
  hs.settings.set(STATE_KEY, on)
  if menubar then
    menubar:setTitle(on and "☕︎" or "")
    menubar:setTooltip(on and "Caffeine: Display awake" or "Caffeine: Off")
  end
  osd.show(on and "Caffeine: ON" or "Caffeine: OFF", { duration = 0.8 })
end

local function toggle()
  setEnabled(not isEnabled())
end

local function buildMenu()
  return {
    { title = isEnabled() and "Turn Caffeine Off" or "Turn Caffeine On",
      fn = toggle },
    { title = "-" },
    { title = "Prevent: Display Sleep", checked = isEnabled(), disabled = true },
  }
end

function M.start()
  if menubar then return end
  menubar = hs.menubar.new()
  if not menubar then return end
  menubar:autosaveName("forge-caffeine")
  menubar:setClickCallback(toggle)
  menubar:setMenu(buildMenu)
  setEnabled(isEnabled()) -- sync UI/state
end

function M.stop()
  if menubar then menubar:delete(); menubar = nil end
end

M.toggle = toggle
M.set = setEnabled
M.enabled = isEnabled

return M

