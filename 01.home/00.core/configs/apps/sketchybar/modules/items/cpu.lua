-- Title         : cpu.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/sketchybar/modules/items/cpu.lua
-- ----------------------------------------------------------------------------
-- CPU monitoring with system-stats integration

local colors = require("modules.colors")
local icons = require("modules.icons")

-- Helper function to get CPU color based on usage
local function get_cpu_color(usage)
  if usage > 80 then
    return colors.cpu_high
  elseif usage > 50 then
    return colors.cpu_medium
  else
    return colors.cpu_good
  end
end

-- Create CPU item
local cpu = sbar.add("item", "cpu", {
  position = "right",
  icon = {
    string = icons.cpu,
    color = colors.cpu_good,
  },
  label = {
    color = colors.foreground,
  },
  background = {
    color = colors.comment,
  },
})

-- Update function using system-stats provider
local function update_cpu_stats()
  -- Check if system-stats provider is available
  sbar.exec("command -v stats_provider", function(result)
    if result and result ~= "" then
      -- Use system-stats provider (preferred)
      cpu:subscribe("system_stats", function(env)
        local usage = tonumber(env.CPU_USAGE)
        if usage then
          cpu:set({
            icon = {
              color = get_cpu_color(usage),
            },
            label = {
              string = math.floor(usage) .. "%",
            },
          })
        end
      end)
    else
      -- Fallback to shell-based monitoring
      sbar.exec("ps -A -o %cpu | awk '{s+=$1} END {printf \"%.0f\", s}'", function(cpu_result)
        local usage = tonumber(cpu_result)
        if usage then
          cpu:set({
            icon = {
              color = get_cpu_color(usage),
            },
            label = {
              string = usage .. "%",
            },
          })
        end
      end)
    end
  end)
end

-- Set up periodic updates
cpu:subscribe("routine", update_cpu_stats)

-- Initial update
update_cpu_stats()