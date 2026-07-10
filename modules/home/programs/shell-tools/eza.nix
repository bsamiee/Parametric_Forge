# Title         : eza.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/eza.nix
# ----------------------------------------------------------------------------
# Modern ls replacement themed from the estate palette owner

{
  config,
  pkgs,
  ...
}: let
  inherit (config.forge.theme) palette;
  yamlFormat = pkgs.formats.yaml {};
  treeIgnoreGlobs = ".git|.direnv|.devenv|.cache|.pytest_cache|.mypy_cache|.ruff_cache|__pycache__|node_modules|bin|obj|dist|build|target|coverage|.next|.nuxt|.turbo|.vite|.parcel-cache|vendor";
  treeCommand = pkgs.writeShellApplication {
    name = "tree";
    runtimeInputs = [pkgs.eza];
    text = ''
      exec eza \
        --tree \
        --level "''${FORGE_TREE_LEVEL:-4}" \
        --long \
        --header \
        --bytes \
        --total-size \
        --git \
        --git-ignore \
        --group-directories-first \
        --icons=auto \
        --classify=auto \
        --no-quotes \
        --no-permissions \
        --no-user \
        --time-style=relative \
        --ignore-glob "''${FORGE_TREE_IGNORE:-${treeIgnoreGlobs}}" \
        "$@"
    '';
  };

  ezaTheme = {
    filekinds = {
      normal = {foreground = palette.foreground.hex;};
      directory = {
        foreground = palette.cyan.hex;
        is_bold = true;
      };
      symlink = {foreground = palette.purple.hex;};
      pipe = {foreground = palette.comment.hex;};
      block_device = {foreground = palette.red.hex;};
      char_device = {foreground = palette.red.hex;};
      socket = {foreground = palette.comment.hex;};
      special = {foreground = palette.magenta.hex;};
      executable = {
        foreground = palette.green.hex;
        is_bold = true;
      };
      mount_point = {foreground = palette.orange.hex;};
    };
    perms = {
      user_read = {foreground = palette.foreground.hex;};
      user_write = {foreground = palette.orange.hex;};
      user_execute_file = {foreground = palette.green.hex;};
      user_execute_other = {foreground = palette.green.hex;};
      group_read = {foreground = palette.foreground.hex;};
      group_write = {foreground = palette.orange.hex;};
      group_execute = {foreground = palette.green.hex;};
      other_read = {foreground = palette.foreground.hex;};
      other_write = {foreground = palette.orange.hex;};
      other_execute = {foreground = palette.green.hex;};
      special_user_file = {foreground = palette.magenta.hex;};
      special_other = {foreground = palette.comment.hex;};
      attribute = {foreground = palette.foreground.hex;};
    };
    size = {
      major = {
        foreground = palette.yellow.hex;
        is_bold = true;
      };
      minor = {foreground = palette.purple.hex;};
      number_byte = {foreground = palette.foreground.hex;};
      number_kilo = {foreground = palette.foreground.hex;};
      number_mega = {foreground = palette.cyan.hex;};
      number_giga = {foreground = palette.pink.hex;};
      number_huge = {foreground = palette.pink.hex;};
      unit_byte = {foreground = palette.foreground.hex;};
      unit_kilo = {foreground = palette.cyan.hex;};
      unit_mega = {foreground = palette.pink.hex;};
      unit_giga = {foreground = palette.pink.hex;};
      unit_huge = {foreground = palette.orange.hex;};
    };
    users = {
      user_you = {foreground = palette.foreground.hex;};
      user_root = {
        foreground = palette.red.hex;
        is_bold = true;
      };
      user_other = {foreground = palette.magenta.hex;};
      group_yours = {foreground = palette.foreground.hex;};
      group_other = {foreground = palette.comment.hex;};
      group_root = {foreground = palette.red.hex;};
    };
    links = {
      normal = {foreground = palette.purple.hex;};
      multi_link_file = {foreground = palette.orange.hex;};
    };
    git = {
      new = {foreground = palette.green.hex;};
      modified = {foreground = palette.yellow.hex;};
      deleted = {foreground = palette.red.hex;};
      renamed = {foreground = palette.cyan.hex;};
      typechange = {foreground = palette.magenta.hex;};
      ignored = {
        foreground = palette.comment.hex;
        is_dimmed = true;
      };
      conflicted = {
        foreground = palette.orange.hex;
        is_bold = true;
      };
    };
    git_repo = {
      branch_main = {foreground = palette.foreground.hex;};
      branch_other = {foreground = palette.magenta.hex;};
      git_clean = {foreground = palette.green.hex;};
      git_dirty = {foreground = palette.red.hex;};
    };
    security_context = {
      none = {foreground = palette.comment.hex;};
      selinux = {
        colon = {foreground = palette.comment.hex;};
        user = {foreground = palette.foreground.hex;};
        role = {foreground = palette.magenta.hex;};
        typ = {foreground = palette.yellow.hex;};
        range = {foreground = palette.magenta.hex;};
      };
    };
    file_type = {
      image = {foreground = palette.orange.hex;};
      video = {foreground = palette.pink.hex;};
      music = {foreground = palette.green.hex;};
      lossless = {foreground = palette.green.hex;};
      crypto = {foreground = palette.purple.hex;};
      document = {foreground = palette.comment.hex;};
      compressed = {foreground = palette.magenta.hex;};
      temp = {foreground = palette.red.hex;};
      compiled = {foreground = palette.cyan.hex;};
      build = {foreground = palette.yellow.hex;};
      source = {foreground = palette.orange.hex;};
    };
    punctuation = {foreground = palette.comment.hex;};
    date = {foreground = palette.pink.hex;};
    inode = {foreground = palette.selection.hex;};
    blocks = {foreground = palette.purple.hex;};
    header = {
      foreground = palette.cyan.hex;
      is_bold = true;
    };
    octal = {foreground = palette.yellow.hex;};
    flags = {foreground = palette.purple.hex;};
    control_char = {foreground = palette.orange.hex;};
    symlink_path = {foreground = palette.purple.hex;};
    broken_symlink = {
      foreground = palette.red.hex;
      is_underline = true;
    };
    broken_path_overlay = {foreground = palette.orange.hex;};
  };
in {
  programs.eza = {
    enable = true;
    enableZshIntegration = false;
    git = true;
    icons = "auto";
    extraOptions = [
      "--group-directories-first"
    ];
  };
  xdg.configFile."eza/theme.yml".source = yamlFormat.generate "eza-theme" ezaTheme;
  home.file.".local/bin/tree".source = "${treeCommand}/bin/tree";
}
