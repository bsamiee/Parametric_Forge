-- Title         : colorscheme.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : modules/home/programs/apps/nvim/lua/plugins/colorscheme.lua
-- ----------------------------------------------------------------------------
-- Dracula colorscheme remapped to the Forge palette (forge/palette.lua)

local palette = require("forge.palette")

local int = function(hex)
    return tonumber(hex:sub(2), 16)
end

-- Stock dracula/vim values -> Forge variant; applied over every
-- highlight group so linked and direct definitions both follow.
local remap = {
    [0x282A36] = int(palette.background),
    [0x21222C] = int(palette.background),
    [0x191A21] = int(palette.background),
    [0x343746] = int(palette.current_line),
    [0x424450] = int(palette.selection),
    [0x8BE9FD] = int(palette.cyan),
    [0xBD93F9] = int(palette.purple),
    [0xFFB86C] = int(palette.orange),
    [0xFF79C6] = int(palette.magenta),
}

local apply = function()
    for name, def in pairs(vim.api.nvim_get_hl(0, {})) do
        if not def.link then
            local changed = false
            for _, key in ipairs({ "fg", "bg", "sp" }) do
                local hit = def[key] and remap[def[key]]
                if hit then
                    def[key] = hit
                    changed = true
                end
            end
            if changed then
                vim.api.nvim_set_hl(0, name, def)
            end
        end
    end
    -- Transparency
    vim.cmd("highlight Normal guibg=NONE ctermbg=NONE")
    vim.cmd("highlight NormalFloat guibg=NONE ctermbg=NONE")
    vim.cmd("highlight SignColumn guibg=NONE ctermbg=NONE")
    -- Dashboard accents follow the variant cyan
    vim.api.nvim_set_hl(0, "SnacksDashboardHeader", { fg = palette.cyan })
    vim.api.nvim_set_hl(0, "SnacksDashboardKey", { fg = palette.cyan })
    vim.api.nvim_set_hl(0, "SnacksDashboardIcon", { fg = palette.cyan })
end

vim.api.nvim_create_autocmd("ColorScheme", {
    pattern = "dracula",
    callback = apply,
})
vim.cmd.colorscheme("dracula")
