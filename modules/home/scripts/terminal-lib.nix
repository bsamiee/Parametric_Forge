# Title         : terminal-lib.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/scripts/terminal-lib.nix
# ----------------------------------------------------------------------------
# Shared vocabulary for the terminal rail: the popup-identity jq predicate, the caller's tab, the DDS client-id projection, and the
# runtime-root derivation. Every terminal.nix kernel reads these single bindings.
let
  # One popup-identity vocabulary — production dispatch and caller dismissal share this exact jq row predicate. terminal_command is the spawn
  # command (invoked_with), so exec inside the pane never breaks rediscovery; the entry argument follows the popup verb.
  yaziPopupIdentity = ''(.is_plugin | not) and (.exited | not) and ((.is_floating // false) or (.is_suppressed // false)) and ((.title // "") == " [YAZI] ") and ((.terminal_command // .command // "") | startswith("yazi-dispatch.sh popup"))'';

  # The caller's tab, from the server's tab table: a spawned pane's process starts before zellij registers the pane (pty.rs spawns, then
  # sends NewPane), so no rail kernel resolves its own row from list-panes.
  currentTabSh = ''tab_id="$(zellij action current-tab-info --json | jq -r .tab_id)"'';

  # One DDS client-id derivation: (session, pane_id) -> deterministic 6-digit id; the popup body and dispatcher both pipe
  # `printf '%s:%s' session pane` through this exact projection.
  cidPipeline = ''cksum | gawk '{ print ($1 % 899999) + 100000 }' '';

  # One runtime-root derivation for every rail script: RPC sockets, the editor and dispatch locks, surfaced markers, and DDS state live in a
  # canonical per-user private namespace. Every target is admitted only as a strict descendant of this root.
  runtimeBaseSh = ''
    runtime_base_raw="''${XDG_RUNTIME_DIR:-''${TMPDIR:-/tmp}}/nvim-edit"
    mkdir -p "$runtime_base_raw"
    runtime_base="$(realpath -- "$runtime_base_raw")"
    chmod go-rwx "$runtime_base"
    _runtime_child() {
      local _child
      _child="$(realpath -m -- "$runtime_base/$1")"
      if [[ "$_child" != "$runtime_base/"* ]]; then
        printf 'terminal rail: path escapes runtime root: %s\n' "$1" >&2
        return 75
      fi
      printf '%s\n' "$_child"
    }
  '';
in {
  inherit yaziPopupIdentity currentTabSh cidPipeline runtimeBaseSh;
}
