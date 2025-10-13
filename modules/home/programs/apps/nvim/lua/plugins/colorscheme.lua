-- Title         : colorscheme.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : modules/home/programs/apps/nvim/lua/plugins/colorscheme.lua
-- ----------------------------------------------------------------------------
-- Dracula colorscheme - clean, modern, no bloat

return {
    "dracula/vim",
    name = "dracula",
    lazy = false,
    priority = 1000,
    config = function()
        vim.cmd.colorscheme("dracula")
        -- Enable transparency
        vim.cmd("highlight Normal guibg=NONE ctermbg=NONE")
        vim.cmd("highlight NormalFloat guibg=NONE ctermbg=NONE")
        vim.cmd("highlight SignColumn guibg=NONE ctermbg=NONE")
        -- Override dashboard colors to use cyan instead of green
        vim.cmd("highlight SnacksDashboardHeader guifg=#8be9fd")
        vim.cmd("highlight SnacksDashboardKey guifg=#8be9fd")
        vim.cmd("highlight SnacksDashboardIcon guifg=#8be9fd")
    end,
}
