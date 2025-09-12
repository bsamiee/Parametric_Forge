-- Title         : styles.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/notifications/styles.lua
-- ----------------------------------------------------------------------------
-- Visual styling configuration for shared canvas notifications
-- Maintains exact look from previous OSD implementation

return {
    -- Layout
    width = 520,
    rowHeight = 30,
    rowSpacing = 6,
    maxMessages = 6,
    topOffset = 8,
    radius = 12,

    -- Timing
    defaultDuration = 2.5,

    -- Typography
    font = {
        name = "GeistMono-Bold",
        size = 12
    },

    -- Color scheme (exact match to previous implementation)
    colors = {
        bg = {
            red = 0x15/255,    -- #15192F
            green = 0x19/255,
            blue = 0x2F/255,
            alpha = 0.75
        },
        text = {
            red = 0xFF/255,    -- #FF79C6 (bright pink/magenta)
            green = 0x79/255,
            blue = 0xC6/255,
            alpha = 1.00
        },
        border = {
            red = 0xf8/255,    -- #f8f8f2 (light gray)
            green = 0xf8/255,
            blue = 0xf2/255,
            alpha = 0.60
        }
    },

    -- Menubar colors (shared across all menu modules)
    menubarColors = {
        cyan = { color = { red = 0x8B/255, green = 0xE9/255, blue = 0xFD/255 } },
        yellow = { color = { red = 0xF1/255, green = 0xFA/255, blue = 0x8C/255 } },
        white = { color = { red = 1.0, green = 1.0, blue = 1.0 } }
    }
}
