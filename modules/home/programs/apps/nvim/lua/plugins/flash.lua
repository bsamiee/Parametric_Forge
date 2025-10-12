-- Title         : flash.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/nvim/lua/plugins/flash.lua
-- ----------------------------------------------------------------------------
-- Navigate with search labels - jump anywhere in 2-3 keystrokes

return {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {
        labels = "asdfghjklqwertyuiopzxcvbnm", -- Home row first
        search = {
            multi_window = true, -- Jump across splits
            forward = true,
            wrap = true,
            mode = "exact", -- Start with exact match (KISS)
            incremental = false,
            exclude = {
                "notify",
                "cmp_menu",
                "noice",
                "flash_prompt",
                function(win)
                    return not vim.api.nvim_win_get_config(win).focusable
                end,
            },
        },
        jump = {
            jumplist = true, -- Integrate with jumplist
            pos = "start",
            history = false, -- Don't pollute search history
            register = false,
            nohlsearch = false,
            autojump = false, -- Always require explicit selection
        },
        label = {
            uppercase = true, -- More labels available
            exclude = "", -- Use all available labels
            current = true, -- Label for current position
            after = true, -- Show label after match
            before = false, -- Cleaner look
            style = "overlay", -- Don't shift text
            reuse = "lowercase", -- Smart label reuse
            distance = true, -- Prioritize closer matches
            min_pattern_length = 0,
            rainbow = {
                enabled = false, -- Keep it simple
            },
        },
        highlight = {
            backdrop = true, -- Dim other text
            matches = true,
            priority = 5000,
            groups = {
                match = "FlashMatch",
                current = "FlashCurrent",
                backdrop = "FlashBackdrop",
                label = "FlashLabel",
            },
        },
        modes = {
            search = {
                enabled = false, -- Don't hijack / and ?
            },
            char = {
                enabled = true, -- Enhance f/t/F/T
                config = function(opts)
                    -- Only show labels in operator-pending mode
                    opts.autohide = opts.autohide or (vim.fn.mode(true):find("no") and vim.v.operator == "y")

                    -- Show jump labels when useful
                    opts.jump_labels = opts.jump_labels
                        and vim.v.count == 0
                        and vim.fn.reg_executing() == ""
                        and vim.fn.reg_recording() == ""
                end,
                autohide = false,
                jump_labels = false, -- Keep f/t simple by default
                multi_line = true, -- f/t can cross lines
                label = { exclude = "hjkliardc" }, -- Avoid conflicts
                keys = { "f", "F", "t", "T", ";", "," }, -- All standard motions
                char_actions = function(motion)
                    return {
                        [";"] = "next",
                        [","] = "prev",
                        [motion:lower()] = "next",
                        [motion:upper()] = "prev",
                    }
                end,
                search = { wrap = false }, -- f/t shouldn't wrap
                highlight = { backdrop = false }, -- Too distracting for f/t
                jump = { register = false },
            },
            treesitter = {
                labels = "abcdefghijklmnopqrstuvwxyz",
                jump = { pos = "range", autojump = true },
                search = { incremental = false },
                label = { before = true, after = true, style = "inline" },
                highlight = {
                    backdrop = false,
                    matches = false,
                },
            },
        },
        prompt = {
            enabled = true,
            prefix = { { "", "FlashPromptIcon" } }, -- Nerd Font search icon
        },
    },
    keys = {
        { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
        { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
    },
    config = function(_, opts)
        require("flash").setup(opts)

        -- Set up highlights to match Dracula theme
        local ui = require("utils.ui")
        local p = ui.palette

        vim.api.nvim_set_hl(0, "FlashBackdrop", { fg = p.subtle })
        vim.api.nvim_set_hl(0, "FlashMatch", { bg = p.selection, fg = p.text, bold = true })
        vim.api.nvim_set_hl(0, "FlashCurrent", { bg = p.orange, fg = p.bg, bold = true })
        vim.api.nvim_set_hl(0, "FlashLabel", { bg = p.pink, fg = p.bg, bold = true })
        vim.api.nvim_set_hl(0, "FlashPrompt", { bg = p.bg, fg = p.text })
        vim.api.nvim_set_hl(0, "FlashPromptIcon", { fg = p.yellow })
    end,
}