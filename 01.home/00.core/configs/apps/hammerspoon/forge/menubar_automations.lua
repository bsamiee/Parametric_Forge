-- Title         : menubar_automations.lua
-- Author        : Parametric Forge
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/forge/menubar_automations.lua
-- ----------------------------------------------------------------------------
-- Separate menubar item for Automations toggles (unzip, webp→png, DMG install).
-- Icons: use checked=true for now; suggest SF Symbols in README/output.

local automations = require("forge.automations")
local core = require("forge.core")
local bus  = core.bus

local M = {}
local mb

-- Asset loading (same pattern as main menubar)
local function hsConfigDir()
  local v = hs.configdir
  if type(v) == "function" then return v() end
  if type(v) == "string" and #v > 0 then return v end
  return (os.getenv("HOME") or "") .. "/.hammerspoon"
end
local ASSETS_DIR = hsConfigDir() .. "/assets"
local imageCache = {}
local function assetImage(name, size, useTemplate)
  local key = name .. (size and (":" .. tostring(size.w) .. "x" .. tostring(size.h)) or "") .. (useTemplate and ":template" or "")
  if imageCache[key] then return imageCache[key] end
  local img
  local pathPng = ASSETS_DIR .. "/" .. name .. ".png"
  if hs.fs.attributes(pathPng) then img = hs.image.imageFromPath(pathPng) end
  if img then
    if size and img.setSize then img = img:setSize(size) end
    if useTemplate and img.setTemplate then img = img:setTemplate(true) end
    imageCache[key] = img
  end
  return img
end

local function currentState()
  return {
    unzip = automations.isEnabled("unzip"),
    webp  = automations.isEnabled("webp2png"),
    dmg   = automations.isEnabled("dmg"),
  }
end

local function updateIcon()
  local st = currentState()
  local anyOn = st.unzip or st.webp or st.dmg
  local icon = assetImage(anyOn and "automations-on" or "automations-off", { w = 18, h = 18 }, false)
  if not icon then
    icon = hs.image.imageFromName("NSActionTemplate")
    if icon and icon.setSize then icon = icon:setSize({ w = 18, h = 18 }) end
  end
  if icon then mb:setIcon(icon) else mb:setTitle(anyOn and "A*" or "A") end
  mb:setTooltip("Automations")
end

local function buildMenu()
  local items = {}
  local st = currentState()

  table.insert(items, { title = "Automations", disabled = true })
  table.insert(items, { title = "-" })

  table.insert(items, {
    title   = "Auto unzip .zip",
    checked = st.unzip,
    image   = assetImage(st.unzip and "unzip-on" or "unzip-off", { w = 16, h = 16 }, false),
    fn = function()
      if st.unzip then automations.disable("unzip") else automations.enable("unzip") end
    end,
  })

  table.insert(items, {
    title   = "Auto convert .webp → .png",
    checked = st.webp,
    image   = assetImage(st.webp and "webp2png-on" or "webp2png-off", { w = 16, h = 16 }, false),
    fn = function()
      if st.webp then automations.disable("webp2png") else automations.enable("webp2png") end
    end,
  })

  table.insert(items, {
    title   = "Auto install .dmg to /Applications",
    checked = st.dmg,
    image   = assetImage(st.dmg and "dmg-on" or "dmg-off", { w = 16, h = 16 }, false),
    fn = function()
      automations.setDmgEnabled(not st.dmg)
    end,
  })

  table.insert(items, { title = "-" })
  table.insert(items, { title = "Open Hammerspoon Console", fn = function() hs.openConsole() end })

  return items
end

function M.start()
  if mb then return end
  mb = hs.menubar.new()
  if not mb then return end
  mb:autosaveName("forge-menubar-automations")
  updateIcon()
  mb:setMenu(buildMenu)
  -- Listen for runtime changes
  bus.on("automations-state", function(_)
    if not mb then return end
    updateIcon()
    mb:setMenu(buildMenu)
  end)
end

function M.stop()
  if mb then mb:delete(); mb = nil end
end

return M
