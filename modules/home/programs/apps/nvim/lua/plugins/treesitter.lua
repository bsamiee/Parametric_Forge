-- Title         : treesitter.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : modules/home/programs/apps/nvim/lua/plugins/treesitter.lua
-- ----------------------------------------------------------------------------
-- nvim-treesitter main: parsers arrive store-owned (one Nix compat unit with
-- the neovim pin); runtime installation is unspellable. Highlight/indent
-- start per buffer when the parser exists; folds ride config/options.lua.
-- Structural textobjects (main branch) bind as row tables over one applier;
-- buffers without a matching query degrade to no-ops.

vim.treesitter.language.register("json", "jsonc")

vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("forge_treesitter", { clear = true }),
    callback = function(ev)
        if pcall(vim.treesitter.start, ev.buf) then
            vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
    end,
})

require("nvim-treesitter-textobjects").setup({
    select = { lookahead = true },
})

local select_rows = {
    af = "@function.outer",
    ["if"] = "@function.inner",
    at = "@class.outer",
    it = "@class.inner",
    aa = "@parameter.outer",
    ia = "@parameter.inner",
}
for keys, query in pairs(select_rows) do
    vim.keymap.set({ "x", "o" }, keys, function()
        require("nvim-treesitter-textobjects.select").select_textobject(query, "textobjects")
    end, { desc = "Select " .. query })
end

-- ]t/[t over @class: builtin ]c/[c stays diff-change navigation.
local move_rows = {
    ["]f"] = { fn = "goto_next_start", query = "@function.outer", desc = "Next function start" },
    ["[f"] = { fn = "goto_previous_start", query = "@function.outer", desc = "Previous function start" },
    ["]t"] = { fn = "goto_next_start", query = "@class.outer", desc = "Next type start" },
    ["[t"] = { fn = "goto_previous_start", query = "@class.outer", desc = "Previous type start" },
    ["]a"] = { fn = "goto_next_start", query = "@parameter.inner", desc = "Next parameter" },
    ["[a"] = { fn = "goto_previous_start", query = "@parameter.inner", desc = "Previous parameter" },
}
for keys, row in pairs(move_rows) do
    vim.keymap.set({ "n", "x", "o" }, keys, function()
        require("nvim-treesitter-textobjects.move")[row.fn](row.query, "textobjects")
    end, { desc = row.desc })
end
