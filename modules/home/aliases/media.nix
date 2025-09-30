# Title         : media.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/aliases/media.nix
# ----------------------------------------------------------------------------
# Media processing aliases for video, audio, and image operations

{ lib, pkgs, ... }:

{
  programs.zsh.shellAliases = {
    # --- MPV Playback -------------------------------------------------------
    play = "mpv";                           # Quick playback alias
    playl = "mpv --loop-file=inf";          # Loop current file
    plays = "mpv --shuffle";                # Shuffle playlist
    yt = "mpv --ytdl-format='bestvideo[height<=?1080]+bestaudio/best'";   # YouTube playback

    # --- FFmpeg Utility -----------------------------------------------------
    ffprobe = "ffprobe -hide_banner";       # Clean media info
    ffplay = "ffplay -hide_banner";         # Clean playback
  };
}
