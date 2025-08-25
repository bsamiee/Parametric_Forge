# Title         : programs.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /reference-implementation/darwin/programs.nix
# ----------------------------------------------------------------------------
# Darwin-specific program configurations for macOS-only tools

{ config, lib, pkgs, ... }:

lib.mkIf pkgs.stdenv.isDarwin {
  # --- macOS-Specific Shell Aliases -----------------------------------------
  programs.zsh.shellAliases = lib.mkIf config.programs.zsh.enable {
    # Mac App Store management
    "mas-search" = "mas search";
    "mas-install" = "mas install";
    "mas-list" = "mas list";
    "mas-outdated" = "mas outdated";
    "mas-upgrade" = "mas upgrade";
    
    # Dock management
    "dock-add" = "dockutil --add";
    "dock-remove" = "dockutil --remove";
    "dock-list" = "dockutil --list";
    "dock-reset" = "dockutil --remove all && dockutil --add /Applications/Safari.app";
    
    # Clipboard utilities
    "png-paste" = "pngpaste";
    "png-copy" = "pngpaste -";
    
    # Audio switching (if switchaudio-osx is available)
    "audio-list" = "SwitchAudioSource -a";
    "audio-current" = "SwitchAudioSource -c";
    "audio-switch" = "SwitchAudioSource -s";
    
    # System monitoring
    "cpu-temp" = "osx-cpu-temp";
    "system-info" = "m info";
    "system-update" = "m update";
    
    # macOS-specific file operations
    "show-hidden" = "defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder";
    "hide-hidden" = "defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder";
    "empty-trash" = "sudo rm -rfv /Volumes/*/.Trashes; sudo rm -rfv ~/.Trash; sudo rm -rfv /private/var/log/asl/*.asl; sqlite3 ~/Library/Preferences/com.apple.LaunchServices.QuarantineEventsV* 'delete from LSQuarantineEvent'";
  };

  # --- macOS-Specific Bash Aliases ------------------------------------------
  programs.bash.shellAliases = lib.mkIf config.programs.bash.enable {
    # Same aliases as zsh for consistency
    "mas-search" = "mas search";
    "mas-install" = "mas install";
    "mas-list" = "mas list";
    "mas-outdated" = "mas outdated";
    "mas-upgrade" = "mas upgrade";
    
    "dock-add" = "dockutil --add";
    "dock-remove" = "dockutil --remove";
    "dock-list" = "dockutil --list";
    "dock-reset" = "dockutil --remove all && dockutil --add /Applications/Safari.app";
    
    "png-paste" = "pngpaste";
    "png-copy" = "pngpaste -";
    
    "audio-list" = "SwitchAudioSource -a";
    "audio-current" = "SwitchAudioSource -c";
    "audio-switch" = "SwitchAudioSource -s";
    
    "cpu-temp" = "osx-cpu-temp";
    "system-info" = "m info";
    "system-update" = "m update";
    
    "show-hidden" = "defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder";
    "hide-hidden" = "defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder";
    "empty-trash" = "sudo rm -rfv /Volumes/*/.Trashes; sudo rm -rfv ~/.Trash; sudo rm -rfv /private/var/log/asl/*.asl; sqlite3 ~/Library/Preferences/com.apple.LaunchServices.QuarantineEventsV* 'delete from LSQuarantineEvent'";
  };

  # --- macOS-Specific Git Configuration -------------------------------------
  programs.git = lib.mkIf config.programs.git.enable {
    extraConfig = {
      # macOS-specific credential helper
      credential.helper = "osxkeychain";
      
      # macOS-specific diff and merge tools
      diff.tool = "opendiff";
      merge.tool = "opendiff";
      difftool.opendiff.cmd = "opendiff \"$LOCAL\" \"$REMOTE\" -merge \"$MERGED\"";
      mergetool.opendiff.cmd = "opendiff \"$LOCAL\" \"$REMOTE\" -ancestor \"$BASE\" -merge \"$MERGED\"";
      mergetool.opendiff.trustExitCode = true;
      
      # macOS-specific pager configuration
      core.pager = "less -R";
    };
  };

  # --- macOS-Specific SSH Configuration -------------------------------------
  programs.ssh = lib.mkIf config.programs.ssh.enable {
    extraConfig = ''
      # macOS-specific SSH configuration
      
      # Use macOS Keychain for SSH key management
      UseKeychain yes
      AddKeysToAgent yes
      
      # macOS-specific identity file locations
      IdentityFile ~/.ssh/id_rsa
      IdentityFile ~/.ssh/id_ed25519
      
      # Use 1Password SSH agent if available
      IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    '';
  };

  # --- macOS-Specific Neovim Configuration ----------------------------------
  programs.neovim = lib.mkIf config.programs.neovim.enable {
    extraLuaConfig = ''
      -- macOS-specific Neovim configuration
      
      -- Use macOS clipboard
      vim.opt.clipboard = "unnamedplus"
      
      -- macOS-specific font settings (if using GUI)
      if vim.g.neovide then
        vim.o.guifont = "SF Mono:h14"
        vim.g.neovide_input_macos_alt_is_meta = true
      end
      
      -- macOS-specific terminal integration
      if vim.env.TERM_PROGRAM == "WezTerm" or vim.env.TERM_PROGRAM == "iTerm.app" then
        vim.opt.termguicolors = true
      end
      
      -- Load Darwin-specific configuration if it exists
      local darwin_config = vim.fn.stdpath("config") .. "/lua/config/darwin.lua"
      if vim.fn.filereadable(darwin_config) == 1 then
        dofile(darwin_config)
      end
    '';
  };
}