-- Title         : neo-tree.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/nvim/lua/plugins/neo-tree.lua
-- ----------------------------------------------------------------------------
-- File explorer aligned with yazi aesthetics - Dracula theme, git status on icons only

local ui = require("utils.ui")

return {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "MunifTanjim/nui.nvim",
        "nvim-tree/nvim-web-devicons",
    },
    cmd = "Neotree",
    keys = {
        { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Explorer" },
        { "<leader>E", "<cmd>Neotree focus<cr>", desc = "Focus Explorer" },
        { "-", "<cmd>Neotree reveal<cr>", desc = "Reveal in Explorer" },
    },
    config = function()
        ui.apply_highlights()

        -- Dracula colors matching yazi theme.toml
        local colors = vim.tbl_extend("force", ui.palette, {
            selection = "#44475a",
        })
        colors.fg = colors.text

        -- Set up highlight groups to match yazi's Dracula theme
        local highlights = {
            -- File explorer background and structure
            NeoTreeNormal = { bg = colors.bg, fg = colors.fg },
            NeoTreeNormalNC = { bg = colors.bg, fg = colors.fg },
            NeoTreeVertSplit = { bg = colors.bg, fg = colors.selection },
            NeoTreeWinSeparator = { bg = colors.bg, fg = colors.selection },
            NeoTreeEndOfBuffer = { bg = colors.bg, fg = colors.bg },
            NeoTreeRootName = { fg = colors.yellow, bold = true, underline = true },
            NeoTreeIndentMarker = { fg = colors.selection },
            NeoTreeExpander = { fg = colors.subtle },
            NeoTreeStatusLine = { bg = colors.bg, fg = colors.fg },

            -- Current line / cursor - match yazi's inverted selection style
            NeoTreeCursorLine = { fg = colors.bg, bg = colors.fg, bold = true },
            NeoTreeCursorNumber = { fg = colors.bg, bg = colors.fg, bold = true },

            -- File names and directories (preserve type colors, no git influence)
            NeoTreeFileName = { fg = colors.fg },
            NeoTreeFileNameOpened = { fg = colors.green },
            NeoTreeDirectoryName = { fg = colors.cyan, bold = true },
            NeoTreeDirectoryIcon = { fg = colors.cyan },

            -- Git status colors (ONLY for the git icons/symbols, not filenames), aligned with yazi's git color scheme
            NeoTreeGitAdded = { fg = colors.green },
            NeoTreeGitModified = { fg = colors.orange },
            NeoTreeGitDeleted = { fg = colors.pink }, -- Changed from red to match yazi
            NeoTreeGitRenamed = { fg = colors.purple },
            NeoTreeGitUntracked = { fg = colors.yellow },
            NeoTreeGitIgnored = { fg = colors.subtle },
            NeoTreeGitConflict = { fg = colors.red, bold = true },
            NeoTreeGitStaged = { fg = colors.green, bold = true },
            NeoTreeGitUnstaged = { fg = colors.orange },

            -- Modified indicator
            NeoTreeModified = { fg = colors.orange },

            -- Symbolic link
            NeoTreeSymbolicLinkTarget = { fg = colors.pink },

            -- Floating window
            NeoTreeFloatBorder = { fg = colors.cyan },
            NeoTreeFloatTitle = { fg = colors.cyan, bold = true },

            -- Tab/buffer indicators
            NeoTreeTabActive = { bg = colors.cyan, fg = colors.bg, bold = true },
            NeoTreeTabInactive = { bg = colors.subtle, fg = colors.fg },
            NeoTreeTabSeparatorActive = { fg = colors.cyan, bg = colors.bg },
            NeoTreeTabSeparatorInactive = { fg = colors.subtle, bg = colors.bg },
        }

        -- Apply highlight groups
        for group, settings in pairs(highlights) do
            vim.api.nvim_set_hl(0, group, settings)
        end

        require("neo-tree").setup({
            close_if_last_window = true,
            popup_border_style = "rounded",
            enable_git_status = true,
            enable_diagnostics = false,
            sort_case_insensitive = true,
            default_component_configs = {
                container = {
                    enable_character_fade = true,
                },
                indent = {
                    indent_size = 2,
                    padding = 1,
                    with_markers = true,
                    indent_marker = "│",
                    last_indent_marker = "└",
                    highlight = "NeoTreeIndentMarker",
                    with_expanders = true,
                    expander_collapsed = "",
                    expander_expanded = "",
                    expander_highlight = "NeoTreeExpander",
                },
                icon = {
                    folder_closed = "",
                    folder_open = "",
                    folder_empty = "󰜌",
                    default = "",
                    highlight = "NeoTreeFileIcon",
                },
                modified = {
                    symbol = "●",
                    highlight = "NeoTreeModified",
                },
                name = {
                    trailing_slash = false,
                    use_git_status_colors = false, -- CRITICAL: Don't color filenames with git status
                    highlight = "NeoTreeFileName",
                },
                git_status = {
                    symbols = {
                        -- Match yazi's git symbols and ensure they use highlight groups
                        added     = "",
                        modified  = "",
                        deleted   = "",
                        renamed   = "",
                        untracked = "?",
                        ignored   = "",
                        unstaged  = "󰄱",
                        staged    = "󰱒",
                        conflict  = "",
                    },
                    align = "right", -- Align git status to the right like yazi
                },
            },
            window = {
                position = "left",
                width = 35,
                mapping_options = {
                    noremap = true,
                    nowait = true,
                },
                win_options = {
                    winhighlight = ui.winhighlight(),
                    winblend = 0,
                },
                mappings = {
                    ["<space>"] = { "toggle_node", nowait = false },
                    ["<cr>"] = "open",
                    ["l"] = "open",
                    ["h"] = "close_node",
                    ["s"] = "open_split",
                    ["v"] = "open_vsplit",
                    ["t"] = "open_tabnew",
                    ["w"] = "open_with_window_picker",
                    ["C"] = "close_all_nodes",
                    ["z"] = "close_all_nodes",
                    ["Z"] = "expand_all_nodes",
                    ["a"] = { "add", config = { show_path = "none" } },
                    ["A"] = "add_directory",
                    ["d"] = "delete",
                    ["r"] = "rename",
                    ["y"] = "copy_to_clipboard",
                    ["x"] = "cut_to_clipboard",
                    ["p"] = "paste_from_clipboard",
                    ["c"] = "copy",
                    ["m"] = "move",
                    ["q"] = "close_window",
                    ["R"] = "refresh",
                    ["?"] = "show_help",
                    ["<"] = "prev_source",
                    [">"] = "next_source",
                    ["i"] = "show_file_details",
                    ["H"] = "toggle_hidden",
                    ["."] = "set_root",
                    ["<bs>"] = "navigate_up",
                    ["/"] = "fuzzy_finder",
                    ["f"] = "filter_on_submit",
                    ["<c-x>"] = "clear_filter",
                    ["[g"] = "prev_git_modified",
                    ["]g"] = "next_git_modified",
                },
            },
            filesystem = {
                bind_to_cwd = true,
                follow_current_file = {
                    enabled = true,
                    leave_dirs_open = false,
                },
                use_libuv_file_watcher = true,
                hijack_netrw_behavior = "open_current",
                filtered_items = {
                    visible = false,
                    hide_dotfiles = false,
                    hide_gitignored = false,
                    hide_hidden = false,
                    hide_by_name = {
                        ".DS_Store",
                        "thumbs.db",
                        ".git",
                    },
                    hide_by_pattern = {
                        "*/node_modules/*",
                        "*/.git/*",
                    },
                    never_show = {
                        ".DS_Store",
                        "thumbs.db",
                    },
                },
                window = {
                    mappings = {
                        ["o"] = { "show_help", nowait = false, config = { title = "Order by", prefix_key = "o" } },
                        ["oc"] = { "order_by_created", nowait = false },
                        ["od"] = { "order_by_diagnostics", nowait = false },
                        ["og"] = { "order_by_git_status", nowait = false },
                        ["om"] = { "order_by_modified", nowait = false },
                        ["on"] = { "order_by_name", nowait = false },
                        ["os"] = { "order_by_size", nowait = false },
                        ["ot"] = { "order_by_type", nowait = false },
                    },
                },
            },
            buffers = {
                follow_current_file = {
                    enabled = true,
                    leave_dirs_open = false,
                },
                group_empty_dirs = false,
                show_unloaded = true,
                window = {
                    mappings = {
                        ["bd"] = "buffer_delete",
                        ["<bs>"] = "navigate_up",
                        ["."] = "set_root",
                    },
                },
            },
            git_status = {
                window = {
                    position = "float",
                    win_options = {
                        winhighlight = ui.winhighlight(),
                    },
                    mappings = {
                        ["A"] = "git_add_all",
                        ["gu"] = "git_unstage_file",
                        ["ga"] = "git_add_file",
                        ["gr"] = "git_revert_file",
                        ["gc"] = "git_commit",
                        ["gp"] = "git_push",
                        ["gg"] = "git_commit_and_push",
                    },
                },
            },
        })
    end,
}
