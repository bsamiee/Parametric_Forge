# Title         : doctor.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/forge-tools/doctor.nix
# ----------------------------------------------------------------------------
# forge-doctor: one machine doctor with catalog-row lens dispatch — path (PATH/binary provenance), launchd (agent census), parity (generation vs
# live $HOME), updates (currency board). Read-only; every lens emits one typed row stream rendering both the human table and --json, plus a receipt.
{
  lib,
  pkgs,
  tl,
}: let
  # ~/.local/bin admission-or-removal decisions: every unmanaged entry carries a named ruling; an entry absent from this table reports unadjudicated.
  localBinDecisions = pkgs.writeText "forge-doctor-localbin-decisions.json" (builtins.toJSON {
    claude = "admitted: launcher symlink into the versioned install";
    coderabbit = "reviewer-identity: official self-updating reviewer binary (services matrix)";
    cr = "reviewer-identity: symlink to coderabbit";
    macroscope = "reviewer-identity: official self-updating reviewer binary (services matrix)";
    agy = "admitted-agent: antigravity CLI";
    "pre-commit" = "uv-lane: uv tool shim";
    "pynvim-python" = "uv-lane: uv tool shim";
    "python3.12" = "uv-lane: uv runtime shim";
    "python3.14" = "uv-lane: uv runtime shim";
    tree = "hm: generation link";
    loc = "hm: generation link";
  });

  # Launchd triage vocabulary: label-prefix rows classifying every non-Apple agent; unmatched labels report unclassified and demand a row.
  launchdTriage = pkgs.writeText "forge-doctor-launchd-triage.json" (builtins.toJSON (lib.mapAttrsToList
    (prefix: t: {
      inherit prefix;
      class = lib.head t;
      note = lib.last t;
    })
    {
      "com.parametric-forge." = ["forge" "Forge launchd grammar"];
      "org.nix-community.home." = ["hm" "HM module agents"];
      "com.adobe." = ["vendor" "Adobe CC estate; retain-or-prune trust row open"];
      "mega.mac." = ["residue" "MEGA updater poller; gui-removal open class"];
      "org.pqrs." = ["vendor" "Karabiner services"];
      "com.openssh." = ["system" "ssh-agent"];
      "com.1password." = ["vendor" "1Password agents"];
      "com.bardiasamiee.codex.update" = ["vendor" "Codex self-updater"];
      "com.microsoft." = ["vendor" "Microsoft update/agent surfaces"];
      "com.macpaw." = ["vendor" "CleanMyMac MAS agents"];
      "com.spotify." = ["vendor" "Spotify startup helper"];
      "com.google." = ["vendor" "Google updater/drivefs"];
    }));

  # Lens catalog: dispatch rows declaring handler and description; the dispatcher admits the lens here before any handler runs.
  doctorCatalog = pkgs.writeText "forge-doctor-catalog.json" (builtins.toJSON [
    {
      lens = "path";
      handler = "lens_path";
      desc = "PATH owner classes, cross-owner shadows, MAGIC seed, CLT health, brew posture, ~/.local/bin rulings";
    }
    {
      lens = "launchd";
      handler = "lens_launchd";
      desc = "declared LaunchAgents plists reconciled with the live launchctl table";
    }
    {
      lens = "parity";
      handler = "lens_parity";
      desc = "generation home-files vs live HOME, broken store links, HM gc-root singleton";
    }
    {
      lens = "updates";
      handler = "lens_updates";
      desc = "update-visibility board: flake-input age, deploy receipt, brew currency, uv tools";
    }
  ]);

  doctorCompletion = pkgs.writeTextDir "share/zsh/site-functions/_forge-doctor" ''
    #compdef forge-doctor
    _arguments \
      '1:lens:(path launchd parity updates)' \
      '--json[typed row envelope (schema forge-doctor/v1)]'
  '';
in {
  inherit doctorCompletion;

  forgeDoctor = tl.mkTool {
    name = "forge-doctor";
    inputs = [pkgs.coreutils pkgs.diffutils pkgs.findutils pkgs.gnugrep pkgs.gawk pkgs.jq];
    text = ''
      catalog='${doctorCatalog}'
      usage() {
        printf 'Usage: forge-doctor LENS [--json]\n\nLenses:\n'
        jq -r '.[] | [.lens, .desc] | @tsv' "$catalog" | gawk -F'\t' '{printf "  %-8s %s\n", $1, $2}'
      }
      lens="''${1:-}"
      shift || true
      case "$lens" in
        "" | --help | -h)
          usage
          exit 0
          ;;
      esac
      as_json=0
      case "''${1:-}" in
        "") ;;
        --json) as_json=1 ;;
        *)
          usage >&2
          exit 64
          ;;
      esac
      handler="$(jq -r --arg l "$lens" 'first(.[] | select(.lens == $l) | .handler) // empty' "$catalog")"
      if [ -z "$handler" ]; then
        printf 'forge-doctor: unknown lens %s (lenses: %s)\n' "$lens" "$(jq -r 'map(.lens) | join(" ")' "$catalog")" >&2
        exit 64
      fi
      work="$(mktemp -d)"
      trap 'rm -rf "$work"' EXIT
      result=ok
      brew_bin="${tl.brewExpr}"

      # PATH and binary provenance: owner classification per PATH segment, cross-owner shadow detection on resolved targets, the file/MAGIC seed
      # case, CLT health, brew posture, and the ~/.local/bin decision inventory.
      # shellcheck disable=SC2329  # dispatched through the catalog handler row
      lens_path() {
        local shadows=0 mismatches=0 unadjudicated=0
        owner_of() {
          case "$1" in
            /etc/profiles/per-user/* | "$HOME/.nix-profile"*) echo hm ;;
            /run/current-system/*) echo system ;;
            /nix/*) echo nix ;;
            /opt/homebrew/*) echo homebrew ;;
            "$HOME/.local/bin"*) echo local ;;
            /usr/bin/* | /bin/* | /usr/sbin/* | /sbin/* | /usr/libexec/*) echo macos ;;
            /Applications/* | "$HOME/Applications"*) echo app ;;
            *) echo unknown ;;
          esac
        }
        # Cross-owner shadow scan: a later PATH segment holding a DIFFERENT binary under a DIFFERENT owner class than the winning segment.
        declare -A win
        local segs d f n w wo so wt st
        IFS=: read -ra segs < <(printf '%s\n' "$PATH")
        for d in "''${segs[@]}"; do
          [ -d "$d" ] || continue
          for f in "$d"/*; do
            [ -x "$f" ] || continue
            n="''${f##*/}"
            if [ -z "''${win[$n]:-}" ]; then
              win[$n]="$f"
            else
              w="''${win[$n]}"
              wo="$(owner_of "$w")" so="$(owner_of "$f")"
              # Store owners (hm/nix/system) winning over macos/homebrew is the sanctioned PATH order; only an inverted or foreign winner drifts.
              case "$wo" in hm | nix | system) continue ;; esac
              # Homebrew over the macOS copy is why the formula is installed: the row still prints, but it never scores as drift.
              sanctioned=0
              if [ "$wo" = homebrew ] && [ "$so" = macos ]; then sanctioned=1; fi
              if [ "$wo" != "$so" ]; then
                wt="$(readlink -f "$w" 2>/dev/null || echo "$w")"
                st="$(readlink -f "$f" 2>/dev/null || echo "$f")"
                if [ "$wt" != "$st" ]; then
                  [ "$sanctioned" = 1 ] || shadows=$((shadows + 1))
                  printf 'family=shadow\tcommand=%s\twinner=%s:%s\tshadowed=%s:%s\tsanctioned=%s\n' "$n" "$wo" "$w" "$so" "$f" "$sanctioned"
                fi
              fi
            fi
          done
        done
        # Seed case: MAGIC pins a store magic database; the serving binary must be the store file, never /usr/bin/file 5.41 (v20-magic rejection).
        local f_bin f_owner clt cltv
        f_bin="$(command -v file || true)"
        f_owner="$(owner_of "''${f_bin:-/dev/null}")"
        if [ -n "''${MAGIC:-}" ] && [ "$f_owner" = macos ]; then
          mismatches=$((mismatches + 1))
          printf 'family=file-magic\tstate=mismatch\tfile=%s\tmagic=%s\tfix=install pkgs.file beside the MAGIC export\n' "$f_bin" "''${MAGIC}"
        else
          printf 'family=file-magic\tstate=ok\tfile=%s\towner=%s\n' "''${f_bin:-absent}" "$f_owner"
        fi
        # CLT health: native builds break silently when the CLT tree drifts.
        clt="$(/usr/bin/xcode-select -p 2>/dev/null || true)"
        if [ -n "$clt" ] && [ -d "$clt" ]; then
          cltv="$(/usr/sbin/pkgutil --pkg-info=com.apple.pkg.CLTools_Executables 2>/dev/null | awk '/^version:/ {print $2}' || true)"
          printf 'family=clt\tstate=ok\tpath=%s\tversion=%s\n' "$clt" "''${cltv:-unknown}"
        else
          mismatches=$((mismatches + 1))
          printf 'family=clt\tstate=missing\tfix=xcode-select --install\n'
        fi
        # Brew posture: taps and pins are read-only telemetry rows.
        if [ -x "$brew_bin" ]; then
          printf 'family=brew\ttaps=%s\n' "$("$brew_bin" tap 2>/dev/null | paste -sd, - || true)"
          printf 'family=brew\tpinned=%s\n' "$("$brew_bin" list --pinned 2>/dev/null | paste -sd, - || echo none)"
        else
          printf 'family=brew\tstate=absent\tpath=%s\n' "$brew_bin"
        fi
        # ~/.local/bin inventory: owner class from the resolved target, decision from the ruling table (loaded once); unruled entries surface loudly.
        declare -A decision_row
        local dk dv tgt cls decision
        while IFS=$'\t' read -r dk dv; do decision_row[$dk]="$dv"; done \
          < <(jq -r 'to_entries[] | [.key, .value] | @tsv' '${localBinDecisions}')
        for f in "$HOME/.local/bin"/*; do
          [ -e "$f" ] || [ -L "$f" ] || continue
          n="''${f##*/}"
          if [ -L "$f" ]; then
            tgt="$(readlink -f "$f" 2>/dev/null || echo broken)"
            case "$tgt" in
              /nix/*) cls=hm ;;
              "$HOME/.local/share/uv"*) cls="uv-lane" ;;
              "$HOME/.local/share/claude"*) cls="app-launcher" ;;
              /Applications/*) cls=app ;;
              broken) cls="broken-link" ;;
              *) cls="other-link" ;;
            esac
          else
            cls=unmanaged
          fi
          decision="''${decision_row[$n]:-unadjudicated}"
          [ "$decision" != "unadjudicated" ] || unadjudicated=$((unadjudicated + 1))
          printf 'family=local-bin\tentry=%s\tclass=%s\tdecision=%s\n' "$n" "$cls" "$decision"
        done
        printf 'family=summary\tshadows=%s\tmismatches=%s\tunadjudicated=%s\n' "$shadows" "$mismatches" "$unadjudicated"
        [ $((shadows + mismatches)) = 0 ] || result=drift
      }

      # Launchd census: declared plists (HM/Forge grammar) reconciled with the live launchctl table — loaded state, pid, last exit, triage class.
      # shellcheck disable=SC2329  # dispatched through the catalog handler row
      lens_launchd() {
        local declared=0 loaded=0 not_loaded=0 unmanaged=0 nonzero=0 owned_not_loaded=0
        # Tab-split keeps labels with spaces intact (launchctl is TSV); a host without launchd yields an empty census instead of a pipefail kill.
        { /bin/launchctl list 2>/dev/null || true; } | awk -F '\t' 'NR > 1 {print $3 "\t" $1 "\t" $2}' >"$work/observed"
        # Triage rows load once; classify is a pure prefix scan in row order.
        local triage_rows r
        mapfile -t triage_rows < <(jq -r '.[] | [.prefix, .class, .note] | @tsv' '${launchdTriage}')
        classify() { # $1=label -> class<TAB>note
          for r in "''${triage_rows[@]}"; do
            if [[ "$1" == "''${r%%$'\t'*}"* ]]; then
              printf '%s\n' "''${r#*$'\t'}"
              return 0
            fi
          done
          printf 'unclassified\tno triage row\n'
        }
        # Exact label match: a label is data, never a regex.
        obs() { awk -F '\t' -v l="$1" '$1 == l {print; exit}' "$work/observed" || true; }
        local plist label o opid ostatus cls note
        # Declared lane: every plist in the user LaunchAgents dir.
        for plist in "$HOME/Library/LaunchAgents"/*.plist; do
          [ -e "$plist" ] || continue
          label="$(/usr/bin/plutil -extract Label raw "$plist" 2>/dev/null || true)"
          [ -n "$label" ] || continue
          declared=$((declared + 1))
          o="$(obs "$label")"
          IFS=$'\t' read -r _ opid ostatus < <(printf '%s\n' "$o") || true
          IFS=$'\t' read -r cls note < <(classify "$label")
          if [ -n "$o" ]; then
            loaded=$((loaded + 1))
            [ "''${ostatus:-0}" = 0 ] || [ "''${ostatus:-0}" = "-" ] || nonzero=$((nonzero + 1))
            printf 'family=declared\tlabel=%s\tclass=%s\tloaded=1\tpid=%s\tlast_exit=%s\tnote=%s\n' \
              "$label" "$cls" "''${opid:--}" "''${ostatus:--}" "$note"
          else
            not_loaded=$((not_loaded + 1))
            # Only an estate-declared agent failing to load is estate drift; a vendor plist is observed, never owned.
            if [ "$cls" = forge ]; then owned_not_loaded=$((owned_not_loaded + 1)); fi
            printf 'family=declared\tlabel=%s\tclass=%s\tloaded=0\tpid=-\tlast_exit=-\tnote=%s\n' "$label" "$cls" "$note"
          fi
          printf '%s\n' "$label" >>"$work/declared"
        done
        # Observed lane: live labels with no declared plist. Apple system rows and per-app transient rows stay out of the census.
        while IFS=$'\t' read -r label opid ostatus; do
          case "$label" in
            com.apple.* | application.* | *.anonymous.* | PID | "") continue ;;
          esac
          ! grep -qxF "$label" "$work/declared" 2>/dev/null || continue
          unmanaged=$((unmanaged + 1))
          [ "''${ostatus:-0}" = 0 ] || nonzero=$((nonzero + 1))
          IFS=$'\t' read -r cls note < <(classify "$label")
          printf 'family=live-only\tlabel=%s\tclass=%s\tloaded=1\tpid=%s\tlast_exit=%s\tnote=%s\n' \
            "$label" "$cls" "''${opid:--}" "''${ostatus:--}" "$note"
        done <"$work/observed"
        printf 'family=summary\tdeclared=%s\tloaded=%s\tnot_loaded=%s\towned_not_loaded=%s\tlive_only=%s\tnonzero_exit=%s\n' \
          "$declared" "$loaded" "$not_loaded" "$owned_not_loaded" "$unmanaged" "$nonzero"
        [ "$owned_not_loaded" = 0 ] || result=drift
      }

      # Parity rail: generation home-files vs live $HOME (store-linked, staged-equal, missing, drifted), broken store links, HM gc-root singleton.
      # shellcheck disable=SC2329  # dispatched through the catalog handler row
      lens_parity() {
        # HM rides nix-darwin: the generation resolves through the gc root, not a nix profile.
        local gen hf ok=0 staged=0 missing=0 drift=0 broken=0 rel tgt l gcroots
        gen="$(readlink -f "$HOME/.local/state/home-manager/gcroots/current-home" 2>/dev/null || true)"
        hf="$gen/home-files"
        if [ ! -d "$hf" ]; then
          printf 'family=generation\tstate=missing\tpath=%s\n' "$hf"
          result=drift
          return 0
        fi
        while IFS= read -r -d "" f; do
          rel="''${f#"$hf"/}"
          tgt="$HOME/$rel"
          if [ -L "$tgt" ] && [ "$(readlink -f "$tgt" 2>/dev/null || true)" = "$(readlink -f "$f")" ]; then
            ok=$((ok + 1))
          elif [ -f "$tgt" ] && cmp -s "$tgt" "$f"; then
            # Writable-staged class: physical by design, content byte-equal.
            staged=$((staged + 1))
          elif [ ! -e "$tgt" ]; then
            missing=$((missing + 1))
            printf 'family=home-files\tstate=missing\tpath=%s\n' "$rel"
          else
            drift=$((drift + 1))
            printf 'family=home-files\tstate=drift\tpath=%s\n' "$rel"
          fi
        done < <(find -H "$hf" -mindepth 1 \( -type f -o -type l \) -print0 2>/dev/null)
        # Broken store links across managed roots: a vanished generation target is HM drift, distinct from the cleanup board's app-litter deadlinks.
        while IFS= read -r -d "" l; do
          tgt="$(readlink "$l" 2>/dev/null || true)"
          case "$tgt" in
            /nix/store/*)
              [ -e "$l" ] || {
                broken=$((broken + 1))
                printf 'family=store-links\tstate=broken\tpath=%s\ttarget=%s\n' "''${l#"$HOME"/}" "$tgt"
              }
              ;;
          esac
        done < <(find "$HOME/.config" "$HOME/.local/share" "$HOME/.local/state" "$HOME/.local/bin" "$HOME/.ssh" "$HOME/Library/LaunchAgents" -maxdepth 8 \( -path "$HOME/.local/share/Trash" \) -prune -o -type l -print0 2>/dev/null)
        gcroots="$(find "$HOME/.local/state/home-manager/gcroots" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l | tr -d ' ')"
        printf 'family=summary\tgeneration=%s\tok=%s\tstaged=%s\tmissing=%s\tdrift=%s\tbroken_links=%s\tgcroots=%s\n' \
          "''${gen##*/}" "$ok" "$staged" "$missing" "$drift" "$broken" "$gcroots"
        [ $((missing + drift + broken)) = 0 ] && [ "$gcroots" = 1 ] || result=drift
      }

      # Observation-only update-visibility board projected from existing receipts and local metadata; never drift-scored.
      # shellcheck disable=SC2329  # dispatched through the catalog handler row
      lens_updates() {
        local flake_lock oldest formulae casks
        tail_receipt() {
          if [ -f "$1" ]; then tail -1 "$1"; else echo "no-receipt"; fi
        }
        flake_lock="${tl.forgeRootExpr}/flake.lock"
        if [ -f "$flake_lock" ]; then
          oldest="$(jq -r '. as $l | [$l.nodes.root.inputs[] | $l.nodes[.].locked.lastModified? // empty] | min' "$flake_lock")"
          printf 'family=flake-inputs\toldest_input_age_days=%s\n' "$(((EPOCHSECONDS - oldest) / 86400))"
        else
          printf 'family=flake-inputs\tstate=absent\n'
        fi
        printf 'family=deploy\t%s\n' "$(tail_receipt "$HOME/Library/Logs/forge-redeploy.receipts.log")"
        if [ -x "$brew_bin" ]; then
          formulae="$(HOMEBREW_NO_AUTO_UPDATE=1 "$brew_bin" outdated --quiet 2>/dev/null | wc -l | tr -d ' ')"
          casks="$(HOMEBREW_NO_AUTO_UPDATE=1 "$brew_bin" outdated --cask --quiet 2>/dev/null | wc -l | tr -d ' ')"
          printf 'family=homebrew\toutdated_formulae=%s\toutdated_casks=%s\n' "$formulae" "$casks"
        else
          printf 'family=homebrew\tstate=absent\n'
        fi
        if command -v uv >/dev/null 2>&1; then
          printf 'family=uv-tools\tinstalled_tools=%s\n' "$(uv tool list 2>/dev/null | grep -c '^[a-z]' || true)"
        fi
      }

      "$handler" >"$work/rows"
      if [ "$as_json" = 1 ]; then
        # One typed row stream renders both surfaces: k=v tokens become JSON object fields, identical keys on both renders.
        jq -Rcs --arg ts "$ts" --arg lens "$lens" --arg result "$result" '{
          schema: "forge-doctor/v1", ts: $ts, lens: $lens, result: $result,
          rows: (split("\n") | map(select(length > 0) | split("\t")
            | map(select(test("^[^=]+=")) | capture("^(?<key>[^=]+)=(?<value>.*)$")) | from_entries))
        }' <"$work/rows"
      else
        cat "$work/rows"
      fi
      persist_receipt "$(printf 'ts=%s\tlens=%s\trows=%s\tresult=%s' \
        "$ts" "$lens" "$(grep -c . "$work/rows" || true)" "$result")"
      [ "$result" = ok ]
    '';
  };
}
