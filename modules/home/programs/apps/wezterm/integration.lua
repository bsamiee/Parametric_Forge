-- Title         : integration.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : modules/home/programs/apps/wezterm/integration.lua
-- ----------------------------------------------------------------------------
-- Zellij integration and external tool configuration

local paths = require("paths")

local M = {}

function M.setup(config)
  -- Zellij Attach -------------------------------------------------------------
  -- paths.zellij is the generation-rooted store binary; no probe chain needed.
  local layout = os.getenv("ZELLIJ_DEFAULT_LAYOUT") or "default"
  config.default_prog = { paths.zellij, "--layout", layout, "attach", "--create", "main" }

  -- PATH Configuration --------------------------------------------------------
  -- paths.path is the toolchain-env owner vector; ambient PATH appends so a
  -- shell-launched WezTerm keeps caller-provided entries.
  local ambient = os.getenv("PATH")
  config.set_environment_variables = {
    PATH = (ambient and ambient ~= "") and (paths.path .. ":" .. ambient) or paths.path,
  }

  -- Tab Bar Configuration -----------------------------------------------------
  config.enable_tab_bar = false -- Zellij renders tabs; hide WezTerm's tab bar
  config.use_fancy_tab_bar = false
end

return M
