# Title         : ripgrep.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/ripgrep.nix
# ----------------------------------------------------------------------------
# Agent-first search defaults: raw `rg` must never silently miss corpus content.
{
  lib,
  pkgs,
  ...
}: let
  # Miss-prevention only: hidden dotfiles/dirs and symlinked trees (HM configs resolve into the store) are searched by default, with .git/ as the
  # sole exclusion — everything else stays gitignore-owned. Match semantics, error visibility, engine selection, and presentation keep upstream
  # defaults; display cosmetics live in the interactive alias, and scripted gates isolate with --no-config.
  ripgrepConfig = [
    # --- [SEARCH_BEHAVIOR]
    "--smart-case"
    "--hidden"
    "--follow"
    "--glob=!.git/"

    # --- [TYPE_DEFINITIONS]
    # Additive vocabulary: inert until a -t/--type selection names it.
    "--type-add=nix:*.nix"
    "--type-add=nix:flake.lock"

    "--type-add=agent:{AGENTS,CLAUDE,SKILL}.md"

    "--type-add=docs:*.{md,markdown,rst,txt,adoc,org}"
    "--type-add=docs:README*"
    "--type-add=docs:LICENSE*"
    "--type-add=docs:CHANGELOG*"
    "--type-add=docs:CONTRIBUTING*"

    "--type-add=shell:*.{sh,bash,zsh,fish}"
    "--type-add=shell:*.{bashrc,zshrc}"

    "--type-add=config:*.{toml,yaml,yml}"
    "--type-add=config:*.{env,env.*}"
    "--type-add=config:.*rc"
    "--type-add=config:Dockerfile*"
    "--type-add=config:docker-compose*.{yml,yaml}"

    "--type-add=data:*.{json,jsonc,json5,yaml,yml,toml}"

    "--type-add=lock:*lock.json"
    "--type-add=lock:*lock.yaml"
    "--type-add=lock:Cargo.lock"
    "--type-add=lock:flake.lock"

    "--type-add=log:*.{log,logs}"

    "--type-add=build:Makefile*"
    "--type-add=build:*.{mk,cmake,bazel,BUILD}"
    "--type-add=proto:*.proto"
    "--type-add=headers:*.{h,hpp,hxx,hh}"
  ];
in {
  home.packages = [pkgs.ripgrep];
  xdg.configFile."ripgrep/config".text = lib.concatStringsSep "\n" ripgrepConfig;
}
