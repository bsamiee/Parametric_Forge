-- Title         : ecosystem.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/sketchybar/modules/core/ecosystem.lua
-- ----------------------------------------------------------------------------
-- Ecosystem state coordination - unifies yabai, yazi, and SketchyBar as one organism

local M = {
    workspace_contexts = {},
    current_context = {},
    git_status_cache = {},
    ecosystem_ready = false,
}

-- Initialize workspace contexts with intelligent defaults
function M.init_workspace_contexts()
    M.workspace_contexts = {
        [1] = { name = "Terminal", directory = "~", type = "shell" },
        [2] = { name = "Development", directory = "~/Documents/99.Github", type = "coding" },
        [3] = { name = "Parametric", directory = "~/Documents/99.Github/Parametric_Forge", type = "nix" },
        [4] = { name = "Documents", directory = "~/Documents", type = "files" },
        [5] = { name = "Config", directory = "~/.config", type = "system" },
    }
end

-- Workspace-aware yazi coordination
function M.coordinate_workspace_change(workspace_id)
    local context = M.workspace_contexts[workspace_id]
    if not context then
        return
    end

    M.current_context = context

    -- Cache current directory for performance
    performance.cache_set("current_workspace", workspace_id, 30)
    performance.cache_set("current_context", context, 30)

    -- Trigger yazi directory change via XDG-compliant ecosystem event
    local home = os.getenv("HOME")
    local xdg_state = os.getenv("XDG_STATE_HOME") or home .. "/.local/state"

    sbar.exec(
        "mkdir -p '"
            .. xdg_state
            .. "/ecosystem' && echo 'cd "
            .. context.directory
            .. "' > '"
            .. xdg_state
            .. "/ecosystem/yazi_command'",
        function()
            events.trigger("ecosystem_workspace_changed", {
                workspace = workspace_id,
                context = context,
            })
        end
    )
end

-- Simplified git context coordination - robust single query
function M.update_git_context()
    local cached_git = performance.cache_get("git_status")
    if cached_git then
        M.git_status_cache = cached_git
        events.trigger("ecosystem_git_updated", cached_git)
        return
    end

    -- Single robust git query using XDG-compliant yazi directory tracking
    local home = os.getenv("HOME")
    local xdg_state = os.getenv("XDG_STATE_HOME") or home .. "/.local/state"

    sbar.exec(
        "cd \"$(cat '"
            .. xdg_state
            .. "/ecosystem/yazi_cwd' 2>/dev/null || echo ~)\" && git rev-parse --show-toplevel 2>/dev/null && git status --porcelain -b 2>/dev/null",
        function(git_output)
            if git_output and git_output ~= "" then
                local lines = {}
                for line in git_output:gmatch("[^\n]+") do
                    table.insert(lines, line)
                end

                local git_root = lines[1] or ""
                local branch_line = lines[2] or ""

                local git_data = {
                    root = git_root,
                    branch = branch_line:match("## ([^%s%.%.]*)") or "main",
                    changes = #lines > 2,
                }

                M.git_status_cache = git_data
                performance.cache_set("git_status", git_data, 5)
                events.trigger("ecosystem_git_updated", git_data)
            end
        end
    )
end

-- Ecosystem state synchronization - coordinates all tool states
function M.sync_ecosystem_state()
    if not M.ecosystem_ready then
        return
    end

    -- Get current yabai workspace
    performance.yabai_query_cached("--spaces --space", 3, function(space_data)
        if space_data and space_data.index then
            M.coordinate_workspace_change(space_data.index)
        end
    end)

    -- Update git context
    M.update_git_context()

    -- Trigger ecosystem synchronization event
    events.trigger("ecosystem_sync_complete", M.current_context)
end

-- Register ecosystem-wide event handlers
function M.register_ecosystem_events()
    -- Workspace change coordination
    events.register("yabai_space_changed", function(data)
        M.coordinate_workspace_change(data.space_id)
    end, 95)

    -- Window focus coordination
    events.register("yabai_window_focused", function(data)
        performance.debounce(function()
            M.update_git_context()
        end, 0.5, "git_context_update")
    end, 90)

    -- Cross-tool communication events (foundation for complex behaviors)
    events.register_custom_event("ecosystem_workspace_changed")
    events.register_custom_event("ecosystem_git_updated")
    events.register_custom_event("ecosystem_file_operation")
    events.register_custom_event("ecosystem_context_switched")
end

-- Initialize ecosystem coordination
function M.init()
    -- Check for ecosystem readiness using window-manager.nix markers
    local home = os.getenv("HOME")
    local readiness_path = home .. "/.local/state/wm/wm-core-ready"

    sbar.exec("test -f " .. readiness_path, function(result, exit_code)
        M.ecosystem_ready = (exit_code == 0)

        if M.ecosystem_ready then
            M.init_workspace_contexts()
            M.register_ecosystem_events()

            -- Initial ecosystem synchronization
            sbar.delay(1.0, function()
                M.sync_ecosystem_state()
            end)
        end
    end)
end

return M
