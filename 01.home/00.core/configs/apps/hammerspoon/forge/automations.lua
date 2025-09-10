-- Title         : automations.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/forge/automations.lua
-- ----------------------------------------------------------------------------
-- Download folder automations: unzip, webp→png, and optional DMG install.
-- Uses hs.pathwatcher + size-stability checks; all actions queued and OSD-notified.

local M = {}
local log   = hs.logger.new("forge.auto2", hs.logger.info)
local osd   = require("forge.osd")
local shlib = require("forge.sh")
local core  = require("forge.core")
local bus   = core.bus

local HOME = os.getenv("HOME") or ""
local DL   = HOME .. "/Downloads"

-- Persisted settings keys
local K = {
  unzip      = "forge.automations.unzip.enabled",
  webp2png   = "forge.automations.webp2png.enabled",
  dmgEnabled = "forge.automations.dmg.enabled", -- simple on/off
}

-- Defaults
if hs.settings.get(K.unzip)      == nil then hs.settings.set(K.unzip, true)      end
if hs.settings.get(K.webp2png)   == nil then hs.settings.set(K.webp2png, true)   end
if hs.settings.get(K.dmgEnabled) == nil then hs.settings.set(K.dmgEnabled, true) end

-- Helpers ---------------------------------------------------------------------

local function exists(p) return hs.fs.attributes(p) ~= nil end
local function sizeOf(p) local a = hs.fs.attributes(p); return a and a.size or 0 end
local function ext(p) return (p:lower():match("%.([a-z0-9]+)$") or "") end
local function base(p) return (p:gsub("/+$",""):match("([^/]+)$") or p) end
local function dirname(p) return (p:match("^(.*)/[^/]+$") or ".") end

local function stableAfter(path, ms, fn)
  if not exists(path) then return end
  local s0 = sizeOf(path)
  hs.timer.doAfter(ms/1000, function()
    if exists(path) and sizeOf(path) == s0 then pcall(fn) end
  end)
end

local function shouldIgnore(path)
  local name = base(path)
  if name:match("^%.") then return true end
  if name:match("%.download$") or name:match("%.crdownload$") or name:match("%.part$") then return true end
  return false
end

local function run(cmd) return shlib.sh(cmd) end

-- Queue to serialize heavier tasks
local Q = {running=false, items={}}
local function enqueue(fn)
  table.insert(Q.items, fn)
  if Q.running then return end
  local function step()
    local f = table.remove(Q.items, 1)
    if not f then Q.running=false; return end
    Q.running=true
    local ok, err = pcall(f)
    if not ok then log.w("automation task error: " .. tostring(err)) end
    hs.timer.doAfter(0.05, step)
  end
  step()
end



-- Actions ---------------------------------------------------------------------

local function actUnzip(zipPath)
  local dir = dirname(zipPath)
  local target = dir
  local cmd = string.format(
    "/usr/bin/ditto -x -k %q %q >/dev/null 2>&1 && /bin/rm -f %q",
    zipPath, target, zipPath
  )
  local ok = run(cmd)
  osd.show("Unzipped: " .. base(zipPath), { duration = 0.9 })
  return ok
end

local function actWebp2Png(webpPath)
  local out = webpPath:gsub("[Ww][Ee][Bb][Pp]$", "png")
  local cmd = string.format([[
    if command -v sips >/dev/null 2>&1; then /usr/bin/sips -s format png %q --out %q >/dev/null 2>&1;
    elif command -v magick >/dev/null 2>&1; then magick convert %q %q >/dev/null 2>&1;
    elif command -v ffmpeg >/dev/null 2>&1; then ffmpeg -y -loglevel error -i %q %q;
    else exit 127; fi
  ]], webpPath, out, webpPath, out, webpPath, out)
  local ok = run(cmd)
  if ok then run(string.format("/bin/rm -f %q", webpPath)) end
  osd.show("Converted: " .. base(out), { duration = 0.9 })
  return ok
end

local function actInstallDMG(dmgPath)
  if hs.settings.get(K.dmgEnabled) ~= true then return end

  local function doInstall()
    local attach = string.format('/usr/bin/hdiutil attach -nobrowse -readonly %q 2>/dev/null', dmgPath)
    local out = run(attach) or ""
    local mount = out:match("/Volumes/[^\n]+$") or out:match("(/Volumes/.-)\n")
    if not mount or #mount==0 then return end
    local findApp = run(string.format([[ /usr/bin/find %q -maxdepth 2 -iname "*.app" -type d -print -quit ]], mount)) or ""
    findApp = findApp:gsub("\n$","")
    if findApp == "" then run(string.format('/usr/bin/hdiutil detach %q >/dev/null 2>&1', mount)); return end
    -- attempt code sign assessment (non-fatal)
    run(string.format('/usr/sbin/spctl -a -vv --type exec %q >/dev/null 2>&1 || true', findApp))
    local target = "/Applications/" .. base(findApp)
    local copy = run(string.format('/usr/bin/ditto %q %q >/dev/null 2>&1', findApp, target))
    run(string.format('/usr/bin/hdiutil detach %q >/dev/null 2>&1', mount))
    if copy then osd.show("Installed: " .. base(findApp), { duration = 1.0 }) end
  end

  enqueue(doInstall)
end

-- Watchers --------------------------------------------------------------------

local watchers = {}   -- key -> hs.pathwatcher

local function startWatcher(key, paths, callback)
  if watchers[key] then return end
  local function onChange(files, _)
    for _, f in ipairs(files) do
      if exists(f) and not shouldIgnore(f) then
        stableAfter(f, 800, function() callback(f) end)
      end
    end
  end
  local ws = {}
  for _, p in ipairs(paths) do
    local w = hs.pathwatcher.new(p, onChange):start()
    table.insert(ws, w)
  end
  watchers[key] = ws
end

local function stopWatcher(key)
  local ws = watchers[key]
  if not ws then return end
  for _, w in ipairs(ws) do pcall(function() w:stop() end) end
  watchers[key] = nil
end

-- Public API ------------------------------------------------------------------

local function emitState()
  bus.emit("automations-state", {
    unzip = hs.settings.get(K.unzip) == true,
    webp2png = hs.settings.get(K.webp2png) == true,
    dmg = hs.settings.get(K.dmgEnabled) == true,
  })
end

function M.enable(name)
  if name == "unzip" then
    hs.settings.set(K.unzip, true)
    startWatcher("unzip", { DL }, function(p) if ext(p)=="zip" then enqueue(function() actUnzip(p) end) end end)
  elseif name == "webp2png" then
    hs.settings.set(K.webp2png, true)
    startWatcher("webp2png", { DL }, function(p) if ext(p)=="webp" then enqueue(function() actWebp2Png(p) end) end end)
  end
  osd.show("Automation on: " .. name, { duration = 0.8 })
  emitState()
end

function M.disable(name)
  if name == "unzip"   then hs.settings.set(K.unzip, false);   stopWatcher("unzip")   end
  if name == "webp2png" then hs.settings.set(K.webp2png, false); stopWatcher("webp2png") end
  osd.show("Automation off: " .. name, { duration = 0.8 })
  emitState()
end

function M.toggle(name)
  local map = { unzip=K.unzip, webp2png=K.webp2png }
  local k = map[name]; if not k then return end
  if hs.settings.get(k) then M.disable(name) else M.enable(name) end
end

function M.setDmgEnabled(enabled)
  local on = enabled and true or false
  hs.settings.set(K.dmgEnabled, on)
  osd.show("DMG auto-install: " .. (on and "On" or "Off"), { duration = 0.8 })
  stopWatcher("dmg")
  if on then
    startWatcher("dmg", { DL }, function(p) if ext(p)=="dmg" then enqueue(function() actInstallDMG(p) end) end end)
  end
  emitState()
end

function M.getDmgEnabled() return hs.settings.get(K.dmgEnabled) == true end
function M.isEnabled(name)
  if name=="unzip"    then return hs.settings.get(K.unzip)    == true end
  if name=="webp2png" then return hs.settings.get(K.webp2png) == true end
  if name=="dmg"      then return hs.settings.get(K.dmgEnabled) == true end
  return false
end

function M.start()
  if hs.settings.get(K.unzip)      then M.enable("unzip")    end
  if hs.settings.get(K.webp2png)   then M.enable("webp2png") end
  if hs.settings.get(K.dmgEnabled) then M.setDmgEnabled(true) end
  emitState()
  log.i("forge.automations started")
end

function M.stop()
  stopWatcher("unzip"); stopWatcher("webp2png"); stopWatcher("dmg")
end

return M
