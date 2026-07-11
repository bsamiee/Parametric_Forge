# Title         : delegation.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/delegation.nix
# ----------------------------------------------------------------------------
# Delegation-observability owner for the Claude Code coordinator: a JSONL event ledger fed by subagent/task lifecycle hooks plus an opt-in external-worker
# emit lane, folded live by the main-statusLine roster renderer so codex/agy runs and native subagents surface with model, label, and elapsed instead of a
# generic spinner. Four bash tools, each built and shellchecked as a package: forge-fleet-hook (the lifecycle ledger writer routed off hook_event_name),
# forge-fleet-emit (the codex/agy declaration lane — model, label, exit truth a process scan cannot see), forge-fleet-status (the main-statusLine roster:
# a bounded ledger tail folded against a TTL-cached pgrep census, ~13ms warm / ~49ms on the census tick), and forge-fleet-row (the subagentStatusLine
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
  mkFleet = name:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [pkgs.jq pkgs.coreutils pkgs.gawk];
      text = builtins.readFile (./fleet + "/${name}.sh");
    };
  tools = lib.genAttrs names mkFleet;
in {
  home.packages = lib.attrValues tools;

  # Immediate-effect mirror: settings.json references ~/.claude/hooks/<name>.sh (a path the user owns, not managed by home.file), so install the raw
  # sources there byte-identical to the masters on every switch; the PATH-baked packages above remain the emit lane and the build-time shellcheck gate.
  # The statusline environment resolves jq from the user profile and awk as /usr/bin/awk — the scripts are proven against exactly that resolution.
  # install -m0755 overwrites in place — no symlink-clobber against a hand-placed live copy.
  home.activation.forgeFleetHooks = lib.hm.dag.entryAfter ["writeBoundary"] ''
    run ${pkgs.coreutils}/bin/mkdir -p "${config.home.homeDirectory}/.claude/hooks"
    ${lib.concatMapStringsSep "\n" (n: ''run ${pkgs.coreutils}/bin/install -m0755 "${./fleet + "/${n}.sh"}" "${config.home.homeDirectory}/.claude/hooks/${n}.sh"'') names}
  '';
}
