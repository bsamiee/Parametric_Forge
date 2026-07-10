# Title         : extensions.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/vscode/extensions.nix
# ----------------------------------------------------------------------------
# Extension roster consumer: overlays/manifest.nix `extensions.vscode` rows
# are desired state, the mutable user extensions dir is runtime state, and
# extensions.json stays VS Code-owned cache. `forge-vscode doctor` proves
# installed-vs-roster plus the settings sentinel; `sync` installs missing
# rows through the live Code CLI and never uninstalls — an extra is a drift
# row for the operator, not a deletion target.
{
  lib,
  pkgs,
  rows,
}: let
  # Roster rows carry the full admission contract — every security field the
  # manifest vocabulary names — so `forge-vscode roster` is the whole ledger.
  rosterJson = builtins.toJSON {
    schema = "forge-vscode-roster/v1";
    rows =
      lib.mapAttrsToList (_: r: {
        inherit (r) id publisher registry capability native_code postinstall_behavior secret_touching host_permissions runtime_write_policy mutable_paths;
      })
      rows;
  };

  forgeVscode = pkgs.writeShellApplication {
    name = "forge-vscode";
    runtimeInputs = [pkgs.jq pkgs.coreutils pkgs.gnugrep];
    text = ''
      roster="''${XDG_CONFIG_HOME:-$HOME/.config}/forge/vscode/roster.json"
      settings="$HOME/Library/Application Support/Code/User/settings.json"
      code_bin="''${FORGE_VSCODE_CODE_BIN:-/opt/homebrew/bin/code}"
      receipts="''${FORGE_VSCODE_RECEIPT_LOG:-$HOME/Library/Logs/forge-vscode.receipts.log}"
      fail() { # $1=code $2=detail -> error envelope on the one rail
        jq -n --arg code "$1" --arg detail "$2" '{schema:"forge-vscode/v1", ok:false, error:{code:$code, detail:$detail}}'
        exit 69
      }
      [[ -x $code_bin ]] || fail code-cli-missing "VS Code CLI not executable; set FORGE_VSCODE_CODE_BIN"
      [[ -r $roster ]] || fail roster-missing "roster projection absent; run forge-redeploy --switch"
      emit() { # $1=verb $2=target $3=result
        local ts
        TZ=UTC0 printf -v ts '%(%Y-%m-%dT%H:%M:%SZ)T' "$EPOCHSECONDS"
        mkdir -p "''${receipts%/*}"
        printf 'ts=%s\tsurface=forge-vscode\tverb=%s\ttarget=%s\tresult=%s\n' "$ts" "$1" "$2" "$3" >>"$receipts"
        jq -cn --arg ts "$ts" --arg surface "forge-vscode" --arg verb "$1" --arg target "$2" --arg result "$3" \
          '{ts:$ts, surface:$surface, verb:$verb, target:$target, result:$result}' >>"''${receipts%.log}.jsonl"
      }
      # One classification fold: roster ids vs live ids (stdin), case-normalized.
      # The live list is captured at the call site so a CLI failure rails as an
      # envelope instead of dying raw inside a pipeline.
      classify() {
        jq -Rn --slurpfile roster <(jq '[.rows[].id | ascii_downcase]' "$roster") '
          [inputs | select(length > 0) | ascii_downcase] as $live | $roster[0] as $want
          | ($want - $live | map({id: ., state: "missing"}))
            + ($want - ($want - $live) | map({id: ., state: "bound"}))
            + ($live - $want | map({id: ., state: "extra"}))'
      }
      case "''${1:-doctor}" in
        doctor)
          live=$("$code_bin" --list-extensions 2>/dev/null) || fail code-cli-list-failed "code --list-extensions exited non-zero"
          sentinel="absent"
          if [[ -s $settings ]] && grep -q "forge-theme:begin" "$settings" && grep -q "forge-theme:end" "$settings"; then
            sentinel="bound"
          fi
          report=$(classify <<<"$live" | jq --arg sentinel "$sentinel" \
            '{schema:"forge-vscode/v1", ok: (($sentinel == "bound") and (map(select(.state == "missing")) | length == 0)), sentinel: $sentinel, rows: sort_by(.state, .id)}')
          printf '%s\n' "$report"
          jq -e '.ok' <<<"$report" >/dev/null || exit 1
          ;;
        sync)
          live=$("$code_bin" --list-extensions 2>/dev/null) || fail code-cli-list-failed "code --list-extensions exited non-zero"
          failures=0
          while IFS= read -r ext_id; do
            if "$code_bin" --install-extension "$ext_id" --force >/dev/null 2>&1; then
              emit install "$ext_id" ok
            else
              emit install "$ext_id" fail
              failures=$((failures + 1))
            fi
          done < <(classify <<<"$live" | jq -r '.[] | select(.state == "missing") | .id')
          live=$("$code_bin" --list-extensions 2>/dev/null) || fail code-cli-list-failed "code --list-extensions exited non-zero after install pass"
          classify <<<"$live" | jq --argjson failures "$failures" \
            '{schema:"forge-vscode/v1", ok: ($failures == 0), installedNow: (map(select(.state == "bound")) | length), extras: [.[] | select(.state == "extra") | .id], failures: $failures}'
          [[ $failures -eq 0 ]] || exit 1
          ;;
        roster)
          jq '{schema, rows: (.rows | sort_by(.id))}' "$roster"
          ;;
        *)
          printf 'usage: forge-vscode [doctor|sync|roster]\n' >&2
          exit 64
          ;;
      esac
    '';
  };
in {
  inherit rosterJson;
  package = forgeVscode;
}
