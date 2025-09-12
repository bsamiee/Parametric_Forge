-- Title         : config_reload.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/forge/config_reload.lua
-- ----------------------------------------------------------------------------
-- Watches config files (yabai/skhd/hammerspoon/yazi) and triggers restarts with OSD

local osd = require("forge.osd")
local core = require("forge.core")

local M = {}
local log = hs.logger.new("forge.config_reload", hs.logger.info)


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
    hs.execute("pkill -f yabai; sleep 1; yabai --start-service || yabai &", true)
    osd.show("Yabai restarted")
end

local function reloadSkhd()
    hs.execute("pkill -f skhd; sleep 1; skhd --start-service || skhd -c ~/.config/skhd/skhdrc &", true)
    osd.show("skhd reloaded")
end

local function reloadHammerspoon()
    osd.show("Hammerspoon reloading…")
    hs.reload()
end

-- Goku (Karabiner EDN watcher) restart/start via Homebrew services
local function restartGoku()
    -- Resolve brew path
    local brew = hs.execute("command -v brew 2>/dev/null | head -n1 | tr -d '\n'", true)
    if not brew or #brew == 0 then
        -- Common Homebrew locations
        if hs.fs.attributes("/opt/homebrew/bin/brew") then
            brew = "/opt/homebrew/bin/brew"
        elseif hs.fs.attributes("/usr/local/bin/brew") then
            brew = "/usr/local/bin/brew"
        end
    end
    if not brew or #brew == 0 then
        osd.show("goku: brew not found")
        return
    end
    -- Try restart, then start
    hs.execute(string.format("'%s' services restart goku >/dev/null 2>&1 || '%s' services start goku >/dev/null 2>&1 || true", brew, brew), true)
    osd.show("goku (watcher) restarted")
end

-- Decide if HS should reload based on changed files (official pattern)
local function shouldReloadHS(files)
    if not files or #files == 0 then
        return false
    end
    for _, f in ipairs(files) do
        -- ignore common non-config changes
        local name = f:match("[^/]+$") or f
        if name:match("^%.") or name == ".DS_Store" or name:match("~$") then
            goto continue
        end
        -- ignore assets by default
        if f:find("/assets/") then
            goto continue
        end
        -- trigger on lua/spoon changes
        if f:match("%.lua$") or f:match("%.spoon/") then
            return true
        end
        ::continue::
    end
    return false
end

local function notifyYazi()
    osd.show("Yazi config updated")
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
    -- Support older Hammerspoon that requires a single string path
    local list = normalizePaths(type(paths) == "table" and paths or { paths })
    for _, p in ipairs(list) do
        local w = hs.pathwatcher.new(p, function(files, flags)
            debounce(key, 250, function()
                pcall(onChange, files, flags)
            end)
        end)
        table.insert(watchers, w)
        w:start()
    end
end

function M.start()
    local home = os.getenv("HOME")
    -- Yabai config file only
    addWatcher({ home .. "/.config/yabai/yabairc" }, "yabai", restartYabai)

    -- skhd config (home)
    addWatcher({ home .. "/.config/skhd/" }, "skhd", reloadSkhd)

    -- Hammerspoon config dir (active one). Only reload on *.lua or .spoon changes.
    local hsConfigDir = (type(hs.configdir) == "function") and hs.configdir() or hs.configdir
    addWatcher({ hsConfigDir }, "hs", function(files)
        if shouldReloadHS(files) then
            reloadHammerspoon()
        end
    end)

    -- Yazi config (home)
    addWatcher({ home .. "/.config/yazi/" }, "yazi", notifyYazi)

    log.i("forge.config_reload watchers started")
    -- Optional: surface a one-time loaded notice when FORGE_DEBUG is set
    if os.getenv("FORGE_DEBUG") == "1" then
        hs.alert.show("Config loaded")
    end
end

-- Export helpers for reuse
M.restartYabai = restartYabai
M.reloadSkhd = reloadSkhd
M.reloadHammerspoon = reloadHammerspoon
M.restartGoku = restartGoku

return M
