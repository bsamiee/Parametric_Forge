-- Title         : colorscheme.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : modules/home/programs/apps/nvim/lua/plugins/colorscheme.lua
-- ----------------------------------------------------------------------------
-- dracula.nvim over the Forge palette, then the generated syntax projection (forge/syntax.lua: owner scope table -> treesitter captures, role
-- rows -> diagnostics/floats/Pmenu/statuscolumn) as its overrides. No hex lives here; every value arrives from the theme owner.

local palette = require("forge.palette")
local syntax = require("forge.syntax")

local function style_flags(style)
    return {
        italic = style:find("italic") and true or nil,
        bold = style:find("bold") and true or nil,
    }
end

local function overrides()
    local roles = syntax.roles
    -- Diff fills carry a background tint with neutral code foreground; search fills run warm, distinct from the cool selection slate.
    local groups = {
        NormalFloat = { fg = palette.foreground },
        CursorLine = { bg = palette.current_line },
        Visual = { bg = palette.selection },
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
        -- Hunk signs ride the owner git-state vocabulary, overriding dracula's Diff* tints. Staged groups stay UNDEFINED: gitsigns derives every
        -- GitSignsStaged* from its unstaged owner hue at half intensity, and with signs_staged sharing the sign glyphs that dim IS the staged
        -- tier — an explicit Staged* row here would erase the staged/unstaged distinction. Change+delete binds the conflict row to match its
        -- minted glyph.
        GitSignsAdd = { fg = roles.git.added.color },
        GitSignsChange = { fg = roles.git.modified.color },
        GitSignsDelete = { fg = roles.git.deleted.color },
        GitSignsUntracked = { fg = roles.git.untracked.color },
        GitSignsChangedelete = { fg = roles.git.conflict.color },
        -- Dashboard accents follow the variant cyan.
        SnacksDashboardHeader = { fg = palette.cyan },
        SnacksDashboardKey = { fg = palette.cyan },
        SnacksDashboardIcon = { fg = palette.cyan },
    }
    -- Treesitter captures project from the owner scope table; a hue rebind in the theme owner lands here with zero edits. Hierarchical fallback
    -- covers capture subgroups (@keyword.return -> @keyword).
    for _, row in ipairs(syntax.scopes) do
        local flags = style_flags(row.style)
        for _, capture in ipairs(row.captures) do
            groups["@" .. capture] = { fg = row.color, italic = flags.italic, bold = flags.bold }
        end
    end
    return groups
end

-- Palette slots the Forge variant rebinds; every other slot keeps dracula's value. Stock pink is the Forge magenta.
require("dracula").setup({
    transparent_bg = true,
    colors = {
        bg = palette.background,
        fg = palette.foreground,
        selection = palette.selection,
        comment = palette.comment,
        red = palette.red,
        orange = palette.orange,
        yellow = palette.yellow,
        green = palette.green,
        purple = palette.purple,
        cyan = palette.cyan,
        pink = palette.magenta,
        menu = palette.background,
        black = palette.background,
    },
    overrides = overrides(),
})
vim.cmd.colorscheme("dracula")
