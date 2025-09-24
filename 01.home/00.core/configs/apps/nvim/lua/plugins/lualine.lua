-- Title         : lualine.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/nvim/lua/plugins/lualine.lua
-- ----------------------------------------------------------------------------
-- Statusline - clean and functional

return {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    lazy = false,
    priority = 999, -- Load after colorscheme (1000)
    config = function()
        local ui = require("utils.ui")
        local p = ui.palette

        -- Match yazi statusbar colors
        local colors = {
            bg = p.bg,           -- Dracula background
            fg = p.text,         -- Dracula foreground
            alt_bg = p.border,   -- Yazi's grey-blue for secondary sections
            green = p.green,
            yellow = p.yellow,
            cyan = p.cyan,
            purple = p.purple,
            orange = p.orange,
            pink = p.pink,
            red = p.red,
        }

        local custom_theme = {
            normal = {
                a = { fg = colors.bg, bg = colors.green, gui = "bold" },
                b = { fg = colors.fg, bg = colors.alt_bg },
                c = { fg = colors.fg, bg = colors.bg },
            },
            insert = {
                a = { fg = colors.bg, bg = colors.cyan, gui = "bold" },
                b = { fg = colors.fg, bg = colors.alt_bg },
                c = { fg = colors.fg, bg = colors.bg },
            },
            visual = {
                a = { fg = colors.bg, bg = colors.purple, gui = "bold" },
                b = { fg = colors.fg, bg = colors.alt_bg },
                c = { fg = colors.fg, bg = colors.bg },
            },
            replace = {
                a = { fg = colors.bg, bg = colors.red, gui = "bold" },
                b = { fg = colors.fg, bg = colors.alt_bg },
                c = { fg = colors.fg, bg = colors.bg },
            },
            command = {
                a = { fg = colors.bg, bg = colors.orange, gui = "bold" },
                b = { fg = colors.fg, bg = colors.alt_bg },
                c = { fg = colors.fg, bg = colors.bg },
            },
            inactive = {
                a = { fg = colors.fg, bg = colors.bg },
                b = { fg = colors.fg, bg = colors.bg },
                c = { fg = colors.fg, bg = colors.bg },
            },
        }

        require("lualine").setup({
            options = {
                theme = custom_theme,
                component_separators = { left = "|", right = "|" },
                section_separators = { left = "", right = "" },
                disabled_filetypes = {
                    statusline = { "NvimTree", "dashboard", "alpha" },
                },
                globalstatus = true, -- Single statusline at bottom
                refresh = {
                    statusline = 1000,
                    tabline = 1000,
                    winbar = 1000,
                },
            },
            sections = {
                lualine_a = {
                    {
                        "mode",
                        fmt = function(str) return "[" .. string.upper(str) .. "]" end
                    }
                },
                lualine_b = { "branch", "diff", "diagnostics" },
                lualine_c = {
                    {
                        "filename",
                        path = 1, -- Relative path
                        symbols = {
                            modified = " ●",
                            readonly = " ",
                            unnamed = "[No Name]",
                        },
                    },
                },
                lualine_x = { "filetype" },
                lualine_y = { "progress" },
                lualine_z = { "location" },
            },
            inactive_sections = {
                lualine_a = {},
                lualine_b = {},
                lualine_c = { "filename" },
                lualine_x = { "location" },
                lualine_y = {},
                lualine_z = {},
            },
        })
    end,
}
