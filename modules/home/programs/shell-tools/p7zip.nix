# Title         : p7zip.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/p7zip.nix
# ----------------------------------------------------------------------------
# 7-Zip archive extraction and compression tool for Yazi
{pkgs, ...}: {
  home.packages = [
    pkgs._7zz-rar # 7-Zip with RAR support for Yazi archive preview/extraction
  ];
}
