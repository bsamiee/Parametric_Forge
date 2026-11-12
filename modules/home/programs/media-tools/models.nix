# Title         : models.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/media-tools/models.nix
# ----------------------------------------------------------------------------
# whisper.cpp and the model files its commands and ffmpeg's speech filters load by path. Each `models` row of overlays/manifest.nix is one
# fetched store file linked into $XDG_DATA_HOME/models under its upstream name, so a command names a model as
# `~/.local/share/models/<file>` and a fresh machine holds every one after its first switch.
{
  lib,
  pkgs,
  ...
}: let
  modelRows = (import ../../../../overlays/manifest.nix).extensions.models.rows;
in {
  home.packages = [
    pkgs.whisper-cpp # whisper-cli, whisper-server, and the whisper-vad-speech-segments segmenter
  ];

  xdg.dataFile = lib.mapAttrs' (name: row:
    lib.nameValuePair "models/${name}" {
      source = pkgs.fetchurl {
        url = "${row.base}/${name}";
        inherit (row) hash;
      };
    })
  modelRows;
}
