-- Title         : clock.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/sketchybar/modules/items/clock.lua
-- ----------------------------------------------------------------------------
-- Date and time display with calendar integration

local colors = require("modules.colors")
local icons = require("modules.icons")

-- Create clock item
local clock = sbar.add("item", "clock", {
  position = "right",
  update_freq = 10,
  icon = {
    string = icons.clock,
    color = colors.purple,
  },
  label = {
    color = colors.foreground,
  },
  background = {
    color = colors.comment,
  },
  click_script = "open -a Calendar",
})

-- Update function
local function update_clock()
  sbar.exec("date '+%a %m/%d %H:%M'", function(result)
    clock:set({
      label = {
        string = result:gsub("\n", ""),
      },
    })
  end)
end

-- Subscribe to timer events
clock:subscribe("routine", update_clock)

-- Initial update
update_clock()