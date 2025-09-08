-- Title         : init.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/yazi/init.lua
-- ----------------------------------------------------------------------------
-- Yazi Lua configuration for advanced functionality

-- Starship integration - configured via shell-tools.nix
require("starship"):setup()

-- Enhanced file opening logic with security
function smart_open()
    local h = cx.active.current.hovered
    if h.cha.is_dir then
        ya.manager_emit("enter", {})
    else
        -- Security feature: Confirm before executing binaries
        if h.cha.is_exec and not h.cha.is_dir then
            local confirm = ya.input({
                title = "Execute binary file?",
                position = { "top-center", y = 3, w = 50 },
            })
            if confirm and (confirm:lower() == "y" or confirm:lower() == "yes") then
                ya.manager_emit("open", {})
            else
                ya.notify({
                    title = "Execution Cancelled",
                    content = "Binary execution aborted",
                    level = "info",
                    timeout = 2,
                })
            end
        else
            ya.manager_emit("open", {})
        end
    end
end

-- Smart paste with conflict resolution
function smart_paste()
    local tasks = cx.tasks
    if #tasks.items > 0 then
        ya.notify({
            title = "Tasks Running",
            content = "Wait for current operations to complete",
            level = "warn",
            timeout = 3,
        })
        return
    end
    ya.manager_emit("paste", {})
end

-- Quick bookmark function
function bookmark_jump(key)
    local bookmarks = {
        h = "~",
        c = "~/.config",
        d = "~/Downloads",
        D = "~/Documents",
        p = "~/Documents/99.Github",
        P = "~/Documents/99.Github/Parametric_Forge",
        n = "~/.config/nix",
        t = "/tmp",
    }

    local path = bookmarks[key]
    if path then
        ya.manager_emit("cd", { path })
    end
end

-- Git root navigation
function cd_git_root()
    local output, err = Command("git"):args({ "rev-parse", "--show-toplevel" }):output()
    if output and output.status.success then
        local git_root = output.stdout:gsub("%s+$", "")
        ya.manager_emit("cd", { git_root })
    else
        ya.notify({
            title = "Not in Git Repository",
            content = "Current directory is not within a git repository",
            level = "warn",
            timeout = 2,
        })
    end
end

-- Archive creation helper
function create_archive(type)
    local selected = cx.active.selected
    if #selected == 0 then
        selected = { cx.active.current.hovered }
    end

    local files = {}
    for _, file in ipairs(selected) do
        table.insert(files, file.name)
    end

    local name = ya.input({
        title = "Archive name:",
        position = { "top-center", y = 3, w = 40 },
    })

    if not name or name == "" then
        return
    end

    local cmd
    if type == "tar" then
        cmd = Command("tar"):args({ "-czf", name .. ".tar.gz" }):args(files)
    elseif type == "zip" then
        cmd = Command("zip"):args({ "-r", name .. ".zip" }):args(files)
    end

    local output = cmd:output()
    if output.status.success then
        ya.notify({
            title = "Archive Created",
            content = string.format("Created %s", name),
            level = "info",
            timeout = 2,
        })
    end
end

-- Custom linemode for git status
function Linemode:git()
    local h = self._tab.current.hovered
    if not h then
        return ui.Line({})
    end

    local output = Command("git"):args({ "status", "--porcelain", h.name }):output()
    if not output or not output.status.success then
        return ui.Line({})
    end

    local status = output.stdout:sub(1, 2)
    local color = "#f8f8f2" -- Dracula foreground (default)

    if status:match("M") then
        color = "#f1fa8c" -- Dracula yellow (modified)
    elseif status:match("A") then
        color = "#50fa7b" -- Dracula green (added)
    elseif status:match("D") then
        color = "#ff5555" -- Dracula red (deleted)
    elseif status:match("?") then
        color = "#bd93f9" -- Dracula purple (untracked)
    end

    return ui.Line({
        ui.Span(" " .. status .. " "):fg(color),
    })
end

-- Performance optimization for large directories
function setup_large_dir_handling()
    -- Performance optimization for large directories
    -- Note: ya.setup may not support these specific options
    -- This is preserved for future API compatibility
    if ya.setup then
        ya.setup({
            folder_skip = 300, -- Skip loading if folder has more than 300 items
            folder_limit = 1000, -- Hard limit for folder items
        })
    end
end

-- Safe file removal with confirmation
function safe_remove()
    local selected = cx.active.selected
    if #selected == 0 then
        selected = { cx.active.current.hovered }
    end

    local count = #selected
    local names = {}
    for i, file in ipairs(selected) do
        if i <= 3 then
            table.insert(names, file.name)
        elseif i == 4 then
            table.insert(names, "...")
            break
        end
    end

    local confirm = ya.input({
        title = string.format("Delete %d file(s)? (%s)", count, table.concat(names, ", ")),
        position = { "top-center", y = 3, w = 60 },
    })

    if confirm and confirm:lower() == "yes" then
        ya.manager_emit("remove", {})
        ya.notify({
            title = "Files Deleted",
            content = string.format("%d file(s) moved to trash", count),
            level = "info",
            timeout = 2,
        })
    end
end

-- Bulk rename safety check
function safe_bulk_rename()
    local selected = cx.active.selected
    if #selected == 0 then
        ya.notify({
            title = "No Selection",
            content = "Select files to bulk rename",
            level = "warn",
            timeout = 2,
        })
        return
    end

    ya.manager_emit("rename", { bulk = true })
end

-- Enhanced session sync for cross-instance operations
function sync_session()
    ya.manager_emit("plugin", { "session.yazi", args = "sync" })
    ya.notify({
        title = "Session Synced",
        content = "Yank buffer synchronized across instances",
        level = "info",
        timeout = 1,
    })
end

-- Enhanced plugin integrations
function enhanced_search()
    -- Leverage fazif for better search with fd/rg integration
    ya.manager_emit("plugin", { "fazif.yazi", args = "search" })
end

function quick_diff()
    -- Use the diff plugin for better git integration
    local selected = cx.active.selected
    if #selected == 2 then
        ya.manager_emit("plugin", { "diff.yazi", args = { selected[1].name, selected[2].name } })
    else
        ya.notify({
            title = "Diff Usage",
            content = "Select exactly 2 files to compare",
            level = "warn",
            timeout = 2,
        })
    end
end

function lazy_git_integration()
    -- Check if we're in a git repository before opening lazygit
    local output = Command("git"):args({ "rev-parse", "--is-inside-work-tree" }):output()
    if output and output.status.success then
        ya.manager_emit("plugin", { "lazygit.yazi" })
    else
        ya.notify({
            title = "Not a Git Repository",
            content = "Current directory is not within a git repository",
            level = "warn",
            timeout = 2,
        })
    end
end

function smart_sudo_operations()
    -- Provide context-aware sudo operations
    local h = cx.active.current.hovered
    if not h then
        return
    end

    if h.cha.is_dir then
        ya.manager_emit("plugin", { "sudo.yazi", args = "dir" })
    else
        ya.manager_emit("plugin", { "sudo.yazi", args = "file" })
    end
end

-- Initialize custom functionality
setup_large_dir_handling()

-- --- Ecosystem Integration -----------------------------------------------
-- Participate in Parametric Forge ecosystem state coordination

-- Write current directory for ecosystem coordination (XDG-compliant)
function notify_ecosystem_directory_change()
    local xdg_state = os.getenv("XDG_STATE_HOME") or os.getenv("HOME") .. "/.local/state"
    local ecosystem_dir = xdg_state .. "/ecosystem"

    -- Ensure ecosystem directory exists
    Command("sh"):arg("-c"):arg("mkdir -p '" .. ecosystem_dir .. "'"):spawn()

    -- Write current directory to XDG-compliant location
    Command("sh"):arg("-c"):arg("echo '" .. cx.active.current.cwd .. "' > '" .. ecosystem_dir .. "/yazi_cwd'"):spawn()

    -- Directory state saved to XDG location
end

-- Enhanced cd with ecosystem coordination
function ecosystem_cd(path)
    ya.manager_emit("cd", { path })
    -- Notify ecosystem after directory change
    ya.sleep(0.1, notify_ecosystem_directory_change)
end

-- Override default navigation to include ecosystem notifications
function Status:name()
    local h = cx.active.current.hovered
    if h then
        notify_ecosystem_directory_change() -- Notify on any navigation
    end
    return h and h.name or ""
end

-- --- Plugin Configurations ------------------------------------------------

-- Whoosh advanced bookmark manager configuration
require("whoosh"):setup({
    -- Configuration bookmarks (cannot be deleted through plugin) - matches your g-shortcuts
    bookmarks = {
        { tag = "Home", path = "~", key = "h" },
        { tag = "Config", path = "~/.config", key = "c" },
        { tag = "Downloads", path = "~/Downloads", key = "d" },
        { tag = "Documents", path = "~/Documents", key = "D" },
        { tag = "Projects", path = "~/Documents/99.Github", key = "p" },
        { tag = "Parametric Forge", path = "~/Documents/99.Github/Parametric_Forge", key = "P" },
        { tag = "Nix Config", path = "~/.config/nix", key = "n" },
        { tag = "Temp", path = "/tmp", key = "t" },
    },

    -- Notification and behavior settings
    jump_notify = false, -- Keep notifications minimal

    -- Path display optimization for macOS
    path_truncate_enabled = true,
    path_max_depth = 3,

    -- History settings for tab-based navigation
    history_size = 15, -- More history for development workflow

    -- Fuzzy search optimization
    fzf_path_truncate_enabled = true,
    fzf_path_max_depth = 4,

    -- Folder name truncation for better readability
    path_truncate_long_names_enabled = true,
    path_max_folder_name_length = 25, -- Slightly longer for macOS paths
    fzf_path_max_folder_name_length = 30,
})

-- UI/UX Refinement: Dynamic layout adjustment based on terminal width
function adjust_layout()
    local width = ya.term_size().cols
    if width < 80 then
        -- Minimal layout for narrow terminals
        ya.manager_emit("layout", { ratio = { 0, 1, 0 } })
    elseif width < 120 then
        -- Balanced layout for medium terminals
        ya.manager_emit("layout", { ratio = { 1, 4, 2 } })
    else
        -- Full layout for wide terminals
        ya.manager_emit("layout", { ratio = { 2, 5, 3 } })
    end
end
