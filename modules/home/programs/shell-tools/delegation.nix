# Title         : delegation.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/delegation.nix
# ----------------------------------------------------------------------------
# Delegation-observability owner for the Claude Code coordinator: a JSONL event ledger fed by subagent/task lifecycle hooks plus an opt-in external-worker
# emit lane, folded live by the main-statusLine roster renderer so codex/agy runs and native subagents surface with model, label, and elapsed instead of a
# generic spinner. Fleet scripts and the attention emitter build as shellchecked packages: forge-fleet-hook routes lifecycle rows,
# forge-fleet-emit (the codex/agy declaration lane — model, label, exit truth a process scan cannot see), forge-fleet-status (the main-statusLine roster:
# a bounded ledger tail folded against a TTL-cached process census), and forge-fleet-row (the subagentStatusLine
# per-row model·label·elapsed·ctx% override). Session scoping law: claude exports CLAUDE_CODE_SESSION_ID to every child and it equals the statusLine
# payload's session_id, so ledger rows stamp it at write and the renderer adopts scanned/detached workers by reading it from each candidate pid's env
# (ps -E; survives reparenting to launchd, where ancestry dies) — one session's workers never bleed into another pane. Platform bounds: the main
# statusLine refreshInterval floor is 1s (event-driven plus timer); the subagent panel re-renders only on the harness's ~5s tick with no faster knob, so
# row counters advance in tick-sized steps. The fleet awk is strictly POSIX and proven under both /usr/bin/awk (the raw mirror's PATH resolves no gawk)
# and the gawk baked here. The packages land on PATH for the emit lane; the activation step mirrors the raw scripts into ~/.claude/hooks/*.sh, the stable
# path the user-owned settings.json references, so the same switch that ships this module refreshes the live handlers. The ledger homes beside the
# forge-agents attention feed under the XDG state root; consumers read the environment, never hardcode the path.
{
  config,
  lib,
  pkgs,
  ...
}: let
  # One tool per script: writeShellApplication bakes the deterministic jq/gawk PATH and runs shellcheck at build. ps/pgrep resolve from the inherited
  # system PATH so BSD etime parsing stays correct; system ps is never shadowed by a GNU procps that would break the elapsed grammar.
  names = ["forge-fleet-hook" "forge-fleet-status" "forge-fleet-row" "forge-fleet-emit"];
  lockLibrary = ./fleet/forge-fleet-lock.sh;
  lockSource = ''
    # shellcheck source=forge-fleet-lock.sh
    source "''${FORGE_FLEET_LOCK_LIB:-''${BASH_SOURCE[0]%/*}/forge-fleet-lock.sh}"
  '';
  mkFleet = name: let
    source = builtins.readFile (./fleet + "/${name}.sh");
    text =
      if builtins.elem name ["forge-fleet-hook" "forge-fleet-emit"]
      then builtins.replaceStrings [lockSource] [(builtins.readFile lockLibrary)] source
      else source;
  in
    pkgs.writeShellApplication {
      inherit name text;
      runtimeInputs = [pkgs.jq pkgs.coreutils pkgs.gawk];
    };
  tools = lib.genAttrs names mkFleet;
  agentAttention = pkgs.writeShellApplication {
    name = "forge-agent-attention";
    runtimeInputs = [pkgs.coreutils pkgs.flock pkgs.jq];
    text = builtins.readFile ../../../../.claude/hooks/agent-attention.sh;
  };
  agentAttentionEmit = pkgs.writeShellApplication {
    name = "forge-attention-emit";
    runtimeInputs = [pkgs.coreutils pkgs.flock pkgs.jq];
    text = ''
      [[ "$#" -eq 2 ]] || exit 64
      feed="$1"
      payload="$2"
      [[ -n "$feed" ]] || exit 0
      feed_dir="''${feed%/*}"
      [[ "$feed_dir" != "$feed" ]] || feed_dir=.
      (( ''${#payload} <= 1048576 )) || exit 0
      max_rows_raw="''${FORGE_ATTENTION_MAX_ROWS:-4000}"
      keep_rows_raw="''${FORGE_ATTENTION_KEEP_ROWS:-1000}"
      [[ "$max_rows_raw" =~ ^0*([1-9][0-9]{0,5})$ ]] || exit 0
      max_rows="$((10#''${BASH_REMATCH[1]}))"
      [[ "$keep_rows_raw" =~ ^0*([1-9][0-9]{0,5})$ ]] || exit 0
      keep_rows="$((10#''${BASH_REMATCH[1]}))"
      ((max_rows <= 100000 && keep_rows <= max_rows)) || exit 0
      row="$(printf '%s\n' "$payload" | jq -ec '
        select(type == "object" and .source == "bell" and .event == "Bell")
        | select((.ts | type) == "string" and (.wezterm_pane | type) == "string")')" || exit 0
      mkdir -p "$feed_dir"
      rotation=""
      trap '[[ -z "$rotation" ]] || rm -f -- "$rotation"' EXIT
      exec {writer_fd}>"''${feed}.writer.lock"
      flock -n "$writer_fd" || exit 0
      printf '%s\n' "$row" >>"$feed"
      rows="$(wc -l <"$feed")"
      rows="''${rows//[[:space:]]/}"
      if [[ "$rows" =~ ^(0|[1-9][0-9]*)$ ]] && ((10#$rows > max_rows)); then
        rotation="$(mktemp "''${feed}.rot.XXXXXX")"
        tail -n "$keep_rows" -- "$feed" >"$rotation"
        mv -f -- "$rotation" "$feed"
        rotation=""
      fi
      exec {writer_fd}>&-
    '';
  };
in {
  home.packages = (lib.attrValues tools) ++ [agentAttention agentAttentionEmit];

  # Immediate-effect mirror: settings.json references ~/.claude/hooks/<name>.sh (a path the user owns, not managed by home.file), so install the raw
  # sources there byte-identical to the masters on every switch; the PATH-baked packages above remain the emit lane and the build-time shellcheck gate.
  # The statusline environment resolves jq from the user profile and awk as /usr/bin/awk — the scripts are proven against exactly that resolution.
  # install -m0755 overwrites in place — no symlink-clobber against a hand-placed live copy.
  home.activation.forgeFleetHooks = lib.hm.dag.entryAfter ["writeBoundary"] ''
    run ${pkgs.coreutils}/bin/mkdir -p "${config.home.homeDirectory}/.claude/hooks"
    ${lib.concatMapStringsSep "\n" (n: ''run ${pkgs.coreutils}/bin/install -m0755 "${./fleet + "/${n}.sh"}" "${config.home.homeDirectory}/.claude/hooks/${n}.sh"'') names}
    run ${pkgs.coreutils}/bin/install -m0755 "${lockLibrary}" "${config.home.homeDirectory}/.claude/hooks/forge-fleet-lock.sh"
  '';
}
