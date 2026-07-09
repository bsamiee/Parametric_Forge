# Title         : theme.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/yazi/theme.nix
# ----------------------------------------------------------------------------
# Nix-generated Yazi theme from the estate palette owner; syntect preview
# highlighting consumes the owner's shared tmTheme artifact and directory
# icons project from the shared icon vocabulary
{
  config,
  lib,
  ...
}: let
  p = config.forge.theme.palette;
  dirIcons = lib.concatStringsSep "\n" (lib.mapAttrsToList (
      name: row: ''{ name = "${name}", text = "${row.glyph}", fg = "${row.color.hex}" },''
    )
    config.forge.theme.icons.dirs);
in {
  xdg.configFile."yazi/theme.toml".text = ''
        # Title         : theme.toml
        # Author        : Bardia Samiee
        # Project       : Parametric Forge
        # License       : MIT
        # Path          : ~/.config/yazi/theme.toml
        # ----------------------------------------------------------------------------
        # Generated from the Forge theme owner (modules/home/theme.nix)

        [mgr]
        cwd = { fg = "${p.yellow.hex}" }
        hovered = { fg = "${p.background.hex}", bg = "${p.cyan.hex}", bold = true }
        preview_hovered = { fg = "${p.magenta.hex}", underline = true }
        find_keyword = { fg = "${p.background.hex}", bg = "${p.yellow.hex}" }
        find_position = { fg = "${p.background.hex}", bg = "${p.orange.hex}" }
        symlink_target = { fg = "${p.magenta.hex}" }
        marker_marked = { fg = "${p.background.hex}", bg = "${p.purple.hex}" }
        marker_copied = { fg = "${p.background.hex}", bg = "${p.orange.hex}" }
        marker_cut = { fg = "${p.background.hex}", bg = "${p.red.hex}" }
        marker_selected = { fg = "${p.background.hex}", bg = "${p.green.hex}" }
        count_copied = { fg = "${p.background.hex}", bg = "${p.orange.hex}" }
        count_cut = { fg = "${p.background.hex}", bg = "${p.red.hex}" }
        count_selected = { fg = "${p.background.hex}", bg = "${p.cyan.hex}" }
        border_symbol = "│"
        border_style = { fg = "${p.cyan.hex}" }
        syntect_theme = "${config.xdg.configHome}/forge/theme/forge-dracula.tmTheme"

        [tabs]
        active = { fg = "${p.background.hex}", bg = "${p.cyan.hex}" }
        inactive = { fg = "${p.background.hex}", bg = "${p.comment.hex}" }
        sep_inner = { open = "", close = "" }
        sep_outer = { open = " ", close = " " }

        [mode]
        normal_main = { fg = "${p.background.hex}", bg = "${p.green.hex}", bold = true }
        normal_alt = { fg = "${p.foreground.hex}", bg = "${p.selection.hex}" }
        select_main = { fg = "${p.background.hex}", bg = "${p.magenta.hex}", bold = true }
        select_alt = { fg = "${p.background.hex}", bg = "${p.pink.hex}" }
        unset_main = { fg = "${p.background.hex}", bg = "${p.red.hex}", bold = true }
        unset_alt = { fg = "${p.background.hex}", bg = "${p.orange.hex}" }

        [status]
        sep_left = { open = "", close = "" }
        sep_right = { open = "", close = "" }
        perm_type = { fg = "${p.green.hex}" }
        perm_read = { fg = "${p.orange.hex}" }
        perm_write = { fg = "${p.foreground.hex}" }
        perm_exec = { fg = "${p.red.hex}" }
        perm_sep = { fg = "${p.cyan.hex}" }
        progress_label = { fg = "${p.background.hex}", bg = "${p.green.hex}" }
        progress_normal = { fg = "${p.background.hex}", bg = "${p.green.hex}" }
        progress_error = { fg = "${p.background.hex}", bg = "${p.red.hex}" }

        [which]
        cols = 3
        mask = { bg = "${p.background.hex}" }
        cand = { fg = "${p.cyan.hex}" }
        rest = { fg = "${p.green.hex}" }
        desc = { fg = "${p.foreground.hex}" }
        separator = "   "
        separator_style = { fg = "${p.yellow.hex}" }

        [confirm]
        border = { fg = "${p.cyan.hex}" }
        title = { fg = "${p.magenta.hex}" }
        content = { fg = "${p.foreground.hex}" }
        list = {}
        btn_yes = { fg = "${p.green.hex}", bg = "${p.background.hex}" }
        btn_no = { fg = "${p.red.hex}", bg = "${p.background.hex}" }
        btn_labels = ["[YES]", "[NO]"]

        [spot]
        border = { fg = "${p.cyan.hex}" }
        title = { fg = "${p.magenta.hex}" }
        tbl_col = { fg = "${p.cyan.hex}" }
        tbl_cell = { fg = "${p.foreground.hex}", reversed = true }

        [notify]
        title_info = { fg = "${p.blue.hex}" }
        title_warn = { fg = "${p.amber.hex}" }
        title_error = { fg = "${p.red.hex}" }
        icon_info = ""
        icon_warn = ""
        icon_error = ""

        [pick]
        border = { fg = "${p.cyan.hex}" }
        active = { fg = "${p.pink.hex}" }
        inactive = {}

        [input]
        border = { fg = "${p.cyan.hex}" }
        title = { fg = "${p.magenta.hex}" }
        value = { fg = "${p.foreground.hex}" }
        selected = { bg = "${p.selection.hex}" }

        [cmp]
        border = { fg = "${p.cyan.hex}" }
        active = { fg = "${p.background.hex}", bg = "${p.foreground.hex}" }
        icon_file = ""
        icon_folder = ""
        icon_command = ""

        [tasks]
        border = { fg = "${p.cyan.hex}" }
        title = { fg = "${p.magenta.hex}" }
        hovered = { fg = "${p.background.hex}", bg = "${p.cyan.hex}" }

        [help]
        on = { fg = "${p.green.hex}" }
        run = { fg = "${p.cyan.hex}" }
        desc = { fg = "${p.foreground.hex}" }
        hovered = { fg = "${p.background.hex}", bg = "${p.cyan.hex}" }
        footer = { fg = "${p.yellow.hex}" }

        [filetype]
        rules = [
          # Images
          { mime = "image/*", fg = "${p.pink.hex}" },
          # Videos and Audio
          { mime = "video/*", fg = "${p.purple.hex}" },
          { mime = "audio/*", fg = "${p.purple.hex}" },
          # Archives
          { mime = "application/{zip,rar,7z*,tar,gzip,xz,zstd,bzip*,lzma,compress,archive,cpio,arj,xar,ms-cab*}", fg = "${p.yellow.hex}" },
          # Documents
          { mime = "application/pdf", fg = "${p.red.hex}" },
          # Empty files
          { mime = "inode/empty", fg = "${p.cyan.hex}" },
          # Programming languages
          { url = "*.py", fg = "${p.green.hex}" },
          { url = "*.js", fg = "${p.yellow.hex}" },
          { url = "*.ts", fg = "${p.orange.hex}" },
          { url = "*.jsx", fg = "${p.orange.hex}" },
          { url = "*.tsx", fg = "${p.orange.hex}" },
          { url = "*.rs", fg = "${p.pink.hex}" },
          { url = "*.go", fg = "${p.purple.hex}" },
          { url = "*.nix", fg = "${p.cyan.hex}" },
          # Configuration files
          { url = "*.{json,toml,yaml,yml,xml}", fg = "${p.purple.hex}" },
          # Web files
          { url = "*.{html,css,scss}", fg = "${p.pink.hex}" },
          # Documentation
          { url = "*.md", fg = "${p.foreground.hex}" },
          { url = "README*", fg = "${p.green.hex}" },
          { url = "LICENSE*", fg = "${p.green.hex}" },
          # 3D Parametric & Technical Design
          { url = "*.{3dm,3dmbak,gh,ghx}", fg = "${p.magenta.hex}" },
          # CAD/Engineering/Architecture
          { url = "*.{dwg,dxf,dwt,rvt,rfa,rft}", fg = "${p.purple.hex}" },
          # Creative 3D Modeling
          { url = "*.{blend,blend1}", fg = "${p.pink.hex}" },
          # Adobe Creative Suite
          { url = "*.{psd,psb,ai,ait,indd,idml,indt}", fg = "${p.pink.hex}" },
          # Shell scripts
          { url = "*.sh", fg = "${p.green.hex}" },
          { url = "*Dockerfile*", fg = "${p.cyan.hex}" },
          { url = "Makefile", fg = "${p.pink.hex}" },
          # Logs
          { url = "*.log", fg = "${p.comment.hex}" },
          # Special files
          { url = "*", is = "orphan", fg = "${p.red.hex}" },
          { url = "*", is = "exec", fg = "${p.green.hex}" },
          # Fallback
          { url = "*/", fg = "${p.foreground.hex}" },
        ]

        [icon]
        # Directory rows project from the shared icon vocabulary (theme owner).
        prepend_dirs = [
    ${dirIcons}
        ]

        prepend_exts = [
          { name = "nix", text = "󱄅", fg = "${p.cyan.hex}" },
          { name = "py", text = "󰌠", fg = "${p.green.hex}" },
          { name = "rs", text = "", fg = "${p.pink.hex}" },
          { name = "js", text = "", fg = "${p.yellow.hex}" },
          { name = "ts", text = "", fg = "${p.orange.hex}" },
          { name = "go", text = "", fg = "${p.cyan.hex}" },
          { name = "lua", text = "", fg = "${p.yellow.hex}" },
          { name = "jsx", text = "", fg = "${p.orange.hex}" },
          { name = "tsx", text = "", fg = "${p.orange.hex}" },
          # Configuration & Data
          { name = "json", text = "", fg = "${p.purple.hex}" },
          { name = "toml", text = "", fg = "${p.purple.hex}" },
          { name = "yaml", text = "", fg = "${p.purple.hex}" },
          { name = "yml", text = "", fg = "${p.purple.hex}" },
          { name = "xml", text = "", fg = "${p.purple.hex}" },
          { name = "env", text = "", fg = "${p.yellow.hex}" },
          { name = "gitignore", text = "", fg = "${p.pink.hex}" },
          # Web
          { name = "html", text = "", fg = "${p.pink.hex}" },
          { name = "css", text = "", fg = "${p.cyan.hex}" },
          { name = "scss", text = "", fg = "${p.pink.hex}" },
          # Shell & Scripts
          { name = "sh", text = "", fg = "${p.green.hex}" },
          { name = "bash", text = "", fg = "${p.green.hex}" },
          # Documentation
          { name = "md", text = "", fg = "${p.foreground.hex}" },
          { name = "pdf", text = "", fg = "${p.red.hex}" },
          # Office Documents
          { name = "doc", text = "", fg = "${p.cyan.hex}" },
          { name = "docx", text = "", fg = "${p.cyan.hex}" },
          { name = "xls", text = "", fg = "${p.green.hex}" },
          { name = "xlsx", text = "", fg = "${p.green.hex}" },
          { name = "ppt", text = "", fg = "${p.red.hex}" },
          { name = "pptx", text = "", fg = "${p.red.hex}" },
          # Images
          { name = "svg", text = "󰜡", fg = "${p.pink.hex}" },
          { name = "jpg", text = "", fg = "${p.pink.hex}" },
          { name = "jpeg", text = "", fg = "${p.pink.hex}" },
          { name = "png", text = "", fg = "${p.pink.hex}" },
          { name = "tiff", text = "", fg = "${p.pink.hex}" },
          { name = "tif", text = "", fg = "${p.pink.hex}" },
          # Archives
          { name = "zip", text = "", fg = "${p.yellow.hex}" },
          { name = "tar", text = "", fg = "${p.yellow.hex}" },
          { name = "gz", text = "", fg = "${p.yellow.hex}" },
          { name = "7z", text = "", fg = "${p.yellow.hex}" },
          # Database
          { name = "sql", text = "", fg = "${p.orange.hex}" },
          { name = "db", text = "", fg = "${p.orange.hex}" },
          { name = "sqlite", text = "", fg = "${p.orange.hex}" },
          # 3D Parametric & Technical Design
          { name = "3dm", text = "", fg = "${p.cyan.hex}" },
          { name = "3dmbak", text = "", fg = "${p.cyan.hex}" },
          { name = "gh", text = "󰮄", fg = "${p.cyan.hex}" },
          { name = "ghx", text = "󰮄", fg = "${p.cyan.hex}" },
          # CAD/Engineering/Architecture
          { name = "dwg", text = "󰕡", fg = "${p.purple.hex}" },
          { name = "dxf", text = "󰕡", fg = "${p.purple.hex}" },
          { name = "dwt", text = "󰕡", fg = "${p.purple.hex}" },
          { name = "rvt", text = "󰕡", fg = "${p.purple.hex}" },
          { name = "rfa", text = "󰕡", fg = "${p.purple.hex}" },
          { name = "rft", text = "󰕡", fg = "${p.purple.hex}" },
          # Creative 3D Modeling
          { name = "blend", text = "", fg = "${p.pink.hex}" },
          { name = "blend1", text = "", fg = "${p.pink.hex}" },
          # Adobe Creative Suite
          { name = "psd", text = "", fg = "${p.pink.hex}" },
          { name = "psb", text = "", fg = "${p.pink.hex}" },
          { name = "ai", text = "", fg = "${p.purple.hex}" },
          { name = "ait", text = "", fg = "${p.purple.hex}" },
          { name = "indd", text = "󰲋", fg = "${p.orange.hex}" },
          { name = "idml", text = "󰲋", fg = "${p.orange.hex}" },
          { name = "indt", text = "󰲋", fg = "${p.orange.hex}" },
          # Photography & Asset Management
          { name = "lrcat", text = "󰄄", fg = "${p.yellow.hex}" },
          { name = "lrtemplate", text = "󰄄", fg = "${p.yellow.hex}" },
          { name = "xmp", text = "󰄄", fg = "${p.yellow.hex}" },
        ]

        prepend_conds = [
          { if = "dir & !hidden & !link & !orphan", text = "", fg = "${p.comment.hex}" },
          { if = "hidden & dir", text = "󰘓" },
          { if = "hidden & !dir", text = "󰟦" },
          { if = "link & !orphan", text = "" },
          { if = "orphan", text = "󰈂" },
        ]
  '';
}
