-- Title         : sh.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/forge/sh.lua
-- ----------------------------------------------------------------------------
-- Centralized shell helpers: PATH, sh(), yabai(), readiness/SA checks

local M = {}

-- Broaden PATH to include common Nix locations to support darwin-rebuild
-- when run from privileged AppleScript without user shell profiles.
M.PATH = table.concat({
    "/opt/homebrew/bin",
    "/usr/local/bin",
    "/run/current-system/sw/bin",
    "/nix/var/nix/profiles/default/bin",
    os.getenv("PATH") or "",
}, ":")

function M.sh(cmd)
    -- Use sh -c instead of sh -lc to avoid loading profile/rc files that output env vars
    return hs.execute("/usr/bin/env PATH='" .. M.PATH .. "' sh -c '" .. cmd .. "'", true)
end

function M.yabai(args)
    return M.sh("yabai -m " .. args)
end

function M.isYabaiReady()
    local out = M.sh("yabai -m query --windows >/dev/null 2>&1; echo $?")
    return out and out:match("^0") ~= nil
end

function M.isProcessRunning(name)
    local out = M.sh("pgrep -x '" .. name .. "' >/dev/null 2>&1; echo $?")
    if not out then
        return false
    end
    -- Trim whitespace and check if output equals "0"
    local trimmed = out:gsub("^%s*(.-)%s*$", "%1")
    return trimmed == "0"
end

function M.isSaAvailable()
    local out = M.sh("[ -d /Library/ScriptingAdditions/yabai.osax ] && echo yes || echo no")
    return out and out:match("yes") ~= nil
end

return M
