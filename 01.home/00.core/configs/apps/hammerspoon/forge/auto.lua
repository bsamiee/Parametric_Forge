-- Title         : auto.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/forge/auto.lua
-- ----------------------------------------------------------------------------
-- Watches config files (yabai/skhd/hammerspoon/yazi) and triggers restarts with OSD

local integ = require("forge.integration")
local osd = require("forge.osd")
local shlib = require("forge.sh")

local M = {}
local log = hs.logger.new("forge.auto", hs.logger.info)

local function sh(cmd)
    return shlib.sh(cmd)
end

-- Debounced runners -------------------------------------------------------
local pending = {}
local function debounce(key, ms, fn)
    local b = pending[key]
    if b and b.timer then
        b.timer:stop()
    end
    b = b or {}
    b.timer = hs.timer.doAfter(ms / 1000, function()
        local ok, err = pcall(fn)
        if not ok then
            log.w("debounce(" .. key .. ") error: " .. tostring(err))
        end
    end)
    pending[key] = b
end

-- Restart helpers ---------------------------------------------------------
local function restartYabai()
    sh("yabai --restart-service || true")
    osd.show("Yabai restarted", { duration = 1.0 })
    -- Borders depends on yabai; ensure it is running again
    integ.ensureBorders({ forceRestart = true })
end

local function reloadSkhd()
    sh("skhd --reload || skhd --restart-service || true")
    osd.show("skhd reloaded", { duration = 1.0 })
end

local function reloadHammerspoon()
    osd.show("Hammerspoon reloading…", { duration = 0.8 })
    hs.reload()
end

local function notifyYazi()
    osd.show("Yazi config updated", { duration = 1.0 })
end

-- Watchers ---------------------------------------------------------------
local watchers = {}

local function normalizePaths(paths)
    local out = {}
    local home = os.getenv("HOME")
    for _, p in ipairs(paths) do
        if p:sub(1, 1) == "/" then
            table.insert(out, p)
        else
            local abs = hs.fs.pathToAbsolute(p) or (home .. "/" .. p)
            table.insert(out, abs)
        end
    end
    return out
end

local function addWatcher(paths, key, onChange)
    local w = hs.pathwatcher.new(normalizePaths(paths), function(files, flags)
        debounce(key, 250, onChange)
    end)
    table.insert(watchers, w)
    w:start()
end

function M.start()
    local home = os.getenv("HOME")
    -- Yabai configs (home)
    addWatcher({ home .. "/.config/yabai/" }, "yabai", restartYabai)

    -- skhd config (home)
    addWatcher({ home .. "/.config/skhd/" }, "skhd", reloadSkhd)

    -- Hammerspoon config dir (active one)
    local hsConfigDir = (type(hs.configdir) == "function") and hs.configdir() or hs.configdir
    addWatcher({ hsConfigDir }, "hs", reloadHammerspoon)

    -- Yazi config (home)
    addWatcher({ home .. "/.config/yazi/" }, "yazi", notifyYazi)

    log.i("forge.auto watchers started")
end

-- Export helpers for reuse (palette actions)
M.restartYabai = restartYabai
M.reloadSkhd = reloadSkhd
M.reloadHammerspoon = reloadHammerspoon

return M
