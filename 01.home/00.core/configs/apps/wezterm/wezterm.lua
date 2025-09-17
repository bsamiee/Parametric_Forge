-- Title         : wezterm.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/wezterm/wezterm.lua
-- ----------------------------------------------------------------------------
-- WezTerm terminal configuration with workspace management - modular entry point

local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Import modules
local appearance = require("appearance")
local behavior = require("behavior")
local icons = require("icons")
local keys = require("keys")
local mouse = require("mouse")
local tabs = require("tabs")

-- Plugins ──────────────────────────────────────────────────────────────────
local workspace_switcher = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")
local resurrect = wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")

local wezterm_utils_bin = os.getenv("WEZTERM_UTILS_BIN") or "wezterm-utils"

-- Setup appearance and get shared values
local colors, FONT, invisible, window_bg, host_bg = appearance.setup(config)

-- Setup other modules
behavior.setup(config, colors, FONT)
tabs.setup(colors, icons.icons, invisible, window_bg, host_bg)
keys.setup(config, workspace_switcher, resurrect)
mouse.setup(config)

-- Resurrect configuration ──────────────────────────────────────────────────
-- Set explicit save directory to avoid symlink traversal issues
resurrect.state_manager.change_state_save_dir(wezterm.home_dir .. "/.local/state/wezterm/resurrect")

-- Auto-save workspace state every 15 minutes
resurrect.state_manager.periodic_save({
    interval_seconds = 900,
    save_workspaces = true,
    save_windows = false, -- Let yabai handle window state
    save_tabs = false, -- Workspace-level is sufficient
})

-- Limit output lines to improve performance
resurrect.state_manager.set_max_nlines(500)

-- Startup and session management ───────────────────────────────────────────
-- Window management handled by yabai - no startup handlers needed

-- Workspace Event Handlers ─────────────────────────────────────────────────
-- Consolidated handler for workspace switching
wezterm.on("smart_workspace_switcher.workspace_switcher.chosen", function(_, workspace)
    local name = workspace
    if type(workspace) == "table" then
        name = workspace.name or workspace.label or workspace.id or ""
    end
    name = tostring(name or "")

    -- Notify yabai about workspace change via wezterm-utils
    if name ~= "" and wezterm_utils_bin ~= "" then
        local ok, err = pcall(function()
            wezterm.run_child_process({ wezterm_utils_bin, "workspace-change", name })
        end)
        if not ok then
            wezterm.log_error("wezterm-utils workspace-change failed: " .. tostring(err))
        end
    end

    wezterm.log_info("Switched to workspace: " .. name)
end)

-- Handle new workspace creation with state restoration
wezterm.on("smart_workspace_switcher.workspace_switcher.created", function(window, path, label)
    -- Try to restore saved state for this workspace
    local ok, state = pcall(function()
        return resurrect.state_manager.load_state(label, "workspace")
    end)

    if ok and state then
        -- Restore workspace state with minimal text (performance optimization)
        local restore_ok, restore_err = pcall(function()
            resurrect.workspace_state.restore_workspace(state, {
                window = window,
                relative = true,
                restore_text = false, -- Don't restore text for performance
                on_pane_restore = resurrect.tab_state.default_on_pane_restore,
            })
        end)

        if restore_ok then
            wezterm.log_info("Restored workspace state for: " .. label)
        else
            wezterm.log_error("Failed to restore workspace: " .. tostring(restore_err))
        end
    else
        wezterm.log_info("No saved state found for workspace: " .. label)
    end

    -- Update yabai space label for new workspace
    if label ~= "" and wezterm_utils_bin ~= "" then
        local ok, err = pcall(function()
            wezterm.run_child_process({ wezterm_utils_bin, "space-label", label })
        end)
        if not ok then
            wezterm.log_error("wezterm-utils space-label failed: " .. tostring(err))
        end
    end
end)

-- Save state when workspace is selected (before switching away)
wezterm.on("smart_workspace_switcher.workspace_switcher.selected", function()
    if not resurrect then
        return
    end

    local ok, err = pcall(function()
        resurrect.state_manager.save_state(resurrect.workspace_state.get_workspace_state())
    end)
    if not ok then
        wezterm.log_error("Failed to save workspace on selection: " .. tostring(err))
    end
end)

return config
