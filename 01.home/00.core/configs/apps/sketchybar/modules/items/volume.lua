-- Title         : volume.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/sketchybar/modules/items/volume.lua
-- ----------------------------------------------------------------------------
-- Volume control with mute toggle integration

local colors = require("modules.colors")
local icons = require("modules.icons")

-- Helper function to get volume icon
local function get_volume_icon(volume, muted)
	if muted then
		return icons.volume_muted
	elseif volume >= 60 then
		return icons.volume_high
	elseif volume >= 30 then
		return icons.volume_medium
	elseif volume > 0 then
		return icons.volume_low
	else
		return icons.volume_muted
	end
end

-- Create volume item
local volume = sbar.add("item", "volume", {
	position = "right",
	icon = {
		string = icons.volume_high,
		color = colors.orange,
	},
	label = {
		color = colors.foreground,
	},
	background = {
		color = colors.comment,
	},
	click_script = "osascript -e 'set volume output muted not (output muted of (get volume settings))'",
})

-- Update function
local function update_volume()
	sbar.exec("osascript -e 'output volume of (get volume settings)'", function(vol_result)
		sbar.exec("osascript -e 'output muted of (get volume settings)'", function(mute_result)
			local vol = tonumber(vol_result)
			local muted = mute_result:find("true") ~= nil

			if vol then
				local icon = get_volume_icon(vol, muted)
				local label = muted and "Muted" or vol .. "%"

				volume:set({
					icon = {
						string = icon,
					},
					label = {
						string = label,
					},
				})
			end
		end)
	end)
end

-- Subscribe to volume change events
volume:subscribe("volume_change", update_volume)

-- Initial update
update_volume()
