-- Title         : brackets.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/sketchybar/modules/items/brackets.lua
-- ----------------------------------------------------------------------------
-- Bracket components for visual grouping using existing foundation

local colors = require("modules.colors")

-- Left side bracket: Workspace navigation group
sbar.add("bracket", "workspace_group", "/space\\..*/", "space_separator", "front_app", {
	background = {
		color = colors.comment,
		corner_radius = 8,
		height = 28,
		padding_left = 4,
		padding_right = 4,
	},
})

-- Right side bracket: System monitoring group  
sbar.add("bracket", "system_group", "volume", "battery", "cpu", "clock", "project_context", {
	background = {
		color = colors.comment,
		corner_radius = 8,
		height = 28,
		padding_left = 4,
		padding_right = 4,
	},
})

-- Dynamic bracket visibility using existing event system
events.register("yabai_space_changed", function(data)
	-- Highlight workspace bracket on space changes
	performance.debounce(function()
		sbar.animate("tanh", 0.2, function()
			sbar.set("workspace_group", {
				background = { color = colors.purple },
			})
		end)
		
		sbar.delay(0.5, function()
			sbar.animate("tanh", 0.3, function()
				sbar.set("workspace_group", {
					background = { color = colors.comment },
				})
			end)
		end)
	end, 0.1, "bracket_highlight")
end)

-- Register click interactions using existing framework
interactions.register_click("workspace_group", function(click_env)
	if click_env.button == "2" then
		events.trigger("workspace_overview_requested", {})
	end
end)

interactions.register_click("system_group", function(click_env)
	if click_env.button == "2" then
		events.trigger("system_overview_requested", {})
	end
end)