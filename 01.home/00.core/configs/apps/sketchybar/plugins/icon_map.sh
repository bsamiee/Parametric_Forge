#!/bin/bash
# Title         : icon_map.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/apps/sketchybar/plugins/icon_map.sh
# ----------------------------------------------------------------------------
# Application name to sketchybar-app-font icon mapping

# --- Application Icon Mapping -----------------------------------------------
case $@ in

# --- Development Tools ------------------------------------------------------
"Keyboard Maestro")
  icon_result=":keyboard_maestro:"
  ;;
"WebStorm")
  icon_result=":web_storm:"
  ;;
"Neovide" | "MacVim" | "Vim" | "VimR")
  icon_result=":vim:"
  ;;
"Sublime Text")
  icon_result=":sublime_text:"
  ;;
"Emacs")
  icon_result=":emacs:"
  ;;
"Code" | "Code - Insiders")
  icon_result=":code:"
  ;;
"VSCodium")
  icon_result=":vscodium:"
  ;;
"Xcode")
  icon_result=":xcode:"
  ;;
"IntelliJ IDEA")
  icon_result=":idea:"
  ;;
"Tower")
  icon_result=":tower:"
  ;;
"Nova")
  icon_result=":nova:"
  ;;
"Atom")
  icon_result=":atom:"
  ;;
"GitHub Desktop")
  icon_result=":git_hub:"
  ;;
"Docker Desktop" | "Docker")
  icon_result=":docker:"
  ;;
"Alacritty" | "Hyper" | "iTerm2" | "kitty" | "Terminal" | "WezTerm")
  icon_result=":terminal:"
  ;;

# --- Creative & Design ------------------------------------------------------
"Final Cut Pro")
  icon_result=":final_cut_pro:"
  ;;
"Adobe Photoshop 2025" | "Adobe Photoshop")
  icon_result=":photoshop:"
  ;;
"Adobe Illustrator 2025" | "Adobe Illustrator")
  icon_result=":illustrator:"
  ;;
"Adobe InDesign 2025" | "Adobe InDesign")
  icon_result=":indesign:"
  ;;
"Adobe Lightroom Classic" | "Adobe Lightroom")
  icon_result=":lightroom:"
  ;;
"Adobe Acrobat DC" | "Adobe Acrobat")
  icon_result=":acrobat:"
  ;;
"Affinity Publisher")
  icon_result=":affinity_publisher:"
  ;;
"Affinity Designer")
  icon_result=":affinity_designer:"
  ;;
"Affinity Photo")
  icon_result=":affinity_photo:"
  ;;
"Blender")
  icon_result=":blender:"
  ;;
"Figma")
  icon_result=":figma:"
  ;;
"Sketch")
  icon_result=":sketch:"
  ;;
"Freeform")
  icon_result=":freeform:"
  ;;
"OBS")
  icon_result=":obsstudio:"
  ;;

# --- Media & Entertainment --------------------------------------------------
"VLC")
  icon_result=":vlc:"
  ;;
"Spotify")
  icon_result=":spotify:"
  ;;
"Music")
  icon_result=":music:"
  ;;
"TIDAL")
  icon_result=":tidal:"
  ;;
"Podcasts")
  icon_result=":podcasts:"
  ;;
"Audacity")
  icon_result=":audacity:"
  ;;

# --- Communication ----------------------------------------------------------
"Messages" | "Nachrichten")
  icon_result=":messages:"
  ;;
"Caprine")
  icon_result=":caprine:"
  ;;
"Zulip")
  icon_result=":zulip:"
  ;;
"WhatsApp")
  icon_result=":whats_app:"
  ;;
"Telegram")
  icon_result=":telegram:"
  ;;
"Discord" | "Discord Canary" | "Discord PTB")
  icon_result=":discord:"
  ;;
"Signal")
  icon_result=":signal:"
  ;;
"Canary Mail" | "HEY" | "Mail" | "Mailspring" | "MailMate" | "Outlook" | "Superhuman")
  icon_result=":mail:"
  ;;
"Spark")
  icon_result=":spark:"
  ;;

# --- Web Browsers ------------------------------------------------------------
"Microsoft Edge")
  icon_result=":microsoft_edge:"
  ;;
"Chromium" | "Google Chrome" | "Google Chrome Canary")
  icon_result=":google_chrome:"
  ;;
"Firefox Developer Edition" | "Firefox Nightly")
  icon_result=":firefox_developer_edition:"
  ;;
"Firefox")
  icon_result=":firefox:"
  ;;
"Safari" | "Safari Technology Preview")
  icon_result=":safari:"
  ;;
"Vivaldi")
  icon_result=":vivaldi:"
  ;;
"Arc")
  icon_result=":arc:"
  ;;
"Tor Browser")
  icon_result=":tor_browser:"
  ;;
"Zen Browser")
  icon_result=":zen_browser:"
  ;;

# --- Productivity & Office ---------------------------------------------------
"ClickUp")
  icon_result=":click_up:"
  ;;
"Microsoft To Do" | "Things")
  icon_result=":things:"
  ;;
"DEVONthink 3")
  icon_result=":devonthink3:"
  ;;
"Trello")
  icon_result=":trello:"
  ;;
"Calendar" | "Fantastical")
  icon_result=":calendar:"
  ;;
"Drafts")
  icon_result=":drafts:"
  ;;
"Notes")
  icon_result=":notes:"
  ;;
"Obsidian")
  icon_result=":obsidian:"
  ;;
"Joplin")
  icon_result=":joplin:"
  ;;
"OmniFocus")
  icon_result=":omni_focus:"
  ;;
"Reminders")
  icon_result=":reminders:"
  ;;
"Todoist")
  icon_result=":todoist:"
  ;;
"Grammarly Editor" | "Grammarly Desktop")
  icon_result=":grammarly:"
  ;;
"Microsoft Word")
  icon_result=":microsoft_word:"
  ;;
"Microsoft Excel")
  icon_result=":microsoft_excel:"
  ;;
"Microsoft PowerPoint")
  icon_result=":microsoft_power_point:"
  ;;
"Microsoft Teams")
  icon_result=":microsoft_teams:"
  ;;
"Keynote")
  icon_result=":keynote:"
  ;;
"Reeder")
  icon_result=":reeder5:"
  ;;
"Raindrop.io")
  icon_result=":raindrop_io:"
  ;;

# --- System & Utilities ------------------------------------------------------
"App Store")
  icon_result=":app_store:"
  ;;
"System Preferences" | "System Settings")
  icon_result=":gear:"
  ;;
"Finder")
  icon_result=":finder:"
  ;;
"Preview")
  icon_result=":preview:"
  ;;
"1Password 7" | "1Password")
  icon_result=":one_password:"
  ;;
"Bitwarden")
  icon_result=":bit_warden:"
  ;;
"CleanMyMac X")
  icon_result=":desktop:"
  ;;
"Zotero")
  icon_result=":zotero:"
  ;;
"Calibre")
  icon_result=":book:"
  ;;
"zoom.us")
  icon_result=":zoom:"
  ;;
"Color Picker")
  icon_result=":color_picker:"
  ;;
"Parallels Desktop")
  icon_result=":parallels:"
  ;;
"VMware Fusion")
  icon_result=":vmware_fusion:"
  ;;
"Pi-hole Remote")
  icon_result=":pihole:"
  ;;
"Insomnia")
  icon_result=":insomnia:"
  ;;
"Transmit")
  icon_result=":transmit:"
  ;;
"Spotlight")
  icon_result=":spotlight:"
  ;;
"Dropbox")
  icon_result=":dropbox:"
  ;;
"Matlab")
  icon_result=":matlab:"
  ;;
"Linear")
  icon_result=":linear:"
  ;;
"Zeplin")
  icon_result=":zeplin:"
  ;;
"Kakoune")
  icon_result=":kakoune:"
  ;;
"Element")
  icon_result=":element:"
  ;;
"FaceTime")
  icon_result=":face_time:"
  ;;
"Raycast")
  icon_result=":raycast:"
  ;;

# --- Default Fallback --------------------------------------------------------
"Default")
  icon_result=":default:"
  ;;
*)
  icon_result=":default:"
  ;;
esac

echo $icon_result
