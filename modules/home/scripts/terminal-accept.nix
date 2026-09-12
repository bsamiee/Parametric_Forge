# Title         : terminal-accept.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/scripts/terminal-accept.nix
# ----------------------------------------------------------------------------
# Runtime acceptance harness for the terminal rail (forge-accept's terminal step): drives the popup/edit rail in a disposable detached session
# against the live generated config and asserts invariants from list-panes/list-tabs JSON. Focus is server state — is_focused rides the panes
# snapshot and focus-pane-id mutates it detached — so the focus leg runs everywhere. Only the dismiss chord needs an attached client:
# send-keys/write on 0.44.3 are pane-pty writes (dump-screen proof), never keybind-engine input, so that one leg DEFERs without a client and the
# residual surfaces as a receipt row either way. The rail kernels arrive as arguments so the harness exercises the exact derivations it ships with.
{
  config,
  host,
  lib,
  pkgs,
  tl,
  forgeNvim,
  forgeEdit,
  forgeYazi,
}: let
  yaziPkg = config.programs.yazi.package;
  # HM-installed cross-module kernels (forge-zellij, forge-workspace) reach the harness through the per-user profile — sibling-module owners.
  profileBin = "/etc/profiles/per-user/${config.home.username}/bin";
  # Receipt grammar owner (receipts.nix): the dual-receipt emit fold and the per-OS receipt-path derivation.
  receipts = import ../../common/receipts.nix;
  receiptPath = receipts.receiptPath {
    inherit lib;
    isDarwin = host.os == "darwin";
  };
  # Chord-vocabulary projection: the injected dismiss chord's bytes derive from the same row that emits the zellij bind.
  yaziToggle = config.forge.chords.zellij.ids.yaziToggle;
  inherit (tl) yaziPopupIdentity liveInTab retrySh deadlineGuardSh panesSnapshotSh cidPipeline runtimeBaseSh;
in
  pkgs.writeShellApplication {
    name = "forge-terminal-accept.sh";
    runtimeInputs = [yaziPkg pkgs.zellij pkgs.jq pkgs.neovim pkgs.coreutils pkgs.findutils pkgs.gawk forgeNvim forgeEdit forgeYazi];
    text = ''
      # Usage: forge-terminal-accept.sh [--session <name>] [--keep]; JSON receipt on stdout, human rows on stderr; exit 1 on any FAIL.
      ${deadlineGuardSh {
        environment = "FORGE_TERMINAL_ACCEPT_DEADLINE_SECONDS";
        default = 180;
        maximum = 900;
        killGrace = 10;
        errorContext = "forge-terminal-accept.sh";
      }}
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
      if [[ -n "$session" && ! "$session" =~ ^fa-[0-9]+-[0-9]+$ ]]; then
        printf 'forge-terminal-accept.sh: --session must match fa-<pid>-<rand>\n' >&2
        exit 2
      fi
      # Owned probe names stay short: the zellij IPC socket path rides $TMPDIR/zellij-<uid>/contract_version_N/<session> under a 103-byte sun_path
      # cap, and the darwin $TMPDIR alone spends ~79 of it.
      owned="false"
      if [[ -z "$session" ]]; then
        session="fa-$$-$((SRANDOM % 10000))"
        owned="true"
      fi
      ${runtimeBaseSh}
      runtime_root="$(_runtime_child "$session")"
      ${retrySh}

      rows="[]"
      fail=0
      row() {
        rows="$(printf '%s\n' "$rows" | jq -c --arg id "$1" --arg st "$2" --arg d "$3" \
          '. + [{id: $id, status: $st, detail: $d}]')"
        printf '%-5s | %s | %s\n' "$2" "$1" "$3" >&2
        if [[ "$2" == "FAIL" ]]; then fail=1; fi
      }

      zj() { zellij --session "$session" action "$@"; }
      panes() {
        local panes
        ${panesSnapshotSh "timeout -k 1 3 zellij --session \"$session\" action list-panes --all --json"}
        printf '%s' "$panes"
      }
      # shellcheck disable=SC2329  # invoked through _retry
      _pred_true() { [[ "$(panes | jq -r "$1" 2>/dev/null)" == "true" ]]; }
      poll() { _retry 50 0.2 _pred_true "$1"; }

      # shellcheck disable=SC2329  # invoked by the EXIT trap
      cleanup() {
        # Probe fixtures die on every exit path, not just the happy tail.
        if [[ -n "''${probe_dir:-}" && -n "''${probe_parent:-}" ]] \
          && [[ "$(realpath -m -- "$probe_dir")" == "$probe_parent/"* ]]; then
          rm -rf -- "$probe_dir"
        fi
        if [[ "$owned" == "true" && "$keep" != "true" ]]; then
          timeout -k 1 3 zellij kill-session "$session" >/dev/null 2>&1 || true
          sleep 0.5
          timeout -k 1 3 zellij delete-session "$session" >/dev/null 2>&1 || true
          rm -rf -- "''${runtime_root:?}"
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
        rm -rf -- "''${runtime_root:?}"
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
      yazi_ver="$(basename "$(dirname "$(dirname "$(realpath "$(command -v yazi)")")")")"
      ya_ver="$(basename "$(dirname "$(dirname "$(realpath "$(command -v ya)")")")")"
      yazi_ver="''${yazi_ver#*-}"
      ya_ver="''${ya_ver#*-}"
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
          and ([.sessions[] | select(.name == $s and .state == "live")] | length == 1)' < <(printf '%s\n' "$state_json") >/dev/null 2>&1; then
        row R15-fabric-state PASS "state/v2 classifies probe session live"
      else
        row R15-fabric-state FAIL "state envelope: $(printf '%s\n' "$state_json" | jq -c '{schema, sessions: (.sessions | length)}' 2>/dev/null || printf 'unparseable')"
      fi

      # R16: workspace rows carry the session lifecycle enum; a headless --json degrades the gui join, never the lifecycle classification.
      ws_json="$(${profileBin}/forge-workspace --json 2>/dev/null || true)"
      if jq -e 'type == "array" and length > 0
          and all(.[]; .lifecycle | IN("live", "resurrectable", "cold"))' < <(printf '%s\n' "$ws_json") >/dev/null 2>&1; then
        row R16-workspace-lifecycle PASS "every workspace row carries a lifecycle verdict"
      else
        row R16-workspace-lifecycle FAIL "rows: $(printf '%s\n' "$ws_json" | jq -c 'map({name, lifecycle}) | .[:6]' 2>/dev/null || printf 'unparseable')"
      fi

      # R04-R08: edit rail — spawn, registry, socket, reuse, multi-file. Canonicalized so bufname comparisons match
      # forge-edit's realpath pin (macOS /var and /tmp are /private symlinks).
      probe_parent="$(realpath -- "''${TMPDIR:-/tmp}")"
      probe_dir="$(realpath -- "$(mktemp -d "$probe_parent/forge-accept.XXXXXX")")"
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
      _rpc_answers() { [[ -S "$socket" ]] && nvim --headless --server "$socket" --remote-expr '1' >/dev/null 2>&1; }
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
        bufname="$(nvim --headless --server "$socket" --remote-expr 'bufname("%")' 2>/dev/null || true)"
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
        buflisted="$(nvim --headless --server "$socket" --remote-expr 'len(getbufinfo({"buflisted":1}))' 2>/dev/null || printf '0')"
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
      receipt_log="${(receiptPath "forge-terminal-accept").expr}"
      receipt_surface="forge-terminal-accept"
      ${receipts.fold}
      result=ok
      ((fail)) && result=fail
      append_receipt "$(jq -c --arg result "$result" \
        '{session: .session, attached: .attached,
          pass: .summary.pass, fail: .summary.fail, defer: .summary.defer, result: $result}' < <(printf '%s\n' "$receipt"))" \
        || printf 'forge-terminal-accept.sh: WARNING receipt not persisted to %s\n' "$receipt_log" >&2
      exit "$fail"
    '';
  }
