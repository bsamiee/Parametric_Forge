-- Title         : process.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/utils/process.lua
-- ----------------------------------------------------------------------------
-- Process checking utilities

local M = {}

function M.isRunning(processName)
    local output, status = hs.execute("pgrep -x '" .. processName .. "'", true)
    return status == true and output and output:match("%d+") ~= nil
end

function M.execute(command, waitForCompletion)
    return hs.execute(command, waitForCompletion)
end

return M
