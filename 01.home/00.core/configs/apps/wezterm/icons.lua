-- Title         : icons.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/wezterm/icons.lua
-- ----------------------------------------------------------------------------
-- Icon definitions for WezTerm interface elements

local wezterm = require("wezterm")

local M = {}

-- Icons ────────────────────────────────────────────────────────────────────
M.icons = {
    process = {
        -- Shells
        ["zsh"] = wezterm.nerdfonts.md_terminal,
        ["bash"] = wezterm.nerdfonts.md_terminal,
        ["fish"] = wezterm.nerdfonts.md_terminal,
        -- Development Tools
        ["cargo"] = wezterm.nerdfonts.dev_rust,
        ["git"] = wezterm.nerdfonts.dev_git,
        ["go"] = wezterm.nerdfonts.seti_go,
        ["lua"] = wezterm.nerdfonts.seti_lua,
        ["node"] = wezterm.nerdfonts.md_hexagon,
        ["python"] = wezterm.nerdfonts.dev_python,
        ["python3"] = wezterm.nerdfonts.dev_python,
        ["ruby"] = wezterm.nerdfonts.dev_ruby_rough,
        -- Text Editors
        ["nvim"] = wezterm.nerdfonts.custom_vim,
        ["vim"] = wezterm.nerdfonts.dev_vim,
        ["code"] = wezterm.nerdfonts.md_microsoft_visual_studio_code,
        ["emacs"] = wezterm.nerdfonts.custom_emacs,
        -- Container and Cloud Tools
        ["docker"] = wezterm.nerdfonts.linux_docker,
        ["docker-compose"] = wezterm.nerdfonts.linux_docker,
        ["kubectl"] = wezterm.nerdfonts.md_kubernetes,
        -- Utilities
        ["xh"] = wezterm.nerdfonts.md_waves,
        ["gh"] = wezterm.nerdfonts.dev_github_badge,
        ["make"] = wezterm.nerdfonts.seti_makefile,
        ["sudo"] = wezterm.nerdfonts.fa_hashtag,
        ["lazygit"] = wezterm.nerdfonts.dev_github_alt,
        ["htop"] = wezterm.nerdfonts.md_chart_line,
        ["btop"] = wezterm.nerdfonts.md_chart_areaspline,
        -- Additional utilities
        ["ssh"] = wezterm.nerdfonts.md_ssh,
        ["tmux"] = wezterm.nerdfonts.cod_terminal_tmux,
        ["less"] = wezterm.nerdfonts.md_file_document,
        ["man"] = wezterm.nerdfonts.md_book_open_variant,
        -- File managers
        ["yazi"] = wezterm.nerdfonts.md_file_tree,
    },
    directory = {
        home = wezterm.nerdfonts.md_home,
        config = wezterm.nerdfonts.md_cog,
        git = wezterm.nerdfonts.dev_git,
        download = wezterm.nerdfonts.md_download,
        documents = wezterm.nerdfonts.md_file_document_box,
        images = wezterm.nerdfonts.md_image,
        video = wezterm.nerdfonts.md_video,
        music = wezterm.nerdfonts.md_music,
        desktop = wezterm.nerdfonts.md_desktop_mac,
        code = wezterm.nerdfonts.md_code_braces,
    },
    ui = {
        zoom = wezterm.nerdfonts.md_magnify,
        workspace = wezterm.nerdfonts.cod_window,
    },
}

return M
