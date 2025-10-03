# Title         : gh.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/git-tools/gh.nix
# ----------------------------------------------------------------------------
# GitHub CLI configuration

{ config, lib, pkgs, ... }:

{
  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;

    settings = {
      git_protocol = "ssh";              # Use SSH for git operations (matches SSH config)

      # --- UI Preferences ---------------------------------------------------
      prompt = "enabled";                # Interactive prompts
      spinner = "enabled";               # Show spinners for long operations
      prefer_editor_prompt = "disabled"; # Use terminal prompts over editor
    };
  };
}
