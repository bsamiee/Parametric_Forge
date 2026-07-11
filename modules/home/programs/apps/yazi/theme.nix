# Title         : theme.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/yazi/theme.nix
# ----------------------------------------------------------------------------
# Typed Yazi theme from the estate palette owner, rendered through the native TOML generator; syntect preview highlighting consumes the owner's shared
# tmTheme artifact and icons project from the shared icon vocabulary plus the extension icon-family vocabulary below.
{
  config,
  lib,
  ...
}: let
  p = config.forge.theme.palette;

  # Style combinators over palette rows; badge is the dominant shape (background-colored text on a colored block).
  fg = c: {fg = c.hex;};
  bg = c: {bg = c.hex;};
  on = f: b: {
    fg = f.hex;
    bg = b.hex;
  };
  badge = on p.background;
  bold = s: s // {bold = true;};
  sep = open: close: {inherit open close;};

  # Extension icon families: space-joined names share one glyph+color row; a new extension is a name on an existing row or one new row.
  extFamilies = {
    "nix" = ["󱄅" p.cyan];
    "py" = ["󰌠" p.green];
    "rs" = ["" p.pink];
    "js" = ["" p.yellow];
    "ts" = ["" p.orange];
    "go" = ["" p.cyan];
    "lua" = ["" p.yellow];
    "jsx tsx" = ["" p.orange];
    "json toml yaml yml xml" = ["" p.purple];
    "env" = ["" p.yellow];
    "gitignore" = ["" p.pink];
    "html" = ["" p.pink];
    "css" = ["" p.cyan];
    "scss" = ["" p.pink];
    "sh bash" = ["" p.green];
    "md" = ["" p.foreground];
    "pdf" = ["" p.red];
    "doc docx" = ["" p.cyan];
    "xls xlsx" = ["" p.green];
    "ppt pptx" = ["" p.red];
    "svg" = ["󰜡" p.pink];
    "jpg jpeg png tiff tif" = ["" p.pink];
    "zip tar gz 7z" = ["" p.yellow];
    "sql db sqlite" = ["" p.orange];
    "3dm 3dmbak" = ["" p.cyan];
    "gh ghx" = ["󰮄" p.cyan];
    "dwg dxf dwt rvt rfa rft" = ["󰕡" p.purple];
    "blend blend1" = ["" p.pink];
    "psd psb" = ["" p.pink];
    "ai ait" = ["" p.purple];
    "indd idml indt" = ["󰲋" p.orange];
    "lrcat lrtemplate xmp" = ["󰄄" p.yellow];
  };

  # Filetype color rows: [kind pattern color ?is], kind mime|url, first match wins; ordering is the routing decision.
  fileRules = [
    ["mime" "image/*" p.pink]
    ["mime" "video/*" p.purple]
    ["mime" "audio/*" p.purple]
    ["mime" "application/{zip,rar,7z*,tar,gzip,xz,zstd,bzip*,lzma,compress,archive,cpio,arj,xar,ms-cab*}" p.yellow]
    ["mime" "application/pdf" p.red]
    ["mime" "inode/empty" p.cyan]
    ["mime" "vfs/{absent,stale}" p.comment]
    ["url" "*.py" p.green]
    ["url" "*.js" p.yellow]
    ["url" "*.{ts,jsx,tsx}" p.orange]
    ["url" "*.rs" p.pink]
    ["url" "*.go" p.purple]
    ["url" "*.nix" p.cyan]
    ["url" "*.{json,toml,yaml,yml,xml}" p.purple]
    ["url" "*.{html,css,scss}" p.pink]
    ["url" "*.md" p.foreground]
    ["url" "README*" p.green]
    ["url" "LICENSE*" p.green]
    ["url" "*.{3dm,3dmbak,gh,ghx}" p.magenta]
    ["url" "*.{dwg,dxf,dwt,rvt,rfa,rft}" p.purple]
    ["url" "*.{blend,blend1}" p.pink]
    ["url" "*.{psd,psb,ai,ait,indd,idml,indt}" p.pink]
    ["url" "*.sh" p.green]
    ["url" "*Dockerfile*" p.cyan]
    ["url" "Makefile" p.pink]
    ["url" "*.log" p.comment]
    ["url" "*" p.red "orphan"]
    ["url" "*" p.green "exec"]
    ["url" "*/" p.foreground]
  ];

  ruleRow = r: let
    kind = builtins.elemAt r 0;
    pattern = builtins.elemAt r 1;
    color = builtins.elemAt r 2;
  in
    {${kind} = pattern;}
    // fg color
    // lib.optionalAttrs (builtins.length r > 3) {is = builtins.elemAt r 3;};
in {
  programs.yazi.theme = {
    mgr = {
      cwd = fg p.yellow;
      find_keyword = badge p.yellow;
      find_position = badge p.orange;
      symlink_target = fg p.magenta;
      marker_marked = badge p.purple;
      marker_copied = badge p.orange;
      marker_cut = badge p.red;
      marker_selected = badge p.green;
      count_copied = badge p.orange;
      count_cut = badge p.red;
      count_selected = badge p.cyan;
      border_style = fg p.cyan;
      syntect_theme = "${config.xdg.configHome}/forge/theme/forge-dracula.tmTheme";
    };

    # Hovered-file styling: 26.5.6 moved mgr.hovered/preview_hovered here.
    indicator = {
      current = bold (badge p.cyan);
      preview = fg p.magenta // {underline = true;};
    };

    tabs = {
      active = badge p.cyan;
      inactive = badge p.comment;
      sep_inner = sep "" "";
      sep_outer = sep " " " ";
    };

    mode = {
      normal_main = bold (badge p.green);
      normal_alt = on p.foreground p.selection;
      select_main = bold (badge p.magenta);
      select_alt = badge p.pink;
      unset_main = bold (badge p.red);
      unset_alt = badge p.orange;
    };

    status = {
      sep_left = sep "" "";
      sep_right = sep "" "";
      perm_type = fg p.green;
      perm_read = fg p.orange;
      perm_write = fg p.foreground;
      perm_exec = fg p.red;
      perm_sep = fg p.cyan;
      progress_label = badge p.green;
      progress_normal = badge p.green;
      progress_error = badge p.red;
    };

    which = {
      mask = bg p.background;
      cand = fg p.cyan;
      rest = fg p.green;
      desc = fg p.foreground;
      separator = "   ";
      separator_style = fg p.yellow;
    };

    confirm = {
      border = fg p.cyan;
      title = fg p.magenta;
      body = fg p.foreground;
      btn_yes = on p.green p.background;
      btn_no = on p.red p.background;
      btn_labels = ["[YES]" "[NO]"];
    };

    spot = {
      border = fg p.cyan;
      title = fg p.magenta;
      tbl_col = fg p.cyan;
      tbl_cell = fg p.foreground // {reversed = true;};
    };

    notify = {
      title_info = fg p.blue;
      title_warn = fg p.amber;
      title_error = fg p.red;
      icon_info = "";
      icon_warn = "";
      icon_error = "";
    };

    pick = {
      border = fg p.cyan;
      active = fg p.pink;
    };

    input = {
      border = fg p.cyan;
      title = fg p.magenta;
      value = fg p.foreground;
      selected = bg p.selection;
    };

    cmp = {
      border = fg p.cyan;
      active = on p.background p.foreground;
      icon_file = "";
      icon_folder = "";
      icon_command = "";
    };

    tasks = {
      border = fg p.cyan;
      title = fg p.magenta;
      hovered = badge p.cyan;
    };

    help = {
      on = fg p.green;
      run = fg p.cyan;
      desc = fg p.foreground;
      hovered = badge p.cyan;
      footer = fg p.yellow;
    };

    filetype.rules = map ruleRow fileRules;

    icon = {
      # Directory rows project from the shared icon vocabulary (theme owner).
      prepend_dirs =
        lib.mapAttrsToList (name: row: {
          inherit name;
          text = row.glyph;
          fg = row.color.hex;
        })
        config.forge.theme.icons.dirs;

      prepend_exts = lib.concatLists (lib.mapAttrsToList (names: family:
        map (name:
          {
            inherit name;
            text = builtins.elemAt family 0;
          }
          // fg (builtins.elemAt family 1)) (lib.splitString " " names))
      extFamilies);

      prepend_conds = [
        ({
            "if" = "dir & !hidden & !link & !orphan";
            text = "";
          }
          // fg p.comment)
        {
          "if" = "hidden & dir";
          text = "󰘓";
        }
        {
          "if" = "hidden & !dir";
          text = "󰟦";
        }
        {
          "if" = "link & !orphan";
          text = "";
        }
        {
          "if" = "orphan";
          text = "󰈂";
        }
      ];
    };
  };
}
