# Title         : cleanup.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/forge-tools/cleanup.nix
# ----------------------------------------------------------------------------
# Guarded cleanup rail over a typed row registry: plan (durable precheck receipt), apply (trash-first execution of plan-proved rows), sweep (the
# hourly orphan lane). Ad-hoc storage questions ride `dust -d 1 -n 20 -r ~` and each tool's own prune verb — never registry rows.
{
  config,
  lib,
  pkgs,
  tl,
}: let
  profileBin = "/etc/profiles/per-user/${config.home.username}/bin";

  # Registry as a tuple grammar: one row per line, projected to typed JSON through rowGrammar. Kinds — glob: trash matches under a root; age:
  # retention window (the age gate IS the live-session guard); deadlink: trash broken links only; codex-trust: prune stale trusted-project rows;
  # orphan: evidence-gated reap of agent-lane litter (ppid-1 tty-less only), `stop` naming the tool's own shutdown verb tried before signals.
  # A row earns its place only as genuine standing policy no first-party tool expresses.
  rowGrammar = {
    glob = ["root" "pattern" "depth"];
    age = ["root" "maxAgeDays" "pattern"];
    deadlink = ["root" "depth"];
    codex-trust = ["target"];
    orphan = ["match" "exclude" "minAgeSec" "stop"];
  };
  projectRows = registry:
    lib.concatLists (lib.mapAttrsToList
      (kind: rows:
        lib.mapAttrsToList
        (name: v: {inherit name kind;} // lib.listToAttrs (lib.zipListsWith lib.nameValuePair rowGrammar.${kind} (lib.toList v)))
        rows)
      registry);

  cleanupRows = pkgs.writeText "forge-cleanup-rows.json" (builtins.toJSON (projectRows {
    # Real removals with no owning tool: Office lock litter, Windows share droppings, agent-root .DS_Store.
    glob = {
      downloads-office-locks = ["Downloads" "~$*" 1];
      downloads-desktop-ini = ["Downloads" "desktop.ini" 1];
      documents-desktop-ini = ["Documents" "desktop.ini" 1];
      agent-root-ds-store-claude = [".claude" ".DS_Store" 0];
      agent-root-ds-store-codex = [".codex" ".DS_Store" 0];
    };
    # Broken links trashed, live links untouched; wezterm's dead mux listeners have no first-party sweep.
    deadlink.wezterm-dead-listeners = [".local/share/wezterm" 1];
    # Agent-root retention: material younger than the window is never a candidate, so a live session's working files stay untouchable. Codex CLI has
    # per-session delete/archive but no bulk age sweep; Claude Code's own sweep (settings cleanupPeriodDays) owns ~/.claude retention. The
    # forge-cleanup state row keeps this tool's own plan/apply/sweep receipts bounded.
    age = {
      codex-dot-tmp-retention = [".codex/.tmp" 7 ""];
      codex-tmp-retention = [".codex/tmp" 7 ""];
      codex-sessions-retention = [".codex/sessions" 30 ""];
      codex-archived-sessions-retention = [".codex/archived_sessions" 30 ""];
      codex-attachments-retention = [".codex/attachments" 14 ""];
      forge-cleanup-state-retention = [".local/state/forge-cleanup" 30 ""];
    };
    # Stale trusted-project rows (nonexistent paths, scratch-class prefixes) leave config.toml; durable repo rows stay.
    codex-trust.codex-trusted-projects = ".codex/config.toml";
    # The evidence-gated reap set: ppid-1 tty-less orphans only, kill classes as allowlisted rows. Rows with a `stop` verb try the tool's own
    # shutdown first; codex lanes detach by design, so only lanes far past every effort-tier deadline are litter.
    orphan = {
      biome-daemon-orphans = ["biome (lsp-proxy|__run_server)" "" 300 "biome stop"];
      lsp-server-orphans = ["(tsgo --lsp|bash-language-server|yaml-language-server|lua-language-server|(^|/)nixd|dts-lsp|postgrestools|roslyn-language-server|Microsoft[.]CodeAnalysis[.]LanguageServer|(^|/)ty server)" "" 300 ""];
      csharp-buildhost-orphans = ["(BuildHost-netcore|MSBuild[.]BuildHost[.]dll)" "" 600 "dotnet build-server shutdown"];
      forge-edit-nvim-orphans = ["nvim.*(forge-edit|forge-accept)" "" 1800 ""];
      codex-lane-orphans = ["(^|/)codex (exec|e) " "Codex[.]app" 14400 ""];
    };
  }));
in {
  forgeCleanup = tl.mkTool {
    name = "forge-cleanup";
    receiptName = "forge-orphan-sweep";
    inputs = [pkgs.coreutils pkgs.findutils pkgs.gawk pkgs.jq pkgs.flock pkgs.symlinks];
    text = ''
      rows_json='${cleanupRows}'
      state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/forge-cleanup"
      run_ts="''${ts//[-:]/}"
      work="$(mktemp -d)"
      trap 'rm -rf "$work" "''${prune_tmp:-}"' EXIT
      usage() { echo "usage: forge-cleanup plan | apply [plan-file] | sweep [--report-only]" >&2; exit 64; }
      verb="''${1:-}"; shift || true

      # Mutating verbs serialize on one lock: an apply racing the scheduled sweep must never double-trash a candidate or double-reap a pid.
      lock_file="''${FORGE_CLEANUP_LOCK:-$HOME/.cache/forge-cleanup.lock}"
      case "$verb" in
        apply | sweep)
          mkdir -p "''${lock_file%/*}"
          exec {cleanup_fd}>"$lock_file"
          flock -w 60 "$cleanup_fd" || {
            printf 'forge-cleanup: another mutating run holds %s\n' "$lock_file" >&2
            exit 75
          }
          ;;
      esac

      # Hard deny for the kill lane: session servers, GUI apps, credential daemons, and system trees are never reaped even on a class match.
      deny_re='/System/|/Applications/|zellij|[Ww]ez[Tt]erm|1[Pp]assword|[Cc]rashpad|loginwindow|(^|/)ssh'
      owner_uid="$(id -u)"
      # Trust rows on scratch/transient roots are litter by class; durable repo rows never match this and always survive the prune.
      scratch_re="^(/private/tmp/|/tmp/|$HOME/Downloads(/|$)|$HOME/Library/CloudStorage/)"

      # Canonical process rows carry both the mutable observations and a stable start stamp. The latter plus PID/PPID/PGID/UID/TTY/command defeats
      # PID reuse; elapsed and RSS are re-read at each signal boundary without pretending either mutable value is an identity key.
      process_rows() {
        ${tl.psBin} -axo pid=,ppid=,pgid=,uid=,tty=,etime=,rss=,state=,lstart=,command= 2>/dev/null | awk '
          function esecs(e,  a, n, d, hms) {
            d = 0
            if (index(e, "-") > 0) { split(e, a, "-"); d = a[1]; e = a[2] }
            n = split(e, hms, ":")
            if (n == 3) return ((d * 24 + hms[1]) * 60 + hms[2]) * 60 + hms[3]
            if (n == 2) return (d * 24 * 60 + hms[1]) * 60 + hms[2]
            return hms[1] + 0
          }
          NF >= 14 {
            cmd = ""
            for (i = 14; i <= NF; i++) cmd = cmd (i > 14 ? " " : "") $i
            started = $9 " " $10 " " $11 " " $12 " " $13
            printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", $1, $2, $3, $4, $5, esecs($6), $7, $8, started, cmd
          }'
      }

      # One live snapshot per run: every uid-owned process with its complete identity/observation tuple; launchd-managed pids drop out first, so a
      # sanctioned agent (KeepAlive services included) is never a candidate.
      proc_snapshot() {
        if [ ! -e "$work/procs" ]; then
          # launchd exclusion is a Darwin fact; on a systemd host the managed set is empty (user services carry a non-1 ppid and drop anyway).
          { /bin/launchctl list 2>/dev/null || true; } | awk 'NR > 1 && $1 ~ /^[0-9]+$/ {print $1}' >"$work/managed"
          process_rows | awk -F '\t' -v uid="$owner_uid" -v self="$$" '
            NR == FNR { managed[$1] = 1; next }
            $4 == uid && !($1 in managed) && $1 != self {
              print
            }
          ' "$work/managed" - >"$work/procs"
        fi
        cat "$work/procs"
      }

      # args: match exclude min-age. The census is the classic ppid-1 tty-less orphan proof; the deny lane always applies (every row is a kill
      # row). Zombies are already terminated and never enter the reap set.
      orphan_matches() {
        proc_snapshot | awk -F '\t' -v m="$1" -v x="$2" -v g="$3" -v d="$deny_re" '
          $8 !~ /^Z/ && $2 == 1 && $5 ~ /^\?\??$/ && $6 >= g && $10 ~ m &&
            (x == "" || $10 !~ x) && $10 !~ d { print }'
      }

      process_record() { process_rows | awk -F '\t' -v pid="$1" '$1 == pid {print}'; }

      # Stable identity fields must match exactly, the elapsed clock may only advance, and both mutable observations must remain well-formed.
      same_identity() { # expected current
        local ep epp eg eu et ea er es ez ec cp cpp cg cu ct ca cr cs cz cc
        IFS=$'\t' read -r ep epp eg eu et ea er es ez ec < <(printf '%s\n' "$1")
        IFS=$'\t' read -r cp cpp cg cu ct ca cr cs cz cc < <(printf '%s\n' "$2")
        [ "$ep" = "$cp" ] && [ "$epp" = "$cpp" ] && [ "$eg" = "$cg" ] && [ "$eu" = "$cu" ] && [ "$et" = "$ct" ] \
          && [ "$ez" = "$cz" ] && [ "$ec" = "$cc" ] && [[ "$ea" =~ ^[0-9]+$ ]] && [[ "$ca" =~ ^[0-9]+$ ]] \
          && [ "$ca" -ge "$ea" ] && [[ "$er" =~ ^[0-9]+$ ]] && [[ "$cr" =~ ^[0-9]+$ ]] && [ -n "$es" ] && [ -n "$cs" ]
      }

      record_admitted() { # record match exclude minage
        local pid ppid uid tty age rss state cmd
        IFS=$'\t' read -r pid ppid _ uid tty age rss state _ cmd < <(printf '%s\n' "$1")
        [ "$uid" = "$owner_uid" ] && [ "$pid" != "$$" ] && [[ "$age" =~ ^[0-9]+$ ]] && [ "$age" -ge "$4" ] \
          && [[ "$rss" =~ ^[0-9]+$ ]] && [[ "$state" != Z* ]] && [[ "$cmd" =~ $2 ]] \
          && { [ -z "$3" ] || [[ ! "$cmd" =~ $3 ]]; } && [ "$ppid" = 1 ] && [[ "$tty" =~ ^\?\??$ ]] \
          && [[ ! "$cmd" =~ $deny_re ]]
      }

      revalidate_candidate() { # expected match exclude minage
        local pid _ current state
        IFS=$'\t' read -r pid _ < <(printf '%s\n' "$1")
        current="$(process_record "$pid")"
        [ -n "$current" ] || return 1
        IFS=$'\t' read -r _ _ _ _ _ _ _ state _ < <(printf '%s\n' "$current")
        [[ "$state" != Z* ]] || return 1
        same_identity "$1" "$current" && record_admitted "$current" "$2" "$3" "$4" || return 2
      }

      target_terminated() { # pid
        local record state
        record="$(process_record "$1")"
        [ -n "$record" ] || return 0
        IFS=$'\t' read -r _ _ _ _ _ _ _ state _ < <(printf '%s\n' "$record")
        [[ "$state" == Z* ]]
      }

      # Row-declared graceful shutdown: the tool's own verb, resolved through the per-user profile first; an unresolvable binary skips straight to
      # signals. Bounded so a wedged daemon cannot stall the sweep.
      graceful_stop() { # stop-command string
        local -a argv
        read -ra argv < <(printf '%s\n' "$1")
        if [ -x "${profileBin}/''${argv[0]}" ]; then
          argv[0]="${profileBin}/''${argv[0]}"
        elif ! command -v "''${argv[0]}" >/dev/null 2>&1; then
          return 1
        fi
        timeout -k 2 10 "''${argv[@]}" >/dev/null 2>&1 || true
      }

      # Both signal boundaries refresh identity, and KILL fires only when the graceful verb and TERM both left the target alive.
      reap_pid() { # expected match exclude minage stop
        local expected="$1" stop="$5" pid revalidate_rc
        IFS=$'\t' read -r pid _ < <(printf '%s\n' "$expected")
        revalidate_rc=0
        revalidate_candidate "$expected" "$2" "$3" "$4" || revalidate_rc=$?
        [ "$revalidate_rc" = 0 ] || return "$revalidate_rc"
        if [ -n "$stop" ] && graceful_stop "$stop"; then
          for _ in 1 2 3; do
            target_terminated "$pid" && return 0
            sleep 1
          done
          revalidate_rc=0
          revalidate_candidate "$expected" "$2" "$3" "$4" || revalidate_rc=$?
          [ "$revalidate_rc" = 0 ] || return "$revalidate_rc"
        fi
        if ! kill -TERM -- "$pid" 2>/dev/null; then
          target_terminated "$pid" && return 0
          return 2
        fi
        for _ in 1 2 3; do
          target_terminated "$pid" && return 0
          sleep 1
        done
        revalidate_rc=0
        revalidate_candidate "$expected" "$2" "$3" "$4" || revalidate_rc=$?
        [ "$revalidate_rc" = 0 ] || return "$revalidate_rc"
        if ! kill -KILL -- "$pid" 2>/dev/null; then
          target_terminated "$pid" && return 0
          return 2
        fi
        for _ in 1 2; do
          target_terminated "$pid" && return 0
          sleep 1
        done
        return 2
      }

      # Shared reap/report emitter for apply and sweep: $6 is the behavior this run applies (kill|report).
      reap_matches() { # name match exclude minage stop act
        reaped=0 failed_reaps=0
        while IFS=$'\t' read -r opid oppid opgid ouid otty oage orss ostate ostarted ocmd; do
          if [ "$6" = kill ]; then
            process_identity="$(printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s' \
              "$opid" "$oppid" "$opgid" "$ouid" "$otty" "$oage" "$orss" "$ostate" "$ostarted" "$ocmd")"
            if reap_pid "$process_identity" "$2" "$3" "$4" "$5"; then
              reaped=$((reaped + 1))
              printf '%s\tkilled\tpid=%s\tppid=%s\tpgid=%s\tuid=%s\ttty=%s\tage_s=%s\trss_kb=%s\tstarted=%s\tcmd=%.140s\n' \
                "$1" "$opid" "$oppid" "$opgid" "$ouid" "$otty" "$oage" "$orss" "$ostarted" "$ocmd"
            else
              reap_rc=$?
              if [ "$reap_rc" = 1 ]; then
                printf '%s\tgone\tpid=%s\n' "$1" "$opid"
              else
                failed_reaps=$((failed_reaps + 1))
                printf '%s\tfailed\tpid=%s\n' "$1" "$opid"
              fi
            fi
          else
            printf '%s\treport\tpid=%s\tppid=%s\tpgid=%s\tuid=%s\ttty=%s\tage_s=%s\trss_kb=%s\tstarted=%s\tcmd=%.140s\n' \
              "$1" "$opid" "$oppid" "$opgid" "$ouid" "$otty" "$oage" "$orss" "$ostarted" "$ocmd"
          fi
        done < <(orphan_matches "$2" "$3" "$4")
      }

      # One jq projection per row: every field lands in one read. Unit-separator delimited: tab is IFS whitespace and read would collapse empty
      # fields. The row pipes in (never <<<): bash-5.3 backs sub-64K here-strings with a self-held pipe that deadlocks under buffer exhaustion.
      row_fields() {
        printf '%s\n' "$1" | jq -r '[.name, .kind, (.target // ""), (.root // ""), (.pattern // ""), (.match // ""), (.exclude // ""), (.minAgeSec // 0 | tostring), (.depth // 0 | tostring), (.maxAgeDays // 0 | tostring), (.stop // "")] | join("\u001f")'
      }

      # One NUL-emitting candidate enumerator per find-shaped kind; detect and apply consume the same predicates, so lane drift is unspellable.
      # symlinks(1) owns dangling detection (depth 1 = the root dir only, otherwise recursive); the adapter keeps the NUL grammar and trash-first apply.
      candidates() { # kind root pattern depth maxAgeDays
        local -a args=()
        if [ "$1" = deadlink ]; then
          [ "$4" = 1 ] || args+=(-r)
          { symlinks ''${args[0]+"''${args[@]}"} "$2" 2>/dev/null || true; } \
            | gawk '/^dangling: / {sub(/^dangling: /, ""); sub(/ -> .*/, ""); printf "%s%c", $0, 0}'
          return 0
        fi
        [ "$4" = 0 ] || args+=(-maxdepth "$4")
        case "$1" in
          glob) args+=(-mindepth 1 -name "$3" -prune) ;;
          age)
            args+=(-mindepth 1 -type f)
            [ -z "$3" ] || args+=(-name "$3")
            args+=(-mtime "+$5")
            ;;
        esac
        # Partial traversal (an unreadable subtree) keeps its yield; find's rc is not evidence and must not kill the detector under pipefail.
        find "$2" "''${args[@]}" -print0 2>/dev/null || true
      }
      count0() { tr -cd '\0' | wc -c | tr -d ' '; }
      # -r: empty stdin must never run du against the CWD; du's rc on a vanished or unreadable entry is noise the awk fold absorbs.
      sum_kb0() { { xargs -0 -r du -sk 2>/dev/null || true; } | awk '{s += $1} END {print s + 0}'; }

      # Stale trusted-project extraction: a row is stale when its path no longer exists or sits on a scratch-class prefix.
      codex_stale_projects() {
        local p
        while IFS= read -r p; do
          if [ ! -e "$p" ] || [[ "$p" =~ $scratch_re ]]; then printf '%s\n' "$p"; fi
        done < <(gawk 'match($0, /^\[projects\."(.*)"\]$/, m) {print m[1]}' "$1")
      }

      # One detector owns every row kind; plan and apply both consume it, so apply never acts on a state the detector cannot reproduce live.
      detect_row() {
        local row="$1" name kind state count kb action safe detail target root pattern match exclude minage opid orss pidlist depth maxage cfg
        IFS=$'\x1f' read -r name kind target root pattern match exclude minage depth maxage _ < <(row_fields "$row")
        state=clean count=0 kb=0 action=none safe=true detail=-
        case "$kind" in
          glob | age | deadlink)
            root="$HOME/$root"
            if [ -d "$root" ]; then
              count="$(candidates "$kind" "$root" "$pattern" "$depth" "$maxage" | count0)"
              if [ "$count" -gt 0 ]; then
                state=litter
                case "$kind" in
                  glob) action=trash ;;
                  age) action=trash-aged detail="age>''${maxage}d" ;;
                  deadlink) action="trash-links" ;;
                esac
                [ "$kind" = deadlink ] || kb="$(candidates "$kind" "$root" "$pattern" "$depth" "$maxage" | sum_kb0)"
              fi
            fi
            ;;
          codex-trust)
            cfg="$HOME/$target"
            if [ -f "$cfg" ]; then
              detail="$(codex_stale_projects "$cfg" | paste -sd' ' -)"
              count="$(codex_stale_projects "$cfg" | wc -l | tr -d ' ')"
              if [ "$count" -gt 0 ]; then
                state=litter action=prune-trust detail="stale: $detail"
              else
                detail=-
              fi
            fi
            ;;
          orphan)
            pidlist=""
            while IFS=$'\t' read -r opid _ _ _ _ _ orss _ _ _; do
              count=$((count + 1))
              kb=$((kb + orss))
              pidlist="$pidlist,$opid"
            done < <(orphan_matches "$match" "$exclude" "$minage")
            if [ "$count" -gt 0 ]; then
              state=litter action=kill detail="pids=''${pidlist#,}"
            fi
            ;;
        esac
        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$name" "$kind" "$state" "$count" "$kb" "$action" "$safe" "$detail"
      }

      trash() {
        mkdir -p "$HOME/.Trash"
        local dest="$HOME/.Trash/''${1##*/}.forge-cleanup.$run_ts"
        # Basename collisions from deep-tree prunes get a unique suffix so no candidate silently stays behind.
        while [ -e "$dest" ] || [ -L "$dest" ]; do dest="$dest.$SRANDOM"; done
        mv -- "$1" "$dest"
      }

      cmd_plan() {
        [ "$#" -eq 0 ] || usage
        mkdir -p "$state_dir"
        plan_file="$state_dir/plan-$run_ts.tsv"
        {
          printf '# forge-cleanup plan\tts=%s\thome=%s\n' "$run_ts" "$HOME"
          printf '# name\tkind\tstate\tcount\tkb\taction\tsafe\tdetail\n'
          while IFS= read -r row; do detect_row "$row"; done < <(jq -c '.[]' "$rows_json")
        } | tee "$plan_file"
        persist_receipt "$(printf 'ts=%s\tverb=plan\tfindings=%s\treceipt=%s\tresult=ok' \
          "$ts" "$(grep -cv '^#' "$plan_file" || true)" "$plan_file")"
      }

      cmd_apply() {
        [ "$#" -le 1 ] || usage
        mkdir -p "$state_dir"
        plan_file="''${1:-$(find "$state_dir" -maxdepth 1 -name 'plan-*.tsv' 2>/dev/null | sort | tail -1)}"
        if [ -z "$plan_file" ] || [ ! -f "$plan_file" ]; then
          echo "forge-cleanup: no plan receipt; run forge-cleanup plan first" >&2
          exit 66
        fi
        apply_file="$state_dir/apply-$run_ts.tsv"
        {
          printf '# forge-cleanup apply\tts=%s\tplan=%s\n' "$run_ts" "$plan_file"
          while IFS=$'\t' read -r name _kind state _count _kb action safe _detail; do
            case "$name" in '#'* | "") continue ;; esac
            if [ "$safe" != true ] || [ "$state" != litter ]; then
              printf '%s\taction=none\toutcome=skipped-%s\n' "$name" "$state"
              continue
            fi
            row="$(jq -c --arg n "$name" '.[] | select(.name == $n)' "$rows_json")"
            # A plan row absent from the live registry (stale plan across a generation change) is a typed skip, never an errexit mid-apply.
            if [ -z "$row" ]; then
              printf '%s\taction=none\toutcome=skipped-unknown-row\n' "$name"
              continue
            fi
            IFS=$'\x1f' read -r _ row_kind row_target row_root row_pattern row_match row_exclude row_minage row_depth row_maxage row_stop < <(row_fields "$row")
            # Re-verify at act time: a row that drifted since plan is skipped.
            IFS=$'\t' read -r _ _ fresh_state _ _ fresh_action _ _ < <(detect_row "$row")
            if [ "$fresh_state" != litter ]; then
              printf '%s\taction=none\toutcome=drifted-%s\n' "$name" "$fresh_state"
              continue
            fi
            case "$fresh_action" in
              trash | trash-aged | trash-links)
                moved=0
                while IFS= read -r -d "" candidate; do
                  # A candidate can vanish between enumeration and act (a parent moved first); absence is done, never an errexit.
                  { [ -e "$candidate" ] || [ -L "$candidate" ]; } || continue
                  trash "$candidate"
                  moved=$((moved + 1))
                done < <(candidates "$row_kind" "$HOME/$row_root" "$row_pattern" "$row_depth" "$row_maxage")
                if [ "$row_kind" = age ]; then
                  # Pruned trees leave empty directory skeletons (file-grain candidates); -delete cascades depth-first and only removes empty dirs.
                  find "$HOME/$row_root" -mindepth 1 -type d -empty -delete 2>/dev/null || true
                fi
                printf '%s\taction=%s\toutcome=applied\tcount=%s\n' "$name" "$fresh_action" "$moved"
                ;;
              prune-trust)
                cfg="$HOME/$row_target"
                stale_list="$work/codex-stale"
                codex_stale_projects "$cfg" >"$stale_list"
                if [ -s "$stale_list" ]; then
                  # Backup rides the trash rail like every other mutation; the rename temp lives beside its target and dies with the trap.
                  prune_tmp="$cfg.forge-prune"
                  cp -p "$cfg" "$work/config.toml.pre-prune" && trash "$work/config.toml.pre-prune"
                  gawk '
                    NR == FNR { stale[$0] = 1; next }
                    {
                      if (match($0, /^\[projects\."(.*)"\]$/, m)) drop = (m[1] in stale)
                      else if ($0 ~ /^\[/) drop = 0
                      if (!drop) print
                    }
                  ' "$stale_list" "$cfg" >"$prune_tmp" && mv "$prune_tmp" "$cfg"
                  printf '%s\taction=prune-trust\toutcome=applied\tcount=%s\n' "$name" "$(wc -l <"$stale_list" | tr -d ' ')"
                else
                  printf '%s\taction=prune-trust\toutcome=drifted-clean\n' "$name"
                fi
                ;;
              kill)
                reap_matches "$name" "$row_match" "$row_exclude" "$row_minage" "$row_stop" kill
                printf '%s\taction=kill\toutcome=applied\tcount=%s\tfailed=%s\n' "$name" "$reaped" "$failed_reaps"
                ;;
              *)
                printf '%s\taction=%s\toutcome=unknown-action\n' "$name" "$fresh_action"
                ;;
            esac
          done <"$plan_file"
        } | tee "$apply_file"
        apply_failed="$(grep -c $'\tfailed\tpid=' "$apply_file" || true)"
        apply_result=ok
        [ "$apply_failed" = 0 ] || apply_result=partial
        persist_receipt "$(printf 'ts=%s\tverb=apply\tapplied=%s\tfailed=%s\tplan=%s\treceipt=%s\tresult=%s' \
          "$ts" "$(grep -c 'outcome=applied' "$apply_file" || true)" "$apply_failed" "$plan_file" "$apply_file" "$apply_result")"
        [ "$apply_result" = ok ]
      }

      # Orphan-only lane for the scheduled agent: fresh detection each run, evidence-gated reaping; per-pid receipt plus one summary line.
      cmd_sweep() {
        report_only=0
        case "''${1:-}" in
          "") ;;
          --report-only) report_only=1 ;;
          *) usage ;;
        esac
        [ "$#" -le 1 ] || usage
        mkdir -p "$state_dir"
        sweep_file="$state_dir/sweep-$run_ts.tsv"
        {
          printf '# forge-cleanup sweep\tts=%s\treport_only=%s\n' "$run_ts" "$report_only"
          while IFS= read -r row; do
            # Full-width read: a truncated read folds every trailing field into its last variable, silently degrading kill rows to report.
            IFS=$'\x1f' read -r name kind _ _ _ match exclude minage _ _ stop < <(row_fields "$row")
            [ "$kind" = orphan ] || continue
            act="kill"
            [ "$report_only" = 0 ] || act=report
            reap_matches "$name" "$match" "$exclude" "$minage" "$stop" "$act"
          done < <(jq -c '.[]' "$rows_json")
        } >"$sweep_file"
        cat "$sweep_file"
        read -r killed reported gone failed < <(awk -F '\t' 'NR > 1 {c[$2]++} END {printf "%d %d %d %d\n", c["killed"] + 0, c["report"] + 0, c["gone"] + 0, c["failed"] + 0}' "$sweep_file")
        sweep_result=ok
        [ "$failed" = 0 ] || sweep_result=partial
        persist_receipt "$(printf 'ts=%s\tverb=sweep\tkilled=%s\treported=%s\tgone=%s\tfailed=%s\treport_only=%s\treceipt=%s\tresult=%s' \
          "$ts" "$killed" "$reported" "$gone" "$failed" "$report_only" "$sweep_file" "$sweep_result")"
        [ "$sweep_result" = ok ]
      }

      case "$verb" in
        plan) cmd_plan "$@" ;;
        apply) cmd_apply "$@" ;;
        sweep) cmd_sweep "$@" ;;
        *) usage ;;
      esac
    '';
  };
}
