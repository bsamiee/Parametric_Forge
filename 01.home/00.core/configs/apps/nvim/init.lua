-- Title         : init.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/nvim/init.lua
-- ----------------------------------------------------------------------------
-- Neovim entry point

-- Load core configuration
require("config.options")
require("config.lazy") -- Plugin manager (loads before keymaps for plugin mappings)
require("config.keymaps")
require("config.autocmds")
