-- Title         : performance.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/sketchybar/modules/core/performance.lua
-- ----------------------------------------------------------------------------
-- Performance optimization layer with caching, debouncing, and batch operations

local M = {
    cache = {},
    cache_timestamps = {},
    debounced_funcs = {},
    batch_queue = {},
    batch_timer = nil,
}

-- Cache with TTL - critical for expensive yabai queries from signals
function M.cache_set(key, value, ttl)
    ttl = ttl or 5 -- Default 5 second TTL
    M.cache[key] = value
    M.cache_timestamps[key] = os.time() + ttl
end

function M.cache_get(key)
    local timestamp = M.cache_timestamps[key]
    if timestamp and os.time() < timestamp then
        return M.cache[key]
    end
    -- Cleanup expired cache
    M.cache[key] = nil
    M.cache_timestamps[key] = nil
    return nil
end

-- Cached yabai query wrapper with callback support for robust async handling
function M.yabai_query_cached(query, ttl, callback)
    local cache_key = "yabai:" .. query
    local cached = M.cache_get(cache_key)

    -- Immediate return if cached and no callback needed
    if cached and not callback then
        return cached
    end

    -- If cached and callback provided, use cached data
    if cached and callback then
        callback(cached)
        return cached
    end

    -- Query and cache, then execute callback
    sbar.exec("yabai -m query " .. query, function(result)
        if result and result ~= "" then
            local data = sbar.json and sbar.json.decode(result) or result
            M.cache_set(cache_key, data, ttl or 5)
            if callback then
                callback(data)
            end
        elseif callback then
            callback(nil)
        end
    end)

    return cached -- May be nil, but callback will handle async result
end

-- Professional debounce implementation using SketchyBar's native delay system
function M.debounce(func, delay, key)
    key = key or tostring(func)
    delay = delay or 0.1

    -- Cancel existing debounced execution
    if M.debounced_funcs[key] then
        M.debounced_funcs[key].cancelled = true
    end

    -- Create execution context
    local execution_context = { cancelled = false }
    M.debounced_funcs[key] = execution_context

    -- Use SketchyBar's native delay system (clean, no namespace pollution)
    sbar.delay(delay, function()
        if not execution_context.cancelled then
            M.debounced_funcs[key] = nil
            func()
        end
    end)
end

-- Batch SketchyBar operations - foundation for Tier 2 mass updates
function M.batch_update(updates)
    for item_name, config in pairs(updates) do
        table.insert(M.batch_queue, { item = item_name, config = config })
    end

    M.flush_batch()
end

function M.flush_batch()
    if #M.batch_queue == 0 then
        return
    end

    -- Process batch efficiently
    for _, update in ipairs(M.batch_queue) do
        sbar.set(update.item, update.config)
    end

    M.batch_queue = {}
end

-- System stats integration with window-manager.nix system-stats service
function M.get_system_stats(callback)
    local cached = M.cache_get("system_stats")
    if cached then
        callback(cached)
        return
    end

    -- Integration with sketchybar-system-stats from window-manager.nix
    sbar.exec("ps aux | grep sketchybar-system-stats | grep -v grep", function(result)
        if result and result ~= "" then
            -- System stats service is running, data available via events
            callback({ available = true, source = "service" })
        else
            -- Fallback to direct queries
            callback({ available = false, source = "fallback" })
        end
    end)
end

return M
