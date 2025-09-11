-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/forge/osd.lua
-- ----------------------------------------------------------------------------
-- Single shared-canvas OSD feed. Events flow downward from a fixed top anchor.

local M = {}

-- Config -------------------------------------------------------------------
local CFG = {
  width        = 520,  -- fixed width to avoid shifting X on new entries
  rowHeight    = 30,
  rowSpacing   = 6,
  maxRows      = 6,
  topOffset    = 8,    -- distance from top edge to canvas Y (fixed)
  defaultMs    = 2.5,  -- seconds per entry
  font         = { name = "GeistMono-Bold", size = 12 },
  colors = {
    bg     = { red = 0x15/255, green = 0x19/255, blue = 0x2F/255, alpha = 0.75 },
    text   = { red = 0xFF/255, green = 0x79/255, blue = 0xC6/255, alpha = 1.00 },
    border = { red = 0xf8/255, green = 0xf8/255, blue = 0xf2/255, alpha = 0.60 },
    shadow = { red = 0x00/255, green = 0x00/255, blue = 0x00/255, alpha = 0.75 },
  },
}

-- State --------------------------------------------------------------------
local container    -- hs.canvas (shared)
local anchorX, anchorY -- fixed top-left anchor (computed once)
local rows = {}    -- { id, text, deadline }
local idCounter = 0
local updating = false
local pendingUpdate = false

-- Delegate persistent indicators to specialized module
local persistentIndicator = require("forge.persistent_indicator")

-- Helpers ------------------------------------------------------------------
local function now() return hs.timer.secondsSinceEpoch() end

local function nextId()
  idCounter = idCounter + 1
  return idCounter
end

local function computeAnchor()
  if anchorX and anchorY then return anchorX, anchorY end
  local s = hs.screen.mainScreen()
  local f = s and s:frame() or hs.geometry.rect(0,0,1440,900)
  anchorX = f.x + (f.w - CFG.width) / 2
  anchorY = f.y + CFG.topOffset
  return anchorX, anchorY
end

local function ensureContainer()
  if container then return container end
  local x, y = computeAnchor()
  container = hs.canvas.new({ x = x, y = y, w = CFG.width, h = 1 })
  container:level(hs.canvas.windowLevels.overlay)
  container:clickActivating(false)
  -- Follow across Spaces at the exact same position
  if hs.canvas.windowBehaviors and hs.canvas.windowBehaviors.canJoinAllSpaces then
    container:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)
  end
  -- Start hidden; we show only when there are rows
  container:hide()
  return container
end

local function formatText(s)
  return string.upper(tostring(s or ""))
end

local function rowCount()
  local n = 0
  for _ in ipairs(rows) do n = n + 1 end
  return n
end

local function render()
  local c = ensureContainer()

  -- Clean expired entries first
  local now_time = now()
  local filtered = {}
  for _, r in ipairs(rows) do
    if r and r.deadline and now_time < r.deadline then
      table.insert(filtered, r)
    end
  end
  rows = filtered

  local n = #rows
  if n == 0 then
    c:hide()
    return
  end

  -- Build fresh elements array (never reuse tables)
  local totalH = n * CFG.rowHeight + (n - 1) * CFG.rowSpacing
  c:frame({ x = anchorX, y = anchorY, w = CFG.width, h = totalH })

  local elems = {}
  local radius = 12

  -- Background rectangle (create fresh table)
  elems[1] = {
    type = "rectangle",
    frame = { x = 0, y = 0, w = CFG.width, h = totalH },
    roundedRectRadii = { xRadius = radius, yRadius = radius },
    fillColor = { red = CFG.colors.bg.red, green = CFG.colors.bg.green, blue = CFG.colors.bg.blue, alpha = CFG.colors.bg.alpha },
    shadow = { blurRadius = 24, color = { red = 0, green = 0, blue = 0, alpha = 0.75 }, offset = { h = 2, w = 0 } },
  }

  -- Border rectangle (create fresh table)
  elems[2] = {
    type = "rectangle",
    action = "stroke",
    frame = { x = 0, y = 0, w = CFG.width, h = totalH },
    roundedRectRadii = { xRadius = radius, yRadius = radius },
    strokeColor = { red = CFG.colors.border.red, green = CFG.colors.border.green, blue = CFG.colors.border.blue, alpha = CFG.colors.border.alpha },
    strokeWidth = 1,
  }

  -- Text elements (create fresh tables)
  for i, r in ipairs(rows) do
    local y = (i - 1) * (CFG.rowHeight + CFG.rowSpacing)
    elems[i + 2] = {
      type = "text",
      frame = { x = 16, y = y + 6, w = CFG.width - 32, h = CFG.rowHeight - 12 },
      text = tostring(r.text or ""),
      textColor = { red = CFG.colors.text.red, green = CFG.colors.text.green, blue = CFG.colors.text.blue, alpha = 1.0 },
      textSize = CFG.font.size,
      textFont = CFG.font.name,
      textAlignment = "center",
    }
  end

  -- Safe atomic update with validation
  pcall(function()
    c:replaceElements(table.unpack(elems))
  end)
  c:show()
end

local function updateSafe(modifyFn)
  if updating then
    pendingUpdate = true
    return
  end

  updating = true
  pcall(function()
    if modifyFn then modifyFn() end
    render()
  end)
  updating = false

  if pendingUpdate then
    pendingUpdate = false
    updateSafe()
  end
end

-- Public API ---------------------------------------------------------------
function M.show(message, opts)
  opts = opts or {}
  local ttl = tonumber(opts.duration) or CFG.defaultMs
  local entryId = nextId()

  updateSafe(function()
    local entry = {
      id = entryId,
      text = formatText(message),
      deadline = now() + ttl,
    }

    table.insert(rows, 1, entry) -- newest on top
    while #rows > CFG.maxRows do
      table.remove(rows)
    end
  end)

  -- Schedule removal using safe update
  hs.timer.doAfter(ttl, function()
    updateSafe(function()
      for i = #rows, 1, -1 do
        local r = rows[i]
        if r and r.id == entryId then
          table.remove(rows, i)
          break
        end
      end
    end)
  end)
end

-- Persistent Indicator API (delegate to specialized module) ---------------
function M.showPersistent(message, priority)
  persistentIndicator.show(message, priority)
end

function M.hidePersistent(priority)
  persistentIndicator.hide(priority)
end

function M.hideAllPersistent()
  persistentIndicator.hideAllPersistent()
end

return M
