-- Title         : core.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/forge/core.lua
-- ----------------------------------------------------------------------------
-- Core utilities: shell execution, event bus, SA tracking, state management

local M = {}

-- Broaden PATH to include common Nix locations to support darwin-rebuild
-- when run from privileged AppleScript without user shell profiles.
M.PATH = table.concat({
    "/opt/homebrew/bin",
    "/usr/local/bin",
    "/run/current-system/sw/bin",
    "/nix/var/nix/profiles/default/bin",
    "/etc/profiles/per-user/" .. (os.getenv("USER") or "bardiasamiee") .. "/bin",
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

-- SA state tracking
M.sa = { available = M.isSaAvailable() }

function M.refreshSa()
    M.sa.available = M.isSaAvailable()
end

function M.setDryRun(enabled)
    -- No-op: dry run not needed in current system
end

-- Event bus (moved from integration.lua for central access)
local subs = {}
M.bus = {
    on = function(event, fn)
        if not event or type(fn) ~= "function" then
            return function() end
        end
        subs[event] = subs[event] or {}
        table.insert(subs[event], fn)
        local idx = #subs[event]
        return function()
            if subs[event] and subs[event][idx] == fn then
                table.remove(subs[event], idx)
            end
        end
    end,
    emit = function(event, payload)
        local list = subs[event]
        if not list then return end
        for _, fn in ipairs(list) do
            pcall(fn, payload)
        end
    end
}

function M.writeYabaiState()
    local cmd = "idx=$(yabai -m query --spaces --space | jq -r '.index // 0' 2>/dev/null || printf '0'); " ..
               "mode=$(yabai -m query --spaces --space | jq -r '.type // \"?\"' 2>/dev/null || printf '?'); " ..
               "gaps=$(yabai -m config top_padding 2>/dev/null | tr -d '\\n' || printf '0'); " ..
               "drop=$(yabai -m config mouse_drop_action 2>/dev/null | tr -d '\\n' || printf 'swap'); " ..
               "op=$(yabai -m config window_opacity 2>/dev/null | tr -d '\\n' || printf 'off'); " ..
               "sa=no; [ -d /Library/ScriptingAdditions/yabai.osax ] && sa=yes; " ..
               "printf '{\"mode\":\"%s\",\"idx\":%s,\"gaps\":%s,\"drop\":\"%s\",\"opacity\":\"%s\",\"sa\":\"%s\"}\\n' " ..
               "\"$mode\" \"$idx\" \"$gaps\" \"$drop\" \"$op\" \"$sa\" > ${TMPDIR:-/tmp}/yabai_state.json"
    return M.sh(cmd)
end

return M
