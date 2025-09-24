-- Title         : ui.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/nvim/lua/utils/ui.lua
-- ----------------------------------------------------------------------------
-- Shared UI palette and helpers for cohesive floating window styling

local M = {}

M.palette = {
    bg = "#282a36",
    border = "#44475a",
    accent = "#8be9fd",
    text = "#f8f8f2",
    subtle = "#6272a4",
    success = "#50fa7b",
    warning = "#f1fa8c",
    panel = "#1f202e",
    cyan = "#8be9fd",
    green = "#50fa7b",
    orange = "#ffb86c",
    pink = "#ff79c6",
    purple = "#bd93f9",
    red = "#ff5555",
    yellow = "#f1fa8c",
}

--- Apply highlight overrides that keep floating surfaces consistent.
function M.apply_highlights()
    local set = vim.api.nvim_set_hl
    local p = M.palette

    set(0, "NormalFloat", { fg = p.text, bg = p.bg })
    set(0, "FloatBorder", { fg = p.border, bg = p.bg })
    set(0, "FloatTitle", { fg = p.accent, bg = p.bg, bold = true })
    set(0, "FloatFooter", { fg = p.subtle, bg = p.bg, italic = true })

    -- Noice specific groups - border should have NO bg to avoid donut effect
    set(0, "NoicePopup", { fg = p.text, bg = p.panel })
    set(0, "NoicePopupBorder", { fg = p.cyan })
    set(0, "NoiceCmdline", { fg = p.text, bg = p.panel })
    set(0, "NoiceCmdlinePopup", { fg = p.text, bg = p.panel })
    set(0, "NoiceCmdlinePopupBorder", { fg = p.cyan })
    set(0, "NoiceCmdlinePopupTitle", { fg = p.bg, bg = p.cyan, bold = true })
    set(0, "NoiceCmdlineIcon", { fg = p.cyan })
    set(0, "NoiceCmdlinePrompt", { fg = p.text })

    for _, group in ipairs({
        "NoiceCmdlinePopupBorderCalculator",
        "NoiceCmdlinePopupBorderCmdline",
        "NoiceCmdlinePopupBorderFilter",
        "NoiceCmdlinePopupBorderHelp",
        "NoiceCmdlinePopupBorderIncRename",
        "NoiceCmdlinePopupBorderInput",
        "NoiceCmdlinePopupBorderLua",
        "NoiceCmdlinePopupBorderSearch",
    }) do
        set(0, group, { fg = p.cyan })
    end

    for _, group in ipairs({
        "NoiceCmdlineIconCalculator",
        "NoiceCmdlineIconCmdline",
        "NoiceCmdlineIconFilter",
        "NoiceCmdlineIconHelp",
        "NoiceCmdlineIconIncRename",
        "NoiceCmdlineIconInput",
        "NoiceCmdlineIconLua",
        "NoiceCmdlineIconSearch",
    }) do
        set(0, group, { fg = p.cyan })
    end

    set(0, "NoiceLspProgressTitle", { fg = p.accent, bold = true })
    set(0, "NoiceLspProgressSpinner", { fg = p.accent })

    -- Dressing and general popup input styling.
    set(0, "DressingInputFloat", { fg = p.text, bg = p.bg })
    set(0, "DressingInputFloatBorder", { fg = p.border, bg = p.bg })

    -- Edgy layout panels
    set(0, "EdgyNormal", { fg = p.text, bg = p.bg })
    set(0, "EdgyNormalFloat", { fg = p.text, bg = p.bg })
    set(0, "EdgyTitle", { fg = p.accent, bg = p.bg, bold = true })
    set(0, "EdgyIcon", { fg = p.accent, bg = p.bg })
    set(0, "EdgyIconActive", { fg = p.success, bg = p.bg })
    set(0, "EdgySeparator", { fg = p.border, bg = p.bg })
    set(0, "EdgyWinBar", { fg = p.accent, bg = p.bg })
    set(0, "EdgyWinBarNC", { fg = p.subtle, bg = p.bg })

    -- Telescope popup styling
    set(0, "TelescopeNormal", { fg = p.text, bg = p.panel })
    set(0, "TelescopeBorder", { fg = p.cyan, bg = p.panel })
    set(0, "TelescopePromptNormal", { fg = p.text, bg = p.panel })
    set(0, "TelescopePromptBorder", { fg = p.cyan, bg = p.panel })
    set(0, "TelescopePromptTitle", { fg = p.bg, bg = p.cyan })
    set(0, "TelescopePromptPrefix", { fg = p.cyan, bg = p.panel })
    set(0, "TelescopeResultsNormal", { fg = p.text, bg = p.panel })
    set(0, "TelescopeResultsBorder", { fg = p.cyan, bg = p.panel })
    set(0, "TelescopeResultsTitle", { fg = p.subtle, bg = p.panel })
    set(0, "TelescopePreviewNormal", { fg = p.text, bg = p.panel })
    set(0, "TelescopePreviewBorder", { fg = p.cyan, bg = p.panel })
    set(0, "TelescopePreviewTitle", { fg = p.subtle, bg = p.panel })
    set(0, "TelescopeSelection", { fg = p.bg, bg = p.text, bold = true })
    set(0, "TelescopeMatching", { fg = p.purple, bold = true })

    -- Make counters more visible
    set(0, "TelescopePromptCounter", { fg = p.cyan })
    set(0, "TelescopeResultsCounter", { fg = p.cyan })
    set(0, "TelescopePreviewCounter", { fg = p.cyan })

    -- Alpha dashboard styling
    set(0, "AlphaHeader", { fg = p.cyan, bold = true })
    set(0, "AlphaButtons", { fg = p.text })
    set(0, "AlphaFooter", { fg = p.subtle, italic = true })
    set(0, "AlphaShortcut", { fg = p.orange, bold = true })
end

--- Border characters used across popup-enabled plugins (rounded corners).
---@return string[]
function M.borderchars()
    return { "─", "│", "─", "│", "╭", "╮", "╯", "╰" }
end

--- winhighlight string helper to keep consistent highlight links.
---@return string
function M.winhighlight()
    return table.concat({
        "Normal:NormalFloat",
        "FloatBorder:FloatBorder",
        "FloatTitle:FloatTitle",
        "FloatFooter:FloatFooter",
    }, ",")
end

vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function()
        M.apply_highlights()
    end,
})

return M
