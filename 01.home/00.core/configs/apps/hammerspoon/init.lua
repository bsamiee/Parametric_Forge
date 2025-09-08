-- Title         : init.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/init.lua
-- ----------------------------------------------------------------------------
-- Core setup, modals, OSD indicator, borders lifecycle, auto-watchers, and palette.
-- Purpose: Provide a clean, minimal Hammerspoon setup that:
--  - Defines right-side modifier modals: Super (Right Cmd) and Meh (Right Option)
--  - Avoids adding new keybinds (no actions are bound here)
--  - Exposes helpers for future use and integrates safely with yabai/skhd
--  - Sets sane defaults (animations off, logging, robust PATH) to match yabai

-- --- Core settings ---------------------------------------------------------
local hs = hs
hs.window.animationDuration = 0
hs.hints.showTitleThresh = 0
hs.hotkey.alertDuration = 0

local log = hs.logger.new("forge", hs.logger.info)

-- Load OSD module early (needed by functions below)
local osd = require("forge.osd")

-- PATH used by shell commands (yabai, jq, etc.)
local PATH = "/opt/homebrew/bin:/usr/local/bin:/run/current-system/sw/bin:" .. os.getenv("PATH")

local function sh(cmd)
    return hs.execute("/usr/bin/env PATH='" .. PATH .. "' sh -lc '" .. cmd .. "'", true)
end

-- --- Yabai helpers (no hard dependency if not installed) -------------------
local function yabai(cmd)
    return sh("yabai -m " .. cmd)
end

local function yabaiIsRunning()
    local out = sh("pgrep -x yabai >/dev/null 2>&1; echo $?")
    return out and out:match("^0") ~= nil
end

-- Goto space by Mission Control index, without assuming SIP state.
-- Uses yabai query to map index -> space id, then uses hs.spaces.gotoSpace.
local function gotoSpaceByIndex(idx)
    if not idx then
        return
    end
    local json = sh("yabai -m query --spaces 2>/dev/null")
    if not json or #json == 0 then
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

-- --- Modal states for right-side modifiers --------------------------------
-- We detect right-specific modifier keys via flagsChanged and keyCode.
-- KeyCodes (Apple): rCmd=54, lCmd=55, lAlt=58, rAlt=61, lShift=56, rShift=60, lCtrl=59, rCtrl=62

local superModal = hs.hotkey.modal.new()
local mehModal = hs.hotkey.modal.new()

superModal.exited = function()
    log.d("Super: exit")
end
mehModal.exited = function()
    log.d("Meh: exit")
end

local superActive = false
local mehActive = false

-- Modifier state indicator as persistent OSD (no menubar icon)
local function updateIndicator()
    if superActive and mehActive then
        osd.showPersistent("mods", "Super / Meh")
    elseif superActive then
        osd.showPersistent("mods", "Super")
    elseif mehActive then
        osd.showPersistent("mods", "Meh")
    else
        osd.hidePersistent("mods")
    end
end

local function enterSuper()
    if not superActive then
        superActive = true
        superModal:enter()
        log.d("Super: enter")
        updateIndicator()
    end
end

local function exitSuper()
    if superActive then
        superActive = false
        superModal:exit()
        updateIndicator()
    end
end

local function enterMeh()
    if not mehActive then
        mehActive = true
        mehModal:enter()
        log.d("Meh: enter")
        updateIndicator()
        -- Temporary stack drop-action while Meh (Right Option) is held
        local current = (sh("yabai -m config mouse_drop_action 2>/dev/null"):gsub("\n$", ""))
        if current == "swap" or current == nil or #current == 0 then
            sh("yabai -m config mouse_drop_action stack")
            osd.show("Drop: Stack (hold)", { duration = 0.6 })
            _G.__forge_meh_set_stack = true
        else
            _G.__forge_meh_set_stack = false
        end
    end
end

local function exitMeh()
    if mehActive then
        mehActive = false
        mehModal:exit()
        updateIndicator()
        -- Restore drop-action if we changed it on enter
        if _G.__forge_meh_set_stack then
            sh("yabai -m config mouse_drop_action swap")
            osd.show("Drop: Swap", { duration = 0.6 })
            _G.__forge_meh_set_stack = false
        end
    end
end

-- Event tap for right-side modifiers only; no bindings are attached here.
local flagsTap = hs.eventtap.new({ hs.eventtap.event.types.flagsChanged }, function(ev)
    local keyCode = ev:getKeyCode()
    local flags = ev:getFlags()

    -- Right Command (Super)
    if keyCode == 54 then
        if flags.cmd then
            enterSuper()
        else
            exitSuper()
        end
    end

    -- Right Option (Meh)
    if keyCode == 61 then
        if flags.alt then
            enterMeh()
        else
            exitMeh()
        end
    end

    return false -- do not consume; just observe
end)

flagsTap:start()
updateIndicator()

-- --- Spaces watcher (optional sync hooks, no keybinds) ---------------------
local function onSpaceChange()
    -- Reserved for future sync (e.g., trigger sketchybar or cache updates)
    -- Example: sh("sketchybar --trigger space_change")
end

local sw = hs.spaces.watcher.new(onSpaceChange)
sw:start()

-- --- Wake/launch resilience ------------------------------------------------
local function afterWake()
    -- Optional: re-check yabai running state, or refresh timers.
    if yabaiIsRunning() then
        -- Example: ensure consistent opacity duration
        yabai("config window_opacity_duration 0.25")
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
    super = function()
        return { "cmd" }
    end, -- semantic alias
    meh = function()
        return { "alt" }
    end, -- semantic alias
}

forge = {
    gotoSpaceByIndex = gotoSpaceByIndex,
    superActive = function()
        return superActive
    end,
    mehActive = function()
        return mehActive
    end,
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
events.start()

-- Ensure JankyBorders starts promptly after yabai readiness; force a clean restart
integ.ensureBorders({ forceRestart = true })
integ.watchYabaiRestart()
integ.watchYabaiState()

-- Start auto-reload watchers for configs (yabai/skhd/hammerspoon/yazi)
auto.start()

log.i("Hammerspoon ready (policy active; Super=RightCmd, Meh=RightOption)")
