-- Title         : main.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : modules/home/programs/apps/yazi/plugins/auto-layout.yazi/main.lua
-- ----------------------------------------------------------------------------
-- Automatically adjusts Yazi pane layout based on terminal width

-- --- Configuration ----------------------------------------------------------
local plugin_config = {
  breakpoint_large = 200,
  breakpoint_medium = 100,
}

-- Fallback Ratios
local fallback_ratios = { parent = 2, current = 3, preview = 4, all = 9 }

-- --- Plugin Module ----------------------------------------------------------
local M = {}

local original_layout = nil
local layout_overridden = false

local function get_layout_ratios()
  if rt and rt.mgr and rt.mgr.ratio and
     rt.mgr.ratio.parent and rt.mgr.ratio.current and
     rt.mgr.ratio.preview and rt.mgr.ratio.all then
      return rt.mgr.ratio
  else
      return fallback_ratios
  end
end

-- Layout override Function ---------------------------------------------------
local function auto_layout_override(self)
  if not self._area or not self._area.w then
    if original_layout then original_layout(self) end
    return
  end
  if not ui or not ui.Layout or not ui.Constraint then
    if original_layout then original_layout(self) end
    return
  end

  local w = self._area.w
  local ratios = get_layout_ratios()

  local success, result = pcall(function()
    local constraints
    if w > plugin_config.breakpoint_large then
      constraints = {
        ui.Constraint.Ratio(ratios.parent, ratios.all),
        ui.Constraint.Ratio(ratios.current, ratios.all),
        ui.Constraint.Ratio(ratios.preview, ratios.all),
      }
    elseif w > plugin_config.breakpoint_medium then
      constraints = {
        ui.Constraint.Ratio(0, ratios.all),
        ui.Constraint.Ratio(ratios.current + ratios.parent, ratios.all),
        ui.Constraint.Ratio(ratios.preview + ratios.parent, ratios.all),
      }
    else
      constraints = {
        ui.Constraint.Ratio(0, ratios.all),
        ui.Constraint.Ratio(ratios.all, ratios.all),
        ui.Constraint.Ratio(0, ratios.all),
      }
    end

    self._chunks = ui.Layout() :direction(ui.Layout.HORIZONTAL) :constraints(constraints) :split(self._area)
    if not self._chunks then error("Layout split returned nil chunks") end
  end)

  if not success or not self._chunks then
    if original_layout then original_layout(self) end
  end
end

-- Setup function -------------------------------------------------------------
function M.setup(user_config)
  if type(user_config) == "table" then
    for k, v in pairs(user_config) do
      if plugin_config[k] ~= nil then
         plugin_config[k] = v
      end
    end
  end

  if layout_overridden then
     return
  end

  if not Tab then
    return
  end

  if not original_layout then
    original_layout = Tab.layout
    if not original_layout then
      original_layout = function() end
    end
  end

  Tab.layout = auto_layout_override
  layout_overridden = true
end

return M
