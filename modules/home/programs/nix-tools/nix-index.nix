# Title         : nix-index.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/nix-tools/nix-index.nix
# ----------------------------------------------------------------------------
# Command-not-found with pre-built package database
{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.nix-index = {
    enable = true;
    enableZshIntegration = true;
  };

  # Download pre-built database on activation (updated weekly)
  home.activation.downloadNixIndexDB = lib.hm.dag.entryAfter ["writeBoundary"] ''
    NIX_INDEX_DIR="${config.xdg.cacheHome}/nix-index"
    if [[ ! -f "$NIX_INDEX_DIR/files" ]]; then
      echo "Downloading pre-built nix-index database..."
      filename="index-$(uname -m | sed 's/^arm64$/aarch64/')-$(uname | tr A-Z a-z)"
      mkdir -p "$NIX_INDEX_DIR"
      $DRY_RUN_CMD ${pkgs.wget}/bin/wget -q -N "https://github.com/nix-community/nix-index-database/releases/latest/download/$filename" -O "$NIX_INDEX_DIR/$filename"
      $DRY_RUN_CMD ln -f "$NIX_INDEX_DIR/$filename" "$NIX_INDEX_DIR/files"
    fi
  '';
}
