-- Title         : options.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/nvim/lua/config/options.lua
-- ----------------------------------------------------------------------------
-- Core Neovim options - the foundation of editor behavior

local opt = vim.opt


-- LEADER ---------------------------------------------------------------------
vim.g.mapleader = " "

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
opt.colorcolumn = "120"

-- EDITING --------------------------------------------------------------------
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
