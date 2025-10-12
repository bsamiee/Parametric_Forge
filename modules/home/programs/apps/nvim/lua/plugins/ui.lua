-- Title         : ui.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/nvim/lua/plugins/ui.lua
-- ----------------------------------------------------------------------------
-- High-touch UI plugins that align Neovim with the Parametric Forge visual system

local ui = require("utils.ui")

return {
    {
        "folke/noice.nvim",
        event = "VeryLazy",
        dependencies = {
            "MunifTanjim/nui.nvim",
            "nvim-lua/plenary.nvim",
        },
        opts = function()
            ui.apply_highlights()

            local popup_winhighlight = table.concat({
                "Normal:NoicePopup",
                "FloatBorder:NoicePopupBorder",
                "FloatTitle:FloatTitle",
                "FloatFooter:FloatFooter",
            }, ",")
            local cmdline_winhighlight = table.concat({
                "Normal:NoiceCmdlinePopup",
                "FloatBorder:NoiceCmdlinePopupBorder",
                "FloatTitle:NoiceCmdlinePopupTitle",
                "FloatFooter:FloatFooter",
                "NormalFloat:NoiceCmdlinePopup",
            }, ",")

            return {
                presets = {
                    bottom_search = true,
                    command_palette = true,
                    long_message_to_split = false,
                    inc_rename = false,
                    lsp_doc_border = true,
                },
                notify = { enabled = false },
                cmdline = {
                    view = "cmdline_popup",
                    format = {
                        cmdline = { icon = "", icon_hl_group = "NoiceCmdlineIcon" },
                        search_up = { icon = "", icon_hl_group = "NoiceCmdlineIcon" },
                        search_down = { icon = "", icon_hl_group = "NoiceCmdlineIcon" },
                        filter = { icon = "", icon_hl_group = "NoiceCmdlineIcon" },
                        lua = { icon = "", icon_hl_group = "NoiceCmdlineIcon" },
                        help = { icon = "󰘥", icon_hl_group = "NoiceCmdlineIcon" },
                    },
                },
                lsp = {
                    progress = {
                        enabled = true,
                        format = "[%s] %s",
                    },
                    hover = {
                        enabled = true,
                        view = "popup",
                    },
                    signature = {
                        enabled = true,
                        auto_open = {
                            enabled = true,
                            trigger = true,
                            throttle = 50,
                        },
                    },
                    override = {
                        ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
                        ["vim.lsp.util.stylize_markdown"] = true,
                        ["cmp.entry.get_documentation"] = true,
                    },
                },
                routes = {
                    {
                        filter = {
                            event = "msg_show",
                            kind = "search_count",
                        },
                        view = "mini",
                    },
                },
                views = {
                    popup = {
                        border = {
                            style = "rounded",
                            padding = {0, 0},
                        },
                        win_options = {
                            winblend = 0,
                            winhighlight = popup_winhighlight,
                        },
                    },
                    popupmenu = {
                        relative = "editor",
                        position = {
                            row = "50%",
                            col = "50%",
                        },
                        size = {
                            width = 60,
                            height = 18,
                        },
                        border = {
                            style = "rounded",
                            padding = {0, 0},
                        },
                        win_options = {
                            winhighlight = popup_winhighlight,
                        },
                    },
                    mini = {
                        win_options = {
                            winhighlight = popup_winhighlight,
                        },
                    },
                    cmdline_popup = {
                        border = {
                            style = "rounded",
                            padding = {0, 0},
                        },
                        position = {
                            row = "17%",
                            col = "50%",
                        },
                        size = {
                            width = 60,
                        },
                        win_options = {
                            winblend = 12,
                            winhighlight = cmdline_winhighlight,
                        },
                    },
                    cmdline_input = {
                        border = {
                            style = "none",
                            padding = {0, 0},
                        },
                        win_options = {
                            winblend = 12,
                            winhighlight = cmdline_winhighlight,
                        },
                    },
                },
                format = {
                    level = {
                        icons = {
                            error = "",
                            warn = "",
                            info = "",
                        },
                    },
                },
            }
        end,
    },
    {
        "folke/edgy.nvim",
        event = "VeryLazy",
        dependencies = {
            "folke/noice.nvim",
            "nvim-neo-tree/neo-tree.nvim",
        },
        opts = function()
            ui.apply_highlights()
            local base_winhighlight = ui.winhighlight()
            local edgy_winhighlight = base_winhighlight .. ",WinBar:EdgyWinBar,WinBarNC:EdgyWinBarNC"

            return {
                animate = { enabled = false },
                bottom = {
                    {
                        ft = "toggleterm",
                        title = "Terminal",
                        size = { height = 0.30 },
                        filter = function(buf)
                            return vim.bo[buf].filetype == "toggleterm"
                        end,
                    },
                    {
                        ft = "Trouble",
                        title = "Diagnostics",
                        size = { height = 0.28 },
                        filter = function(buf)
                            return vim.bo[buf].filetype == "Trouble"
                        end,
                    },
                    {
                        ft = "qf",
                        title = "Quickfix",
                        size = { height = 0.22 },
                        filter = function(buf)
                            return vim.bo[buf].filetype == "qf"
                        end,
                    },
                },
                left = {
                    {
                        ft = "neo-tree",
                        title = "Explorer",
                        size = { width = 36 },
                        pinned = true,
                        open = "Neotree reveal",
                        filter = function(buf)
                            return vim.b[buf].neo_tree_source == "filesystem"
                        end,
                    },
                },
                options = {
                    left = {
                        wo = {
                            winhighlight = edgy_winhighlight,
                            winblend = 0,
                        },
                    },
                    bottom = {
                        wo = {
                            winhighlight = edgy_winhighlight,
                            winblend = 0,
                        },
                    },
                },
            }
        end,
    },
    {
        "stevearc/dressing.nvim",
        event = "VeryLazy",
        opts = function()
            ui.apply_highlights()
            local winhighlight = ui.winhighlight()
            local borderchars = ui.borderchars()

            local function telescope_dropdown()
                local ok, themes = pcall(require, "telescope.themes")
                if not ok then
                    return {}
                end
                return themes.get_dropdown({
                    previewer = false,
                    layout_config = { width = 0.5, height = 0.4 },
                    borderchars = borderchars,
                    winblend = 0,
                    prompt_prefix = "󰍉  ",
                    results_title = false,
                    prompt_title = "",
                })
            end

            return {
                input = {
                    enabled = true,
                    default_prompt = "➤ ",
                    win_options = {
                        winhighlight = winhighlight,
                        winblend = 0,
                    },
                    border = "rounded",
                    relative = "editor",
                    prefer_width = 60,
                },
                select = {
                    backend = { "nui", "telescope" },
                    nui = {
                        position = "50%",
                        size = nil,
                        relative = "editor",
                        border = {
                            style = "rounded",
                        },
                        win_options = {
                            winhighlight = winhighlight,
                            winblend = 0,
                        },
                    },
                    telescope = telescope_dropdown,
                },
            }
        end,
    },
}
