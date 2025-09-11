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
    core.sh("/bin/launchctl kickstart -k gui/$UID org.pqrs.karabiner.karabiner_console_user_server || true")
    -- Restart system grabber with passwordless sudo (requires sudoers rule)
    -- If not permitted, this will fail silently due to -n and || true
    core.sh("sudo -n /bin/launchctl kickstart -k system/org.pqrs.karabiner.karabiner_grabber || true")
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
                core.sh("yabai -m space --layout " .. next)
                osd.show("Layout: " .. (next == "bsp" and "BSP" or "Stack"))
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
                core.sh("yabai -m config mouse_drop_action " .. next)
                osd.show("Drop: " .. (next == "stack" and "Stack" or "Swap"))
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
                    core.sh("yabai -m config top_padding 0; yabai -m config bottom_padding 0; yabai -m config left_padding 0; yabai -m config right_padding 0; yabai -m config window_gap 0; yabai -m config external_bar all:0:0")
                    osd.show("Gaps: Disabled")
                    state.gaps = false
                else
                    core.sh("yabai -m config top_padding 4; yabai -m config bottom_padding 4; yabai -m config left_padding 4; yabai -m config right_padding 4; yabai -m config window_gap 4; yabai -m config external_bar all:4:4")
                    osd.show("Gaps: Enabled")
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
                core.sh("yabai -m config window_opacity " .. next)
                osd.show("Opacity: " .. (next == "on" and "Enabled" or "Disabled"))
                state.opacity = (next == "on")
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

    -- Always-available console shortcut at the end
    table.insert(items, { title = "-" })
    -- Hammerspoon reload just above console
    table.insert(items, {
        title = "Hammerspoon (reload)",
        image = assetImage("hammerspoon-reload", { w = 18, h = 18 }, false),
        fn = function()
            osd.show("Reloading Hammerspoon…")
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
