-- Title         : keymaps.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : modules/home/programs/apps/nvim/lua/config/keymaps.lua
-- ----------------------------------------------------------------------------
-- Chord binder: motion primitives stay native rows here; every domain chord
-- is a generated forge/chords.lua row (owner: apps/chords.nix). `fn` rows
-- resolve through the dispatch table; unknown ids fault at startup.

local map = vim.keymap.set

-- WINDOW NAVIGATION ----------------------------------------------------------
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

-- MOTION PRIMITIVES ----------------------------------------------------------
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true, desc = "Down by display line" })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true, desc = "Up by display line" })
map("n", "<C-d>", "<C-d>zz", { desc = "Scroll down and center" })
map("n", "<C-u>", "<C-u>zz", { desc = "Scroll up and center" })
map("n", "n", "nzzzv", { desc = "Next search result and center" })
map("n", "N", "Nzzzv", { desc = "Previous search result and center" })

-- QUIT/SAVE/CLEAR ------------------------------------------------------------
map("n", "<leader>q", "<cmd>qa<cr>", { desc = "Quit all" })
map("n", "<leader>w", "<cmd>w<cr>", { desc = "Save file" })
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

-- DOMAIN CHORD DISPATCH ------------------------------------------------------
-- Action identity lives in the chord row; this table owns the callbacks.
local actions = {
    pick_files = function()
        Snacks.picker.files()
    end,
    pick_recent = function()
        Snacks.picker.recent()
    end,
    pick_buffers = function()
        Snacks.picker.buffers()
    end,
    pick_grep = function()
        Snacks.picker.grep()
    end,
    pick_grep_word = function()
        Snacks.picker.grep_word()
    end,
    pick_resume = function()
        Snacks.picker.resume()
    end,
    pick_help = function()
        Snacks.picker.help()
    end,
    pick_keymaps = function()
        Snacks.picker.keymaps()
    end,
    pick_estate = function()
        require("plugins.snacks").pick_estate()
    end,
    lsp_definitions = function()
        Snacks.picker.lsp_definitions()
    end,
    lsp_references = function()
        Snacks.picker.lsp_references()
    end,
    lsp_implementations = function()
        Snacks.picker.lsp_implementations()
    end,
    lsp_type_definitions = function()
        Snacks.picker.lsp_type_definitions()
    end,
    lsp_symbols = function()
        Snacks.picker.lsp_symbols()
    end,
    lsp_workspace_symbols = function()
        Snacks.picker.lsp_workspace_symbols()
    end,
    lsp_rename = function()
        vim.lsp.buf.rename()
    end,
    code_action = function()
        vim.lsp.buf.code_action()
    end,
    format = function()
        require("conform").format({ async = true, lsp_format = "fallback" })
    end,
    grug_open = function()
        require("grug-far").open()
    end,
    grug_word = function()
        require("grug-far").open({ prefills = { search = vim.fn.expand("<cword>") } })
    end,
    git_blame_line = function()
        Snacks.git.blame_line()
    end,
    git_browse = function()
        Snacks.gitbrowse()
    end,
    bufdelete = function()
        Snacks.bufdelete()
    end,
    bufdelete_all = function()
        Snacks.bufdelete.all()
    end,
    bufdelete_other = function()
        Snacks.bufdelete.other()
    end,
    zen = function()
        Snacks.zen()
    end,
}

for _, row in ipairs(require("forge.chords")) do
    local rhs = row.action or actions[row.fn]
    if not rhs then
        vim.notify(("forge.chords: unknown dispatch id %q"):format(tostring(row.fn)), vim.log.levels.ERROR)
    else
        map(row.mode, row.keys, rhs, { desc = row.desc })
    end
end
