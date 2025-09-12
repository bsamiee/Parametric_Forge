-- Title         : config.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/utils/config.lua
-- ----------------------------------------------------------------------------
-- Configuration utilities - eliminates duplication across modules

local M = {}

function M.getConfigDir()
    local configdir = hs.configdir
    if type(configdir) == "function" then
        return configdir()
    elseif type(configdir) == "string" and #configdir > 0 then
        return configdir
    else
        return os.getenv("HOME") .. "/.hammerspoon"
    end
end

function M.getAssetsDir()
    return M.getConfigDir() .. "/assets"
end

function M.getYabaiPath()
    return "/opt/homebrew/bin/yabai"
end

function M.getBrewPath()
    local files = require("utils.files")
    if files.exists("/opt/homebrew/bin/brew") then
        return "/opt/homebrew/bin/brew"
    elseif files.exists("/usr/local/bin/brew") then
        return "/usr/local/bin/brew"
    else
        return nil
    end
end

function M.getKarabinerConsoleService()
    return "gui/$UID org.pqrs.karabiner.karabiner_console_user_server"
end

function M.getKarabinerGrabberService()
    return "system/org.pqrs.karabiner.karabiner_grabber"
end

function M.getSkhdPlist()
    return "~/Library/LaunchAgents/com.koekeishiya.skhd.plist"
end

function M.getFlakeRoot()
    return (os.getenv("HOME") or "") .. "/Documents/99.Github/Parametric_Forge"
end

return M
