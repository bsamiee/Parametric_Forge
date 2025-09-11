-- Title         : persistent_indicator.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/forge/persistent_indicator.lua
-- ----------------------------------------------------------------------------
-- Persistent top-right indicator with priority-based content management.
-- Efficient single canvas that updates content without recreation.

local M = {}

-- Config -------------------------------------------------------------------
local CFG = {
  width = 200,
  height = 40,
  cornerRadius = 8,
  topOffset = 20,
  rightOffset = 20,
  font = { name = "GeistMono-Bold", size = 12 },
  colors = {
    bg     = { red = 0x15/255, green = 0x19/255, blue = 0x2F/255, alpha = 0.75 },
    text   = { red = 0xFF/255, green = 0x79/255, blue = 0xC6/255, alpha = 1.00 },
    border = { red = 0xf8/255, green = 0xf8/255, blue = 0xf2/255, alpha = 0.60 },
    shadow = { red = 0x00/255, green = 0x00/255, blue = 0x00/255, alpha = 0.75 },
  },
}

-- State --------------------------------------------------------------------
local canvas
local anchorX, anchorY
local currentContent = {}
local updating = false

-- Priority system (higher number = higher priority)
local PRIORITIES = {
  workspace = 1,
  modal = 2,
}

-- Helpers ------------------------------------------------------------------
local function computeAnchor()
  if anchorX and anchorY then return anchorX, anchorY end
  local s = hs.screen.mainScreen()
  local f = s and s:frame() or hs.geometry.rect(0,0,1440,900)
  anchorX = f.x + f.w - CFG.width - CFG.rightOffset
  anchorY = f.y + CFG.topOffset
  return anchorX, anchorY
end

local function ensureCanvas()
  if canvas then return canvas end
  local x, y = computeAnchor()
  canvas = hs.canvas.new({ x = x, y = y, w = CFG.width, h = CFG.height })
  canvas:level(hs.canvas.windowLevels.overlay)
  canvas:clickActivating(false)
  
  if hs.canvas.windowBehaviors and hs.canvas.windowBehaviors.canJoinAllSpaces then
    canvas:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)
  end
  
  canvas:hide() -- Start hidden
  return canvas
end

local function formatText(s)
  return string.upper(tostring(s or ""))
end

local function getCurrentPriorityContent()
  local highestPriority = 0
  local content = nil
  
  for key, text in pairs(currentContent) do
    local priority = PRIORITIES[key] or 0
    if priority > highestPriority then
      highestPriority = priority
      content = text
    end
  end
  
  return content
end

local function render()
  local c = ensureCanvas()
  local content = getCurrentPriorityContent()
  
  if not content then
    c:hide()
    return
  end
  
  -- Build elements (create fresh tables)
  local elements = {
    -- Background
    {
      type = "rectangle",
      frame = { x = 0, y = 0, w = CFG.width, h = CFG.height },
      roundedRectRadii = { xRadius = CFG.cornerRadius, yRadius = CFG.cornerRadius },
      fillColor = CFG.colors.bg,
      shadow = { blurRadius = 16, color = CFG.colors.shadow, offset = { h = 2, w = 0 } },
    },
    -- Border
    {
      type = "rectangle",
      action = "stroke",
      frame = { x = 0, y = 0, w = CFG.width, h = CFG.height },
      roundedRectRadii = { xRadius = CFG.cornerRadius, yRadius = CFG.cornerRadius },
      strokeColor = CFG.colors.border,
      strokeWidth = 1,
    },
    -- Text
    {
      type = "text",
      frame = { x = 8, y = 8, w = CFG.width - 16, h = CFG.height - 16 },
      text = formatText(content),
      textColor = CFG.colors.text,
      textSize = CFG.font.size,
      textFont = CFG.font.name,
      textAlignment = "center",
    }
  }
  
  -- Safe atomic update
  pcall(function()
    c:replaceElements(table.unpack(elements))
  end)
  c:show()
end

local function updateSafe()
  if updating then return end
  updating = true
  pcall(render)
  updating = false
end

-- Public API ---------------------------------------------------------------
function M.show(content, priority)
  priority = priority or "modal"
  currentContent[priority] = content
  updateSafe()
end

function M.hide(priority)
  if priority then
    currentContent[priority] = nil
  else
    -- Hide all
    currentContent = {}
  end
  updateSafe()
end

function M.hideAllPersistent()
  currentContent = {}
  updateSafe()
end

-- Legacy compatibility with existing OSD calls
function M.showPersistent(message, priority)
  M.show(message, priority)
end

function M.hidePersistent(priority)
  M.hide(priority)
end

return M