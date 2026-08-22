# Title         : lib.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/forge-tools/lib.nix
# ----------------------------------------------------------------------------
# Shared vocabulary for the forge-tools kernels: the receipt-bearing tool builder, named path defaults, the AC/lock gate, the acceptance verdict
# mark, and the launchd agent fold.
{
  config,
  lib,
  pkgs,
}: let
  receiptsFold = import ../../../../common/receipts.nix;
  logs = "${config.home.homeDirectory}/Library/Logs";
  bundleId = "com.parametric-forge.forge-nix-automation";
  inherit (config.forge.theme) roles icons;
in rec {
  # Env-overridable path defaults named once: every kernel interpolates these instead of respelling the literals.
  forgeRootExpr = "\${FORGE_ROOT:-$HOME/Documents/99.Github/Parametric_Forge}";
  brewExpr = "\${FORGE_BREW:-/opt/homebrew/bin/brew}";
  redeployLockExpr = "\${FORGE_REDEPLOY_LOCK:-$HOME/.cache/forge-redeploy.lock}";

  # Platform ps dispatch: /bin/ps is a Darwin fact; NixOS gets procps by store path so a manual run on the Linux host degrades typed, never 127.
  psBin =
    if pkgs.stdenv.hostPlatform.isDarwin
    then "/bin/ps"
    else "${pkgs.procps}/bin/ps";

  # Acceptance verdict mark: renders a verdict as its alphabet ASCII twin colored on the state ladder, TTY/NO_COLOR-gated because every line is
  # piped and persisted.
  statusFold = ''
    if [ -t 2 ] && [ -z "''${NO_COLOR:-}" ]; then _sgr() { printf '\033[38;2;%sm' "$1"; }; _rst=$'\033[0m'; else _sgr() { :; }; _rst=""; fi
    mark() {
      local m c
      case "$1" in
        PASS) m='${icons.alphabet.ok.ascii}' c='${roles.state.success.triple}' ;;
        FAIL) m='${icons.alphabet.failure.ascii}' c='${roles.state.danger.triple}' ;;
        WARN) m='${icons.alphabet.warning.ascii}' c='${roles.state.warning.triple}' ;;
        INSTRUCT) m='${icons.alphabet.attention.ascii}' c='${roles.state.attention.triple}' ;;
        SKIP) m='${icons.alphabet.idle.ascii}' c='${roles.text.muted.triple}' ;;
        *) m="$1" c='${roles.text.muted.triple}' ;;
      esac
      printf '%s%-4s%s' "$(_sgr "$c")" "$m" "$_rst"
    }
  '';

  # Shared scheduled-run gate (maintenance agents): AC-gated on battery hosts — pmset is a Darwin fact, a host without it is mains-powered and
  # skips the gate instead of dying under pipefail; scheduled runs yield the lock (-n), manual runs wait. Consume-all grep avoids the -q
  # pipefail/SIGPIPE false skip. Callers own trap-set receipts before interpolating, so the battery skip stays visible.
  acGateFold = ''
    if [ "$mode" = "scheduled" ]; then
      if [ -x /usr/bin/pmset ]; then
        /usr/bin/pmset -g batt | grep "AC Power" >/dev/null || {
          power="battery" result="skipped"
          exit 0
        }
        power="ac"
      else
        power="mains"
      fi
      flock_args=(-n)
    else
      flock_args=(-w 600)
    fi
  '';

  # One builder owns the shared tool rail: UTC stamp, per-tool receipt-log override (FORGE_<NAME>_RECEIPT_LOG), and the dual-receipt fold — every
  # persist_receipt row lands as one TSV line plus a JSONL sibling with identical keys. storePath prepends the Determinate profile so every
  # nix/nix-env call (incl. nh's) resolves the daemon-matched client.
  mkTool = {
    name,
    inputs ? [],
    receiptName ? name,
    storePath ? false,
    text,
  }: let
    envKey = "FORGE_${lib.toUpper (lib.replaceStrings ["-"] ["_"] (lib.removePrefix "forge-" receiptName))}_RECEIPT_LOG";
  in
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = lib.unique (inputs ++ [pkgs.jq]);
      text =
        lib.optionalString storePath ''
          export PATH="/nix/var/nix/profiles/default/bin:$PATH"
        ''
        + ''
          TZ=UTC0 printf -v ts '%(%Y-%m-%dT%H:%M:%SZ)T' "$EPOCHSECONDS"
          receipt_log="''${${envKey}:-$HOME/Library/Logs/${receiptName}.receipts.log}"
          receipt_surface="${receiptName}"
          ${receiptsFold}
          # An unwritable log must never fail a trap or mask a landed run.
          persist_receipt() {
            append_receipt "$1" \
              || printf '${name}: WARNING receipt not persisted to %s\n' "$receipt_log" >&2
            printf '${name}: receipt\t%s\n' "$1"
          }
        ''
        + text;
    };

  # Scheduled-agent fold: one Login Items identity (the automation bundle), one log per agent, schedule and argv as the only per-row facts.
  mkAgent = name: schedule: argv: {
    enable = true;
    config =
      {
        Label = "com.parametric-forge.${name}";
        ProgramArguments = argv;
        ProcessType = "Background";
        StandardOutPath = "${logs}/${name}.log";
        StandardErrorPath = "${logs}/${name}.log";
        AssociatedBundleIdentifiers = [bundleId];
      }
      // schedule;
  };
}
