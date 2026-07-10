-- Title         : gitsigns.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : modules/home/programs/apps/nvim/lua/plugins/gitsigns.lua
-- ----------------------------------------------------------------------------
-- In-buffer git state: sign-column hunks and the per-buffer status facts (b:gitsigns_head, b:gitsigns_status_dict) the statusline consumes — one
-- git engine for signs, branch, and diff counts. Hunk motions/textobject bind in config/keymaps.lua; blame stays with Snacks.git.blame_line;
-- Zellij owns lazygit; stage/reset hunk chords land as apps/chords.nix rows.

require("gitsigns").setup({
    attach_to_untracked = true,
    current_line_blame = false,
})
