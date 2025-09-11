-- Title         : menu_automations.lua
-- Author        : Parametric Forge
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/forge/menu_automations.lua
-- ----------------------------------------------------------------------------
-- Separate menubar item for Automations toggles (unzip, webp→png, DMG install).
-- Icons: use checked=true for now; suggest SF Symbols in README/output.

local automations = require("forge.automations")
local osd = require("forge.osd")
local core = require("forge.core")
local bus = core.bus

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

-- Common Hammerspoon section builder (consistent with menu_services)
local function hammerspoonSection()
  return {
    { title = "-" },
    { title = "Hammerspoon", disabled = true },
    {
      title = "Hammerspoon (reload)",
      image = assetImage("hammerspoon-reload", { w = 18, h = 18 }, false),
      fn = function()
        osd.show("Reloading Hammerspoon…")
        hs.reload()
      end,
    },
    {
      title = "Hammerspoon Console",
      image = assetImage("forge-menu", { w = 18, h = 18 }, false),
      fn = function()
        hs.openConsole()
      end,
    }
  }
end

local function currentState()
  return {
    unzip = automations.isEnabled("unzip"),
    webp  = automations.isEnabled("webp2png"),
    pdf   = automations.isEnabled("pdf"),
  }
end

local function updateIcon()
  local st = currentState()
  local anyOn = st.unzip or st.webp or st.pdf
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
    title   = string.format("Auto Unzip: %s", st.unzip and "Enabled" or "Disabled"),
    checked = st.unzip,
    image   = assetImage(st.unzip and "unzip-on" or "unzip-off", { w = 16, h = 16 }, false),
    fn = function()
      if st.unzip then automations.disable("unzip") else automations.enable("unzip") end
    end,
  })

  table.insert(items, {
    title   = string.format("Auto WebP→PNG: %s", st.webp and "Enabled" or "Disabled"),
    checked = st.webp,
    image   = assetImage(st.webp and "webp2png-on" or "webp2png-off", { w = 16, h = 16 }, false),
    fn = function()
      if st.webp then automations.disable("webp2png") else automations.enable("webp2png") end
    end,
  })

  table.insert(items, {
    title   = string.format("Auto PDF OCR+Optimize: %s", st.pdf and "Enabled" or "Disabled"),
    checked = st.pdf,
    image   = assetImage(st.pdf and "pdf-on" or "pdf-off", { w = 16, h = 16 }, false),
    fn = function()
      if st.pdf then automations.disable("pdf") else automations.enable("pdf") end
    end,
  })

  -- Add common Hammerspoon section
  for _, item in ipairs(hammerspoonSection()) do
    table.insert(items, item)
  end

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
