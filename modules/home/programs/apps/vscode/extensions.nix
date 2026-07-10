# Title         : extensions.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/vscode/extensions.nix
# ----------------------------------------------------------------------------
# Extension roster consumer: overlays/manifest.nix `extensions.vscode` rows are desired state, the mutable user extensions dir is
# runtime state, and extensions.json stays VS Code-owned cache. `forge-vscode doctor` proves installed-vs-roster, the settings and
# keybindings sentinels; `sync` installs missing rows through the live Code CLI and never uninstalls — an extra is operator freedom,
# and uninstalling one is an operator gesture, never code.

{
  lib,
  pkgs,
  rows,
}: let
  # Supersession map — the one durable drift ruling: an id here duplicates a surface the estate already owns, so its presence (now or after removal)
  # is a named finding, never bare drift. Keys are lowercase to join the case-normalized classify fold. Age alone never mints a row: a merely
  # outdated or undecided extra (dotenv syntax for files the secrets law bans, viewers with no owned twin) is the operator's uninstall, not code.
  superseded = {
    "aaron-bond.better-comments" = "Gruntfuggly.todo-tree + owner tag rows";
    "alefragnani.project-manager" = "forge-workspace session fabric";
    "be5invis.toml" = "tamasfe.even-better-toml roster row";
    "bierner.markdown-mermaid" = "builtin mermaid-markdown-features";
    "bmalehorn.shell-syntax" = "timonwong.shellcheck diagnostics lane";
    "bpruitt-goddard.mermaid-markdown-syntax-highlighting" = "builtin mermaid-markdown-features";
    "donjayamanne.python-extension-pack" = "members individually roster-decided";
    "evondev.dracula-high-contrast" = "theme law: Default Dark Modern + palette override";
    "georgiatechdb.sqlcheck" = "estate SQL quality lane sqlfluff/sqruff";
    "humao.rest-client" = "estate API lane hurl/xh/grpcurl";
    "mathematic.vscode-pdf" = "duplicate of tomoki1207.pdf";
    "nhoizey.gremlins" = "builtin editor.unicodeHighlight family";
    "oderwat.indent-rainbow" = "builtin indent guides + bracket-pair cycle";
    "patcx.vscode-nuget-gallery" = "nuget MCP + hand-curated manifest law";
    "pflannery.vscode-versionlens" = "nuget MCP + hand-curated manifest law";
    "shardulm94.trailing-spaces" = "owner renderWhitespace + trimTrailingWhitespace";
    "spywhere.guides" = "builtin indent guides + bracket-pair cycle";
    "tomoyukim.vscode-mermaid-editor" = "builtin mermaid-markdown-features";
    "uniquevision.vscode-plpgsql-lsp" = "estate postgres-language-server lane";
    "vstirbu.vscode-mermaid-preview" = "builtin mermaid-markdown-features";
  };

  # Contradiction guard: an id cannot be desired (roster) and condemned (superseded) at once — a re-admission
  # must retire the ruling in the same change, or the doctor proves "bound" while the map damns it.
  contradictions = builtins.filter (id: lib.elem id (map (r: lib.toLower r.id) (lib.attrValues rows))) (builtins.attrNames superseded);

  # Roster rows carry the full admission contract — every security field the manifest vocabulary names — and
  # the supersession map rides beside them, so `forge-vscode roster` is the whole desired-state + ruling surface.
  rosterJson = lib.throwIf (contradictions != []) "forge-vscode roster/supersession contradiction: ${lib.concatStringsSep ", " contradictions}" (builtins.toJSON {
    schema = "forge-vscode-roster/v2";
    rows =
      lib.mapAttrsToList (_: r: {
        inherit (r) id publisher registry capability native_code postinstall_behavior secret_touching host_permissions runtime_write_policy mutable_paths;
      })
      rows;
    inherit superseded;
  });

  forgeVscode = pkgs.writeShellApplication {
    name = "forge-vscode";
    runtimeInputs = [pkgs.jq pkgs.coreutils pkgs.gnugrep pkgs.gnused];
    text = ''
      roster="''${XDG_CONFIG_HOME:-$HOME/.config}/forge/vscode/roster.json"
      keys_block="''${XDG_CONFIG_HOME:-$HOME/.config}/forge/vscode/keybindings-block.jsonc"
      settings="$HOME/Library/Application Support/Code/User/settings.json"
      keybindings="$HOME/Library/Application Support/Code/User/keybindings.json"
      code_bin="''${FORGE_VSCODE_CODE_BIN:-/opt/homebrew/bin/code}"
      receipts="''${FORGE_VSCODE_RECEIPT_LOG:-$HOME/Library/Logs/forge-vscode.receipts.log}"
      fail() { # $1=code $2=detail -> error envelope on the one rail
        jq -n --arg code "$1" --arg detail "$2" '{schema:"forge-vscode/v2", ok:false, error:{code:$code, detail:$detail}}'
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
      sentinel_of() { # $1=file $2=marker -> bound|absent
        if [[ -s $1 ]] && grep -q "$2:begin" "$1" && grep -q "$2:end" "$1"; then
          printf 'bound'
        else
          printf 'absent'
        fi
      }
      # Tail proof, not marker presence: the live region must equal the projected block byte-for-byte (a second
      # marker pair or an edited row reads stale) AND nothing but blanks, comments, and the closing "]" may follow
      # it — tail position is the authority position the rail claims, so a displaced block is a named finding.
      keys_probe() { # -> bound|stale|displaced|absent
        [[ -s $keybindings && -r $keys_block ]] || { printf 'absent'; return; }
        if ! { grep -q "forge-keys:begin" "$keybindings" && grep -q "forge-keys:end" "$keybindings"; }; then
          printf 'absent'
          return
        fi
        [[ "$(sed -n '/forge-keys:begin/,/forge-keys:end/p' "$keybindings")" == "$(cat "$keys_block")" ]] || { printf 'stale'; return; }
        trailing=$(awk '/forge-keys:end/ {f = 1; next} f && !/^[[:space:]]*$/ && !/^[[:space:]]*\/\// && !/^[[:space:]]*\][[:space:]]*$/ {c++} END {print c + 0}' "$keybindings")
        [[ $trailing -eq 0 ]] || { printf 'displaced'; return; }
        printf 'bound'
      }
      # One classification fold: roster ids vs live ids (stdin), case-normalized; an extra matching the supersession map carries its ruling inline.
      # The live list is captured at the call site so a CLI failure rails as an envelope instead of dying raw inside a pipeline.
      classify() {
        jq -Rn --slurpfile roster <(jq '{ids: [.rows[].id | ascii_downcase], superseded: (.superseded // {})}' "$roster") '
          [inputs | select(length > 0) | ascii_downcase] as $live
          | $roster[0].ids as $want | $roster[0].superseded as $s
          | ($want - $live | map({id: ., state: "missing"}))
            + ($want - ($want - $live) | map({id: ., state: "bound"}))
            + ($live - $want | map({id: ., state: "extra"} + (if $s[.] then {superseded_by: $s[.]} else {} end)))'
      }
      case "''${1:-doctor}" in
        doctor)
          live=$("$code_bin" --list-extensions 2>/dev/null) || fail code-cli-list-failed "code --list-extensions exited non-zero"
          sentinel=$(sentinel_of "$settings" "forge-theme")
          keys=$(keys_probe)
          report=$(classify <<<"$live" | jq --arg sentinel "$sentinel" --arg keys "$keys" '
            {schema: "forge-vscode/v2",
             ok: (($sentinel == "bound") and ($keys == "bound") and (map(select(.state == "missing")) | length == 0)),
             sentinel: $sentinel, keybindings: $keys,
             extras: (map(select(.state == "extra")) | length),
             superseded: [.[] | select(.superseded_by) | .id],
             rows: sort_by(.state, .id)}')
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
            '{schema: "forge-vscode/v2", ok: ($failures == 0),
              installedNow: (map(select(.state == "bound")) | length),
              extras: (map(select(.state == "extra")) | length),
              superseded: [.[] | select(.superseded_by) | .id],
              failures: $failures}'
          [[ $failures -eq 0 ]] || exit 1
          ;;
        roster)
          jq '{schema, rows: (.rows | sort_by(.id)), superseded}' "$roster"
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
