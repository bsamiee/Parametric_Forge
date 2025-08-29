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

    -- Optimized event handling using Tier 1 foundations
    space:subscribe("space_changed", function(env)
        performance.debounce(function()
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
        end, 0.05, "space_" .. i)
    end)

    -- Enhanced window focus with performance optimization
    space:subscribe("window_focused", function(env)
        performance.debounce(function()
            events.trigger("yabai_space_changed", { space_id = i })
        end, 0.1, "focus_space_" .. i)
    end)

    -- Foundation for Tier 2: click interactions
    interactions.register_click("space." .. i, function(click_env)
        if click_env.button == "2" then
            events.trigger("space_context_requested", { space_id = i })
        end
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
})
    :subscribe("front_app_switched", function(env)
        sbar.set("front_app", {
            label = {
                string = env.INFO or "Desktop",
            },
        })
    end)
    :subscribe("window_focused", function(env)
        -- Performance-optimized front app updates with proper async handling
        performance.debounce(function()
            performance.yabai_query_cached("--windows --window", 2, function(window_data)
                if window_data and window_data.app then
                    sbar.set("front_app", {
                        label = { string = window_data.app },
                    })
                end
            end)
        end, 0.2, "front_app_update")
    end)

-- Foundation for Tier 2: front app interaction capabilities
interactions.register_click("front_app", function(click_env)
    if click_env.button == "2" then
        events.trigger("app_context_requested", { app = click_env.item })
    end
end)

-- Ecosystem context indicator
sbar.add("item", "ecosystem_context", {
    position = "right",
    icon = {
        string = "⚡",
        color = colors.accent,
        padding_left = 8,
    },
    label = {
        string = "Ready",
        color = colors.foreground,
        padding_right = 10,
    },
    background = {
        color = colors.comment,
        corner_radius = 6,
        height = 24,
    },
}):subscribe("ecosystem_context_switched", function(env)
    local project_type = env.project_type or "general"
    local type_colors = {
        nix = colors.cyan,
        rust = colors.orange,
        python = colors.yellow,
        git = colors.red,
        general = colors.comment,
    }

    sbar.set("ecosystem_context", {
        icon = {
            color = type_colors[project_type] or colors.accent,
            string = project_type == "nix" and "❄" or "⚡",
        },
        label = {
            string = project_type:upper(),
            color = colors.foreground,
        },
        background = {
            color = (type_colors[project_type] or colors.comment) & 0x00ffffff | 0x40000000, -- 25% opacity via alpha channel
        },
    })
end)
