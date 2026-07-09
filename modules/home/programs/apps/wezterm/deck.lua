-- Title         : deck.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : modules/home/programs/apps/wezterm/deck.lua
-- ----------------------------------------------------------------------------
-- Row interpreter for constructor-bound config: fonts, seam env, key dispatch,
-- pane-nav handoff, guarded broadcast, hyperlinks, launcher menu, floats.
-- Every vocabulary it consumes is generated (rows.lua); no private literals.

local wezterm = require("wezterm")
local act = wezterm.action
local rows = require("rows")

local M = {}

M.rows = rows
M.has_nightly = wezterm.version:sub(1, 8) >= rows.nightly_floor
M.is_macos = wezterm.target_triple:find("apple") ~= nil
M.sync = nil -- populated in apply(); events.lua reads is_synced for status

local layout = os.getenv("ZELLIJ_DEFAULT_LAYOUT") or "default"

-- Workspace identity crosses the outer-inner seam intact: the zellij session
-- carries the workspace name (CA-1 slug policy), so windows in different
-- workspaces never mirror one shared session.
function M.session_args(name)
  return { rows.paths.zellij, "--layout", layout, "attach", "--create", name }
end

function M.workspace_cwd(name)
  for _, w in ipairs(rows.workspaces) do
    if w.name == name then
      return w.cwd
    end
  end
end

-- Destructive-action gate, total across version predicates: nightly prompts
-- via Confirmation, stable via a two-row InputSelector — the safety row
-- degrades in form, never in force.
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

-- Receipt rail: kv-tab rows appended to the deck log (forge-receipts parses).
function M.receipt(fields)
  local parts = {
    "ts=" .. os.date("!%Y-%m-%dT%H:%M:%SZ"),
    "owner=wezterm-deck",
  }
  for k, v in pairs(fields) do
    parts[#parts + 1] = k .. "=" .. tostring(v):gsub("[\t\n]", " ")
  end
  local f = io.open(rows.receipts_log, "a")
  if f then
    f:write(table.concat(parts, "\t") .. "\n")
    f:close()
  end
end

-- Floating utility deck: mux-spawn then shape the GUI window from float rows.
-- Cell metrics derive from the live window; window level is a macOS platform
-- row — other hosts degrade with an explicit receipt, never silently.
function M.spawn_float(cmd)
  local float = rows.floats[cmd.float] or rows.floats.utility
  local _, pane, window = wezterm.mux.spawn_window({ args = cmd.args, cwd = cmd.cwd })
  local gui = window:gui_window()
  local level = "degrade:platform"
  if gui then
    local dims = gui:get_dimensions()
    local size = pane:get_dimensions()
    gui:set_inner_size(
      math.floor(float.width * dims.pixel_width / math.max(size.cols, 1)),
      math.floor(float.height * dims.pixel_height / math.max(size.viewport_rows, 1))
    )
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

-- Command rows dispatch: one handler per kind; unknown kinds fault loudly.
local command_kinds = {
  float = function(cmd, window, pane)
    if cmd.destructive then
      window:perform_action(
        M.confirm(
          "Run destructive deck command: " .. cmd.label .. "?",
          wezterm.action_callback(function()
            M.spawn_float(cmd)
          end)
        ),
        pane
      )
    else
      M.spawn_float(cmd)
    end
  end,
  domain = function(cmd, window, pane)
    window:perform_action(act.SpawnCommandInNewWindow({ domain = { DomainName = cmd.domain } }), pane)
    M.receipt({ command = cmd.id, action = "domain", domain = cmd.domain, result = "ok" })
  end,
}

function M.run_command(cmd, window, pane)
  local handler = command_kinds[cmd.kind]
  if handler then
    handler(cmd, window, pane)
  else
    wezterm.log_error("deck: no handler for command kind " .. tostring(cmd.kind))
  end
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

function M.select_action(row)
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
-- then the plugin toggle. Disabling an active sync never prompts.
local function guarded_sync_action(sync)
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
    local enable = wezterm.action_callback(function(win, p)
      win:perform_action(sync.toggle, p)
      M.receipt({ command = "sync-toggle", action = "on", result = "ok" })
    end)
    window:perform_action(M.confirm("Broadcast every keystroke to ALL panes in this tab?", enable), pane)
  end)
end

-- Chord-row action dispatch: semantic id -> action. Total over the generated
-- vocabulary; the build validator proves every row id has an arm here.
local function key_actions(launcher, quick_select)
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
    ["workspace-switch"] = wezterm.action_callback(function(window, pane)
      window:perform_action(
        act.InputSelector({
          title = "forge workspaces",
          fuzzy = true,
          choices = workspace_choices(),
          action = wezterm.action_callback(function(win, p, id)
            if id then
              switch_workspace(win, p, id)
            end
          end),
        }),
        pane
      )
    end),
    ["workspace-new"] = wezterm.action_callback(function(window, pane)
      local prompt = { description = "New workspace name:" }
      if M.has_nightly then
        prompt.prompt = "workspace ❯ "
      end
      prompt.action = wezterm.action_callback(function(win, p, line)
        if line and line ~= "" then
          switch_workspace(win, p, line)
        end
      end)
      window:perform_action(act.PromptInputLine(prompt), pane)
    end),
    ["sync-toggle"] = "plugin-owned", -- bound by the sync-panes wrap below
    ["nav-left"] = "nav",
    ["nav-down"] = "nav",
    ["nav-up"] = "nav",
    ["nav-right"] = "nav",
  }
end

function M.apply(config)
  -- Fonts: generated row, constructor-bound (design-language cell metrics).
  local families = {}
  for _, f in ipairs(rows.font.chain) do
    families[#families + 1] = f.weight and { family = f.family, weight = f.weight } or f.family
  end
  config.font = wezterm.font_with_fallback(families)
  config.font_size = rows.font.size
  config.line_height = rows.font.line_height
  config.harfbuzz_features = rows.font.harfbuzz_features
  config.use_cap_height_to_scale_fallback_fonts = true
  config.warn_about_missing_glyphs = true

  -- Nightly-gated scalar rows.
  if M.has_nightly then
    config.command_palette_font = config.font
    config.quick_select_remove_styling = true
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

  -- Launcher menu: float/domain command rows become launch items.
  config.launch_menu = {}
  for _, cmd in ipairs(rows.commands) do
    if cmd.kind == "float" and not cmd.destructive then
      table.insert(config.launch_menu, { label = cmd.label, args = cmd.args })
    end
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
