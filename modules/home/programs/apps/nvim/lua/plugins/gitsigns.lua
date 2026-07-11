-- Title         : gitsigns.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : modules/home/programs/apps/nvim/lua/plugins/gitsigns.lua
-- ----------------------------------------------------------------------------
-- In-buffer git state: sign-column hunks and the per-buffer status facts (b:gitsigns_head, b:gitsigns_status_dict) the statusline consumes — one
-- git engine for signs, branch, and diff counts. Hunk motions/textobject bind in config/keymaps.lua; blame stays with Snacks.git.blame_line;
-- Zellij owns lazygit; stage/reset hunk chords land as apps/chords.nix rows.

-- Sign glyphs project from the owner git-state vocabulary (forge/syntax.lua rows): kind reads from the glyph, staged-ness from the highlight
-- tier, so the gutter speaks the same codicon family as the prompt and yazi linemode. Change+delete renders the conflict glyph.
local git = require("forge.syntax").roles.git
local signs = {
    add = { text = git.added.glyph },
    change = { text = git.modified.glyph },
    delete = { text = git.deleted.glyph },
    topdelete = { text = git.deleted.glyph },
    changedelete = { text = git.conflict.glyph },
    untracked = { text = git.untracked.glyph },
}

require("gitsigns").setup({
    signs = signs,
    signs_staged = signs,
    attach_to_untracked = true,
    current_line_blame = false,
})
