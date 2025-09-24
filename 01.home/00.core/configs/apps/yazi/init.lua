-- Title         : init.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/yazi/init.lua
-- ----------------------------------------------------------------------------
-- Yazi Lua configuration for advanced functionality

-- Initialize installed plugins from package.toml
-- Only activate the most essential, practical plugins

local function safe_setup(name, opts)
    local ok, plugin = pcall(require, name)
    if not ok then
        ya.notify({
            title = "Plugin skipped",
            content = string.format("%s failed to load: %s", name, plugin),
            level = "warn",
            timeout = 3,
        })
        return false
    end

    local setup = plugin.setup
    if type(setup) ~= "function" then
        return false
    end

    local ok_setup, err = pcall(function()
        if opts ~= nil then
            setup(plugin, opts)
        else
            setup(plugin)
        end
    end)

    if not ok_setup then
        ya.notify({
            title = "Plugin setup failed",
            content = string.format("%s: %s", name, err),
            level = "error",
            timeout = 3,
        })
        return false
    end

    return true
end

-- Core UI/UX plugins
safe_setup("starship") -- Prompt integration (matches shell prompt)
safe_setup("git", {
    order = 1000, -- Show git status right after filename, before mtime (default is 1500)
}) -- Git status in file list (shows git changes inline)
safe_setup("system-clipboard") -- Synchronize yanks/cuts with the host clipboard
safe_setup("full-border", { -- Full border around Yazi (cleaner visual separation)
    type = ui.Border.ROUNDED,
})

-- macOS tagging support (requires: brew install tag)
safe_setup("mactag", {
    -- Keys used to add or remove tags
    keys = {
        r = "Red",
        o = "Orange",
        y = "Yellow",
        g = "Green",
        b = "Blue",
        p = "Purple",
    },
    -- Colors used to display tags
    colors = {
        Red = "#ee7b70",
        Orange = "#f5bd5c",
        Yellow = "#fbe764",
        Green = "#91fc87",
        Blue = "#5fa3f8",
        Purple = "#cb88f8",
    },
})

-- Recycle bin management (requires: trash-cli)
safe_setup("recycle-bin", {
    -- trash_dir will be auto-discovered from trash-cli
})

-- Whoosh bookmark manager - all frequently used directories
safe_setup("whoosh", {
    bookmarks = {
        -- Essential system directories
        { tag = "Home", path = "~", key = "h" },
        { tag = "Config", path = "~/.config", key = "c" },
        { tag = "Downloads", path = "~/Downloads", key = "d" },
        { tag = "Documents", path = "~/Documents", key = "D" },
        { tag = "Temp", path = "/tmp", key = "t" },
        { tag = "Applications", path = "/Applications", key = "a" },
        -- Project directories
        { tag = "Parametric Forge", path = "~/Documents/99.Github/Parametric_Forge", key = "f" },
        { tag = "Parametric Arsenal", path = "~/Documents/99.Github/Parametric_Arsenal", key = "A" },
        { tag = "Github Projects", path = "~/Documents/99.Github", key = "g" },
    },
    jump_notify = false, -- Keep it quiet
    path_truncate_enabled = true,
    path_max_depth = 3,
})
