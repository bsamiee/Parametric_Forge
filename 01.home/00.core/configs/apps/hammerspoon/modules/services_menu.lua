-- Title         : services_menu.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/modules/services_menu.lua
-- ----------------------------------------------------------------------------
-- Complete services menu with all individual service controls

local canvas = require("notifications.canvas")
local assets = require("utils.assets")
local process = require("utils.process")
local config = require("utils.config")
local files = require("utils.files")

local M = {}
local log = hs.logger.new("services_menu", hs.logger.info)

local menuItem

-- Service management functions (from working backup patterns)
local function restartYabai()
    canvas.show("RESTARTING YABAI")
    -- Kill any existing yabai processes first
    process.execute("killall -9 yabai 2>/dev/null", true)
    hs.timer.usleep(500000) -- 0.5 second delay
    -- Restart via launchctl
    local plist = os.getenv("HOME") .. "/Library/LaunchAgents/com.koekeishiya.yabai.plist"
    process.execute(string.format("launchctl unload %q 2>/dev/null; launchctl load %q", plist, plist), true)
    canvas.show("YABAI RESTARTED")
end

local function reloadSkhd()
    canvas.show("RESTARTING SKHD")
    -- Kill any existing skhd processes and clean up pid file
    process.execute("killall -9 skhd 2>/dev/null; rm -f /tmp/skhd_*.pid", true)
    hs.timer.usleep(500000) -- 0.5 second delay
    -- Restart via launchctl
    local plist = os.getenv("HOME") .. "/Library/LaunchAgents/com.koekeishiya.skhd.plist"
    process.execute(string.format("launchctl unload %q 2>/dev/null; launchctl load %q", plist, plist), true)
    canvas.show("SKHD RESTARTED")
end

local function restartGoku()
    canvas.show("RESTARTING GOKU")
    -- Kill existing gokuw processes
    process.execute("killall -9 gokuw 2>/dev/null", true)
    hs.timer.usleep(500000) -- 0.5 second delay
    -- Try to restart via brew services or launchctl
    local brew = config.getBrewPath() or "/opt/homebrew/bin/brew"
    local plist = os.getenv("HOME") .. "/Library/LaunchAgents/homebrew.mxcl.goku.plist"
    if files.exists(plist) then
        process.execute(string.format("launchctl unload %q 2>/dev/null; launchctl load %q", plist, plist), true)
        canvas.show("GOKU RESTARTED")
    else
        process.execute(
            string.format("%q services restart goku 2>/dev/null || %q services start goku", brew, brew),
            true
        )
        canvas.show("GOKU RESTARTED")
    end
end

local function restartKarabiner()
    canvas.show("RESTARTING KARABINER")
    -- Quit Karabiner-Elements app first
    process.execute("osascript -e 'tell application \"Karabiner-Elements\" to quit' 2>/dev/null", true)
    hs.timer.usleep(1000000) -- 1 second delay
    -- Restart the services
    process.execute(
        "/bin/launchctl kickstart -k gui/$(id -u)/org.pqrs.karabiner.karabiner_console_user_server 2>/dev/null",
        true
    )
    -- Launch the app again
    process.execute("/usr/bin/open -a 'Karabiner-Elements'", true)
    canvas.show("KARABINER RESTARTED")
end

local function darwinRebuild()
    local flakeRoot = config.getFlakeRoot()
    if not files.exists(flakeRoot .. "/flake.nix") then
        canvas.show("FLAKE.NIX NOT FOUND")
        return
    end

    canvas.show("DARWIN REBUILD STARTED")
    local cmd = string.format("cd %q && sudo darwin-rebuild switch --flake .", flakeRoot)
    local output, status = process.execute(cmd, true)

    if status then
        canvas.show("DARWIN REBUILD COMPLETED")
    else
        canvas.show("DARWIN REBUILD FAILED")
    end
end

-- Simple service item builder with icon
local function serviceItem(title, iconName, onClick)
    return {
        title = title,
        image = assets.image(iconName, { w = 18, h = 18 }),
        fn = onClick,
    }
end

-- Simple app launchers
local function openApp(name)
    process.execute(string.format("/usr/bin/open -a %q", name), true)
end

local function openBundle(bundleID)
    hs.application.launchOrFocusByBundleID(bundleID)
end

local function buildMenu()
    return {
        {
            title = "System",
            disabled = true,
        },
        serviceItem("Darwin Rebuild", "forge-rebuild", darwinRebuild),
        { title = "-" },
        {
            title = "Services",
            disabled = true,
        },
        serviceItem("yabai", "yabai", restartYabai),
        serviceItem("skhd", "skhd", reloadSkhd),
        serviceItem("goku", "goku", restartGoku),
        serviceItem("karabiner-elements", "karabiner", restartKarabiner),
        { title = "-" },
        {
            title = "Karabiner",
            disabled = true,
        },
        serviceItem("Karabiner Settings", "karabiner", function()
            openApp("Karabiner-Elements")
        end),
        serviceItem("Karabiner EventViewer", "karabiner", function()
            openBundle("org.pqrs.Karabiner-EventViewer")
        end),
        { title = "-" },
        {
            title = "Hammerspoon",
            disabled = true,
        },
        serviceItem("Reload Hammerspoon", "hammerspoon-reload", function()
            canvas.show("HAMMERSPOON RELOADING")
            hs.reload()
        end),
        serviceItem("Hammerspoon Console", "forge-menu", function()
            hs.openConsole()
        end),
    }
end

function M.init()
    if menuItem then
        return
    end

    menuItem = hs.menubar.new()
    if not menuItem then
        log.e("Failed to create services menubar item")
        return false
    end

    menuItem:autosaveName("forge-menubar")
    menuItem:setTooltip("Parametric Forge")

    -- Set icon with system fallback
    local icon = assets.image("forge-menu", { w = 18, h = 18 })
    if icon then
        menuItem:setIcon(icon)
    else
        local fallback = hs.image.imageFromName("NSAdvanced") or hs.image.imageFromName("NSPreferencesGeneral")
        if fallback and fallback.setSize then
            menuItem:setIcon(fallback:setSize({ w = 18, h = 18 }))
        else
            menuItem:setTitle("SRV")
        end
    end

    menuItem:setMenu(buildMenu)

    log.i("Services menu initialized")
    return true
end

function M.stop()
    if menuItem then
        menuItem:delete()
        menuItem = nil
    end
    log.i("Services menu stopped")
end

return M
