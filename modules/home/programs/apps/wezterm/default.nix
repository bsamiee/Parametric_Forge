# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/wezterm/default.nix
# ----------------------------------------------------------------------------
# WezTerm outer-command-deck owner: typed rows (keys, deck commands, quick-select patterns, hyperlink rules, floats, ssh domains, workspaces,
# fonts, plugin pins) project into generated Lua data + a colors TOML; deck.lua and events.lua are the only static interpreters. A build-time
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
  # The font owner's WezTerm projection: chain, per-family leading, shaping features, and the forge-font override path all arrive
  # from config.forge.fonts; deck.lua interprets them.
  fontRow = config.forge.fonts.projections.luaFont;

  # --- [WORKSPACE_ROWS_ONE_SESSION_FABRIC_VOCABULARY]
  # One row = picker entry + zellij session identity + cwd + float policy + warm posture. Local rows project from the name-policy register; remote
  # rows derive from ssh-host mount rows (cwd = the rclone mountpoint), so a second VPS lights the picker with zero edits here. `warm` rows
  # resurrect in the background at login (forge-workspace --warm); `float` names the shape workspace-scoped floats take while the workspace is active.
  workspaceRoot = "${homeDir}/Documents/99.Github";
  workspaceRows =
    map (r: {
      name = r.slug;
      label = r.display;
      cwd = "${workspaceRoot}/${r.source}";
      kind = "local";
      float = "utility";
      warm = lib.elem "wezterm-workspace-warm" r.consumers;
    })
    (builtins.filter (r: r.domain == "estate-repo") naming)
    ++ lib.concatMap (
      h:
        map (m: {
          name = "${h.name}-${m.name}";
          label = "[${lib.toUpper h.name} ${lib.toUpper m.name}]";
          cwd = m.mountpoint;
          kind = "remote";
          host = h.name;
          float = "remote";
          warm = false;
        })
        h.mounts
    ) (lib.attrValues sshHosts);
  defaultWorkspace =
    (lib.findFirst (r: lib.elem "wezterm-workspace-name" r.consumers) {slug = "forge";} naming).slug;
  warmSlugs = map (r: r.name) (builtins.filter (r: r.warm) workspaceRows);

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
    # Semantic estate links: forge://<register-domain>[/...] opens the register browser float scoped to the domain (forge-browse takes a DOMAIN arg).
    {
      id = "forge-scheme";
      regex = "forge://[A-Za-z0-9/@._:-]+";
      format = "$0";
    }
  ];

  # --- [FLOATING_UTILITY_DECK_ROWS]
  # `remote` is the workspace-scoped shape remote workspaces select: near-opaque so a remote-context float never reads as a local one.
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
    remote = {
      width = 120;
      height = 32;
      level = "AlwaysOnTop";
      opacity = 0.98;
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
        scope = "workspace";
        args = ["${profileBin}/zsh" "-l"];
      }
      {
        # Pane-capture float: the waiting agent pane's tail (forge-zellij peek --attention) pinned in a pager — F10 capture on the float rail.
        id = "peek-attention";
        label = "forge: peek waiting agent pane";
        kind = "float";
        float = "utility";
        args = ["${pkgs.bash}/bin/bash" "-c" "${profileBin}/forge-zellij peek --attention --text | ${pkgs.less}/bin/less -R +G"];
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
    # Bell rings are structured attention: the events.lua bell arm owns the surface (receipt row always, toast when background), never a beep.
    audible_bell = "Disabled";

    # Input seam
    disable_default_key_bindings = true;
    send_composed_key_when_left_alt_is_pressed = false;
    send_composed_key_when_right_alt_is_pressed = false;
    bypass_mouse_reporting_modifiers = "SHIFT";
    hide_mouse_cursor_when_typing = true;

    # Outer identity chrome: retro tab bar, theme-projected via the scheme TOML. Hidden at one tab — the zellij zjstatus bar is the ONE standing
    # top bar; this bar exists only when a second WezTerm tab makes it informative.
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
  badFloatRefs =
    map (r: r.id) (builtins.filter (r: r.kind == "float" && !(floatRows ? ${r.float})) commandRows)
    ++ map (r: r.name) (builtins.filter (r: !(floatRows ? ${r.float})) workspaceRows);
  chordDupes = dupesOf (map (r: "${r.mods}+${r.key}") chordRows);
  workspaceDupes = dupesOf (map (r: r.name) workspaceRows);

  # --- [GENERATED_LUA_DATA_ENTRY_POINT]
  rows = {
    nightly_floor = "20260707";
    receipts_log = "${homeDir}/Library/Logs/forge-wezterm.receipts.log";
    # Attention-feed seam: the bell arm appends source=bell rows on the hook-feed schema for the collector fold.
    attention_feed = "${config.xdg.stateHome}/forge/agent-attention.jsonl";
    paths = {
      path = lib.concatStringsSep ":" toolchainEnv.launchdPathEntries;
      zellij = "${pkgs.zellij}/bin/zellij";
      nvim = "${profileBin}/nvim";
      forge_agents = "${profileBin}/forge-agents";
      # Frozen-layout assets (forge-zellij layout record): session_args and forge-workspace both resolve <slug>.kdl here before the default.
      recorded_layouts = "${homeDir}/.local/state/forge/zellij-layouts";
      # Nightly-only mux pin: without it the mux inherits the identity-less Apple launchd SSH_AUTH_SOCK (deck.lua applies it under has_nightly).
      auth_sock = config.forge.ssh.identityAgent;
    };
    host_domains = hostDomains;
    plugins.sync_panes = "${syncPanesSrc}";
    font = fontRow;
    # Registry float rows are singletons: a live float focuses instead of duplicating. Synthesized floats (quick-edit, open-uri) never set reuse.
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
  # The grep proves the arm shape itself — a ["id"] table key or an == "id" equality dispatch — so a receipt/log string literal never false-passes.
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
      # Resolves a workspace-row slug (or wildcard project root) to a WezTerm workspace + slug-named zellij session; --json/--list carry the session
      # lifecycle (live | resurrectable | cold) joined from zellij truth; --warm resurrects warm rows in the background (login rail). Provider
      # dispatch: none (default) degrades with an explicit receipt row.
      rows="${namingJson}"
      wezterm_bin="''${FORGE_WEZTERM_BIN:-/Applications/WezTerm.app/Contents/MacOS/wezterm}"
      zellij_bin="${pkgs.zellij}/bin/zellij"
      layout="''${ZELLIJ_DEFAULT_LAYOUT:-default}"
      workspace_root="${workspaceRoot}"
      recorded_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/forge/zellij-layouts"
      receipt_log="''${FORGE_WORKSPACE_RECEIPT_LOG:-$HOME/Library/Logs/forge-workspace.receipts.log}"
      receipt_surface="forge-workspace"
      provider="''${FORGE_SPACE_PROVIDER:-none}"
      ${receiptsFold}

      usage() { printf 'Usage: forge-workspace [SLUG] | --list | --json | --warm\n'; }

      layout_for() { # frozen slug asset (forge-zellij layout record) wins over the default
        if [ -f "$recorded_dir/$1.kdl" ]; then printf '%s' "$recorded_dir/$1.kdl"; else printf '%s' "$layout"; fi
      }

      emit() { # $1=slug $2=action $3=result $4=detail $5=space
        local ts row
        TZ=UTC0 printf -v ts '%(%Y-%m-%dT%H:%M:%SZ)T' "$EPOCHSECONDS"
        printf -v row 'ts=%s\tslug=%s\taction=%s\tprovider=%s\tspace=%s\tresult=%s\tdetail=%s' \
          "$ts" "$1" "$2" "$provider" "$5" "$3" "''${4:--}"
        append_receipt "$row" \
          || printf 'forge-workspace: WARNING receipt not persisted to %s\n' "$receipt_log" >&2
      }

      # --no-auto-start on every cli call: a stale socket must fail the probe, never fork a daemonized mux server (the recorded litter hazard).
      # The failed probe degrades to an empty live set, never a pipefail abort.
      live_workspaces() {
        if [ -n "''${WEZTERM_UNIX_SOCKET:-}" ] && [ -x "$wezterm_bin" ]; then
          "$wezterm_bin" cli --no-auto-start list --format json 2>/dev/null | jq -r '[.[].workspace] | unique | .[]' || true
        fi
      }

      # Lifecycle join: zellij session truth per row — live (session up), resurrectable (EXITED, serialized), cold (no session); `gui` carries the
      # wezterm workspace presence separately (a session can outlive its window). One list-sessions text parse feeds both classifications.
      lifecycle_rows() {
        local sess
        sess="$("$zellij_bin" list-sessions --no-formatting 2>/dev/null || true)"
        jq --argjson gui "$(live_workspaces | jq -nR '[inputs]')" \
          --argjson zlive "$(gawk '!/EXITED/ && NF {print $1}' <<<"$sess" | jq -nR '[inputs]')" \
          --argjson zexit "$(gawk '/EXITED/ {print $1}' <<<"$sess" | jq -nR '[inputs]')" \
          'map(. + {
             gui: (.name as $n | ($gui | index($n)) != null),
             lifecycle: (.name as $n
               | if ($zlive | index($n)) != null then "live"
                 elif ($zexit | index($n)) != null then "resurrectable"
                 else "cold" end)})' "$rows"
      }

      case "''${1:-}" in
        --help | -h)
          usage
          exit 0
          ;;
        --json)
          lifecycle_rows
          exit 0
          ;;
        --warm)
          # Login rail: warm rows that are not live attach in the background — resurrectable sessions replay their serialized layout, cold rows
          # land their frozen (or default) layout at the row cwd.
          lifecycle_rows | jq -r '.[] | select(.warm and .lifecycle != "live") | [.name, .cwd, .lifecycle] | @tsv' \
            | while IFS=$'\t' read -r slug cwd was; do # streaming boundary: warm rows as they arrive
                if (cd "$cwd" 2>/dev/null && "$zellij_bin" --layout "$(layout_for "$slug")" attach --create-background "$slug" >/dev/null 2>&1); then
                  emit "$slug" warm ok "from=$was" "-"
                else
                  emit "$slug" warm error "attach --create-background failed (from=$was)" "-"
                fi
              done
          exit 0
          ;;
        --list | "")
          {
            printf 'SLUG\tLABEL\tKIND\tLIFECYCLE\tGUI\tCWD\n'
            lifecycle_rows | jq -r '.[] | [.name, .label, .kind, .lifecycle, (.gui | tostring), .cwd] | @tsv'
          } | gawk -F'\t' '{printf "%-14s %-14s %-8s %-13s %-6s %s\n", $1, $2, $3, $4, $5, $6}'
          exit 0
          ;;
      esac

      slug="$1"
      row="$(jq -c --arg s "$slug" '.[] | select(.name == $s)' "$rows")"
      if [ -z "$row" ] && [ -d "$workspace_root/$slug" ]; then
        # Wildcard admission: any project root is a latent workspace with the default layout; explicit registry rows always win over the pattern.
        row="$(jq -cn --arg s "$slug" --arg cwd "$workspace_root/$slug" \
          '{name: $s, label: ("[" + ($s | ascii_upcase) + "]"), cwd: $cwd, kind: "wildcard"}')"
      fi
      if [ -z "$row" ]; then
        emit "$slug" resolve error "unknown slug" "-"
        printf 'forge-workspace: unknown slug %s\n' "$slug" >&2
        exit 64
      fi
      IFS=$'\x1f' read -r cwd kind < <(jq -r '[.cwd, .kind] | join("\u001f")' <<<"$row")

      # Remote rows ride a mountpoint: device-diff against the parent proves the mount answers before a session lands on a dead directory.
      if [ "$kind" = "remote" ] \
        && [ "$(stat -c %d "$cwd" 2>/dev/null || echo x)" = "$(stat -c %d "''${cwd%/*}" 2>/dev/null || echo y)" ]; then
        emit "$slug" spawn error "mount absent at $cwd (forge-vps-mount agent down?)" "-"
        printf 'forge-workspace: %s is not mounted; check the mount agent receipts\n' "$cwd" >&2
        exit 69
      fi

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

      # Explicit prog mirrors the deck seam: the workspace's slug-named zellij session, never the shared default_prog session. Stderr lands in a
      # trap-registered temp so warning noise never corrupts the pane id.
      err="$(mktemp)"
      trap 'rm -f "$err"' EXIT
      pane_id="$("$wezterm_bin" cli --no-auto-start spawn --new-window --workspace "$slug" --cwd "$cwd" -- \
        "$zellij_bin" --layout "$(layout_for "$slug")" attach --create "$slug" 2>"$err")" || {
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
      '--list[table of rows with session lifecycle]' \
      '--json[rows with session lifecycle as JSON]' \
      '--warm[background-attach warm rows (login rail)]'
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
        message = "wezterm: duplicate workspace row names (local/remote collision): ${lib.concatStringsSep ", " workspaceDupes}";
      }
    ];

    home.packages = [forgeWorkspace workspaceCompletion];

    # Warm rail: at login the warm workspace rows resurrect or create their sessions in the background, so the first interactive attach is instant;
    # every warm emits a forge-workspace receipt. Row-gated: the agent exists only while a warm row does.
    forge.bundleApps = lib.mkIf (warmSlugs != []) {forge-workspace-warm = "Forge Workspace Warm";};
    launchd.agents.forge-workspace-warm = lib.mkIf (warmSlugs != []) {
      enable = true;
      config = {
        Label = "com.parametric-forge.forge-workspace-warm";
        ProgramArguments = ["${forgeWorkspace}/bin/forge-workspace" "--warm"];
        RunAtLoad = true;
        ProcessType = "Background";
        StandardOutPath = "${homeDir}/Library/Logs/forge-workspace-warm.log";
        StandardErrorPath = "${homeDir}/Library/Logs/forge-workspace-warm.log";
        AssociatedBundleIdentifiers = ["com.parametric-forge.forge-workspace-warm"];
      };
    };

    xdg.configFile."wezterm" = {
      source = configDir;
      recursive = false;
    };
  };
}
