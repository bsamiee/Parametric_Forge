-- Title         : keys.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/wezterm/keys.lua
-- ----------------------------------------------------------------------------
-- Key bindings, key tables, and leader configuration

local wezterm = require("wezterm")

local M = {}

local function build_spawn_actions(config, act)
    local default_cwd = config.default_cwd
    if not default_cwd or default_cwd == "" then
        default_cwd = os.getenv("WEZTERM_FRESH_CWD") or wezterm.home_dir
    end

    local default_prog = config.default_prog
    if not default_prog or #default_prog == 0 then
        local shell = os.getenv("SHELL")
        if shell and shell ~= "" then
            default_prog = { shell, "-l" }
        else
            default_prog = { "/bin/sh" }
        end
    end

    local function is_local(pane)
        local domain = pane and pane:get_domain_name()
        return not domain or domain == "" or domain == "local" or domain == "DefaultDomain"
    end

    local function tab_action()
        return wezterm.action_callback(function(window, pane)
            if not pane then
                return
            end

            if is_local(pane) then
                window:perform_action(
                    act.SpawnCommandInNewTab({ args = default_prog, cwd = default_cwd }),
                    pane
                )
                return
            end

            local domain = pane:get_domain_name()
            if domain and domain ~= "" then
                window:perform_action(act.SpawnTab({ DomainName = domain }), pane)
            else
                window:perform_action(act.SpawnTab("CurrentPaneDomain"), pane)
            end
        end)
    end

    local function split_action(direction)
        return wezterm.action_callback(function(window, pane)
            if not pane then
                return
            end

            local opts = {
                direction = direction,
                size = { Percent = 50 },
                domain = "CurrentPaneDomain",
            }

            if is_local(pane) then
                opts.command = { args = default_prog, cwd = default_cwd }
            end

            window:perform_action(act.SplitPane(opts), pane)
        end)
    end

    return {
        tab = tab_action(),
        split_right = split_action("Right"),
        split_down = split_action("Down"),
    }
end


-- Helper function for smart-splits.nvim integration
-- Detects if the current pane is running Neovim
local function is_vim(pane)
    -- This is set by the smart-splits.nvim plugin
    return pane:get_user_vars().IS_NVIM == "true"
end

-- Smart navigation between WezTerm panes and Neovim splits
local function smart_split_nav(resize_or_move, key)
    local direction_keys = {
        h = "Left",
        j = "Down",
        k = "Up",
        l = "Right",
    }

    return {
        key = key,
        mods = resize_or_move == "resize" and "ALT" or "CTRL",
        action = wezterm.action_callback(function(win, pane)
            if is_vim(pane) then
                -- Pass the keys through to Neovim
                win:perform_action({
                    SendKey = { key = key, mods = resize_or_move == "resize" and "ALT" or "CTRL" },
                }, pane)
            else
                -- Handle WezTerm pane navigation/resizing
                if resize_or_move == "resize" then
                    win:perform_action({ AdjustPaneSize = { direction_keys[key], 3 } }, pane)
                else
                    win:perform_action({ ActivatePaneDirection = direction_keys[key] }, pane)
                end
            end
        end),
    }
end

function M.setup(config, workspace_switcher, resurrect)
    local act = wezterm.action
    local spawn_actions = build_spawn_actions(config, act)

    -- Key Configuration ────────────────────────────────────────────────────────
    config.send_composed_key_when_left_alt_is_pressed = false
    config.send_composed_key_when_right_alt_is_pressed = false
    config.use_dead_keys = false

    -- Mode Key Tables ──────────────────────────────────────────────────────────
    config.key_tables = {
        copy_mode = {
            -- Vim-like navigation
            { key = "h", action = act.CopyMode("MoveLeft") },
            { key = "j", action = act.CopyMode("MoveDown") },
            { key = "k", action = act.CopyMode("MoveUp") },
            { key = "l", action = act.CopyMode("MoveRight") },
            -- Word navigation
            { key = "w", action = act.CopyMode("MoveForwardWord") },
            { key = "b", action = act.CopyMode("MoveBackwardWord") },
            { key = "e", action = act.CopyMode("MoveForwardWordEnd") },
            -- Line navigation
            { key = "0", action = act.CopyMode("MoveToStartOfLine") },
            { key = "$", action = act.CopyMode("MoveToEndOfLineContent") },
            { key = "^", action = act.CopyMode("MoveToStartOfLineContent") },
            -- Page navigation
            { key = "g", action = act.CopyMode("MoveToScrollbackTop") },
            { key = "G", action = act.CopyMode("MoveToScrollbackBottom") },
            { key = "H", action = act.CopyMode("MoveToViewportTop") },
            { key = "L", action = act.CopyMode("MoveToViewportBottom") },
            { key = "M", action = act.CopyMode("MoveToViewportMiddle") },
            -- Selection modes
            { key = "v", action = act.CopyMode({ SetSelectionMode = "Cell" }) },
            { key = "V", action = act.CopyMode({ SetSelectionMode = "Line" }) },
            { key = "v", mods = "CTRL", action = act.CopyMode({ SetSelectionMode = "Block" }) },
            -- Copy and exit
            {
                key = "y",
                action = act.Multiple({
                    { CopyTo = "ClipboardAndPrimarySelection" },
                    { CopyMode = "Close" },
                }),
            },
            -- Just exit
            { key = "q", action = act.CopyMode("Close") },
            -- Search within copy mode
            { key = "/", action = act.Search({ CaseInSensitiveString = "" }) },
            { key = "n", action = act.CopyMode("NextMatch") },
            { key = "N", action = act.CopyMode("PriorMatch") },
        },
        window_mode = {
            -- Pane focus
            { key = "h", action = act.ActivatePaneDirection("Left") },
            { key = "j", action = act.ActivatePaneDirection("Down") },
            { key = "k", action = act.ActivatePaneDirection("Up") },
            { key = "l", action = act.ActivatePaneDirection("Right") },
            -- Pane sizing
            { key = "h", mods = "SHIFT", action = act.AdjustPaneSize({ "Left", 3 }) },
            { key = "j", mods = "SHIFT", action = act.AdjustPaneSize({ "Down", 3 }) },
            { key = "k", mods = "SHIFT", action = act.AdjustPaneSize({ "Up", 3 }) },
            { key = "l", mods = "SHIFT", action = act.AdjustPaneSize({ "Right", 3 }) },
            -- Split and pane management (mirrors existing Cmd bindings)
            { key = "s", action = spawn_actions.split_down },
            { key = "v", action = spawn_actions.split_right },
            { key = "c", action = act.ActivateCopyMode },
            { key = "t", action = spawn_actions.tab },
            { key = "y", action = act.SpawnCommandInNewTab({ args = { "yazi" } }) },
            { key = "o", action = act.CloseCurrentPane({ confirm = false }) },
            { key = "z", action = act.TogglePaneZoomState },
            { key = "q", action = "PopKeyTable" },
        },
        workspace_mode = {
            { key = "g", action = workspace_switcher.switch_workspace() },
            { key = "l", action = workspace_switcher.switch_to_prev_workspace() },
            { key = "w", action = wezterm.action.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },
            {
                key = "n",
                action = act.PromptInputLine({
                    description = "Enter name for new workspace",
                    action = wezterm.action_callback(function(window, pane, line)
                        if line then
                            window:perform_action(act.SwitchToWorkspace({ name = line }), pane)
                        end
                    end),
                }),
            },
            {
                key = "r",
                action = act.PromptInputLine({
                    description = "Enter new workspace name",
                    action = wezterm.action_callback(function(window, pane, line)
                        if line then
                            window:perform_action(act.SwitchToWorkspace({ name = line }), pane)
                        end
                    end),
                }),
            },
            {
                key = "s",
                action = wezterm.action_callback(function(win, pane)
                    local workspace = wezterm.mux.get_active_workspace()
                    if resurrect and workspace then
                        resurrect.state_manager.save_state(resurrect.workspace_state.get_workspace_state(), workspace)
                        win:toast_notification("WezTerm", "Workspace state saved: " .. workspace, nil, 2000)
                    end
                end),
            },
            {
                key = "s",
                mods = "SHIFT",
                action = wezterm.action_callback(function(win, pane)
                    if not resurrect then
                        win:toast_notification("WezTerm", "Resurrect plugin not available", nil, 2000)
                        return
                    end

                    resurrect.fuzzy_loader.fuzzy_load(win, pane, function(id, label)
                        local type = string.match(id, "^([^/]+)")
                        id = string.match(id, "([^/]+)$")
                        id = string.match(id, "(.+)%..+$") or id

                        local opts = {
                            relative = true,
                            restore_text = false,
                            on_pane_restore = resurrect.tab_state.default_on_pane_restore,
                        }

                        if type == "workspace" then
                            local state = resurrect.state_manager.load_state(id, "workspace")
                            if state then
                                resurrect.workspace_state.restore_workspace(state, opts)
                                win:toast_notification("WezTerm", "Workspace restored: " .. id, nil, 2000)
                            end
                        elseif type == "window" then
                            opts.window = win
                            local state = resurrect.state_manager.load_state(id, "window")
                            if state then
                                resurrect.window_state.restore_window(win, state, opts)
                                win:toast_notification("WezTerm", "Window restored: " .. id, nil, 2000)
                            end
                        elseif type == "tab" then
                            local state = resurrect.state_manager.load_state(id, "tab")
                            if state then
                                resurrect.tab_state.restore_tab(pane:tab(), state, opts)
                                win:toast_notification("WezTerm", "Tab restored: " .. id, nil, 2000)
                            end
                        end
                    end, {
                        title = "Load Saved State",
                        description = "Select state to restore (Enter = load, q = cancel)",
                        fuzzy_description = "Search saved states: ",
                        is_fuzzy = true,
                        ignore_tabs = true,
                        ignore_windows = true,
                    })
                end),
            },
            { key = "y", action = act.SpawnCommandInNewTab({ args = { "yazi" } }) },
            { key = "q", action = "PopKeyTable" },
        },
    }

    -- Key Bindings ─────────────────────────────────────────────────────────────
    -- Design Philosophy:
    -- - Prefix tables on Ctrl+w and Ctrl+g mirror Vim/Yazi style chords
    -- - Tab navigation: CMD+number (standard macOS pattern)
    -- - Pane navigation: Ctrl+arrows OR Cmd+Option+HJKL (avoids vim conflicts)
    -- - Pane resizing: Ctrl+Shift+arrows OR Cmd+Shift+HJKL
    -- - Preserve Option+arrows for word jumping in terminal
    -- Smart tab switching helper - creates tabs if they don't exist
    local function smart_tab_switch(target_index)
        return wezterm.action_callback(function(window, pane)
            local tabs = window:mux_window():tabs()
            while #tabs <= target_index do
                window:perform_action(spawn_actions.tab, pane)
                tabs = window:mux_window():tabs()
            end
            window:perform_action(act.ActivateTab(target_index), pane)
        end)
    end

    config.keys = {
        -- Prefix-driven modal tables (single left-hand modifier)
        {
            key = "w",
            mods = "CTRL",
            action = act.ActivateKeyTable({ name = "window_mode", one_shot = true, timeout_milliseconds = 1000 }),
        },
        {
            key = "g",
            mods = "CTRL",
            action = act.ActivateKeyTable({ name = "workspace_mode", one_shot = true, timeout_milliseconds = 1000 }),
        },

        -- Tab cycling
        { key = "Tab", mods = "OPT", action = act.ActivateTabRelative(1) },
        { key = "Tab", mods = "CTRL", action = act.ActivateTabRelative(-1) },

        -- macOS standard shortcuts
        { key = "t", mods = "CMD", action = spawn_actions.tab },
        { key = "w", mods = "CMD", action = act.CloseCurrentTab({ confirm = false }) },
        -- Clipboard copy/paste
        { key = "c", mods = "CMD", action = act.CopyTo("Clipboard") },
        { key = "v", mods = "CMD", action = act.PasteFrom("Clipboard") },
        -- Command palette and search
        { key = "k", mods = "CMD", action = act.ActivateCommandPalette },
        { key = "f", mods = "CMD|SHIFT", action = act.Search({ CaseInSensitiveString = "" }) },
        { key = "k", mods = "CMD|SHIFT", action = act.ClearScrollback("ScrollbackOnly") },
        -- Pane splitting (Cmd+D horizontal, Cmd+Shift+D vertical) like iTerm2
        { key = "d", mods = "CMD", action = spawn_actions.split_right },
        { key = "d", mods = "CMD|SHIFT", action = spawn_actions.split_down },
        -- Smart navigation between WezTerm panes and Neovim splits (smart-splits.nvim integration)
        -- These will intelligently pass through to Neovim when needed
        smart_split_nav("move", "h"),
        smart_split_nav("move", "j"),
        smart_split_nav("move", "k"),
        smart_split_nav("move", "l"),
        -- Smart resizing with Alt+HJKL
        smart_split_nav("resize", "h"),
        smart_split_nav("resize", "j"),
        smart_split_nav("resize", "k"),
        smart_split_nav("resize", "l"),
        -- Keep arrow key navigation as fallback (always WezTerm panes)
        { key = "LeftArrow", mods = "CTRL", action = act.ActivatePaneDirection("Left") },
        { key = "DownArrow", mods = "CTRL", action = act.ActivatePaneDirection("Down") },
        { key = "UpArrow", mods = "CTRL", action = act.ActivatePaneDirection("Up") },
        { key = "RightArrow", mods = "CTRL", action = act.ActivatePaneDirection("Right") },
        -- Pane resizing (Ctrl+Shift + arrows) - consistent modifier pattern
        { key = "LeftArrow", mods = "CTRL|SHIFT", action = act.AdjustPaneSize({ "Left", 2 }) },
        { key = "DownArrow", mods = "CTRL|SHIFT", action = act.AdjustPaneSize({ "Down", 2 }) },
        { key = "UpArrow", mods = "CTRL|SHIFT", action = act.AdjustPaneSize({ "Up", 2 }) },
        { key = "RightArrow", mods = "CTRL|SHIFT", action = act.AdjustPaneSize({ "Right", 2 }) },
        -- Pane management
        { key = "w", mods = "CMD|OPT", action = act.CloseCurrentPane({ confirm = false }) },
        { key = "z", mods = "CMD|OPT", action = act.TogglePaneZoomState },
        -- Alternative navigation (Cmd+Option) - always navigates WezTerm panes, bypasses smart-splits
        { key = "h", mods = "CMD|OPT", action = act.ActivatePaneDirection("Left") },
        { key = "j", mods = "CMD|OPT", action = act.ActivatePaneDirection("Down") },
        { key = "k", mods = "CMD|OPT", action = act.ActivatePaneDirection("Up") },
        { key = "l", mods = "CMD|OPT", action = act.ActivatePaneDirection("Right") },
        -- Vim-style pane resizing (Cmd+Shift for safety)
        { key = "h", mods = "CMD|SHIFT", action = act.AdjustPaneSize({ "Left", 3 }) },
        { key = "j", mods = "CMD|SHIFT", action = act.AdjustPaneSize({ "Down", 3 }) },
        { key = "k", mods = "CMD|SHIFT", action = act.AdjustPaneSize({ "Up", 3 }) },
        { key = "l", mods = "CMD|SHIFT", action = act.AdjustPaneSize({ "Right", 3 }) },
        -- Tab navigation (Cycling)
        { key = "[", mods = "CMD|SHIFT", action = act.ActivateTabRelative(-1) },
        { key = "]", mods = "CMD|SHIFT", action = act.ActivateTabRelative(1) },
        -- Tab navigation with smart creation (CMD + number)
        { key = "1", mods = "CMD", action = act.ActivateTab(0) }, -- Tab 0 always exists
        { key = "2", mods = "CMD", action = smart_tab_switch(1) },
        { key = "3", mods = "CMD", action = smart_tab_switch(2) },
        { key = "4", mods = "CMD", action = smart_tab_switch(3) },
        { key = "5", mods = "CMD", action = smart_tab_switch(4) },
        { key = "6", mods = "CMD", action = smart_tab_switch(5) },
        { key = "7", mods = "CMD", action = smart_tab_switch(6) },
        { key = "8", mods = "CMD", action = smart_tab_switch(7) },
        { key = "9", mods = "CMD", action = act.ActivateTab(-1) }, -- Last tab
    }
end

return M
