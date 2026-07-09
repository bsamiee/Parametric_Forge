-- Title         : health.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : modules/home/programs/apps/nvim/lua/forge/health.lua
-- ----------------------------------------------------------------------------
-- :checkhealth forge — proves plugin store paths, server commands, parsers,
-- formatter/linter binaries, Claude LSP marketplace parity, generated nixd
-- expressions, and provider resolution against the generated fact modules.

local M = {}
local health = vim.health

local function executable(name)
    return vim.fn.executable(name) == 1
end

local function check_commands(title, names)
    health.start(title)
    for _, name in ipairs(names) do
        if executable(name) then
            health.ok(name)
        else
            health.error(("%s not resolvable on PATH"):format(name))
        end
    end
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

    local formatters = {}
    for _, names in pairs(tools.format) do
        for _, name in ipairs(names) do
            formatters[name:gsub("^ruff_.*", "ruff")] = true
        end
    end
    check_commands("formatter binaries", vim.tbl_keys(formatters))

    local linters = {}
    for _, names in pairs(tools.lint) do
        for _, name in ipairs(names) do
            linters[name] = true
        end
    end
    health.start("linter lane")
    for name in pairs(linters) do
        local defined = pcall(require, "lint.linters." .. name)
        if not defined then
            health.error(("nvim-lint has no definition for %s"):format(name))
        elseif executable(name) then
            health.ok(name)
        else
            health.error(("%s not resolvable on PATH"):format(name))
        end
    end

    health.start("claude lsp parity")
    local generated = vim.fn.stdpath("config"):gsub("/nvim$", "") .. "/forge/lsp/claude-marketplace.json"
    local gen_fd = io.open(generated, "r")
    if not gen_fd then
        health.error("generated parity projection missing: " .. generated)
    else
        local rows = vim.json.decode(gen_fd:read("*a"))
        gen_fd:close()
        for plugin, want in pairs(rows) do
            local path = ("%s/.claude/lsp-marketplace/%s/.lsp.json"):format(tools.flake_root, plugin)
            local fd = io.open(path, "r")
            if not fd then
                health.error(("marketplace entry missing: %s"):format(path))
            else
                local doc = vim.json.decode(fd:read("*a"))
                fd:close()
                local _, live = next(doc)
                local same = live.command == want.command
                    and vim.deep_equal(live.args or {}, want.args or {})
                    and vim.deep_equal(live.extensionToLanguage, want.extensionToLanguage)
                    and vim.deep_equal(live.settings, want.settings)
                if same then
                    health.ok(plugin)
                else
                    health.error(("identity drift: %s (command/args/extensions/settings differ from generated rows)"):format(plugin))
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
