-- Title         : integration.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/forge/integration.lua
-- ----------------------------------------------------------------------------
-- Yabai state watchers and coordination (borders managed exclusively by yabai)

local M = {}
local log = hs.logger.new("forge.integr", hs.logger.info)
local core = require("forge.core")

-- Use centralized utilities
local bus = core.bus

-- Borders lifecycle is handled by yabai (see yabairc). No HS management.

-- Watch for yabai state changes and coordinate with Hammerspoon
local _started = false

function M.watchYabaiState()
    if _started then
        return
    end
    -- Observe yabai state files in temp locations (/tmp and $TMPDIR), but keep callbacks
    -- extremely selective and debounced to avoid unnecessary work.
    local dirs = {}
    local sysTmp = "/tmp/"
    local envTmp = os.getenv("TMPDIR")
    if envTmp and #envTmp > 0 then
        if not envTmp:match("/$") then
            envTmp = envTmp .. "/"
        end
        if hs.fs.attributes(envTmp) then
            table.insert(dirs, envTmp)
        end
    end
    if hs.fs.attributes(sysTmp) then
        table.insert(dirs, sysTmp)
    end
    if #dirs == 0 then
        log.w("Unable to access temp directories for yabai state watching")
        return
    end

    local osd = require("forge.osd")
    local debounce = {}
    local last = { mode = nil, drop = nil, gaps = nil, opacity = nil }
    local function coalesce(path, fn)
        -- Coalesce rapid successive updates per path (configurable)
        if debounce[path] then
            debounce[path]:stop()
        end
        local delay = 0.120  -- 120ms debounce (matches core.lua bus timing)
        debounce[path] = hs.timer.doAfter(delay, function()
            pcall(fn)
        end)
    end


    local function handleState(file)
        local f = io.open(file, "r")
        local txt = f and f:read("*a") or nil
        if f then
            f:close()
        end
        if not txt or #txt == 0 then
            return
        end
        if not (txt:find("^{") or txt:find("^%[")) then
            return
        end
        local ok, data = pcall(hs.json.decode, txt)
        if not ok or not data then return end

        -- Detect and notify on changes only (avoid duplicate OSD when toggled via menubar)
        local changed = false

        -- Space navigation with workspace context
        if data.idx and data.idx ~= last.idx then
            last.idx = data.idx
            local label = data.label and #data.label > 0 and data.label or nil
            local message = label and ("Workspace: " .. label:upper()) or ("Space: " .. tostring(data.idx))
            osd.show(message)
            changed = true
        end

        -- Workspace persistent indicator (automatic, lower priority)
        if data.label ~= last.label then
            last.label = data.label
            local label = data.label and #data.label > 0 and data.label or nil
            if label then
                osd.showPersistent("[ " .. label:upper() .. " ]", "workspace")
            else
                osd.hidePersistent("workspace")
            end
            changed = true
        end

        -- Layout mode
        if data.mode and data.mode ~= last.mode then
            last.mode = data.mode
            osd.show("Layout: " .. ((data.mode == "bsp") and "BSP" or "Stack"))
            changed = true
        end

        -- Drop action
        if data.drop and data.drop ~= last.drop then
            last.drop = data.drop
            local msg = (data.drop == "stack") and "Drop: Stack" or "Drop: Swap"
            osd.show(msg)
            changed = true
        end

        -- Gaps (numeric padding > 0 -> Enabled)
        if data.gaps ~= nil then
            local g = tonumber(data.gaps)
            local gapsOn = g and g > 0 or false
            local lastOn = last.gaps and true or false
            if gapsOn ~= lastOn then
                last.gaps = gapsOn
                osd.show("Gaps: " .. (gapsOn and "Enabled" or "Disabled"))
                changed = true
            end
        end

        -- Opacity ("on"/"off")
        if data.opacity and data.opacity ~= last.opacity then
            last.opacity = data.opacity
            osd.show("Opacity: " .. ((data.opacity == "on") and "Enabled" or "Disabled"))
            changed = true
        end

        -- Space count delta (created/destroyed on current display)
        if data.count ~= nil then
            local cnt = tonumber(data.count)
            local lastCnt = tonumber(last.count)
            if lastCnt ~= nil and cnt ~= lastCnt then
                if cnt > lastCnt then
                    local idx = tonumber(data.idx)
                    osd.show("Space Created" .. (idx and (": " .. tostring(idx)) or ""))
                else
                    osd.show("Space Destroyed")
                end
                changed = true
            end
            last.count = cnt
        end

        -- Broadcast complete state for UI consumers
        bus.emit("yabai-state", data)
    end

    local watchers = {}
    local function startWatcher(dir)
        local w = hs.pathwatcher.new(dir, function(files, _)
            if not core.isProcessRunning("yabai") then
                return
            end
            for _, file in ipairs(files) do
                local name = file:match("([^/]+)$") or file
                if name == "yabai_state.json" then
                    coalesce(file, function()
                        handleState(file)
                    end)
                end
            end
        end)
        w:start()
        table.insert(watchers, w)
        log.d("yabai state watcher started at: " .. dir)
    end
    for _, d in ipairs(dirs) do
        startWatcher(d)
    end
    _started = true
end

return M
