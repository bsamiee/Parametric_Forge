-- Title         : canvas.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/notifications/canvas.lua
-- ----------------------------------------------------------------------------
-- Shared canvas notification system using native hs.drawing
-- Maintains exact visual style from previous implementation but simplified

local styles = require("notifications.styles")

local M = {}
local canvas = nil
local messages = {}
local idCounter = 0
local renderQueued = false

-- Initialize canvas with proper settings
local function ensureCanvas()
    if canvas then return canvas end

    local screen = hs.screen.mainScreen()
    local frame = screen:frame()
    local x = frame.x + (frame.w - styles.width) / 2
    local y = frame.y + styles.topOffset

    canvas = hs.canvas.new({
        x = x,
        y = y,
        w = styles.width,
        h = 1
    })

    canvas:level(hs.canvas.windowLevels.overlay)
    canvas:clickActivating(false)

    -- Follow across all spaces at the same position
    if hs.canvas.windowBehaviors and hs.canvas.windowBehaviors.canJoinAllSpaces then
        canvas:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)
    end

    canvas:hide()
    return canvas
end

-- Clean expired messages
local function cleanExpired()
    local now = hs.timer.secondsSinceEpoch()
    local active = {}

    for _, msg in ipairs(messages) do
        if msg.expiry > now then
            table.insert(active, msg)
        end
    end

    messages = active
end

-- Render current messages to canvas
local function render()
    if renderQueued then return end
    renderQueued = true

    local c = ensureCanvas()
    cleanExpired()

    local count = #messages
    if count == 0 then
        c:hide()
        return
    end

    local totalHeight = count * styles.rowHeight + (count - 1) * styles.rowSpacing
    c:frame({
        x = c:frame().x,
        y = c:frame().y,
        w = styles.width,
        h = totalHeight
    })

    local elements = {}

    -- Background with rounded corners and shadow
    elements[1] = {
        type = "rectangle",
        frame = { x = 0, y = 0, w = styles.width, h = totalHeight },
        roundedRectRadii = { xRadius = styles.radius, yRadius = styles.radius },
        fillColor = styles.colors.bg,
        shadow = {
            blurRadius = 24,
            color = { red = 0, green = 0, blue = 0, alpha = 0.75 },
            offset = { h = 2, w = 0 }
        }
    }

    -- Border
    elements[2] = {
        type = "rectangle",
        action = "stroke",
        frame = { x = 0, y = 0, w = styles.width, h = totalHeight },
        roundedRectRadii = { xRadius = styles.radius, yRadius = styles.radius },
        strokeColor = styles.colors.border,
        strokeWidth = 1
    }

    -- Message text elements (newest on top)
    for i, msg in ipairs(messages) do
        local y = (i - 1) * (styles.rowHeight + styles.rowSpacing)
        elements[i + 2] = {
            type = "text",
            frame = {
                x = 16,
                y = y + 6,
                w = styles.width - 32,
                h = styles.rowHeight - 12
            },
            text = string.upper(msg.text),
            textColor = styles.colors.text,
            textSize = styles.font.size,
            textFont = styles.font.name,
            textAlignment = "center"
        }
    end

    if #elements > 0 then
        c:replaceElements(table.unpack(elements))
    end
    c:show()

    renderQueued = false
end

-- Public API
function M.show(text, duration)
    duration = duration or styles.defaultDuration
    idCounter = idCounter + 1

    local message = {
        id = idCounter,
        text = tostring(text),
        expiry = hs.timer.secondsSinceEpoch() + duration
    }

    -- Add to front (newest on top)
    table.insert(messages, 1, message)

    -- Limit to max messages
    while #messages > styles.maxMessages do
        table.remove(messages)
    end

    render()

    -- Auto-cleanup after expiry
    hs.timer.doAfter(duration, function()
        render() -- Will clean expired messages
    end)
end

function M.clear()
    messages = {}
    render()
end

return M
