-- Title         : main.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : modules/home/programs/apps/yazi/plugins/sidebar-status.yazi/main.lua
-- ----------------------------------------------------------------------------
-- Clean up Yazi status bar by removing desktop information

return {
    setup = function()
        -- Status:children_remove(1, Status.LEFT) -- MODE
        -- Status:children_remove(2, Status.LEFT) -- size
        Status:children_remove(3, Status.LEFT) -- Desktop

        -- Status:children_remove(4, Status.RIGHT) -- OWNERSHIP
        -- Status:children_add(function()
        --     return ui.Span("Custom"):fg("cyan"):bold() -- custom value
        -- end, 4, Status.RIGHT)
        -- Status:children_remove(5, Status.RIGHT) -- percentage
        -- Status:children_remove(6, Status.RIGHT) -- file counter
    end,
}
