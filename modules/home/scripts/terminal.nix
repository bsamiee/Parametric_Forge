# Title         : terminal.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/scripts/terminal.nix
# ----------------------------------------------------------------------------
# Yazi -> Zellij -> Neovim rail: popup dispatcher, RPC handoff, server owner. Pane targeting is ID-based via list-panes JSON; never ordinal focus.
{
  config,
  lib,
  pkgs,
  ...
}: let
  yaziPkg = config.programs.yazi.package;
  # HM-installed cross-module kernels (forge-zellij, forge-workspace) reach the harness through the per-user profile — sibling-module owners.
  profileBin = "/etc/profiles/per-user/${config.home.username}/bin";
  # Shared dual-receipt emit fold: one grammar for every receipt-bearing kernel, TSV plus JSONL with identical keys.
  receiptsFold = import ../programs/shell-tools/receipts.nix;
  # Chord-vocabulary projection: the injected dismiss chord's bytes derive from the same row that emits the zellij bind.
  yaziToggle = config.forge.chords.zellij.ids.yaziToggle;
  # Geometry-owner projection: popup flags render from the zellij option rows.
  yaziPopup = config.programs.zellij.popupGeometry.yazi;
  yaziPopupArgs = lib.escapeShellArgs ["-x" yaziPopup.x "-y" yaziPopup.y "--width" yaziPopup.width "--height" yaziPopup.height];

  # One popup-identity vocabulary — production dispatch, caller dismissal, and the acceptance harness share this exact jq row predicate, so the harness
  # can never miss a production identity. terminal_command is the spawn command (invoked_with), so exec inside the pane never breaks rediscovery.
  yaziPopupIdentity = ''(.is_plugin | not) and (.exited | not) and ((.is_floating // false) or (.is_suppressed // false)) and ((.title // "") == " [YAZI] ") and ((.terminal_command // .command // "") == "forge-yazi.sh")'';

  # One self-row vocabulary: (panes snapshot, $self) -> this pane's row; every kernel resolves its own pane through this exact projection.
  selfRow = ''[.[] | select((.is_plugin | not) and ((.id | tostring) == $self))][0]'';

  # One live-row vocabulary: (panes snapshot, $id, $tab) -> count of live terminal rows with that id in that tab; the registry-hit gate and the
  # acceptance harness join registry rows to live panes through this exact predicate.
  liveInTab = ''[.[] | select((.is_plugin | not) and ((.id | tostring) == $id) and (.tab_id == $tab) and (.exited | not))] | length'';

  # One bounded-retry owner: every startup race, RPC probe, DDS bind wait, and snapshot flap in the rail polls through this single loop.
  retrySh = ''
    _retry() { # $1 tries, $2 interval, $3.. simple command; truthy on first success
      local -i _n="$1"
      local _iv="$2"
      shift 2
      while ((_n-- > 0)); do
        if "$@"; then return 0; fi
        ((_n)) && sleep "$_iv"
      done
      return 1
    }
  '';

  # One truthy-snapshot kernel: list-panes flaps transiently against a busy session; every reader retries to a non-empty array, so a flap never
  # misreads the session as pane-free. Interpolate after retrySh.
  panesSnapshotSh = listCmd: ''
    # shellcheck disable=SC2329  # invoked through _retry
    _panes_probe() {
      panes="$(${listCmd} 2>/dev/null || true)"
      jq -e 'type == "array" and length > 0' <<<"$panes" >/dev/null 2>&1
    }
    _retry 5 0.2 _panes_probe || panes="[]"
  '';

  # One DDS client-id derivation: (session, pane_id) -> deterministic 6-digit id; the popup body, dispatcher, and acceptance harness all pipe
  # `printf '%s:%s' session pane` through this exact projection.
  cidPipeline = ''cksum | gawk '{ print ($1 % 899999) + 100000 }' '';

  # One runtime-root derivation for every rail script and the harness: RPC sockets, the dispatch lock, surfaced markers, and DDS state live in a
  # per-user private namespace (XDG runtime dir on Linux, per-user $TMPDIR on darwin), never predictable world-writable /tmp; the go-rwx clamp fails
  # closed if a squatter pre-owns the bare-/tmp fallback.
  runtimeBaseSh = ''
    runtime_base="''${XDG_RUNTIME_DIR:-''${TMPDIR:-/tmp}}/forge-edit"
    mkdir -p "$runtime_base"
    chmod go-rwx "$runtime_base"
  '';

  # Registry contract: one editor per tab, "<tab_id>\t<pane_id>\t<socket>" under ${XDG_RUNTIME_DIR:-/tmp}/forge-edit/<session>/editor-tab-<tab_id>.tsv
  forgeNvim = pkgs.writeShellApplication {
    name = "forge-nvim.sh";
    runtimeInputs = [pkgs.neovim pkgs.zellij pkgs.jq pkgs.coreutils];
    text = ''
      # Outside Zellij: plain editor. Inside: per-pane RPC server + tab registry.
      if [[ -z "''${ZELLIJ:-}" ]]; then
        exec nvim "$@"
      fi

      session="''${ZELLIJ_SESSION_NAME:-default}"
      pane_id="''${ZELLIJ_PANE_ID:-0}"
      ${runtimeBaseSh}
      runtime_root="$runtime_base/''${session}"
      mkdir -p "$runtime_root"
      ${retrySh}

      # Tab resolution can lag pane creation at layout startup; retry briefly and skip registry publication rather than poisoning a tab-0 entry.
      tab_id=""
      # shellcheck disable=SC2329  # invoked through _retry
      _tab_probe() {
        tab_id="$(zellij action list-panes --all --json 2>/dev/null \
          | jq -r --arg self "$pane_id" '${selfRow}.tab_id // empty' || true)"
        [[ -n "$tab_id" ]]
      }
      _retry 10 0.1 _tab_probe || true

      socket="''${runtime_root}/pane-''${pane_id}.sock"
      rm -f "$socket"
      if [[ -n "$tab_id" ]]; then
        # Rename-atomic publication: forge-edit reads this row concurrently, so a direct write would expose a torn registry line.
        registry="''${runtime_root}/editor-tab-''${tab_id}.tsv"
        printf '%s\t%s\t%s\n' "$tab_id" "$pane_id" "$socket" >"''${registry}.$$"
        mv -f "''${registry}.$$" "$registry"
      fi
      exec nvim --listen "$socket" "$@"
    '';
  };

  forgeEdit = pkgs.writeShellApplication {
    name = "forge-edit.sh";
    runtimeInputs = [pkgs.neovim pkgs.zellij pkgs.jq pkgs.coreutils forgeNvim];
    text = ''
      # Yazi opener target: RPC into the tab's registered Neovim, else spawn one.
      if [[ $# -eq 0 ]]; then
        exit 0
      fi
      if [[ -z "''${ZELLIJ:-}" ]]; then
        exec nvim "$@"
      fi

      session="''${ZELLIJ_SESSION_NAME:-default}"
      caller="''${ZELLIJ_PANE_ID:-}"
      ${runtimeBaseSh}
      runtime_root="$runtime_base/''${session}"
      ${retrySh}
      # RPC handoff resolves paths against the server's cwd, and a fresh editor pane opens
      # at $PWD; pin caller-relative arguments to absolute so both branches open the caller's files.
      mapfile -d "" -t args < <(realpath -zm -- "$@")
      set -- "''${args[@]}"
      # A dead snapshot degrades to the fresh-editor branch.
      ${panesSnapshotSh "zellij action list-panes --all --json"}
      caller_row="$(jq -c --arg self "$caller" '${selfRow} // {}' <<<"$panes")"
      tab_id="$(jq -r '.tab_id // 0' <<<"$caller_row")"

      editor_pane=""
      socket=""
      registry="''${runtime_root}/editor-tab-''${tab_id}.tsv"
      if [[ -r "$registry" ]]; then
        IFS=$'\t' read -r _ editor_pane socket <"$registry" || true
      fi

      # Registry hit counts only if the recorded pane still lives in this tab AND the socket answers AND the remote open succeeds; any miss or race
      # falls through to a fresh editor pane. The RPC probe retries briefly: a plugin-busy nvim misses one poll without being dead.
      # shellcheck disable=SC2329  # invoked through _retry
      _rpc_probe() { nvim --server "$socket" --remote-expr '1' >/dev/null 2>&1; }
      handed_off="false"
      if [[ -n "$editor_pane" && -n "$socket" && -S "$socket" ]]; then
        pane_alive="$(jq -r --arg id "$editor_pane" --argjson tab "$tab_id" '${liveInTab} > 0' <<<"$panes")"
        if [[ "$pane_alive" == "true" ]] && _retry 5 0.2 _rpc_probe \
          && nvim --server "$socket" --remote "$@" >/dev/null 2>&1; then
          handed_off="true"
        fi
      fi
      if [[ "$handed_off" != "true" ]]; then
        editor_pane="$(zellij action new-pane --name " [EDITOR] " --cwd "$PWD" -- forge-nvim.sh "$@")"
      fi

      # Focusing the tiled editor lowers the floating layer without touching other floating panes.
      if [[ -n "$editor_pane" ]]; then
        zellij action focus-pane-id "terminal_''${editor_pane#terminal_}" >/dev/null 2>&1 || true
      fi

      # Pane-scoped dismissal: close only the Forge popup this ran inside, killing its own process tree, so it must stay the final statement. Shared
      # identity vocabulary; a yazi launched WITH args ("forge-yazi.sh <dir>") is never the popup.
      caller_is_popup="$(jq -r '${yaziPopupIdentity}' <<<"$caller_row")"
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
      runtime_root="$runtime_base/''${session}"
      mkdir -p "$runtime_root"
      ${retrySh}
      cid_of() { # $1 = pane id; globally unique across sessions via name hash
        printf '%s:%s' "$session" "$1" | ${cidPipeline}
      }

      if [[ $# -eq 0 && -n "''${ZELLIJ:-}" ]]; then
        # Popup body: pin the DDS client id and bridge local events. Events stream as `kind,receiver,sender,{json}`; cd lands in a compact state
        # cache AND the event log, hover only in the cache (render-hot path reads caches, never the stream). TUI renders on the pty untouched. State
        # writes truncate in place — rename-atomicity would fork per hover event — so cache readers poll with jq -e and retry torn JSON.
        pane_id="''${ZELLIJ_PANE_ID:-0}"
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

      self="''${ZELLIJ_PANE_ID:-}"
      # Serialize concurrent dispatchers (double-chord): one session-scoped lock spans snapshot-to-act, so racing
      # toggles never both read a popup-free tab and create duplicate popups.
      exec {lock_fd}>"$runtime_root/toggle.lock"
      flock -w 5 "$lock_fd" || {
        printf 'forge-yazi.sh: another toggle holds the dispatch lock\n' >&2
        exit 75
      }
      ${panesSnapshotSh "zellij action list-panes --all --json"}
      tab_id="$(jq -r --arg self "$self" '${selfRow}.tab_id // 0' <<<"$panes")"
      # Shared identity vocabulary scoped to this tab, excluding self. Dispatchers ("forge-yazi.sh toggle") and yazi-with-args rows never match;
      # hidden floating popups keep is_floating, so identity holds through the hide cycle.
      popup_row="$(jq -c --arg self "$self" --argjson tab "$tab_id" \
        '[.[] | select(${yaziPopupIdentity}
          and (.tab_id == $tab) and ((.id | tostring) != $self))][0] // {}' <<<"$panes")"
      popup="$(jq -r '.id // empty' <<<"$popup_row")"

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

  # Runtime acceptance harness: drives the popup/edit rail in a disposable detached session against the live generated config and asserts invariants
  # from list-panes/list-tabs JSON. Focus is server state — is_focused rides the panes snapshot and focus-pane-id mutates it detached — so the focus
  # leg runs everywhere. Only the dismiss chord needs an attached client: send-keys/write on 0.44.3 are pane-pty writes (dump-screen proof), never
  # keybind-engine input, so that one leg DEFERs without a client and the residual surfaces as a receipt row either way.
  forgeTerminalAccept = pkgs.writeShellApplication {
    name = "forge-terminal-accept.sh";
    runtimeInputs = [yaziPkg pkgs.zellij pkgs.jq pkgs.neovim pkgs.coreutils pkgs.findutils pkgs.gawk forgeNvim forgeEdit forgeYazi];
    text = ''
      # Usage: forge-terminal-accept.sh [--session <name>] [--keep]; JSON receipt on stdout, human rows on stderr; exit 1 on any FAIL.
      unset ZELLIJ ZELLIJ_SESSION_NAME ZELLIJ_PANE_ID

      session=""
      keep="false"
      while [[ $# -gt 0 ]]; do
        case "$1" in
          --session) session="''${2:?--session requires a name}"; shift 2 ;;
          --keep) keep="true"; shift ;;
          *)
            printf 'unknown flag: %s\nusage: forge-terminal-accept.sh [--session <name>] [--keep]\n' "$1" >&2
            exit 2
            ;;
        esac
      done
      # Owned probe names stay short: the zellij IPC socket path rides $TMPDIR/zellij-<uid>/contract_version_N/<session> under a 103-byte sun_path
      # cap, and the darwin $TMPDIR alone spends ~79 of it.
      owned="false"
      if [[ -z "$session" ]]; then
        session="fa-$$-$((SRANDOM % 10000))"
        owned="true"
      fi
      ${runtimeBaseSh}
      ${retrySh}

      rows="[]"
      fail=0
      row() {
        rows="$(jq -c --arg id "$1" --arg st "$2" --arg d "$3" \
          '. + [{id: $id, status: $st, detail: $d}]' <<<"$rows")"
        printf '%-5s | %s | %s\n' "$2" "$1" "$3" >&2
        if [[ "$2" == "FAIL" ]]; then fail=1; fi
      }

      zj() { zellij --session "$session" action "$@"; }
      panes() {
        local panes
        ${panesSnapshotSh "zj list-panes --all --json"}
        printf '%s' "$panes"
      }
      # shellcheck disable=SC2329  # invoked through _retry
      _pred_true() { [[ "$(panes | jq -r "$1" 2>/dev/null)" == "true" ]]; }
      poll() { _retry 50 0.2 _pred_true "$1"; }

      # shellcheck disable=SC2329  # invoked by the EXIT trap
      cleanup() {
        # Probe fixtures die on every exit path, not just the happy tail.
        if [[ -n "''${probe_dir:-}" ]]; then rm -rf "$probe_dir"; fi
        if [[ "$owned" == "true" && "$keep" != "true" ]]; then
          zellij kill-session "$session" >/dev/null 2>&1 || true
          sleep 0.5
          zellij delete-session "$session" >/dev/null 2>&1 || true
          rm -rf "''${runtime_base:?}/''${session}"
        fi
      }
      trap cleanup EXIT

      if [[ "$owned" == "true" ]]; then
        # A dead probe session fails every row with misleading detail; make the bootstrap fault (socket path, server refusal) the one loud exit.
        if ! err="$(zellij attach --create-background "$session" 2>&1 >/dev/null)"; then
          printf 'forge-terminal-accept.sh: probe session %s failed to start: %s\n' "$session" "$err" >&2
          exit 1
        fi
      else
        # Reused probe session: reset rail state so invariants start from zero. Streaming boundary: close each stale rail pane as its id arrives.
        while IFS= read -r id; do
          if [[ -n "$id" ]]; then
            zj close-pane --pane-id "terminal_''${id}" >/dev/null 2>&1 || true
          fi
        done < <(panes | jq -r '.[] | select((.is_plugin | not) and (.exited | not)
          and (((.terminal_command // .command // "") | startswith("forge-nvim.sh"))
            or ((.terminal_command // .command // "") == "forge-yazi.sh")
            or ((.terminal_command // .command // "") == "forge-yazi.sh toggle"))) | .id')
        rm -rf "''${runtime_base:?}/''${session}"
        sleep 1
      fi

      # R01: live config loaded — both zjstatus bars plus a shell pane present.
      if poll '([.[] | select(.is_plugin and ((.title // "") | startswith("zjstatus")))] | length >= 2)
        and ([.[] | select(.is_plugin | not)] | length >= 1)'; then
        row R01-session-ready PASS "two zjstatus bars + shell pane in $session"
      else
        row R01-session-ready FAIL "generated config did not produce the bar layout"
      fi

      # shellcheck disable=SC2329  # invoked through _retry
      _client_attached() { [[ "$(zj list-clients 2>/dev/null | awk 'NR > 1 { n++ } END { print n + 0 }')" -gt 0 ]]; }
      attached="false"
      _retry 3 0.5 _client_attached && attached="true"

      popup_pred='[.[] | select(${yaziPopupIdentity})]'
      popup_n() { panes | jq -r "$popup_pred | length"; }
      popup_head() { panes | jq -r "$popup_pred | .[0].id // empty"; }

      # R02: toggle creates exactly one floating popup titled " [YAZI] ".
      zj new-pane --floating -c -- forge-yazi.sh toggle >/dev/null 2>&1 || true
      if poll "$popup_pred | (length == 1) and (.[0].title == \" [YAZI] \")"; then
        row R02-popup-create PASS "one floating ' [YAZI] ' pane, exact title + spawn-command identity"
      else
        row R02-popup-create FAIL "popup row: $(panes | jq -c "$popup_pred")"
      fi

      # R03: second toggle never duplicates the popup (marker-gated hide). A negative can only settle, never poll.
      zj new-pane --floating -c -- forge-yazi.sh toggle >/dev/null 2>&1 || true
      sleep 1.5
      if [[ "$(popup_n)" == "1" ]]; then
        row R03-popup-single PASS "popup count stays 1 after repeat toggle"
      else
        row R03-popup-single FAIL "popup count $(popup_n) after repeat toggle"
      fi

      # R12/R13: DDS spine — ya rides version-matched in the closure; emit-to retargets the popup by its derived client id and the cd state cache
      # materializes (the bridge's compact-state contract).
      yazi_ver="$(yazi --version | awk '{print $2}')"
      ya_ver="$(ya --version | awk '{print $2}')"
      if [[ "$yazi_ver" == "$ya_ver" ]]; then
        row R12-ya-version PASS "ya $ya_ver matches yazi in the wrapper closure"
      else
        row R12-ya-version FAIL "yazi=$yazi_ver ya=$ya_ver"
      fi
      popup_id="$(popup_head)"
      if [[ -n "$popup_id" ]]; then
        cid="$(printf '%s:%s' "$session" "$popup_id" | ${cidPipeline})"
        state="$runtime_base/''${session}/dds-cd-pane-''${popup_id}.json"
        # shellcheck disable=SC2329  # invoked through _retry
        _cd_state_ok() { [[ -r "$state" ]] && jq -e '.body.url | test("^(/private)?/tmp")' "$state" >/dev/null 2>&1; }
        dds_sent="false"
        cd_seen="false"
        _retry 25 0.2 ya emit-to "$cid" cd /tmp 2>/dev/null && dds_sent="true"
        _retry 25 0.2 _cd_state_ok && cd_seen="true"
        if [[ "$dds_sent" == "true" && "$cd_seen" == "true" ]]; then
          row R13-dds-bridge PASS "emit-to cid=$cid retargeted the popup; cd state cache landed"
        else
          row R13-dds-bridge FAIL "sent=$dds_sent state_seen=$cd_seen state=$state"
        fi
      else
        row R13-dds-bridge DEFER "no live popup for the DDS probe"
      fi

      # R14: opener-seam config truth — the deployed yazi config must wire the Forge editor opener and the zoxide picker; a rename on either edge is
      # the four-file-edit trap this harness exists to catch.
      yazi_conf="''${XDG_CONFIG_HOME:-$HOME/.config}/yazi"
      if grep -q 'forge-edit\.sh %s' "$yazi_conf/yazi.toml" 2>/dev/null \
        && grep -q 'yazi-zoxide-cdi\.sh' "$yazi_conf/keymap.toml" 2>/dev/null; then
        row R14-opener-seam PASS "yazi.toml edit opener + keymap zoxide picker spell the Forge scripts"
      else
        row R14-opener-seam FAIL "opener/picker rows missing under $yazi_conf"
      fi

      # R15: session-fabric state envelope — forge-zellij state emits schema v2 with classified session rows
      # (the resurrection-receipts join), and the probe session classifies live.
      state_json="$(${profileBin}/forge-zellij state 2>/dev/null || true)"
      if jq -e --arg s "$session" '
          (.schema == "forge-zellij-state/v2")
          and (.sessions | type == "array")
          and ([.sessions[] | select(.name == $s and .state == "live")] | length == 1)' <<<"$state_json" >/dev/null 2>&1; then
        row R15-fabric-state PASS "state/v2 classifies probe session live"
      else
        row R15-fabric-state FAIL "state envelope: $(jq -c '{schema, sessions: (.sessions | length)}' <<<"$state_json" 2>/dev/null || printf 'unparseable')"
      fi

      # R16: workspace rows carry the session lifecycle enum; a headless --json degrades the gui join, never the lifecycle classification.
      ws_json="$(${profileBin}/forge-workspace --json 2>/dev/null || true)"
      if jq -e 'type == "array" and length > 0
          and all(.[]; .lifecycle | IN("live", "resurrectable", "cold"))' <<<"$ws_json" >/dev/null 2>&1; then
        row R16-workspace-lifecycle PASS "every workspace row carries a lifecycle verdict"
      else
        row R16-workspace-lifecycle FAIL "rows: $(jq -c 'map({name, lifecycle}) | .[:6]' <<<"$ws_json" 2>/dev/null || printf 'unparseable')"
      fi

      # R04-R08: edit rail — spawn, registry, socket, reuse, multi-file. Canonicalized so bufname comparisons match
      # forge-edit's realpath pin (macOS /var and /tmp are /private symlinks).
      probe_dir="$(realpath -- "$(mktemp -d "''${TMPDIR:-/tmp}/forge-accept.XXXXXX")")"
      printf 'alpha\n' >"$probe_dir/a.txt"
      printf 'beta\n' >"$probe_dir/b.txt"
      printf 'gamma\n' >"$probe_dir/c.txt"
      editor_pred='[.[] | select((.is_plugin | not) and (.exited | not)
        and ((.terminal_command // .command // "") | startswith("forge-nvim.sh")))]'
      editor_n() { panes | jq -r "$editor_pred | length"; }

      zj new-pane -c -- forge-edit.sh "$probe_dir/a.txt" >/dev/null 2>&1 || true
      if poll "$editor_pred | length == 1"; then
        row R04-editor-spawn PASS "one ' [EDITOR] ' pane running forge-nvim.sh"
      else
        row R04-editor-spawn FAIL "editor rows: $(panes | jq -c "$editor_pred")"
      fi

      # Registry publication and socket liveness lag pane creation; poll the row, the socket, and the live-pane join together.
      runtime_root="$runtime_base/''${session}"
      registry=""
      editor_pane=""
      socket=""
      reg_tab=""
      # shellcheck disable=SC2329  # invoked through _retry
      _registry_live() {
        registry="$(find "$runtime_root" -name 'editor-tab-*.tsv' 2>/dev/null | head -1 || true)"
        [[ -n "$registry" ]] || return 1
        IFS=$'\t' read -r reg_tab editor_pane socket <"$registry" || true
        [[ -n "$editor_pane" && -S "$socket" ]] || return 1
        panes | jq -e --arg id "$editor_pane" --argjson tab "''${reg_tab:-0}" '${liveInTab} == 1' >/dev/null
      }
      if _retry 150 0.2 _registry_live; then
        row R05-registry PASS "registry row tab=''${reg_tab:-?} pane=$editor_pane matches live pane"
      else
        row R05-registry FAIL "registry=$registry pane=$editor_pane socket=$socket"
      fi

      # shellcheck disable=SC2329  # invoked through _retry
      _rpc_answers() { [[ -S "$socket" ]] && nvim --server "$socket" --remote-expr '1' >/dev/null 2>&1; }
      if _retry 75 0.2 _rpc_answers; then
        row R06-socket-rpc PASS "editor socket answers remote-expr"
      else
        row R06-socket-rpc FAIL "no RPC answer on $socket"
      fi

      zj new-pane -c -- forge-edit.sh "$probe_dir/b.txt" >/dev/null 2>&1 || true
      # The RPC hand-off is async; poll the buffer instead of a fixed sleep.
      bufname=""
      # shellcheck disable=SC2329  # invoked through _retry
      _buf_current() {
        bufname="$(nvim --server "$socket" --remote-expr 'bufname("%")' 2>/dev/null || true)"
        [[ "$bufname" == "$probe_dir/b.txt" ]]
      }
      _retry 25 0.2 _buf_current || true
      if [[ "$(editor_n)" == "1" && "$bufname" == "$probe_dir/b.txt" ]]; then
        row R07-editor-reuse PASS "second open reused the tab editor; current buffer is b.txt"
      else
        row R07-editor-reuse FAIL "editors=$(editor_n) bufname=$bufname"
      fi

      zj new-pane -c -- forge-edit.sh "$probe_dir/c.txt" >/dev/null 2>&1 || true
      buflisted=0
      # shellcheck disable=SC2329  # invoked through _retry
      _bufs_loaded() {
        buflisted="$(nvim --server "$socket" --remote-expr 'len(getbufinfo({"buflisted":1}))' 2>/dev/null || printf '0')"
        [[ "$buflisted" =~ ^[0-9]+$ ]] || buflisted=0
        [[ "$buflisted" -ge 3 ]]
      }
      _retry 25 0.2 _bufs_loaded || true
      if [[ "$(editor_n)" == "1" && "$buflisted" -ge 3 ]]; then
        row R08-editor-multifile PASS "one editor holds all $buflisted probe buffers"
      else
        row R08-editor-multifile FAIL "editors=$(editor_n) buflisted=$buflisted"
      fi

      # R09: the adjudicated runtime residual. The dismiss gesture is a marker-gated HIDE on the real keybind path: the popup persists with its yazi
      # state and the floating dispatcher reaps itself. The chord must enter as client input — zellij 0.44.3 has no zero-client route
      # (send-keys/write land in the pane pty) — so the chord is injected through an attached wezterm pty (FORGE_ACCEPT_WEZTERM_SOCK +
      # FORGE_ACCEPT_WEZTERM_PANE). Default bytes are the kitty CSI-u projection of the chord owner's yaziToggle row; env override takes %b escapes.
      dismiss_chord="''${FORGE_ACCEPT_DISMISS_CHORD:-$(printf '\x1b[%d;%du' "$(printf '%d' "'${yaziToggle.key}")" ${toString yaziToggle.mods})}"
      wezterm_bin="''${FORGE_ACCEPT_WEZTERM_BIN:-/Applications/WezTerm.app/Contents/MacOS/wezterm}"
      dispatcher_pred='[.[] | select((.exited | not) and ((.terminal_command // .command // "") == "forge-yazi.sh toggle"))]'
      popup_id="$(popup_head)"
      if [[ "$attached" == "true" && -n "$popup_id" && -n "''${FORGE_ACCEPT_WEZTERM_SOCK:-}" \
        && -n "''${FORGE_ACCEPT_WEZTERM_PANE:-}" && -x "$wezterm_bin" ]]; then
        # Surface + focus through the real dispatcher so the marker records pre-chord visibility; the chord then means hide.
        zj new-pane --floating -c -- forge-yazi.sh toggle >/dev/null 2>&1 || true
        sleep 1.5
        printf '%b' "$dismiss_chord" | WEZTERM_UNIX_SOCKET="$FORGE_ACCEPT_WEZTERM_SOCK" \
          "$wezterm_bin" cli send-text --no-paste --pane-id "$FORGE_ACCEPT_WEZTERM_PANE" || true
        layer_vis="unknown"
        # shellcheck disable=SC2329  # invoked through _retry
        _layer_hidden() {
          layer_vis="$(zj list-tabs --json 2>/dev/null | jq -r '.[0].are_floating_panes_visible' 2>/dev/null || true)"
          [[ "$layer_vis" == "false" ]]
        }
        _retry 25 0.2 _layer_hidden || true
        sleep 1
        dispatchers="$(panes | jq -r "$dispatcher_pred | length")"
        if [[ "$(popup_n)" == "1" && "$layer_vis" == "false" && "$dispatchers" == "0" ]]; then
          row R09-dismiss-hide PASS "chord hid the layer; popup persists, dispatcher reaped"
        else
          row R09-dismiss-hide FAIL "popups=$(popup_n) layer_visible=$layer_vis dispatchers=$dispatchers"
        fi
      else
        row R09-dismiss-hide DEFER "chord needs client input (send-keys is a pane-pty write); set FORGE_ACCEPT_WEZTERM_SOCK/_PANE on an attached probe"
      fi

      # R10: create-branch focus retention — the fresh popup must hold focus after the floating dispatcher reaps itself. is_focused is server state in
      # the panes snapshot, so this leg runs attached or detached.
      popup_id="$(popup_head)"
      if [[ -n "$popup_id" ]]; then
        zj close-pane --pane-id "terminal_''${popup_id}" >/dev/null 2>&1 || true
        sleep 1
      fi
      zj new-pane --floating -c -- forge-yazi.sh toggle >/dev/null 2>&1 || true
      if poll "$popup_pred | (length == 1) and (.[0].is_focused == true)"; then
        new_popup="$(popup_head)"
        row R10-create-focus PASS "focus retained on created popup terminal_$new_popup"
      else
        row R10-create-focus FAIL "popup/focus rows: $(panes | jq -c "$popup_pred | map({id, is_focused})")"
      fi

      # R11: pane-scoped close returns the tab to zero popups.
      popup_id="$(popup_head)"
      if [[ -n "$popup_id" ]]; then
        zj close-pane --pane-id "terminal_''${popup_id}" >/dev/null 2>&1 || true
      fi
      if poll "$popup_pred | length == 0"; then
        row R11-popup-close PASS "popup closed by pane id; no floating residue"
      else
        row R11-popup-close FAIL "popup still present after close-pane"
      fi

      receipt="$(jq -n --argjson rows "$rows" --arg session "$session" \
        --argjson attached "$attached" \
        '{schema: "forge-terminal-accept/v1", session: $session, attached: $attached, rows: $rows,
          summary: (reduce $rows[] as $r ({pass: 0, fail: 0, defer: 0};
            .[$r.status | ascii_downcase] += 1))}')"
      printf '%s\n' "$receipt"

      # Dual receipts through the shared fold: one TSV row plus a JSONL sibling with identical envelope keys, numerics as numbers.
      receipt_log="''${FORGE_TERMINAL_ACCEPT_RECEIPT_LOG:-$HOME/Library/Logs/forge-terminal-accept.receipts.log}"
      receipt_surface="forge-terminal-accept"
      ${receiptsFold}
      TZ=UTC0 printf -v ts '%(%Y-%m-%dT%H:%M:%SZ)T' "$EPOCHSECONDS"
      result=ok
      ((fail)) && result=fail
      append_receipt "$(jq -c --arg ts "$ts" --arg result "$result" \
        '{ts: $ts, session: .session, attached: .attached,
          pass: .summary.pass, fail: .summary.fail, defer: .summary.defer, result: $result}' <<<"$receipt")" \
        || printf 'forge-terminal-accept.sh: WARNING receipt not persisted to %s\n' "$receipt_log" >&2
      exit "$fail"
    '';
  };

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
