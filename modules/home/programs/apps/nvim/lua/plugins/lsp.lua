-- Title         : lsp.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/nvim/lua/plugins/lsp.lua
-- ----------------------------------------------------------------------------
-- LSP foundation - Mason for installation, lspconfig for configuration

return {
    -- Mason: LSP installer
    {
        "williamboman/mason.nvim",
        cmd = "Mason",
        build = ":MasonUpdate",
        opts = {},
    },

    -- Mason-LSPconfig bridge
    {
        "williamboman/mason-lspconfig.nvim",
        dependencies = { "williamboman/mason.nvim" },
        config = function()
            require("mason-lspconfig").setup({
                ensure_installed = {
                    "basedpyright",     -- Python (preferred over pyright)
                    "rust_analyzer",    -- Rust
                    "lua_ls",           -- Lua
                    "bashls",           -- Bash
                    "yamlls",           -- YAML
                    "jsonls",           -- JSON
                    "html",             -- HTML
                    "cssls",            -- CSS
                    "taplo",            -- TOML
                    "marksman",         -- Markdown
                    "dockerls",         -- Dockerfiles
                    "lemminx",          -- XML
                    "sqls",             -- SQL
                    "cmake",            -- CMake
                    "gopls",            -- Go
                    "pylsp",            -- Python LSP (plugins enabled via python-lsp-ruff)
                    "nixd",             -- Nix
                },
                automatic_installation = true,
            })
        end,
    },

    -- Modern formatting with conform.nvim
    {
        "stevearc/conform.nvim",
        event = { "BufWritePre" },
        cmd = { "ConformInfo" },
        opts = {
            formatters_by_ft = {
                python = { "ruff_format" },
                rust = { "rustfmt" },
                lua = { "stylua" },
                sh = { "shfmt" },
                bash = { "shfmt" },
                zsh = { "shfmt" },
                javascript = { "prettier" },
                typescript = { "prettier" },
                json = { "prettier" },
                jsonc = { "prettier" },
                html = { "prettier" },
                css = { "prettier" },
                markdown = { "prettier" },
                yaml = { "yamlfmt" },
                nix = { "nixfmt" },
                sql = { "sqlfluff" },
                go = { "gofmt" },
            },
            default_format_opts = {
                lsp_format = "fallback",
            },
            format_on_save = {
                timeout_ms = 500,
                lsp_format = "fallback",
            },
        },
    },

    -- Modern linting with nvim-lint
    {
        "mfussenegger/nvim-lint",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            local lint = require("lint")

            lint.linters_by_ft = {
                python = { "ruff", "mypy" },
                lua = { "luacheck" },
                sh = { "shellcheck" },
                bash = { "shellcheck" },
                zsh = { "shellcheck" },
                yaml = { "yamllint" },
                nix = { "deadnix", "statix" },
                sql = { "sqlfluff" },
            }

            vim.keymap.set("n", "<leader>lt", function()
                lint.try_lint()
            end, { desc = "Trigger linting" })
        end,
    },

    -- LSP Configuration
    {
        "neovim/nvim-lspconfig",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = {
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
            "stevearc/conform.nvim",
            "hrsh7th/cmp-nvim-lsp", -- Completion capabilities
        },
        config = function()
            -- Suppress false deprecation warning until nvim-lspconfig v3.0.0 is released
            -- The new vim.lsp.config API is not ready yet in Neovim 0.11
            vim.deprecate = function() return end

            -- Defer lspconfig require to ensure it's loaded
            local ok, lspconfig = pcall(require, "lspconfig")
            if not ok then
                vim.notify("nvim-lspconfig not found", vim.log.levels.ERROR)
                return
            end

            -- Restore deprecation warnings after lspconfig is loaded
            vim.deprecate = nil

            -- Enhanced capabilities from nvim-cmp
            local capabilities = require("cmp_nvim_lsp").default_capabilities()

            -- Shared on_attach
            local on_attach = function(client, bufnr)
                -- Basic keymaps with descriptions
                local function opts(desc)
                    return { buffer = bufnr, desc = desc }
                end

                vim.keymap.set("n", "K", vim.lsp.buf.hover, opts("Hover documentation"))
                vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts("Go to definition"))
                vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts("Go to declaration"))
                vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts("Go to implementation"))
                vim.keymap.set("n", "go", vim.lsp.buf.type_definition, opts("Go to type definition"))
                vim.keymap.set("n", "gr", vim.lsp.buf.references, opts("Find references"))
                vim.keymap.set("n", "gs", vim.lsp.buf.signature_help, opts("Signature help"))
                vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts("Rename symbol"))
                vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts("Code action"))
                vim.keymap.set("n", "<leader>gf", function()
                    require("conform").format({ bufnr = bufnr })
                end, opts("Format buffer"))
                vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts("Previous diagnostic"))
                vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts("Next diagnostic"))
                vim.keymap.set("n", "<leader>ld", vim.diagnostic.open_float, opts("Line diagnostics"))
                vim.keymap.set("n", "<leader>ll", vim.diagnostic.setloclist, opts("Diagnostic list"))
            end

            -- Server configurations
            local servers = {
                -- Python: Uses basedpyright.json for configuration
                basedpyright = {},

                -- Rust: Uses rustfmt.toml for formatting
                rust_analyzer = {
                    settings = {
                        ["rust-analyzer"] = {
                            checkOnSave = {
                                command = "clippy", -- Enable clippy for better linting
                            },
                        },
                    },
                },

                -- Lua: Neovim-specific setup
                lua_ls = {
                    settings = {
                        Lua = {
                            runtime = { version = "LuaJIT" },
                            diagnostics = {
                                globals = { "vim" },
                            },
                            workspace = {
                                library = vim.api.nvim_get_runtime_file("", true),
                                checkThirdParty = false,
                            },
                            telemetry = { enable = false },
                        },
                    },
                },

                -- Other servers use default configs
                bashls = {},
                yamlls = {},
                jsonls = {},
                html = {},
                cssls = {},
                taplo = {},
                marksman = {},
                dockerls = {},
                lemminx = {},
                sqls = {},
                cmake = {},
                gopls = {},
                pylsp = {
                    settings = {
                        pylsp = {
                            plugins = {
                                pycodestyle = { enabled = false },
                                pyflakes = { enabled = false },
                                mccabe = { enabled = false },
                                ruff = { enabled = true },
                                ruff_autoimport = { enabled = true },
                            },
                        },
                    },
                },
                nixd = {},
            }

            -- Configure servers with lspconfig
            for server, config in pairs(servers) do
                config.capabilities = capabilities
                config.on_attach = on_attach
                lspconfig[server].setup(config)
            end
        end,
    },
}
