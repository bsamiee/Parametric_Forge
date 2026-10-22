-- Title         : lualine.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : modules/home/programs/apps/nvim/lua/plugins/lualine.lua
-- ----------------------------------------------------------------------------
-- Statusline over the generated Forge palette (showmode=false decided a statusline mode indicator; default shows none). Theme rows derive from one
-- mode->hue table; git facts from gitsigns buffer state — no second git engine. globalstatus derives from laststatus=3 (owner: config/options.lua).

local p = require("forge.palette")
local git = require("forge.syntax").roles.git

local mode = function(hue)
    return {
        a = { bg = hue, fg = p.crust, gui = "bold" },
        b = { bg = p.overlay, fg = p.foreground },
        c = { bg = p.surface, fg = p.comment },
    }
end

require("lualine").setup({
    options = {
        theme = {
            normal = mode(p.cyan),
            insert = mode(p.green),
            visual = mode(p.purple),
            replace = mode(p.red),
            command = mode(p.amber),
            terminal = mode(p.orange),
            inactive = mode(p.selection),
        },
        icons_enabled = false, -- render-markdown.lua names the icon-provider law.
        component_separators = "│",
        section_separators = "",
    },
    sections = {
        lualine_b = {
            "b:gitsigns_head",
            {
                "diff",
                -- Count hues ride the owner git-state vocabulary, not lualine's defaults.
                diff_color = {
                    added = { fg = git.added.color },
                    modified = { fg = git.modified.color },
                    removed = { fg = git.deleted.color },
                },
                source = function()
                    return vim.b.gitsigns_status_dict
                end,
            },
            "diagnostics",
        },
        lualine_c = { { "filename", path = 1 } },
        lualine_x = { "lsp_status", "filetype" },
    },
})
