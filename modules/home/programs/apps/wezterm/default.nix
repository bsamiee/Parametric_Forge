# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/wezterm/default.nix
# ----------------------------------------------------------------------------
# WezTerm outer-command-deck owner: typed rows (keys, deck commands, quick-select patterns, floats, workspaces, fonts, plugin
# pins) project into generated Lua data + a colors TOML; deck.lua and events.lua are the only static interpreters.
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
  pluginSrc = row:
    pkgs.fetchFromGitHub {
      inherit (row) owner repo rev hash;
    };
  syncPanesSrc = pluginSrc manifest.extensions.wezterm-plugins.rows.sync-panes;
  weztermTypesSrc = pluginSrc manifest.extensions.wezterm-plugins.rows.wezterm-types;

  # --- [FONT_ROW]
  # The font owner's WezTerm projection: chain, per-family leading, shaping features, and the font override path all arrive
  # from config.forge.fonts; deck.lua interprets them.
  fontRow = config.forge.fonts.projections.luaFont;

  # --- [WORKSPACE_ROWS]
  # One row = picker entry + zellij session identity + cwd + float policy. The workspace name IS the inner zellij session name, so windows in
  # different workspaces never mirror one shared session; the default workspace keeps the historical `main` session. The cwd seeds a
  # brand-new session's first pane and the workspace scratch float only: a live or rebuilt session keeps its own pane directories.
  mkWorkspace = name: label: cwd: {
    inherit name label cwd;
    float = "utility";
  };
  workspaceRows = [
    (mkWorkspace "main" "[MAIN]" homeDir)
  ];
  defaultWorkspace = "main";

  # --- [ACTION_BUS_ROWS_QUICK_SELECT_PATTERNS_HYPERLINK_RULES]
  # `select` names a deck.lua action arm for the captured span (edit opens the span in an editor float); rows without it keep the native
  # clipboard default.
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
  # One registry feeds the command palette, the launcher menu, and key rows. Each row spawns its command in a shaped float window;
  # `destructive` rows pass the deck confirm gate before acting; `scope = "workspace"` keys the float singleton per workspace and takes the
  # active workspace row's float shape.
  commandRows = [
    {
      id = "redeploy-build";
      label = "deploy: redeploy build";
      float = "log";
      args = ["${profileBin}/redeploy" "--build"];
    }
    {
      id = "redeploy-switch";
      label = "deploy: redeploy SWITCH";
      float = "log";
      destructive = true;
      args = ["${profileBin}/redeploy" "--switch"];
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
      args = ["${profileBin}/zsh" "-l"];
    }
  ];

  # --- [PURE_DATA_SETTINGS_RENDERED_VIA_LIB_GENERATORS_TOLUA]
  # Constructor/env-dependent values live in deck.lua; the two sets stay disjoint so the single-writer merge never collides.
  settings = {
    color_scheme = "forge-dracula";
    check_for_updates = false; # the cask pin owns updates; check_update state stays inert

    # Window
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

    # Cursor
    default_cursor_style = "SteadyBar";
    cursor_thickness = 2;
    force_reverse_video_cursor = true;

    # Behavior (rows differ from the documented defaults; the mux-process close list is unread under NeverPrompt)
    native_macos_fullscreen_mode = true;
    enable_kitty_keyboard = true;
    switch_to_last_active_tab_when_closing_tab = true;
    adjust_window_size_when_changing_font_size = false;
    window_close_confirmation = "NeverPrompt";
    use_cap_height_to_scale_fallback_fonts = true;
    # Silent bell.
    audible_bell = "Disabled";

    # Input seam: both Option keys send ESC-prefixed bytes (left is the default, right defaults to composed), so Alt-C reaches fzf.
    disable_default_key_bindings = true;
    send_composed_key_when_right_alt_is_pressed = false;

    # Outer identity chrome: retro tab bar, theme-projected via the scheme TOML. Hidden at one tab — the zellij zjstatus bar is the ONE standing
    # top bar; this bar exists only when a second WezTerm tab makes it informative.
    use_fancy_tab_bar = false;
    hide_tab_bar_if_only_one_tab = true;
    tab_max_width = 32;
    show_new_tab_button_in_tab_bar = false;

    # Command palette + char-select chrome
    command_palette_bg_color = roles.surface.raised.hex;
    command_palette_fg_color = roles.accent.primary.hex;
    command_palette_rows = 10;
    command_palette_font_size = fontRow.size;
    char_select_bg_color = roles.surface.raised.hex;
    char_select_fg_color = roles.accent.primary.hex;
    char_select_font_size = fontRow.size;

    # Performance: the documented front_end default reverted to OpenGL (20240128); WebGpu is the Metal path on macOS.
    front_end = "WebGpu";
    max_fps = 120;
    scrollback_lines = 5000;

    # Outer plane rows (pure data)
    default_workspace = defaultWorkspace;
    quick_select_patterns = map (r: r.regex) (lib.sort (a: b: a.priority < b.priority) quickSelectRows);
    quick_select_remove_styling = true;
    # Mux auth-sock pin: every mux-spawned pane rides the 1Password agent, also when a login restores WezTerm before the gui-env
    # replay (environments/shell.nix) points the launchd domain at it.
    default_ssh_auth_sock = config.forge.ssh.identityAgent;
  };

  # --- [GENERATED_LUA_DATA_ENTRY_POINT]
  rows = {
    paths = {
      zsh = "${profileBin}/zsh";
      zellij = "${pkgs.zellij}/bin/zellij";
      nvim = "${profileBin}/nvim";
    };
    plugins.sync_panes = "${syncPanesSrc}";
    font = fontRow;
    # Registry float rows are singletons: a live float focuses instead of duplicating. Synthesized floats (quick-edit) never set reuse.
    commands = map (r: r // {reuse = true;}) commandRows;
    keys =
      map (r: {
        inherit (r) id key mods action class;
        destructive = r.destructive or false;
      })
      chordRows;
    floats = floatRows;
    workspaces = workspaceRows;
    quick_select = quickSelectRows;
    # WezTerm-host nerdfont identifiers for palette entries — data rows, so deck.lua carries no private literals.
    palette_icons = {
      command = "md_dock_window";
      quick_select = "md_select_search";
    };
    theme.roles = projections.rolesHex;
  };
  rowsLua = pkgs.writeText "wezterm-rows.lua" ''
    -- Generated register projection; interpreters are deck.lua and events.lua.
    return ${lib.generators.toLua {} rows}
  '';
  weztermLua = pkgs.writeText "wezterm-entry.lua" ''
    -- Generated entry point: pure-data settings land first, interpreters own constructors, callbacks, and event handlers.
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
  luarc = pkgs.writeText "wezterm-luarc.json" (builtins.toJSON {
    "$schema" = "https://raw.githubusercontent.com/LuaLS/vscode-lua/master/setting/schema.json";
    runtime.version = "Lua 5.4";
    workspace = {
      library = ["${weztermTypesSrc}/lua"];
      checkThirdParty = false;
    };
    diagnostics.globals = ["wezterm"];
  });
in {
  xdg.configFile."wezterm" = {
    source = pkgs.linkFarm "wezterm-config" {
      "deck.lua" = ./deck.lua;
      "events.lua" = ./events.lua;
      "wezterm.lua" = weztermLua;
      "rows.lua" = rowsLua;
      "colors/forge-dracula.toml" = schemeToml;
      ".luarc.json" = luarc;
    };
    recursive = false;
  };
}
