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

  # --- Finder Settings ------------------------------------------------------
  showfiles = "defaults write com.apple.finder AppleShowAllFiles YES && killall Finder"; # Show hidden files
  hidefiles = "defaults write com.apple.finder AppleShowAllFiles NO && killall Finder"; # Hide hidden files

  # --- Application Management -----------------------------------------------
  lsapps = "ls /Applications"; # List installed applications

  # --- Clipboard Operations -------------------------------------------------
  copy = "pbcopy"; # Pipe to clipboard
  paste = "pbpaste"; # Output clipboard contents
  clip = "screencapture -ic"; # Interactive screenshot to clipboard
  clipfile = "screencapture -i"; # Interactive screenshot to file

  # --- Quick Look Preview ---------------------------------------------------
  preview = "qlmanage -p 2>/dev/null"; # Preview without opening app

  # --- Terminal Launchers ---------------------------------------------------
  wez = "open -ga WezTerm"; # Launch WezTerm

  # --- System Power & Display -----------------------------------------------
  awake = "caffeinate -dims"; # Prevent sleep (Ctrl+C to stop)
  lock = "pmset displaysleepnow"; # Lock screen immediately

  # --- System Information ---------------------------------------------------
  battery = "pmset -g batt"; # Battery status
  wifi = "networksetup -getairportnetwork en0"; # Current WiFi network
  cpu = "sysctl -n machdep.cpu.brand_string"; # CPU info
  mem = "top -l 1 -s 0 | grep PhysMem"; # Memory usage

  # --- Network & System -----------------------------------------------------
  flushdns = "sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder"; # Flush DNS cache
}
