-- Title         : keymaps.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/nvim/lua/config/keymaps.lua
-- ----------------------------------------------------------------------------
-- Core key mappings - foundation before plugins

local map = vim.keymap.set

-- BUFFER NAVIGATION ---------------------------------------------------------
map("n", "<A-w>", "<cmd>bdelete<cr>", { desc = "Delete buffer" })
map("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Delete buffer" })
map("n", "<leader>bn", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "<leader>bp", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
map("n", "<leader>bb", "<cmd>e #<cr>", { desc = "Switch to other buffer" })
map("n", "<leader>ba", "<cmd>bufdo bd<cr>", { desc = "Delete all buffers" })

-- WINDOW NAVIGATION ----------------------------------------------------------
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

-- BETTER MOVEMENT ------------------------------------------------------------
map({ "n", "v" }, "j", "gj", { desc = "Move down by display line" })
map({ "n", "v" }, "k", "gk", { desc = "Move up by display line" })
map("n", "<C-d>", "<C-d>zz", { desc = "Scroll down and center" })
map("n", "<C-u>", "<C-u>zz", { desc = "Scroll up and center" })
map("n", "n", "nzzzv", { desc = "Next search result and center" })
map("n", "N", "Nzzzv", { desc = "Previous search result and center" })

-- QUIT/SAVE -----------------------------------------------------------------
map("n", "<leader>q", "<cmd>qa<cr>", { desc = "Quit all" })
map("n", "<leader>w", "<cmd>w<cr>", { desc = "Save file" })

-- CLEAR SEARCH HIGHLIGHT ----------------------------------------------------
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })
