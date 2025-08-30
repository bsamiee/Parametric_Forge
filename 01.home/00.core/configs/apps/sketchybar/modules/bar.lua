-- Title         : bar.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/sketchybar/modules/bar.lua
-- ----------------------------------------------------------------------------
-- Bar configuration with Dracula theme integration

local colors = require("modules.colors")

-- Configure bar appearance
sbar.bar({
    height = 32,
    blur_radius = 30,
    position = "top",
    sticky = true,
    padding_left = 10,
    padding_right = 10,
    color = colors.background,
    corner_radius = 0,
    y_offset = 0,
    margin = 0,
})

-- Set default item properties
sbar.default({
    icon = {
        font = "SF Pro:Semibold:15.0",
        color = colors.foreground,
        padding_left = 10,
        padding_right = 4,
    },
    label = {
        font = "SF Pro:Semibold:15.0",
        color = colors.foreground,
        padding_left = 4,
        padding_right = 10,
    },
    background = {
        color = colors.comment,
        corner_radius = 6,
        height = 24,
    },
    padding_left = 5,
    padding_right = 5,
})
