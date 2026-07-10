-- Title         : lint.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : modules/home/programs/apps/nvim/lua/plugins/lint.lua
-- ----------------------------------------------------------------------------
-- Non-LSP diagnostic lane over generated linter rows (forge/tools.lua): spawn-parse-publish through vim.diagnostic with namespace separation from LSP.
-- Filetype lanes index rows directly — a new Nix lint row lands with zero edits here. GitHub Actions lanes gate on workflow path, never plain yaml.

local lint = require("lint")
local rows = require("forge.tools").lint

-- Resolvability cache keyed on the linter definition's own cmd: an unresolvable or undefined linter degrades to silence (nvim-lint would ERROR-notify
-- per event); :checkhealth forge owns the availability proof.
local resolvable = setmetatable({}, {
    __index = function(cache, name)
        local ok, def = pcall(require, "lint.linters." .. name)
        local cmd = ok and (type(def.cmd) == "function" and def.cmd() or def.cmd)
        cache[name] = cmd and vim.fn.executable(cmd) == 1 or false
        return cache[name]
    end,
})

local function names_for(buf)
    local names = vim.deepcopy(rows.ft[vim.bo[buf].filetype] or {})
    vim.list_extend(names, rows.global)
    if vim.api.nvim_buf_get_name(buf):match("%.github/workflows/") then
        vim.list_extend(names, rows.workflow)
    end
    return vim.tbl_filter(function(name)
        return resolvable[name]
    end, names)
end

-- FileType (not BufReadPost): init-registered read autocmds run before filetype detection, so the filetype lane would resolve empty on open.
vim.api.nvim_create_autocmd({ "FileType", "BufWritePost", "InsertLeave" }, {
    group = vim.api.nvim_create_augroup("forge_lint", { clear = true }),
    callback = function(ev)
        if vim.bo[ev.buf].modifiable and vim.bo[ev.buf].buftype == "" then
            local names = names_for(ev.buf)
            if #names > 0 then
                lint.try_lint(names)
            end
        end
    end,
})
