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

local M = {}

-- Assets (SF Symbols exported as template PDFs) expected at:
--   ~/.config/hammerspoon/assets/
-- using nix to deploy
local ASSETS_BASE = (hs.configdir or os.getenv("HOME") .. "/.hammerspoon") .. "/assets"

local function assetImage(name, size)
  local pathPdf = ASSETS_BASE .. "/" .. name .. ".pdf"
  local img
  if hs.fs.attributes(pathPdf) then img = hs.image.imageFromPath(pathPdf) end
  if img then
    img = img:template(true)
    if size then img = img:size(size) end
  end
  return img
end

local brewPath -- resolved once
local function findBrew()
  if brewPath then return brewPath end
  if hs.fs.attributes("/opt/homebrew/bin/brew") then
    brewPath = "/opt/homebrew/bin/brew"
  elseif hs.fs.attributes("/usr/local/bin/brew") then
    brewPath = "/usr/local/bin/brew"
  else
    local out = shlib.sh([[command -v brew 2>/dev/null | head -n1 | tr -d '\n']])
    brewPath = (out and #out > 0) and out or "brew"
  end
  return brewPath
end

local function green(b) return b and "🟢" or "🔴" end

-- Generic brew-services status (falls back to pgrep if not present)
local function brewIsStarted(name, pgrepName)
  local brew = findBrew()
  local out = shlib.sh(string.format("'%s' services list 2>/dev/null | awk '$1==\"%s\" {print $2}' | tr -d '\n'", brew, name))
  if out and (out == "started" or out == "startedroot") then
    return true
  end
  if pgrepName and #pgrepName > 0 then
    return shlib.isProcessRunning(pgrepName)
  end
  return false
end

local function brewRestart(name)
  local brew = findBrew()
  local cmd = string.format("'%s' services restart '%s' >/dev/null 2>&1 || '%s' services start '%s' >/dev/null 2>&1", brew, name, brew, name)
  shlib.sh(cmd)
end

-- Async runner for non-blocking UI
local function runAsync(cmd, onExit)
  local escPATH = (shlib.PATH or os.getenv("PATH")):gsub("'", "'\\''")
  local full = string.format("PATH='%s' %s", escPATH, cmd)
  hs.task.new("/bin/sh", function(exitCode)
    if onExit then onExit(exitCode) end
  end, {"-lc", full}):start()
end

-- Karabiner restart via launchctl kickstart (admin)
local function restartKarabiner()
  local script = [[
    do shell script "launchctl kickstart -k gui/$UID org.pqrs.karabiner.karabiner_console_user_server; \
                     launchctl kickstart -k system/org.pqrs.karabiner.karabiner_grabber" with administrator privileges
  ]]
  -- Run asynchronous to avoid blocking the UI
  hs.task.new("/usr/bin/osascript", function() end, {"-e", script}):start()
end

-- Darwin rebuild with escalation; finds flake root by walking up to flake.nix
local function findFlakeRoot()
  -- Derive from this file path
  local src = debug.getinfo(1, "S").source or ""
  local path = src:gsub("^@", "")
  if path == "" then return os.getenv("HOME") end
  local dir = path:match("^(.*)/[^/]+$") or path
  dir = hs.fs.pathToAbsolute(dir) or dir
  -- ascend a few levels to locate flake.nix
  for _ = 1, 8 do
    if hs.fs.attributes(dir .. "/flake.nix") then
      return dir
    end
    local parent = hs.fs.pathToAbsolute(dir .. "/..")
    if not parent or parent == dir then break end
    dir = parent
  end
  -- common fallback: repo under Documents
  local cand = os.getenv("HOME") .. "/Documents/99.Github/Parametric_Forge"
  if hs.fs.attributes(cand .. "/flake.nix") then return cand end
  return os.getenv("HOME") or "/"
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
    state = running and not restarting[serviceKey] and "on" or "off",
    image = img,
    fn = function()
      -- show restarting while action runs
      restarting[serviceKey] = true
      if menubar then menubar:setMenu(buildMenu) end
      onClick(function()
        restarting[serviceKey] = false
        if menubar then
          hs.timer.doAfter(0.2, function() menubar:setMenu(buildMenu) end)
        end
      end)
    end,
  }
  return item
end

local function buildMenu()
  local items = {}
  table.insert(items, { title = "Darwin Rebuild…", image = assetImage("forge-rebuild", {w=18,h=18}), fn = darwinRebuild })
  table.insert(items, { title = "-" })
  table.insert(items, { title = "Services", disabled = true })

  -- yabai
  local yabaiUp = brewIsStarted("yabai", "yabai")
  table.insert(items, serviceItem("yabai", "yabai", yabaiUp, function(done)
    runAsync(string.format("'%s' services restart yabai >/dev/null 2>&1 || '%s' services start yabai >/dev/null 2>&1", findBrew(), findBrew()), function()
      osd.show("Restarted: yabai", { duration = 0.9 })
      if done then done() end
    end)
  end))

  -- skhd
  local skhdUp = brewIsStarted("skhd", "skhd")
  table.insert(items, serviceItem("skhd", "skhd", skhdUp, function(done)
    runAsync(string.format("'%s' services restart skhd >/dev/null 2>&1 || '%s' services start skhd >/dev/null 2>&1", findBrew(), findBrew()), function()
      osd.show("Restarted: skhd", { duration = 0.9 })
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

  return items
end

local menubar
function M.start()
  if menubar then return end
  menubar = hs.menubar.new()
  if not menubar then return end
  menubar:autosaveName("forge-menubar")
  local img = assetImage("forge-menu", {w=18,h=18}) or hs.image.imageFromName("NSActionTemplate")
  if img then
    menubar:setIcon(img, true)
  else
    menubar:setTitle("⚙︎")
  end
  menubar:setTooltip("Parametric Forge")
  menubar:setMenu(buildMenu)
end

return M

