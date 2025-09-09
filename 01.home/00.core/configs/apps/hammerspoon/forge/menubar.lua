-- Title         : menubar.lua
-- Author        : Parametric Forge
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/forge/menubar.lua
-- ----------------------------------------------------------------------------
-- Minimal status/ops menubar: darwin-rebuild and service controls

local shlib = require("forge.sh")
local osd = require("forge.osd")
local auto = require("forge.auto")

local M = {}
-- cache for menu status to avoid lag on open
local menuCache = { layout = nil, drop = nil, gaps = nil, opacity = nil, sa = nil, health = {} }
local timers = { status = nil, health = nil }

-- Resolve assets directory (standard Hammerspoon deploy).
-- Canonical path: ~/.hammerspoon/assets (hs.configdir()/assets)
local function hsConfigDir()
  local v = hs.configdir
  if type(v) == "function" then return v() end
  if type(v) == "string" and #v > 0 then return v end
  return (os.getenv("HOME") or "") .. "/.hammerspoon"
end

local ASSETS_DIR = hsConfigDir() .. "/assets"

local imageCache = {}
local function assetImage(name, size, useTemplate)
  local key = name .. (size and (":" .. tostring(size.w) .. "x" .. tostring(size.h)) or "") .. (useTemplate and ":template" or "")
  if imageCache[key] then return imageCache[key] end
  local img
  local pathPng = ASSETS_DIR .. "/" .. name .. ".png"
  if hs.fs.attributes(pathPng) then img = hs.image.imageFromPath(pathPng) end
  if img then
    if size then
      if img.setSize then img = img:setSize(size) end
    end
    -- Only use template mode for the main menubar icon, not service status icons
    if useTemplate then
      if img.setTemplate then
        img = img:setTemplate(true)
      elseif img.template then
        img:template(true)
      end
    end
    imageCache[key] = img
  end
  return img
end

-- Note: removed old emoji status indicator 'green()' in favor of
-- template service icons and native on/off checkmarks.

-- Simple service management - no status polling needed

-- Karabiner restart via launchctl kickstart (admin)
local function restartKarabiner()
  -- Restart console user server without sudo (GUI domain)
  shlib.sh("/bin/launchctl kickstart -k gui/$UID org.pqrs.karabiner.karabiner_console_user_server || true")
  -- Restart system grabber with passwordless sudo (requires sudoers rule)
  -- If not permitted, this will fail silently due to -n and || true
  shlib.sh("sudo -n /bin/launchctl kickstart -k system/org.pqrs.karabiner.karabiner_grabber || true")
end

-- Darwin rebuild with escalation; simplified flake detection
local function findFlakeRoot()
  local home = os.getenv("HOME") or "/tmp"
  local flakeRoot = home .. "/Documents/99.Github/Parametric_Forge"
  if hs.fs.attributes(flakeRoot .. "/flake.nix") then
    return flakeRoot
  end
  return home
end

local function findDarwinRebuildPath()
  -- Prefer stable profile paths that match sudoers entries
  local candidates = {
    "/run/current-system/sw/bin/darwin-rebuild",
    "/nix/var/nix/profiles/default/bin/darwin-rebuild",
    (os.getenv("HOME") or "") .. "/.nix-profile/bin/darwin-rebuild",
  }
  for _, p in ipairs(candidates) do
    if p and #p > 0 and hs.fs.attributes(p) then return p end
  end
  local fromPath = shlib.sh("command -v darwin-rebuild 2>/dev/null | head -n1 | tr -d '\n'")
  if fromPath and #fromPath > 0 and hs.fs.attributes(fromPath) then
    return fromPath
  end
  return nil
end

local function darwinRebuild()
  local flakeRoot = findFlakeRoot()
  osd.show("darwin-rebuild started…", { duration = 1.0 })
  local drPath = findDarwinRebuildPath()
  if not drPath then
    osd.show("darwin-rebuild not found", { duration = 1.4 })
    return
  end
  local log = "/tmp/forge-darwin-rebuild.log"
  -- Run without AppleScript. Use passwordless sudo (-n). Log stdout+stderr.
  local cmd = string.format(
    "cd '%s' && : > '%s' && sudo -n env NIX_CONFIG='experimental-features = nix-command flakes' '%s' switch --flake . > '%s' 2>&1; rc=$?; printf '%s' $rc",
    flakeRoot, log, drPath, log, "%s"
  )
  local rc = shlib.sh(cmd)
  rc = (rc or ""):gsub("%s+$", "")
  if rc == "0" then
    osd.show("darwin-rebuild completed", { duration = 1.2 })
  else
    osd.show("darwin-rebuild failed (see /tmp/forge-darwin-rebuild.log)", { duration = 1.8 })
  end
end

-- Build static menu -----------------------------------------------
local flagsWatcher

local function isOptionDown()
  local mods = hs.eventtap.checkKeyboardModifiers() or {}
  return mods.alt == true
end

-- Forward declarations to avoid upvalue/global lookup issues
local menubar -- hs.menubar instance (created in start())
local buildMenu -- function value assigned below

local function serviceIcon(service)
  -- Always use the "on" icon - simple and consistent
  local img = assetImage(string.format("%s-on", service), { w = 18, h = 18 }, false)
  return img
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
  local img = serviceIcon(serviceKey)
  local item = {
    title = title,
    image = img,
    fn = onClick
  }
  return item
end

-- Background refreshers (decouple shell/JSON cost from click)
local function refreshStatus()
  -- layout
  local js = shlib.sh("yabai -m query --spaces 2>/dev/null")
  if js and js:match("^[%[{]") then
    local ok, arr = pcall(hs.json.decode, js)
    if ok and type(arr) == "table" then
      for _, s in ipairs(arr) do if s["has-focus"] then menuCache.layout = s.type or menuCache.layout end end
    end
  end
  -- drop
  local v = shlib.sh("yabai -m config mouse_drop_action 2>/dev/null") or ""
  menuCache.drop = (v:gsub("\n$", ""))
  if menuCache.drop == "" then menuCache.drop = "swap" end
  -- gaps
  local pad = shlib.sh("yabai -m config top_padding 2>/dev/null") or ""
  local n = tonumber((pad:gsub("\n$", ""))) or 0
  menuCache.gaps = n
  -- opacity
  local op = shlib.sh("yabai -m config window_opacity 2>/dev/null") or "off"
  menuCache.opacity = (op:gsub("\n$", ""))
  -- SA availability
  menuCache.sa = shlib.isSaAvailable()
end

local function refreshHealth()
  local h = {}
  local function running(p) return shlib.isProcessRunning(p) end
  h.yabai = running("yabai")
  h.skhd = running("skhd")
  h.borders = running("borders")
  h.goku = running("gokuw") or running("goku")
  h.karabiner = running("karabiner_grabber") or running("karabiner_console_user_server")
  menuCache.health = h
end

-- Simple static menu builder
function buildMenu()
  local items = {}
  -- Use cached status only; avoids lag at click time
  local cache = menuCache
  local function layout() return cache.layout or "?" end
  local function toggleLayout()
    local cur = layout()
    if cur == "bsp" then shlib.sh("yabai -m space --layout stack") else shlib.sh("yabai -m space --layout bsp") end
    cache.layout = (cur == "bsp") and "stack" or "bsp"
    osd.show("Layout: " .. layout(), { duration = 0.8 })
  end

  local function drop() return cache.drop or "swap" end
  local function toggleDrop()
    local cur = drop()
    if cur == "swap" then shlib.sh("yabai -m config mouse_drop_action stack"); cache.drop = "stack" else shlib.sh("yabai -m config mouse_drop_action swap"); cache.drop = "swap" end
    osd.show("Drop: " .. drop(), { duration = 0.8 })
  end

  local function gaps() return cache.gaps or 0 end
  local function toggleGapsAction()
    if gaps() == 0 then
      shlib.sh("yabai -m config top_padding 4; yabai -m config bottom_padding 4; yabai -m config left_padding 4; yabai -m config right_padding 4; yabai -m config window_gap 4")
      osd.show("Gaps: 4 px", { duration = 0.9 })
      cache.gaps = 4
    else
      shlib.sh("yabai -m config top_padding 0; yabai -m config bottom_padding 0; yabai -m config left_padding 0; yabai -m config right_padding 0; yabai -m config window_gap 0")
      osd.show("Gaps: 0 px", { duration = 0.9 })
      cache.gaps = 0
    end
  end

  local function opacity() return cache.opacity or "off" end
  local function toggleOpacity()
    if not require("forge.executor").sa.available then
      osd.show("Opacity requires SIP/SA", { duration = 1.2 })
      return
    end
    if opacity() == "off" or opacity() == "" then shlib.sh("yabai -m config window_opacity on"); cache.opacity = "on" else shlib.sh("yabai -m config window_opacity off"); cache.opacity = "off" end
    osd.show("Opacity: " .. opacity(), { duration = 0.9 })
  end

  local function saAvail() return cache.sa == true end

  -- icons (optional; falls back gracefully)
  local function icon(name) return assetImage(name, {w=16,h=16}, false) end
  local layoutIcon = (layout() == "bsp") and icon("layout-bsp") or icon("layout-stack")
  local dropIcon = (drop() == "stack") and icon("drop-stack") or icon("drop-swap")
  local gapsIcon = (gaps() == 0) and icon("gaps-off") or icon("gaps-on")
  local opacityIcon = (opacity() == "on") and icon("opacity-on") or icon("opacity-off")

  table.insert(items, { title = string.format("Layout: %s", (layout()=="bsp" and "BSP" or "Stack")), image = layoutIcon, fn = toggleLayout })
  table.insert(items, { title = string.format("Drop: %s", (drop()=="swap" and "Swap" or "Stack")), image = dropIcon, fn = toggleDrop })
  table.insert(items, { title = string.format("Gaps: %d px", gaps()), image = gapsIcon, fn = toggleGapsAction })
  table.insert(items, { title = string.format("Opacity: %s", (opacity()=="on" and "On" or "Off")), image = opacityIcon, fn = toggleOpacity, disabled = not saAvail() })
  table.insert(items, { title = "-" })
  table.insert(items, { title = "Darwin Rebuild", image = assetImage("forge-rebuild", {w=18,h=18}, false), fn = darwinRebuild })
  table.insert(items, { title = "-" })
  table.insert(items, { title = "Services", disabled = true })

  -- yabai
  table.insert(items, serviceItem("yabai", "yabai", function()
    auto.restartYabai()
    osd.show("Restarted: yabai", { duration = 0.9 })
  end))

  -- skhd
  table.insert(items, serviceItem("skhd", "skhd", function()
    auto.reloadSkhd()
    osd.show("Restarted: skhd", { duration = 0.9 })
  end))

  -- goku (Karabiner EDN watcher)
  table.insert(items, serviceItem("goku", "goku", function()
    auto.restartGoku()
    osd.show("Restarted: goku", { duration = 0.9 })
  end))


  -- Karabiner-Elements
  table.insert(items, serviceItem("karabiner-elements", "karabiner", function()
    restartKarabiner()
    osd.show("Restarted: Karabiner", { duration = 0.9 })
  end))
  -- Karabiner convenience actions (open settings and EventViewer like the menubar)
  table.insert(items, {
    title = "Karabiner Settings",
    image = assetImage("karabiner-on", {w=18,h=18}, false),
    fn = function()
      -- Officially recommended approach in Karabiner docs
      openApp("Karabiner-Elements")
    end
  })
  table.insert(items, {
    title = "Karabiner EventViewer",
    image = assetImage("karabiner-on", {w=18,h=18}, false),
    fn = function()
      openBundle("org.pqrs.Karabiner-EventViewer")
    end
  })

  -- Hammerspoon reload at bottom
  table.insert(items, { title = "-" })
  table.insert(items, {
    title = "Hammerspoon (reload)",
    image = assetImage("hammerspoon-reload", {w=18,h=18}, false),
    fn = function()
      osd.show("Reloading Hammerspoon…", { duration = 0.6 })
      hs.reload()
    end
  })

  -- Health checks ----------------------------------------------------------
  table.insert(items, { title = "-" })
  table.insert(items, { title = "Health", disabled = true })
  local function statusLine()
    local function ok(b) return b and "✓" or "✗" end
    local h = cache.health or {}
    local st = {
      string.format("yabai %s", ok(h.yabai)),
      string.format("skhd %s", ok(h.skhd)),
      string.format("borders %s", ok(h.borders)),
      string.format("goku %s", ok(h.goku)),
      string.format("karabiner %s", ok(h.karabiner)),
      string.format("SA %s", ok(saAvail())),
    }
    return table.concat(st, "  •  ")
  end
  table.insert(items, { title = statusLine(), disabled = true })
  table.insert(items, { title = "Run Health Checks", fn = function()
    refreshHealth()
    osd.show("Health: " .. statusLine(), { duration = 1.6 })
  end })

  -- Always-available console shortcut at the end
  table.insert(items, { title = "-" })
  table.insert(items, {
    title = "Hammerspoon Console",
    image = assetImage("forge-menu", {w=18,h=18}, false),
    fn = function() hs.openConsole() end
  })

  -- Advanced items (hold Option to reveal)
  if isOptionDown() then
    table.insert(items, { title = "-" })
    table.insert(items, { title = "Advanced", disabled = true })
    table.insert(items, {
      title = "Open Hammerspoon config folder",
      fn = function() hs.execute(string.format("open '%s'", hsConfigDir()), true) end,
      image = hs.image.imageFromName("NSFolderSmart")
    })
    table.insert(items, {
      title = "Open assets folder",
      fn = function() hs.execute(string.format("open '%s'", ASSETS_DIR), true) end,
      image = hs.image.imageFromName("NSFolderSmart")
    })
  end

  return items
end

function M.start()
  if menubar then return end
  menubar = hs.menubar.new()
  if not menubar then return end
  menubar:autosaveName("forge-menubar")
  
  -- Set icon (non-template to render as provided, e.g., pure white)
  local img = assetImage("forge-menu", {w=18,h=18}, false)
  if not img then
    local fallback = hs.image.imageFromName("NSAdvanced")
                    or hs.image.imageFromName("NSPreferencesGeneral")
                    or hs.image.imageFromName("NSActionTemplate")
    if fallback and fallback.setSize then
      img = fallback:setSize({w=18,h=18})
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
  
  -- Set static menu
  menubar:setMenu(buildMenu)

  -- Start background refreshers
  refreshStatus(); refreshHealth()
  if timers.status then timers.status:stop() end
  if timers.health then timers.health:stop() end
  timers.status = hs.timer.doEvery(1.2, refreshStatus)
  timers.health = hs.timer.doEvery(3.0, refreshHealth)

  -- Simple modifier key monitoring for Advanced menu
  if flagsWatcher then flagsWatcher:stop() end
  local lastAlt = isOptionDown()
  flagsWatcher = hs.eventtap.new({ hs.eventtap.event.types.flagsChanged }, function()
    local nowAlt = isOptionDown()
    if nowAlt ~= lastAlt then
      lastAlt = nowAlt
      menubar:setMenu(buildMenu)
    end
    return false
  end)
  flagsWatcher:start()
end

-- Cleanup function
function M.stop()
  if flagsWatcher then
    flagsWatcher:stop()
    flagsWatcher = nil
  end
  if menubar then
    menubar:delete()
    menubar = nil
  end
end

return M
