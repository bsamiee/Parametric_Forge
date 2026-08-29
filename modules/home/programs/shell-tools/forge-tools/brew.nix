# Title         : brew.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/forge-tools/brew.nix
# ----------------------------------------------------------------------------
# Homebrew currency owner: the one pass that keeps formulae, casks, and the WezTerm nightly current. nix-darwin's Brewfile only installs missing
# roster rows, and a `version :latest` cask never reads outdated, so without this rail the nightly silently freezes at its install date. The
# scheduled run is unattended-safe (formulae + nightly + cleanup); cask upgrades, which may quit running apps, ride the manual pass only.
{
  pkgs,
  tl,
}: {
  forgeBrewMaintenance = tl.mkTool {
    name = "forge-brew-maintenance";
    inputs = [pkgs.coreutils pkgs.gawk pkgs.gnugrep pkgs.flock];
    text = ''
      # Reject unknown argv up front: a typo must never silently run as a manual pass (600s lock wait, no AC gate).
      case "''${1:-}" in
        "") mode="manual" ;;
        --scheduled) mode="scheduled" ;;
        *)
          printf 'Usage: forge-brew-maintenance [--scheduled]\n' >&2
          exit 2
          ;;
      esac
      if [ "$#" -gt 1 ]; then
        printf 'forge-brew-maintenance: unexpected arguments after %s\n' "$1" >&2
        exit 2
      fi
      brew_bin="${tl.brewExpr}"
      lock_file="${tl.redeployLockExpr}"
      nightly_cask="wezterm@nightly"
      wezterm_bin="''${FORGE_WEZTERM_BIN:-/Applications/WezTerm.app/Contents/MacOS/wezterm}"
      export HOMEBREW_NO_ANALYTICS=1 HOMEBREW_NO_ENV_HINTS=1 HOMEBREW_NO_AUTO_UPDATE=1

      # One typed receipt per run; the EXIT trap emits it even when a leg aborts, so a failed upgrade or a frozen nightly stays visible.
      power="-" lock="-" update="-" upgrade="-" nightly="-" nightly_from="-" nightly_to="-" autoremove="-" cleanup="-"
      result="fail"
      emit_receipt() {
        persist_receipt "$(printf 'ts=%s\tmode=%s\tpower=%s\tlock=%s\tupdate=%s\tupgrade=%s\tnightly=%s\tnightly_from=%s\tnightly_to=%s\tautoremove=%s\tcleanup=%s\tresult=%s' \
          "$ts" "$mode" "$power" "$lock" "$update" "$upgrade" "$nightly" "$nightly_from" "$nightly_to" "$autoremove" "$cleanup" "$result")"
      }
      trap emit_receipt EXIT

      ${tl.acGateFold}
      if [ ! -x "$brew_bin" ]; then
        result="skipped"
        printf 'forge-brew-maintenance: no Homebrew at %s; skipped\n' "$brew_bin" >&2
        exit 0
      fi
      # The deploy lock: activation's own `brew bundle` never races this pass.
      mkdir -p "$(dirname "$lock_file")"
      exec {lock_fd}>"$lock_file"
      flock "''${flock_args[@]}" "$lock_fd" || {
        lock="held" result="skipped"
        printf 'forge-brew-maintenance: deploy in flight holds %s; skipped\n' "$lock_file" >&2
        exit 75
      }
      lock="ok"

      # The nightly's build stamp (YYYYMMDD-HHMMSS-sha) is the only currency signal a :latest cask carries; the receipt records both edges.
      nightly_stamp() { "$wezterm_bin" --version 2>/dev/null | awk '{print $2}' | grep . || printf 'absent'; }
      nightly_from="$(nightly_stamp)"
      # Leg verdicts stay per-leg: a failing upgrade never masks the nightly refresh or the cleanup that follows it.
      leg() { # $1 = receipt key, $2.. = brew argv
        local key="$1"
        shift
        if "$brew_bin" "$@"; then
          printf -v "$key" 'ok'
        else
          printf -v "$key" 'fail'
          printf 'forge-brew-maintenance: WARNING brew %s failed\n' "$*" >&2
        fi
      }
      leg update update --quiet
      # Cask upgrades quit running apps (1Password, editors) whenever the cask declares it, so only the attended manual pass takes them; the
      # scheduled pass upgrades formulae alone.
      if [ "$mode" = manual ]; then
        leg upgrade upgrade
      else
        leg upgrade upgrade --formula
      fi
      # A :latest cask is never outdated to brew; --greedy-latest is the only verb that re-downloads the nightly. The cask carries no quit stanza,
      # so a running WezTerm keeps its mapped binary and picks the new build up at its next launch.
      leg nightly upgrade --cask --greedy-latest "$nightly_cask"
      nightly_to="$(nightly_stamp)"
      leg autoremove autoremove
      leg cleanup cleanup --prune=all -s
      result="ok"
      for leg_state in "$update" "$upgrade" "$nightly" "$autoremove" "$cleanup"; do
        [ "$leg_state" = ok ] || result="partial"
      done
    '';
  };
}
