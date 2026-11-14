local wezterm = require("wezterm")
local act = wezterm.action
local rows = require("rows")

local M = {}

M.palette = {}

local function workspace_row(name)
    for _, w in ipairs(rows.workspaces) do
        if w.name == name then
            return w
        end
    end
end

function M.session_args(name, gated)
    local w = workspace_row(name)
    local launch = "unset __MISE_DIFF __MISE_SESSION __HM_SESS_VARS_SOURCED __HM_ZSH_SESS_VARS_SOURCED"
        .. ' WEZTERM_UNIX_SOCKET WEZTERM_PANE; cd -- "$1" && shift && exec "$@"'
    local body = gated and "read -r _; " .. launch or launch
    return {
        rows.paths.zsh,
        "-lc",
        body,
        "zsh",
        w and w.cwd or wezterm.home_dir,
        rows.paths.zellij_attach,
        name,
    }
end

local function float_key(cmd)
    if cmd.scope == "workspace" then
        return cmd.id .. "@" .. wezterm.mux.get_active_workspace()
    end
    return cmd.id
end

local function focus_float(cmd)
    local window_id = (wezterm.GLOBAL.deck_floats or {})[float_key(cmd)]
    if not window_id then
        return false
    end
    local ok, mux_window = pcall(wezterm.mux.get_window, window_id)
    local gui = ok and mux_window and mux_window:gui_window() or nil
    if not gui then
        return false
    end
    gui:focus()
    return true
end

local function spawn_float(cmd)
    if focus_float(cmd) then
        return
    end
    local wrow = cmd.scope == "workspace" and workspace_row(wezterm.mux.get_active_workspace()) or nil
    local float = rows.floats[cmd.float]
    local ok, spawned, pane, window = pcall(wezterm.mux.spawn_window, {
        args = cmd.args,
        cwd = wrow and wrow.cwd,
        width = float.width,
        height = float.height,
    })
    if not ok then
        wezterm.log_error("deck: float spawn failed: " .. tostring(spawned))
        return
    end
    local gui = window:gui_window()
    if gui then
        gui:set_config_overrides({
            window_background_opacity = float.opacity,
            window_decorations = float.decorations,
            enable_tab_bar = false,
        })
        gui:perform_action(act.SetWindowLevel(float.level), pane)
    end
    local registry = wezterm.GLOBAL.deck_floats or {}
    registry[float_key(cmd)] = window:window_id()
    wezterm.GLOBAL.deck_floats = registry
end

local function command_action(cmd)
    local action = wezterm.action_callback(function()
        spawn_float(cmd)
    end)
    if cmd.destructive then
        return act.Confirmation({ message = "Run destructive deck command: " .. cmd.label .. "?", action = action })
    end
    return action
end

local select_kinds = {
    ["edit"] = function(_, pane, sel)
        local file, position = sel:match("^([^:]+)(:%d.*)$")
        if not file then
            return
        end
        if file:sub(1, 2) == "~/" then
            file = wezterm.home_dir .. file:sub(2)
        elseif file:sub(1, 1) ~= "/" then
            local cwd = pane:get_current_working_dir()
            if not cwd then
                wezterm.log_error("deck: focused pane reported no working directory")
                return
            end
            file = cwd.file_path .. "/" .. file
        end
        wezterm.background_child_process({ rows.paths.code, "--goto", file .. position })
    end,
}

local function select_action(row)
    local kind = select_kinds[row.select]
    if not kind then
        return nil
    end
    return wezterm.action_callback(function(window, pane)
        kind(window, pane, window:get_selection_text_for_pane(pane))
    end)
end

local function workspace_choices()
    local choices, seen = {}, {}
    for _, w in ipairs(rows.workspaces) do
        choices[#choices + 1] = { id = w.name, label = w.label .. "  " .. w.name }
        seen[w.name] = true
    end
    for _, name in ipairs(wezterm.mux.get_workspace_names()) do
        if not seen[name] then
            choices[#choices + 1] = { id = name, label = "[LIVE]  " .. name }
        end
    end
    return choices
end

local function switch_workspace(window, pane, name)
    local spawn = { args = M.session_args(name), cwd = wezterm.home_dir }
    window:perform_action(act.SwitchToWorkspace({ name = name, spawn = spawn }), pane)
end

local pick_workspace = wezterm.action_callback(function(win, p, id)
    if id then
        switch_workspace(win, p, id)
    end
end)

local function key_actions(launcher, quick_select)
    local prompt = {
        description = "New workspace name:",
        prompt = "workspace ❯ ",
        action = wezterm.action_callback(function(win, p, line)
            if line and line ~= "" then
                switch_workspace(win, p, line)
            end
        end),
    }
    return {
        ["copy"] = act.CopyTo("Clipboard"),
        ["paste"] = act.PasteFrom("Clipboard"),
        ["spawn-window"] = wezterm.action_callback(function(window, _)
            local ws = window:active_workspace()
            wezterm.mux.spawn_window({ workspace = ws, cwd = wezterm.home_dir, args = M.session_args(ws) })
        end),
        ["quit"] = act.QuitApplication,
        ["hide-app"] = act.HideApplication,
        ["minimize"] = act.Hide,
        ["font-inc"] = act.IncreaseFontSize,
        ["font-dec"] = act.DecreaseFontSize,
        ["font-reset"] = act.ResetFontSize,
        ["reload"] = act.ReloadConfiguration,
        ["palette"] = act.ActivateCommandPalette,
        ["char-select"] = act.CharSelect,
        ["debug-overlay"] = act.ShowDebugOverlay,
        ["quick-select"] = quick_select,
        ["launcher"] = act.ShowLauncherArgs(launcher),
        ["workspace-switch"] = wezterm.action_callback(function(window, pane)
            window:perform_action(
                act.InputSelector({
                    title = "deck workspaces",
                    fuzzy = true,
                    choices = workspace_choices(),
                    action = pick_workspace,
                }),
                pane
            )
        end),
        ["workspace-new"] = act.PromptInputLine(prompt),
    }
end

function M.apply(config)
    config.font = wezterm.font_with_fallback(rows.font.chain)
    config.font_size = rows.font.size
    config.line_height = rows.font.line_height
    config.command_palette_font = config.font

    config.default_prog = M.session_args(config.default_workspace)

    config.launch_menu = {}
    for _, cmd in ipairs(rows.commands) do
        if not cmd.destructive then
            table.insert(config.launch_menu, { label = cmd.label, args = cmd.args })
        end
    end

    M.palette = {}
    for _, cmd in ipairs(rows.commands) do
        M.palette[#M.palette + 1] = { brief = cmd.label, icon = rows.palette_icons.command, action = command_action(cmd) }
    end
    for _, pattern in ipairs(rows.quick_select) do
        M.palette[#M.palette + 1] = {
            brief = "quick select: " .. pattern.id,
            icon = rows.palette_icons.quick_select,
            action = act.QuickSelectArgs({
                label = pattern.id,
                patterns = { pattern.regex },
                action = select_action(pattern),
            }),
        }
    end

    local quick_select = act.QuickSelectArgs({ skip_action_on_paste = true })
    local launcher = {
        flags = "FUZZY|COMMANDS|KEY_ASSIGNMENTS|WORKSPACES|LAUNCH_MENU_ITEMS",
        title = "deck launcher",
        help_text = "Enter=run  Esc=cancel  /=filter",
        fuzzy_help_text = "Launcher: ",
    }

    local actions = key_actions(launcher, quick_select)
    config.keys = {}
    for _, row in ipairs(rows.keys) do
        local action = actions[row.action]
        if action == nil then
            wezterm.log_error("deck: chord action without dispatch arm: " .. row.action)
        else
            table.insert(config.keys, { key = row.key, mods = row.mods, action = action })
        end
    end
end

return M
