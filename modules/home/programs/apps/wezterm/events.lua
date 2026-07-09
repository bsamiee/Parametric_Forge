-- Title         : events.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : modules/home/programs/apps/wezterm/events.lua
-- ----------------------------------------------------------------------------
-- Event plane: startup shaping, outer-fact status cells, tab/window titles,
-- palette augmentation, and the forge:// open-uri handoff. Status reads cheap
-- pane/window state plus cached JSON only; every probe writes elsewhere.

local wezterm = require("wezterm")
local act = wezterm.action
local rows = require("rows")
local deck = require("deck")

local M = {}

local roles = rows.theme.roles

-- Cached-JSON reader: nightly serde, json_parse fallback; absent cache is a
-- silent no-cell (the CA-7 collector owns writing it).
local function read_cache(path)
  local f = io.open(path, "r")
  if not f then
    return nil
  end
  local body = f:read("*a")
  f:close()
  local ok, parsed
  if deck.has_nightly and wezterm.serde then
    ok, parsed = pcall(wezterm.serde.json_decode, body)
  else
    ok, parsed = pcall(wezterm.json_parse, body)
  end
  return ok and parsed or nil
end

local function cell(fg, text)
  return {
    { Foreground = { Color = fg } },
    { Text = " " .. text .. " " },
  }
end

local function workspace_cwd(name)
  for _, w in ipairs(rows.workspaces) do
    if w.name == name then
      return w.cwd
    end
  end
end

function M.apply(config) -- luacheck: no unused args
  -- Session persistence is code-defined: GUI and auto-spawned mux servers
  -- land the default workspace at its name-policy cwd; no session plugin.
  wezterm.on("gui-startup", function(cmd)
    local spawn = cmd or {}
    spawn.cwd = spawn.cwd or workspace_cwd(wezterm.mux.get_active_workspace())
    local _, _, window = wezterm.mux.spawn_window(spawn)
    local gui = window:gui_window()
    if gui then
      gui:maximize()
    end
  end)

  wezterm.on("mux-startup", function()
    wezterm.mux.spawn_window({ cwd = workspace_cwd(wezterm.mux.get_active_workspace()) })
  end)

  -- Domain attach shaping: one launch receipt per attach.
  wezterm.on("gui-attached", function(domain)
    deck.receipt({ action = "attach", domain = domain:name(), result = "ok" })
  end)

  -- Outer facts only: key table, sync state, domain, workspace, cached agent
  -- cell. Inner facts (mode, cwd, git) stay with zjstatus/starship.
  wezterm.on("update-status", function(window, pane)
    local items = {}
    local function push(fragments)
      for _, fragment in ipairs(fragments) do
        items[#items + 1] = fragment
      end
    end

    local key_table = window:active_key_table()
    if key_table then
      push(cell(roles.state.attention, "[" .. key_table:upper() .. "]"))
    end
    if deck.sync and deck.sync.is_synced(window) then
      push(cell(roles.state.danger, "[SYNC]"))
    end

    local domain = pane and pane:get_domain_name() or "local"
    if domain ~= "local" then
      push(cell(roles.state.info, domain))
    end

    local cache = read_cache(rows.status_cache)
    if cache and cache.cells then
      for _, c in ipairs(cache.cells) do
        push(cell(roles.state[c.role] or roles.text.muted, c.text))
      end
    end

    push(cell(roles.accent.tertiary, window:active_workspace()))
    window:set_right_status(wezterm.format(items))
    window:set_left_status("")
  end)

  wezterm.on("format-tab-title", function(tab)
    local pane = tab.active_pane
    local proc = (pane.foreground_process_name or ""):gsub(".*/", "")
    local title = proc ~= "" and proc or pane.title
    return string.format(" %d:%s ", tab.tab_index + 1, title)
  end)

  wezterm.on("format-window-title", function(tab, _, tabs)
    local workspace = wezterm.mux.get_active_workspace()
    return string.format("%s — %d/%d", workspace, tab.tab_index + 1, #tabs)
  end)

  -- Command deck rows land in the native palette without replacing it.
  wezterm.on("augment-command-palette", function(window, pane)
    local entries = {}
    for _, cmd in ipairs(rows.commands) do
      entries[#entries + 1] = {
        brief = cmd.label,
        icon = "md_dock_window",
        action = wezterm.action_callback(function(win, p)
          deck.run_command(cmd, win, p)
        end),
      }
    end
    for _, pattern in ipairs(rows.quick_select) do
      entries[#entries + 1] = {
        brief = "quick select: " .. pattern.id,
        icon = "md_select_search",
        action = act.QuickSelectArgs({
          label = pattern.id,
          patterns = { pattern.regex },
          action = deck.select_action(pattern),
        }),
      }
    end
    return entries
  end)

  -- forge://<register-domain>[/...] opens the register browser float.
  wezterm.on("open-uri", function(window, pane, uri)
    local domain = uri:match("^forge://([%w-]+)")
    if domain then
      for _, cmd in ipairs(rows.commands) do
        if cmd.id == "browse-registers" then
          local scoped = { id = cmd.id, kind = cmd.kind, float = cmd.float, label = cmd.label, args = { cmd.args[1], domain } }
          deck.run_command(scoped, window, pane)
          return false
        end
      end
    end
  end)
end

return M
