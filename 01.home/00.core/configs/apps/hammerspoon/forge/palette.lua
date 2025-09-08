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

function M.showCurrentSpace()
    local active = hs.spaces.activeSpaces()
    local thisScr = hs.screen.mainScreen()
    local wins = hs.window.filter.new():getWindows()
    local filtered = {}
    for _, w in ipairs(wins) do
        local sp = hs.spaces.windowSpaces(w)
        if sp and #sp > 0 then
            for _, s in ipairs(sp) do
                if active and active[thisScr:getUUID()] == s then
                    table.insert(filtered, w)
                    break
                end
            end
        end
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
    if choice.id == "hs_reload" then
        auto.reloadHammerspoon()
        return
    end
    if choice.id == "drop_toggle" then
        local PATH = "/opt/homebrew/bin:/usr/local/bin:/run/current-system/sw/bin:" .. os.getenv("PATH")
        local function sh(cmd)
            return hs.execute("/usr/bin/env PATH='" .. PATH .. "' sh -lc '" .. cmd .. "'", true)
        end
        local current = (sh("yabai -m config mouse_drop_action 2>/dev/null"):gsub("\n$", ""))
        if current == "swap" then
            sh("yabai -m config mouse_drop_action stack")
            osd.show("Drop: Stack", { duration = 0.8 })
        else
            sh("yabai -m config mouse_drop_action swap")
            osd.show("Drop: Swap", { duration = 0.8 })
        end
        return
    end

    if choice.id == "gaps_toggle" then
        local PATH = "/opt/homebrew/bin:/usr/local/bin:/run/current-system/sw/bin:" .. os.getenv("PATH")
        local function sh(cmd)
            return hs.execute("/usr/bin/env PATH='" .. PATH .. "' sh -lc '" .. cmd .. "'", true)
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
        local PATH = "/opt/homebrew/bin:/usr/local/bin:/run/current-system/sw/bin:" .. os.getenv("PATH")
        local function sh(cmd)
            return hs.execute("/usr/bin/env PATH='" .. PATH .. "' sh -lc '" .. cmd .. "'", true)
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
            local PATH = "/opt/homebrew/bin:/usr/local/bin:/run/current-system/sw/bin:" .. os.getenv("PATH")
            local function sh(cmd)
                return hs.execute("/usr/bin/env PATH='" .. PATH .. "' sh -lc '" .. cmd .. "'", true)
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
