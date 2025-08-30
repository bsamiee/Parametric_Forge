-- Title         : slider.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/sketchybar/modules/items/slider.lua
-- ----------------------------------------------------------------------------
-- Interactive slider components using existing performance and interaction foundation

local colors = require("modules.colors")
local icons = require("modules.icons")

-- Volume slider with existing volume integration
local volume_slider = sbar.add("slider", "volume_slider", {
	position = "popup.volume",
	slider = {
		width = 120,
		percentage = 50,
		highlight_color = colors.purple,
		background = {
			color = colors.comment,
			corner_radius = 4,
			height = 8,
		},
		knob = {
			string = "●",
			color = colors.purple,
		},
	},
	background = {
		color = colors.background,
		corner_radius = 12,
		padding_left = 8,
		padding_right = 8,
		padding_top = 4,
		padding_bottom = 4,
	},
})

-- Integrate with existing volume widget using performance caching
volume_slider:subscribe("volume_change", function(env)
	local volume = tonumber(env.INFO) or 50
	performance.debounce(function()
		volume_slider:set({
			slider = { percentage = volume },
		})
	end, 0.05, "volume_slider_update")
end)

-- Interactive volume control using existing click framework
volume_slider:subscribe("mouse.clicked", function(env)
	local percentage = tonumber(env.PERCENTAGE) or 50
	
	performance.debounce(function()
		sbar.exec("osascript -e 'set volume output volume " .. percentage .. "'", function()
			-- Update existing volume widget
			events.trigger("volume_updated", { volume = percentage })
		end)
	end, 0.1, "volume_control")
end)

-- Brightness slider (macOS system integration)
local brightness_slider = sbar.add("slider", "brightness_slider", {
	position = "popup.brightness",
	slider = {
		width = 120,
		percentage = 75,
		highlight_color = colors.yellow,
		background = {
			color = colors.comment,
			corner_radius = 4,
			height = 8,
		},
		knob = {
			string = "☀",
			color = colors.yellow,
		},
	},
	background = {
		color = colors.background,
		corner_radius = 12,
		padding_left = 8,
		padding_right = 8,
		padding_top = 4,
		padding_bottom = 4,
	},
})

-- Brightness control with system integration
brightness_slider:subscribe("mouse.clicked", function(env)
	local percentage = tonumber(env.PERCENTAGE) or 75
	
	performance.debounce(function()
		-- Convert percentage to brightness scale (0.0-1.0)
		local brightness = percentage / 100.0
		sbar.exec("brightness " .. brightness, function()
			events.trigger("brightness_updated", { brightness = percentage })
		end)
	end, 0.1, "brightness_control")
end)

-- Register slider interactions using existing framework
interactions.register_click("volume_slider", function(click_env)
	events.trigger("volume_popup_toggle", {})
end)

interactions.register_click("brightness_slider", function(click_env)
	events.trigger("brightness_popup_toggle", {})
end)