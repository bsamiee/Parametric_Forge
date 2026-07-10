-- Title         : init.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : modules/home/programs/apps/nvim/init.lua
-- ----------------------------------------------------------------------------
-- Deterministic startup: options, chords, LSP rows, then plugin setup owners.
-- Plugins and forge/* fact modules arrive store-owned via Home Manager; no
-- runtime bootstrap exists.

require("config.options")
require("config.keymaps")
require("config.lsp")
require("plugins.colorscheme")
require("plugins.treesitter")
require("plugins.snacks")
require("plugins.gitsigns")
require("plugins.lualine")
require("plugins.conform")
require("plugins.lint")
require("plugins.grug-far")
require("plugins.render-markdown")
require("plugins.overseer")
require("plugins.trouble")
