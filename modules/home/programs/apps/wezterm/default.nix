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
  inherit (config.forge.theme) roles projections;
  chordRows = config.forge.chords.wezterm.rows;
  naming = config.forge.registers.naming;
  sshHosts = config.forge.ssh.hosts;
  manifest = import ../../../../../overlays/manifest.nix;
  receiptsFold = import ../../shell-tools/receipts.nix;
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
  # The font owner's WezTerm projection (modules/home/fonts.nix): chain,
  # per-family leading, shaping features, and the forge-font override path
  # all arrive from config.forge.fonts; deck.lua interprets them.
  fontRow = config.forge.fonts.projections.luaFont;

  # --- [WORKSPACE_ROWS_NAME_POLICY_PROJECTION]
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
  # `select` names a deck.lua action arm for the captured span (edit opens the
  # span in an editor float, domain opens the aliased SSH window); rows
  # without it keep the native clipboard default.
  hostAliasAlternation =
    lib.concatStringsSep "|"
    (map lib.escapeRegex (lib.unique (lib.concatMap (h: h.aliases ++ [h.tunnelHost]) (lib.attrValues sshHosts))));
  hostDomains = lib.listToAttrs (lib.concatMap (
    h: map (a: lib.nameValuePair a "SSH:${h.name}") (lib.unique (h.aliases ++ [h.tunnelHost]))
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
  hyperlinkRows = [
    # Semantic estate links: forge://<register-domain>[/...] opens the register
    # browser float scoped to the domain (forge-browse takes one DOMAIN arg).
    {
      id = "forge-scheme";
      regex = "forge://[A-Za-z0-9/@._:-]+";
      format = "$0";
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
  # One registry feeds the command palette, the launcher menu, and key rows.
  # kind: float (spawn command in shaped window) | domain (spawn in mux
  # domain); `destructive` rows pass the deck confirm gate before acting.
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

  # --- [PURE_DATA_SETTINGS_RENDERED_VIA_LIB_GENERATORS_TOLUA]
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
    use_cap_height_to_scale_fallback_fonts = true;
    warn_about_missing_glyphs = true;
    # Bell rings are structured attention: the events.lua bell arm owns the
    # surface (receipt row always, toast when background), never a beep.
    audible_bell = "Disabled";

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
  badKinds = lib.unique (map (r: r.kind) (builtins.filter (r: !(lib.elem r.kind ["float" "domain"])) commandRows));
  badFloatRefs = map (r: r.id) (builtins.filter (r: r.kind == "float" && !(floatRows ? ${r.float})) commandRows);
  chordDupes = dupesOf (map (r: "${r.mods}+${r.key}") chordRows);

  # --- [GENERATED_LUA_DATA_ENTRY_POINT]
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
    # Registry float rows are singletons: a live float focuses instead of
    # duplicating. Synthesized floats (quick-edit, open-uri) never set reuse.
    commands = map (r: r // {reuse = r.kind == "float";}) commandRows;
    keys =
      map (r: {
        inherit (r) id key mods action class;
        destructive = r.destructive or false;
        requires_nightly = r.requiresNightly or false;
      })
      chordRows;
    floats = floatRows;
    workspaces = workspaceRows;
    quick_select = quickSelectRows;
    hyperlinks = hyperlinkRows;
    theme = {
      roles = projections.rolesHex;
      git = projections.gitHex;
      accent = roles.accent.primary.hex;
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
  # (chord actions AND quick-select select arms both resolve in deck.lua). The
  # grep proves the arm shape itself — a ["id"] table key or an == "id"
  # equality dispatch — so a receipt/log string literal never false-passes.
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

  # --- [FORGE_WORKSPACE_NAME_POLICY_ROUTER_WORKSPACE_DOMAIN_SPACE_BRIDGE]
  namingJson = pkgs.writeText "forge-workspace-rows.json" (builtins.toJSON workspaceRows);
  forgeWorkspace = pkgs.writeShellApplication {
    name = "forge-workspace";
    runtimeInputs = [pkgs.coreutils pkgs.jq pkgs.gawk pkgs.gnugrep];
    text = ''
      # Resolves a name-policy slug to WezTerm workspace + mux window and
      # the desktop-Space bridge. Provider dispatch: none (default) degrades
      # with an explicit receipt row — never silent fallthrough.
      rows="${namingJson}"
      wezterm_bin="''${FORGE_WEZTERM_BIN:-/Applications/WezTerm.app/Contents/MacOS/wezterm}"
      zellij_bin="${pkgs.zellij}/bin/zellij"
      layout="''${ZELLIJ_DEFAULT_LAYOUT:-default}"
      receipt_log="''${FORGE_WORKSPACE_RECEIPT_LOG:-$HOME/Library/Logs/forge-workspace.receipts.log}"
      receipt_surface="forge-workspace"
      provider="''${FORGE_SPACE_PROVIDER:-none}"
      ${receiptsFold}

      usage() { printf 'Usage: forge-workspace [SLUG] | --list | --json\n'; }

      emit() { # $1=slug $2=action $3=result $4=detail $5=space
        local ts row
        TZ=UTC0 printf -v ts '%(%Y-%m-%dT%H:%M:%SZ)T' "$EPOCHSECONDS"
        printf -v row 'ts=%s\tslug=%s\taction=%s\tprovider=%s\tspace=%s\tresult=%s\tdetail=%s' \
          "$ts" "$1" "$2" "$provider" "$5" "$3" "''${4:--}"
        append_receipt "$row" \
          || printf 'forge-workspace: WARNING receipt not persisted to %s\n' "$receipt_log" >&2
      }

      # --no-auto-start on every cli call: a stale socket must fail the probe,
      # never fork a daemonized mux server (the recorded litter hazard). The
      # failed probe degrades to an empty live set, never a pipefail abort.
      live_workspaces() {
        if [ -n "''${WEZTERM_UNIX_SOCKET:-}" ] && [ -x "$wezterm_bin" ]; then
          "$wezterm_bin" cli --no-auto-start list --format json 2>/dev/null | jq -r '[.[].workspace] | unique | .[]' || true
        fi
      }

      case "''${1:-}" in
        --help | -h)
          usage
          exit 0
          ;;
        --json)
          jq --argjson live "$(live_workspaces | jq -nR '[inputs]')" \
            'map(. + {live: (.name as $n | $live | index($n) != null)})' "$rows"
          exit 0
          ;;
        --list | "")
          # One awk pass owns the join: the live set enters as a variable, the
          # registry rows stream as TSV (every field provably non-empty).
          {
            printf 'SLUG\tLABEL\tCWD\tLIVE\n'
            jq -r '.[] | [.name, .label, .cwd] | @tsv' "$rows"
          } | awk -F'\t' -v live="$(live_workspaces)" '
            BEGIN { n = split(live, ls, "\n"); for (i = 1; i <= n; i++) if (ls[i] != "") set[ls[i]] = 1 }
            NR == 1 { printf "%-16s %-24s %-56s %s\n", $1, $2, $3, $4; next }
            { printf "%-16s %-24s %-56s %s\n", $1, $2, $3, ($1 in set ? "yes" : "no") }'
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
      # session, never the shared default_prog session. Stderr lands in a
      # trap-registered temp so warning noise never corrupts the pane id.
      err="$(mktemp)"
      trap 'rm -f "$err"' EXIT
      pane_id="$("$wezterm_bin" cli --no-auto-start spawn --new-window --workspace "$slug" --cwd "$cwd" -- \
        "$zellij_bin" --layout "$layout" attach --create "$slug" 2>"$err")" || {
        detail="$(tr '\t\n' '  ' <"$err")"
        emit "$slug" spawn error "''${detail:-spawn failed}" "$space_state"
        printf 'forge-workspace: spawn failed: %s\n' "''${detail:-unknown}" >&2
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
    ];

    home.packages = [forgeWorkspace workspaceCompletion];

    xdg.configFile."wezterm" = {
      source = configDir;
      recursive = false;
    };
  };
}
