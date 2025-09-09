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
    -- Observe yabai state files in the system temp dir, but keep the callback
    -- extremely selective and debounced to avoid unnecessary work.
    local tmpdir = os.getenv("TMPDIR") or "/tmp/"
    if not tmpdir:match("/$") then tmpdir = tmpdir .. "/" end
    if not hs.fs.attributes(tmpdir) then
        log.w("Unable to access temp directory for yabai state watching: " .. tostring(tmpdir))
        return
    end

    local osd = require("forge.osd")
    local debounce = {}
    local function coalesce(path, fn)
        -- Coalesce rapid successive updates per path within 120ms
        if debounce[path] then debounce[path]:stop() end
        debounce[path] = hs.timer.doAfter(0.12, function()
            pcall(fn)
        end)
    end

    local function handleDrop(file)
        local f = io.open(file, "r")
        local txt = f and f:read("*a") or nil
        if f then f:close() end
        if not txt or #txt == 0 then return end
        if not (txt:find("^{") or txt:find("^%[")) then return end
        local ok, data = pcall(hs.json.decode, txt)
        if ok and data and data.drop then
            local msg = (data.drop == "stack") and "Drop: Stack" or (data.drop == "swap" and "Drop: Swap" or nil)
            if msg then osd.show(msg, { duration = 1.0 }) end
        end
    end

    local function handleState(file)
        local f = io.open(file, "r")
        local txt = f and f:read("*a") or nil
        if f then f:close() end
        if not txt or #txt == 0 then return end
        if not (txt:find("^{") or txt:find("^%[")) then return end
        local ok, data = pcall(hs.json.decode, txt)
        if ok and data and data.mode then
            osd.show("Layout: " .. tostring(data.mode), { duration = 1.0 })
        end
    end

    local watcher = hs.pathwatcher.new(tmpdir, function(files, _)
        -- Fast path exit when yabai is not running
        if not shlib.isProcessRunning("yabai") then return end
        for _, file in ipairs(files) do
            local name = file:match("([^/]+)$") or file
            -- React only to known yabai files
            if name == "yabai_drop.json" then
                coalesce(file, function() handleDrop(file) end)
            elseif name == "yabai_state.json" then
                coalesce(file, function() handleState(file) end)
            end
        end
    end)
    watcher:start()
    log.d("yabai state watcher started at: " .. tmpdir)
end

return M
