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
  # palette retained for the one hue with no semantic role: string-yellow (size emphasis, octal, build kind, SELinux type).
  inherit (config.forge.theme) roles palette;
  yamlFormat = pkgs.formats.yaml {};
  treeIgnoreGlobs = ".git|.direnv|.devenv|.cache|.pytest_cache|.mypy_cache|.ruff_cache|__pycache__|node_modules|obj|dist|build|target|coverage|.next|.nuxt|.turbo|.vite|.parcel-cache|vendor";
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
      normal = {foreground = roles.text.primary.hex;};
      directory = {
        foreground = roles.accent.primary.hex;
        is_bold = true;
      };
      symlink = {foreground = roles.accent.structural.hex;};
      pipe = {foreground = roles.text.muted.hex;};
      block_device = {foreground = roles.state.danger.hex;};
      char_device = {foreground = roles.state.danger.hex;};
      socket = {foreground = roles.text.muted.hex;};
      special = {foreground = roles.accent.secondary.hex;};
      executable = {
        foreground = roles.state.success.hex;
        is_bold = true;
      };
      mount_point = {foreground = roles.state.attention.hex;};
    };
    perms = {
      user_read = {foreground = roles.text.primary.hex;};
      user_write = {foreground = roles.state.attention.hex;};
      user_execute_file = {foreground = roles.state.success.hex;};
      user_execute_other = {foreground = roles.state.success.hex;};
      group_read = {foreground = roles.text.primary.hex;};
      group_write = {foreground = roles.state.attention.hex;};
      group_execute = {foreground = roles.state.success.hex;};
      other_read = {foreground = roles.text.primary.hex;};
      other_write = {foreground = roles.state.attention.hex;};
      other_execute = {foreground = roles.state.success.hex;};
      special_user_file = {foreground = roles.accent.secondary.hex;};
      special_other = {foreground = roles.text.muted.hex;};
      attribute = {foreground = roles.text.primary.hex;};
    };
    size = {
      major = {
        foreground = palette.yellow.hex;
        is_bold = true;
      };
      minor = {foreground = roles.accent.structural.hex;};
      number_byte = {foreground = roles.text.primary.hex;};
      number_kilo = {foreground = roles.text.primary.hex;};
      number_mega = {foreground = roles.accent.primary.hex;};
      number_giga = {foreground = roles.accent.tertiary.hex;};
      number_huge = {foreground = roles.accent.tertiary.hex;};
      unit_byte = {foreground = roles.text.primary.hex;};
      unit_kilo = {foreground = roles.accent.primary.hex;};
      unit_mega = {foreground = roles.accent.tertiary.hex;};
      unit_giga = {foreground = roles.accent.tertiary.hex;};
      unit_huge = {foreground = roles.state.attention.hex;};
    };
    users = {
      user_you = {foreground = roles.text.primary.hex;};
      user_root = {
        foreground = roles.state.danger.hex;
        is_bold = true;
      };
      user_other = {foreground = roles.accent.secondary.hex;};
      group_yours = {foreground = roles.text.primary.hex;};
      group_other = {foreground = roles.text.muted.hex;};
      group_root = {foreground = roles.state.danger.hex;};
    };
    links = {
      normal = {foreground = roles.accent.structural.hex;};
      multi_link_file = {foreground = roles.state.attention.hex;};
    };
    # Git column hues project from the owner state ladder (roles.git); the glyph column stays eza-fixed (N/M/D/R/T/I/U — not themable), the one
    # sanctioned tool-owned-glyph exception. Ignored keeps muted text (no owner row: ignore is a visibility tier, not a git state).
    git = {
      new = {foreground = roles.git.added.color.hex;};
      modified = {foreground = roles.git.modified.color.hex;};
      deleted = {foreground = roles.git.deleted.color.hex;};
      renamed = {foreground = roles.git.renamed.color.hex;};
      typechange = {foreground = roles.git.typechange.color.hex;};
      ignored = {
        foreground = roles.text.muted.hex;
        is_dimmed = true;
      };
      conflicted = {
        foreground = roles.git.conflict.color.hex;
        is_bold = true;
      };
    };
    git_repo = {
      branch_main = {foreground = roles.text.primary.hex;};
      branch_other = {foreground = roles.accent.secondary.hex;};
      git_clean = {foreground = roles.git.clean.color.hex;};
      git_dirty = {foreground = roles.state.danger.hex;};
    };
    security_context = {
      none = {foreground = roles.text.muted.hex;};
      selinux = {
        colon = {foreground = roles.text.muted.hex;};
        user = {foreground = roles.text.primary.hex;};
        role = {foreground = roles.accent.secondary.hex;};
        typ = {foreground = palette.yellow.hex;};
        range = {foreground = roles.accent.secondary.hex;};
      };
    };
    file_type = {
      image = {foreground = roles.state.attention.hex;};
      video = {foreground = roles.accent.tertiary.hex;};
      music = {foreground = roles.state.success.hex;};
      lossless = {foreground = roles.state.success.hex;};
      crypto = {foreground = roles.accent.structural.hex;};
      document = {foreground = roles.text.muted.hex;};
      compressed = {foreground = roles.accent.secondary.hex;};
      temp = {foreground = roles.state.danger.hex;};
      compiled = {foreground = roles.accent.primary.hex;};
      build = {foreground = palette.yellow.hex;};
      source = {foreground = roles.state.attention.hex;};
    };
    punctuation = {foreground = roles.text.muted.hex;};
    date = {foreground = roles.accent.tertiary.hex;};
    inode = {foreground = roles.surface.selected.hex;};
    blocks = {foreground = roles.accent.structural.hex;};
    header = {
      foreground = roles.accent.primary.hex;
      is_bold = true;
    };
    octal = {foreground = palette.yellow.hex;};
    flags = {foreground = roles.accent.structural.hex;};
    control_char = {foreground = roles.state.attention.hex;};
    symlink_path = {foreground = roles.accent.structural.hex;};
    broken_symlink = {
      foreground = roles.state.danger.hex;
      is_underline = true;
    };
    broken_path_overlay = {foreground = roles.state.attention.hex;};
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
