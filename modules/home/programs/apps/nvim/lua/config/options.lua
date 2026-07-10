-- Title         : options.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : modules/home/programs/apps/nvim/lua/config/options.lua
-- ----------------------------------------------------------------------------
-- Core Neovim options - the foundation of editor behavior

local opt = vim.opt

-- LEADER ---------------------------------------------------------------------
vim.g.mapleader = " "

-- PROVIDERS ------------------------------------------------------------------
-- Python rides the uv tool lane (generated fact); the rest are owned-off rows.
vim.g.python3_host_prog = require("forge.tools").provider.python3
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_node_provider = 0

-- UI/DISPLAY -----------------------------------------------------------------
opt.termguicolors = true
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.wrap = false
opt.linebreak = true
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
opt.fillchars = { eob = " " }
opt.showmode = false
opt.cmdheight = 2
opt.laststatus = 3
opt.colorcolumn = "150"
-- One border owner for every float that names none (hover, signature, diagnostics); surfaces passing an explicit border keep their own.
opt.winborder = "rounded"

-- EDITING --------------------------------------------------------------------
opt.undofile = true -- persistent undo: history survives sessions under the state dir
opt.clipboard = vim.env.SSH_TTY and "" or "unnamedplus"
opt.mouse = "a"
opt.virtualedit = "block"
opt.inccommand = "split"
opt.completeopt = { "menu", "menuone", "noselect" }
opt.pumheight = 10
opt.pumblend = 10

-- INDENTATION ----------------------------------------------------------------
opt.expandtab = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.shiftround = true
opt.smartindent = true
opt.breakindent = true

-- FOLDING --------------------------------------------------------------------
-- Native Tree-sitter fold rail; buffers without a parser stay unfolded.
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldtext = ""
opt.foldlevel = 99
opt.foldlevelstart = 99

-- FEEDBACK -------------------------------------------------------------------
-- Yank flash through the host highlighter (no default autocmd ships).
vim.api.nvim_create_autocmd("TextYankPost", {
    group = vim.api.nvim_create_augroup("forge_yank", { clear = true }),
    callback = function()
        vim.hl.on_yank()
    end,
})
