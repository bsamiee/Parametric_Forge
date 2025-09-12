-- Title         : process.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/utils/process.lua
-- ----------------------------------------------------------------------------
-- Process checking utilities

local M = {}

function M.isRunning(processName)
    local output = hs.execute("pgrep -x '" .. processName .. "' >/dev/null 2>&1; echo $?", true)
    return output and output:match("^%s*0%s*$") ~= nil
end

function M.execute(command, waitForCompletion)
    return hs.execute(command, waitForCompletion)
end

return M
