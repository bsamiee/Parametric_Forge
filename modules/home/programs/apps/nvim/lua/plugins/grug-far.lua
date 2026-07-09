-- Title         : grug-far.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : modules/home/programs/apps/nvim/lua/plugins/grug-far.lua
-- ----------------------------------------------------------------------------
-- rg + ast-grep search/replace workbench; engines resolve the Forge-owned
-- global binaries. The replace-flag blacklist stays enabled (rg defaults).

require("grug-far").setup({
    engines = {
        ripgrep = { path = "rg" },
        astgrep = { path = "ast-grep" },
    },
})
