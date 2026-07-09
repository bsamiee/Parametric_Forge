-- Title         : treesitter.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : modules/home/programs/apps/nvim/lua/plugins/treesitter.lua
-- ----------------------------------------------------------------------------
-- nvim-treesitter main: parsers arrive store-owned (one Nix compat unit with
-- the neovim pin); runtime installation is unspellable. Highlight/indent
-- start per buffer when the parser exists; folds ride config/options.lua.

vim.treesitter.language.register("json", "jsonc")

vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("forge_treesitter", { clear = true }),
    callback = function(ev)
        if pcall(vim.treesitter.start, ev.buf) then
            vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
    end,
})
