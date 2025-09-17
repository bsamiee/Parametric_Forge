-- Title         : tabs.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/wezterm/tabs.lua
-- ----------------------------------------------------------------------------
-- Tab formatting, status bar handling, and helper functions

-- luacheck: ignore 561 (cyclomatic complexity justified for UI formatting functions)

local wezterm = require("wezterm")

local M = {}

function M.setup(colors, icons, invisible, window_bg, host_bg)
    -- Helper Functions ─────────────────────────────────────────────────────────
    local git_cache = {}
    local git_cache_ttl_seconds = 5

    local function resolve_path(raw)
        if not raw or raw == "" then
            return nil
        end

        local path = raw
        if path:match("^~") then
            local home = os.getenv("HOME")
            if home then
                path = path:gsub("^~", home)
            end
        end

        if path:match("^%a+://") then
            return nil
        end

        return path
    end

    local function get_pane_cwd(pane)
        if not pane then
            return nil
        end

        local ok, cwd = pcall(function()
            return pane:get_current_working_dir()
        end)

        if ok and cwd and cwd ~= "" then
            return cwd
        end

        return nil
    end

    local function get_current_mode(window, pane)
        -- Get the active key table first
        local key_table = window:active_key_table()

        local modes = {
            -- Check for key table based modes first
            {
                condition = function()
                    return key_table == "search_mode"
                end,
                name = "SEARCH",
                color = colors.yellow,
            },
            {
                condition = function()
                    return key_table == "copy_mode"
                end,
                name = "COPY",
                color = colors.cyan,
            },
            {
                condition = function()
                    return key_table == "window_mode"
                end,
                name = "WINDOW",
                color = colors.pink,
            },
            {
                condition = function()
                    return key_table == "workspace_mode"
                end,
                name = "WORKSPACE",
                color = colors.orange,
            },
            -- Visual mode - only when NOT in copy mode
            {
                condition = function()
                    if key_table == "copy_mode" then
                        return false
                    end
                    local selection = window:get_selection_text_for_pane(pane)
                    return selection and selection ~= ""
                end,
                name = "VISUAL",
                color = colors.purple,
            },
        }

        -- Check modes in order
        for _, mode in ipairs(modes) do
            if mode.condition() then
                return mode.name, mode.color
            end
        end
        -- Check for alt screen but ignore for TUI applications that legitimately use it
        if pane:is_alt_screen_active() then
            local process = pane:get_foreground_process_name()
            if process then
                process = process:match("([^/\\]+)$") or process

                -- Applications that legitimately use alternate screen - don't show ALT
                local tui_apps = {
                    -- Editors & Text Processing
                    ["nvim"] = true,
                    ["vim"] = true,
                    ["emacs"] = true,
                    -- File Managers
                    ["yazi"] = true,
                    ["broot"] = true,
                    -- System Monitoring
                    ["bottom"] = true,
                    ["htop"] = true,
                    ["btop"] = true,
                    ["top"] = true,
                    ["bandwhich"] = true,
                    -- Git & Development TUI
                    ["lazygit"] = true,
                    ["bacon"] = true,
                    -- Media & Documentation
                    ["mpv"] = true,
                    ["w3m"] = true,
                    ["man"] = true,
                    ["less"] = true,
                    ["more"] = true,
                    ["glow"] = true,
                    -- Search & Navigation
                    ["fzf"] = true,
                    -- Development Tools
                    ["sqlite-interactive"] = true,
                }

                if not tui_apps[process] then
                    return "ALT", colors.blue
                end
            end
        end
        -- Check for other key tables (catch-all for custom modes)
        if key_table then
            -- Unknown key table - display it nicely
            return key_table:upper():gsub("_", " "), colors.pink
        end

        return "NORMAL", colors.green
    end

    --- Get process info for tab
    local function get_process_info(tab)
        local pane = tab.active_pane
        if not pane then
            return nil, nil
        end

        -- Try property first (works in some WezTerm versions)
        local process = pane.foreground_process_name
        if not process or process == "" then
            -- Fallback to method (if available)
            local ok, proc_name = pcall(function()
                return pane:get_foreground_process_name()
            end)
            if ok and proc_name then
                process = proc_name
            end
        end

        if not process or process == "" then
            return nil, nil
        end

        -- Extract basename and get icon
        process = process:match("([^/\\]+)$") or process
        local icon = icons.process[process]

        return process, icon
    end

    --- Simple git repository detection with caching
    local function is_git_repo(path)
        local resolved = resolve_path(path)
        if not resolved then
            return false
        end

        local now = os.time()
        local cache_entry = git_cache[resolved]
        if cache_entry and now < cache_entry.expires then
            return cache_entry.value
        end

        local ok, is_repo = pcall(function()
            local success = false
            local stdout = nil
            success, stdout = wezterm.run_child_process({ "git", "-C", resolved, "rev-parse", "--git-dir" })
            return success and stdout and stdout:match("%S") ~= nil
        end)

        if not ok then
            is_repo = false
        end

        git_cache[resolved] = {
            value = is_repo,
            expires = now + git_cache_ttl_seconds,
        }

        return is_repo
    end

    --- Extract path from URL or path string
    local function extract_path_from_uri(uri)
        if not uri then
            return nil
        end

        local path
        if type(uri) == "userdata" then
            -- URL object
            path = uri.file_path
        elseif type(uri) == "string" then
            -- String URL - handle both file:// and direct paths
            if uri:match("^file://") then
                path = uri:gsub("^file://[^/]*", "")
            else
                path = uri
            end
        else
            return nil
        end
        -- Decode URL encoding
        if path then
            path = path:gsub("%%(%x%x)", function(hex)
                return string.char(tonumber(hex, 16))
            end)
        end

        return path
    end

    --- Smart directory formatting with icons (for tabs)
    local function format_cwd(tab)
        local pane = tab.active_pane
        if not pane then
            return ""
        end

        local path = extract_path_from_uri(get_pane_cwd(pane))
        if not path then
            return ""
        end

        local home = os.getenv("HOME")
        if not home then
            return path:match("([^/]+)$") or path
        end
        -- Handle home directory - return empty for default state
        -- Check both with and without trailing slash
        if path == home or path == home .. "/" then
            return "" -- Return empty so tab shows just index
        end
        -- Replace home with ~
        path = path:gsub("^" .. home, "~")
        -- Check if we're at ~/ (home with tilde)
        if path == "~" or path == "~/" then
            return "" -- Return empty for home directory
        end
        -- Check for special directories and their icons
        local aliases = {
            ["~/Development"] = icons.directory.code,
            ["~/Documents"] = icons.directory.documents,
            ["~/Downloads"] = icons.directory.download,
            ["~/Desktop"] = icons.directory.desktop,
            ["~/.config"] = icons.directory.config,
            ["~/Code"] = icons.directory.code,
        }
        for dir, icon in pairs(aliases) do
            if path:find("^" .. dir) then
                -- Show icon + last directory component
                local last = path:match("([^/]+)$") or ""
                if last ~= "" and last ~= dir:match("([^/]+)$") then
                    return icon .. " " .. last
                else
                    return icon .. " " .. dir:match("([^/]+)$")
                end
            end
        end
        -- Check for git repos directly
        if is_git_repo(path) then
            -- Double-check we're not in a special directory that should have its own icon
            local in_special_dir = false
            for dir, _ in pairs(aliases) do
                if path:find("^" .. dir) then
                    in_special_dir = true
                    break
                end
            end

            if not in_special_dir then
                local repo_name = path:match("([^/]+)/?$") or path
                return icons.directory.git .. " " .. repo_name
            end
        end
        -- Default: show last path component for clean display
        local last = path:match("([^/]+)$") or path
        -- If the path is deep, show ... prefix
        local depth = select(2, path:gsub("/", ""))
        if depth > 2 then
            return "…/" .. last
        else
            return last
        end
    end

    --- Format current working directory for status bar
    local function format_status_cwd(pane)
        if not pane then
            return ""
        end

        local path = extract_path_from_uri(get_pane_cwd(pane))
        if not path or path == "" then
            return ""
        end

        local home = os.getenv("HOME")
        if not home then
            return path:match("([^/]+)$") or path
        end
        -- Replace home with ~
        path = path:gsub("^" .. home, "~")
        -- Path aliases for common directories - use our defined icons
        local aliases = {
            ["~/Development"] = icons.directory.code,
            ["~/Documents"] = icons.directory.documents,
            ["~/Downloads"] = icons.directory.download,
            ["~/Desktop"] = icons.directory.desktop,
            ["~/.config"] = icons.directory.config,
            ["~/Code"] = icons.directory.code,
        }
        -- Apply aliases first
        for full_path, icon in pairs(aliases) do
            if path == full_path then
                return icon
            elseif path:find("^" .. full_path .. "/") then
                local rest = path:sub(#full_path + 2)
                -- Just show the last component with the icon
                local last = rest:match("([^/]+)$") or rest
                return icon .. "/" .. last
            end
        end
        -- Check for git repos directly
        if is_git_repo(path) then
            local repo_name = path:match("([^/]+)/?$") or path
            return icons.directory.git .. " " .. repo_name
        end
        -- Show last component for most paths
        local last = path:match("([^/]+)$") or path
        return last
    end

    --- Get development environment indicators
    local function get_env_status(pane)
        if not pane then
            return nil
        end

        local envs = {}
        local ok, user_vars = pcall(function()
            return pane:get_user_vars()
        end)

        if not ok or not user_vars then
            return nil
        end

        -- Check for Nix shell
        if user_vars.WEZTERM_IN_NIX and user_vars.WEZTERM_IN_NIX ~= "" and user_vars.WEZTERM_IN_NIX ~= "0" then
            table.insert(envs, "[ NIX ]")
        end

        -- Check for Python venv
        if user_vars.WEZTERM_VENV and user_vars.WEZTERM_VENV ~= "" then
            table.insert(envs, "[ VENV ]")
        end

        -- Check for Node version
        if user_vars.WEZTERM_NODE and user_vars.WEZTERM_NODE ~= "" then
            table.insert(envs, "[ NODE ]")
        end

        if #envs > 0 then
            return table.concat(envs, " ")
        end
        return nil
    end

    -- Status Bar Handlers ──────────────────────────────────────────────────────
    --- Update left status (mode indicator)
    wezterm.on("update-status", function(window, pane)
        local mode_name, mode_color = get_current_mode(window, pane)

        window:set_left_status(wezterm.format({
            { Background = { Color = window_bg } },
            { Foreground = { Color = mode_color } },
            { Text = "  [" .. mode_name .. "]  " },
        }))
    end)

    --- Update right status (env, cwd, workspace, hostname)
    wezterm.on("update-right-status", function(window, pane)
        -- Safety check for valid pane
        if not pane or not pcall(function()
            return pane:pane_id()
        end) then
            return
        end

        --- Safely collect status bar information with fallbacks
        local function safe_get_status_info(win, p)
            local info = {}

            -- Development environment indicators (leftmost position)
            local env_status = get_env_status(p)
            if env_status then
                table.insert(info, env_status)
            end

            -- Current working directory with fallback
            local ok, cwd = pcall(format_status_cwd, p)
            if ok and cwd and cwd ~= "" then
                table.insert(info, cwd)
            end

            -- Workspace with error handling
            local workspace_ok, workspace = pcall(function()
                return win:active_workspace()
            end)
            workspace = workspace_ok and workspace or "default"
            -- Truncate long workspace names
            if #workspace > 12 then
                workspace = workspace:sub(1, 9) .. "..."
            end
            table.insert(info, icons.ui.workspace .. " " .. workspace)

            -- Hostname with fallback
            local hostname_ok, hostname = pcall(wezterm.hostname)
            hostname = hostname_ok and hostname or "localhost"
            local dot = hostname:find("[.]")
            if dot then
                hostname = hostname:sub(1, dot - 1)
            end
            table.insert(info, hostname)

            return info
        end

        local cells = safe_get_status_info(window, pane)
        -- Build status string
        local status_text = table.concat(cells, " | ")

        window:set_right_status(wezterm.format({
            { Background = { Color = window_bg } },
            { Foreground = { Color = colors.cyan } },
            { Text = "  " .. status_text .. "  " },
        }))
    end)

    --- Build tab title with content hierarchy: custom > process > cwd > index
    local function build_tab_title(tab)
        local index = tab.tab_index + 1
        local parts = { tostring(index) }

        -- Custom title takes priority
        if tab.tab_title and #tab.tab_title > 0 then
            table.insert(parts, tab.tab_title)
            return table.concat(parts, " • "), true
        end

        -- Process icon + name
        local process, icon = get_process_info(tab)
        if process and icon then
            table.insert(parts, icon .. " " .. process)
            return table.concat(parts, " • "), true
        end

        -- Directory context
        local cwd = format_cwd(tab)
        if cwd and cwd ~= "" then
            table.insert(parts, cwd)
            return table.concat(parts, " • "), true
        end

        -- Just index
        return parts[1], false
    end

    -- Tab Formatting ───────────────────────────────────────────────────────────
    wezterm.on("format-tab-title", function(tab, tabs, panes, config_obj, hover, max_width)
        -- Safety check for valid tab
        if not tab or not tab.active_pane then
            return "[" .. tostring(tab and tab.tab_index + 1 or "?") .. "]"
        end

        local pane = tab.active_pane
        local title, has_content = build_tab_title(tab)

        -- Check for zoomed state
        local is_zoomed = false
        for _, p in ipairs(tab.panes) do
            if p.is_zoomed then
                is_zoomed = true
                break
            end
        end

        -- Add zoom indicator if needed
        if is_zoomed then
            title = title .. " " .. icons.ui.zoom
        end
        -- Handle colors consistently
        local bg, fg

        if tab.is_active then
            bg = colors.cyan
            fg = colors.bg -- Use our defined background color for contrast
        elseif pane.domain_name and host_bg[pane.domain_name] then
            bg = host_bg[pane.domain_name]
            fg = colors.fg
        elseif hover then
            bg = colors.blue
            fg = colors.fg
        else
            -- Inactive tab
            bg = window_bg
            fg = colors.fg
        end

        return wezterm.format({
            { Background = { Color = bg } },
            { Foreground = { Color = fg } },
            { Text = " " .. title .. " " },
        })
    end)
end

return M
