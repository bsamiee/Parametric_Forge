-- Title         : utils.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/sketchybar/modules/helpers/utils.lua
-- ----------------------------------------------------------------------------
-- Utility functions for SketchyBar configuration

local M = {}

-- Execute shell command with callback
function M.exec(command, callback)
  sbar.exec(command, callback)
end

-- Get percentage color based on thresholds
function M.get_percentage_color(value, colors, thresholds)
  thresholds = thresholds or {high = 80, medium = 50}

  if value > thresholds.high then
    return colors.high or colors.error
  elseif value > thresholds.medium then
    return colors.medium or colors.warning
  else
    return colors.low or colors.success
  end
end

-- Format bytes to human readable
function M.format_bytes(bytes)
  local units = {"B", "KB", "MB", "GB", "TB"}
  local size = bytes
  local unit_index = 1

  while size >= 1024 and unit_index < #units do
    size = size / 1024
    unit_index = unit_index + 1
  end

  return string.format("%.1f%s", size, units[unit_index])
end

-- Round number to specified decimal places
function M.round(num, decimals)
  local mult = 10 ^ (decimals or 0)
  return math.floor(num * mult + 0.5) / mult
end

-- Check if command exists in PATH
function M.command_exists(command)
  local result = nil
  sbar.exec("command -v " .. command, function(output)
    result = output and output ~= ""
  end)
  return result
end

-- Throttle function calls
function M.throttle(func, delay)
  local last_call = 0
  return function(...)
    local now = os.time()
    if now - last_call >= delay then
      last_call = now
      func(...)
    end
  end
end

-- Clamp value between min and max
function M.clamp(value, min, max)
  return math.max(min, math.min(max, value))
end

-- Split string by delimiter
function M.split(str, delimiter)
  local result = {}
  local pattern = "(.-)" .. delimiter
  local last_end = 1
  local s, e, cap = str:find(pattern, 1)

  while s do
    if s ~= 1 or cap ~= "" then
      table.insert(result, cap)
    end
    last_end = e + 1
    s, e, cap = str:find(pattern, last_end)
  end

  if last_end <= #str then
    cap = str:sub(last_end)
    table.insert(result, cap)
  end

  return result
end

-- Trim whitespace from string
function M.trim(str)
  return str:match("^%s*(.-)%s*$")
end

return M