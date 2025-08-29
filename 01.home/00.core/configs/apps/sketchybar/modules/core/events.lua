-- Title         : events.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/sketchybar/modules/core/events.lua
-- ----------------------------------------------------------------------------
-- Centralized event management with yabai integration and custom events

local M = {
    handlers = {},
    custom_events = {},
    yabai_ready = false,
    readiness_checked = false,
}

-- Check yabai readiness using window-manager.nix coordination markers
function M.check_yabai_readiness()
    if M.readiness_checked then
        return M.yabai_ready
    end

    local home = os.getenv("HOME")
    local marker_path = home .. "/.local/state/wm/yabai-ready"

    sbar.exec("test -f " .. marker_path, function(result, exit_code)
        M.yabai_ready = (exit_code == 0)
        M.readiness_checked = true
    end)

    return M.yabai_ready
end

-- Register event handler with priority support (Tier 2 anticipation)
function M.register(event_name, handler, priority)
    priority = priority or 0

    if not M.handlers[event_name] then
        M.handlers[event_name] = {}
    end

    table.insert(M.handlers[event_name], { handler = handler, priority = priority })

    -- Sort by priority (higher priority first)
    table.sort(M.handlers[event_name], function(a, b)
        return a.priority > b.priority
    end)
end

-- Trigger custom events with data propagation
function M.trigger(event_name, data)
    data = data or {}

    if M.handlers[event_name] then
        for _, handler_info in ipairs(M.handlers[event_name]) do
            local ok, err = pcall(handler_info.handler, data)
            if not ok then
                print("Event handler error for " .. event_name .. ": " .. tostring(err))
            end
        end
    end
end

-- Register custom event type (foundation for Tier 2 state management)
function M.register_custom_event(event_name)
    M.custom_events[event_name] = true
end

-- yabai signal integration wrapper - extends existing yabairc signals
function M.bridge_yabai_signal(yabai_event, custom_handler)
    M.register(yabai_event, function(env)
        if M.check_yabai_readiness() then
            custom_handler(env)
        end
    end, 100) -- High priority for yabai events
end

-- Initialize event system with existing infrastructure
function M.init()
    -- Bridge existing yabai signals from yabairc (lines 71-75)
    M.register_custom_event("yabai_space_changed")
    M.register_custom_event("yabai_window_focused")

    -- Foundation for Tier 2: state synchronization events
    M.register_custom_event("state_updated")
    M.register_custom_event("config_reloaded")
end

return M
