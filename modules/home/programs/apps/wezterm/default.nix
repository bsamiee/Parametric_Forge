# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/wezterm/default.nix
# ----------------------------------------------------------------------------
# WezTerm outer-command-deck owner: typed rows (keys, deck commands, quick-select patterns, floats, ssh domains, workspaces, fonts, plugin
# pins) project into generated Lua data + a colors TOML; deck.lua and events.lua are the only static interpreters. A build-time
# validator gates activation on Lua syntax, plugin payloads, and action-dispatch totality.
{
  config,
  forgeToolchainEnvFor,
  lib,
  pkgs,
  ...
}: let
  inherit (config.forge.theme) roles projections;
  chordRows = config.forge.chords.wezterm.rows;
  sshHosts = config.forge.ssh.hosts;
  manifest = import ../../../../../overlays/manifest.nix;
  profileBin = "/etc/profiles/per-user/${config.home.username}/bin";
  homeDir = config.home.homeDirectory;
  toolchainEnv = forgeToolchainEnvFor {
    home = homeDir;
    username = config.home.username;
    xdgCacheHome = config.xdg.cacheHome;
  };

  # --- [PLUGIN_PINS_MANIFEST_ROWS_FILE_STORE_PATH_LOADS_ONLY]
  pluginSrc = row:
    pkgs.fetchFromGitHub {
      inherit (row) owner repo rev hash;
    };
  syncPanesSrc = pluginSrc manifest.extensions.wezterm-plugins.rows.sync-panes;
  weztermTypesSrc = pluginSrc manifest.extensions.wezterm-plugins.rows.wezterm-types;

  # --- [FONT_ROW]
  # The font owner's WezTerm projection: chain, per-family leading, shaping features, and the forge-font override path all arrive
  # from config.forge.fonts; deck.lua interprets them.
  fontRow = config.forge.fonts.projections.luaFont;

  # --- [WORKSPACE_ROWS]
  # One row = picker entry + zellij session identity + cwd + float policy. The workspace name IS the inner zellij session name, so windows in
  # different workspaces never mirror one shared session; the default workspace keeps the estate's historical `main` session.
  workspaceRoot = "${homeDir}/Developer";
  mkWorkspace = name: label: source: {
    inherit name label;
    cwd = "${workspaceRoot}/${source}";
    float = "utility";
  };
  workspaceRows = [
    (mkWorkspace "main" "[FORGE]" "Parametric_Forge")
    (mkWorkspace "rasm" "[RASM]" "Rasm")
  ];
  defaultWorkspace = "main";

  # --- [SSH_DOMAIN_ROWS_SSH_REGISTRY_ROWS_TRANSPORT_ONLY_NEVER_PERSISTENCE]
  sshDomainRows =
    map (h: {
      name = "SSH:${h.name}";
      remote_address = h.hostName;
      username = h.user;
      multiplexing = "None";
    })
    (lib.attrValues sshHosts);

  # --- [ACTION_BUS_ROWS_QUICK_SELECT_PATTERNS_HYPERLINK_RULES]
  # `select` names a deck.lua action arm for the captured span (edit opens the span in an editor float, domain opens the aliased SSH window);
  # rows without it keep the native clipboard default.
  hostAliasAlternation =
    lib.concatStringsSep "|"
    (map lib.escapeRegex (lib.unique (lib.concatMap (h: h.aliases) (lib.attrValues sshHosts))));
  hostDomains = lib.listToAttrs (lib.concatMap (
    h: map (a: lib.nameValuePair a "SSH:${h.name}") (lib.unique h.aliases)
  ) (lib.attrValues sshHosts));
  quickSelectRows =
    [
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
    ]
    ++ lib.optional (hostAliasAlternation != "") {
      id = "host-alias";
      regex = "\\b(${hostAliasAlternation})\\b";
      priority = 50;
      select = "domain";
    };
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
  # One registry feeds the command palette, the launcher menu, and key rows. kind: float (spawn command in shaped window) | domain
  # (spawn in mux domain); `destructive` rows pass the deck confirm gate before acting; `scope = "workspace"` keys the float singleton
  # per workspace and takes the active workspace row's float shape.
  commandRows =
    [
      {
        id = "redeploy-check";
        label = "forge: redeploy check";
        kind = "float";
        float = "log";
        args = ["${profileBin}/forge-redeploy" "--check-only"];
      }
      {
        id = "redeploy-switch";
        label = "forge: redeploy SWITCH";
        kind = "float";
        float = "log";
        destructive = true;
        args = ["${profileBin}/forge-redeploy" "--switch"];
      }
      {
        id = "telemetry";
        label = "deck: system telemetry";
        kind = "float";
        float = "log";
        args = ["${pkgs.bottom}/bin/btm"];
      }
      {
        id = "scratch";
        label = "deck: scratch shell";
        kind = "float";
        float = "utility";
        scope = "workspace";
        args = ["${profileBin}/zsh" "-l"];
      }
    ]
    ++ map (d: {
      id = "attach-${d.name}";
      label = "deck: open ${d.name} window";
      kind = "domain";
      domain = d.name;
    })
    sshDomainRows
    # Remote state through the VFS: one float per host browses sftp://<host>/ in Yazi — remote registers and logs inspected through the same
    # themed file UI as local state, identity via the pinned agent socket.
    ++ map (h: {
      id = "sftp-${h.name}";
      label = "remote: browse ${h.name} files (sftp)";
      kind = "float";
      float = "utility";
      args = ["${profileBin}/forge-yazi.sh" "sftp://${h.name}/"];
    }) (lib.attrValues sshHosts);

  # --- [PURE_DATA_SETTINGS_RENDERED_VIA_LIB_GENERATORS_TOLUA]
  # Constructor/env-dependent values live in deck.lua; the two sets stay disjoint (validated below) so the single-writer merge never collides.
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
    ssh_domains = sshDomainRows;
    quick_select_patterns = map (r: r.regex) (lib.sort (a: b: a.priority < b.priority) quickSelectRows);
    quick_select_remove_styling = true;
    # Mux auth-sock pin: every mux-spawned pane and SSH domain rides the 1Password agent instead of the identity-less Apple launchd SSH_AUTH_SOCK.
    default_ssh_auth_sock = config.forge.ssh.identityAgent;
  };

  # Config keys the interpreters own; a settings row on this list is a shallow-merge collision and fails eval.
  luaOwnedKeys = [
    "font"
    "font_size"
    "line_height"
    "harfbuzz_features"
    "keys"
    "key_tables" # sync-panes writes its broadcast table here
    "mouse_bindings"
    "default_prog"
    "set_environment_variables"
    "launch_menu"
    "command_palette_font"
  ];
  settingsCollisions = lib.intersectLists luaOwnedKeys (lib.attrNames settings);

  dupesOf = xs: lib.attrNames (lib.filterAttrs (_: c: c > 1) (lib.foldl' (acc: x: acc // {${x} = (acc.${x} or 0) + 1;}) {} xs));
  commandDupes = dupesOf (map (r: r.id) commandRows);
  patternDupes = dupesOf (map (r: r.id) quickSelectRows) ++ dupesOf (map (r: toString r.priority) quickSelectRows);
  selectIds = lib.unique (builtins.filter (s: s != null) (map (r: r.select or null) quickSelectRows));
  badSelects = builtins.filter (s: !(lib.elem s ["edit" "domain"])) selectIds;
  badKinds = lib.unique (map (r: r.kind) (builtins.filter (r: !(lib.elem r.kind ["float" "domain"])) commandRows));
  badFloatRefs =
    map (r: r.id) (builtins.filter (r: r.kind == "float" && !(floatRows ? ${r.float})) commandRows)
    ++ map (r: r.name) (builtins.filter (r: !(floatRows ? ${r.float})) workspaceRows);
  chordDupes = dupesOf (map (r: "${r.mods}+${r.key}") chordRows);
  workspaceDupes = dupesOf (map (r: r.name) workspaceRows);

  # --- [GENERATED_LUA_DATA_ENTRY_POINT]
  rows = {
    # The oldest wezterm@nightly build every deck.lua action, option, and overlay exists in; deck.lua faults the config load below it.
    nightly_floor = "20260707";
    paths = {
      path = lib.concatStringsSep ":" toolchainEnv.launchdPathEntries;
      zellij = "${pkgs.zellij}/bin/zellij";
      nvim = "${profileBin}/nvim";
    };
    host_domains = hostDomains;
    plugins.sync_panes = "${syncPanesSrc}";
    font = fontRow;
    # Registry float rows are singletons: a live float focuses instead of duplicating. Synthesized floats (quick-edit) never set reuse.
    commands = map (r: r // {reuse = r.kind == "float";}) commandRows;
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
    theme = {
      roles = projections.rolesHex;
      # Shared remote-context badge: the strip's non-local domain chip reads the same glyph + hue as the prompt hostname badge (events.lua).
      badges.remote = {inherit (projections.contextBadges.remote) glyph color;};
    };
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
  actionIds = map (r: r.action) chordRows;

  # Build-time validator: Lua syntax, plugin payload shape, dispatch totality (chord actions AND quick-select select arms both resolve in deck.lua).
  # The grep proves the arm shape itself — a ["id"] table key or an == "id" equality dispatch — so a log string literal never false-passes.
  configDir =
    pkgs.runCommand "wezterm-config" {
      nativeBuildInputs = [pkgs.lua5_4];
      actions = lib.concatStringsSep " " (lib.unique (actionIds ++ selectIds));
    } ''
      mkdir -p "$out/colors"
      cp ${./deck.lua} "$out/deck.lua"
      cp ${./events.lua} "$out/events.lua"
      cp ${weztermLua} "$out/wezterm.lua"
      cp ${rowsLua} "$out/rows.lua"
      cp ${schemeToml} "$out/colors/forge-dracula.toml"
      cp ${luarc} "$out/.luarc.json"
      for f in "$out"/*.lua; do
        luac -p "$f"
      done
      test -f ${syncPanesSrc}/plugin/init.lua
      test -d ${weztermTypesSrc}/lua
      for a in $actions; do
        grep -Eq "\[\"$a\"\]|== \"$a\"" "$out/deck.lua" || {
          echo "wezterm validator: chord action '$a' has no deck.lua dispatch arm" >&2
          exit 1
        }
      done
    '';
in {
  config = {
    assertions = [
      {
        assertion = settingsCollisions == [];
        message = "wezterm: settings keys collide with interpreter-owned config keys: ${lib.concatStringsSep ", " settingsCollisions}";
      }
      {
        assertion = commandDupes == [];
        message = "wezterm: duplicate command ids: ${lib.concatStringsSep ", " commandDupes}";
      }
      {
        assertion = patternDupes == [];
        message = "wezterm: quick-select id/priority collisions: ${lib.concatStringsSep ", " patternDupes}";
      }
      {
        assertion = badSelects == [];
        message = "wezterm: quick-select rows carry unknown select arms: ${lib.concatStringsSep ", " badSelects}";
      }
      {
        assertion = badKinds == [];
        message = "wezterm: command rows carry unknown kinds: ${lib.concatStringsSep ", " badKinds}";
      }
      {
        assertion = badFloatRefs == [];
        message = "wezterm: command rows reference undeclared float shapes: ${lib.concatStringsSep ", " badFloatRefs}";
      }
      {
        assertion = chordDupes == [];
        message = "wezterm: duplicate chord key+mods rows (guard wrap and dispatch both collide): ${lib.concatStringsSep ", " chordDupes}";
      }
      {
        assertion = workspaceDupes == [];
        message = "wezterm: duplicate workspace row names: ${lib.concatStringsSep ", " workspaceDupes}";
      }
    ];

    xdg.configFile."wezterm" = {
      source = configDir;
      recursive = false;
    };
  };
}
