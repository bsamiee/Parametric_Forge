-- Title         : snacks.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : modules/home/programs/apps/nvim/lua/plugins/snacks.lua
-- ----------------------------------------------------------------------------
-- Snacks.nvim plugin collection configuration

return {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    init = function()
        vim.api.nvim_create_autocmd("User", {
        pattern = "OilActionsPost",
        callback = function(event)
            if event.data.actions.type == "move" then
            Snacks.rename.on_rename_file(event.data.actions.src_url, event.data.actions.dest_url)
            end
        end,
        })
    end,
    keys = {
        { "<leader>bd", function() Snacks.bufdelete() end,       desc = "Buffer delete",       mode = "n" },
        { "<leader>ba", function() Snacks.bufdelete.all() end,   desc = "Buffer delete all",   mode = "n" },
        { "<leader>bo", function() Snacks.bufdelete.other() end, desc = "Buffer delete other", mode = "n" },
        { "<leader>bz", function() Snacks.zen() end,             desc = "Toggle Zen Mode",     mode = "n" },
    },
    opts = {
        bigfile = { enabled = true },
        dashboard = {
        preset = {
            pick = nil,
            keys = {
                { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
                { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
                { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
                { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
                { icon = " ", key = "c", desc = "Config", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
                { icon = " ", key = "s", desc = "Restore Session", section = "session" },
                { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy", enabled = package.loaded.lazy ~= nil },
                { icon = " ", key = "q", desc = "Quit", action = ":qa" },
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
            { section = 'header' },
            { title = "[QUICK ACTIONS]", padding = 1 },
            { section = "keys", padding = 1 },
            { title = "[RECENT FILES]", padding = 1 },
            { section = 'recent_files', indent = 1, padding = 2, limit = 8 },
            { section = "startup" },
        },
        },
        explorer = { enabled = false },
        indent = { enabled = true },
        input = { enabled = false },
        picker = { enabled = true },
        notifier = { enabled = true },
        quickfile = { enabled = true },
        scope = { enabled = true },
        statuscolumn = { enabled = true },
        words = { enabled = true },
        rename = { enabled = true },
        zen = {
            enabled = true,
            toggles = {
                ufo             = true,
                dim             = true,
                git_signs       = false,
                diagnostics     = false,
                line_number     = false,
                relative_number = false,
                signcolumn      = "no",
                indent          = false
            }
        },
    },
    config = function(_, opts)
        require("snacks").setup(opts)

        Snacks.toggle.new({
        id = "ufo",
        name = "Enable/Disable ufo",
        get = function()
            return require("ufo").inspect()
        end,
        set = function(state)
            if state == nil then
            require("noice").enable()
            require("ufo").enable()
            vim.o.foldenable = true
            vim.o.foldcolumn = "1"
            else
            require("noice").disable()
            require("ufo").disable()
            vim.o.foldenable = false
            vim.o.foldcolumn = "0"
            end
        end,
        })
    end
}
