-- Title         : leader_indicator.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/modules/leader_indicator.lua
-- ----------------------------------------------------------------------------
-- Show a small persistent indicator while leader combos are held:
--   - Hyper: cmd+alt+ctrl+shift  → [HYPER]
--   - Super: cmd+alt+ctrl        → [SUPER]
--   - Power: alt+ctrl+shift      → [POWER]
-- Uses hs.eventtap flagsChanged (read-only) for low overhead.

local M = {}
local log = hs.logger.new("leader_indicator", hs.logger.info)

local persistent = require("notifications.persistent_canvas")

local tap = nil
local current = nil -- one of "HYPER"|"SUPER"|"POWER"|nil

local function labelForFlags(flags)
  -- flags is a table with boolean fields: cmd, alt, ctrl, shift, etc.
  local cmd  = flags.cmd   or false
  local alt  = flags.alt   or false
  local ctrl = flags.ctrl  or false
  local shft = flags.shift or false

  if cmd and alt and ctrl and shft then
    return "HYPER"
  elseif cmd and alt and ctrl and not shft then
    return "SUPER"
  elseif (not cmd) and alt and ctrl and shft then
    return "POWER"
  else
    return nil
  end
end

local function onFlagsChanged(event)
  local flags = event:getFlags() or {}
  local nextState = labelForFlags(flags)
  if nextState == current then return false end -- no change

  current = nextState
  if current then
    persistent.set("leader_hold", { text = string.format("[%s]", current) })
  else
    persistent.remove("leader_hold")
  end

  return false -- do not consume
end

function M.init()
  if tap then return true end

  persistent.init()

  tap = hs.eventtap.new({ hs.eventtap.event.types.flagsChanged }, onFlagsChanged)
  tap:start()

  log.i("Leader indicator initialized")
  return true
end

function M.stop()
  if tap then
    tap:stop()
    tap = nil
  end
  persistent.remove("leader_hold")
  current = nil
  log.i("Leader indicator stopped")
end

return M

