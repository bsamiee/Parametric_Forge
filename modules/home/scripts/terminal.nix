# Title         : terminal.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/scripts/terminal.nix
# ----------------------------------------------------------------------------
# Yazi -> Zellij -> Neovim rail: popup dispatcher, RPC handoff, server owner. Pane targeting is ID-based via list-panes JSON; never ordinal focus.
# The shared vocabulary lives in terminal-lib.nix and the acceptance harness in terminal-accept.nix; both read the one lib.
{
  config,
  host,
  lib,
  pkgs,
  ...
}: let
  yaziPkg = config.programs.yazi.package;
  # Geometry-owner projection: popup flags render from the zellij option rows.
  yaziPopup = config.programs.zellij.popupGeometry.yazi;
  yaziPopupArgs = lib.escapeShellArgs ["-x" yaziPopup.x "-y" yaziPopup.y "--width" yaziPopup.width "--height" yaziPopup.height];
  tl = import ./terminal-lib.nix {inherit lib;};
  inherit (tl) yaziPopupIdentity selfRow liveInTab retrySh deadlineGuardSh panesSnapshotSh cidPipeline runtimeBaseSh;

  # Registry contract: forge-edit serializes observe/create/publication of one "<tab_id>\t<pane_id>\t<socket>" row per tab; forge-nvim admits only
  # its already-published row before binding the deterministic socket.
  forgeNvim = pkgs.writeShellApplication {
    name = "forge-nvim.sh";
    runtimeInputs = [pkgs.neovim pkgs.zellij pkgs.jq pkgs.coreutils];
    text = ''
      # Outside Zellij: plain editor. Inside: per-pane RPC server + tab registry.
      if [[ -z "''${ZELLIJ:-}" ]]; then
        exec nvim "$@"
      fi

      session="''${ZELLIJ_SESSION_NAME:-default}"
      pane_id="''${ZELLIJ_PANE_ID:?forge-nvim.sh: ZELLIJ_PANE_ID is unset inside Zellij}"
      ${runtimeBaseSh}
      runtime_root="$(_runtime_child "$session")"
      mkdir -p "$runtime_root"
      ${retrySh}

      # Tab resolution can lag pane creation at layout startup; retry briefly, then fail closed rather than starting an unregistered editor server.
      tab_id=""
      # shellcheck disable=SC2329  # invoked through _retry
      _tab_probe() {
        tab_id="$(timeout -k 1 3 zellij action list-panes --all --json 2>/dev/null \
          | jq -r --arg self "$pane_id" '(${selfRow}) as $row
            | select(($row.tab_id | type) == "number" and (($row.exited // false) | not)) | $row.tab_id' || true)"
        [[ -n "$tab_id" ]]
      }
      if ! _retry 10 0.1 _tab_probe; then
        printf 'forge-nvim.sh: pane inventory never resolved pane %s to a tab; refusing an unregistered editor server\n' "$pane_id" >&2
        exit 75
      fi

      socket="''${runtime_root}/pane-''${pane_id}.sock"
      registry="''${runtime_root}/editor-tab-''${tab_id}.tsv"
      # The dispatcher publishes the exact row inside its per-tab transaction; a directly launched or abandoned child never becomes a second owner.
      # shellcheck disable=SC2329  # invoked through _retry
      _registry_probe() {
        local _tab="" _pane="" _socket=""
        [[ -r "$registry" ]] || return 1
        IFS=$'\t' read -r _tab _pane _socket <"$registry" || return 1
        [[ "$_tab" == "$tab_id" && "$_pane" == "$pane_id" && "$_socket" == "$socket" ]] && _runtime_contains "$_socket"
      }
      if ! _retry 20 0.1 _registry_probe; then
        printf 'forge-nvim.sh: editor registry never admitted tab=%s pane=%s; refusing an unowned server\n' "$tab_id" "$pane_id" >&2
        exit 75
      fi
      rm -f "$socket"
      exec nvim --listen "$socket" "$@"
    '';
  };

  forgeEdit = pkgs.writeShellApplication {
    name = "forge-edit.sh";
    runtimeInputs = [pkgs.neovim pkgs.zellij pkgs.jq pkgs.coreutils pkgs.flock forgeNvim];
    text = ''
      # Yazi opener target: RPC into the tab's registered Neovim, else spawn one.
      if [[ $# -eq 0 ]]; then
        exit 0
      fi
      if [[ -z "''${ZELLIJ:-}" ]]; then
        exec nvim "$@"
      fi
      ${deadlineGuardSh {
        environment = "FORGE_EDIT_DEADLINE_SECONDS";
        default = 30;
        maximum = 120;
        killGrace = 2;
        errorContext = "forge-edit.sh";
      }}

      session="''${ZELLIJ_SESSION_NAME:-default}"
      caller="''${ZELLIJ_PANE_ID:?forge-edit.sh: ZELLIJ_PANE_ID is unset inside Zellij}"
      self="$caller"
      ${runtimeBaseSh}
      runtime_root="$(_runtime_child "$session")"
      mkdir -p "$runtime_root"
      ${retrySh}
      # RPC handoff resolves paths against the server's cwd, and a fresh editor pane opens
      # at $PWD; pin caller-relative arguments to absolute so both branches open the caller's files.
      mapfile -d "" -t args < <(realpath -zm -- "$@")
      set -- "''${args[@]}"
      # Snapshot failure is ambiguous, so it never licenses another editor process; the caller retries after the bounded Zellij probe recovers.
      ${panesSnapshotSh "timeout -k 1 3 zellij action list-panes --all --json"}
      if [[ "$panes_snapshot_ok" != "true" ]]; then
        printf 'forge-edit.sh: pane inventory unavailable; refusing an ambiguous editor spawn\n' >&2
        exit 75
      fi
      # One projection owns the caller vector; the unit separator preserves empty fields without tab-field collapse.
      IFS=$'\x1f' read -r tab_id caller_is_popup < <(printf '%s\n' "$panes" | jq -r --arg self "$caller" '
        (${selfRow}) as $row
        | [($row.tab_id | tostring), (($row | ${yaziPopupIdentity}) | tostring)]
        | join("\u001f")')

      registry="''${runtime_root}/editor-tab-''${tab_id}.tsv"
      exec {editor_lock_fd}>"''${registry}.lock"
      if ! flock -w 5 "$editor_lock_fd"; then
        printf 'forge-edit.sh: another editor transaction holds tab %s\n' "$tab_id" >&2
        exit 75
      fi

      editor_pane=""
      socket=""
      reg_tab=""
      if [[ -r "$registry" ]]; then
        IFS=$'\t' read -r reg_tab editor_pane socket <"$registry" || true
      fi

      # Registry hit counts only if the recorded pane still lives in this tab AND the socket answers AND the remote open succeeds; any miss or race
      # falls through to a fresh editor pane. A newly published child receives a bounded startup window while this transaction excludes a duplicate.
      # shellcheck disable=SC2329  # invoked through _retry
      _pane_probe() {
        pane_alive="$(timeout -k 1 3 zellij action list-panes --all --json 2>/dev/null \
          | jq -r --arg id "$editor_pane" --argjson tab "$tab_id" '${liveInTab} > 0' || printf 'false')"
        [[ "$pane_alive" == "true" ]]
      }
      # shellcheck disable=SC2329  # invoked through _retry
      _rpc_probe() { nvim --headless --server "$socket" --remote-expr '1' >/dev/null 2>&1; }
      handed_off="false"
      row_admitted="false"
      pane_alive="false"
      if [[ "$reg_tab" == "$tab_id" && "$editor_pane" =~ ^[0-9]+$ \
        && "$socket" == "$runtime_root/pane-$editor_pane.sock" ]] && _runtime_contains "$socket"; then
        row_admitted="true"
        if _retry 10 0.2 _pane_probe && _retry 25 0.2 _rpc_probe \
          && nvim --server "$socket" --remote "$@" >/dev/null 2>&1; then
          handed_off="true"
        fi
      fi
      if [[ "$handed_off" != "true" ]]; then
        if [[ "$row_admitted" == "true" && "''${pane_alive:-false}" == "true" ]]; then
          zellij action close-pane --pane-id "terminal_''${editor_pane}" >/dev/null 2>&1 || true
        fi
        rm -f -- "$registry"
        created="$(zellij action new-pane --close-on-exit --name " [EDITOR] " --cwd "$PWD" -- forge-nvim.sh "$@")"
        editor_pane="''${created#terminal_}"
        if [[ ! "$editor_pane" =~ ^[0-9]+$ ]]; then
          printf 'forge-edit.sh: editor spawn returned an invalid pane id: %s\n' "$created" >&2
          exit 75
        fi
        socket="$runtime_root/pane-$editor_pane.sock"
        registry_tmp="''${registry}.$$"
        trap 'rm -f -- "$registry_tmp"' EXIT
        printf '%s\t%s\t%s\n' "$tab_id" "$editor_pane" "$socket" >"$registry_tmp"
        mv -f "$registry_tmp" "$registry"
        trap - EXIT
      fi

      # Focusing the tiled editor lowers the floating layer without touching other floating panes.
      if [[ -n "$editor_pane" ]]; then
        zellij action focus-pane-id "terminal_''${editor_pane#terminal_}" >/dev/null 2>&1 || true
      fi

      # Pane-scoped dismissal: close only the Forge popup this ran inside, killing its own process tree, so it must stay the final statement. Shared
      # identity vocabulary; a yazi launched WITH args ("forge-yazi.sh <dir>") is never the popup.
      if [[ "$caller_is_popup" == "true" ]]; then
        zellij action close-pane --pane-id "terminal_''${caller}" >/dev/null 2>&1 || true
      fi
    '';
  };

  forgeYazi = pkgs.writeShellApplication {
    name = "forge-yazi.sh";
    runtimeInputs = [yaziPkg pkgs.zellij pkgs.jq pkgs.coreutils pkgs.flock pkgs.gawk forgeEdit];
    text = ''
      # Polymorphic entry — one command owns every popup modality:
      #   (no args)          popup body: yazi + DDS bridge (client-id, local-events)
      #   toggle             per-tab popup dispatch (create / show+focus / hide)
      #   reveal|cd <path>   semantic DDS action on the tab popup via ya emit-to, creating the popup when absent — never key simulation
      #   <entries...>       plain yazi with the Forge editor handoff
      # DDS client ids derive deterministically from (session, pane_id), so the dispatcher recomputes the popup's id without a registry.
      session="''${ZELLIJ_SESSION_NAME:-default}"
      ${runtimeBaseSh}
      runtime_root="$(_runtime_child "$session")"
      mkdir -p "$runtime_root"
      ${retrySh}
      cid_of() { # $1 = pane id; globally unique across sessions via name hash
        printf '%s:%s' "$session" "$1" | ${cidPipeline}
      }

      if [[ $# -eq 0 && -n "''${ZELLIJ:-}" ]]; then
        # Popup body: pin the DDS client id and bridge local events. Events stream as `kind,receiver,sender,{json}`; cd lands in a compact state
        # cache AND the event log, hover only in the cache (render-hot path reads caches, never the stream). TUI renders on the pty untouched. State
        # writes truncate in place — rename-atomicity would fork per hover event — so cache readers poll with jq -e and retry torn JSON.
        pane_id="''${ZELLIJ_PANE_ID:?forge-yazi.sh: ZELLIJ_PANE_ID is unset inside Zellij}"
        cid="$(cid_of "$pane_id")"
        EDITOR="forge-edit.sh" exec yazi "$PWD" \
          --client-id "$cid" \
          --local-events=cd,hover,rename,bulk,@yank,move,trash,delete \
          > >(exec gawk -F, -v root="$runtime_root" -v pane="$pane_id" '
            {
              kind = $1
              sender = $3
              body = substr($0, index($0, "{"))
              ts = strftime("%Y-%m-%dT%H:%M:%SZ", systime(), 1)
              if (kind == "cd" || kind == "hover") {
                state = root "/dds-" kind "-pane-" pane ".json"
                printf "{\"ts\":\"%s\",\"kind\":\"%s\",\"sender\":\"%s\",\"body\":%s}\n", ts, kind, sender, body > state
                close(state)
                if (kind == "hover") next
              }
              log_file = root "/dds-events.log"
              printf "ts=%s\tsurface=forge-yazi\tkind=%s\tsender=%s\tbody=%s\n", ts, kind, sender, body >> log_file
              close(log_file)
            }')
      fi

      case "''${1:-}" in
        toggle | reveal | cd) ;;
        *)
          (($#)) || set -- "$PWD"
          EDITOR="forge-edit.sh" exec yazi "$@"
          ;;
      esac

      if [[ -z "''${ZELLIJ:-}" ]]; then
        printf 'forge-yazi.sh %s: requires a Zellij session\n' "$1" >&2
        exit 1
      fi
      ${deadlineGuardSh {
        environment = "FORGE_YAZI_DISPATCH_DEADLINE_SECONDS";
        default = 45;
        maximum = 120;
        killGrace = 2;
        errorContext = "forge-yazi.sh";
      }}

      verb="$1"
      target=""
      if [[ "$verb" != "toggle" ]]; then
        target="''${2:?forge-yazi.sh $verb needs a path}"
        # emit-to resolves paths against the popup's cwd, never the caller's, and the cd action only accepts a directory — normalize both here so the
        # create and live-popup branches see one canonical target.
        target="$(realpath -m -- "$target")"
        if [[ "$verb" == "cd" && ! -d "$target" ]]; then
          target="$(dirname "$target")"
        fi
      fi

      self="''${ZELLIJ_PANE_ID:?forge-yazi.sh: ZELLIJ_PANE_ID is unset inside Zellij}"
      # Serialize concurrent dispatchers (double-chord): one session-scoped lock spans snapshot-to-act, so racing
      # toggles never both read a popup-free tab and create duplicate popups.
      exec {lock_fd}>"$runtime_root/toggle.lock"
      flock -w 5 "$lock_fd" || {
        printf 'forge-yazi.sh: another toggle holds the dispatch lock\n' >&2
        exit 75
      }
      ${panesSnapshotSh "timeout -k 1 3 zellij action list-panes --all --json"}
      if [[ "$panes_snapshot_ok" != "true" ]]; then
        printf 'forge-yazi.sh: pane inventory unavailable; refusing an ambiguous popup action\n' >&2
        exit 75
      fi
      # One projection resolves both self-tab and popup identity. Dispatchers and yazi-with-args rows never match; hidden floating popups retain
      # is_floating, so identity holds through the hide cycle.
      IFS=$'\x1f' read -r tab_id popup < <(printf '%s\n' "$panes" | jq -r --arg self "$self" '
        (${selfRow}) as $caller
        | $caller.tab_id as $tab
        | [($tab | tostring), (([.[] | select(${yaziPopupIdentity}
            and (.tab_id == $tab) and ((.id | tostring) != $self))][0].id // "") | tostring)]
        | join("\u001f")')

      # Per-tab surfaced marker: the dispatcher's own floating spawn surfaces the layer, so live layer state cannot discriminate show from hide. An
      # out-of-band layer toggle desyncs it by at most one keypress.
      marker="$runtime_root/surfaced-tab-''${tab_id}"
      # Floating, never in_place: an attached client (zellij 0.44.3) strands exited in-place panes and their suppressed hosts.
      spawn_popup() { # $1 = cwd for the new popup
        created="$(zellij action new-pane --floating --pinned true \
          ${yaziPopupArgs} \
          --name " [YAZI] " --close-on-exit --cwd "$1" -- forge-yazi.sh)"
        zellij action focus-pane-id "$created" >/dev/null 2>&1 || true
        : >"$marker"
      }
      surface_popup() {
        # Best-effort focus: the popup can exit between snapshot and focus; the marker stays authoritative and self-heals within one chord.
        zellij action focus-pane-id "terminal_''${popup}" >/dev/null 2>&1 || true
        : >"$marker"
      }
      emit_popup() { # $1 = client id, $2 = action, $3 = path; the DDS endpoint binds after the pane appears — retry through the startup race
        _retry 10 0.3 ya emit-to "$1" "$2" "$3" 2>/dev/null
      }

      case "$verb" in
        toggle)
          if [[ -z "$popup" ]]; then
            spawn_popup "$PWD"
          elif [[ -e "$marker" ]]; then
            # Chord means hide: lower the layer, keep the popup and its yazi state alive for the next surface.
            zellij action hide-floating-panes >/dev/null 2>&1 || true
            rm -f "$marker"
          else
            # Focusing a floating pane surfaces the floating layer
            surface_popup
          fi
          ;;
        reveal | cd)
          # Semantic DDS action: retarget the popup through ya emit-to (keymap-equivalent action grammar), creating it when absent. A fresh popup
          # needs no emit for cd — it opens at the target.
          if [[ -z "$popup" ]]; then
            dir="$target"
            [[ "$verb" == "reveal" || ! -d "$target" ]] && dir="$(dirname "$target")"
            spawn_popup "$dir"
            if [[ "$verb" == "reveal" ]]; then
              emit_popup "$(cid_of "''${created#terminal_}")" reveal "$target" || true
            fi
          else
            emit_popup "$(cid_of "$popup")" "$verb" "$target" || {
              printf 'forge-yazi.sh: DDS %s to the tab popup did not land\n' "$verb" >&2
              exit 1
            }
            surface_popup
          fi
          ;;
      esac
    '';
  };

  forgeTerminalAccept = import ./terminal-accept.nix {inherit config host lib pkgs tl forgeNvim forgeEdit forgeYazi;};

  fzfDefaultOpts = lib.concatStringsSep " " (config.programs.fzf.defaultOptions or []);
  fzfDefaultCommand = config.programs.fzf.defaultCommand or "";

  yaziZoxideCdi = pkgs.writeShellApplication {
    name = "yazi-zoxide-cdi.sh";
    runtimeInputs = [pkgs.zoxide pkgs.fzf yaziPkg];
    text = ''
      # FZF-backed zoxide directory picker for Yazi; emits a safe cwd-change event. Ambient FZF env wins over the HM projections.
      ${lib.optionalString (fzfDefaultOpts != "") ''
        export FZF_DEFAULT_OPTS="''${FZF_DEFAULT_OPTS:-${lib.escapeShellArg fzfDefaultOpts}}"
      ''}
      ${lib.optionalString (fzfDefaultCommand != "") ''
        export FZF_DEFAULT_COMMAND="''${FZF_DEFAULT_COMMAND:-${lib.escapeShellArg fzfDefaultCommand}}"
      ''}
      selection="$(zoxide query --interactive -- "$@" || true)"
      if [[ -z "$selection" ]]; then
        exit 0
      fi
      # ya emit passes argv structurally; the raw path is one argument
      ya emit cd "$selection"
    '';
  };
in {
  imports = [../programs/apps/chords.nix];

  home.packages = [forgeNvim forgeEdit forgeYazi yaziZoxideCdi forgeTerminalAccept];
}
