{
  dev = [
    ["rhproject" "dotnet new rhino -sample"]
    ["ghproject" "dotnet new gh2 -sample"]
    ["yakb" "yak build"]
    ["rhcode" "rhinocode"]
  ];
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
