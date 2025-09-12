-- Title         : files.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/utils/files.lua
-- ----------------------------------------------------------------------------
-- File operation utilities

local M = {}

function M.exists(path)
    return hs.fs.attributes(path) ~= nil
end

function M.size(path)
    local attrs = hs.fs.attributes(path)
    return attrs and attrs.size or 0
end

function M.extension(path)
    return (path:lower():match("%.([a-z0-9]+)$") or "")
end

function M.basename(path)
    return (path:gsub("/+$", ""):match("([^/]+)$") or path)
end

function M.dirname(path)
    return (path:match("^(.*)/[^/]+$") or ".")
end

function M.isRecentlyCreated(path, maxAgeSeconds)
    maxAgeSeconds = maxAgeSeconds or 300 -- 5 minutes default
    local attrs = hs.fs.attributes(path)
    if not attrs then return false end

    local now = hs.timer.secondsSinceEpoch()
    return (now - attrs.creation) < maxAgeSeconds
end

function M.shouldIgnoreFile(path)
    local name = M.basename(path)

    -- Hidden files
    if name:match("^%.") then return true end

    -- Download temporary files
    if name:match("%.download$") or
       name:match("%.crdownload$") or
       name:match("%.part$") then
        return true
    end

    return false
end

return M
