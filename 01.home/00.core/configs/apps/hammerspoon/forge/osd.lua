-- Title         : osd.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/forge/osd.lua
-- ----------------------------------------------------------------------------
-- Lightweight, snappy OSD for transient and persistent overlays.
-- Goals:
--  - Centered top overlays by default (space/layout status)
--  - Fast updates with minimal redraws
--  - No stale positions on screen/space changes
--  - Simple API compatible with existing calls

local M = {}

-- Config -------------------------------------------------------------------
local CFG = {
  maxConcurrent = 3,        -- Max transient toasts at once
  fadeIn        = 0.10,
  fadeOut       = 0.25,
  defaultMs     = 2100,
  minWidth      = 300,      -- Minimum width for dynamic sizing
  maxWidth      = 600,      -- Maximum width for dynamic sizing
  height        = 32,       -- Reduced height for refined appearance
  topOffset     = 8,        -- y = frame.y + topOffset
  -- Use Geist Mono Bold face explicitly. Common registered names include
  -- "GeistMono-Bold" and "Geist Mono Bold"; we select the first, which matches
  -- the installed OTF screenshot provided.
  font          = { name = "GeistMono-Bold", size = 12 },
  colors = {
    -- Dracula palette (official): bg #282a36, comment #6272a4, cyan #8be9fd
    -- Background at 75% alpha per request
    bg     = { red = 0x28/255, green = 0x2a/255, blue = 0x36/255, alpha = 0.75 },
    -- Text color set to Dracula Magenta (aka Pink) #FF79C6
    text   = { red = 0xFF/255, green = 0x79/255, blue = 0xC6/255, alpha = 1.00 },
    -- Border color set to Dracula Comment #6272A4
    border = { red = 0x62/255, green = 0x72/255, blue = 0xA4/255, alpha = 1.00 },
    shadow = { red = 0x00/255, green = 0x00/255, blue = 0x00/255, alpha = 0.40 },
  },
}

-- State --------------------------------------------------------------------
local queue = { urgent = {}, normal = {}, info = {} }
local active = {}
local persist = {}   -- id -> { canvas }

-- Utilities ----------------------------------------------------------------
local function newCanvas(x, y, w, h)
  local c = hs.canvas.new({ x = x, y = y, w = w, h = h })
  c:level(hs.canvas.windowLevels.overlay)
  -- Default: transient overlays render on the current space; persistent overlays will set canJoinAllSpaces.
  c:clickActivating(false)
  return c
end

local function layoutCenteredTop(w)
  local s = hs.screen.mainScreen()
  local f = s and s:frame() or hs.geometry.rect(0,0,1440,900)
  local x = f.x + (f.w - w) / 2
  local y = f.y + CFG.topOffset
  return x, y
end

local function calculateOptimalWidth(message)
  -- Use hs.drawing.getTextDrawingSize for robust text measurement
  local txt = tostring(message or "")
  local sz = hs.drawing.getTextDrawingSize(txt, { font = CFG.font.name, size = CFG.font.size }) or { w = CFG.minWidth }
  local w = (sz and sz.w) or CFG.minWidth
  return math.max(CFG.minWidth, math.min(CFG.maxWidth, w + 48))
end

-- Ensure consistent formatting for all OSD text without changing font or position
local function formatMessage(message)
  -- Always render as uppercase for improved readability
  local txt = tostring(message or "")
  -- Lua string.upper covers ASCII reliably; acceptable for our OSD usage
  return string.upper(txt)
end

local function applyStyle(c, message, w, h)
  local radius = 12
  c:replaceElements({
    {
      type = "rectangle",
      action = "fill",
      roundedRectRadii = { xRadius = radius, yRadius = radius },
      fillColor = CFG.colors.bg,
      shadow = { blurRadius = 32, color = CFG.colors.shadow, offset = { h = 2, w = 0 } },
    },
    {
      type = "rectangle",
      action = "stroke",
      roundedRectRadii = { xRadius = radius, yRadius = radius },
      strokeColor = CFG.colors.border,
      strokeWidth = 1.0,
    },
    {
      type = "text",
      text = message,
      textColor = CFG.colors.text,
      textSize = CFG.font.size,
      textFont = CFG.font.name,
      frame = { x = 16, y = 6, w = w - 32, h = h - 12 },
      textAlignment = "center",
    },
  })
end

local function showCanvas(c)
  c:alpha(0):show()
  c:alpha(1)
end

local function repositionPersistent(id)
  local p = persist[id]
  if not p or not p.canvas then return end
  local w, h = p.canvas:frame().w, p.canvas:frame().h
  local x, y = layoutCenteredTop(w)
  p.canvas:frame({ x = x, y = y, w = w, h = h })
end

-- Transient Toasts ---------------------------------------------------------
local function dismiss(n)
  if not n then return end
  if n.timer then n.timer:stop(); n.timer = nil end
  if n.canvas then
    n.canvas:alpha(0)
    hs.timer.doAfter(CFG.fadeOut, function()
      pcall(function() n.canvas:delete() end)
    end)
  end
  for i, v in ipairs(active) do
    if v == n then table.remove(active, i) break end
  end
  -- Continue queue
  M._process()
end

local function showNow(message, ms)
  local formatted = formatMessage(message)
  local w = calculateOptimalWidth(formatted)
  local h = CFG.height
  local x, y = layoutCenteredTop(w)
  local c = newCanvas(x, y, w, h)
  applyStyle(c, formatted, w, h)
  showCanvas(c)

  local n = { canvas = c, timer = nil }
  table.insert(active, n)

  n.timer = hs.timer.doAfter((ms or CFG.defaultMs)/1000, function() dismiss(n) end)
end

function M._process()
  if #active >= CFG.maxConcurrent then return end
  for _, pri in ipairs({"urgent","normal","info"}) do
    if #queue[pri] > 0 then
      local it = table.remove(queue[pri], 1)
      showNow(it.message, it.ms)
      break
    end
  end
end

local function enqueue(message, pri, ms)
  if #active < CFG.maxConcurrent then
    showNow(message, ms)
  else
    table.insert(queue[pri], { message = message, ms = ms })
  end
end

-- Persistent Overlays ------------------------------------------------------
local function ensurePersistent(id, message, width)
  local p = persist[id]
  local formatted = formatMessage(message)
  local w = width or calculateOptimalWidth(formatted)
  local h = CFG.height
  if p and p.canvas then
    -- Update content and reposition on every call to avoid stale positions
    applyStyle(p.canvas, formatted, w, h)
    repositionPersistent(id)
    return
  end
  local x, y = layoutCenteredTop(w)
  local c = newCanvas(x, y, w, h)
  -- Make persistent overlays visible across all Spaces by default
  if hs and hs.canvas and hs.canvas.windowBehaviors and hs.canvas.windowBehaviors.canJoinAllSpaces then
    c:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)
  end
  applyStyle(c, formatted, w, h)
  showCanvas(c)
  persist[id] = { canvas = c }
end

-- Intentionally no external bus/watchers: compute position simply on show

-- Public API ---------------------------------------------------------------
function M.show(message, opts)
  opts = opts or {}
  enqueue(message, opts.priority or "normal", opts.duration and (opts.duration*1000) or CFG.defaultMs)
end

function M.showPersistent(id, message, opts)
  if not id then return end
  opts = opts or {}
  ensurePersistent(id, message, opts.width)
end

function M.hidePersistent(id)
  local p = persist[id]
  if not p then return end
  if p.canvas then pcall(function() p.canvas:delete() end) end
  persist[id] = nil
end

function M.hideAllPersistent()
  for id, p in pairs(persist) do
    if p.canvas then pcall(function() p.canvas:delete() end) end
    persist[id] = nil
  end
end

function M.repositionAll()
  for id, _ in pairs(persist) do repositionPersistent(id) end
end

function M.notifyCaffeine(state)
  M.show(state and "Caffeine: Enabled" or "Caffeine: Disabled", { duration = 0.9, centered = true })
end

return M
