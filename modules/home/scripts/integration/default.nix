# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/scripts/integration/default.nix
# ----------------------------------------------------------------------------
# Yazi -> Zellij -> Neovim rail: popup dispatcher, RPC handoff, server owner.
# Pane targeting is ID-based via list-panes JSON; never ordinal focus. Dismiss
# lowers the layer, then the bind's close_on_exit drops the suppressed popup
# with the dispatcher (close-pane cannot reach a suppressed pane on 0.44.3).
# terminal_command is the spawn command (invoked_with), so exec inside a pane
# never breaks pane rediscovery.
{
  config,
  lib,
  pkgs,
  ...
}: let
  yaziPkg = config.programs.yazi.package;
  # Chord-vocabulary owner projection: the harness injects the REAL dismiss
  # chord, so its bytes derive from the same row that emits the zellij bind.
  yaziToggle = config.forge.chords.zellij.ids.yaziToggle;

  # Registry contract: one editor per tab, "<tab_id>\t<pane_id>\t<socket>" under
  # ${XDG_RUNTIME_DIR:-/tmp}/forge-edit/<session>/editor-tab-<tab_id>.tsv
  forgeNvim = pkgs.writeShellApplication {
    name = "forge-nvim.sh";
    runtimeInputs = [pkgs.neovim pkgs.zellij pkgs.jq];
    text = ''
      # Outside Zellij: plain editor. Inside: per-pane RPC server + tab registry.
      if [[ -z "''${ZELLIJ:-}" ]]; then
        exec nvim "$@"
      fi

      session="''${ZELLIJ_SESSION_NAME:-default}"
      pane_id="''${ZELLIJ_PANE_ID:-0}"
      runtime_root="''${XDG_RUNTIME_DIR:-/tmp}/forge-edit/''${session}"
      mkdir -p "$runtime_root"

      # Tab resolution can lag pane creation at layout startup; retry briefly
      # and skip registry publication rather than poisoning a tab-0 entry.
      tab_id=""
      for _ in 1 2 3 4 5 6 7 8 9 10; do
        tab_id="$(zellij action list-panes --all --json 2>/dev/null \
          | jq -r --arg self "$pane_id" \
            '[.[] | select((.is_plugin | not) and ((.id | tostring) == $self))][0].tab_id // empty' \
          || true)"
        if [[ -n "$tab_id" ]]; then
          break
        fi
        sleep 0.1
      done

      socket="''${runtime_root}/pane-''${pane_id}.sock"
      rm -f "$socket"
      if [[ -n "$tab_id" ]]; then
        printf '%s\t%s\t%s\n' "$tab_id" "$pane_id" "$socket" \
          >"''${runtime_root}/editor-tab-''${tab_id}.tsv"
      fi
      exec nvim --listen "$socket" "$@"
    '';
  };

  forgeEdit = pkgs.writeShellApplication {
    name = "forge-edit.sh";
    runtimeInputs = [pkgs.neovim pkgs.zellij pkgs.jq forgeNvim];
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
      runtime_root="''${XDG_RUNTIME_DIR:-/tmp}/forge-edit/''${session}"
      # list-panes flaps transiently against a busy session; retry to a truthy
      # snapshot, then degrade to the fresh-editor branch on a dead read.
      panes="[]"
      for _ in 1 2 3 4 5; do
        panes="$(zellij action list-panes --all --json 2>/dev/null || true)"
        if jq -e 'type == "array" and length > 0' <<<"$panes" >/dev/null 2>&1; then
          break
        fi
        panes="[]"
        sleep 0.2
      done
      caller_row="$(jq -c --arg self "$caller" \
        '[.[] | select((.is_plugin | not) and ((.id | tostring) == $self))][0] // {}' <<<"$panes")"
      tab_id="$(jq -r '.tab_id // 0' <<<"$caller_row")"

      editor_pane=""
      socket=""
      registry="''${runtime_root}/editor-tab-''${tab_id}.tsv"
      if [[ -r "$registry" ]]; then
        IFS=$'\t' read -r _ editor_pane socket <"$registry" || true
      fi

      # Registry hit counts only if the recorded pane still lives in this tab
      # AND the socket answers AND the remote open succeeds; any miss or race
      # falls through to a fresh editor pane. The RPC probe retries briefly:
      # a plugin-busy nvim misses one poll without being dead.
      handed_off="false"
      if [[ -n "$editor_pane" && -n "$socket" && -S "$socket" ]]; then
        pane_alive="$(jq -r --arg id "$editor_pane" --argjson tab "$tab_id" \
          '[.[] | select((.is_plugin | not) and ((.id | tostring) == $id)
            and (.tab_id == $tab) and (.exited | not))] | length > 0' <<<"$panes")"
        rpc_alive="false"
        if [[ "$pane_alive" == "true" ]]; then
          for _ in 1 2 3 4 5; do
            if nvim --server "$socket" --remote-expr '1' >/dev/null 2>&1; then
              rpc_alive="true"
              break
            fi
            sleep 0.2
          done
        fi
        if [[ "$rpc_alive" == "true" ]] \
          && nvim --server "$socket" --remote "$@" >/dev/null 2>&1; then
          handed_off="true"
        fi
      fi
      if [[ "$handed_off" != "true" ]]; then
        editor_pane="$(zellij action new-pane --name " [EDITOR] " --cwd "$PWD" -- forge-nvim.sh "$@")"
      fi

      # Focusing the tiled editor lowers the floating layer without touching
      # other floating panes.
      if [[ -n "$editor_pane" ]]; then
        zellij action focus-pane-id "terminal_''${editor_pane#terminal_}" >/dev/null 2>&1 || true
      fi

      # Pane-scoped dismissal: close only the Forge popup we ran inside; this
      # kills our own process tree, so it must stay the final statement.
      caller_is_popup="$(jq -r \
        '((.is_floating // false) and ((.terminal_command // "") | startswith("forge-yazi.sh")))' <<<"$caller_row")"
      if [[ "$caller_is_popup" == "true" ]]; then
        zellij action close-pane --pane-id "terminal_''${caller}" >/dev/null 2>&1 || true
      fi
    '';
  };

  forgeYazi = pkgs.writeShellApplication {
    name = "forge-yazi.sh";
    runtimeInputs = [yaziPkg pkgs.zellij pkgs.jq forgeEdit];
    text = ''
      # Polymorphic entry: "toggle" dispatches the per-tab popup; any other argv
      # launches Yazi with the Forge editor handoff, entries forwarded intact.
      if [[ "''${1:-}" != "toggle" ]]; then
        if [[ $# -eq 0 ]]; then
          set -- "$PWD"
        fi
        EDITOR="forge-edit.sh" exec yazi "$@"
      fi

      if [[ -z "''${ZELLIJ:-}" ]]; then
        echo "forge-yazi.sh toggle requires a Zellij session" >&2
        exit 1
      fi

      self="''${ZELLIJ_PANE_ID:-}"
      # list-panes flaps transiently against a busy session; retry to a truthy
      # snapshot so a flap never misreads the tab as popup-free.
      panes="[]"
      for _ in 1 2 3 4 5; do
        panes="$(zellij action list-panes --all --json 2>/dev/null || true)"
        if jq -e 'type == "array" and length > 0' <<<"$panes" >/dev/null 2>&1; then
          break
        fi
        panes="[]"
        sleep 0.2
      done
      tab_id="$(jq -r --arg self "$self" \
        '[.[] | select((.is_plugin | not) and ((.id | tostring) == $self))][0].tab_id // 0' <<<"$panes")"
      # Prefix-anchored on the spawn command: a rediscovered popup is exactly a
      # forge-yazi.sh process, never an editor holding a forge-yazi* file arg.
      popup_row="$(jq -c --arg self "$self" --argjson tab "$tab_id" \
        '[.[] | select((.is_plugin | not) and (.exited | not) and (.tab_id == $tab)
          and ((.id | tostring) != $self)
          and ((.terminal_command // "") | startswith("forge-yazi.sh"))
          and (((.terminal_command // "") | startswith("forge-yazi.sh toggle")) | not))][0] // {}' <<<"$panes")"
      popup="$(jq -r '.id // empty' <<<"$popup_row")"

      if [[ -z "$popup" ]]; then
        created="$(zellij action new-pane --floating --pinned true \
          -x "8%" -y "6%" --width "84%" --height "86%" \
          --name " [YAZI] " --close-on-exit --cwd "$PWD" -- forge-yazi.sh)"
        zellij action focus-pane-id "$created" >/dev/null 2>&1 || true
      elif [[ "$(jq -r '.is_suppressed // false' <<<"$popup_row")" == "true" ]]; then
        # The in-place dispatcher replaced the focused popup: chord means
        # dismiss. hide-floating-panes restores the layer baseline; the bind's
        # close_on_exit then drops the dispatcher AND the replaced popup, so
        # dismissal destroys the popup like a pane-scoped close (close-pane
        # cannot reach a suppressed pane on zellij 0.44.3).
        zellij action hide-floating-panes
      else
        # Focusing a floating pane surfaces the floating layer
        zellij action focus-pane-id "terminal_''${popup}"
      fi
    '';
  };

  # Runtime acceptance harness: drives the popup/edit rail in a disposable
  # detached session against the live generated config and asserts invariants
  # from list-panes/list-tabs JSON. In-place and focus semantics need an
  # attached client (zellij 0.44.3 routes them per-client), so those legs run
  # only when the target session has one and DEFER otherwise — the two
  # adjudicated runtime residuals surface as receipt rows either way.
  forgeTerminalAccept = pkgs.writeShellApplication {
    name = "forge-terminal-accept.sh";
    runtimeInputs = [pkgs.zellij pkgs.jq pkgs.neovim forgeNvim forgeEdit forgeYazi];
    text = ''
      # Usage: forge-terminal-accept.sh [--session <name>] [--keep]
      # JSON receipt on stdout, human rows on stderr; exit 1 on any FAIL.
      unset ZELLIJ ZELLIJ_SESSION_NAME ZELLIJ_PANE_ID

      session=""
      keep="false"
      while [[ $# -gt 0 ]]; do
        case "$1" in
          --session) session="''${2:?--session requires a name}"; shift 2 ;;
          --keep) keep="true"; shift ;;
          *) echo "unknown flag: $1" >&2; exit 2 ;;
        esac
      done
      owned="false"
      if [[ -z "$session" ]]; then
        session="forge-accept-$$-$RANDOM"
        owned="true"
      fi

      rows="[]"
      fail=0
      row() {
        rows="$(jq -c --arg id "$1" --arg st "$2" --arg d "$3" \
          '. + [{id: $id, status: $st, detail: $d}]' <<<"$rows")"
        printf '%-5s | %s | %s\n' "$2" "$1" "$3" >&2
        if [[ "$2" == "FAIL" ]]; then fail=1; fi
      }

      zj() { zellij --session "$session" action "$@"; }
      # list-panes flaps transiently against a busy session; retry to a truthy
      # snapshot so single-shot reads never act on an empty flap.
      panes() {
        local out
        for _ in 1 2 3 4 5; do
          out="$(zj list-panes --all --json 2>/dev/null || true)"
          if jq -e 'type == "array" and length > 0' <<<"$out" >/dev/null 2>&1; then
            printf '%s' "$out"
            return 0
          fi
          sleep 0.2
        done
        echo '[]'
      }
      poll() {
        local pred="$1"
        for _ in $(seq 1 50); do
          if [[ "$(panes | jq -r "$pred" 2>/dev/null)" == "true" ]]; then return 0; fi
          sleep 0.2
        done
        return 1
      }

      # shellcheck disable=SC2329  # invoked by the EXIT trap
      cleanup() {
        if [[ "$owned" == "true" && "$keep" != "true" ]]; then
          zellij kill-session "$session" >/dev/null 2>&1 || true
          sleep 0.5
          zellij delete-session "$session" >/dev/null 2>&1 || true
          rm -rf "''${XDG_RUNTIME_DIR:-/tmp}/forge-edit/''${session}"
        fi
      }
      trap cleanup EXIT

      if [[ "$owned" == "true" ]]; then
        zellij attach --create-background "$session" >/dev/null 2>&1 || true
      else
        # Reused probe session: reset rail state so invariants start from zero.
        while IFS= read -r id; do
          if [[ -n "$id" ]]; then
            zj close-pane --pane-id "terminal_''${id}" >/dev/null 2>&1 || true
          fi
        done < <(panes | jq -r '.[] | select((.is_plugin | not) and (.exited | not)
          and (((.terminal_command // "") | startswith("forge-nvim.sh"))
            or ((.terminal_command // "") | startswith("forge-yazi.sh")))) | .id')
        rm -rf "''${XDG_RUNTIME_DIR:-/tmp}/forge-edit/''${session}"
        sleep 1
      fi

      # R01: live config loaded — both zjstatus bars plus a shell pane present.
      if poll '([.[] | select(.is_plugin and (.title | startswith("zjstatus")))] | length >= 2)
        and ([.[] | select(.is_plugin | not)] | length >= 1)'; then
        row R01-session-ready PASS "two zjstatus bars + shell pane in $session"
      else
        row R01-session-ready FAIL "generated config did not produce the bar layout"
      fi

      attached="false"
      for _ in 1 2 3; do
        if [[ "$(zj list-clients 2>/dev/null | tail -n +2 | wc -l | tr -d ' ')" -gt 0 ]]; then
          attached="true"
          break
        fi
        sleep 0.5
      done

      popup_pred='[.[] | select((.is_plugin | not) and (.exited | not) and .is_floating
        and ((.terminal_command // "") | startswith("forge-yazi.sh"))
        and (((.terminal_command // "") | startswith("forge-yazi.sh toggle")) | not))]'

      # R02: toggle creates exactly one floating popup titled " [YAZI] ".
      zj new-pane -c -- forge-yazi.sh toggle >/dev/null 2>&1 || true
      if poll "$popup_pred | (length == 1) and (.[0].title == \" [YAZI] \")"; then
        row R02-popup-create PASS "one floating ' [YAZI] ' pane, prefix-matched spawn command"
      else
        row R02-popup-create FAIL "popup row: $(panes | jq -c "$popup_pred")"
      fi

      # R03: second toggle never duplicates the popup.
      zj new-pane -c -- forge-yazi.sh toggle >/dev/null 2>&1 || true
      sleep 1.5
      if [[ "$(panes | jq -r "$popup_pred | length")" == "1" ]]; then
        row R03-popup-single PASS "popup count stays 1 after repeat toggle"
      else
        row R03-popup-single FAIL "popup count $(panes | jq -r "$popup_pred | length") after repeat toggle"
      fi

      # R04-R08: edit rail — spawn, registry, socket, reuse, multi-file.
      probe_dir="$(mktemp -d "''${TMPDIR:-/tmp}/forge-accept.XXXXXX")"
      printf 'alpha\n' >"$probe_dir/a.txt"
      printf 'beta\n' >"$probe_dir/b.txt"
      printf 'gamma\n' >"$probe_dir/c.txt"
      editor_pred='[.[] | select((.is_plugin | not) and (.exited | not)
        and ((.terminal_command // "") | startswith("forge-nvim.sh")))]'

      zj new-pane -c -- forge-edit.sh "$probe_dir/a.txt" >/dev/null 2>&1 || true
      if poll "$editor_pred | length == 1"; then
        row R04-editor-spawn PASS "one ' [EDITOR] ' pane running forge-nvim.sh"
      else
        row R04-editor-spawn FAIL "editor rows: $(panes | jq -c "$editor_pred")"
      fi

      # Registry publication and socket liveness lag pane creation; poll both.
      runtime_root="''${XDG_RUNTIME_DIR:-/tmp}/forge-edit/''${session}"
      registry=""
      editor_pane=""
      socket=""
      reg_ok="false"
      for _ in $(seq 1 150); do
        registry="$(find "$runtime_root" -name 'editor-tab-*.tsv' 2>/dev/null | head -1 || true)"
        if [[ -n "$registry" ]]; then
          IFS=$'\t' read -r reg_tab editor_pane socket <"$registry" || true
          if [[ -n "$editor_pane" && -S "$socket" ]] && panes | jq -e --arg id "$editor_pane" --argjson tab "''${reg_tab:-0}" \
            '[.[] | select((.is_plugin | not) and ((.id | tostring) == $id) and (.tab_id == $tab) and (.exited | not))] | length == 1' >/dev/null; then
            reg_ok="true"
            break
          fi
        fi
        sleep 0.2
      done
      if [[ "$reg_ok" == "true" ]]; then
        row R05-registry PASS "registry row tab=''${reg_tab:-?} pane=$editor_pane matches live pane"
      else
        row R05-registry FAIL "registry=$registry pane=$editor_pane socket=$socket"
      fi

      rpc_ok="false"
      for _ in $(seq 1 75); do
        if [[ -S "$socket" ]] && nvim --server "$socket" --remote-expr '1' >/dev/null 2>&1; then
          rpc_ok="true"
          break
        fi
        sleep 0.2
      done
      if [[ "$rpc_ok" == "true" ]]; then
        row R06-socket-rpc PASS "editor socket answers remote-expr"
      else
        row R06-socket-rpc FAIL "no RPC answer on $socket"
      fi

      zj new-pane -c -- forge-edit.sh "$probe_dir/b.txt" >/dev/null 2>&1 || true
      sleep 2
      bufname="$(nvim --server "$socket" --remote-expr 'bufname("%")' 2>/dev/null || true)"
      if [[ "$(panes | jq -r "$editor_pred | length")" == "1" && "$bufname" == "$probe_dir/b.txt" ]]; then
        row R07-editor-reuse PASS "second open reused the tab editor; current buffer is b.txt"
      else
        row R07-editor-reuse FAIL "editors=$(panes | jq -r "$editor_pred | length") bufname=$bufname"
      fi

      zj new-pane -c -- forge-edit.sh "$probe_dir/c.txt" >/dev/null 2>&1 || true
      sleep 2
      buflisted="$(nvim --server "$socket" --remote-expr 'len(getbufinfo({"buflisted":1}))' 2>/dev/null || echo 0)"
      if [[ "$(panes | jq -r "$editor_pred | length")" == "1" && "$buflisted" -ge 3 ]]; then
        row R08-editor-multifile PASS "one editor holds all $buflisted probe buffers"
      else
        row R08-editor-multifile FAIL "editors=$(panes | jq -r "$editor_pred | length") buflisted=$buflisted"
      fi

      # R09/R10: the two adjudicated runtime residuals. The dismiss gesture
      # (in-place over the FOCUSED FLOATING popup) only exists on the real
      # keybind path: zellij's CLI in-place cannot target a floating pane, so
      # R09 needs the chord injected through an attached wezterm pty
      # (FORGE_ACCEPT_WEZTERM_SOCK + FORGE_ACCEPT_WEZTERM_PANE). The create
      # gesture replaces a TILED pane, which the CLI reproduces faithfully.
      # Default chord bytes are the kitty CSI-u projection of the chord
      # owner's yaziToggle row; the env override still accepts %b escapes.
      dismiss_chord="''${FORGE_ACCEPT_DISMISS_CHORD:-$(printf '\x1b[%d;%du' "$(printf '%d' "'${yaziToggle.key}")" ${toString yaziToggle.mods})}"
      wezterm_bin="''${FORGE_ACCEPT_WEZTERM_BIN:-/Applications/WezTerm.app/Contents/MacOS/wezterm}"
      popup_id="$(panes | jq -r "$popup_pred | .[0].id // empty")"
      if [[ "$attached" == "true" && -n "$popup_id" && -n "''${FORGE_ACCEPT_WEZTERM_SOCK:-}" \
        && -n "''${FORGE_ACCEPT_WEZTERM_PANE:-}" && -x "$wezterm_bin" ]]; then
        zj focus-pane-id "terminal_''${popup_id}" >/dev/null 2>&1 || true
        sleep 0.5
        printf '%b' "$dismiss_chord" | WEZTERM_UNIX_SOCKET="$FORGE_ACCEPT_WEZTERM_SOCK" \
          "$wezterm_bin" cli send-text --no-paste --pane-id "$FORGE_ACCEPT_WEZTERM_PANE" || true
        layer_vis="unknown"
        for _ in $(seq 1 25); do
          layer_vis="$(zj list-tabs --json 2>/dev/null | jq -r '.[0].are_floating_panes_visible' 2>/dev/null || true)"
          if [[ "$layer_vis" == "false" ]]; then break; fi
          sleep 0.2
        done
        if [[ "$(panes | jq -r "$popup_pred | length")" == "0" && "$layer_vis" == "false" ]]; then
          row R09-dismiss-suppressed PASS "chord on focused popup dropped it and hid the layer"
        else
          row R09-dismiss-suppressed FAIL "popups=$(panes | jq -r "$popup_pred | length") layer_visible=$layer_vis"
        fi
      else
        row R09-dismiss-suppressed DEFER "dismiss gesture needs a pty-injected chord; set FORGE_ACCEPT_WEZTERM_SOCK/_PANE on an attached probe"
      fi

      if [[ "$attached" == "true" ]]; then
        # Create-branch focus retention: fresh popup must hold focus after
        # the dispatcher pane exit-restores its replaced shell pane.
        popup_id="$(panes | jq -r "$popup_pred | .[0].id // empty")"
        if [[ -n "$popup_id" ]]; then
          zj close-pane --pane-id "terminal_''${popup_id}" >/dev/null 2>&1 || true
          sleep 1
        fi
        zj new-pane --in-place -c -- forge-yazi.sh toggle >/dev/null 2>&1 || true
        if poll "$popup_pred | length == 1"; then
          new_popup="$(panes | jq -r "$popup_pred | .[0].id")"
          focused=""
          for _ in $(seq 1 10); do
            focused="$(zj list-clients 2>/dev/null | awk 'NR==2 {print $2}')"
            if [[ "$focused" == "terminal_''${new_popup}" ]]; then break; fi
            sleep 0.5
          done
          if [[ "$focused" == "terminal_''${new_popup}" ]]; then
            row R10-create-focus PASS "focus retained on created popup terminal_$new_popup"
          else
            row R10-create-focus FAIL "focus=$focused popup=terminal_$new_popup"
          fi
        else
          row R10-create-focus FAIL "popup did not recreate for the focus probe"
        fi
      else
        row R10-create-focus DEFER "needs an attached client; runs in the attached choreography"
      fi

      # R11: pane-scoped close returns the tab to zero popups.
      popup_id="$(panes | jq -r "$popup_pred | .[0].id // empty")"
      if [[ -n "$popup_id" ]]; then
        zj close-pane --pane-id "terminal_''${popup_id}" >/dev/null 2>&1 || true
      fi
      if poll "$popup_pred | length == 0"; then
        row R11-popup-close PASS "popup closed by pane id; no floating residue"
      else
        row R11-popup-close FAIL "popup still present after close-pane"
      fi

      rm -rf "$probe_dir"
      jq -n --argjson rows "$rows" --arg session "$session" \
        --argjson attached "$([[ "$attached" == "true" ]] && echo true || echo false)" \
        '{schema: "forge-terminal-accept/v1", session: $session, attached: $attached, rows: $rows,
          summary: (reduce $rows[] as $r ({pass: 0, fail: 0, defer: 0};
            .[$r.status | ascii_downcase] += 1))}'
      exit "$fail"
    '';
  };

  fzfDefaultOpts = lib.concatStringsSep " " (config.programs.fzf.defaultOptions or []);
  fzfDefaultCommand = config.programs.fzf.defaultCommand or "";

  yaziZoxideCdi = pkgs.writeShellApplication {
    name = "yazi-zoxide-cdi.sh";
    runtimeInputs = [pkgs.zoxide pkgs.fzf yaziPkg];
    text = ''
      # FZF-backed zoxide directory picker for Yazi; emits a safe cwd-change event.
      ${lib.optionalString (fzfDefaultOpts != "") ''
        if [[ -z "''${FZF_DEFAULT_OPTS:-}" ]]; then
          export FZF_DEFAULT_OPTS=${lib.escapeShellArg fzfDefaultOpts}
        fi
      ''}
      ${lib.optionalString (fzfDefaultCommand != "") ''
        if [[ -z "''${FZF_DEFAULT_COMMAND:-}" ]]; then
          export FZF_DEFAULT_COMMAND=${lib.escapeShellArg fzfDefaultCommand}
        fi
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
  imports = [../../programs/apps/chords.nix];

  home.packages = [forgeNvim forgeEdit forgeYazi yaziZoxideCdi forgeTerminalAccept];
}
