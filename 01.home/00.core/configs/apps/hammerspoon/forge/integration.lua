-- Title         : integration.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/forge/integration.lua
-- ----------------------------------------------------------------------------
-- Yabai state watchers and coordination (borders managed exclusively by yabai)

local M = {}
local log = hs.logger.new("forge.integr", hs.logger.info)
local shlib = require("forge.sh")

-- Borders lifecycle is handled by yabai (see yabairc). No HS management.

-- Watch for yabai state changes and coordinate with Hammerspoon
function M.watchYabaiState()
    -- Observe yabai state files in temp locations (/tmp and $TMPDIR), but keep callbacks
    -- extremely selective and debounced to avoid unnecessary work.
    local dirs = {}
    local sysTmp = "/tmp/"
    local envTmp = os.getenv("TMPDIR")
    if envTmp and #envTmp > 0 then
        if not envTmp:match("/$") then envTmp = envTmp .. "/" end
        if hs.fs.attributes(envTmp) then table.insert(dirs, envTmp) end
    end
    if hs.fs.attributes(sysTmp) then table.insert(dirs, sysTmp) end
    if #dirs == 0 then
        log.w("Unable to access temp directories for yabai state watching")
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

    local watchers = {}
    local function startWatcher(dir)
        local w = hs.pathwatcher.new(dir, function(files, _)
            if not shlib.isProcessRunning("yabai") then return end
            for _, file in ipairs(files) do
                local name = file:match("([^/]+)$") or file
                if name == "yabai_drop.json" then
                    coalesce(file, function() handleDrop(file) end)
                elseif name == "yabai_state.json" then
                    coalesce(file, function() handleState(file) end)
                end
            end
        end)
        w:start()
        table.insert(watchers, w)
        log.d("yabai state watcher started at: " .. dir)
    end
    for _, d in ipairs(dirs) do startWatcher(d) end
end

return M
