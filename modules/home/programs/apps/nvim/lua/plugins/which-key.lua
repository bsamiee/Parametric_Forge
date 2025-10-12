-- Title         : which-key.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/nvim/lua/plugins/which-key.lua
-- ----------------------------------------------------------------------------
-- Keybinding overlay - shows available keys when you start typing

return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    init = function()
        vim.o.timeout = true
        vim.o.timeoutlen = 500 -- Trigger which-key after 500ms
    end,
    config = function()
        local wk = require("which-key")
        local ui = require("utils.ui")
        local p = ui.palette

        -- Apply Dracula theme
        vim.api.nvim_set_hl(0, "WhichKey", { fg = p.cyan })
        vim.api.nvim_set_hl(0, "WhichKeyGroup", { fg = p.purple })
        vim.api.nvim_set_hl(0, "WhichKeyDesc", { fg = p.text })
        vim.api.nvim_set_hl(0, "WhichKeyFloat", { bg = p.bg })
        vim.api.nvim_set_hl(0, "WhichKeyBorder", { fg = p.border, bg = p.bg })
        vim.api.nvim_set_hl(0, "WhichKeySeparator", { fg = p.subtle })
        vim.api.nvim_set_hl(0, "WhichKeyValue", { fg = p.orange })

        wk.setup({
            plugins = {
                marks = false, -- Disable showing marks
                registers = false, -- Disable register display
                spelling = { enabled = false }, -- No spelling suggestions
                presets = {
                    operators = false, -- No default operators
                    motions = false, -- No default motions
                    text_objects = false, -- No default text objects
                    windows = true, -- Default window commands (C-w)
                    nav = true, -- Navigation defaults ([, ])
                    z = true, -- Fold commands
                    g = true, -- g prefix commands
                },
            },
            icons = {
                breadcrumb = "»",
                separator = "➜",
                group = "+",
            },
            window = {
                border = "rounded",
                position = "bottom",
                margin = { 1, 0, 1, 0 },
                padding = { 2, 2, 2, 2 },
                winblend = 0,
            },
            layout = {
                height = { min = 4, max = 25 },
                width = { min = 20, max = 50 },
                spacing = 3,
                align = "left",
            },
            ignore_missing = false, -- Show all mappings
            hidden = { "<silent>", "<cmd>", "<Cmd>", "<CR>", "call", "lua", "^:", "^ " },
            show_help = true,
            show_keys = true,
            triggers = "auto", -- Automatically detect triggers
            triggers_blacklist = {
                i = { "j", "k" }, -- Don't trigger in insert mode for jk
                v = { "j", "k" },
            },
        })

        -- Register group names for prefixes
        -- With which-key v3, we should only register groups that don't conflict
        wk.register({
            ["<leader>"] = {
                b = { name = "+buffer" }, -- Now safe since we moved telescope buffers to bl
                l = { name = "+lsp/lint" }, -- Safe, only has sub-commands
                -- These have direct mappings, so don't register as groups:
                -- d = Dashboard (<leader>d)
                -- e = Explorer (<leader>e, <leader>E)
                -- f = Find files (<leader>f)
                -- s = Search/grep (<leader>s)
                -- p = Projects (<leader>p)
                -- h = Help (<leader>h)
                -- r = Recent files (<leader>r)
                -- w = Save (<leader>w)
                -- q = Quit (<leader>q)
                -- c = Code actions (<leader>ca)
                -- g = Format (<leader>gf)
            },
        })
    end,
}