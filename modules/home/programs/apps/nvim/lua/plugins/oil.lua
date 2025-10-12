-- Title         : oil.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/nvim/lua/plugins/oil.lua
-- ----------------------------------------------------------------------------
-- Edit your filesystem like a buffer - vim-vinegar on steroids

return {
    "stevearc/oil.nvim",
    dependencies = { { "echasnovski/mini.icons", opts = {} } },
    lazy = false, -- Oil hijacks directory buffers, needs to load early
    keys = {
        { "-", "<CMD>Oil<CR>", desc = "Open parent directory" },
    },
    config = function()
        require("oil").setup({
            default_file_explorer = false, -- Keep neo-tree as primary explorer
            columns = {
                "icon",
                -- "permissions", -- Only add if you need to edit permissions
                "size",        -- Keep UI clean
                "mtime",       -- Not usually relevant for dotfiles
            },
            delete_to_trash = true, -- Safety first
            skip_confirm_for_simple_edits = true, -- You know what you're doing
            prompt_save_on_select_new_entry = true, -- Prevent accidental data loss
            cleanup_delay_ms = 2000,
            lsp_file_methods = {
                enabled = true, -- Use LSP for rename operations when available
                timeout_ms = 1000,
                autosave_changes = false, -- Manual control over saves
            },
            constrain_cursor = "editable", -- Keep cursor in safe areas
            keymaps = {
                ["g?"] = "actions.show_help",
                ["<CR>"] = "actions.select",
                ["<C-v>"] = { "actions.select", opts = { vertical = true }, desc = "Open vertical" },
                ["<C-s>"] = { "actions.select", opts = { horizontal = true }, desc = "Open horizontal" },
                ["<C-t>"] = { "actions.select", opts = { tab = true }, desc = "Open in tab" },
                ["<C-p>"] = "actions.preview",
                ["<C-c>"] = "actions.close",
                ["<C-l>"] = "actions.refresh",
                ["-"] = "actions.parent",
                ["_"] = "actions.open_cwd",
                ["`"] = "actions.cd",
                ["~"] = { "actions.cd", opts = { scope = "tab" }, desc = "cd (tab scope)" },
                ["gs"] = "actions.change_sort",
                ["gx"] = "actions.open_external",
                ["g."] = "actions.toggle_hidden",
                ["g\\"] = "actions.toggle_trash",
            },
            use_default_keymaps = true,
            view_options = {
                show_hidden = true, -- You work with dotfiles constantly
                is_hidden_file = function(name, _)
                    return vim.startswith(name, ".")
                end,
                is_always_hidden = function(name, _)
                    return name == ".DS_Store" or name == ".git"
                end,
                natural_order = true, -- Better number sorting
                case_insensitive = false, -- Case matters in Unix
                sort = {
                    { "type", "asc" },
                    { "name", "asc" },
                },
            },
            float = {
                padding = 2,
                max_width = 0.9,
                max_height = 0.9,
                border = "rounded",
                win_options = {
                    winblend = 20,
                },
            },
            preview_win = {
                update_on_cursor_moved = true,
                preview_method = "fast_scratch",
            },
            confirmation = {
                border = "rounded",
            },
            progress = {
                border = "rounded",
            },
        })
    end,
}