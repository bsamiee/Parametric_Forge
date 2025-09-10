-- Title         : menubar.lua
-- Author        : Parametric Forge
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/forge/menubar.lua
-- ----------------------------------------------------------------------------
-- Minimal ops menubar: direct actions only (no polling, no status caching)

local core = require("forge.core")
local auto = require("forge.auto")
local osd = require("forge.osd")
local shlib = require("forge.sh")
local autom = require("forge.automations")
local config = core.config
local bus = core.bus


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
    shlib.sh("/bin/launchctl kickstart -k gui/$UID org.pqrs.karabiner.karabiner_console_user_server || true")
    -- Restart system grabber with passwordless sudo (requires sudoers rule)
    -- If not permitted, this will fail silently due to -n and || true
    shlib.sh("sudo -n /bin/launchctl kickstart -k system/org.pqrs.karabiner.karabiner_grabber || true")
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

-- State is updated by bus events; no polling, no shell queries on open
local state = {
    layout = "bsp",
    drop = "swap",
    gaps = false,
    opacity = false,
    label = "",
    idx = nil,
}

-- Seed initial state from the last written file, if available
local function seedStateFromFile()
    local candidates = {}
    local tmp = os.getenv("TMPDIR")
    if tmp and #tmp > 0 then
        table.insert(candidates, (tmp:match("/$") and tmp or (tmp .. "/")) .. "yabai_state.json")
    end
    table.insert(candidates, "/tmp/yabai_state.json")
    for _, p in ipairs(candidates) do
        local f = io.open(p, "r")
        if f then
            local txt = f:read("*a")
            f:close()
            if txt and #txt > 0 and (txt:find("^{") or txt:find("^%[")) then
                local ok, data = pcall(hs.json.decode, txt)
                if ok and type(data) == "table" then
                    if data.mode then state.layout = tostring(data.mode) end
                    if data.drop then state.drop = tostring(data.drop) end
                    if data.gaps ~= nil then state.gaps = tonumber(data.gaps) and tonumber(data.gaps) > 0 end
                    if data.opacity then state.opacity = (tostring(data.opacity) == "on") end
                    if data.label then state.label = tostring(data.label) end
                    if data.idx then state.idx = tonumber(data.idx) end
                    break
                end
            end
        end
    end
end

-- Simple static menu builder
buildMenu = function()
    local items = {}

    local lay = state.layout
    local drop = state.drop
    local gaps = state.gaps
    local opac = state.opacity

    -- Layout toggle
    table.insert(items, {
        title = string.format("Layout: %s", lay == "bsp" and "BSP" or "Stack"),
        image = assetImage(lay == "bsp" and "layout-bsp" or "layout-stack", { w = 16, h = 16 }, false),
        fn = function()
            hs.timer.doAfter(0.01, function()
                local current = state.layout
                local next = (current == "bsp") and "stack" or "bsp"
                shlib.sh("yabai -m space --layout " .. next)
                -- write minimal state for other producers/consumers (align with skhd/yabai conventions)
                pcall(function()
                    pcall(shlib.writeYabaiState)
                end)
                -- immediately update local state/UI (do not wait for yabai signal)
                state.layout = next
                local spacePart
                if state.idx then
                    if state.label and #state.label > 0 then
                        spacePart = string.format("Space: %d • %s", state.idx, state.label)
                    else
                        spacePart = string.format("Space: %d", state.idx)
                    end
                else
                    spacePart = "Space: ?"
                end
                local tip = string.format(
                    "%s • Layout: %s • Gaps: %s • Drop: %s • Opacity: %s",
                    spacePart, tostring(state.layout), tostring(state.gaps and 1 or 0), tostring(state.drop), tostring(state.opacity and "on" or "off")
                )
                menubar:setTooltip(tip)
                menubar:setMenu(buildMenu)
                -- broadcast to other modules
                bus.emit("yabai-state", { mode = state.layout, gaps = state.gaps and 1 or 0, drop = state.drop, opacity = state.opacity and "on" or "off" })
            end)
        end,
    })

    table.insert(items, {
        title = string.format("Drop: %s", drop == "stack" and "Stack" or "Swap"),
        image = assetImage(drop == "stack" and "drop-stack" or "drop-swap", { w = 16, h = 16 }, false),
        fn = function()
            hs.timer.doAfter(0.01, function()
                local current = state.drop
                local next = (current == "swap") and "stack" or "swap"
                shlib.sh("yabai -m config mouse_drop_action " .. next)
                pcall(shlib.writeYabaiState)
                state.drop = next
                local tip = string.format(
                    "Layout: %s • Gaps: %s • Drop: %s • Opacity: %s",
                    tostring(state.layout), tostring(state.gaps and 1 or 0), tostring(state.drop), tostring(state.opacity and "on" or "off")
                )
                menubar:setTooltip(tip)
                menubar:setMenu(buildMenu)
                bus.emit("yabai-state", { mode = state.layout, gaps = state.gaps and 1 or 0, drop = state.drop, opacity = state.opacity and "on" or "off" })
            end)
        end,
    })

    table.insert(items, {
        title = string.format("Gaps: %s", gaps and "On" or "Off"),
        image = assetImage(gaps and "gaps-on" or "gaps-off", { w = 16, h = 16 }, false),
        fn = function()
            hs.timer.doAfter(0.01, function()
                local current = state.gaps
                if current then
                    shlib.sh("yabai -m config top_padding 0; yabai -m config bottom_padding 0; yabai -m config left_padding 0; yabai -m config right_padding 0; yabai -m config window_gap 0; yabai -m config external_bar all:0:0")
                    pcall(function()
                        pcall(shlib.writeYabaiState)
                    end)
                    state.gaps = false
                else
                    shlib.sh("yabai -m config top_padding 4; yabai -m config bottom_padding 4; yabai -m config left_padding 4; yabai -m config right_padding 4; yabai -m config window_gap 4; yabai -m config external_bar all:4:4")
                    pcall(function()
                        pcall(shlib.writeYabaiState)
                    end)
                    state.gaps = true
                end
                local spacePart
                if state.idx then
                    if state.label and #state.label > 0 then
                        spacePart = string.format("Space: %d • %s", state.idx, state.label)
                    else
                        spacePart = string.format("Space: %d", state.idx)
                    end
                else
                    spacePart = "Space: ?"
                end
                local tip = string.format(
                    "%s • Layout: %s • Gaps: %s • Drop: %s • Opacity: %s",
                    spacePart, tostring(state.layout), tostring(state.gaps and 1 or 0), tostring(state.drop), tostring(state.opacity and "on" or "off")
                )
                menubar:setTooltip(tip)
                menubar:setMenu(buildMenu)
                bus.emit("yabai-state", { mode = state.layout, gaps = state.gaps and 1 or 0, drop = state.drop, opacity = state.opacity and "on" or "off" })
            end)
        end,
    })

    table.insert(items, {
        title = string.format("Opacity: %s", opac and "On" or "Off"),
        image = assetImage(opac and "opacity-on" or "opacity-off", { w = 16, h = 16 }, false),
        fn = function()
            hs.timer.doAfter(0.01, function()
                local next = state.opacity and "off" or "on"
                shlib.sh("yabai -m config window_opacity " .. next)
                state.opacity = (next == "on")
                pcall(function()
                    pcall(shlib.writeYabaiState)
                end)
                local spacePart
                if state.idx then
                    if state.label and #state.label > 0 then
                        spacePart = string.format("Space: %d • %s", state.idx, state.label)
                    else
                        spacePart = string.format("Space: %d", state.idx)
                    end
                else
                    spacePart = "Space: ?"
                end
                local tip = string.format(
                    "%s • Layout: %s • Gaps: %s • Drop: %s • Opacity: %s",
                    spacePart, tostring(state.layout), tostring(state.gaps and 1 or 0), tostring(state.drop), tostring(state.opacity and "on" or "off")
                )
                menubar:setTooltip(tip)
                menubar:setMenu(buildMenu)
                bus.emit("yabai-state", { mode = state.layout, gaps = state.gaps and 1 or 0, drop = state.drop, opacity = state.opacity and "on" or "off" })
            end)
        end,
    })

    table.insert(items, { title = "-" })
    table.insert(items, { title = "Automations", disabled = true })

    local function toggleItem(label, key)
    return {
        title   = string.format("%s %s", label, autom.isEnabled(key) and "✓" or " "),
        fn      = function() autom.toggle(key); menubar:setMenu(buildMenu) end
    }
    end

    table.insert(items, toggleItem("Auto-unzip (Downloads)", "unzip"))
    table.insert(items, toggleItem("WEBP → PNG (Downloads)", "webp2png"))
    table.insert(items, {
    title = "Install DMGs",
    menu = {
        { title = "Off",  checked = autom.getDmgMode()=="off",  fn = function() autom.setDmgMode("off");  menubar:setMenu(buildMenu) end },
        { title = "Ask",  checked = autom.getDmgMode()=="ask",  fn = function() autom.setDmgMode("ask");  menubar:setMenu(buildMenu) end },
        { title = "Auto (allow-list)", checked = autom.getDmgMode()=="auto", fn = function() autom.setDmgMode("auto"); menubar:setMenu(buildMenu) end },
    },
})

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
            auto.restartYabai()
            osd.show("Restarted: yabai", { duration = 0.9 })
        end)
    )

    -- skhd
    table.insert(
        items,
        serviceItem("skhd", "skhd", function()
            auto.reloadSkhd()
            osd.show("Restarted: skhd", { duration = 0.9 })
        end)
    )

    -- goku (Karabiner EDN watcher)
    table.insert(
        items,
        serviceItem("goku", "goku", function()
            auto.restartGoku()
            osd.show("Restarted: goku", { duration = 0.9 })
        end)
    )

    -- Karabiner-Elements
    table.insert(
        items,
        serviceItem("karabiner-elements", "karabiner", function()
            restartKarabiner()
            osd.show("Restarted: Karabiner", { duration = 0.9 })
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

    -- Always-available console shortcut at the end
    table.insert(items, { title = "-" })
    -- Hammerspoon reload just above console
    table.insert(items, {
        title = "Hammerspoon (reload)",
        image = assetImage("hammerspoon-reload", { w = 18, h = 18 }, false),
        fn = function()
            osd.show("Reloading Hammerspoon…", { duration = 0.6 })
            hs.reload()
        end,
    })
    table.insert(items, {
        title = "Hammerspoon Console",
        image = assetImage("forge-menu", { w = 18, h = 18 }, false),
        fn = function()
            hs.openConsole()
        end,
    })

    -- Formerly "Advanced": always visible
    -- Keep Advanced section minimal; remove folder-opening items to avoid clutter

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

    -- No flagsChanged watcher

    -- Seed initial state from file
    seedStateFromFile()

    -- Subscribe to bus updates from integration.lua (single watcher source)
    bus.on("yabai-state", function(data)
        if type(data) ~= "table" then return end
        if data.mode then state.layout = tostring(data.mode) end
        if data.drop then state.drop = tostring(data.drop) end
        if data.gaps ~= nil then
            local g = tonumber(data.gaps)
            if g ~= nil then state.gaps = g > 0 end
        end
        if data.opacity then state.opacity = (tostring(data.opacity) == "on") end
        if data.label then state.label = tostring(data.label) end
        if data.idx then state.idx = tonumber(data.idx) end
        local spacePart
        if state.idx then
            if state.label and #state.label > 0 then
                spacePart = string.format("Space: %d • %s", state.idx, state.label)
            else
                spacePart = string.format("Space: %d", state.idx)
            end
        else
            spacePart = "Space: ?"
        end
        local tip = string.format(
            "%s • Layout: %s • Gaps: %s • Drop: %s • Opacity: %s",
            spacePart, tostring(state.layout), tostring(state.gaps and 1 or 0), tostring(state.drop), tostring(state.opacity and "on" or "off")
        )
        menubar:setTooltip(tip)
        menubar:setMenu(buildMenu)
    end)
end

-- Cleanup function
function M.stop()
    if menubar then
        menubar:delete()
        menubar = nil
    end
end

return M
