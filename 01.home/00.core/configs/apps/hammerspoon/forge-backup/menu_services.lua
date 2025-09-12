-- Title         : menu_services.lua
-- Author        : Parametric Forge
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/forge/menu_services.lua
-- ----------------------------------------------------------------------------
-- Minimal ops menubar: direct actions only (no polling, no status caching)

local config_reload = require("forge.config_reload")
local osd = require("forge.osd")
local core = require("forge.core")


local M = {}
-- Resolve assets directory (standard Hammerspoon deploy).
-- Canonical path: ~/.hammerspoon/assets (hs.configdir()/assets)
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

local imageCache = {}
local function assetImage(name, size, useTemplate)
    local key = name
        .. (size and (":" .. tostring(size.w) .. "x" .. tostring(size.h)) or "")
        .. (useTemplate and ":template" or "")
    if imageCache[key] then
        return imageCache[key]
    end
    local img
    local pathPng = ASSETS_DIR .. "/" .. name .. ".png"
    if hs.fs.attributes(pathPng) then
        img = hs.image.imageFromPath(pathPng)
    end
    if img then
        if size and img.setSize then
            img = img:setSize(size)
        end
        if useTemplate and img.setTemplate then
            img = img:setTemplate(true)
        end
        imageCache[key] = img
    end
    return img
end

-- Karabiner restart via launchctl kickstart (admin)
local function restartKarabiner()
    -- Restart console user server without sudo (GUI domain)
    hs.execute("/bin/launchctl kickstart -k gui/$UID org.pqrs.karabiner.karabiner_console_user_server || true", true)
    -- Restart system grabber with passwordless sudo (requires sudoers rule)
    -- If not permitted, this will fail silently due to -n and || true
    hs.execute("sudo -n /bin/launchctl kickstart -k system/org.pqrs.karabiner.karabiner_grabber || true", true)
end

local function darwinRebuild()
    local flakeRoot = (os.getenv("HOME") or "") .. "/Documents/99.Github/Parametric_Forge"
    if not hs.fs.attributes(flakeRoot .. "/flake.nix") then
        osd.show("flake.nix not found", { duration = 1.4 })
        return
    end

    osd.show("darwin-rebuild started…", { duration = 1.0 })

    -- Simple sudo approach - relies on sudoers configuration
    local cmd = string.format("cd %q && sudo darwin-rebuild switch --flake .", flakeRoot)
    local output, status = hs.execute(cmd, true)

    if status then
        osd.show("darwin-rebuild completed", { duration = 1.2 })
    else
        osd.show("darwin-rebuild failed", { duration = 1.8 })
    end
end

-- Build static menu -----------------------------------------------
-- No modifier-gated sections; all items are always visible

-- Forward declarations to avoid upvalue/global lookup issues
local menubar -- hs.menubar instance (created in start())
local buildMenu -- function value assigned below

local function serviceIcon(service)
    return assetImage(string.format("%s-on", service), { w = 18, h = 18 }, false)
end

-- Simple launcher by bundle identifier (no fallbacks)
local function openBundle(bundleID)
    hs.application.launchOrFocusByBundleID(bundleID)
end

-- For apps whose bundle ID varies across versions, prefer LaunchServices by name
local function openApp(name)
    hs.execute(string.format("/usr/bin/open -a %q", name), true)
end

local function serviceItem(title, serviceKey, onClick)
    return { title = title, image = serviceIcon(serviceKey), fn = onClick }
end

-- Simple menu without state tracking - query yabai directly when needed

-- Common Hammerspoon section builder
local function hammerspoonSection()
    return {
        { title = "-" },
        { title = "Hammerspoon", disabled = true },
        {
            title = "Hammerspoon (reload)",
            image = assetImage("hammerspoon-reload", { w = 18, h = 18 }, false),
            fn = function()
                osd.show("Reloading Hammerspoon…")
                hs.reload()
            end,
        },
        {
            title = "Hammerspoon Console",
            image = assetImage("forge-menu", { w = 18, h = 18 }, false),
            fn = function()
                hs.openConsole()
            end,
        }
    }
end

-- Simple menu builder - services and system only
buildMenu = function()
    local items = {}

    -- System section
    table.insert(items, { title = "System", disabled = true })
    table.insert(items, { title = "-" })
    table.insert(
        items,
        { title = "Darwin Rebuild", image = assetImage("forge-rebuild", { w = 18, h = 18 }, false), fn = darwinRebuild }
    )
    
    table.insert(items, { title = "-" })
    table.insert(items, { title = "Services", disabled = true })

    -- yabai
    table.insert(
        items,
        serviceItem("yabai", "yabai", function()
            config_reload.restartYabai()
            osd.show("Restarted: yabai")
        end)
    )

    -- skhd
    table.insert(
        items,
        serviceItem("skhd", "skhd", function()
            config_reload.reloadSkhd()
            osd.show("Restarted: skhd")
        end)
    )

    -- goku (Karabiner EDN watcher)
    table.insert(
        items,
        serviceItem("goku", "goku", function()
            config_reload.restartGoku()
            osd.show("Restarted: goku")
        end)
    )

    -- Karabiner-Elements
    table.insert(
        items,
        serviceItem("karabiner-elements", "karabiner", function()
            restartKarabiner()
            osd.show("Restarted: Karabiner")
        end)
    )
    -- Karabiner convenience actions (open settings and EventViewer like the menubar)
    table.insert(items, {
        title = "Karabiner Settings",
        image = assetImage("karabiner-on", { w = 18, h = 18 }, false),
        fn = function()
            -- Officially recommended approach in Karabiner docs
            openApp("Karabiner-Elements")
        end,
    })
    table.insert(items, {
        title = "Karabiner EventViewer",
        image = assetImage("karabiner-on", { w = 18, h = 18 }, false),
        fn = function()
            openBundle("org.pqrs.Karabiner-EventViewer")
        end,
    })

    -- Add common Hammerspoon section
    for _, item in ipairs(hammerspoonSection()) do
        table.insert(items, item)
    end

    return items
end

function M.start()
    if menubar then
        return
    end
    menubar = hs.menubar.new()
    if not menubar then
        return
    end
    menubar:autosaveName("forge-menubar")

    -- Set icon (non-template to render as provided, e.g., pure white)
    local img = assetImage("forge-menu", { w = 18, h = 18 }, false)
    if not img then
        local fallback = hs.image.imageFromName("NSAdvanced")
            or hs.image.imageFromName("NSPreferencesGeneral")
            or hs.image.imageFromName("NSActionTemplate")
        if fallback and fallback.setSize then
            img = fallback:setSize({ w = 18, h = 18 })
        else
            img = fallback
        end
    end
    if img then
        menubar:setIcon(img)
    else
        menubar:setTitle("⚙︎")
    end
    menubar:setTooltip("Parametric Forge")

    -- Set dynamic menu provider; do not change it while open
    menubar:setMenu(buildMenu)

    -- Clean menu - no state tracking needed
end

-- Cleanup function
function M.stop()
    if menubar then
        menubar:delete()
        menubar = nil
    end
end

return M
