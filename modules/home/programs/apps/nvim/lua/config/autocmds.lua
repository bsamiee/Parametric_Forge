-- Title         : autocmds.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/nvim/lua/config/autocmds.lua
-- ----------------------------------------------------------------------------
-- Automatic behaviors that enhance workflow without adding complexity

local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

-- General improvements
local general = augroup("General", { clear = true })

-- Live linting (requires nvim-lint plugin)
local linting = augroup("Linting", { clear = true })

autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
    group = linting,
    callback = function()
        local lint_ok, lint = pcall(require, "lint")
        if lint_ok then
            lint.try_lint()
        end
    end,
})
