{
  config,
  lib,
  pkgs,
  ...
}: let
  kernel = lib.escapeShellArg "${config.home.homeDirectory}/Library/Application Support/McNeel/Rhinoceros/9.0/Plug-ins/Grasshopper (b45a29b1-4343-4035-989e-044e8580d9cf)/grasshopper_kernel.xml";
in {
  home.activation.setGrasshopperDeveloperSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [[ -f ${kernel} ]]; then
      updated="$(mktemp)"
      ${lib.getExe pkgs.yq-go-current} -p xml -o xml '(.Fragment.items.item[] | select(.+@name == "ObjectServer:TrackPluginLoading" or .+@name == "Widget.Profiler.Show" or .+@name == "Ribbon:ShowObscure")).+content = "true"' ${kernel} > "$updated"
      /usr/bin/cmp -s "$updated" ${kernel} || if /usr/bin/pgrep -qx Rhinoceros; then noteEcho "Rhino is running: Grasshopper developer settings wait for the next switch"; else run cp "$updated" ${kernel}; fi
      rm -f "$updated"
    fi
  '';
}
