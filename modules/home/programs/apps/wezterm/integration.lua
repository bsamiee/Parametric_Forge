-- Title         : integration.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : modules/home/programs/apps/wezterm/integration.lua
-- ----------------------------------------------------------------------------
-- Zellij integration and external tool configuration

local wezterm = require("wezterm")

local M = {}

function M.setup(config)
  -- Core Integration ---------------------------------------------------------
  local home = wezterm.home_dir
  local user = os.getenv("USER") or ""
  local candidates = {
    home and (home .. "/.nix-profile/bin/zellij") or nil,
    user ~= "" and ("/etc/profiles/per-user/" .. user .. "/bin/zellij") or nil,
    "/run/current-system/sw/bin/zellij",
    "/nix/profile/bin/zellij",
    "/opt/homebrew/bin/zellij",
    "/usr/local/bin/zellij",
  }

  local zellij = "zellij"
  for _, p in ipairs(candidates) do
    if p then
      local f = io.open(p, "r")
      if f then f:close(); zellij = p; break end
    end
  end

  -- Launch Zellij in a new WezTerm window with layout
  local layout = os.getenv("ZELLIJ_DEFAULT_LAYOUT") or "default"
  config.default_prog = { zellij, "--layout", layout, "attach", "--create", "main" }

  -- PATH Configuration -------------------------------------------------------
  local path_segments = {}
  if home then
    table.insert(path_segments, home .. "/.local/bin")
    table.insert(path_segments, home .. "/bin")
    table.insert(path_segments, home .. "/.nix-profile/bin")
  end
  if user ~= "" then table.insert(path_segments, "/etc/profiles/per-user/" .. user .. "/bin") end
  for _, p in ipairs({
    "/run/current-system/sw/bin",
    "/nix/profile/bin",
    "/opt/homebrew/bin",
    "/usr/local/bin",
    "/usr/bin",
    "/bin",
    "/usr/sbin",
    "/sbin",
  }) do
    table.insert(path_segments, p)
  end

  local existing_path = os.getenv("PATH")
  if existing_path and existing_path ~= "" then
    table.insert(path_segments, existing_path)
  end

  -- Set PATH to ensure Zellij can find all Nix-installed binaries including yazi
  config.set_environment_variables = {
    PATH = table.concat(path_segments, ":"),
  }

  -- Tab Bar Configuration ----------------------------------------------------
  config.enable_tab_bar = false -- Zellij will render tabs; hide WezTerm's tab bar
  config.use_fancy_tab_bar = false
end

return M
