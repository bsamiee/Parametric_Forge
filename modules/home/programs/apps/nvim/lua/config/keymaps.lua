-- Title         : keymaps.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : modules/home/programs/apps/nvim/lua/config/keymaps.lua
-- ----------------------------------------------------------------------------
-- Chord binder: motion primitives stay native rows here; every domain chord
-- is a generated forge/chords.lua row (owner: apps/chords.nix). `fn` rows
-- resolve through the dispatch table: explicit verbs, then the picker
-- grammar; ids outside both fault at startup.

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
map("n", "]h", function()
    require("gitsigns").nav_hunk("next")
end, { desc = "Next git hunk" })
map("n", "[h", function()
    require("gitsigns").nav_hunk("prev")
end, { desc = "Previous git hunk" })
map({ "o", "x" }, "ih", function()
    require("gitsigns").select_hunk()
end, { desc = "Inner git hunk" })

-- QUIT/SAVE/CLEAR ------------------------------------------------------------
map("n", "<leader>q", "<cmd>qa<cr>", { desc = "Quit all" })
map("n", "<leader>w", "<cmd>w<cr>", { desc = "Save file" })
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

-- DOMAIN CHORD DISPATCH ------------------------------------------------------
-- Action identity lives in the chord row; this table owns the callbacks.
-- Picker actions derive from the fn grammar (pick_<source>, lsp_<source>)
-- over one factory, so a new picker chord is one chords.nix row with zero
-- edits here; explicit rows own the non-picker verbs and grammar overrides.
-- Closures defer Snacks resolution to press time (the global lands at
-- setup); Snacks.picker returns nil for an unregistered source, so a bad
-- source name faults typed at press while ungrammatical ids fault at bind.
local pick = function(source)
    return function()
        local open = Snacks.picker[source]
        if not open then
            vim.notify(("forge.chords: unknown picker source %q"):format(source), vim.log.levels.ERROR)
            return
        end
        open()
    end
end

local actions = setmetatable({
    pick_estate = function()
        require("plugins.snacks").pick_estate()
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
}, {
    __index = function(_, fn)
        if type(fn) ~= "string" then
            return nil
        end
        local source = fn:match("^pick_(.+)$") or (fn:find("^lsp_") and fn or nil)
        return source and pick(source) or nil
    end,
})

for _, row in ipairs(require("forge.chords")) do
    local rhs = row.action or actions[row.fn]
    if not rhs then
        vim.notify(("forge.chords: unknown dispatch id %q"):format(tostring(row.fn)), vim.log.levels.ERROR)
    else
        map(row.mode, row.keys, rhs, { desc = row.desc })
    end
end
