_: {
  xdg.dataFile."blender/scripts/startup/developer_preferences.py".text = ''
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
}
