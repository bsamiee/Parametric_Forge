{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.forge.theme) roles projections;
  chordRows = config.forge.chords.wezterm.rows;
  manifest = import ../../../../../overlays/manifest.nix;
  profileBin = "/etc/profiles/per-user/${config.home.username}/bin";
  homeDir = config.home.homeDirectory;

  # --- [PLUGIN_PINS_MANIFEST_ROWS_FILE_STORE_PATH_LOADS_ONLY]
  syncPanesSrc = pkgs.fetchFromGitHub {
    inherit (manifest.extensions.wezterm-plugins.rows.sync-panes) owner repo rev hash;
  };

  # --- [FONT_ROW]
  fontRow = config.forge.fonts.projections.luaFont;

  # --- [WORKSPACE_ROWS]
  mkWorkspace = name: label: cwd: {
    inherit name label cwd;
    float = "utility";
  };
  workspaceRows = [
    (mkWorkspace "main" "[MAIN]" homeDir)
  ];
  defaultWorkspace = "main";

  # --- [ACTION_BUS_ROWS_QUICK_SELECT_PATTERNS_HYPERLINK_RULES]
  quickSelectRows = [
    {
      id = "nix-store-path";
      regex = "/nix/store/[a-z0-9]{32}-[a-zA-Z0-9+._?=-]+";
      priority = 10;
    }
    {
      id = "flake-ref";
      regex = "(github|gitlab|sourcehut):[A-Za-z0-9._-]+/[A-Za-z0-9._-]+(/[A-Za-z0-9._/-]+)?";
      priority = 20;
    }
    {
      id = "file-span";
      regex = "[A-Za-z0-9~._/-]+[.][a-z]+:[0-9]+(:[0-9]+)?";
      priority = 30;
      select = "edit";
    }
    {
      id = "issue-id";
      regex = "[A-Z]{2,10}-[0-9]{1,6}|#[0-9]{2,6}";
      priority = 40;
    }
  ];
  # --- [FLOATING_UTILITY_DECK_ROWS]
  floatRows = {
    utility = {
      width = 120;
      height = 32;
      level = "AlwaysOnTop";
      opacity = 0.92;
      decorations = "RESIZE";
    };
    log = {
      width = 150;
      height = 24;
      level = "AlwaysOnTop";
      opacity = 0.88;
      decorations = "RESIZE";
    };
  };

  # --- [COMMAND_DECK_ROWS]
  commandRows = [
    {
      id = "redeploy-build";
      label = "deploy: redeploy build";
      float = "log";
      args = ["${profileBin}/redeploy" "build"];
    }
    {
      id = "redeploy-switch";
      label = "deploy: redeploy SWITCH";
      float = "log";
      destructive = true;
      args = ["${profileBin}/redeploy" "switch"];
    }
    {
      id = "telemetry";
      label = "deck: system telemetry";
      float = "log";
      args = ["${pkgs.bottom}/bin/btm"];
    }
    {
      id = "scratch";
      label = "deck: scratch shell";
      float = "utility";
      scope = "workspace";
      args = [config.forge.shell "-l"];
    }
  ];

  # --- [PURE_DATA_SETTINGS_RENDERED_VIA_LIB_GENERATORS_TOLUA]
  settings = {
    color_scheme = "forge-dracula";
    check_for_updates = false;

    window_background_opacity = 0.85;
    macos_window_background_blur = 20;
    window_decorations = "RESIZE";
    window_padding = {
      left = 10;
      right = 10;
      top = 5;
      bottom = 10;
    };
    initial_cols = 150;
    initial_rows = 34;
    inactive_pane_hsb = {
      saturation = 0.75;
      brightness = 0.75;
    };

    default_cursor_style = "SteadyBar";
    cursor_thickness = 2;
    force_reverse_video_cursor = true;

    native_macos_fullscreen_mode = true;
    enable_kitty_keyboard = true;
    switch_to_last_active_tab_when_closing_tab = true;
    adjust_window_size_when_changing_font_size = false;
    window_close_confirmation = "NeverPrompt";
    use_cap_height_to_scale_fallback_fonts = true;
    audible_bell = "Disabled";

    disable_default_key_bindings = true;
    send_composed_key_when_right_alt_is_pressed = false;

    use_fancy_tab_bar = false;
    hide_tab_bar_if_only_one_tab = true;
    tab_max_width = 32;
    show_new_tab_button_in_tab_bar = false;

    command_palette_bg_color = roles.surface.raised.hex;
    command_palette_fg_color = roles.accent.primary.hex;
    command_palette_rows = 10;
    command_palette_font_size = fontRow.size;
    char_select_bg_color = roles.surface.raised.hex;
    char_select_fg_color = roles.accent.primary.hex;
    char_select_font_size = fontRow.size;

    front_end = "WebGpu";
    max_fps = 120;
    scrollback_lines = 5000;

    default_workspace = defaultWorkspace;
    quick_select_patterns = map (r: r.regex) (lib.sort (a: b: a.priority < b.priority) quickSelectRows);
    quick_select_remove_styling = true;
    default_ssh_auth_sock = config.forge.ssh.identityAgent;
  };

  # --- [GENERATED_LUA_DATA_ENTRY_POINT]
  rows = {
    paths = {
      zsh = config.forge.shell;
      zellij = "${pkgs.zellij}/bin/zellij";
      zellij_attach = lib.getExe config.forge.zellij.attach;
      code = "${config.forge.apps.vscode.path}/Contents/Resources/app/bin/code";
    };
    plugins.sync_panes = "${syncPanesSrc}";
    font = fontRow;
    commands = commandRows;
    keys =
      map (r: {
        inherit (r) id key mods action class;
        destructive = r.destructive or false;
      })
      chordRows;
    floats = floatRows;
    workspaces = workspaceRows;
    quick_select = quickSelectRows;
    palette_icons = {
      command = "md_dock_window";
      quick_select = "md_select_search";
    };
    theme.roles = projections.rolesHex;
  };
  rowsLua = pkgs.writeText "wezterm-rows.lua" ''
    return ${lib.generators.toLua {} rows}
  '';
  weztermLua = pkgs.writeText "wezterm-entry.lua" ''
    local wezterm = require("wezterm")
    local config = wezterm.config_builder()
    local settings = ${lib.generators.toLua {} settings}
    for k, v in pairs(settings) do
      config[k] = v
    end
    require("deck").apply(config)
    require("events").apply(config)
    return config
  '';
  schemeToml = (pkgs.formats.toml {}).generate "forge-dracula.toml" {
    colors = projections.weztermColorScheme;
    metadata.name = "forge-dracula";
  };
in {
  xdg.configFile."wezterm" = {
    source = pkgs.linkFarm "wezterm-config" {
      "deck.lua" = ./deck.lua;
      "events.lua" = ./events.lua;
      "wezterm.lua" = weztermLua;
      "rows.lua" = rowsLua;
      "colors/forge-dracula.toml" = schemeToml;
    };
    recursive = false;
  };
}
