{pkgs, ...}: let
  pin = (builtins.fromJSON (builtins.readFile ../../../../../overlays/_sources/generated.json)).blender-debugpy;
  debugpy = pkgs.runCommand "blender-debugpy-${pin.version}" {src = pkgs.fetchurl {inherit (pin.src) url sha256;};} ''
    mkdir -p "$out"
    tar -xzf "$src" -C "$out" --strip-components=2 "debugpy-${pin.version}/src/debugpy"
  '';
in {
  xdg.dataFile = {
    "blender/scripts/modules/debugpy".source = "${debugpy}/debugpy";
    "blender/scripts/startup/debugpy_listen.py".text = ''
      import os
      import sys

      import bpy


      def register():
          if port := os.environ.get("BLENDER_DEBUGPY_PORT"):
              sys.path[:0] = [path for path in bpy.utils.script_paths(subdir="modules") if path not in sys.path]
              import debugpy

              debugpy.listen(("127.0.0.1", int(port)))
              debugpy.wait_for_client()
    '';
    "blender/scripts/startup/developer_preferences.py".text = ''
      import bpy


      def register():
          preferences = bpy.context.preferences
          preferences.view.show_developer_ui = True
          preferences.view.show_tooltips_python = True
          preferences.filepaths.use_scripts_auto_execute = True
          experimental = preferences.experimental
          for name in ("use_new_curves_tools", "use_3d_texture_paint", "use_extended_asset_browser", "use_shader_node_previews", "use_extensions_debug", "show_asset_debug_info", "use_cycles_debug", "use_eevee_debug", "use_viewport_debug"):
              setattr(experimental, name, True)
    '';
  };
}
