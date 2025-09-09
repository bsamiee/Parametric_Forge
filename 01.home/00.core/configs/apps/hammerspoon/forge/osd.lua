-- Title         : osd.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/forge/osd.lua
-- ----------------------------------------------------------------------------
-- On-screen display overlays (transient and persistent)

local M = {}

-- Disable persistent overlays globally (top-left pills). They are not used
-- by our current config and have caused confusing status remnants.
local PERSISTENT_ENABLED = false

local defaultStyle = {
    bgColor = { black = 0, alpha = 0.75 },
    textColor = { white = 1, alpha = 1.0 },
    -- Use Geist Mono (from 00.system/fonts.nix geist-font)
    font = { name = "Geist Mono", size = 16 },
    radius = 8,
    padding = 12,
}

local function makeCanvas(screen)
    local frame = screen:frame()
    local width = math.min(520, frame.w - 40)
    local height = 44
    local x = frame.x + (frame.w - width) / 2
    local y = frame.y + 30
    return hs.canvas.new({ x = x, y = y, w = width, h = height }):level(hs.canvas.windowLevels.overlay)
end

local function applyCanvas(cvs, msg, style)
    style = style or {}
    local s = {
        bgColor = style.bgColor or defaultStyle.bgColor,
        textColor = style.textColor or defaultStyle.textColor,
        font = style.font or defaultStyle.font,
        radius = style.radius or defaultStyle.radius,
        padding = style.padding or defaultStyle.padding,
    }
    cvs:replaceElements({
        {
            id = "bg",
            type = "rectangle",
            action = "fill",
            roundedRectRadii = { xRadius = s.radius, yRadius = s.radius },
            fillColor = s.bgColor,
        },
        {
            id = "text",
            type = "text",
            text = msg,
            textColor = s.textColor,
            textSize = s.font.size,
            textFont = s.font.name,
            frame = { x = s.padding, y = 8, w = cvs:frame().w - 2 * s.padding, h = cvs:frame().h - 16 },
            textAlignment = "center",
        },
    })
end

local activeCvs
local hideTimer

-- Transient message --------------------------------------------------------
function M.show(msg, opts)
    opts = opts or {}
    local scr = hs.screen.mainScreen()
    if activeCvs then
        activeCvs:delete()
        activeCvs = nil
    end
    if hideTimer then
        hideTimer:stop()
        hideTimer = nil
    end

    activeCvs = makeCanvas(scr)
    applyCanvas(activeCvs, msg, opts.style)
    activeCvs:alpha(0)
    activeCvs:show()
    -- older hs.canvas:alpha does not accept animation tables; set directly
    activeCvs:alpha(1)
    hideTimer = hs.timer.doAfter(opts.duration or 1.2, function()
        if not activeCvs then
            return
        end
        activeCvs:alpha(0)
        -- delete after a short delay to mimic fade-out completion
        hs.timer.doAfter(0.16, function()
            if activeCvs then
                activeCvs:delete()
            end
            activeCvs = nil
        end)
    end)
end

-- Persistent overlays ------------------------------------------------------
local persist = {}

local function makePersistentCanvas(id, screen)
    local frame = screen:frame()
    local width = 180
    local height = 30
    local margin = 10
    local x = frame.x + margin
    -- stack space overlay at top, leaders just below it to avoid overlap
    local y = frame.y + margin
    if type(id) == "string" and id:match("^leader_") then
        y = y + height + 4
    end
    local cvs = hs.canvas.new({ x = x, y = y, w = width, h = height }):level(hs.canvas.windowLevels.overlay)
    cvs:alpha(0.9)
    return cvs
end

local function applyPersistentCanvas(cvs, msg)
    cvs:replaceElements({
        {
            id = "bg",
            type = "rectangle",
            action = "fill",
            roundedRectRadii = { xRadius = 6, yRadius = 6 },
            fillColor = { black = 0, alpha = 0.6 },
        },
        {
            id = "text",
            type = "text",
            text = msg,
            textColor = { white = 1, alpha = 1 },
            textSize = 13,
            textFont = "Geist Mono",
            frame = { x = 8, y = 5, w = cvs:frame().w - 16, h = cvs:frame().h - 10 },
            textAlignment = "center",
        },
    })
end

function M.showPersistent(id, msg)
    if not PERSISTENT_ENABLED then
        -- Fallback to a short transient notification instead of a sticky pill
        M.show(msg or "", { duration = 0.9 })
        return
    end
    if not id then return end
    local rec = persist[id]
    if rec and rec.cvs then
        applyPersistentCanvas(rec.cvs, msg)
        rec.cvs:show(); rec.visible = true
        return
    end
    local scr = hs.screen.mainScreen()
    local cvs = makePersistentCanvas(id, scr)
    applyPersistentCanvas(cvs, msg)
    cvs:show()
    persist[id] = { cvs = cvs, visible = true }
end

function M.hidePersistent(id)
    if not PERSISTENT_ENABLED then return end
    local rec = id and persist[id]
    if rec and rec.cvs then rec.cvs:delete() end
    persist[id] = nil
end

function M.hideAllPersistent()
    for id, rec in pairs(persist) do
        if rec and rec.cvs then
            pcall(function() rec.cvs:delete() end)
        end
        persist[id] = nil
    end
end

function M.updatePersistent(id, msg)
    if not PERSISTENT_ENABLED then return end
    local rec = id and persist[id]
    if rec and rec.cvs then applyPersistentCanvas(rec.cvs, msg) end
end

-- Convenience: Caffeine (display idle) status OSD
function M.notifyCaffeine(state)
    local msg
    if state then
        msg = "Caffeine: Enabled (display stays awake)"
    else
        msg = "Caffeine: Disabled (normal sleep)"
    end
    M.show(msg, { duration = 0.9 })
end

return M
