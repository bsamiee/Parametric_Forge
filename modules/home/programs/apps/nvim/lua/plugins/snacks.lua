-- Title         : snacks.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : modules/home/programs/apps/nvim/lua/plugins/snacks.lua
-- ----------------------------------------------------------------------------
-- Snacks.nvim: the one rich editor surface. Terminal, explorer, and input stay off; Zellij owns terminals, Yazi owns file
-- navigation. The Forge action picker is the register-rail projection inside the editor: typed action rows arrive from forge/tools.lua;
-- scratch rows render into a float, pane rows hand off to a Zellij floating pane.

require("snacks").setup({
    bigfile = { enabled = true },
    dashboard = {
        enabled = true,
        preset = {
            keys = {
                { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
                { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
                { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
                { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
                {
                    icon = " ",
                    key = "c",
                    desc = "Config Files",
                    action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
                },
                { icon = " ", key = "q", desc = "Quit", action = ":qa" },
            },
            header = [[
                ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
                ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡏⣿⣿⢳⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢧⣿⡿⣸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
                ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠁⣿⡏⠸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠸⣿⡇⢹⣿⣿⣿⣿⣿⣿⣿⣿⢻⢿⣿⡿⣿⣿⡇⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
                ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠸⣇⠀⠹⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣯⠀⢻⡇⠈⢿⣿⣿⣿⣿⣿⣿⣿⣬⣬⣾⠃⣿⣿⠀⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
                ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣇⠀⠹⣆⠀⢹⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⢻⡄⠈⢿⣿⣿⣿⣿⣿⣿⡇⣿⣿⠀⢿⣿⡀⠈⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
                ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣆⠀⢹⡆⠀⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡀⠈⢷⡀⠈⢿⣿⣿⣿⣿⣿⠀⣿⣿⡀⠈⢿⣷⡀⠘⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
                ⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⣛⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣘⣉⣸⣿⣿⡄⠀⢿⡄⠀⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢻⢛⣿⣿⣷⡀⠈⣷⡀⠘⣿⣿⣿⣿⣿⠀⠘⣿⣷⡀⠈⢿⣷⠀⠘⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
                ⣿⣿⣿⣿⣿⣿⣿⣿⡏⣾⡿⠛⠛⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡀⠘⣷⡀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⣫⣭⣽⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣶⣿⣿⣿⣧⠀⢹⣧⠀⢹⣿⣿⣿⣿⣧⠀⠘⣿⣷⡀⠈⢿⣧⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢻⣿⣿⣿⣿
                ⣿⣿⣿⣿⣿⣿⣿⣿⣧⠙⢀⣤⣤⡀⢹⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⢿⣿⣿⣿⣧⠀⣿⣇⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡏⡾⠟⠋⠙⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⢿⣿⣿⣿⡆⠈⣿⡆⢸⣿⣿⣿⠿⣿⣧⠀⠹⣿⣷⠀⠘⣿⡆⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠸⣿⣿⣿⣿
                ⣿⣿⣿⣿⣿⣿⣿⣿⡏⢀⠀⠈⠉⠀⢸⣿⣿⡿⠟⢿⣿⣿⣿⣿⡿⠛⠉⠉⠉⠛⠛⠿⢿⣿⣿⣿⣿⣿⠀⠀⠙⣿⣿⣿⠀⣿⣿⠰⢿⣿⣿⣿⡏⢻⣿⣿⣿⣿⣿⡿⠀⠠⣴⣦⡀⠈⣿⣿⣿⠿⠛⠉⠉⠛⠛⠻⠿⣿⣿⣿⣿⣿⡏⠀⠀⢻⣿⣿⣷⠀⣿⡇⣸⣿⡟⠁⡀⣸⣿⣇⠀⢻⣿⣇⠀⢻⣿⠀⡙⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠿⠿⠿⣷⡀⢻⣿⣿⣿
                ⣿⣿⡟⠙⠿⠿⠿⠟⠁⣾⣿⣷⡆⠘⠛⠛⠉⢀⣀⢠⣿⣿⣿⢋⣠⣤⣤⣤⣤⣄⡀⠀⠀⠈⠉⠙⠛⠛⠳⢄⠀⠻⠿⠛⠁⢟⡅⣾⣆⣿⣿⣿⣅⠀⠻⠿⣿⠿⠋⣰⣄⠀⠀⠉⠁⣰⣿⡟⢁⣠⣤⣤⣤⣤⣀⡀⠀⠀⠈⠉⠛⠛⠛⠷⡀⠀⠿⠿⠋⢰⣿⢧⣿⠏⣠⣾⡇⣿⣿⣿⡄⠈⢿⣿⠀⢸⣿⠀⣿⢸⠟⠉⠙⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠛⠋⠁⠀⢀⣀⣀⡀⢹⣧⠀⢿⣿⣿
                ⣿⣿⣿⣦⣄⣀⣀⣠⣼⣿⣿⣿⣧⣄⣠⣴⠾⣿⣇⠘⠿⣿⣿⣿⡿⠿⠿⠟⠛⠋⠁⠀⣀⣀⣀⣠⣀⣀⣰⡿⠀⣤⣤⣴⢣⢟⣾⡿⠋⠙⠻⣿⣿⡄⢀⣀⣀⣠⣴⣿⣿⣿⣶⡆⠰⢿⣿⣴⣿⣿⠿⠿⠟⠛⠋⠁⠀⣀⣀⣀⣀⣀⣀⣼⡟⢠⣤⣤⣶⣿⢫⣿⠏⣰⣿⣿⡀⣿⣿⣿⣷⠀⡀⠀⢀⣾⡿⣼⡟⠀⢠⣤⡀⠈⠻⣿⣿⣿⣿⣿⣿⣿⠿⠟⠋⠉⠀⣀⣠⣴⣶⣿⣿⣿⣿⣿⢸⣿⠆⣾⣿⣿
                ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣄⠀⣠⣿⣄⠀⠀⠀⠀⠀⠀⢀⣀⣠⣴⣾⣿⣿⣿⣿⣿⣿⡿⠋⢀⣼⣿⣿⡏⣡⣾⣿⣿⣦⣤⣾⣿⡿⢃⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⢀⣀⣤⣴⣾⣿⣿⣿⣿⣿⣿⠿⠋⢠⣾⣿⣿⣿⣱⠟⢃⣴⣿⣿⣿⣇⠈⠉⠉⠁⢠⣿⣿⣿⠟⣽⠟⢰⡀⠀⠈⠁⢠⣄⡀⠉⠉⠉⠉⠁⠀⣀⣠⣤⣶⣿⣿⣿⣿⣿⡋⠀⢙⣿⠏⠈⢁⣴⣿⣿⣿
                ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡋⠀⠉⣻⣿⣿⣿⣿⣿⣿⣿⣷⣽⣻⠿⢿⣿⣿⠿⠟⠋⠁⣀⣴⣿⣿⣿⣿⡇⠹⣿⣿⣿⣿⡿⠟⠋⢀⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣮⣟⡿⠿⣿⣿⣿⠿⠟⠋⠁⣠⣴⣿⣿⣿⣿⣿⣶⣾⣿⣿⣿⣿⣿⣿⣷⣶⣶⡘⠿⠿⠿⠏⠞⢁⣠⣿⣿⣷⣶⣤⣾⣿⣿⣿⣶⣶⣶⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣿⣿⣦⣶⣿⣿⣿⣿⣿
                ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣦⣤⣀⣤⣶⣾⣿⣿⣿⣿⣿⣿⣷⡀⠀⠈⠁⠀⠀⣠⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣤⣀⣀⣤⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣶⣶⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
                ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣶⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
                ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
            ]],
        },
        formats = {
            key = function(item)
                return { { "[", hl = "special" }, { item.key, hl = "key" }, { "]", hl = "special" } }
            end,
        },
        sections = {
            { section = "header" },
            { title = "[QUICK ACTIONS]", padding = 1 },
            { section = "keys", padding = 1 },
            { title = "[RECENT FILES]", padding = 1 },
            -- No lazy.nvim on this rail: the "startup" section requires lazy.stats and faults at UIEnter; recent_files closes the board.
            { section = "recent_files", indent = 1, padding = 2, limit = 8 },
        },
    },
    indent = { enabled = true },
    picker = { enabled = true },
    notifier = { enabled = true },
    quickfile = { enabled = true },
    scope = { enabled = true },
    statuscolumn = { enabled = true },
    words = { enabled = true },
    zen = {
        -- Every id resolves to a registered toggle: dim/diagnostics/line_number/indent are Snacks factories; signcolumn is the option toggle below.
        toggles = {
            dim = true,
            diagnostics = false,
            line_number = false,
            signcolumn = false,
            indent = false,
        },
    },
})

-- Zen consumes this by id; false projects "no", state restores on close.
Snacks.toggle.option("signcolumn", { on = "yes", off = "no", name = "Sign Column" })

-- ----------------------------------------------------------------------------
-- [FORGE_PICKER]
-- Chords live in apps/chords.nix (fn = "pick_forge"); rows are generated facts. Buffer-lifecycle chords ride the same owner — no keymaps here.
local M = {}
local tools = require("forge.tools")

local function scratch_show(row, out)
    local text = out.stdout or ""
    if out.stderr and out.stderr ~= "" then
        text = text .. "\n" .. out.stderr
    end
    vim.schedule(function()
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(text, "\n"))
        vim.bo[buf].filetype = row.ft or "text"
        vim.bo[buf].modifiable = false
        Snacks.win({
            buf = buf,
            width = 0.85,
            height = 0.85,
            border = "rounded",
            title = " " .. row.label .. " ",
            wo = { wrap = false },
        })
    end)
end

local function run(row)
    if row.mode == "pane" then
        if not vim.env.ZELLIJ then
            vim.notify(("forge action %q needs a zellij session"):format(row.id), vim.log.levels.WARN)
            return
        end
        -- No --close-on-exit: non-interactive rows must keep their output visible after exit; zellij's pending-close banner owns dismissal.
        local argv = { "zellij", "run", "--floating", "--name", row.id }
        if row.cwd then
            vim.list_extend(argv, { "--cwd", row.cwd })
        end
        table.insert(argv, "--")
        vim.list_extend(argv, row.argv)
        vim.system(argv)
        return
    end
    -- vim.system throws on a missing executable; the error lands as a notification instead of a stack trace in the picker confirm.
    local ok, err = pcall(vim.system, row.argv, { cwd = row.cwd, text = true }, function(out)
        scratch_show(row, out)
    end)
    if not ok then
        vim.notify(("forge action %q: %s"):format(row.id, err), vim.log.levels.ERROR)
    end
end

function M.pick_forge()
    local items = {}
    for idx, row in ipairs(tools.actions) do
        items[#items + 1] = { idx = idx, text = row.label, row = row }
    end
    Snacks.picker({
        title = "Forge Actions",
        items = items,
        format = "text",
        layout = { preset = "select" },
        confirm = function(picker, item)
            picker:close()
            if item then
                run(item.row)
            end
        end,
    })
end

return M
