-- Title         : automations.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/forge/automations.lua
-- ----------------------------------------------------------------------------
-- Download folder automations: unzip, webp→png, and optional DMG install.
-- Uses hs.pathwatcher + size-stability checks; all actions queued and OSD-notified.

local M = {}
local log   = hs.logger.new("forge.auto", hs.logger.info)
local osd   = require("forge.osd")
local core = require("forge.core")
local bus = core.bus

local HOME = os.getenv("HOME") or ""
local DL   = HOME .. "/Downloads"

-- Persisted settings keys
local K = {
  unzip      = "forge.automations.unzip.enabled",
  webp2png   = "forge.automations.webp2png.enabled",
  pdf        = "forge.automations.pdf.enabled",
}

-- Defaults
if hs.settings.get(K.unzip)      == nil then hs.settings.set(K.unzip, true)      end
if hs.settings.get(K.webp2png)   == nil then hs.settings.set(K.webp2png, true)   end
if hs.settings.get(K.pdf)        == nil then hs.settings.set(K.pdf, true)        end

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

local function run(cmd) return core.sh(cmd) end

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
  osd.show("Unzipped: " .. base(zipPath))
  return ok
end

local function actWebp2Png(webpPath)
  local out = webpPath:gsub("[Ww][Ee][Bb][Pp]$", "png")
  local cmd = string.format("magick %q %q", webpPath, out)
  local ok = run(cmd)
  if ok then run(string.format("rm -f %q", webpPath)) end
  osd.show("Converted: " .. base(out))
  return ok
end

local function actPdfOptimize(pdfPath)
  -- Check if PDF already has substantial text (likely vector-based)
  local textCheck = run(string.format("pdftotext %q - 2>/dev/null | wc -c", pdfPath))
  local textLength = tonumber(textCheck and textCheck:match("%d+")) or 0

  -- Skip vector PDFs (those with substantial text content)
  if textLength > 50 then
    return false
  end

  -- Use OCRmyPDF for intelligent processing: OCR + optimization
  local cmd = string.format("ocrmypdf --optimize 3 --skip-text %q %q", pdfPath, pdfPath)
  local ok = run(cmd)

  if ok then
    osd.show("PDF optimized: " .. base(pdfPath))
  end
  return ok
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
    pdf = hs.settings.get(K.pdf) == true,
  })
end

function M.enable(name)
  if name == "unzip" then
    hs.settings.set(K.unzip, true)
    startWatcher("unzip", { DL }, function(p) if ext(p)=="zip" then enqueue(function() actUnzip(p) end) end end)
  elseif name == "webp2png" then
    hs.settings.set(K.webp2png, true)
    startWatcher("webp2png", { DL }, function(p) if ext(p)=="webp" then enqueue(function() actWebp2Png(p) end) end end)
  elseif name == "pdf" then
    hs.settings.set(K.pdf, true)
    startWatcher("pdf", { DL }, function(p) if ext(p)=="pdf" then enqueue(function() actPdfOptimize(p) end) end end)
  end
  osd.show("Automation on: " .. name)
  emitState()
end

function M.disable(name)
  if name == "unzip"   then hs.settings.set(K.unzip, false);   stopWatcher("unzip")   end
  if name == "webp2png" then hs.settings.set(K.webp2png, false); stopWatcher("webp2png") end
  if name == "pdf"     then hs.settings.set(K.pdf, false);     stopWatcher("pdf")     end
  osd.show("Automation off: " .. name)
  emitState()
end

function M.toggle(name)
  local map = { unzip=K.unzip, webp2png=K.webp2png, pdf=K.pdf }
  local k = map[name]; if not k then return end
  if hs.settings.get(k) then M.disable(name) else M.enable(name) end
end


function M.isEnabled(name)
  if name=="unzip"    then return hs.settings.get(K.unzip)    == true end
  if name=="webp2png" then return hs.settings.get(K.webp2png) == true end
  if name=="pdf"      then return hs.settings.get(K.pdf)      == true end
  return false
end

function M.start()
  if hs.settings.get(K.unzip)      then M.enable("unzip")    end
  if hs.settings.get(K.webp2png)   then M.enable("webp2png") end
  if hs.settings.get(K.pdf)        then M.enable("pdf")      end
  emitState()
  log.i("forge.automations started")
end

function M.stop()
  stopWatcher("unzip"); stopWatcher("webp2png"); stopWatcher("pdf")
end

return M
