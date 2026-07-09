-- Title         : lint.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : modules/home/programs/apps/nvim/lua/plugins/lint.lua
-- ----------------------------------------------------------------------------
-- Non-LSP diagnostic lane over generated linter rows (forge/tools.lua):
-- spawn-parse-publish through vim.diagnostic with namespace separation from
-- LSP. GitHub Actions lanes gate on the workflow path, never plain yaml.

local lint = require("lint")
local rows = require("forge.tools").lint

local by_ft = {
    nix = rows.nix,
    sh = rows.sh,
    bash = rows.bash,
    python = rows.python,
    yaml = rows.yaml,
    dockerfile = rows.dockerfile,
}

local function names_for(buf)
    local names = vim.deepcopy(by_ft[vim.bo[buf].filetype] or {})
    vim.list_extend(names, rows.global)
    if vim.api.nvim_buf_get_name(buf):match("%.github/workflows/") then
        vim.list_extend(names, rows.workflow)
    end
    return names
end

vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
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
