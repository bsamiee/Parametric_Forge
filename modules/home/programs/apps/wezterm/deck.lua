-- Title         : deck.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : modules/home/programs/apps/wezterm/deck.lua
-- ----------------------------------------------------------------------------
-- Row interpreter for constructor-bound config: fonts, seam env, key dispatch,
-- pane-nav handoff, guarded broadcast, hyperlinks, launcher menu, floats, and
-- palette entries. Every vocabulary it consumes is generated (rows.lua); no
-- private literals. Actions build once per config generation: action_callback
-- registers a permanent handler per call, so per-press construction leaks.

local wezterm = require("wezterm")
local act = wezterm.action
local rows = require("rows")

local M = {}

M.rows = rows
M.has_nightly = wezterm.version:sub(1, 8) >= rows.nightly_floor
M.is_macos = wezterm.target_triple:find("apple") ~= nil
M.sync = nil -- populated in apply(); events.lua reads is_synced for status
M.palette = {} -- populated in apply(); events.lua replays it per palette open
M.commands = {} -- id -> command row (events.lua open-uri scoped spawns)
for _, cmd in ipairs(rows.commands) do
    M.commands[cmd.id] = cmd
end

-- Workspace identity crosses the outer-inner seam intact: the zellij session
-- carries the workspace name (estate slug policy), so windows in different
-- workspaces never mirror one shared session. A frozen layout asset recorded
-- under the slug (forge-zellij layout record) outranks the default layout —
-- the freeze/load round-trip closing at the spawn seam.
function M.session_args(name)
    local layout = os.getenv("ZELLIJ_DEFAULT_LAYOUT") or "default"
    local frozen = rows.paths.recorded_layouts .. "/" .. name .. ".kdl"
    local f = io.open(frozen)
    if f then
        f:close()
        layout = frozen
    end
    return { rows.paths.zellij, "--layout", layout, "attach", "--create", name }
end

function M.workspace_row(name)
    for _, w in ipairs(rows.workspaces) do
        if w.name == name then
            return w
        end
    end
end

function M.workspace_cwd(name)
    local w = M.workspace_row(name)
    return w and w.cwd
end

-- Destructive-action gate, total across version predicates: nightly prompts
-- via Confirmation, stable via a two-row InputSelector — the safety row
-- degrades in form, never in force. Build-time factory only: the stable arm
-- registers a callback per call.
function M.confirm(message, on_confirm)
    if M.has_nightly then
        return act.Confirmation({ message = message, action = on_confirm })
    end
    return act.InputSelector({
        title = message,
        choices = { { id = "confirm", label = "Confirm" }, { id = "cancel", label = "Cancel" } },
        action = wezterm.action_callback(function(window, pane, id)
            if id == "confirm" then
                window:perform_action(on_confirm, pane)
            end
        end),
    })
end

-- Receipt rail: the estate dual-receipt envelope — one kv-tab TSV row plus a
-- JSONL sibling with identical keys (ts + surface always; numerics stay JSON
-- numbers on the JSONL side). forge-receipts parses both.
function M.receipt(fields)
    local row = { ts = os.date("!%Y-%m-%dT%H:%M:%SZ"), surface = "wezterm-deck" }
    local parts = { "ts=" .. row.ts, "surface=" .. row.surface }
    for k, v in pairs(fields) do
        row[k] = v
        parts[#parts + 1] = k .. "=" .. tostring(v):gsub("[\t\n]", " ")
    end
    local f = io.open(rows.receipts_log, "a")
    if f then
        f:write(table.concat(parts, "\t") .. "\n")
        f:close()
    end
    local ok, json = pcall(wezterm.json_encode, row)
    local j = ok and io.open(rows.receipts_log:gsub("%.log$", ".jsonl"), "a") or nil
    if j then
        j:write(json .. "\n")
        j:close()
    end
end

-- Attention emitter: one JSONL row on the hook-feed superset schema (ts +
-- source + event + terminal identity), so non-Claude processes ride the same
-- collector fold, focus routing, and history queries as harness sessions.
-- Append-only and failure-silent — a bell must never fault the event plane.
function M.attention(fields)
    local row = {
        ts = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        source = "bell",
        event = "Bell",
        session_id = "-",
        cwd = "-",
        term = "WezTerm",
        wezterm_pane = "",
        zellij_session = "",
        zellij_pane = "",
        tty = "",
    }
    for k, v in pairs(fields) do
        row[k] = v
    end
    local ok, json = pcall(wezterm.json_encode, row)
    local f = ok and io.open(rows.attention_feed, "a") or nil
    if f then
        f:write(json .. "\n")
        f:close()
    end
end

-- Registry float rows are singletons: a live float for the row focuses
-- instead of duplicating (a second redeploy press must never fork a second
-- run); synthesized floats (varying args) never set reuse and spawn fresh.
-- Workspace-scoped rows key the singleton per workspace, so each workspace
-- owns its own instance (one scratch float per workspace, not one global).
-- The registry rides wezterm.GLOBAL, surviving config reloads; a dead or
-- workspace-hidden window fails resolution and falls through to a spawn.
local function float_key(cmd)
    if cmd.scope == "workspace" then
        return cmd.id .. "@" .. wezterm.mux.get_active_workspace()
    end
    return cmd.id
end

local function focus_float(cmd)
    local window_id = cmd.reuse and (wezterm.GLOBAL.deck_floats or {})[float_key(cmd)] or nil
    if not window_id then
        return false
    end
    local ok, mux_window = pcall(wezterm.mux.get_window, window_id)
    local gui = ok and mux_window and mux_window:gui_window() or nil
    if not gui then
        return false
    end
    gui:focus()
    M.receipt({ command = cmd.id, action = "focus", window_id = window_id, result = "ok" })
    return true
end

-- Floating utility deck: float rows shape the spawn natively — width/height
-- ride wezterm.mux.spawn_window as cell counts; window level is a macOS
-- platform row — other hosts degrade with an explicit receipt, never
-- silently. Workspace-scoped rows take the active workspace row's float
-- policy, so a remote workspace's floats read visibly distinct. The spawn
-- rides a pcall rail: a failure lands an error receipt, never an unhandled
-- callback fault (the second result is the error value).
function M.spawn_float(cmd)
    if focus_float(cmd) then
        return
    end
    local shape = cmd.float
    local cwd = cmd.cwd
    if cmd.scope == "workspace" then
        -- Workspace-scoped floats take the active workspace row's shape AND
        -- land at its cwd: the per-workspace scratch opens in the workspace.
        local wrow = M.workspace_row(wezterm.mux.get_active_workspace())
        shape = (wrow and wrow.float) or shape
        cwd = cwd or (wrow and wrow.cwd)
    end
    local float = rows.floats[shape]
    local ok, spawned, pane, window = pcall(wezterm.mux.spawn_window, {
        args = cmd.args,
        cwd = cwd,
        width = float.width,
        height = float.height,
    })
    if not ok then
        wezterm.log_error("deck: float spawn failed: " .. tostring(spawned))
        M.receipt({ command = cmd.id, action = "float", result = "error", detail = tostring(spawned) })
        return
    end
    local gui = window:gui_window()
    local level = "degrade:platform"
    if gui then
        gui:set_config_overrides({
            window_background_opacity = float.opacity,
            window_decorations = float.decorations,
            enable_tab_bar = false,
        })
        if M.is_macos then
            gui:perform_action(act.SetWindowLevel(float.level), pane)
            level = float.level
        end
    end
    if cmd.reuse then
        local registry = wezterm.GLOBAL.deck_floats or {}
        registry[float_key(cmd)] = window:window_id()
        wezterm.GLOBAL.deck_floats = registry
    end
    M.receipt({
        command = cmd.id,
        action = "float",
        domain = pane:get_domain_name(),
        window_id = window:window_id(),
        pane_id = pane:pane_id(),
        level = level,
        result = "ok",
    })
end

-- Command rows project to actions once: one factory per kind; a destructive
-- row wraps its action in the confirm gate at build time; unknown kinds fault
-- loudly and drop from the palette.
local command_kinds = {
    float = function(cmd)
        return wezterm.action_callback(function()
            M.spawn_float(cmd)
        end)
    end,
    domain = function(cmd)
        return wezterm.action_callback(function(window, pane)
            window:perform_action(act.SpawnCommandInNewWindow({ domain = { DomainName = cmd.domain } }), pane)
            M.receipt({ command = cmd.id, action = "domain", domain = cmd.domain, result = "ok" })
        end)
    end,
}

local function command_action(cmd)
    local kind = command_kinds[cmd.kind]
    if not kind then
        wezterm.log_error("deck: no handler for command kind " .. tostring(cmd.kind))
        return nil
    end
    local action = kind(cmd)
    if cmd.destructive then
        return M.confirm("Run destructive deck command: " .. cmd.label .. "?", action)
    end
    return action
end

-- Quick-select action bus: per-row `select` arms convert the selected span
-- into a Forge action; rows without an arm keep the native clipboard default.
local select_kinds = {
    ["edit"] = function(_, pane, sel)
        local file, line = sel:match("^(.-):(%d+)")
        if not file then
            return
        end
        local cwd = pane:get_current_working_dir()
        local host = cwd and cwd.host and cwd.host:gsub("%..*", "") or nil
        if host and host ~= wezterm.hostname():gsub("%..*", "") then
            -- Remote pane: a local nvim float cannot reach the remote path.
            M.receipt({ command = "quick-edit", action = "edit", result = "blocked", detail = "remote pane " .. host })
            return
        end
        M.spawn_float({
            id = "quick-edit",
            float = "utility",
            cwd = cwd and cwd.file_path or nil,
            args = { rows.paths.nvim, "+" .. line, file },
        })
    end,
    ["domain"] = function(window, pane, sel)
        local domain = rows.host_domains[sel]
        if not domain then
            return
        end
        window:perform_action(act.SpawnCommandInNewWindow({ domain = { DomainName = domain } }), pane)
        M.receipt({ command = "quick-domain", action = "domain", domain = domain, result = "ok" })
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

-- Workspace switcher: configured name-policy rows plus live mux workspaces.
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
    -- Fresh workspaces land their slug-named inner session at the policy cwd;
    -- live workspaces ignore spawn, so reattach converges on the same session.
    local spawn = { args = M.session_args(name), cwd = M.workspace_cwd(name) }
    window:perform_action(act.SwitchToWorkspace({ name = name, spawn = spawn }), pane)
    M.receipt({ command = "workspace-switch", action = "switch", workspace = name, result = "ok" })
end

-- Workspace picker action, registered once: choices rebuild per press inside
-- the key callback; every selection replays this one handler.
local pick_workspace = wezterm.action_callback(function(win, p, id)
    if id then
        switch_workspace(win, p, id)
    end
end)

-- Pane-nav handoff: one generated row set crosses the WezTerm boundary —
-- nvim/zellij panes receive the raw chord, plain splits get pane motion.
local nav_direction = {
    ["nav-left"] = "Left",
    ["nav-down"] = "Down",
    ["nav-up"] = "Up",
    ["nav-right"] = "Right",
}
local function nav_action(row)
    return wezterm.action_callback(function(window, pane)
        local proc = (pane:get_foreground_process_name() or ""):gsub(".*/", "")
        if proc == "nvim" or proc == "zellij" then
            window:perform_action(act.SendKey({ key = row.key, mods = row.mods }), pane)
        else
            window:perform_action(act.ActivatePaneDirection(nav_direction[row.action]), pane)
        end
    end)
end

-- Guarded broadcast: SSH-domain safety then destructive confirmation, only
-- then the plugin toggle. Disabling an active sync never prompts. The enable
-- and confirm actions build once; the per-press body only performs them.
local function guarded_sync_action(sync)
    local enable = wezterm.action_callback(function(win, p)
        win:perform_action(sync.toggle, p)
        M.receipt({ command = "sync-toggle", action = "on", result = "ok" })
    end)
    local confirm_enable = M.confirm("Broadcast every keystroke to ALL panes in this tab?", enable)
    return wezterm.action_callback(function(window, pane)
        if sync.is_synced(window) then
            window:perform_action(sync.toggle, pane)
            M.receipt({ command = "sync-toggle", action = "off", result = "ok" })
            return
        end
        for _, p in ipairs(window:active_tab():panes()) do
            local domain = p:get_domain_name()
            if domain ~= "local" then
                window:toast_notification("forge deck", "sync-panes blocked: remote pane in tab (" .. domain .. ")", nil, 4000)
                M.receipt({ command = "sync-toggle", action = "on", result = "blocked", domain = domain })
                return
            end
        end
        window:perform_action(confirm_enable, pane)
    end)
end

-- Chord-row action dispatch: semantic id -> action, built once. Total over the
-- generated vocabulary minus the plugin-owned sync row and class-routed nav
-- rows; the build validator proves every row id has an arm in this file.
local function key_actions(launcher, quick_select)
    local prompt = {
        description = "New workspace name:",
        action = wezterm.action_callback(function(win, p, line)
            if line and line ~= "" then
                switch_workspace(win, p, line)
            end
        end),
    }
    if M.has_nightly then
        prompt.prompt = "workspace ❯ "
    end
    return {
        ["copy"] = act.CopyTo("Clipboard"),
        ["paste"] = act.PasteFrom("Clipboard"),
        ["spawn-window"] = wezterm.action_callback(function(window, _)
            local ws = window:active_workspace()
            wezterm.mux.spawn_window({ workspace = ws, cwd = M.workspace_cwd(ws), args = M.session_args(ws) })
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
        -- Attention router: one keypress resolves the collector's latest
        -- needs-input row and focuses that pane (forge-agents owns the hops).
        ["attention-focus"] = wezterm.action_callback(function()
            wezterm.background_child_process({ rows.paths.forge_agents, "focus" })
        end),
        ["workspace-switch"] = wezterm.action_callback(function(window, pane)
            window:perform_action(
                act.InputSelector({
                    title = "forge workspaces",
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
    -- Fonts: font-owner rows (modules/home/fonts.nix), constructor-bound. The
    -- forge-font override file prepends a manifest-proven family and rides the
    -- config reload watch list, so a swap applies live; leading travels per
    -- mono family, never as one global value; an override naming a chain row
    -- keeps that row's full spec (weight included).
    local function font_spec(f)
        return f.weight and { family = f.family, weight = f.weight } or f.family
    end
    local chain_rows = {}
    for _, f in ipairs(rows.font.chain) do
        chain_rows[f.family] = f
    end
    local families = {}
    local primary = rows.font.chain[1] and rows.font.chain[1].family
    wezterm.add_to_config_reload_watch_list(rows.font.override_path)
    local fh = io.open(rows.font.override_path)
    if fh then
        local ok, override = pcall(wezterm.json_parse, fh:read("*a"))
        fh:close()
        if ok and type(override) == "table" and override.mono then
            primary = override.mono
            families[1] = chain_rows[primary] and font_spec(chain_rows[primary]) or primary
        end
    end
    for _, f in ipairs(rows.font.chain) do
        if f.family ~= primary or #families == 0 then
            families[#families + 1] = font_spec(f)
        end
    end
    config.font = wezterm.font_with_fallback(families)
    config.font_size = rows.font.size
    config.line_height = rows.font.line_heights[primary] or rows.font.default_line_height
    config.harfbuzz_features = rows.font.harfbuzz_features

    -- Nightly-gated scalar rows. The auth-sock pin routes every mux-spawned
    -- pane and SSH domain through the 1Password agent instead of the
    -- identity-less ambient launchd socket.
    if M.has_nightly then
        config.command_palette_font = config.font
        config.quick_select_remove_styling = true
        config.default_ssh_auth_sock = rows.paths.auth_sock
    end

    -- Outer-inner seam: zellij attach + toolchain PATH projection. Deck-owned
    -- spawns carry their workspace session explicitly; this is the fallback for
    -- panes spawned outside deck control (`wezterm cli spawn` without a prog).
    config.default_prog = M.session_args(config.default_workspace)
    local ambient = os.getenv("PATH")
    config.set_environment_variables = {
        PATH = (ambient and ambient ~= "") and (rows.paths.path .. ":" .. ambient) or rows.paths.path,
    }

    -- Action bus: default hyperlink rules plus generated semantic rows.
    config.hyperlink_rules = wezterm.default_hyperlink_rules()
    for _, rule in ipairs(rows.hyperlinks) do
        table.insert(config.hyperlink_rules, { regex = rule.regex, format = rule.format })
    end

    -- Launcher menu: non-destructive float command rows become launch items.
    config.launch_menu = {}
    for _, cmd in ipairs(rows.commands) do
        if cmd.kind == "float" and not cmd.destructive then
            table.insert(config.launch_menu, { label = cmd.label, args = cmd.args })
        end
    end

    -- Palette rows build once: command entries plus per-pattern quick select;
    -- the palette event replays this table (a per-open rebuild would register
    -- a fresh callback set on every open).
    M.palette = {}
    for _, cmd in ipairs(rows.commands) do
        local action = command_action(cmd)
        if action then
            M.palette[#M.palette + 1] = { brief = cmd.label, icon = "md_dock_window", action = action }
        end
    end
    for _, pattern in ipairs(rows.quick_select) do
        M.palette[#M.palette + 1] = {
            brief = "quick select: " .. pattern.id,
            icon = "md_select_search",
            action = act.QuickSelectArgs({
                label = pattern.id,
                patterns = { pattern.regex },
                action = select_action(pattern),
            }),
        }
    end

    -- Mouse: SHIFT bypasses inner-plane reporting; SHIFT-click opens links.
    config.mouse_bindings = {
        {
            event = { Up = { streak = 1, button = "Left" } },
            mods = "SHIFT",
            action = act.OpenLinkAtMouseCursor,
        },
    }

    -- Quick select: stable QuickSelect, nightly QuickSelectArgs paste-skip.
    local quick_select = act.QuickSelect
    local launcher = { flags = "FUZZY|COMMANDS|KEY_ASSIGNMENTS|WORKSPACES|DOMAINS|LAUNCH_MENU_ITEMS" }
    if M.has_nightly then
        quick_select = act.QuickSelectArgs({ skip_action_on_paste = true })
        launcher.title = "forge launcher"
        launcher.help_text = "Enter=run  Esc=cancel  /=filter"
        launcher.fuzzy_help_text = "Launcher: "
    end

    -- Key rows: generated chord vocabulary through the dispatch table.
    local actions = key_actions(launcher, quick_select)
    config.keys = {}
    local sync_row = nil
    for _, row in ipairs(rows.keys) do
        if row.action == "sync-toggle" then
            sync_row = row
        elseif row.class == "nav" then
            table.insert(config.keys, { key = row.key, mods = row.mods, action = nav_action(row) })
        elseif not (row.requires_nightly and not M.has_nightly) then
            local action = actions[row.action]
            if action == nil then
                wezterm.log_error("deck: chord action without dispatch arm: " .. row.action)
            else
                table.insert(config.keys, { key = row.key, mods = row.mods, action = action })
            end
        end
    end

    -- Store-owned plugin rail: direct store-path load. plugin.require would
    -- git-clone into the runtime cache (and a fetchFromGitHub tree is not a
    -- repo); dofile consumes the pin with zero cache mutation, so the cache
    -- stays empty and update_all() has nothing to touch. The env row swaps the
    -- pin for a dev checkout without touching generated config.
    local sync_src = os.getenv("FORGE_WEZTERM_PLUGIN_SYNC_PANES") or rows.plugins.sync_panes
    local sync = dofile(sync_src .. "/plugin/init.lua")
    M.sync = sync
    if sync_row then
        sync.apply_to_config(config, {
            toggle_key = sync_row.key,
            toggle_mods = sync_row.mods,
            indicator = false, -- events.lua owns the status plane
            border = true,
            border_color = rows.theme.roles.state.attention,
        })
        -- Wrap the plugin-inserted toggle with the SSH-domain + confirmation guard.
        local guarded = guarded_sync_action(sync)
        for _, k in ipairs(config.keys) do
            if k.key == sync_row.key and k.mods == sync_row.mods then
                k.action = guarded
            end
        end
    end
end

return M
