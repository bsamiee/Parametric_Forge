-- Title         : lazy.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/nvim/lua/config/lazy.lua
-- ----------------------------------------------------------------------------
-- Plugin management foundation with lazy.nvim

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "--branch=stable",
        lazyrepo,
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

-- Configure lazy.nvim
require("lazy").setup({
    spec = {
        { import = "plugins" }, -- Load plugin specs from lua/plugins/
    },
    defaults = {
        lazy = false, -- Don't lazy-load by default
        version = false, -- Use latest commits, not releases
    },
    install = {
        missing = true, -- Auto-install missing plugins on startup
    },
    checker = {
        enabled = false, -- Don't auto-check for updates (manual control preferred)
    },
    change_detection = {
        enabled = true, -- Auto-reload on config change
        notify = false, -- Quiet reloads
    },
    performance = {
        rtp = {
            disabled_plugins = {
                "gzip",
                "matchit",
                "matchparen",
                "netrwPlugin",
                "tarPlugin",
                "tohtml",
                "tutor",
                "zipPlugin",
            },
        },
    },
    ui = {
        border = "rounded",
        backdrop = 50,
    },
})
