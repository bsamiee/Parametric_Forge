-- Title         : url.lua
-- Author        : Parametric Forge
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/forge/url.lua
-- ----------------------------------------------------------------------------
-- Minimal hammerspoon:// URL endpoints for one-shot actions from skhd/yabai.

local M = {}
local osd = require("forge.osd")

-- forge/osd?msg=Hello&center=1&dur=0.9
hs.urlevent.bind("forge/osd", function(_, params)
  local msg = params and params.msg or nil
  if not msg or #msg == 0 then return end
  local centered = (params and params.center == "1") or true
  local dur = tonumber(params and params.dur) or 0.9
  osd.show(msg, { centered = centered, duration = dur })
end)

return M
