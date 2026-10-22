# Title         : terminal.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/scripts/terminal.nix
# ----------------------------------------------------------------------------
# Yazi -> Zellij -> Neovim rail: popup dispatcher and RPC handoff. Pane targeting is ID-based (current-tab-info, --tab-id, list-panes JSON);
# never ordinal focus. The shared vocabulary lives in terminal-lib.nix.
{
  config,
  lib,
  pkgs,
  ...
}: let
  yaziPkg = config.programs.yazi.package;
  zsh = config.forge.shell;
  # Geometry-owner projection: popup flags render from the zellij option rows.
  yaziPopup = config.forge.zellij.popupGeometry.yazi;
  yaziPopupArgs = lib.escapeShellArgs ["-x" yaziPopup.x "-y" yaziPopup.y "--width" yaziPopup.width "--height" yaziPopup.height];
  inherit (import ./terminal-lib.nix) yaziPopupIdentity currentTabSh cidPipeline runtimeBaseSh;

  # One editor per tab on a socket named by the tab, known before the editor exists. The per-tab lock spans probe-to-bind: an opener that
  # spawns the editor holds it until nvim is past server_init, so a later opener's --remote lands first try and a refused socket means the
  # editor is gone.
  nvimEdit = pkgs.writeShellApplication {
    name = "nvim-edit.sh";
    runtimeInputs = [config.programs.neovim.finalPackage pkgs.zellij pkgs.jq pkgs.coreutils pkgs.flock];
    text = ''
      # Yazi opener target: RPC into the tab's Neovim, else spawn one.
      if [[ $# -eq 0 ]]; then
        exit 0
      fi
      if [[ -z "''${ZELLIJ:-}" ]]; then
        exec nvim "$@"
      fi

      session="''${ZELLIJ_SESSION_NAME:-default}"
      ${runtimeBaseSh}
      runtime_root="$(_runtime_child "$session")"
      mkdir -p "$runtime_root"
      ${currentTabSh}
      # RPC handoff resolves paths against the server's cwd, and a fresh editor pane opens at $PWD; pin caller-relative arguments to absolute so
      # both branches open the caller's files.
      mapfile -d "" -t args < <(realpath -zm -- "$@")
      socket="$runtime_root/editor-tab-$tab_id.sock"
      exec {lock_fd}>"$socket.lock"
      flock "$lock_fd"
      if ! nvim --server "$socket" --remote "''${args[@]}" >/dev/null 2>&1; then
        rm -f -- "$socket"
        ready="$(mktemp -u "$runtime_root/ready.XXXXXX")"
        mkfifo -m 600 "$ready"
        # --cmd runs after server_init (nvim main.c), so the fifo opens only once the socket is bound; the read below is the rendezvous. The
        # editor pane starts through zsh so .zshenv seats the session environment the zellij server's launchd PATH lacks.
        # shellcheck disable=SC2016  # zsh expands the positional parameters
        zellij action new-pane --tab-id "$tab_id" --close-on-exit --name " [EDITOR] " --cwd "$PWD" -- \
          ${zsh} -c 'exec "$@"' zsh nvim --listen "$socket" --cmd "lua io.open([[$ready]], 'w'):close()" "''${args[@]}" >/dev/null
        read -r _ <"$ready" || true
        rm -f -- "$ready"
      fi

      # Focusing the tiled editor lowers the floating layer without touching other floating panes.
      zellij action focus-pane-id "$(zellij action list-panes --all --json | jq -r --arg t "$tab_id" '[.[] | select((.tab_id|tostring)==$t and .title==" [EDITOR] " and (.exited|not))][0] | "terminal_\(.id)"')"
      # Pane-scoped dismissal: close only the Forge popup this ran inside, killing its own process tree, so it stays the final statement. The
      # caller's row is registered long before yazi invokes the opener; a yazi launched with entries ("yazi-dispatch.sh <dir>") is never the popup.
      if [[ "$(zellij action list-panes --all --json | jq -r --arg s "$ZELLIJ_PANE_ID" '.[] | select((.id|tostring)==$s) | (${yaziPopupIdentity})')" == true ]]; then
        zellij action close-pane --pane-id "terminal_$ZELLIJ_PANE_ID"
      fi
    '';
  };

  yaziDispatch = pkgs.writeShellApplication {
    name = "yazi-dispatch.sh";
    runtimeInputs = [yaziPkg pkgs.zellij pkgs.jq pkgs.coreutils pkgs.flock pkgs.gawk nvimEdit];
    text = ''
      # Polymorphic entry — one command owns every popup modality:
      #   popup <entry>      popup body: yazi at the entry + DDS bridge (client-id, local-events)
      #   toggle             per-tab popup dispatch (create / show+focus / hide)
      #   reveal|cd <path>   the tab popup at the path: a fresh popup opens there, a live one takes one ya emit-to — never key simulation
      #   <entries...>       plain yazi with the Forge editor handoff
      # DDS client ids derive deterministically from (session, pane_id), so the dispatcher recomputes the popup's id without a registry.
      session="''${ZELLIJ_SESSION_NAME:-default}"
      ${runtimeBaseSh}
      runtime_root="$(_runtime_child "$session")"
      mkdir -p "$runtime_root"
      cid_of() { # $1 = pane id; globally unique across sessions via name hash
        printf '%s:%s' "$session" "$1" | ${cidPipeline}
      }

      if [[ "''${1:-}" == popup && -n "''${ZELLIJ:-}" ]]; then
        # Popup body: pin the DDS client id and bridge local events. A file entry opens its parent with the file hovered. Events stream as
        # `kind,receiver,sender,{json}`; cd lands in a compact state cache AND the event log, hover only in the cache (render-hot path reads
        # caches, never the stream). TUI renders on the pty untouched. State writes truncate in place — rename-atomicity would fork per hover
        # event — so cache readers poll with jq -e and retry torn JSON.
        pane_id="''${ZELLIJ_PANE_ID:?yazi-dispatch.sh: ZELLIJ_PANE_ID is unset inside Zellij}"
        cid="$(cid_of "$pane_id")"
        EDITOR="nvim-edit.sh" exec yazi "''${2:-$PWD}" \
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
              printf "ts=%s\tsurface=yazi-dispatch\tkind=%s\tsender=%s\tbody=%s\n", ts, kind, sender, body >> log_file
              close(log_file)
            }')
      fi

      case "''${1:-}" in
        toggle | reveal | cd) ;;
        *)
          (($#)) || set -- "$PWD"
          EDITOR="nvim-edit.sh" exec yazi "$@"
          ;;
      esac

      if [[ -z "''${ZELLIJ:-}" ]]; then
        printf 'yazi-dispatch.sh %s: requires a Zellij session\n' "$1" >&2
        exit 1
      fi

      verb="$1"
      target=""
      if [[ "$verb" != "toggle" ]]; then
        target="''${2:?yazi-dispatch.sh $verb needs a path}"
        # emit-to resolves paths against the popup's cwd, never the caller's, and the cd action only accepts a directory — normalize both here so the
        # create and live-popup branches see one canonical target.
        target="$(realpath -m -- "$target")"
        if [[ "$verb" == "cd" && ! -d "$target" ]]; then
          target="$(dirname "$target")"
        fi
      fi

      # Serialize concurrent dispatchers (double-chord): one session-scoped lock spans snapshot-to-act, so racing
      # toggles never both read a popup-free tab and create duplicate popups.
      exec {lock_fd}>"$runtime_root/toggle.lock"
      flock -w 5 "$lock_fd" || {
        printf 'yazi-dispatch.sh: another toggle holds the dispatch lock\n' >&2
        exit 75
      }
      ${currentTabSh}
      # Dispatchers and yazi-with-entries rows never match; hidden floating popups retain is_floating, so identity holds through the hide cycle.
      popup="$(zellij action list-panes --all --json | jq -r --arg tab "$tab_id" '[.[] | select(${yaziPopupIdentity} and .tab_id == ($tab | tonumber))][0].id // ""')"

      # Per-tab surfaced marker: the dispatcher's own floating spawn surfaces the layer, so live layer state cannot discriminate show from hide. An
      # out-of-band layer toggle desyncs it by at most one keypress.
      marker="$runtime_root/surfaced-tab-''${tab_id}"
      # Floating, never in_place: on zellij 0.45.1 an in-place run from an attached client returns a pane id that never surfaces.
      spawn_popup() { # $1 = cwd for the new popup, $2 = yazi entry
        created="$(zellij action new-pane --tab-id "$tab_id" --floating --pinned true \
          ${yaziPopupArgs} \
          --name " [YAZI] " --close-on-exit --cwd "$1" -- yazi-dispatch.sh popup "$2")"
        zellij action focus-pane-id "$created" >/dev/null 2>&1 || true
        : >"$marker"
      }
      surface_popup() {
        # Best-effort focus: the popup can exit between snapshot and focus; the marker stays authoritative and self-heals within one chord.
        zellij action focus-pane-id "terminal_''${popup}" >/dev/null 2>&1 || true
        : >"$marker"
      }

      case "$verb" in
        toggle)
          if [[ -z "$popup" ]]; then
            spawn_popup "$PWD" "$PWD"
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
          # A fresh popup takes the target as its entry (reveal hovers it in its parent, cd opens it); a live popup's DDS endpoint is long up,
          # so the keymap-equivalent action lands in one ya emit-to.
          if [[ -z "$popup" ]]; then
            dir="$target"
            [[ "$verb" == "reveal" ]] && dir="$(dirname "$target")"
            spawn_popup "$dir" "$target"
          else
            ya emit-to "$(cid_of "$popup")" "$verb" "$target"
            surface_popup
          fi
          ;;
      esac
    '';
  };
in {
  imports = [../programs/apps/chords.nix];

  home.packages = [nvimEdit yaziDispatch];
}
