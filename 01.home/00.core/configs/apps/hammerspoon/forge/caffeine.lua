-- Title         : caffeine.lua
-- Author        : Parametric Forge
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/forge/caffeine.lua
-- ----------------------------------------------------------------------------
-- Classic Caffeine-style display sleep inhibitor using Hammerspoon's hs.caffeinate.
-- No external apps required.

local M = {}

local osd = require("forge.osd")

local menubar
local STATE_KEY = "forge.caffeine.displayIdle"

-- Resolve assets dir for icons
local function hsConfigDir()
    local v = hs.configdir
    if type(v) == "function" then
        return v()
    end
    if type(v) == "string" and #v > 0 then
        return v
    end
    return (os.getenv("HOME") or "") .. "/.hammerspoon"
end
local ASSETS_DIR = hsConfigDir() .. "/assets"

local function assetImage(name, size, template)
    local path = ASSETS_DIR .. "/" .. name .. ".png"
    local img = hs.fs.attributes(path) and hs.image.imageFromPath(path) or nil
    if not img then
        -- Fall back to system status icons sized for menu bar
        local sys = hs.image.imageFromName(template and "NSStatusAvailable" or "NSStatusUnavailable")
        img = sys
    end
    if img and size and img.setSize then
        img = img:setSize(size)
    end
    if img and template then
        if img.setTemplate then
            img = img:setTemplate(true)
        else
            if img.template then
                img:template(true)
            end
        end
    end
    return img
end

local function setIcon(on)
    if not menubar then
        return
    end
    -- Prefer custom assets if present: caffeine-on.png / caffeine-off.png
    local name = on and "caffeine-on" or "caffeine-off"
    -- Use non-template so icons render as provided (pure white), not tinted
    local img = assetImage(name, { w = 18, h = 18 }, false)
    if img then
        menubar:setIcon(img)
    else
        -- Fallback title if icon creation fails
        menubar:setTitle("☕︎")
    end
end

local function isEnabled()
    local ok, val = pcall(hs.caffeinate.get, "displayIdle")
    if ok and type(val) == "boolean" then
        return val
    end
    -- fall back to stored state when API unavailable
    return hs.settings.get(STATE_KEY) == true
end

local function setEnabled(on)
    -- best-effort apply through hs.caffeinate
    pcall(hs.caffeinate.set, "displayIdle", on, true)
    hs.settings.set(STATE_KEY, on)
    if menubar then
        setIcon(on)
        menubar:setTooltip(on and "Caffeine: Display awake" or "Caffeine: Off")
    end
    -- Use unified OSD helper
    if osd and type(osd.notifyCaffeine) == "function" then
        osd.notifyCaffeine(on)
    else
        osd.show(on and "Caffeine: ON" or "Caffeine: OFF", { duration = 0.8 })
    end
end

local function toggle()
    setEnabled(not isEnabled())
end

local function buildMenu()
    return {
        { title = isEnabled() and "Turn Caffeine Off" or "Turn Caffeine On", fn = toggle },
        { title = "-" },
        { title = "Prevent: Display Sleep", checked = isEnabled(), disabled = true },
    }
end

function M.start()
    if menubar then
        return
    end
    menubar = hs.menubar.new()
    if not menubar then
        return
    end
    menubar:autosaveName("forge-caffeine")
    menubar:setClickCallback(toggle)
    menubar:setMenu(buildMenu)
    -- Prefer project-provided assets: caffeine-on.png / caffeine-off.png
    setIcon(isEnabled())
end

function M.stop()
    if menubar then
        menubar:delete()
        menubar = nil
    end
end

M.toggle = toggle
M.set = setEnabled
M.enabled = isEnabled

return M
