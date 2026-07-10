-- Title         : conform.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : modules/home/programs/apps/nvim/lua/plugins/conform.lua
-- ----------------------------------------------------------------------------
-- Formatter orchestration over Forge-owned global binaries; the per-filetype table is a generated fact (forge/tools.lua). Availability rows feed
-- :checkhealth forge.

require("conform").setup({
    formatters_by_ft = require("forge.tools").format,
    -- Bare-name law: the builtin prettier def prefers the repo's node_modules/.bin (a repo-owned binary runs on save) and the builtin csharpier
    -- probes cwd-dependent, session-cached `dotnet csharpier`; pin the profile binaries the estate fmt router's lanes own.
    formatters = {
        prettier = { command = "prettier" },
        csharpier = { command = "csharpier", args = { "format" } },
    },
    format_on_save = {
        timeout_ms = 1500,
        lsp_format = "fallback",
    },
})
