-- Title         : palette.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/forge/palette.lua
-- ----------------------------------------------------------------------------
-- Window/focus palettes and main action palette with OSD feedback

local auto = require("forge.auto")
local exec = require("forge.executor")
local osd = require("forge.osd")
local shlib = require("forge.sh")

local M = {}

local function appIcon(app)
    local ok, img = pcall(function()
        if not app then
            return nil
        end
        local bundleID = app:bundleID()
        if not bundleID then
            return nil
        end
        return hs.image.imageFromAppBundle(bundleID)
    end)
    if ok and img then
        return img
    end
    return nil
end

local function toChoice(win)
    local app = win:application()
    local appName = app and app:name() or "?"
    local title = win:title() or "(untitled)"
    local scr = win:screen()
    local spaceIds = hs.spaces.windowSpaces(win) or {}
    local txt = string.format("%s — %s", appName, title)
    local sub =
        string.format("Screen: %s  •  Spaces: %s", scr and (scr:name() or "?") or "?", table.concat(spaceIds, ","))
    return {
        text = txt,
        subText = sub,
        image = appIcon(app),
        win = win,
    }
end

local function focusWin(win)
    if not win then
        return
    end
    if win:isMinimized() then
        win:unminimize()
    end
    win:focus()
    osd.show("Focused: " .. (win:title() or "window"), { duration = 0.9 })
end

local function buildChoices(windows)
    local choices = {}
    for _, w in ipairs(windows) do
        if w:isStandard() and w:isVisible() then
            table.insert(choices, toChoice(w))
        end
    end
    return choices
end

function M.showAll()
    local wins = hs.window.filter.new():getWindows()
    local chooser = hs.chooser.new(function(choice)
        if choice and choice.win then
            focusWin(choice.win)
        end
    end)
    chooser:choices(buildChoices(wins))
    chooser:placeholderText("Focus window…")
    chooser:show()
end

local function safeActiveSpaces()
    if not hs.spaces or not hs.spaces.activeSpaces then return nil end
    local ok, res = pcall(function() return hs.spaces.activeSpaces() end)
    return ok and res or nil
end

local function safeWindowSpaces(w)
    if not hs.spaces or not hs.spaces.windowSpaces then return nil end
    local ok, res = pcall(function() return hs.spaces.windowSpaces(w) end)
    return ok and res or nil
end

function M.showCurrentSpace()
    local active = safeActiveSpaces()
    local thisScr = hs.screen.mainScreen()
    local wins = hs.window.filter.new():getWindows()
    local filtered = {}
    if active and thisScr then
        for _, w in ipairs(wins) do
            local sp = safeWindowSpaces(w)
            if sp and #sp > 0 then
                for _, s in ipairs(sp) do
                    if active[thisScr:getUUID()] == s then
                        table.insert(filtered, w)
                        break
                    end
                end
            end
        end
    else
        -- Fallback: when hs.spaces is unavailable, show all windows
        filtered = wins
    end
    local chooser = hs.chooser.new(function(choice)
        if choice and choice.win then
            focusWin(choice.win)
        end
    end)
    chooser:choices(buildChoices(filtered))
    chooser:placeholderText("Focus window (current space)…")
    chooser:show()
end

-- URL handlers for SKHD or scripts
hs.urlevent.bind("forge/palette/windows", function()
    M.showAll()
end)
hs.urlevent.bind("forge/palette/windowsSpace", function()
    M.showCurrentSpace()
end)

-- Main action palette ------------------------------------------------------
local function mainChoices()
    return {
        { text = "Windows — All", subText = "Focus any visible window", id = "win_all" },
        { text = "Windows — Current Space", subText = "Focus window on active space", id = "win_space" },
        { text = "Layout — Toggle BSP/Stack", subText = "Switch current space layout", id = "layout_toggle" },
        { text = "Layout — Set BSP", subText = "Binary Space Partitioning", id = "layout_bsp" },
        { text = "Layout — Set Stack", subText = "Stack layout", id = "layout_stack" },
        { text = "Stack — Next", subText = "Focus next in stack", id = "stack_next" },
        { text = "Stack — Prev", subText = "Focus previous in stack", id = "stack_prev" },
        { text = "Stack — Unstack", subText = "Unstack current window", id = "stack_unstack" },
        { text = "Restart Yabai", subText = "Restart service and borders", id = "yabai_restart" },
        { text = "Reload skhd", subText = "Reload hotkeys", id = "skhd_reload" },
        { text = "Reload Hammerspoon", subText = "Reload configuration", id = "hs_reload" },
        { text = "Toggle Drop Action", subText = "Swap ⇄ Stack", id = "drop_toggle" },
        { text = "Toggle Gaps/Padding", subText = "0 ⇄ 4 px (all)", id = "gaps_toggle" },
        { text = "Opacity — Toggle", subText = "Enable/disable window opacity", id = "opacity_toggle" },
        { text = "Opacity — Set Levels", subText = "Active/Normal presets", id = "opacity_set" },
    }
end

local function handleMainChoice(choice)
    if not choice or not choice.id then
        return
    end
    if choice.id == "win_all" then
        M.showAll()
        return
    end
    if choice.id == "win_space" then
        M.showCurrentSpace()
        return
    end
    if choice.id == "yabai_restart" then
        auto.restartYabai()
        return
    end
    if choice.id == "skhd_reload" then
        auto.reloadSkhd()
        return
    end

    if choice.id == "layout_toggle" or choice.id == "layout_bsp" or choice.id == "layout_stack" then
        local function sh(cmd) return shlib.sh(cmd) end
        local js = sh("yabai -m query --spaces 2>/dev/null")
        local curType = "?"
        if js and js:match("^[%[{]") then
            local ok, arr = pcall(hs.json.decode, js)
            if ok and type(arr) == "table" then
                for _, s in ipairs(arr) do if s["has-focus"] then curType = s.type or curType end end
            end
        end
        local new
        if choice.id == "layout_toggle" then
            if curType == "bsp" then sh("yabai -m space --layout stack"); new = "stack" else sh("yabai -m space --layout bsp"); new = "bsp" end
        elseif choice.id == "layout_bsp" then
            sh("yabai -m space --layout bsp"); new = "bsp"
        else
            sh("yabai -m space --layout stack"); new = "stack"
        end
        -- Persist for watchers (write file directly to avoid shell quoting issues)
        local f = io.open("/tmp/yabai_state.json", "w")
        if f then f:write(string.format('{"mode":"%s"}\n', new)); f:close() end
        osd.show("Layout: " .. new, { duration = 0.8 })
        return
    end

    if choice.id == "stack_next" or choice.id == "stack_prev" then
        local dir = (choice.id == "stack_next") and "stack.next" or "stack.prev"
        local function sh(cmd) return shlib.sh(cmd) end
        sh("yabai -m window --focus " .. dir .. " 2>/dev/null")
        local info = sh("yabai -m query --windows --window 2>/dev/null")
        if info and info:match("^[%[{]") then
            local ok, w = pcall(hs.json.decode, info)
            if ok and w and w["stack-index"] and w["stack-index"] > 0 then
                osd.show("Stack: " .. tostring(w["stack-index"]), { duration = 0.8 })
            else
                osd.show("Not in a stack", { duration = 0.8 })
            end
        end
        return
    end

    if choice.id == "stack_unstack" then
        local function sh(cmd) return shlib.sh(cmd) end
        -- Try to warp in a direction to unstack; fallback through directions
        local dirs = { "east", "west", "north", "south" }
        for _, d in ipairs(dirs) do
            local rc = sh(string.format("yabai -m window --warp %s >/dev/null 2>&1; echo $?", d))
            if rc and rc:match("^0") then break end
        end
        osd.show("Unstacked (if stacked)", { duration = 0.8 })
        return
    end
    if choice.id == "hs_reload" then
        auto.reloadHammerspoon()
        return
    end
    if choice.id == "drop_toggle" then
        local function sh(cmd)
            return shlib.sh(cmd)
        end
        local current = (sh("yabai -m config mouse_drop_action 2>/dev/null"):gsub("\n$", ""))
        local new
        if current == "swap" then
            new = "stack"
        else
            new = "swap"
        end
        sh(string.format("yabai -m config mouse_drop_action %s", new))
        -- Persist state for HS OSD watchers and other integrations
        local fd = io.open("/tmp/yabai_drop.json", "w")
        if fd then fd:write(string.format('{"drop":"%s"}\n', new)); fd:close() end
        osd.show("Drop: " .. (new == "stack" and "Stack" or "Swap"), { duration = 0.8 })
        return
    end

    if choice.id == "gaps_toggle" then
        local function sh(cmd)
            return shlib.sh(cmd)
        end
        local padding = (sh("yabai -m config top_padding 2>/dev/null"):gsub("\n$", ""))
        if padding == "0" or padding == "" then
            sh(
                "yabai -m config top_padding 4; yabai -m config bottom_padding 4; yabai -m config left_padding 4; yabai -m config right_padding 4; yabai -m config window_gap 4"
            )
            osd.show("Gaps/Padding: 4 px", { duration = 0.9 })
        else
            sh(
                "yabai -m config top_padding 0; yabai -m config bottom_padding 0; yabai -m config left_padding 0; yabai -m config right_padding 0; yabai -m config window_gap 0"
            )
            osd.show("Gaps/Padding: 0 px", { duration = 0.9 })
        end
        return
    end

    if choice.id == "opacity_toggle" then
        if not exec.sa.available then
            osd.show("Opacity requires SIP/SA", { duration = 1.2 })
            return
        end
        local function sh(cmd)
            return shlib.sh(cmd)
        end
        local status = (sh("yabai -m config window_opacity 2>/dev/null"):gsub("\n$", ""))
        if status == "off" or status == "" then
            sh("yabai -m config window_opacity on")
            osd.show("Opacity: Enabled", { duration = 0.9 })
        else
            sh("yabai -m config window_opacity off")
            osd.show("Opacity: Disabled", { duration = 0.9 })
        end
        return
    end

    if choice.id == "opacity_set" then
        if not exec.sa.available then
            osd.show("Opacity requires SIP/SA", { duration = 1.2 })
            return
        end
        local presets = {
            { text = "Active 0.95 / Normal 0.80", id = "0.95:0.80" },
            { text = "Active 1.00 / Normal 0.90", id = "1.00:0.90" },
            { text = "Active 1.00 / Normal 1.00", id = "1.00:1.00" },
            { text = "Active 0.90 / Normal 0.70", id = "0.90:0.70" },
        }
        local chooser = hs.chooser.new(function(c)
            if not c then
                return
            end
            local a, n = c.id:match("([^:]+):([^:]+)")
            if not a or not n then
                return
            end
            local function sh(cmd)
                return shlib.sh(cmd)
            end
            sh(
                string.format(
                    "yabai -m config active_window_opacity %s; yabai -m config normal_window_opacity %s; yabai -m config window_opacity on",
                    a,
                    n
                )
            )
            osd.show(string.format("Opacity: %s/%s", a, n), { duration = 1.0 })
        end)
        chooser:choices(presets)
        chooser:placeholderText("Set opacity levels…")
        chooser:show()
        return
    end
end

function M.showMain()
    local chooser = hs.chooser.new(handleMainChoice)
    chooser:choices(mainChoices())
    chooser:placeholderText("Forge palette…")
    chooser:show()
end

hs.urlevent.bind("forge/palette/main", function()
    M.showMain()
end)

return M
