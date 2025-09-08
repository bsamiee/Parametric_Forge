-- Title         : init.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/init.lua
-- ----------------------------------------------------------------------------
-- Core setup, modals, OSD indicator, borders lifecycle, auto-watchers, and palette.
-- Purpose: Provide a clean, minimal Hammerspoon setup that:
--  - Avoids duplicating keybinds (leaders via Karabiner-Elements)
--  - Exposes helpers for future use and integrates safely with yabai/skhd
--  - Sets sane defaults (animations off, logging, robust PATH) to match yabai

-- --- Core settings ---------------------------------------------------------
local hs = hs
hs.window.animationDuration = 0
hs.hints.showTitleThresh = 0
hs.hotkey.alertDuration = 0

local log = hs.logger.new("forge", hs.logger.info)

-- Load helpers early
local osd = require("forge.osd")
local shlib = require("forge.sh")

-- --- Yabai helpers (no hard dependency if not installed) -------------------
local function yabai(cmd)
    return shlib.yabai(cmd)
end

local function yabaiIsRunning()
    return shlib.isProcessRunning("yabai")
end

-- Goto space by Mission Control index, without assuming SIP state.
-- Uses yabai query to map index -> space id, then uses hs.spaces.gotoSpace.
local function gotoSpaceByIndex(idx)
    if not idx then
        return
    end
    local json = shlib.sh("yabai -m query --spaces 2>/dev/null")
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

-- --- Modifier leaders handled by Karabiner-Elements -----------------------
-- Right-side leaders (Hyper/Super/Power) are mapped at the OS level via
-- Karabiner-Elements. Hammerspoon no longer tracks right-modifier state,
-- avoiding duplication and reducing complexity.

-- (Spaces watcher moved to forge.events; avoid duplicate watchers here)

-- --- Wake/launch resilience ------------------------------------------------
local function afterWake()
    -- Optional: re-check yabai running state, or refresh timers.
    if yabaiIsRunning() then
        -- Example: ensure consistent opacity duration
        yabai("config window_opacity_duration 0.25")
        -- Refresh SA availability in case Dock/Yabai changed
        local exec = require("forge.executor")
        exec.refreshSa()
    end
end

local cw = hs.caffeinate.watcher.new(function(event)
    if event == hs.caffeinate.watcher.systemDidWake then
        afterWake()
    end
end)
cw:start()

-- --- Public module-like exports (for future use) ---------------------------
mods = {
    hyper = function() return { "cmd", "alt", "ctrl", "shift" } end,
    super = function() return { "cmd", "alt", "ctrl" } end,
    power = function() return { "alt", "ctrl", "shift" } end,
}

forge = {
    gotoSpaceByIndex = gotoSpaceByIndex,
    superActive = function() return false end,
    mehActive = function() return false end,
    yabai = yabai,
}

-- Ready notice
-- Start policy engine modules
local exec = require("forge.executor")
local events = require("forge.events")
local integ = require("forge.integration")
local auto = require("forge.auto")
-- Load modules for side effects (register handlers, etc.)
require("forge.policy") -- Policy registration
require("forge.config") -- Config definitions
require("forge.palette") -- URL handlers registration

-- Step 1: start in dry-run (can be switched off after verification)
exec.setDryRun(false)
exec.refreshSa()
events.start()

-- Ensure JankyBorders starts promptly after yabai readiness; force a clean restart
-- Borders lifecycle managed by yabai (see yabairc). Avoid duplicate management here.

-- Start auto-reload watchers for configs (yabai/skhd/hammerspoon/yazi)
auto.start()

-- Start system menubar (status + ops)
require("forge.menubar").start()

log.i("Hammerspoon ready (policy active; leaders via Karabiner)")
