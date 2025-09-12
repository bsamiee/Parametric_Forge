-- Title         : assets.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/utils/assets.lua
-- ----------------------------------------------------------------------------
-- Simple asset loading utility with caching

local config = require("utils.config")
local files = require("utils.files")

local M = {}
local ASSETS_DIR = config.getAssetsDir()
local imageCache = {}

function M.image(name, size, useTemplate)
    local key = name
    if size then
        key = key .. ":" .. tostring(size.w) .. "x" .. tostring(size.h)
    end
    if useTemplate then
        key = key .. ":template"
    end

    if imageCache[key] then
        return imageCache[key]
    end

    local path = ASSETS_DIR .. "/" .. name .. ".png"
    if not files.exists(path) then
        return nil
    end

    local img = hs.image.imageFromPath(path)
    if not img then
        return nil
    end

    if size and img.setSize then
        img = img:setSize(size)
    end

    if useTemplate and img.setTemplate then
        img = img:setTemplate(true)
    end

    imageCache[key] = img
    return img
end

return M
