-- Title         : conform.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : modules/home/programs/apps/nvim/lua/plugins/conform.lua
-- ----------------------------------------------------------------------------
-- Formatter orchestration over Forge-owned binaries; per-filetype table is generated (estate/tools.lua); availability rows feed :checkhealth estate.

require("conform").setup({
    formatters_by_ft = require("estate.tools").format,
    -- Bare-name law: the builtin prettier def prefers the repo's node_modules/.bin (a repo-owned binary runs on save); pin the profile binary
    -- node-tools.nix installs. C# has no lane here either: `dotnet format` owns .cs through the project rails.
    formatters = {
        prettier = { command = "prettier" },
    },
    -- LSP fallback sits in the defaults so a filetype row's lsp_format (TOML: never) outranks it.
    default_format_opts = {
        lsp_format = "fallback",
    },
    format_on_save = {
        timeout_ms = 1500,
    },
})
