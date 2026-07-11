# Title         : delegation.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/delegation.nix
# ----------------------------------------------------------------------------
# Delegation-observability owner for the Claude Code coordinator: a JSONL event ledger fed by subagent/task lifecycle hooks plus an opt-in external-worker
# emit lane, folded live by the main-statusLine roster renderer so codex/agy runs and native subagents surface with model, label, and elapsed instead of a
# generic spinner. Four bash tools, each built and shellchecked as a package: forge-fleet-hook (the lifecycle ledger writer routed off hook_event_name),
# forge-fleet-emit (the codex/agy declaration lane — model, label, exit truth a pgrep scan cannot see), forge-fleet-status (the main-statusLine roster: a
# bounded ledger tail folded against a single ps|awk process scan, sub-100ms), and forge-fleet-row (the subagentStatusLine per-row model·label·elapsed
# override). The packages land on PATH for the emit lane; the activation step mirrors them into ~/.claude/hooks/*.sh, the stable path the user-owned
# settings.json references, so the same switch that ships this module refreshes the live handlers. The ledger homes beside the forge-agents attention feed
# under the XDG state root; consumers read the environment, never hardcode the path.
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

  # Immediate-effect mirror: settings.json references ~/.claude/hooks/<name>.sh (a path the user owns, not managed by home.file), so install the built,
  # PATH-baked binaries there on every switch. install -m0755 overwrites in place — no symlink-clobber against a hand-placed live copy.
  home.activation.forgeFleetHooks = lib.hm.dag.entryAfter ["writeBoundary"] ''
    run ${pkgs.coreutils}/bin/mkdir -p "${config.home.homeDirectory}/.claude/hooks"
    ${lib.concatMapStringsSep "\n" (n: ''run ${pkgs.coreutils}/bin/install -m0755 "${tools.${n}}/bin/${n}" "${config.home.homeDirectory}/.claude/hooks/${n}.sh"'') names}
  '';
}
