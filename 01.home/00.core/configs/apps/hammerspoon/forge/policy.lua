-- Title         : policy.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/forge/policy.lua
-- ----------------------------------------------------------------------------
-- Window and space policy logic (advisory; Yabai owns float)

local config = require("forge.config")
local exec = require("forge.executor")
local shlib = require("forge.sh")
local state = require("forge.state")

local M = {}

local function axRole(win)
    local ok, ax = pcall(hs.axuielement.windowElement, win)
    if not ok or not ax then
        return nil, nil
    end
    local role = ax:attributeValue("AXRole")
    local sub = ax:attributeValue("AXSubrole")
    return role, sub
end

local function matchRule(app, title)
    for _, r in ipairs(config.appRules) do
        if app:match(r.app) and (not r.title or (title and title:match(r.title))) then
            return r
        end
    end
    return nil
end

local function shouldFloatBySize(win)
    local f = win:frame()
    return f.w < config.floatThreshold.minW or f.h < config.floatThreshold.minH
end

-- Called on window created (or when we want to ensure policy)
function M.applyWindowPolicy(win)
    if not win or not win:id() then
        return
    end
    -- Quick short-circuit when HS is not enforcing float logic
    if not config.enforceFloatInHS then
        return
    end
    local id = win:id()
    local app = win:application() and win:application():name() or ""
    local title = win:title() or ""
    local role, subrole = axRole(win)
    local e = state.windowEntry(id)
    e.app, e.title, e.role, e.subrole = app, title, role, subrole

    -- Avoid overlap with Yabai rules/signals by default.
    if config.enforceFloatInHS then
        -- App rule first
        local rule = matchRule(app or "", title or "")
        if rule then
            if rule.manage == false then
                exec.windowFloat(id, true)
            end
            if rule.sticky == true then
                exec.windowSticky(id, true)
            end
            if rule.subLayer then
                exec.windowSubLayer(id, rule.subLayer)
            end
            if rule.gridAnchor then
                exec.windowGrid(id, rule.gridAnchor)
            end
            return
        end

        -- Generic float policy for dialogs/sheets/system dialogs & tiny windows
        local isDialog = (
            role == "AXWindow"
            and (
                subrole == "AXDialog"
                or subrole == "AXSheet"
                or subrole == "AXSystemDialog"
                or subrole == "AXPopover"
                or subrole == "AXInspector"
                or subrole == "AXUnknown"
            )
        )

        local isSystemFloating = (subrole == "AXSystemFloatingWindow")

        local isPrefsTitle = false
        if title and #title > 0 then
            isPrefsTitle = (
                string.match(title, "Preferences")
                or string.match(title, "Settings")
                or string.match(title, "Options")
                or string.match(title, "Configuration")
                or string.match(title, "About")
                or string.match(title, "Library")
                or string.match(title, "Queue")
                or string.match(
                    title,
                    "^(General|(Tab|Password|Website|Extension)s|AutoFill|Se(arch|curity)|Privacy|Advance)$"
                )
            )
                    and true
                or false
        end

        if isDialog or isSystemFloating or isPrefsTitle or shouldFloatBySize(win) then
            exec.windowFloat(id, true)
            if isSystemFloating then
                exec.windowSticky(id, true)
                exec.windowSubLayer(id, "above")
            end
        end
    end
end

-- Space normalization policy with stack layout awareness
function M.applySpacePolicy(spaceId)
    if not spaceId then
        return
    end
    -- Only normalize BSP spaces, leave stack spaces alone.
    -- Note: yabai --space expects an index/label, not an ID. Query all and match by id.
    local all = shlib.sh("yabai -m query --spaces 2>/dev/null")
    if not all or #all == 0 or not all:match("^%s*[%[{]") then
        return
    end
    local ok, spaces = pcall(hs.json.decode, all)
    if not ok or type(spaces) ~= "table" then
        return
    end
    for _, s in ipairs(spaces) do
        if s.id == spaceId and s.type == "bsp" then
            exec.normalizeSpace(spaceId)
            break
        end
    end
end

-- Window stack detection helper
function M.isWindowStacked(winId)
    local sh = function(cmd)
        return shlib.sh(cmd)
    end

    local winInfo = sh(string.format("yabai -m query --windows --window %s 2>/dev/null", winId))
    if winInfo and #winInfo > 0 and winInfo:match("^%s*[%[{]") then
        local ok, window = pcall(hs.json.decode, winInfo)
        if ok and window and window["stack-index"] then
            return window["stack-index"] > 0
        end
    end
    return false
end

return M
