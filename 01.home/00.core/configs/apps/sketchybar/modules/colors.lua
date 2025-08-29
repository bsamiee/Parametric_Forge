-- Title         : colors.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/sketchybar/modules/colors.lua
-- ----------------------------------------------------------------------------
-- Dracula color palette definitions for SketchyBar

return {
    -- Core Dracula colors
    background = 0xff282a36, -- Dark gray background
    foreground = 0xfff8f8f2, -- Light gray foreground
    current_line = 0xff44475a, -- Current line highlight
    comment = 0xff6272a4, -- Comments/muted elements

    -- Accent colors
    cyan = 0xff8be9fd, -- Primary accent
    green = 0xff50fa7b, -- Success/good status
    orange = 0xffffb86c, -- Warning/medium status
    pink = 0xffff79c6, -- Pink accent
    purple = 0xffbd93f9, -- Purple accent
    red = 0xffff5555, -- Error/critical status
    yellow = 0xfff1fa8c, -- Warning/caution

    -- Semantic aliases for better readability
    success = 0xff50fa7b, -- Green
    warning = 0xfff1fa8c, -- Yellow
    error = 0xffff5555, -- Red
    accent = 0xff8be9fd, -- Cyan

    -- Component-specific colors
    space_active = 0xff8be9fd, -- Active space
    space_inactive = 0xff6272a4, -- Inactive space
    battery_good = 0xff50fa7b, -- Battery > 60%
    battery_medium = 0xffffb86c, -- Battery 20-60%
    battery_low = 0xffff5555, -- Battery < 20%
    cpu_good = 0xff50fa7b, -- CPU < 50%
    cpu_medium = 0xfff1fa8c, -- CPU 50-80%
    cpu_high = 0xffff5555, -- CPU > 80%
}
