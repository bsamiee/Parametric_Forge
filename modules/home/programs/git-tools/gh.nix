# Title         : gh.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/git-tools/gh.nix
# ----------------------------------------------------------------------------
# GitHub CLI configuration
{
  config,
  lib,
  pkgs,
  ...
}: let
  ghDefaultConfig = pkgs.writeText "gh-config.yml" ''
    aliases: {}
    editor: ""
    git_protocol: ssh
    prefer_editor_prompt: disabled
    prompt: enabled
    spinner: enabled
    version: "1"
  '';
in {
  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
  };

  # Temporarily stash an existing writable config before Home Manager checks for
  # collisions so that we can re-instate it after the generation is linked.
  home.activation.prepareWritableGhConfig = lib.hm.dag.entryBefore ["checkFilesChanged"] ''
    cfg="${config.xdg.configHome}/gh/config.yml"
    backup="$cfg.hm-backup"

    if [ -f "$backup" ] && [ ! -f "$cfg" ]; then
      mv "$backup" "$cfg"
    fi

    if [ -f "$cfg" ] && [ ! -L "$cfg" ]; then
      mkdir -p "$(dirname "$backup")"
      cp -p "$cfg" "$backup"
      rm -f "$cfg"
    fi
  '';

  # Ensure GitHub CLI config is a writable file instead of a Nix store symlink so
  # `gh auth login` and other commands can persist credentials.
  home.activation.ensureWritableGhConfig = lib.hm.dag.entryAfter ["linkGeneration"] ''
    cfg="${config.xdg.configHome}/gh/config.yml"
    backup="$cfg.hm-backup"
    if [ -L "$cfg" ]; then
      rm -f "$cfg"
    fi
    if [ ! -f "$cfg" ]; then
      mkdir -p "${config.xdg.configHome}/gh"
      if [ -f "$backup" ]; then
        mv "$backup" "$cfg"
      else
        install -m 600 ${ghDefaultConfig} "$cfg"
      fi
    elif [ -f "$backup" ]; then
      # Cleanup stale backup from an interrupted activation.
      rm -f "$backup"
    fi
    chmod 600 "$cfg"
  '';
}
