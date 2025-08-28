-- Title         : battery.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/sketchybar/modules/items/battery.lua
-- ----------------------------------------------------------------------------
-- Battery status monitor with event-driven updates

local colors = require("modules.colors")
local icons = require("modules.icons")

-- Helper function to get battery icon and color
local function get_battery_display(percentage, charging)
	local icon, color

	if charging then
		icon = icons.battery_charging
		color = colors.battery_good
	elseif percentage >= 75 then
		icon = icons.battery_100
		color = colors.battery_good
	elseif percentage >= 50 then
		icon = icons.battery_75
		color = colors.battery_good
	elseif percentage >= 25 then
		icon = icons.battery_50
		color = colors.battery_medium
	else
		icon = icons.battery_25
		color = colors.battery_low
	end
	return icon, color
end

-- Create battery item
local battery = sbar.add("item", "battery", {
	position = "right",
	update_freq = 120,
	icon = {
		string = icons.battery_100,
		color = colors.battery_good,
	},
	label = {
		color = colors.foreground,
	},
	background = {
		color = colors.comment,
	},
})

-- Update function
local function update_battery()
	sbar.exec("pmset -g batt", function(result)
		local percentage = result:match("(%d+)%%")
		local charging = result:find("AC Power") ~= nil

		if percentage then
			local pct = tonumber(percentage)
			local icon, color = get_battery_display(pct, charging)

			battery:set({
				icon = {
					string = icon,
					color = color,
				},
				label = {
					string = percentage .. "%",
				},
			})
		end
	end)
end

-- Subscribe to system events
battery:subscribe({ "system_woke", "power_source_change" }, update_battery)

-- Initial update
update_battery()
