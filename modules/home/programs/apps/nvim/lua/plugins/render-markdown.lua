-- Title         : render-markdown.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : modules/home/programs/apps/nvim/lua/plugins/render-markdown.lua
-- ----------------------------------------------------------------------------
-- In-buffer agent-doc rendering (Markdown, checklists, tables, callouts,
-- injections). Icon providers stay default: mini.icons rides only if a Mini
-- module lands with its own estate reason.

require("render-markdown").setup({
    completions = { lsp = { enabled = true } },
})
