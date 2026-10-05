-- Title         : health.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : modules/home/programs/apps/nvim/lua/estate/health.lua
-- ----------------------------------------------------------------------------
-- :checkhealth estate — proves each generated Forge fact module resolves against the live editor surface it projects.

local M = {}
local health = vim.health

local function executable(name)
    return vim.fn.executable(name) == 1
end

function M.check()
    local tools = require("estate.tools")
    local lsp = require("estate.lsp")

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
end

return M
