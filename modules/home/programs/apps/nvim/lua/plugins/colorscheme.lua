-- Title         : colorscheme.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : modules/home/programs/apps/nvim/lua/plugins/colorscheme.lua
-- ----------------------------------------------------------------------------
-- Dracula colorscheme remapped to the Forge palette, then the generated
-- syntax projection (forge/syntax.lua: owner scope table -> treesitter
-- captures, role rows -> diagnostics/floats/Pmenu/statuscolumn) applies on
-- top. No hex lives here; every value arrives from the theme owner.

local palette = require("forge.palette")
local syntax = require("forge.syntax")

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

local function style_flags(style)
    return {
        italic = style:find("italic") and true or nil,
        bold = style:find("bold") and true or nil,
    }
end

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

    -- Treesitter captures project from the owner scope table; a hue rebind in
    -- the theme owner lands here with zero edits. Hierarchical fallback covers
    -- capture subgroups (@keyword.return -> @keyword).
    for _, row in ipairs(syntax.scopes) do
        local flags = style_flags(row.style)
        for _, capture in ipairs(row.captures) do
            vim.api.nvim_set_hl(0, "@" .. capture, { fg = row.color, italic = flags.italic, bold = flags.bold })
        end
    end

    -- Role rows: diagnostics, floats, completion menu, statuscolumn, diff
    -- fills (background tint, neutral code foreground), and search fills
    -- (warm, distinct from the cool selection slate).
    local roles = syntax.roles
    for name, def in pairs({
        DiagnosticError = { fg = roles.state.danger },
        DiagnosticWarn = { fg = roles.state.warning },
        DiagnosticInfo = { fg = roles.state.info },
        DiagnosticHint = { fg = roles.text.muted },
        DiagnosticUnderlineError = { undercurl = true, sp = roles.state.danger },
        DiagnosticUnderlineWarn = { undercurl = true, sp = roles.state.warning },
        DiagnosticUnderlineInfo = { undercurl = true, sp = roles.state.info },
        DiagnosticUnderlineHint = { undercurl = true, sp = roles.text.muted },
        FloatBorder = { fg = roles.ui.border },
        FloatTitle = { fg = roles.accent.primary, bold = true },
        Pmenu = { bg = roles.surface.overlay, fg = roles.text.primary },
        PmenuSel = { bg = roles.surface.selected },
        PmenuSbar = { bg = roles.surface.overlay },
        PmenuThumb = { bg = roles.surface.selected },
        LineNr = { fg = roles.text.subtle },
        CursorLineNr = { fg = roles.accent.primary, bold = true },
        DiffAdd = { bg = roles.diff.add },
        DiffDelete = { bg = roles.diff.del, fg = roles.state.danger },
        DiffChange = { bg = roles.diff.change },
        DiffText = { bg = roles.diff.changeEmph },
        Search = { bg = roles.ui.search },
        IncSearch = { bg = roles.ui.match, fg = roles.text.primary },
        CurSearch = { bg = roles.ui.match, fg = roles.text.primary },
        Whitespace = { fg = roles.ui.whitespace },
        SnacksIndent = { fg = roles.ui.indent },
        -- Hunk signs ride the owner git-state vocabulary — the same hues the
        -- VS Code and WezTerm gutters read; dracula links them to Diff* tints.
        GitSignsAdd = { fg = roles.git.added },
        GitSignsChange = { fg = roles.git.modified },
        GitSignsDelete = { fg = roles.git.deleted },
        GitSignsUntracked = { fg = roles.git.untracked },
    }) do
        vim.api.nvim_set_hl(0, name, def)
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
