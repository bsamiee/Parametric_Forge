-- Title         : completion.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/nvim/lua/plugins/completion.lua
-- ----------------------------------------------------------------------------
-- Completion engine with nvim-cmp, snippets, and all sources

return {
    -- Snippet engine (required for nvim-cmp)
    {
        "L3MON4D3/LuaSnip",
        build = "make install_jsregexp",
        dependencies = {
            "rafamadriz/friendly-snippets", -- Preconfigured snippets
        },
        config = function()
            require("luasnip.loaders.from_vscode").lazy_load()
        end,
    },

    -- Completion engine
    {
        "hrsh7th/nvim-cmp",
        event = { "InsertEnter", "CmdlineEnter" },
        dependencies = {
            "L3MON4D3/LuaSnip",
            "saadparwaiz1/cmp_luasnip",                -- Snippet completions
            "hrsh7th/cmp-nvim-lsp",                    -- LSP completions
            "hrsh7th/cmp-nvim-lsp-signature-help",     -- Function signatures
            "hrsh7th/cmp-buffer",                      -- Buffer word completions
            "hrsh7th/cmp-path",                        -- Path completions
            "hrsh7th/cmp-cmdline",                     -- Command line completions
            "hrsh7th/cmp-nvim-lua",                    -- Neovim Lua API
            "onsails/lspkind.nvim",                    -- VSCode-like pictograms
        },
        config = function()
            local cmp = require("cmp")
            local luasnip = require("luasnip")
            local lspkind = require("lspkind")
            local ui = require("utils.ui")

            -- Apply UI highlights
            ui.apply_highlights()

            -- Dracula-themed highlights for completion
            local p = ui.palette
            vim.api.nvim_set_hl(0, "CmpItemAbbrDefault", { fg = p.text })
            vim.api.nvim_set_hl(0, "CmpItemAbbrMatch", { fg = p.cyan, bold = true })
            vim.api.nvim_set_hl(0, "CmpItemAbbrMatchFuzzy", { fg = p.cyan, bold = true })
            vim.api.nvim_set_hl(0, "CmpItemKind", { fg = p.purple })
            vim.api.nvim_set_hl(0, "CmpItemMenu", { fg = p.subtle })
            vim.api.nvim_set_hl(0, "CmpBorder", { fg = p.border })
            vim.api.nvim_set_hl(0, "CmpDocBorder", { fg = p.border })
            vim.api.nvim_set_hl(0, "CmpPmenu", { bg = p.panel })
            vim.api.nvim_set_hl(0, "CmpSel", { bg = p.selection, bold = true })
            vim.api.nvim_set_hl(0, "CmpGhostText", { link = "Comment" })

            -- Kind highlights (match VSCode)
            vim.api.nvim_set_hl(0, "CmpItemKindText", { fg = p.text })
            vim.api.nvim_set_hl(0, "CmpItemKindMethod", { fg = p.purple })
            vim.api.nvim_set_hl(0, "CmpItemKindFunction", { fg = p.purple })
            vim.api.nvim_set_hl(0, "CmpItemKindConstructor", { fg = p.yellow })
            vim.api.nvim_set_hl(0, "CmpItemKindField", { fg = p.cyan })
            vim.api.nvim_set_hl(0, "CmpItemKindVariable", { fg = p.cyan })
            vim.api.nvim_set_hl(0, "CmpItemKindClass", { fg = p.yellow })
            vim.api.nvim_set_hl(0, "CmpItemKindInterface", { fg = p.yellow })
            vim.api.nvim_set_hl(0, "CmpItemKindModule", { fg = p.yellow })
            vim.api.nvim_set_hl(0, "CmpItemKindProperty", { fg = p.cyan })
            vim.api.nvim_set_hl(0, "CmpItemKindUnit", { fg = p.text })
            vim.api.nvim_set_hl(0, "CmpItemKindValue", { fg = p.orange })
            vim.api.nvim_set_hl(0, "CmpItemKindEnum", { fg = p.yellow })
            vim.api.nvim_set_hl(0, "CmpItemKindKeyword", { fg = p.pink })
            vim.api.nvim_set_hl(0, "CmpItemKindSnippet", { fg = p.green })
            vim.api.nvim_set_hl(0, "CmpItemKindColor", { fg = p.text })
            vim.api.nvim_set_hl(0, "CmpItemKindFile", { fg = p.text })
            vim.api.nvim_set_hl(0, "CmpItemKindReference", { fg = p.text })
            vim.api.nvim_set_hl(0, "CmpItemKindFolder", { fg = p.cyan })
            vim.api.nvim_set_hl(0, "CmpItemKindEnumMember", { fg = p.cyan })
            vim.api.nvim_set_hl(0, "CmpItemKindConstant", { fg = p.orange })
            vim.api.nvim_set_hl(0, "CmpItemKindStruct", { fg = p.yellow })
            vim.api.nvim_set_hl(0, "CmpItemKindEvent", { fg = p.purple })
            vim.api.nvim_set_hl(0, "CmpItemKindOperator", { fg = p.pink })
            vim.api.nvim_set_hl(0, "CmpItemKindTypeParameter", { fg = p.cyan })

            cmp.setup({
                snippet = {
                    expand = function(args)
                        luasnip.lsp_expand(args.body)
                    end,
                },
                window = {
                    completion = {
                        border = "rounded",
                        winhighlight = "Normal:CmpPmenu,FloatBorder:CmpBorder,CursorLine:CmpSel,Search:None",
                        scrollbar = false,
                    },
                    documentation = {
                        border = "rounded",
                        winhighlight = "Normal:CmpPmenu,FloatBorder:CmpDocBorder,Search:None",
                        max_height = 15,
                        max_width = 60,
                    },
                },
                formatting = {
                    fields = { "kind", "abbr", "menu" },
                    format = lspkind.cmp_format({
                        mode = "symbol",
                        maxwidth = 50,
                        ellipsis_char = "...",
                        symbol_map = {
                            Text = "󰉿", Method = "󰆧", Function = "󰊕", Constructor = "",
                            Field = "󰜢", Variable = "󰀫", Class = "󰠱", Interface = "",
                            Module = "", Property = "󰜢", Unit = "󰑭", Value = "󰎠",
                            Enum = "", Keyword = "󰌋", Snippet = "", Color = "󰏘",
                            File = "󰈙", Reference = "󰈇", Folder = "󰉋", EnumMember = "",
                            Constant = "󰏿", Struct = "󰙅", Event = "", Operator = "󰆕",
                            TypeParameter = "",
                        },
                        before = function(entry, vim_item)
                            vim_item.menu = ({
                                nvim_lsp = "[LSP]",
                                nvim_lua = "[Lua]",
                                luasnip = "[Snip]",
                                buffer = "[Buf]",
                                path = "[Path]",
                                cmdline = "[Cmd]",
                            })[entry.source.name]
                            return vim_item
                        end,
                    }),
                },
                mapping = cmp.mapping.preset.insert({
                    ["<C-n>"] = cmp.mapping.select_next_item(),
                    ["<C-p>"] = cmp.mapping.select_prev_item(),
                    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
                    ["<C-f>"] = cmp.mapping.scroll_docs(4),
                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<C-e>"] = cmp.mapping.abort(),
                    ["<CR>"] = cmp.mapping.confirm({ select = false }), -- Only confirm explicitly selected
                    ["<Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_next_item()
                        elseif luasnip.expand_or_jumpable() then
                            luasnip.expand_or_jump()
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                    ["<S-Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_prev_item()
                        elseif luasnip.jumpable(-1) then
                            luasnip.jump(-1)
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                }),
                sources = cmp.config.sources({
                    { name = "nvim_lsp", priority = 1000 },
                    { name = "nvim_lsp_signature_help", priority = 900 },
                    { name = "luasnip", priority = 750 },
                    { name = "nvim_lua", priority = 700 },
                }, {
                    { name = "buffer", keyword_length = 3 },
                    { name = "path" },
                }),
                experimental = {
                    ghost_text = { hl_group = "CmpGhostText" },
                },
                performance = {
                    debounce = 60,
                    throttle = 30,
                    fetching_timeout = 200,
                },
            })

            -- Command line setup for / search
            cmp.setup.cmdline({ "/", "?" }, {
                mapping = cmp.mapping.preset.cmdline(),
                sources = {
                    { name = "buffer" },
                },
            })

            -- Command line setup for : commands
            cmp.setup.cmdline(":", {
                mapping = cmp.mapping.preset.cmdline(),
                sources = cmp.config.sources({
                    { name = "path" },
                }, {
                    { name = "cmdline", keyword_length = 2 },
                }),
                matching = { disallow_symbol_nonprefix_matching = false },
            })
        end,
    },
}