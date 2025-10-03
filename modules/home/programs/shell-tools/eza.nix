# Title         : eza.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/shell-tools/eza.nix
# ----------------------------------------------------------------------------
# Modern ls replacement with Dracula theme

{ config, lib, pkgs, ... }:

# Dracula theme color reference
# background    #15131F
# current_line  #2A2640
# selection     #44475a
# foreground    #F8F8F2
# comment       #7A71AA
# purple        #A072C6
# cyan          #94F2E8
# green         #50FA7B
# yellow        #F1FA8C
# orange        #F97359
# red           #ff5555
# magenta       #d82f94
# pink          #E98FBE

let
  yamlFormat = pkgs.formats.yaml { };

  ezaTheme = {
    filekinds = {
      normal = { foreground = "#F8F8F2"; };
      directory = { foreground = "#94F2E8"; is_bold = true; };
      symlink = { foreground = "#A072C6"; };
      pipe = { foreground = "#7A71AA"; };
      block_device = { foreground = "#FF5555"; };
      char_device = { foreground = "#FF5555"; };
      socket = { foreground = "#7A71AA"; };
      special = { foreground = "#d82f94"; };
      executable = { foreground = "#50FA7B"; is_bold = true; };
      mount_point = { foreground = "#F97359"; };
    };
    perms = {
      user_read = { foreground = "#F8F8F2"; };
      user_write = { foreground = "#F97359"; };
      user_execute_file = { foreground = "#50FA7B"; };
      user_execute_other = { foreground = "#50FA7B"; };
      group_read = { foreground = "#F8F8F2"; };
      group_write = { foreground = "#F97359"; };
      group_execute = { foreground = "#50FA7B"; };
      other_read = { foreground = "#F8F8F2"; };
      other_write = { foreground = "#F97359"; };
      other_execute = { foreground = "#50FA7B"; };
      special_user_file = { foreground = "#d82f94"; };
      special_other = { foreground = "#7A71AA"; };
      attribute = { foreground = "#F8F8F2"; };
    };
    size = {
      major = { foreground = "#F1FA8C"; is_bold = true; };
      minor = { foreground = "#A072C6"; };
      number_byte = { foreground = "#F8F8F2"; };
      number_kilo = { foreground = "#F8F8F2"; };
      number_mega = { foreground = "#94F2E8"; };
      number_giga = { foreground = "#E98FBE"; };
      number_huge = { foreground = "#E98FBE"; };
      unit_byte = { foreground = "#F8F8F2"; };
      unit_kilo = { foreground = "#94F2E8"; };
      unit_mega = { foreground = "#E98FBE"; };
      unit_giga = { foreground = "#E98FBE"; };
      unit_huge = { foreground = "#F97359"; };
    };
    users = {
      user_you = { foreground = "#F8F8F2"; };
      user_root = { foreground = "#FF5555"; is_bold = true; };
      user_other = { foreground = "#d82f94"; };
      group_yours = { foreground = "#F8F8F2"; };
      group_other = { foreground = "#7A71AA"; };
      group_root = { foreground = "#FF5555"; };
    };
    links = {
      normal = { foreground = "#A072C6"; };
      multi_link_file = { foreground = "#F97359"; };
    };
    git = {
      new = { foreground = "#50FA7B"; };
      modified = { foreground = "#F97359"; };
      deleted = { foreground = "#FF5555"; };
      renamed = { foreground = "#94F2E8"; };
      typechange = { foreground = "#d82f94"; };
      ignored = { foreground = "#7A71AA"; is_dimmed = true; };
      conflicted = { foreground = "#FF5555"; is_bold = true; };
    };
    git_repo = {
      branch_main = { foreground = "#F8F8F2"; };
      branch_other = { foreground = "#d82f94"; };
      git_clean = { foreground = "#50FA7B"; };
      git_dirty = { foreground = "#FF5555"; };
    };
    security_context = {
      colon = { foreground = "#7A71AA"; };
      user = { foreground = "#F8F8F2"; };
      role = { foreground = "#d82f94"; };
      typ = { foreground = "#7A71AA"; };
      range = { foreground = "#d82f94"; };
    };
    file_type = {
      image = { foreground = "#F97359"; };
      video = { foreground = "#E98FBE"; };
      music = { foreground = "#50FA7B"; };
      lossless = { foreground = "#50FA7B"; };
      crypto = { foreground = "#7A71AA"; };
      document = { foreground = "#F8F8F2"; };
      compressed = { foreground = "#d82f94"; };
      temp = { foreground = "#FF5555"; };
      compiled = { foreground = "#94F2E8"; };
      build = { foreground = "#7A71AA"; };
      source = { foreground = "#94F2E8"; };
    };
    punctuation = { foreground = "#7A71AA"; };
    date = { foreground = "#E98FBE"; };
    inode = { foreground = "#44475a"; };
    broken_symlink = { foreground = "#FF5555"; is_underline = true; };
    broken_path_overlay = { foreground = "#94F2E8"; };
  };
in
{
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
}
