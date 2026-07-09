# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/wezterm/default.nix
# ----------------------------------------------------------------------------
# WezTerm outer-command-deck owner: typed rows (keys, deck commands, quick-
# select patterns, hyperlink rules, floats, ssh domains, workspaces, fonts,
# plugin pins) project into generated Lua data + a colors TOML; deck.lua and
# events.lua are the only static interpreters. A build-time validator gates
# activation on Lua syntax, plugin payloads, and action-dispatch totality.
{
  config,
  forgeToolchainEnvFor,
  lib,
  pkgs,
  ...
}: let
  inherit (config.forge.theme) palette roles projections;
  chordRows = config.forge.chords.wezterm.rows;
  naming = config.forge.registers.naming;
  sshHosts = config.forge.ssh.hosts;
  manifest = import ../../../../../overlays/manifest.nix;
  profileBin = "/etc/profiles/per-user/${config.home.username}/bin";
  homeDir = config.home.homeDirectory;
  toolchainEnv = forgeToolchainEnvFor {
    home = homeDir;
    username = config.home.username;
    xdgCacheHome = config.xdg.cacheHome;
  };

  # --- Plugin pins (CA-2 manifest rows; file:// store-path loads only) ---------
  pluginSrc = row:
    pkgs.fetchFromGitHub {
      inherit (row) owner repo rev hash;
    };
  syncPanesSrc = pluginSrc manifest.extensions.wezterm-plugins.rows.sync-panes;
  weztermTypesSrc = pluginSrc manifest.extensions.wezterm-plugins.rows.wezterm-types;

  # --- Font row: the font owner's WezTerm projection (modules/home/fonts.nix) --
  # Chain, per-family leading, shaping features, and the forge-font override
  # path all arrive from config.forge.fonts; deck.lua interprets them.
  fontRow = config.forge.fonts.projections.luaFont;

  # --- Workspace rows (CA-1 name policy projection) ----------------------------
  workspaceRoot = "${homeDir}/Documents/99.Github";
  workspaceRows =
    map (r: {
      name = r.slug;
      label = r.display;
      cwd = "${workspaceRoot}/${r.source}";
    })
    (builtins.filter (r: r.domain == "estate-repo") naming);
  defaultWorkspace =
    (lib.findFirst (r: lib.elem "wezterm-workspace-name" r.consumers) {slug = "forge";} naming).slug;

  # --- SSH domain rows (CA-3 host rows; transport-only, never persistence) -----
  sshDomainRows =
    map (h: {
      name = "SSH:${h.name}";
      remote_address = h.hostName;
      username = h.user;
      multiplexing = "None";
    })
    (lib.attrValues sshHosts);

  # --- Action-bus rows: quick-select patterns + hyperlink rules ----------------
  # `select` names a deck.lua action arm for the captured span (edit opens the
  # span in an editor float, domain opens the aliased SSH window); rows
  # without it keep the native clipboard default.
  hostAliasAlternation =
    lib.concatStringsSep "|"
    (lib.concatMap (h: h.aliases ++ [h.tunnelHost]) (lib.attrValues sshHosts));
  hostDomains = lib.listToAttrs (lib.concatMap (
    h: map (a: lib.nameValuePair a "SSH:${h.name}") (lib.unique (h.aliases ++ [h.tunnelHost]))
  ) (lib.attrValues sshHosts));
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
    {
      id = "host-alias";
      regex = "\\b(${hostAliasAlternation})\\b";
      priority = 50;
      select = "domain";
    }
  ];
  hyperlinkRows = [
    # Semantic estate links: forge://<register-domain>[/<row>] opens the
    # register browser float via the open-uri handler.
    {
      id = "forge-scheme";
      regex = "forge://[A-Za-z0-9/@._:-]+";
      format = "$0";
    }
  ];

  # --- Floating utility deck rows -----------------------------------------------
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

  # --- Command deck rows ----------------------------------------------------------
  # One registry feeds the command palette, the launcher menu, and key rows.
  # kind: float (spawn command in shaped window) | domain (spawn in mux domain)
  # | builtin (deck.lua dispatch arm). `destructive` rows confirm on nightly.
  commandRows =
    [
      {
        id = "browse-registers";
        label = "forge: browse registers";
        kind = "float";
        float = "utility";
        args = ["${profileBin}/forge-browse"];
      }
      {
        id = "receipts-browse";
        label = "forge: browse receipts";
        kind = "float";
        float = "utility";
        args = ["${profileBin}/forge-receipts" "--fzf"];
      }
      {
        id = "receipts-follow";
        label = "forge: follow receipts (live log)";
        kind = "float";
        float = "log";
        args = ["${profileBin}/forge-receipts" "--follow"];
      }
      {
        id = "tv-channels";
        label = "forge: television channels";
        kind = "float";
        float = "utility";
        args = ["${profileBin}/tv"];
      }
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
        id = "workspace-list";
        label = "forge: workspace receipts";
        kind = "float";
        float = "utility";
        args = ["${profileBin}/forge-workspace" "--list"];
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
        args = ["${profileBin}/zsh" "-l"];
      }
    ]
    ++ map (d: {
      id = "attach-${d.name}";
      label = "deck: open ${d.name} window";
      kind = "domain";
      domain = d.name;
    })
    sshDomainRows;

  # --- Pure-data settings (rendered via lib.generators.toLua) --------------------
  # Constructor/env-dependent values live in deck.lua; the two sets stay
  # disjoint (validated below) so the single-writer merge never collides.
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
    default_cursor_style = "BlinkingBar";
    cursor_thickness = 2;
    cursor_blink_rate = 250;
    force_reverse_video_cursor = true;

    # Behavior
    automatically_reload_config = true;
    native_macos_fullscreen_mode = true;
    enable_kitty_keyboard = true;
    switch_to_last_active_tab_when_closing_tab = true;
    adjust_window_size_when_changing_font_size = false;
    window_close_confirmation = "NeverPrompt";
    skip_close_confirmation_for_processes_named = ["bash" "sh" "zsh" "fish" "tmux" "nu"];

    # Input seam
    disable_default_key_bindings = true;
    send_composed_key_when_left_alt_is_pressed = false;
    send_composed_key_when_right_alt_is_pressed = false;
    bypass_mouse_reporting_modifiers = "SHIFT";
    hide_mouse_cursor_when_typing = true;

    # Outer identity chrome: retro tab bar, theme-projected via the scheme TOML.
    # Hidden at one tab — the zellij zjstatus bar is the ONE standing top bar;
    # this bar exists only when a second WezTerm tab makes it informative.
    enable_tab_bar = true;
    use_fancy_tab_bar = false;
    hide_tab_bar_if_only_one_tab = true;
    tab_bar_at_bottom = false;
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

    # Performance
    front_end = "WebGpu";
    max_fps = 120;
    animation_fps = 120;
    scrollback_lines = 5000;

    # Outer plane rows (pure data)
    default_workspace = defaultWorkspace;
    ssh_domains = sshDomainRows;
    quick_select_patterns = map (r: r.regex) (lib.sort (a: b: a.priority < b.priority) quickSelectRows);
  };

  # Config keys the interpreters own; a settings row on this list is a
  # shallow-merge collision and fails eval.
  luaOwnedKeys = [
    "font"
    "font_size"
    "line_height"
    "harfbuzz_features"
    "use_cap_height_to_scale_fallback_fonts"
    "warn_about_missing_glyphs"
    "keys"
    "key_tables" # sync-panes writes its broadcast table here
    "mouse_bindings"
    "default_prog"
    "set_environment_variables"
    "hyperlink_rules"
    "launch_menu"
    "command_palette_font"
    "quick_select_remove_styling"
  ];
  settingsCollisions = lib.intersectLists luaOwnedKeys (lib.attrNames settings);

  dupesOf = xs: lib.attrNames (lib.filterAttrs (_: c: c > 1) (lib.foldl' (acc: x: acc // {${x} = (acc.${x} or 0) + 1;}) {} xs));
  commandDupes = dupesOf (map (r: r.id) commandRows);
  patternDupes = dupesOf (map (r: r.id) quickSelectRows) ++ dupesOf (map (r: toString r.priority) quickSelectRows);
  selectIds = lib.unique (builtins.filter (s: s != null) (map (r: r.select or null) quickSelectRows));
  badSelects = builtins.filter (s: !(lib.elem s ["edit" "domain"])) selectIds;

  # --- Generated Lua data + entry point -------------------------------------------
  rows = {
    nightly_floor = "20260707";
    receipts_log = "${homeDir}/Library/Logs/forge-wezterm.receipts.log";
    paths = {
      path = lib.concatStringsSep ":" toolchainEnv.launchdPathEntries;
      zellij = "${pkgs.zellij}/bin/zellij";
      nvim = "${profileBin}/nvim";
    };
    host_domains = hostDomains;
    plugins.sync_panes = "${syncPanesSrc}";
    font = fontRow;
    keys =
      map (r: {
        inherit (r) id key mods action class;
        destructive = r.destructive or false;
        requires_nightly = r.requiresNightly or false;
      })
      chordRows;
    commands = commandRows;
    floats = floatRows;
    workspaces = workspaceRows;
    quick_select = quickSelectRows;
    hyperlinks = hyperlinkRows;
    theme = {
      roles = lib.mapAttrs (_: lib.mapAttrs (_: c: c.hex)) {inherit (roles) surface text accent state diff ui;};
      git =
        lib.mapAttrs (_: g: {
          color = g.color.hex;
          inherit (g) glyph;
        })
        roles.git;
      accent = palette.cyan.hex;
    };
  };
  rowsLua = pkgs.writeText "wezterm-rows.lua" ''
    -- Generated register projection; interpreters are deck.lua and events.lua.
    return ${lib.generators.toLua {} rows}
  '';
  weztermLua = pkgs.writeText "wezterm-entry.lua" ''
    -- Generated entry point: pure-data settings land first, interpreters own
    -- constructors, callbacks, and event handlers.
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

  # Build-time validator: Lua syntax, plugin payload shape, dispatch totality
  # (chord actions AND quick-select select arms both resolve in deck.lua).
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
        grep -q "\"$a\"" "$out/deck.lua" || {
          echo "wezterm validator: chord action '$a' has no deck.lua dispatch arm" >&2
          exit 1
        }
      done
    '';

  # --- forge-workspace: name-policy router (workspace + domain + Space bridge) ---
  namingJson = pkgs.writeText "forge-workspace-rows.json" (builtins.toJSON workspaceRows);
  forgeWorkspace = pkgs.writeShellApplication {
    name = "forge-workspace";
    runtimeInputs = [pkgs.coreutils pkgs.jq pkgs.gawk pkgs.gnugrep];
    text = ''
      # Resolves a CA-1 name-policy slug to WezTerm workspace + mux window and
      # the desktop-Space bridge. Provider dispatch: none (default) degrades
      # with an explicit receipt row — never silent fallthrough.
      rows="${namingJson}"
      wezterm_bin="''${FORGE_WEZTERM_BIN:-/Applications/WezTerm.app/Contents/MacOS/wezterm}"
      zellij_bin="${pkgs.zellij}/bin/zellij"
      layout="''${ZELLIJ_DEFAULT_LAYOUT:-default}"
      receipt_log="''${FORGE_WORKSPACE_RECEIPT_LOG:-$HOME/Library/Logs/forge-workspace.receipts.log}"
      provider="''${FORGE_SPACE_PROVIDER:-none}"

      usage() { printf 'Usage: forge-workspace [SLUG] | --list | --json\n'; }

      emit() { # $1=slug $2=action $3=result $4=detail
        local ts
        TZ=UTC0 printf -v ts '%(%Y-%m-%dT%H:%M:%SZ)T' "$EPOCHSECONDS"
        mkdir -p "$(dirname "$receipt_log")"
        printf 'ts=%s\towner=forge-workspace\tslug=%s\taction=%s\tprovider=%s\tspace=%s\tresult=%s\tdetail=%s\n' \
          "$ts" "$1" "$2" "$provider" "$5" "$3" "''${4:--}" >>"$receipt_log"
      }

      # --no-auto-start on every cli call: a stale socket must fail the probe,
      # never fork a daemonized mux server (the recorded litter hazard).
      live_workspaces() {
        if [ -n "''${WEZTERM_UNIX_SOCKET:-}" ] && [ -x "$wezterm_bin" ]; then
          "$wezterm_bin" cli --no-auto-start list --format json 2>/dev/null | jq -r '[.[].workspace] | unique | .[]'
        fi
      }

      case "''${1:-}" in
        --help | -h)
          usage
          exit 0
          ;;
        --json)
          jq --argjson live "$(live_workspaces | jq -R . | jq -s .)" \
            'map(. + {live: (.name as $n | $live | index($n) != null)})' "$rows"
          exit 0
          ;;
        --list | "")
          live_set="$(live_workspaces)"
          {
            printf 'SLUG\tLABEL\tCWD\tLIVE\n'
            while IFS=$'\t' read -r slug label cwd; do
              live=no
              grep -qx "$slug" <<<"$live_set" && live=yes
              printf '%s\t%s\t%s\t%s\n' "$slug" "$label" "$cwd" "$live"
            done < <(jq -r '.[] | [.name, .label, .cwd] | @tsv' "$rows")
          } | awk -F'\t' '{printf "%-16s %-24s %-56s %s\n", $1, $2, $3, $4}'
          exit 0
          ;;
      esac

      slug="$1"
      row="$(jq -c --arg s "$slug" '.[] | select(.name == $s)' "$rows")"
      if [ -z "$row" ]; then
        emit "$slug" resolve error "unknown slug" "-"
        printf 'forge-workspace: unknown slug %s\n' "$slug" >&2
        exit 64
      fi
      cwd="$(jq -r '.cwd' <<<"$row")"

      # Space bridge: provider table decides; `none` is a declared degrade.
      space_state="degrade:provider-none"
      case "$provider" in
        none) : ;;
        *)
          space_state="degrade:provider-unknown"
          ;;
      esac

      if [ -z "''${WEZTERM_UNIX_SOCKET:-}" ] || [ ! -x "$wezterm_bin" ]; then
        emit "$slug" spawn error "gui unavailable (no WEZTERM_UNIX_SOCKET)" "$space_state"
        printf 'forge-workspace: run inside a WezTerm session (workspace switch is a GUI action)\n' >&2
        exit 69
      fi

      # Explicit prog mirrors the deck seam: the workspace's slug-named zellij
      # session, never the shared default_prog session.
      pane_id="$("$wezterm_bin" cli --no-auto-start spawn --new-window --workspace "$slug" --cwd "$cwd" -- \
        "$zellij_bin" --layout "$layout" attach --create "$slug" 2>&1)" || {
        emit "$slug" spawn error "$pane_id" "$space_state"
        printf 'forge-workspace: spawn failed: %s\n' "$pane_id" >&2
        exit 1
      }
      emit "$slug" spawn ok "pane_id=$pane_id" "$space_state"
      printf '%s\t%s\tpane_id=%s\tspace=%s\n' "$slug" "$cwd" "$pane_id" "$space_state"
    '';
  };
  workspaceCompletion = pkgs.writeTextDir "share/zsh/site-functions/_forge-workspace" ''
    #compdef forge-workspace
    _arguments \
      '1:workspace:(${lib.concatMapStringsSep " " (r: r.name) workspaceRows})' \
      '--list[table of rows with live state]' \
      '--json[rows with live state as JSON]'
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
    ];

    home.packages = [forgeWorkspace workspaceCompletion];

    xdg.configFile."wezterm" = {
      source = configDir;
      recursive = false;
    };
  };
}
