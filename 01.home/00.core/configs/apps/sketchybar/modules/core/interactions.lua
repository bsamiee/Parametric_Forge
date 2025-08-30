-- Title         : interactions.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/sketchybar/modules/core/interactions.lua
-- ----------------------------------------------------------------------------
-- Advanced interaction framework with click handlers and popup foundation

local M = {
	click_handlers = {},
	popup_stack = {},
	active_popup = nil,
	hotkey_actions = {},
}

-- Register click handler with button detection and modifier support
function M.register_click(item_name, handler, button_types)
	button_types = button_types or { "left", "right" }

	M.click_handlers[item_name] = {
		handler = handler,
		buttons = button_types,
	}

	-- Create click script that calls our handler
	local click_script = "sketchybar --trigger item_clicked ITEM=" .. item_name .. " BUTTON=$BUTTON MODIFIER=$MODIFIER"

	sbar.set(item_name, { click_script = click_script })
end

-- Popup positioning system - foundation for Tier 2 dropdowns
function M.create_popup(anchor_item, items, position)
	position = position or "below"

	-- Close existing popup
	M.close_popup()

	local popup_name = "popup_" .. anchor_item
	M.active_popup = popup_name

	-- Get anchor position for smart placement
	sbar.exec("yabai -m query --displays --display", function(display_info)
		local display = sbar.json and sbar.json.decode(display_info)

		local popup = sbar.add("item", popup_name, {
			position = "popup." .. anchor_item,
			background = {
				color = 0xff282a36, -- Dracula background
				corner_radius = 8,
				border_width = 1,
				border_color = 0xff6272a4, -- Dracula comment
			},
			popup = {
				height = 30,
				horizontal = position == "right",
			},
		})

		-- Add popup items
		for i, item_config in ipairs(items) do
			local item_name = popup_name .. "_item_" .. i
			sbar.add("item", item_name, {
				position = "popup." .. anchor_item,
				icon = { string = item_config.icon or "" },
				label = { string = item_config.label or "" },
				click_script = item_config.click_script or "",
				background = {
					color = item_config.hover and 0xff44475a or 0x00000000,
				},
			})
		end
	end)
end

-- Close active popup
function M.close_popup()
	if M.active_popup then
		sbar.remove(M.active_popup)
		M.active_popup = nil
	end
end

-- Hotkey action bridge with skhdrc integration
function M.register_hotkey_action(action_name, handler)
	M.hotkey_actions[action_name] = handler
	-- Note: Event registration handled by init system to avoid circular dependency
end

-- Called by init system after events module is ready
function M.register_events()
	for action_name, handler in pairs(M.hotkey_actions) do
		if events and events.register then
			events.register("hotkey_" .. action_name, handler, 90)
		end
	end
end

-- Mouse event processor - handles all click events centrally
function M.process_click(env)
	local item = env.ITEM
	local button = env.BUTTON
	local modifier = env.MODIFIER or ""

	local handler_info = M.click_handlers[item]
	if not handler_info then
		return
	end

	-- Check if button type is supported
	local button_supported = false
	for _, supported_button in ipairs(handler_info.buttons) do
		if
			(supported_button == "left" and button == "1")
			or (supported_button == "right" and button == "2")
			or (supported_button == "middle" and button == "3")
		then
			button_supported = true
			break
		end
	end

	if button_supported then
		handler_info.handler({
			item = item,
			button = button,
			modifier = modifier,
			close_popup = M.close_popup,
		})
	end
end

-- Initialize interaction system
function M.init()
	-- Register global click handler
	sbar.hotload(true)
	M.register("item_clicked", M.process_click, 100)

	-- Foundation events for Tier 2
	M.register_custom_event("popup_opened")
	M.register_custom_event("popup_closed")
	M.register_custom_event("interaction_state_changed")
end

return M
