-- Title         : core.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/forge/core.lua
-- ----------------------------------------------------------------------------
-- Minimal core utilities

local M = {}

function M.isProcessRunning(name)
    local out = hs.execute("pgrep -x '" .. name .. "' >/dev/null 2>&1; echo $?", true)
    return out and out:match("^%s*0%s*$") ~= nil
end

return M
