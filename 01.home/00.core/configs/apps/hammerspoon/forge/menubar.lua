-- Title         : menubar.lua
-- Author        : Parametric Forge
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/forge/menubar.lua
-- ----------------------------------------------------------------------------
-- Minimal status/ops menubar: darwin-rebuild and service controls

local shlib = require("forge.sh")
local osd = require("forge.osd")
local integ = require("forge.integration")
local auto = require("forge.auto")

local M = {}

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
local function assetImage(name, size)
  local key = name .. (size and (":" .. tostring(size.w) .. "x" .. tostring(size.h)) or "")
  if imageCache[key] then return imageCache[key] end
  local img
  local pathPng = ASSETS_DIR .. "/" .. name .. ".png"
  if hs.fs.attributes(pathPng) then img = hs.image.imageFromPath(pathPng) end
  if img then
    -- ensure size and template are applied; setSize/template often return the image
    if size then
      if img.setSize then img = img:setSize(size) end
    end
    if img.setTemplate then
      img = img:setTemplate(true)
    elseif img.template then
      img:template(true)
    end
    imageCache[key] = img
  end
  return img
end

-- Note: removed old emoji status indicator 'green()' in favor of
-- template service icons and native on/off checkmarks.

-- Generic brew-services status (falls back to pgrep if not present)
local function isProcRunning(name)
  return shlib.isProcessRunning(name)
end

-- Note: no Homebrew dependency or async shell helper required

-- Karabiner restart via launchctl kickstart (admin)
local function restartKarabiner()
  local script = [[
    do shell script "launchctl kickstart -k gui/$UID org.pqrs.karabiner.karabiner_console_user_server; \
                     launchctl kickstart -k system/org.pqrs.karabiner.karabiner_grabber" with administrator privileges
  ]]
  -- Run asynchronous to avoid blocking the UI
  hs.task.new("/usr/bin/osascript", function() end, {"-e", script}):start()
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

local function darwinRebuild()
  local flakeRoot = findFlakeRoot()
  osd.show("darwin-rebuild started…", { duration = 1.0 })
  local escPATH = (shlib.PATH or os.getenv("PATH")):gsub("'", "'\\''")
  local script = string.format([[do shell script "cd '%s' && /usr/bin/env PATH='%s' darwin-rebuild switch --flake ." with administrator privileges]], flakeRoot, escPATH)
  hs.task.new("/usr/bin/osascript", function(exitCode)
    if exitCode == 0 then
      osd.show("darwin-rebuild completed", { duration = 1.2 })
    else
      osd.show("darwin-rebuild failed", { duration = 1.5 })
    end
  end, {"-e", script}):start()
end

-- Build dynamic menu -----------------------------------------------
-- track transient restarting states per service for icon presentation
local restarting = {}
local flagsWatcher

local function isOptionDown()
  local mods = hs.eventtap.checkKeyboardModifiers() or {}
  return mods.alt == true
end

-- Forward declarations to avoid upvalue/global lookup issues
local menubar -- hs.menubar instance (created in start())
local buildMenu -- function value assigned below

local function serviceIcon(service, status)
  -- names: <service>-on/off/restarting
  local img = assetImage(string.format("%s-%s", service, status), { w = 18, h = 18 })
  return img
end

local function serviceItem(title, serviceKey, running, onClick)
  local status = restarting[serviceKey] and "restarting" or (running and "on" or "off")
  local img = serviceIcon(serviceKey, status)
  local item = {
    title = title,
    -- Use icons only (checked marks hide images in some setups)
    image = img,
    fn = function()
      -- show restarting while action runs
      restarting[serviceKey] = true
      -- Rebind menu using our function value (not global) to refresh icons/states
      if menubar and buildMenu then menubar:setMenu(buildMenu) end
      onClick(function()
        restarting[serviceKey] = false
        if menubar and buildMenu then
          hs.timer.doAfter(0.2, function() menubar:setMenu(buildMenu) end)
        end
      end)
    end,
  }
  return item
end

function buildMenu()
  local items = {}
  table.insert(items, { title = "Darwin Rebuild…", image = assetImage("forge-rebuild", {w=18,h=18}), fn = darwinRebuild })
  table.insert(items, { title = "-" })
  table.insert(items, { title = "Services", disabled = true })

  -- yabai
  local yabaiUp = isProcRunning("yabai")
  table.insert(items, serviceItem("yabai", "yabai", yabaiUp, function(done)
    hs.timer.doAfter(0.05, function()
      auto.restartYabai()
      if done then done() end
    end)
  end))

  -- skhd
  local skhdUp = isProcRunning("skhd")
  table.insert(items, serviceItem("skhd", "skhd", skhdUp, function(done)
    hs.timer.doAfter(0.05, function()
      auto.reloadSkhd()
      if done then done() end
    end)
  end))

  -- JankyBorders (borders)
  local bordersUp = shlib.isProcessRunning("borders")
  table.insert(items, serviceItem("jankyborders", "jankyborders", bordersUp, function(done)
    hs.timer.doAfter(0.05, function()
      integ.ensureBorders({ forceRestart = true })
      osd.show("Restarted: jankyborders", { duration = 0.9 })
      if done then done() end
    end)
  end))

  -- Hammerspoon (reload config)
  table.insert(items, {
    title = "hammerspoon (reload)",
    image = assetImage("hammerspoon-reload", {w=18,h=18}),
    fn = function()
      osd.show("Reloading Hammerspoon…", { duration = 0.6 })
      hs.reload()
    end
  })

  -- Karabiner-Elements
  local keUp = shlib.isProcessRunning("karabiner_console_user_server")
  table.insert(items, serviceItem("karabiner-elements", "karabiner", keUp, function(done)
    restartKarabiner()
    hs.timer.doAfter(0.9, function()
      osd.show("Restarted: Karabiner", { duration = 0.9 })
      if done then done() end
    end)
  end))

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
    table.insert(items, {
      title = "Open Hammerspoon Console",
      fn = function() hs.openConsole() end,
      image = hs.image.imageFromName("NSAdvanced")
    })
  end

  return items
end

function M.start()
  if menubar then return end
  menubar = hs.menubar.new()
  if not menubar then return end
  menubar:autosaveName("forge-menubar")
  local img = assetImage("forge-menu", {w=18,h=18})
              or hs.image.imageFromName("NSAdvanced")
              or hs.image.imageFromName("NSPreferencesGeneral")
              or hs.image.imageFromName("NSActionTemplate")
  if img then
    menubar:setIcon(img, true)
  else
    menubar:setTitle("⚙︎")
  end
  menubar:setTooltip("Parametric Forge")
  menubar:setMenu(buildMenu)

  -- Rebuild menu when modifier flags change (to reveal Advanced items)
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

return M
