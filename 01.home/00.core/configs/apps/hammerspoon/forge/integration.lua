local M = {}

local PATH = "/opt/homebrew/bin:/usr/local/bin:/run/current-system/sw/bin:" .. os.getenv("PATH")
local log  = hs.logger.new("forge.integr", hs.logger.info)

local function sh(cmd)
  return hs.execute("/usr/bin/env PATH='" .. PATH .. "' sh -lc '" .. cmd .. "'", true)
end

local function yabaiReady()
  local out = sh("yabai -m query --windows >/dev/null 2>&1; echo $?")
  return out and out:match("^0") ~= nil
end

local function bordersRunning()
  local out = sh("pgrep -fx 'borders( .*)?' >/dev/null 2>&1; echo $?")
  return out and out:match("^0") ~= nil
end

local function startBorders()
  local rc = os.getenv("HOME") .. "/.config/borders/bordersrc"
  local cmd = string.format("[ -x '%s' ] && '%s' >/dev/null 2>&1 &", rc, rc)
  sh(cmd)
  log.i("borders started")
end

local function killBorders()
  sh("pkill -fx 'borders( .*)?' >/dev/null 2>&1 || true")
end

-- Public: ensure borders is running and fresh; wait for yabai readiness
function M.ensureBorders(opts)
  opts = opts or {}
  local forceRestart = opts.forceRestart == true

  local function step()
    if not yabaiReady() then
      hs.timer.doAfter(0.5, step)
      return
    end
    if forceRestart and bordersRunning() then killBorders() end
    if not bordersRunning() then startBorders() end
  end

  step()
end

-- Monitor yabai PID and restart borders after yabai restarts
function M.watchYabaiRestart()
  local last = nil
  hs.timer.doEvery(2, function()
    local pid = sh("pgrep -x yabai | head -n1 | tr -d '\n'")
    if pid and #pid > 0 then
      if last == nil then last = pid; return end
      if pid ~= last then
        last = pid
        M.ensureBorders({ forceRestart = true })
      end
    end
  end)
end

-- Watch for yabai state changes and coordinate with Hammerspoon
function M.watchYabaiState()
  local stateWatcher = hs.pathwatcher.new("/tmp/", function(files, flagTables)
    for i, file in ipairs(files) do
      if file:match("yabai_.*%.json$") then
        log.d("yabai state change detected: " .. file)
        -- Could trigger specific responses based on state changes
      end
    end
  end)
  stateWatcher:start()
  log.d("yabai state watcher started")
end

return M
