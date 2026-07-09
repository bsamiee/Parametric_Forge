-- Title         : lsp.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : modules/home/programs/apps/nvim/lua/config/lsp.lua
-- ----------------------------------------------------------------------------
-- Native LSP control plane over generated forge/lsp.lua rows (owner:
-- apps/nvim/default.nix). Native completion with autotrigger is the decided
-- lane (blink.cmp stays annex-gated); diagnostics render through one config.

for name, row in pairs(require("forge.lsp").servers) do
    vim.lsp.config(name, {
        cmd = row.cmd,
        filetypes = row.filetypes,
        root_markers = row.root_markers,
        settings = row.settings,
    })
    vim.lsp.enable(name)
end

vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("forge_lsp_attach", { clear = true }),
    callback = function(ev)
        local client = assert(vim.lsp.get_client_by_id(ev.data.client_id))
        if client:supports_method("textDocument/completion") then
            vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
        end
    end,
})

vim.diagnostic.config({
    severity_sort = true,
    virtual_text = { source = "if_many" },
    float = { border = "rounded", source = "if_many" },
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = "●",
            [vim.diagnostic.severity.WARN] = "▲",
            [vim.diagnostic.severity.INFO] = "◆",
            [vim.diagnostic.severity.HINT] = "○",
        },
    },
})
