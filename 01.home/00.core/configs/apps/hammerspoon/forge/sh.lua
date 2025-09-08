-- Title         : sh.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/forge/sh.lua
-- ----------------------------------------------------------------------------
-- Centralized shell helpers: PATH, sh(), yabai(), readiness/SA checks

local M = {}

M.PATH = "/opt/homebrew/bin:/usr/local/bin:/run/current-system/sw/bin:" .. os.getenv("PATH")

function M.sh(cmd)
  return hs.execute("/usr/bin/env PATH='" .. M.PATH .. "' sh -lc '" .. cmd .. "'", true)
end

function M.yabai(args)
  return M.sh("yabai -m " .. args)
end

function M.isYabaiReady()
  local out = M.sh("yabai -m query --windows >/dev/null 2>&1; echo $?")
  return out and out:match("^0") ~= nil
end

function M.isProcessRunning(name)
  local out = M.sh("pgrep -x '" .. name .. "' >/dev/null 2>&1; echo $?")
  return out and out:match("^0") ~= nil
end

function M.isSaAvailable()
  local out = M.sh("[ -d /Library/ScriptingAdditions/yabai.osax ] && echo yes || echo no")
  return out and out:match("yes") ~= nil
end

return M

