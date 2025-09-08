-- Title         : integration.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/forge/integration.lua
-- ----------------------------------------------------------------------------
-- Borders lifecycle, Yabai state watchers, and coordination

local M = {}
local log = hs.logger.new("forge.integr", hs.logger.info)
local shlib = require("forge.sh")

local function yabaiReady()
    return shlib.isYabaiReady()
end

local function bordersRunning()
    return shlib.isProcessRunning("borders")
end

local function findBordersBin()
    if hs.fs.attributes("/opt/homebrew/bin/borders") then
        return "/opt/homebrew/bin/borders"
    end
    if hs.fs.attributes("/usr/local/bin/borders") then
        return "/usr/local/bin/borders"
    end
    local out = shlib.sh("command -v borders 2>/dev/null | head -n1 | tr -d '\n'")
    if out and #out > 0 then
        return out
    end
    return nil
end

local function startBorders()
    local home = os.getenv("HOME")
    local rc = home .. "/.config/borders/bordersrc"
    local bin = findBordersBin()
    if bin then
        local cmd
        if hs.fs.attributes(rc) then
            cmd = string.format("'%s' --config '%s' >/dev/null 2>&1 &", bin, rc)
        else
            cmd = string.format("'%s' >/dev/null 2>&1 &", bin)
        end
        shlib.sh(cmd)
        log.i("borders started (binary)")
        local osd = require("forge.osd")
        osd.show("Borders started", { duration = 0.8 })
    elseif hs.fs.attributes(rc) then
        -- Last resort: execute rc if it's a wrapper script and executable
        shlib.sh(string.format("[ -x '%s' ] && '%s' >/dev/null 2>&1 &", rc, rc))
        log.i("borders started (rc)")
        local osd = require("forge.osd")
        osd.show("Borders started", { duration = 0.8 })
    else
        log.w("borders not found; skipping start")
    end
end

local function killBorders()
    shlib.sh("pkill -x borders >/dev/null 2>&1 || true")
    local osd = require("forge.osd")
    osd.show("Borders stopped", { duration = 0.6 })
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
        if forceRestart and bordersRunning() then
            killBorders()
        end
        if not bordersRunning() then
            startBorders()
        end
    end

    step()
end

-- Monitor yabai PID and restart borders after yabai restarts
function M.watchYabaiRestart()
    local last = nil
    hs.timer.doEvery(2, function()
        local pid = shlib.sh("pgrep -x yabai | head -n1 | tr -d '\n'")
        if pid and #pid > 0 then
            if last == nil then
                last = pid
                return
            end
            if pid ~= last then
                last = pid
                M.ensureBorders({ forceRestart = true })
                -- refresh scripting-addition availability state
                local exec = require("forge.executor")
                exec.refreshSa()
                local osd = require("forge.osd")
                osd.show("Yabai restarted (PID change)", { duration = 0.8 })
            end
        end
    end)
end

-- Periodically ensure borders is running when yabai is ready
function M.watchBorders()
    hs.timer.doEvery(10, function()
        if yabaiReady() and not bordersRunning() then
            startBorders()
        end
    end)
end

-- Watch for yabai state changes and coordinate with Hammerspoon
function M.watchYabaiState()
    -- Ensure /tmp directory exists and is accessible
    if not hs.fs.attributes("/tmp") then
        log.w("Unable to access /tmp directory for yabai state watching")
        return
    end
    
    local stateWatcher = hs.pathwatcher.new("/tmp/", function(files, flagTables)
        for i, file in ipairs(files) do
            if file:match("yabai_.*%.json$") then
                log.d("yabai state change detected: " .. file)
                -- Surface actionable OSD for known state files
                if file:match("yabai_drop%.json$") then
                    local f = io.open(file, "r")
                    local txt = f and f:read("*a") or nil
                    if f then f:close() end
                    if txt and (#txt > 0) and (txt:find("^{") or txt:find("^%[")) then
                        local ok, data = pcall(hs.json.decode, txt)
                        if ok and data and data.drop then
                            local msg = (data.drop == "stack") and "Drop: Stack" or "Drop: Swap"
                            if msg then
                                local osd = require("forge.osd")
                                osd.show(msg, { duration = 1.0 })
                            end
                        end
                    end
                elseif file:match("yabai_state%.json$") then
                    local f2 = io.open(file, "r")
                    local txt2 = f2 and f2:read("*a") or nil
                    if f2 then f2:close() end
                    if txt2 and (#txt2 > 0) and (txt2:find("^{") or txt2:find("^%[")) then
                        local ok2, data = pcall(hs.json.decode, txt2)
                        if ok2 and data and data.mode then
                            local osd = require("forge.osd")
                            osd.show("Layout: " .. tostring(data.mode), { duration = 1.0 })
                        end
                    end
                end
            end
        end
    end)
    stateWatcher:start()
    log.d("yabai state watcher started")
end

return M
