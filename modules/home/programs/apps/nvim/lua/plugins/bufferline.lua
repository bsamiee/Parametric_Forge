-- Title         : bufferline.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/nvim/lua/plugins/bufferline.lua
-- ----------------------------------------------------------------------------
-- Buffer tabline with clean Dracula integration

return {
    "akinsho/bufferline.nvim",
    version = "*",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    event = "VeryLazy",
    keys = {
        { "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Previous buffer" },
        { "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next buffer" },
        { "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "Previous buffer" },
        { "]b", "<cmd>BufferLineCycleNext<cr>", desc = "Next buffer" },
        { "<leader>bp", "<cmd>BufferLinePick<cr>", desc = "Pick buffer" },
        { "<leader>bc", "<cmd>BufferLinePickClose<cr>", desc = "Pick buffer to close" },
    },
    config = function()
        local ui = require("utils.ui")
        local p = ui.palette

        -- Apply UI highlights first
        ui.apply_highlights()

        -- Define color scheme for different states (matching yazi tabs)
        local colors = {
            -- Inactive tabs: grey/blue background with white text
            inactive_bg = p.border,
            inactive_fg = p.text,
            -- Active tab: cyan background with black text
            active_bg = p.cyan,
            active_fg = p.bg,
            -- Special colors
            modified_inactive = p.cyan,
            modified_active = p.pink,
            error = p.red,
            warning = p.yellow,
            info = p.cyan,
        }

        -- Helper to create consistent highlight groups
        local function make_hl(state)
            if state == "selected" then
                return { fg = colors.active_fg, bg = colors.active_bg, bold = true }
            elseif state == "visible" then
                return { fg = colors.inactive_fg, bg = colors.inactive_bg }
            else -- inactive
                return { fg = colors.inactive_fg, bg = colors.inactive_bg }
            end
        end

        require("bufferline").setup({
            options = {
                mode = "buffers",
                themable = true,
                numbers = "none",
                close_command = "bdelete! %d",
                right_mouse_command = "bdelete! %d",
                left_mouse_command = "buffer %d",
                indicator = {
                    icon = "▎",
                    style = "icon",
                },
                buffer_close_icon = "󰅖",
                modified_icon = "●",
                close_icon = "",
                left_trunc_marker = "",
                right_trunc_marker = "",
                max_name_length = 18,
                tab_size = 18,
                diagnostics = "nvim_lsp",
                diagnostics_update_on_event = true,
                diagnostics_indicator = function(count, level)
                    local icon = level:match("error") and " " or " "
                    return " " .. icon .. count
                end,
                offsets = {
                    {
                        filetype = "neo-tree",
                        text = "Explorer",
                        text_align = "center",
                        separator = true,
                    },
                },
                color_icons = true,
                show_buffer_icons = true,
                show_buffer_close_icons = false,
                show_close_icon = false,
                show_tab_indicators = true,
                persist_buffer_sort = true,
                separator_style = "none",  -- Remove separators
                always_show_bufferline = true,
                hover = {
                    enabled = true,
                    delay = 200,
                    reveal = { "close" },
                },
                sort_by = "insert_after_current",
            },
            highlights = {
                -- Background
                fill = { bg = p.bg },

                -- Core buffer states
                background = make_hl("inactive"),
                buffer_visible = make_hl("visible"),
                buffer_selected = make_hl("selected"),

                -- Modified indicator (cyan for inactive, pink for active)
                modified = { fg = colors.modified_inactive, bg = colors.inactive_bg },
                modified_visible = { fg = colors.modified_inactive, bg = colors.inactive_bg },
                modified_selected = { fg = colors.modified_active, bg = colors.active_bg },

                -- Diagnostics
                diagnostic = make_hl("inactive"),
                diagnostic_visible = make_hl("visible"),
                diagnostic_selected = make_hl("selected"),

                -- Errors (red on active background)
                error = make_hl("inactive"),
                error_visible = make_hl("visible"),
                error_selected = { fg = colors.error, bg = colors.active_bg },
                error_diagnostic = make_hl("inactive"),
                error_diagnostic_visible = make_hl("visible"),
                error_diagnostic_selected = { fg = colors.error, bg = colors.active_bg },

                -- Warnings (yellow on active background)
                warning = make_hl("inactive"),
                warning_visible = make_hl("visible"),
                warning_selected = { fg = colors.warning, bg = colors.active_bg },
                warning_diagnostic = make_hl("inactive"),
                warning_diagnostic_visible = make_hl("visible"),
                warning_diagnostic_selected = { fg = colors.warning, bg = colors.active_bg },

                -- Info/Hint
                info = make_hl("inactive"),
                info_visible = make_hl("visible"),
                info_selected = make_hl("selected"),
                info_diagnostic = make_hl("inactive"),
                info_diagnostic_visible = make_hl("visible"),
                info_diagnostic_selected = make_hl("selected"),
                hint = make_hl("inactive"),
                hint_visible = make_hl("visible"),
                hint_selected = make_hl("selected"),
                hint_diagnostic = make_hl("inactive"),
                hint_diagnostic_visible = make_hl("visible"),
                hint_diagnostic_selected = make_hl("selected"),

                -- Indicators (the vertical line on the left of active buffer)
                indicator_visible = { fg = colors.inactive_fg, bg = colors.inactive_bg },
                indicator_selected = { fg = colors.active_bg, bg = colors.active_bg },

                -- Duplicates (italicize)
                duplicate = { fg = colors.inactive_fg, bg = colors.inactive_bg, italic = true },
                duplicate_visible = { fg = colors.inactive_fg, bg = colors.inactive_bg, italic = true },
                duplicate_selected = { fg = colors.active_fg, bg = colors.active_bg, italic = true },

                -- Pick mode
                pick = { fg = colors.error, bg = colors.inactive_bg, bold = true },
                pick_selected = { fg = colors.error, bg = colors.active_bg, bold = true },
                pick_visible = { fg = colors.error, bg = colors.inactive_bg, bold = true },

                -- Close buttons (disabled but defined for completeness)
                close_button = make_hl("inactive"),
                close_button_visible = make_hl("visible"),
                close_button_selected = { fg = colors.error, bg = colors.active_bg },

                -- Numbers (if enabled)
                numbers = make_hl("inactive"),
                numbers_visible = make_hl("visible"),
                numbers_selected = make_hl("selected"),

                -- Separators (hidden since we use "none" style)
                separator = { fg = p.bg, bg = p.bg },
                separator_visible = { fg = p.bg, bg = p.bg },
                separator_selected = { fg = p.bg, bg = p.bg },

                -- Offset for neo-tree
                offset_separator = { fg = p.border, bg = p.bg },
            },
        })
    end,
}