-- Title         : overseer.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : modules/home/programs/apps/nvim/lua/plugins/overseer.lua
-- ----------------------------------------------------------------------------
-- Task graph over mise/just/npm builtin providers with quickfix hooks; DAP
-- integration stays off until nvim-dap lands with an explicit adapter matrix.

require("overseer").setup({
    dap = false,
})
