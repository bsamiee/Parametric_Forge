-- Title         : spaces.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/sketchybar/modules/items/spaces.lua
-- ----------------------------------------------------------------------------
-- Yabai space integration with event-driven updates

local colors = require("modules.colors")
local icons = require("modules.icons")

-- Space configuration
local space_names = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "10" }

-- Create space items
for i, name in ipairs(space_names) do
	local space = sbar.add("space", "space." .. i, {
		space = i,
		icon = {
			string = name,
			color = colors.foreground,
		},
		label = {
			drawing = false,
		},
		background = {
			color = colors.space_inactive,
		},
		click_script = "yabai -m space --focus " .. i,
	})

	-- Event handler for space changes
	space:subscribe("space_change", function(env)
		local selected = env.SELECTED == "true"
		space:set({
			background = {
				drawing = selected,
				color = selected and colors.space_active or colors.space_inactive,
			},
			icon = {
				color = selected and colors.background or colors.foreground,
			},
		})
	end)
end

-- Add space separator
sbar.add("item", "space_separator", {
	position = "left",
	icon = {
		string = icons.separator,
		color = colors.space_inactive,
		padding_left = 4,
	},
	label = {
		drawing = false,
	},
	background = {
		drawing = false,
	},
})

-- Add front app display
sbar.add("item", "front_app", {
	position = "left",
	icon = {
		drawing = false,
	},
	label = {
		color = colors.foreground,
		padding_left = 10,
		padding_right = 10,
	},
	background = {
		color = colors.green,
	},
}):subscribe("front_app_switched", function(env)
	sbar.set("front_app", {
		label = {
			string = env.INFO or "Desktop",
		},
	})
end)
