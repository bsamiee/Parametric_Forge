-- Title         : luarocks.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : 01.home/00.core/configs/languages/luarocks.lua
-- ----------------------------------------------------------------------------
-- LuaRocks configuration for package management

-- --- Repository Servers -----------------------------------------------------
-- Default server is automatically included, adding moonrocks as secondary
rocks_servers = {
    "https://luarocks.org",
    "https://raw.githubusercontent.com/rocks-moonscript/moonrocks-mirror/master/",
}

-- --- Dependency Resolution Mode ---------------------------------------------
-- "one": Consider only the first tree (cleaner for user installs)
-- "all": Consider all trees (default)
-- "order": Consider trees in order
deps_mode = "one"

-- --- Local Installation by Default ------------------------------------------
-- Prefer user-local installations over system-wide
local_by_default = true
