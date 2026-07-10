-- Title         : health.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : modules/home/programs/apps/nvim/lua/forge/health.lua
-- ----------------------------------------------------------------------------
-- :checkhealth forge — proves plugin store paths, server commands, parsers, formatter/linter binaries, estate action rows, Claude LSP marketplace
-- parity (tracked file AND the installed cache copy Claude actually loads), generated nixd expressions, and
-- provider resolution against the generated fact modules.

local M = {}
local health = vim.health

local function executable(name)
    return vim.fn.executable(name) == 1
end

local function read_json(path)
    local fd = io.open(path, "r")
    if not fd then
        return nil
    end
    local ok, doc = pcall(vim.json.decode, fd:read("*a"))
    fd:close()
    return ok and doc or nil
end

-- Identity dimensions of one marketplace server entry vs the generated row.
local function identity_match(live, want)
    return live.command == want.command
        and vim.deep_equal(live.args or {}, want.args or {})
        and vim.deep_equal(live.extensionToLanguage, want.extensionToLanguage)
        and vim.deep_equal(live.settings, want.settings)
end

function M.check()
    local tools = require("forge.tools")
    local lsp = require("forge.lsp")

    health.start("plugin store paths")
    for _, row in ipairs(tools.plugins) do
        if vim.uv.fs_stat(row.path) then
            health.ok(("%s -> %s"):format(row.name, row.path))
        else
            health.error(("%s missing store path %s"):format(row.name, row.path))
        end
    end

    health.start("treesitter parsers")
    for _, lang in ipairs(tools.grammars) do
        if pcall(vim.treesitter.language.add, lang) then
            health.ok(lang)
        else
            health.error(("parser missing: %s"):format(lang))
        end
    end

    health.start("lsp server commands")
    for name, row in pairs(lsp.servers) do
        if executable(row.cmd[1]) then
            health.ok(("%s (%s)"):format(name, table.concat(row.cmd, " ")))
        else
            health.error(("%s command not resolvable: %s"):format(name, row.cmd[1]))
        end
    end

    -- Formatter rows resolve through conform's own definitions (command + availability), so name/binary divergence (ruff_format -> ruff) never needs restating.
    health.start("formatter binaries")
    local formatters = {}
    for _, names in pairs(tools.format) do
        for _, name in ipairs(names) do
            formatters[name] = true
        end
    end
    for name in vim.spairs(formatters) do
        local info = require("conform").get_formatter_info(name)
        if info.available then
            health.ok(("%s (%s)"):format(name, info.command))
        else
            health.error(("%s unavailable: %s"):format(name, info.available_msg or "no definition"))
        end
    end

    -- tbl_extend("error") faults if an ft row ever collides with a lane name.
    local linters = {}
    local lint_lanes = { global = tools.lint.global, workflow = tools.lint.workflow }
    for _, names in pairs(vim.tbl_extend("error", lint_lanes, tools.lint.ft)) do
        for _, name in ipairs(names) do
            linters[name] = true
        end
    end
    health.start("linter lane")
    for name in vim.spairs(linters) do
        local defined, def = pcall(require, "lint.linters." .. name)
        if not defined then
            health.error(("nvim-lint has no definition for %s"):format(name))
        else
            local cmd = type(def.cmd) == "function" and def.cmd() or def.cmd
            if executable(cmd) then
                health.ok(("%s (%s)"):format(name, cmd))
            else
                health.error(("%s command not resolvable: %s"):format(name, cmd))
            end
        end
    end

    health.start("estate action rows")
    local estate_bins = {}
    for _, row in ipairs(tools.estate) do
        for _, bin in ipairs(row.probes or { row.argv[1] }) do
            estate_bins[bin] = true
        end
    end
    for bin in vim.spairs(estate_bins) do
        if executable(bin) then
            health.ok(bin)
        else
            health.error(("%s not resolvable on PATH"):format(bin))
        end
    end

    -- Two consumed surfaces per plugin: the tracked marketplace file and the installed cache copy Claude Code actually loads (directory
    -- marketplaces copy on install; only an explicit marketplace update refreshes them).
    health.start("claude lsp parity")
    local generated = vim.fn.stdpath("config"):gsub("/nvim$", "") .. "/forge/lsp/claude-marketplace.json"
    local rows = read_json(generated)
    if not rows then
        health.error("generated parity projection missing: " .. generated)
    else
        local installed = read_json(vim.env.HOME .. "/.claude/plugins/installed_plugins.json")
        for plugin, want in pairs(rows) do
            local tracked = read_json(("%s/.claude/lsp-marketplace/%s/.lsp.json"):format(tools.flake_root, plugin))
            if not tracked then
                health.error(("marketplace entry missing: %s/.claude/lsp-marketplace/%s/.lsp.json"):format(tools.flake_root, plugin))
            else
                local _, live = next(tracked)
                if identity_match(live, want) then
                    health.ok(plugin .. " (tracked)")
                else
                    health.error(("identity drift: %s tracked file differs from generated rows"):format(plugin))
                end
            end
            local record = installed and installed.plugins and installed.plugins[plugin .. "@forge-lsp"]
            local cached = record and record[1] and read_json(record[1].installPath .. "/.lsp.json")
            if not cached then
                health.warn(("%s not installed in Claude Code (claude plugin install %s@forge-lsp)"):format(plugin, plugin))
            else
                local _, live = next(cached)
                if identity_match(live, want) then
                    health.ok(plugin .. " (installed cache)")
                else
                    health.error(("stale consumed cache: %s — run `claude plugin update %s@forge-lsp`"):format(plugin, plugin))
                end
            end
        end
    end

    health.start("nixd generated expressions")
    local nixd = lsp.servers.nixd.settings.nixd
    if nixd and nixd.nixpkgs and nixd.nixpkgs.expr ~= "" and nixd.options then
        health.ok(("option sets: %s"):format(table.concat(vim.tbl_keys(nixd.options), ", ")))
    else
        health.error("nixd option expressions absent from generated rows")
    end
    if vim.uv.fs_stat(tools.flake_root .. "/flake.nix") then
        health.ok("flake root present: " .. tools.flake_root)
    else
        health.error("flake root missing: " .. tools.flake_root)
    end

    health.start("python provider (uv tool lane)")
    if vim.uv.fs_stat(tools.provider.python3) then
        health.ok(tools.provider.python3)
    else
        health.warn("pynvim shim missing; activation row installs it: uv tool install pynvim")
    end
end

return M
