-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/notifications/persistent_canvas.lua
-- ----------------------------------------------------------------------------
-- Persistent, top-right notification panel managed by keyed states.
-- Aesthetics intentionally match notifications/canvas.lua (transient OSD):
-- same background, border, radius, shadow, font, row metrics; only location differs.
-- Simple API: init, set(id, { text }), remove(id), clear(), show(), hide().

local M = {}
local styles = require("notifications.styles")

-- Defaults (tuned for unobtrusive, legible status)
local DEFAULTS = {
  width = styles.width,
  marginTop = styles.topOffset,
  marginRight = 4,
  rowHeight = styles.rowHeight,
  rowSpacing = styles.rowSpacing,
  radius = styles.radius,
  fontName = styles.font.name,
  fontSize = styles.font.size,
  maxItems = styles.maxMessages,
  colors = {
    bg = styles.colors.bg,
    border = styles.colors.border,
    text = styles.colors.text,
  }
}

-- Internal state
local opts = nil
local canvas = nil
local screenWatcher = nil
local states = {}         -- map: id -> { text }
local order = {}          -- array of ids to preserve insertion ordering
local idCounter = 0       -- monotonic for order (if needed)

-- Compute panel frame at top-right of main screen
local function computeFrame(itemCount)
  local screen = hs.screen.mainScreen()
  local frame = screen and screen:frame() or { x = 0, y = 0, w = 1440, h = 900 }
  local h = 0
  if itemCount > 0 then
    h = itemCount * opts.rowHeight + (itemCount - 1) * opts.rowSpacing
  end
  local w = opts.width
  local x = frame.x + frame.w - w - opts.marginRight
  local y = frame.y + opts.marginTop
  return { x = x, y = y, w = w, h = h }
end

-- Ensure canvas exists and positioned
local function ensureCanvas()
  if canvas then return canvas end
  canvas = hs.canvas.new(computeFrame(0))
  canvas:level(hs.canvas.windowLevels.overlay)
  canvas:clickActivating(false)
  if hs.canvas.windowBehaviors and hs.canvas.windowBehaviors.canJoinAllSpaces then
    canvas:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)
  end
  canvas:hide()
  return canvas
end

-- Remove id from order list
local function removeFromOrder(id)
  for i, v in ipairs(order) do
    if v == id then table.remove(order, i) break end
  end
end

-- Render panel from current states
local function render()
  local c = ensureCanvas()

  local items = {}
  for _, id in ipairs(order) do
    local st = states[id]
    if st then table.insert(items, { id = id, data = st }) end
  end

  -- Clamp to maxItems
  if #items > opts.maxItems then
    local slice = {}
    for i = 1, opts.maxItems do slice[i] = items[i] end
    items = slice
  end

  -- Update frame
  local f = computeFrame(#items)
  c:frame(f)

  -- Nothing to draw → hide panel
  if #items == 0 then
    c:replaceElements() -- empty
    c:hide()
    return
  end

  local elements = {}

  -- Background (match transient canvas.lua)
  elements[#elements + 1] = {
    type = "rectangle",
    frame = { x = 0, y = 0, w = f.w, h = f.h },
    roundedRectRadii = { xRadius = opts.radius, yRadius = opts.radius },
    fillColor = opts.colors.bg,
    shadow = { blurRadius = 24, color = { red = 0, green = 0, blue = 0, alpha = 0.75 }, offset = { h = 2, w = 0 } }
  }

  -- Border
  elements[#elements + 1] = {
    type = "rectangle",
    action = "stroke",
    frame = { x = 0, y = 0, w = f.w, h = f.h },
    roundedRectRadii = { xRadius = opts.radius, yRadius = opts.radius },
    strokeColor = opts.colors.border,
    strokeWidth = 1
  }

  -- Rows (centered text, uppercase, paddings align with transient canvas)
  local y = 0
  for _, item in ipairs(items) do
    local st = item.data
    -- Text
    local textX = 16
    elements[#elements + 1] = {
      type = "text",
      frame = { x = textX, y = y + 6, w = f.w - 32, h = opts.rowHeight - 12 },
      text = string.upper(tostring(st.text or "")),
      textColor = opts.colors.text,
      textFont = opts.fontName,
      textSize = opts.fontSize,
      textAlignment = "center"
    }

    y = y + opts.rowHeight + opts.rowSpacing
  end

  c:replaceElements(table.unpack(elements))
  c:show()
end

-- Screen change handling: reposition at top-right
local function startScreenWatcher()
  if screenWatcher then return end
  screenWatcher = hs.screen.watcher.new(function()
    if not canvas then return end
    -- Only reposition; re-render to update width/height
    render()
  end)
  screenWatcher:start()
end

-- Public API ----------------------------------------------------------------

-- Initialize module with optional overrides: width, margins, colors, etc.
function M.init(overrides)
  if opts then return true end
  opts = hs.fnutils.copy(DEFAULTS)
  if type(overrides) == "table" then
    for k, v in pairs(overrides) do
      if type(v) == "table" and type(opts[k]) == "table" then
        for kk, vv in pairs(v) do opts[k][kk] = vv end
      else
        opts[k] = v
      end
    end
  end
  ensureCanvas()
  startScreenWatcher()
  render()
  return true
end

-- Add or update a state entry by id
-- props = { text=string }
function M.set(id, props)
  if not id or type(props) ~= "table" then return false end
  if not states[id] then
    table.insert(order, id)
  end
  states[id] = {
    text = props.text or (states[id] and states[id].text) or "",
  }
  render()
  return true
end

-- Remove a state entry by id
function M.remove(id)
  if not states[id] then return false end
  states[id] = nil
  removeFromOrder(id)
  render()
  return true
end

-- Clear all states
function M.clear()
  states = {}
  order = {}
  render()
end

-- Show/hide panel (does not affect state)
function M.show()
  ensureCanvas():show()
end

function M.hide()
  if canvas then canvas:hide() end
end

-- Accessors (for testing/integration)
function M.list()
  local out = {}
  for _, id in ipairs(order) do
    if states[id] then out[#out + 1] = { id = id, text = states[id].text } end
  end
  return out
end

return M
