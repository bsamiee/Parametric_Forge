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
  stackOffset   = 44,       -- Vertical offset for stacked toasts
  margins       = { top = 0, left = 20 }, -- top 0 to align to yabai window top by default
  fadeIn        = 0.10,
  fadeOut       = 0.15,
  defaultMs     = 1200,
  centerWidth   = 420,      -- Default width for centered overlays
  height        = 40,       -- Default height for all overlays
  font          = { name = "Geist Mono", size = 15 },
  colors = {
    -- Dracula palette: bg #282a36, fg #f8f8f2, cyan #8be9fd
    bg     = { red = 0x28/255, green = 0x2a/255, blue = 0x36/255, alpha = 0.88 },
    text   = { red = 0xf8/255, green = 0xf8/255, blue = 0xf2/255, alpha = 0.80 },
    border = { red = 0x8b/255, green = 0xe9/255, blue = 0xfd/255, alpha = 0.50 },
    shadow = { red = 0x00/255, green = 0x00/255, blue = 0x00/255, alpha = 0.40 },
  },
}

-- State --------------------------------------------------------------------
local queue = { urgent = {}, normal = {}, info = {} }
local active = {}
local persist = {}   -- id -> { canvas, centered }

-- Track yabai insets to align overlays with managed window top
local yabaiInsets = {
  topPadding = 4,      -- yabai -m config top_padding
  externalTop = 4,     -- yabai external_bar top padding (we set 4 in yabairc)
}

-- Utilities ----------------------------------------------------------------
local function mainScreenFrames()
  local s = hs.screen.mainScreen()
  local f = s and s:frame() or hs.geometry.rect(0,0,1440,900)
  local ff = s and s:fullFrame() or f
  return f, ff
end

local function safeTopY(extraOffset)
  local f, ff = mainScreenFrames()
  -- Target alignment: window top used by yabai = frame.y + externalTop + topPadding
  local base = f.y + (yabaiInsets.externalTop or 0) + (yabaiInsets.topPadding or 0)
  local desired = base + (extraOffset or 0)
  -- Safety: never above the physical top line (avoid drawing into notch)
  local yMin = (ff.y or 0) + 1
  return math.max(desired, yMin)
end

local function newCanvas(x, y, w, h)
  local c = hs.canvas.new({ x = x, y = y, w = w, h = h })
  c:level(hs.canvas.windowLevels.overlay)
  -- Default: transient overlays render on the current space; persistent overlays will set canJoinAllSpaces.
  c:clickActivating(false)
  return c
end

local function layoutCentered(w)
  local f = select(1, mainScreenFrames())
  local x = f.x + (f.w - w) / 2
  local y = safeTopY(CFG.margins.top)
  return x, y
end

local function layoutStack(i, w)
  local f = select(1, mainScreenFrames())
  local x = f.x + CFG.margins.left
  local y = safeTopY((CFG.margins.top or 0) + (i * CFG.stackOffset))
  return x, y
end

local function applyStyle(c, message, w, h)
  local radius = 8
  c:replaceElements({
    {
      type = "rectangle",
      action = "fill",
      roundedRectRadii = { xRadius = radius, yRadius = radius },
      fillColor = CFG.colors.bg,
      shadow = { blurRadius = 8, color = CFG.colors.shadow, offset = { h = 2, w = 0 } },
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
      frame = { x = 12, y = 5, w = w - 24, h = h - 10 },
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
  local x, y
  if p.centered then x, y = layoutCentered(w) else x, y = layoutStack(0, w) end
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
  -- Reposition remaining stacked items
  for i, v in ipairs(active) do
    if v.canvas and not v.centered then
      local w, h = v.canvas:frame().w, v.canvas:frame().h
      local x, y = layoutStack(i-1, w)
      v.canvas:frame({ x = x, y = y, w = w, h = h })
    end
  end
  -- Continue queue
  M._process()
end

local function showNow(message, ms, centered)
  local idx = #active
  local w = centered and CFG.centerWidth or 320
  local h = CFG.height
  local x, y = centered and layoutCentered(w) or layoutStack(idx, w)
  local c = newCanvas(x, y, w, h)
  applyStyle(c, message, w, h)
  showCanvas(c)

  local n = { canvas = c, centered = centered, timer = nil }
  table.insert(active, n)

  n.timer = hs.timer.doAfter((ms or CFG.defaultMs)/1000, function() dismiss(n) end)
end

function M._process()
  if #active >= CFG.maxConcurrent then return end
  for _, pri in ipairs({"urgent","normal","info"}) do
    if #queue[pri] > 0 then
      local it = table.remove(queue[pri], 1)
      showNow(it.message, it.ms, it.centered)
      break
    end
  end
end

local function enqueue(message, pri, ms, centered)
  if #active < CFG.maxConcurrent then
    showNow(message, ms, centered)
  else
    table.insert(queue[pri], { message = message, ms = ms, centered = centered })
  end
end

-- Persistent Overlays ------------------------------------------------------
local function ensurePersistent(id, message, centered, width)
  local p = persist[id]
  local w = width or CFG.centerWidth
  local h = CFG.height
  if p and p.canvas then
    -- Update content and reposition on every call to avoid stale positions
    applyStyle(p.canvas, message, w, h)
    p.centered = centered and true or false
    repositionPersistent(id)
    return
  end
  local x, y = centered and layoutCentered(w) or layoutStack(0, w)
  local c = newCanvas(x, y, w, h)
  -- Make persistent overlays visible across all Spaces by default
  if hs and hs.canvas and hs.canvas.windowBehaviors and hs.canvas.windowBehaviors.canJoinAllSpaces then
    c:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)
  end
  applyStyle(c, message, w, h)
  showCanvas(c)
  persist[id] = { canvas = c, centered = centered and true or false }
end

-- Subscribe to yabai-state bus to track top padding changes
pcall(function()
  local bus = require("forge.bus")
  bus.on("yabai-state", function(st)
    if type(st) ~= "table" then return end
    if st.gaps ~= nil then
      local n = tonumber(st.gaps)
      if n then yabaiInsets.topPadding = n end
    end
    -- reposition any persistent overlays to reflect the new insets
    for id, _ in pairs(persist) do repositionPersistent(id) end
  end)
end)

-- Public API ---------------------------------------------------------------
function M.show(message, opts)
  opts = opts or {}
  enqueue(message, opts.priority or "normal", opts.duration and (opts.duration*1000) or CFG.defaultMs, opts.centered == true)
end

function M.showPersistent(id, message, opts)
  if not id then return end
  opts = opts or {}
  local centered = (opts.centered ~= false) -- default true
  ensurePersistent(id, message, centered, CFG.centerWidth)
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

