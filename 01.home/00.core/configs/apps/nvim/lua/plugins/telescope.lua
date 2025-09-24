-- Title         : telescope.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/nvim/lua/plugins/telescope.lua
-- ----------------------------------------------------------------------------
-- Fuzzy finder for everything

local ui = require("utils.ui")

return {
    {
        "nvim-telescope/telescope.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-telescope/telescope-ui-select.nvim",
        },
        cmd = "Telescope",
        keys = {
            { "<C-f>", function() require("telescope.builtin").find_files() end, desc = "Find files" },
            { "<C-g>", function() require("telescope.builtin").live_grep() end, desc = "Live grep" },
            { "<C-b>", function() require("telescope.builtin").buffers() end, desc = "Buffers" },
            { "<C-h>", function() require("telescope.builtin").help_tags() end, desc = "Help" },
            { "<C-r>", function() require("telescope.builtin").oldfiles() end, desc = "Recent files" },
            { "<leader>f", function() require("telescope.builtin").find_files() end, desc = "Find files" },
            { "<leader>s", function() require("telescope.builtin").live_grep() end, desc = "Live grep" },
            {
                "<leader>p",
                function()
                    -- Try to use the clean project opener first
                    local ok = pcall(vim.cmd, "ProjectsClean")
                    if not ok then
                        -- Fallback to regular projects if clean command not available
                        local telescope_ok, telescope = pcall(require, "telescope")
                        if telescope_ok and telescope.extensions.projects then
                            telescope.extensions.projects.projects()
                        else
                            vim.notify("Telescope projects extension is not available", vim.log.levels.WARN)
                        end
                    end
                end,
                desc = "Projects",
            },
            { "<leader>bl", function() require("telescope.builtin").buffers() end, desc = "List buffers" },
            { "<leader>h", function() require("telescope.builtin").help_tags() end, desc = "Help tags" },
            { "<leader>r", function() require("telescope.builtin").oldfiles() end, desc = "Recent files" },
        },
        config = function()
            ui.apply_highlights()

            local telescope = require("telescope")
            local themes = require("telescope.themes")
            local borderchars = ui.borderchars()
            local winhighlight = ui.winhighlight()

            telescope.setup({
                defaults = {
                    prompt_prefix = "󰍉  ",
                    selection_caret = " ",
                    entry_prefix = "  ",
                    multi_icon = "󰄬 ",
                    path_display = { "truncate" },
                    sorting_strategy = "ascending",
                    border = true,
                    borderchars = borderchars,
                    winblend = 12,
                    layout_config = {
                        width = 0.75,
                        height = 0.7,
                        prompt_position = "top",
                        preview_cutoff = 120,
                        horizontal = {
                            preview_width = 0.55,
                        },
                        vertical = {
                            mirror = false,
                        },
                    },
                    results_title = false,
                    prompt_title = "",
                    preview_title = "",
                    color_devicons = true,
                    dynamic_preview_title = true,
                    winhighlight = winhighlight,
                },
                pickers = {
                    find_files = {
                        find_command = { "fd", "--type", "f", "--hidden", "--exclude", ".git" },
                    },
                },
                extensions = {
                    ["ui-select"] = themes.get_dropdown({
                        borderchars = borderchars,
                        winblend = 0,
                        layout_config = { width = 0.5 },
                        previewer = false,
                        prompt_prefix = "󰍉  ",
                        results_title = false,
                        prompt_title = "",
                    }),
                },
            })
            telescope.load_extension("ui-select")
        end,
    },
}
