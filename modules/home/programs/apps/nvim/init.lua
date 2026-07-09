-- Title         : init.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : modules/home/programs/apps/nvim/init.lua
-- ----------------------------------------------------------------------------
-- Deterministic startup: options, keymaps, then direct plugin setup. Plugins
-- arrive store-owned via Home Manager pack/hm; no runtime bootstrap exists.

require("config.options")
require("config.keymaps")
require("plugins.colorscheme")
require("plugins.snacks")
