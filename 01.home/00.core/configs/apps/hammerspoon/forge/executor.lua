-- Title         : executor.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/forge/executor.lua
-- ----------------------------------------------------------------------------
-- Debounced Yabai command execution with SA-awareness and grid
local config = require("forge.config")
local state = require("forge.state")

local M = {}

local PATH = "/opt/homebrew/bin:/usr/local/bin:/run/current-system/sw/bin:" .. os.getenv("PATH")
local function sh(cmd)
    return hs.execute("/usr/bin/env PATH='" .. PATH .. "' sh -lc '" .. cmd .. "'", true)
end

local log = hs.logger.new("forge.exec", hs.logger.info)

local dryRun = true
function M.setDryRun(b)
    dryRun = b and true or false
end
function M.isDryRun()
    return dryRun
end

local function saAvailable()
    local out = sh("[ -d /Library/ScriptingAdditions/yabai.osax ] && echo yes || echo no")
    return out and out:match("yes") ~= nil
end

M.sa = { available = saAvailable() }

local function yabai(cmd)
    local full = "yabai -m " .. cmd
    if dryRun then
        log.d("DRY: " .. full)
        return "", "", 0
    else
        local out = sh(full)
        return out
    end
end

local function getWindowInfo(winId)
    local out = sh(string.format("yabai -m query --windows --window %d 2>/dev/null", winId))
    if not out or #out == 0 then
        return nil
    end
    local ok, obj = pcall(hs.json.decode, out)
    if ok then
        return obj
    end
    return nil
end

local function getSpaces()
    local out = sh("yabai -m query --spaces 2>/dev/null")
    if not out or #out == 0 then
        return {}
    end
    local ok, arr = pcall(hs.json.decode, out)
    if ok and type(arr) == "table" then
        return arr
    end
    return {}
end

local function spaceIdToIndex(spaceId)
    local arr = getSpaces()
    for _, s in ipairs(arr) do
        if s.id == spaceId then
            return s.index
        end
    end
    return nil
end

local function applyGrid(winId, anchor)
    if not config.gridScript or #config.gridScript == 0 then
        return
    end
    local cmd = string.format("'%s' %s --window %d", config.gridScript, anchor, winId)
    if dryRun then
        log.d("DRY: grid " .. cmd)
    else
        sh(cmd)
    end
end

-- Coalesce window ops per winId and flush after debounce
local function scheduleWindow(winId, ms, fn)
    local bucket = state.pending.window[winId]
    if bucket and bucket.timer then
        bucket.timer:stop()
    end
    bucket = bucket or { ops = {} }
    bucket.timer = hs.timer.doAfter(ms / 1000, function()
        local ok, err = pcall(fn)
        if not ok then
            log.w("window flush error: " .. tostring(err))
        end
    end)
    state.pending.window[winId] = bucket
end

local function scheduleSpace(spaceId, ms, fn)
    local bucket = state.pending.space[spaceId]
    if bucket and bucket.timer then
        bucket.timer:stop()
    end
    bucket = bucket or { ops = {} }
    bucket.timer = hs.timer.doAfter(ms / 1000, function()
        local ok, err = pcall(fn)
        if not ok then
            log.w("space flush error: " .. tostring(err))
        end
    end)
    state.pending.space[spaceId] = bucket
end

-- Public API ---------------------------------------------------------------

function M.windowFloat(winId, shouldFloat)
    scheduleWindow(winId, config.debounce.window, function()
        if shouldFloat then
            local info = getWindowInfo(winId)
            if not info or info["is-floating"] ~= true then
                yabai(string.format("window %d --toggle float", winId))
            end
        end
    end)
end

function M.windowSticky(winId, sticky)
    if not M.sa.available then
        return
    end
    scheduleWindow(winId, config.debounce.window, function()
        if sticky then
            local info = getWindowInfo(winId)
            if not info or info["is-sticky"] ~= true then
                yabai(string.format("window %d --toggle sticky", winId))
            end
        end
    end)
end

function M.windowSubLayer(winId, layer)
    if not M.sa.available then
        return
    end
    if layer ~= "above" and layer ~= "below" and layer ~= "normal" then
        return
    end
    scheduleWindow(winId, config.debounce.window, function()
        yabai(string.format("window %d --sub-layer %s", winId, layer))
    end)
end

function M.windowGrid(winId, anchor)
    scheduleWindow(winId, config.debounce.window, function()
        applyGrid(winId, anchor)
    end)
end

function M.normalizeSpace(spaceId)
    scheduleSpace(spaceId, config.debounce.space, function()
        local idx = spaceIdToIndex(spaceId)
        if idx then
            yabai(string.format("space %d --layout %s", idx, config.space.layout))
            if config.space.autoBalance then
                yabai(string.format("space %d --balance", idx))
            end
        end
        state.spaceEntry(spaceId).lastNormalizedAt = hs.timer.absoluteTime()
    end)
end

return M
