{
  macos = [
    ["awake" "caffeinate -dims"]
    ["reveal" "open -R"]
    ["lsapps" "ls /Applications"]
    ["o" "open"]
    ["oo" "open ."]
    ["qq" "qlmanage -p 2>/dev/null"]
  ];
  network = [
    ["flushdns" "sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder"]
  ];
}
