-- Title         : conform.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : modules/home/programs/apps/nvim/lua/plugins/conform.lua
-- ----------------------------------------------------------------------------
-- Formatter orchestration over Forge-owned global binaries; the per-filetype
-- table is a generated fact (forge/tools.lua). Availability rows feed
-- :checkhealth forge.

require("conform").setup({
    formatters_by_ft = require("forge.tools").format,
    -- Bare-name law: the builtin prettier definition prefers the repo's
    -- node_modules/.bin, executing a repo-owned binary on save; pin the
    -- per-user profile binary instead.
    formatters = {
        prettier = { command = "prettier" },
    },
    format_on_save = {
        timeout_ms = 1500,
        lsp_format = "fallback",
    },
})
