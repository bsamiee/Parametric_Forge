-- Title         : .luacheckrc
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/languages/.luacheckrc
-- ----------------------------------------------------------------------------
-- Global luacheck configuration for consistent Lua code quality

-- Standard library globals - "lua54" for Lua 5.4 environment
std = "lua54"

-- Performance optimization
cache = true
jobs = 4

-- Output preferences
codes = true -- Show warning codes for easier reference
color = true -- Enable colored output

-- Code quality settings
unused_args = false -- Allow unused args in callbacks (common pattern)
unused_secondaries = false -- Allow unused secondary values from multiple assignments

-- Global variables allowed across all Lua files
globals = {
  -- Remove unnecessary globals - these aren't actually used in our codebase
}

-- More targeted ignore list based on actual needs
ignore = {
  "212", -- Unused argument (common in callback functions)
  "213", -- Unused loop variable (common in iterators)
  "631", -- Line too long (stylua handles formatting)
  "614", -- Trailing whitespace in comment (stylua handles this)
}

-- File-specific configurations
files = {
  -- WezTerm configuration
  ["**/wezterm.lua"] = {
    globals = {
      "wezterm",
    },
  },

  -- Yazi configuration
  ["**/yazi/**/*.lua"] = {
    globals = {
      "ya", "Command", "Child", "cx", "ui", "Status", "Linemode",
      -- Custom functions defined in init.lua
      "smart_open", "smart_paste", "bookmark_jump", "cd_git_root",
      "create_archive", "setup_large_dir_handling", "safe_remove",
      "safe_bulk_rename", "sync_session", "enhanced_search", "quick_diff",
      "lazy_git_integration", "smart_sudo_operations", "ecosystem_cd",
      "notify_ecosystem_directory_change", "adjust_layout",
    },
  },

  -- Hammerspoon configuration
  ["**/hammerspoon/**/*.lua"] = {
    globals = {
      -- Core Hammerspoon API (available globally in Hammerspoon)
      "hs", "spoon",
      -- Intentional global exports from init.lua (module system)
      "mods", "forge",
    },
  },


  -- LuaRocks configuration
  ["**/luarocks.lua"] = {
    globals = {
      "rocks_servers", "deps_mode", "local_by_default",
    },
  },

  -- Test files (Busted framework)
  ["**/spec/**/*.lua"] = {
    globals = {
      "describe", "it", "before_each", "after_each", "setup",
      "teardown", "pending", "finally",
    },
  },

  ["**/test/**/*.lua"] = {
    globals = {
      "describe", "it", "before_each", "after_each", "setup",
      "teardown", "pending", "finally",
    },
  },
}

-- Code complexity limits
max_line_length = false -- Let stylua handle line length
max_cyclomatic_complexity = 15 -- Reasonable complexity limit
