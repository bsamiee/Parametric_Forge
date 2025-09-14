-- Title         : yabai_bridge.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/integration/yabai_bridge.lua
-- ----------------------------------------------------------------------------
-- Clean integration between Hammerspoon, yabai, and skhd using native hs.ipc

local canvas = require("notifications.canvas")
local process = require("utils.process")
local config = require("utils.config")

local M = {}
local log = hs.logger.new("yabai_bridge", hs.logger.info)

-- Path constants
local YABAI_PATH = config.getYabaiPath()

-- Event handlers for different integration points
local handlers = {}

-- Register handler for URL scheme communication (from karabiner leaders)
function handlers.leader(params)
    local name = params.name
    local down = params.down == "1"

    if name == "hyper" then
        if down then
            -- Hyper key pressed - could show indicator or prepare for commands
            canvas.show("HYPER MODE", 2.5)
        end
    elseif name == "super" then
        if down then
            canvas.show("SUPER MODE", 2.5)
        end
    elseif name == "power" then
        if down then
            canvas.show("POWER MODE", 2.5)
        end
    end
end

-- Modal indicator control from URL (e.g., hammerspoon://modal?name=float&down=1)
-- (modal URL control removed for simplicity; unused in current setup)

-- System state query handlers
function handlers.system(params)
    local action = params.action

    if action == "yabai_status" then
        local isRunning = process.isRunning("yabai")
        canvas.show("Yabai: " .. (isRunning and "RUNNING" or "STOPPED"))
    elseif action == "skhd_status" then
        local isRunning = process.isRunning("skhd")
        canvas.show("SKHD: " .. (isRunning and "RUNNING" or "STOPPED"))
    end
end

-- Wake handler for system integration
function handlers.wake()
    -- Restore yabai opacity settings after wake
    if process.isRunning("yabai") then
        process.execute(YABAI_PATH .. " -m config window_opacity_duration 0.25", true)
        canvas.show("YABAI OPACITY RESTORED")
    end
end

-- URL handler for hammerspoon:// scheme
local function handleURL(scheme, host, params, fullURL)
    log.i("Received URL: " .. tostring(fullURL))

    if host and handlers[host] then
        handlers[host](params or {})
        return true
    end

    log.w("Unknown handler: " .. tostring(host))
    return false
end

-- Initialize integration
function M.init()
    -- Install CLI tool for skhd communication (derive prefix from brew when available)
    local brew = config.getBrewPath()
    local prefix = "/opt/homebrew"
    if brew and type(brew) == "string" then
        prefix = brew:gsub("/bin/brew$", "")
    end
    hs.ipc.cliInstall(prefix, true)

    -- Register URL handler for karabiner leader communication
    hs.urlevent.bind("hammerspoon", handleURL)

    -- Setup system wake watcher
    local wakeWatcher = hs.caffeinate.watcher.new(function(event)
        if event == hs.caffeinate.watcher.systemDidWake then
            handlers.wake()
        end
    end)
    wakeWatcher:start()

    log.i("Yabai bridge initialized")
    return true
end

return M
