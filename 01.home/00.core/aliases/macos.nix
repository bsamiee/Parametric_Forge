# Title         : macos.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/aliases/macos.nix
# ----------------------------------------------------------------------------
# macOS-specific aliases - unique system features not covered elsewhere

_:

{
  # --- Finder & Navigation --------------------------------------------------
  o = "open"; # Open file/URL with default app
  oo = "open ."; # Open current directory in Finder
  reveal = "open -R"; # Reveal file in Finder

  # --- Clipboard Operations -------------------------------------------------
  copy = "pbcopy"; # Pipe to clipboard
  paste = "pbpaste"; # Output clipboard contents
  clip = "screencapture -ic"; # Screenshot to clipboard

  # --- Quick Look Preview ---------------------------------------------------
  preview = "qlmanage -p 2>/dev/null"; # Preview without opening app

  # --- Terminal Launchers ---------------------------------------------------
  wez = "open -ga WezTerm"; # Launch WezTerm (moved from core.nix)

  # --- Spotlight Search -----------------------------------------------------
  search = "mdfind"; # Search everywhere via Spotlight
  searchhere = "mdfind -onlyin ."; # Search current dir via Spotlight

  # --- System Power & Display -----------------------------------------------
  awake = "caffeinate -dims"; # Prevent sleep (Ctrl+C to stop)
  lock = "pmset displaysleepnow"; # Lock screen immediately

  # --- System Information ---------------------------------------------------
  battery = "pmset -g batt"; # Battery status
  wifi = "networksetup -getairportnetwork en0"; # Current WiFi network

  # --- Finder Settings ------------------------------------------------------
  hf = "defaults write com.apple.finder AppleShowAllFiles YES && killall Finder"; # Show hidden files
  hhf = "defaults write com.apple.finder AppleShowAllFiles NO && killall Finder"; # Hide hidden files

  # --- Trash Management -----------------------------------------------------
  emptytrash = "rm -rf ~/.Trash/* ~/.Trash/.*"; # Empty trash completely

  # --- Network & System -----------------------------------------------------
  flushdns = "sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder"; # Flush DNS cache

  # --- Quick yabai debugging (keep minimal debugging tools)
  yabai-config = "yabai -m query --spaces && yabai -m query --windows";
  yabai-logs = "tail -f /tmp/yabai_$USER.*.log";
}
