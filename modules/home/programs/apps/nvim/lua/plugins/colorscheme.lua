-- Title         : colorscheme.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/nvim/lua/plugins/colorscheme.lua
-- ----------------------------------------------------------------------------
-- Dracula colorscheme - clean, modern, no bloat

return {
    "dracula/vim",
    name = "dracula",
    lazy = false,
    priority = 1000,
    config = function()
        vim.cmd.colorscheme("dracula")
    end,
}
