-- Title         : init.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/init.lua
-- ----------------------------------------------------------------------------
-- Core setup, modals, OSD indicator, borders lifecycle, and auto-watchers.
-- Purpose: Provide a clean, minimal Hammerspoon setup that:
--  - Avoids duplicating keybinds (uses skhd for system-level hotkeys)
--  - Exposes helpers for future use and integrates safely with yabai/skhd
--  - Sets sane defaults (animations off, logging, robust PATH) to match yabai

-- --- Core settings ----------------------------------------------------------
local hs = hs
hs.window.animationDuration = 0
hs.hints.showTitleThresh = 0
hs.hotkey.alertDuration = 0

local log = hs.logger.new("forge", hs.logger.info)

-- Ensure local modules are discoverable regardless of default package.path
do
    local cfgdir = (type(hs.configdir) == "function") and hs.configdir() or hs.configdir
    if type(cfgdir) == "string" and #cfgdir > 0 then
        package.path = string.format("%s/?.lua;%s/?/init.lua;%s", cfgdir, cfgdir, package.path)
    end
end

-- Load helpers early
local osd = require("forge.osd")
-- Clear any stale persistent overlays from previous sessions
pcall(function()
    osd.hideAllPersistent()
end)

-- Ensure `hs` CLI exists for skhd pipes (hs.ipc); ignore failures gracefully
pcall(function()
    local ok, ipc = pcall(require, "hs.ipc")
    if ok and ipc and type(ipc.cliInstall) == "function" then
        -- Install to /usr/local/bin for skhd compatibility
        ipc.cliInstall("/usr/local")
    end
end)

-- Load core modules early to avoid undefined references
local core = require("forge.core")

-- --- Yabai helpers (no hard dependency if not installed) --------------------
local function yabai(cmd)
    return core.yabai(cmd)
end

-- Goto space by Mission Control index, without assuming SIP state.
-- Uses yabai query to map index -> space id, then uses hs.spaces.gotoSpace.
local function gotoSpaceByIndex(idx)
    if not idx then
        return
    end
    local json = core.sh("yabai -m query --spaces 2>/dev/null")
    if not json or #json == 0 then
        return
    end
    if not json:match("^%s*[%[{]") then
        return
    end
    local ok, spaces = pcall(hs.json.decode, json)
    if not ok or type(spaces) ~= "table" then
        return
    end
    local targetId
    for _, s in ipairs(spaces) do
        if s.index == idx then
            targetId = s.id
            break
        end
    end
    if targetId then
        local ok2, err = hs.spaces.gotoSpace(targetId)
        if not ok2 then
            log.w("hs.spaces.gotoSpace failed: " .. tostring(err))
        end
    end
end

-- --- Public module-like exports (for future use) ----------------------------
mods = {
    hyper = function()
        return { "cmd", "alt", "ctrl", "shift" }
    end,
    super = function()
        return { "cmd", "alt", "ctrl" }
    end,
    power = function()
        return { "alt", "ctrl", "shift" }
    end,
}

forge = {
    gotoSpaceByIndex = gotoSpaceByIndex,
    superActive = function()
        return false
    end,
    mehActive = function()
        return false
    end,
    yabai = yabai,
}

-- Ready notice
-- Start core modules
local config_reload = require("forge.config_reload")
local events = require("forge.events")
local integ = require("forge.integration")
local window_picker = require("forge.window_picker")
-- Load modules for side effects (register handlers, etc.)

-- Step 1: start in dry-run (can be switched off after verification)
core.setDryRun(false)
core.refreshSa()
events.start()

-- Observe yabai state files for layout/drop OSD when toggled outside HS (e.g., via skhd)
if integ and type(integ.watchYabaiState) == "function" then
    integ.watchYabaiState()
end

-- Start auto-reload watchers for configs (yabai/skhd/hammerspoon/yazi)
config_reload.start()
require("forge.menu_services").start()
require("forge.menu_automations").start()
require("forge.space_indicator").start()
require("forge.caffeine").start()
require("forge.automations").start()

-- URL scheme handlers for Karabiner integration
hs.urlevent.bind("window_picker", function(eventName, params)
    if eventName == "show" then
        window_picker.show()
    end
end)

hs.urlevent.bind("forge/leader", function(eventName, params)
    core.leader.track(params.name, params.down)
end)

log.i("Hammerspoon ready")
