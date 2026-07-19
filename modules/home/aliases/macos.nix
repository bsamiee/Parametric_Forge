# Title         : macos.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/aliases/macos.nix
# ----------------------------------------------------------------------------
# Darwin-bound register rows: expansions resolve only against macOS binaries or the Rhino PATH entry, so the register gates this file on host.os.
{
  dev = [
    ["rhproject" "dotnet new rhino -sample" "Rhino plugin template"]
    ["ghproject" "dotnet new grasshopper -sample" "Grasshopper template"]
    ["yakb" "yak build" "Package Rhino plugins"]
    ["rhcode" "rhinocode" "Rhino script compiler"]
  ];
  macos = [
    ["awake" "caffeinate -dims" "Prevent sleep"]
    ["reveal" "open -R" "Reveal in Finder"]
    ["lsapps" "ls /Applications" "List installed applications"]
    ["o" "open" "Open with default app"]
    ["oo" "open ." "Open cwd in Finder"]
    ["qq" "qlmanage -p 2>/dev/null" "Quick Look preview"]
  ];
  network = [
    ["flushdns" "sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder" "Flush macOS DNS cache" "sudo"]
  ];
}
