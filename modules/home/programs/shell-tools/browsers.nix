# Title         : browsers.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/browsers.nix
# ----------------------------------------------------------------------------
# Register rail owner: one row grammar projected to fzf browse commands, Television durable channels, XDG register JSON, and zsh completions.
# Previews are read-only evidence; every browse run emits one typed receipt.
{
  config,
  host,
  lib,
  pkgs,
  ...
}: let
  inherit (config.forge.theme) palette;
  # Shared dual-receipt emit fold (receipts.nix) + the F01 attention vocabulary (attention.nix): urgency ladder, kv parser, spine, alert rows.
  receiptsFold = import ./receipts.nix;
  attention = import ./attention.nix {sshHosts = config.forge.ssh.hosts;};
  profileBin = "/etc/profiles/per-user/${config.home.username}/bin";
  fleet = import ./mcp-fleet.nix {
    inherit profileBin;
    homeDir = config.home.homeDirectory;
    sshBin = "${pkgs.openssh}/bin/ssh";
  };

  # --- [NAME_POLICY_ROWS]
  # One repo/workroot identity per row — [source slug consumers previous?]; display derives from slug; slug claims (current + retired `previous`,
  # which keep receipt-partition history across renames) collide at eval.
  naming =
    map (t: {
      source = lib.elemAt t 0;
      slug = lib.elemAt t 1;
      display = "[${lib.toUpper (lib.elemAt t 1)}]";
      domain = "estate-repo";
      collision = "reject";
      previous = lib.flatten (lib.drop 3 t);
      consumers = lib.elemAt t 2;
    }) [
      ["Parametric_Forge" "forge" ["television-channel-prefix" "receipt-log-prefix" "launchd-agent-name-prefix" "wezterm-workspace-name" "wezterm-workspace-warm" "zellij-session-name"]]
      ["Rasm" "rasm" ["zellij-session-name"]]
      ["Maghz" "maghz" ["tunnel-receipt-partition" "zellij-session-name"]]
    ];
  channelPrefix = (lib.findFirst (r: lib.elem "television-channel-prefix" r.consumers) {slug = "forge";} naming).slug;
  slugClaims = lib.concatMap (r: [r.slug] ++ r.previous) naming;
  slugConflicts = lib.attrNames (lib.filterAttrs (_: c: c > 1) (lib.foldl' (acc: s: acc // {${s} = (acc.${s} or 0) + 1;}) {} slugClaims));

  # --- [RECEIPT_SOURCE_REGISTER]
  # Declared receipt emitters at $HOME-relative paths that may not exist yet; tuple grammar "kind[|stem[|emitter]]" defaults stem=kind and
  # emitter=forge-<stem>; grain is kv (TSV k=v) unless a literal row says json (JSONL). Query plane, audit verb, and push bus dispatch on the rows
  # — an unregistered emitter is invisible to all three; --audit flags it.
  osPath = darwin: linux:
    if host.os == "darwin"
    then darwin
    else linux;
  kvSource = s: let
    p = lib.splitString "|" s ++ ["" ""];
    at = i: d: lib.findFirst (v: v != "") d [(lib.elemAt p i)];
    stem = at 1 (lib.head p);
  in {
    kind = lib.head p;
    path = "Library/Logs/forge-${stem}.receipts.log";
    emitter = at 2 "forge-${stem}";
  };
  receiptSources =
    map (r: {grain = "kv";} // r)
    (map kvSource ["redeploy" "maintenance|nix-maintenance" "drift|nix-drift" "orphan-sweep" "activation-sweep" "accept" "browse" "workspace" "wezterm||wezterm command deck" "zellij" "mcp" "agents||forge-agents collector" "terminal-accept||forge-terminal-accept.sh" "path-doctor" "launchd-doctor" "parity" "update-board" "vscode" "fonts||forge-project-fonts" "theme-proof"]
      ++ [
        # rsync-mv emits JSONL only, at a per-OS path (rsync.nix).
        {
          kind = "rsync-mv";
          path = osPath "Library/Logs/forge-rsync-mv.receipts.jsonl" ".local/state/parametric-forge/rsync-mv.receipts.jsonl";
          emitter = "rsync-mv.sh";
          grain = "json";
        }
      ]
      # Tunnel and mount rows derive from the ssh host registry: a new VPS or mount row appears here untouched; paths follow each supervisor's
      # per-OS write target (launchd logs on Darwin, systemd state on Linux).
      ++ lib.mapAttrsToList (name: _: {
        kind = "tunnel-${name}";
        path = osPath "Library/Logs/forge-${name}-vps-tunnel.receipts.log" ".local/state/forge-tunnels/${name}-vps-tunnel.receipts.log";
        emitter = "${name}-vps-tunnel supervisor";
      })
      config.forge.ssh.hosts
      ++ lib.concatLists (lib.mapAttrsToList (
          name: h:
            map (m: {
              kind = "mount-${name}-${m.name}";
              path = osPath "Library/Logs/forge-${name}-mount-${m.name}.receipts.log" ".local/state/forge-mounts/${name}-mount-${m.name}.receipts.log";
              emitter = "forge-vps-mount supervisor";
            }) (h.mounts or [])
        )
        config.forge.ssh.hosts));

  # --- [REGISTER_JSON_PROJECTIONS]
  # MCP rows sanitize at the seam — endpoint basename, key NAMES, pin, doctor family — never argv, token custody paths, or values; `sub` projects
  # an optional sub-attrset onto its closed key family, null when absent.
  sub = keys: v:
    if v == null
    then null
    else keys // builtins.intersectAttrs keys v;
  mcpRegister =
    map (r: {
      inherit (r) name transport probe;
      endpoint = r.url or (baseNameOf r.command);
      envKeys = r.envKeys or [];
      clients = r.clients or ["claude" "codex"];
      assertLevel = r.assertLevel or "full";
      launcher = sub (lib.genAttrs ["pkg" "version"] (_: null)) (r.launcher or null);
      codex = r.codex or null;
      doctor = sub (lib.genAttrs ["launchdLabel" "port"] (_: null) // {execs = [];}) (r.doctor or null);
    })
    fleet;
  registerJson = domain: rows: pkgs.writeText "forge-register-${domain}.json" (builtins.toJSON rows);
  registers = lib.mapAttrs registerJson {
    inherit naming;
    aliases = config.forge.registers.aliases;
    chords = config.forge.chords.register or [];
    mcp = mcpRegister;
    receipts = receiptSources;
  };

  # --- [BROWSE_CATALOG]
  # One tuple per domain — [tsvProjection desc binds?]; label and json derive from the name; the receipts domain delegates to forge-receipts.
  catalogRows =
    lib.mapAttrs (d: t:
      {
        json = registers.${d};
        label = "[${lib.toUpper d}]";
        tsv = lib.elemAt t 0;
        desc = lib.elemAt t 1;
      }
      // lib.optionalAttrs (lib.length t > 2) {binds = lib.elemAt t 2;}) {
      aliases = [''.[] | [.alias, .category, .risk, .expansion] | @tsv'' "shell alias register"];
      chords = [''.[] | [.chord_id, .mods, .key, .label] | @tsv'' "chord register across consumers"];
      mcp = [''.[] | [.name, .transport, (.launcher.version // "-"), .probe] | @tsv'' "MCP fleet rows" ["ctrl-d:execute(${profileBin}/forge-mcp doctor | ${pkgs.less}/bin/less -R)"]];
      naming = [''.[] | [.slug, .source, .display, .domain] | @tsv'' "name policy rows"];
    }
    // {
      receipts = {
        delegate = "receipts";
        label = "[RECEIPTS]";
        desc = "typed receipt rows across estate logs";
      };
    };
  catalogJson = pkgs.writeText "forge-browse-catalog.json" (builtins.toJSON catalogRows);

  # Per-browser fzf theme: the theme owner's shared fzf vocabulary rides every generated command (global fzf options stay theme-only in fzf.nix).
  fzfColorRows = config.forge.theme.projections.fzfColorRows;
  fzfBaseArgs = fzfColorRows ++ ["--border=sharp" "--layout=reverse" "--info=right" "--highlight-line" "--prompt=❯ " "--pointer=❯"];
  # Bash array literal injected into each generated script; consumers expand "''${fzf_base[@]}" so every browser carries the theme per command.
  fzfArgsBash = "fzf_base=(\n${lib.concatMapStringsSep "\n" (a: "        ${lib.escapeShellArg a}") fzfBaseArgs}\n      )";

  # --- [RECEIPT_VERB_ROWS]
  # Canned [desc sql] projections over the normalized event spine (fixed columns per attention.spineColumnsSql) so every verb binds on any
  # corpus thinness; kind-specific raw fields extract from JSON text. A new analytic is one row.
  receiptVerbs =
    lib.mapAttrs (_: t: {
      desc = lib.elemAt t 0;
      sql = lib.elemAt t 1;
    }) {
      kinds = ["corpus census: rows, span, failure count per kind" "SELECT kind, count(*) AS n, min(ts) AS first_ts, max(ts) AS last_ts, count(*) FILTER (urgency = 'high') AS failures FROM receipts GROUP BY kind ORDER BY n DESC"];
      failures = ["failure-urgency rows, newest first" "SELECT ts, kind, COALESCE(result, state, status, '-') AS outcome, COALESCE(surface, '-') AS surface FROM receipts WHERE urgency = 'high' ORDER BY ts DESC LIMIT 100"];
      redeploy-trend = ["per-day redeploy runs, build seconds, failures" "SELECT substr(ts, 1, 10) AS day, count(*) AS runs, round(avg(TRY_CAST(json_extract_string(raw, '$.build_s') AS DOUBLE)), 1) AS avg_build_s, round(max(TRY_CAST(json_extract_string(raw, '$.build_s') AS DOUBLE)), 1) AS max_build_s, count(*) FILTER (COALESCE(result, 'ok') != 'ok') AS failures FROM receipts WHERE kind = 'redeploy' GROUP BY day ORDER BY day DESC LIMIT 30"];
      tunnel-flaps = ["per-day tunnel state transitions" "SELECT substr(ts, 1, 10) AS day, kind, count(*) FILTER (prev IS NOT NULL AND state IS DISTINCT FROM prev) AS flaps, count(*) FILTER (state != 'up') AS down_rows FROM (SELECT ts, kind, state, LAG(state) OVER (PARTITION BY kind ORDER BY ts) AS prev FROM receipts WHERE kind LIKE 'tunnel-%') GROUP BY day, kind ORDER BY day DESC, kind LIMIT 30"];
      accept-trend = ["acceptance pass/warn/fail per run" "SELECT ts, TRY_CAST(regexp_extract(json_extract_string(raw, '$.summary'), 'pass:(\\d+)', 1) AS INTEGER) AS pass, TRY_CAST(regexp_extract(json_extract_string(raw, '$.summary'), 'warn:(\\d+)', 1) AS INTEGER) AS warn, TRY_CAST(regexp_extract(json_extract_string(raw, '$.summary'), 'fail:(\\d+)', 1) AS INTEGER) AS fail, result FROM receipts WHERE kind = 'accept' ORDER BY ts DESC LIMIT 30"];
      timeline = ["unified estate chronology: receipts + attention rows" "SELECT ts, kind, COALESCE(source, kind) AS source, urgency, COALESCE(event, verb, json_extract_string(raw, '$.mode'), json_extract_string(raw, '$.action'), '-') AS what, COALESCE(result, state, status, '-') AS outcome, COALESCE(surface, '-') AS surface FROM receipts ORDER BY ts DESC LIMIT 200"];
      session-replay = ["forensic chronology of the latest attention session: events + receipts on one join key" "SELECT ts, kind, COALESCE(event, verb, '-') AS what, COALESCE(result, state, status, '-') AS outcome, urgency, COALESCE(surface, '-') AS surface FROM receipts WHERE session_id = (SELECT session_id FROM receipts WHERE kind = 'attention' AND COALESCE(session_id, '-') != '-' ORDER BY ts DESC LIMIT 1) ORDER BY ts DESC LIMIT 200"];
    };
  verbsJson = pkgs.writeText "forge-receipts-verbs.json" (builtins.toJSON receiptVerbs);

  # --- [FORGE_RECEIPTS]
  forgeReceipts = pkgs.writeShellApplication {
    name = "forge-receipts";
    runtimeInputs = [pkgs.coreutils pkgs.jq pkgs.fzf pkgs.gawk pkgs.findutils pkgs.duckdb];
    text = ''
      # Unified receipts plane over registry-declared sources (kv TSV + JSONL): browse/table rows, an ad-hoc SQL door plus canned verbs over the
      # normalized spine (DuckDB), a registry-vs-disk audit, and a live failure push bus; the attention feed folds in as kind=attention rows.
      registry="${registers.receipts}"
      verbs="${verbsJson}"
      self="''${BASH_SOURCE[0]}"
      zellij_bin="${profileBin}/zellij"
      attention_feed="''${FORGE_ATTENTION_FEED:-''${XDG_STATE_HOME:-$HOME/.local/state}/forge/agent-attention.jsonl}"
      reg_rows="$(jq -r '.[] | [.kind, .path, (.grain // "kv")] | @tsv' "$registry")"
      ${fzfArgsBash}
      # Shared F01 vocabulary (attention.nix) composed into every jq program; the $-bearing jq text is single-quoted data, never a shell expansion.
      # shellcheck disable=SC2016
      jq_defs=${lib.escapeShellArg (attention.urgencyJq + attention.kvJq + attention.spineJq)}
      mode="" render="table" since="" failures=0 limit=40 pick="" sql_query="" verb_name=""
      kinds=()
      usage() { printf '%s\n' 'Usage: forge-receipts [--kind K]... [--since ISO|Nh|Nd] [--failures] [--limit N]' '                      [--json|--tsv|--fzf|--follow] [--pick kind@ts]' '                      [--sql QUERY] [--verb NAME] [--verbs] [--audit] [--bus]'; }
      while [ "$#" -gt 0 ]; do
        case "$1" in
          --kind) kinds+=("''${2:?--kind needs a value}"); shift ;;
          --since) since="''${2:?--since needs a value}"; shift ;;
          --failures) failures=1 ;;
          --limit) limit="''${2:?--limit needs a value}"; shift ;;
          --json | --tsv) render="''${1#--}" ;;
          --fzf | --follow | --verbs | --audit | --bus) mode="''${1#--}" ;;
          --pick) mode="pick"; pick="''${2:?--pick needs kind@ts}"; shift ;;
          --sql) mode="sql"; sql_query="''${2:?--sql needs a query}"; shift ;;
          --verb) mode="verb"; verb_name="''${2:?--verb needs a name}"; shift ;;
          --help | -h) usage; exit 0 ;;
          *) usage >&2; exit 64 ;;
        esac
        shift
      done
      : "''${mode:=rows}"
      # --limit feeds --argjson, --since Nh/Nd feeds arithmetic: both reject non-numeric input at the option seam instead of a bash math abort.
      case "$limit" in "" | *[!0-9]*) usage >&2; exit 64 ;; esac
      case "$since" in
        *h | *d) case "''${since%?}" in "" | *[!0-9]*) usage >&2; exit 64 ;; esac ;;
      esac

      threshold="''${since//[:-]/}" # empty since stays empty; ISO normalizes
      case "$since" in
        *h) TZ=UTC0 printf -v threshold '%(%Y%m%dT%H%M%SZ)T' "$((EPOCHSECONDS - ''${since%h} * 3600))" ;;
        *d) TZ=UTC0 printf -v threshold '%(%Y%m%dT%H%M%SZ)T' "$((EPOCHSECONDS - ''${since%d} * 86400))" ;;
      esac

      wanted() { # kind membership; an empty --kind filter admits every row
        [ "''${#kinds[@]}" -eq 0 ] || case " ''${kinds[*]} " in *" $1 "*) return 0 ;; *) return 1 ;; esac
      }

      collect() { # $1 = per-source row cap; grain selects the parse expression
        local cap="''${1:-500}" kind path grain parse f
        while IFS=$'\t' read -r kind path grain; do
          f="$HOME/$path"
          { [ -f "$f" ] && wanted "$kind"; } || continue
          parse='kv_row'
          [ "$grain" != json ] || parse='(fromjson? | select(type == "object"))'
          tail -n "$cap" "$f" \
            | jq -Rc --arg kind "$kind" "$jq_defs $parse"' + {kind: $kind}' 2>/dev/null || true
        done <<<"$reg_rows"
      }

      # --- [SQL_PLANE]
      run_sql() { # $1 = SQL over the `receipts` spine table
        # Script-scope temp: the EXIT trap fires after this function returns, so a `local` here would be unbound at cleanup under set -u.
        tmpd="$(mktemp -d)"
        trap 'rm -rf "$tmpd"' EXIT
        corpus="$tmpd/corpus.jsonl"
        {
          collect 100000
          if wanted attention; then
            tail -n 100000 "$attention_feed" 2>/dev/null \
              | jq -Rc 'fromjson? | select(type == "object") + {kind: "attention"}' || true
          fi
        } | jq -c "$jq_defs spine" >"$corpus"
        [ -s "$corpus" ] || { printf 'forge-receipts: empty corpus\n' >&2; exit 1; }
        duckdb_args=()
        [ "$render" != json ] || duckdb_args+=(-json)
        # Declared spine schema (attention.nix spineColumnsSql), never inference: an all-null column on a thin or
        # --kind-filtered corpus infers JSON and poisons every COALESCE over it.
        duckdb ''${duckdb_args[0]+"''${duckdb_args[@]}"} -c \
          "CREATE TEMP TABLE receipts AS FROM read_json('$corpus', format = 'newline_delimited', columns = {${attention.spineColumnsSql}}); $1"
      }

      # --- [AUDIT]
      # Registry-vs-disk truth: declared rows probed for presence, JSONL sibling, and last ts; any on-disk receipt log the registry does not
      # claim is a FAIL — the dual-receipt law made enforceable.
      cmd_audit() {
        local rows="" kind path grain f last found registered rc=0
        note() { rows+="$(printf '%s\t%s\t%s' "$1" "$2" "$3")"$'\n'; }
        while IFS=$'\t' read -r kind path grain; do
          f="$HOME/$path"
          [ -f "$f" ] || { note ABSENT "$kind" "declared log has no rows yet: ~/$path"; continue; }
          last="$({ tail -n 1 "$f" 2>/dev/null || true; } \
            | jq -Rr "$jq_defs"' (if startswith("{") then (fromjson? // {}) else kv_row end) | .ts // "-"' 2>/dev/null || true)"
          if [ "$grain" = "kv" ] && [ "''${path##*.}" = "log" ] && [ ! -f "''${f%.log}.jsonl" ]; then
            note WARN "$kind" "kv log without JSONL sibling (pre-fold history or non-fold emitter), last=''${last:--}"
          else
            note OK "$kind" "last=''${last:--}"
          fi
        done <<<"$reg_rows"
        registered="$(jq -r --arg home "$HOME" '.[] | ($home + "/" + .path), ($home + "/" + .path | sub("\\.log$"; ".jsonl"))' "$registry")"
        while IFS= read -r found; do
          [ -n "$found" ] || continue
          grep -qxF "$found" <<<"$registered" \
            || { note FAIL "$(basename "$found")" "unregistered receipt emitter: ''${found/#"$HOME"/\~}"; rc=1; }
        done < <({
          find "$HOME/Library/Logs" -maxdepth 1 \( -name '*.receipts.log' -o -name '*.receipts.jsonl' \) 2>/dev/null || true
          find "''${XDG_STATE_HOME:-$HOME/.local/state}" -maxdepth 2 \( -name '*.receipts.log' -o -name '*.receipts.jsonl' \) 2>/dev/null || true
        } | sort)
        if [ "$render" = json ]; then
          TZ=UTC0 printf -v now_ts '%(%Y-%m-%dT%H:%M:%SZ)T' "$EPOCHSECONDS"
          jq -Rcs --arg ts "$now_ts" --arg rc "$rc" '{schema: "forge-receipts/v1", ts: $ts, verb: "audit", result: (if $rc == "0" then "ok" else "fail" end), rows: (split("\n") | map(select(length > 0) | split("\t") | {status: .[0], kind: .[1], detail: .[2]}))}' <<<"$rows"
        else
          printf '%s' "$rows" | gawk -F'\t' '{printf "[%-6s] %-18s %s\n", $1, $2, $3}'
        fi
        exit "$rc"
      }

      # --- [PUSH_BUS]
      # Live failure fold: every new registry row parses, derives urgency, and a high row broadcasts into every live zjstatus bar via
      # zjstatus::notify::. Torn or foreign lines fold to info and drop; a dead zellij is benign.
      cmd_bus() {
        local pathmap
        mapfile -t logs < <(jq -r --arg home "$HOME" '.[] | $home + "/" + .path' "$registry")
        [ "''${#logs[@]}" -gt 0 ] || { printf 'forge-receipts: empty registry\n' >&2; exit 1; }
        pathmap="$(jq -c --arg home "$HOME" \
          'map({key: ($home + "/" + .path), value: {kind, grain: (.grain // "kv")}}) | from_entries' "$registry")"
        tail -n 0 -F "''${logs[@]}" 2>/dev/null \
          | gawk 'match($0, /^==> (.+) <==$/, m) {f = m[1]; next} f != "" {print f "\t" $0; fflush()}' \
          | jq -Rrc --unbuffered --argjson map "$pathmap" "$jq_defs"'
              (split("\t")[0]) as $path
              | ($map[$path] // empty) as $row
              | (sub("^[^\t]*\t"; "")) as $line
              | (if $row.grain == "json" then ($line | fromjson? // {}) else ($line | kv_row) end)
              | . + {kind: $row.kind}
              | select(urgency == "high")
              | ((.ts // "" | fromdateiso8601? | localtime | strftime("%H:%M")) // "") as $hm
              | "!! \(.kind | ascii_upcase) \(.result // .state // .status // "fail")\(if $hm != "" then " · " + $hm else "" end)"' \
          | while IFS= read -r msg; do # streaming boundary: live failure push
              while IFS= read -r s; do
                [ -n "$s" ] || continue
                "$zellij_bin" --session "$s" pipe "zjstatus::notify::''${msg:0:120}" 2>/dev/null || true
              done < <("$zellij_bin" list-sessions -ns 2>/dev/null || true)
            done
      }

      case "$mode" in
        verbs) jq -r 'to_entries[] | [.key, .value.desc] | @tsv' "$verbs" | gawk -F'\t' '{printf "%-16s %s\n", $1, $2}'; exit 0 ;;
        sql) run_sql "$sql_query"; exit 0 ;;
        verb)
          v_sql="$(jq -r --arg v "$verb_name" '.[$v].sql // empty' "$verbs")"
          [ -n "$v_sql" ] || { printf 'forge-receipts: unknown verb %s (see --verbs)\n' "$verb_name" >&2; exit 64; }
          run_sql "$v_sql"; exit 0
          ;;
        audit) cmd_audit ;;
        bus) cmd_bus; exit 0 ;;
      esac

      if [ "$mode" = "follow" ]; then
        logs=()
        while IFS=$'\t' read -r kind path _; do
          wanted "$kind" || continue
          [ -f "$HOME/$path" ] && logs+=("$HOME/$path")
        done <<<"$reg_rows"
        [ "''${#logs[@]}" -gt 0 ] || { printf 'forge-receipts: no logs to follow\n' >&2; exit 1; }
        exec tail -n 0 -F "''${logs[@]}"
      fi

      if [ "$mode" = "pick" ]; then
        kinds=("''${pick%%@*}")
        collect | jq -s --arg ts "''${pick#*@}" '[.[] | select(.ts == $ts)] | last // empty'
        exit 0
      fi

      rows="$(collect | jq -s -c --arg th "$threshold" --argjson failures "$failures" --argjson limit "$limit" "$jq_defs"' map(select(.ts != null)) | (if $th != "" then map(select((.ts | gsub("[-:]"; "")) >= $th)) else . end) | (if $failures == 1 then map(select(urgency == "high")) else . end) | sort_by(.ts | gsub("[-:]"; "")) | reverse | .[:$limit]')"

      to_tsv() {
        jq -r '.[] | [.kind, .ts, (.result // .status // "-"), (to_entries | map(select(.key | IN("kind", "ts", "result") | not)) | map("\(.key)=\(.value)") | join(" "))] | @tsv' <<<"$rows"
      }

      case "$render" in
        json) jq -c '.[]' <<<"$rows" ;;
        tsv) to_tsv ;;
        table)
          if [ "$mode" = "fzf" ]; then
            sel="$(to_tsv | fzf --delimiter=$'\t' --border-label='[RECEIPTS]' \
              --preview="$self --pick {1}@{2} | jq ." --preview-window=right:55%:border-bold \
              "''${fzf_base[@]}")" || exit 0
            IFS=$'\t' read -r sel_kind sel_ts _ <<<"$sel"
            [ -n "$sel_kind" ] && "$self" --pick "$sel_kind@$sel_ts"
          else
            to_tsv | gawk -F'\t' '{printf "%-17s %-21s %-8s %s\n", $1, $2, $3, $4}'
          fi
          ;;
      esac
    '';
  };

  # --- [FORGE_BROWSE]
  forgeBrowse = pkgs.writeShellApplication {
    name = "forge-browse";
    runtimeInputs = [pkgs.coreutils pkgs.jq pkgs.fzf pkgs.gawk pkgs.gnused];
    text = ''
      # Polymorphic register browser: one entrypoint dispatches on the catalog; previews are read-only evidence; one typed receipt per browse run.
      catalog="${catalogJson}"
      self="''${BASH_SOURCE[0]}"
      receipt_log="''${FORGE_BROWSE_RECEIPT_LOG:-$HOME/Library/Logs/forge-browse.receipts.log}"
      ${fzfArgsBash}
      usage() {
        printf 'Usage: forge-browse [DOMAIN] | --json [DOMAIN] | --preview DOMAIN ID | --list-domains\n'
        printf 'Domains: %s\n' "$(jq -r 'keys | join(" ")' "$catalog")"
      }

      row_by_id() { # $1=register json  $2=id
        jq --arg id "$2" 'first(.[] | select((.alias // .chord_id // .name // .slug // .kind) == $id)) // empty' "$1"
      }

      preview() { # $1=domain  $2=id
        local json row
        json="$(jq -r --arg d "$1" '.[$d].json // empty' "$catalog")"
        [ -n "$json" ] || { printf 'no register json for domain %s\n' "$1"; return 1; }
        row="$(row_by_id "$json" "$2")"
        [ -n "$row" ] || { printf 'no row: %s\n' "$2"; return 1; }
        jq -r 'to_entries[] | select(.key != "rendered") | "\(.key): \(.value | tostring | gsub("\n\\s*"; " "))"' <<<"$row"
        case "$1" in
          aliases)
            printf '\nresolved bins:\n'
            jq -r '.expansion' <<<"$row" \
              | awk 'BEGIN{RS="[|;&\n]+"}{if ($1 != "") print $1}' \
              | while read -r w; do
                  case "$w" in
                    [a-zA-Z]*) command -v "$w" 2>/dev/null || printf '%s: unresolved\n' "$w" ;;
                  esac
                done | sort -u
            ;;
          chords)
            printf '\nrendered projection:\n'
            jq -r '.rendered' <<<"$row"
            ;;
        esac
        printf '\npreview_rc=0 source=%s\n' "$(basename "$json")"
      }

      receipt_surface="forge-browse"
      ${receiptsFold}
      emit_receipt() { # $1=domain $2=query $3=row_id $4=selection $5=action $6=result $7=exit $8=duration_ms
        local ts row q sel
        TZ=UTC0 printf -v ts '%(%Y-%m-%dT%H:%M:%SZ)T' "$EPOCHSECONDS"
        q="''${2//$'\t'/ }"
        sel="''${4//$'\t'/ }"
        printf -v row 'ts=%s\tdomain=%s\tsession_id=%s\tpane_id=%s\tcwd=%s\tquery=%s\trow_id=%s\tselection=%s\taction=%s\texit=%s\tduration_ms=%s\tresult=%s' \
          "$ts" "$1" "''${ZELLIJ_SESSION_NAME:--}" "''${ZELLIJ_PANE_ID:--}" "$PWD" \
          "''${q:--}" "''${3:--}" "''${sel:--}" "$5" "$7" "$8" "$6"
        append_receipt "$row" \
          || printf 'forge-browse: WARNING receipt not persisted to %s\n' "$receipt_log" >&2
      }

      case "''${1:-}" in
        --help | -h) usage; exit 0 ;;
        --list-domains) jq -r 'keys[]' "$catalog"; exit 0 ;;
        --preview) preview "''${2:?--preview needs DOMAIN ID}" "''${3:?--preview needs DOMAIN ID}"; exit 0 ;;
        --json)
          if [ -n "''${2:-}" ]; then
            json="$(jq -r --arg d "$2" '.[$d].json // empty' "$catalog")"
            [ -n "$json" ] || { printf 'forge-browse: no register json for %s\n' "$2" >&2; exit 64; }
            jq . "$json"
          else
            jq -r 'to_entries[] | select(.value.json != null) | [.key, .value.json] | @tsv' "$catalog" \
              | while IFS=$'\t' read -r d j; do jq --arg d "$d" '{($d): .}' "$j"; done | jq -s 'add'
          fi
          exit 0
          ;;
      esac

      domain="''${1:-}"
      if [ -z "$domain" ]; then
        domain="$(jq -r 'to_entries[] | [.key, .value.desc] | @tsv' "$catalog" \
          | fzf --delimiter=$'\t' --border-label='[REGISTERS]' --height=80% \
            "''${fzf_base[@]}" | cut -f1)" || true
        [ -n "$domain" ] || exit 0
      fi

      crow="$(jq -c --arg d "$domain" '.[$d] // empty' "$catalog")"
      [ -n "$crow" ] || { usage >&2; exit 64; }

      # One projection per catalog-row snapshot; 0x1f join survives empties.
      IFS=$'\x1f' read -r delegate json label filter < <(jq -r \
        '[(.delegate // ""), (.json // ""), (.label // ""), (.tsv // "")] | join("\u001f")' <<<"$crow")

      if [ "$delegate" = "receipts" ]; then
        exec ${forgeReceipts}/bin/forge-receipts --fzf
      fi

      binds=()
      while IFS= read -r b; do [ -n "$b" ] && binds+=(--bind "$b"); done < <(jq -r '.binds[]?' <<<"$crow")
      ${lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''binds+=(--bind "ctrl-y:execute-silent(printf '%s' {} | /usr/bin/pbcopy)")''}

      start="''${EPOCHREALTIME//[.,]/}"
      rc=0
      out="$(jq -r "$filter" "$json" | fzf --delimiter=$'\t' --border-label="$label" \
        --print-query --height=100% \
        --preview="$self --preview $domain {1}" --preview-window=right:55%:border-bold \
        "''${binds[@]}" "''${fzf_base[@]}")" || rc=$?
      end="''${EPOCHREALTIME//[.,]/}"
      duration_ms=$(((end - start) / 1000))

      # fzf --print-query contract: line 1 query, line 2 selection.
      mapfile -t out_lines <<<"$out"
      query="''${out_lines[0]:-}"
      sel="''${out_lines[1]:-}"
      id="''${sel%%$'\t'*}"
      # fzf exit classes: 0 select, 1 no-match, 130 user abort are benign; any other rc is a browser fault — result=error survives --failures
      # triage and the rc propagates to the caller.
      if [ "$rc" -eq 0 ] && [ -n "$id" ]; then
        emit_receipt "$domain" "$query" "$id" "$sel" "print" "ok" "0" "$duration_ms"
        row_by_id "$json" "$id"
      elif [ "$rc" -eq 0 ] || [ "$rc" -eq 1 ] || [ "$rc" -eq 130 ]; then
        emit_receipt "$domain" "$query" "-" "-" "cancel" "ok" "$rc" "$duration_ms"
      else
        emit_receipt "$domain" "$query" "-" "-" "browse" "error" "$rc" "$duration_ms"
        exit "$rc"
      fi
    '';
  };

  # --- [COMPLETIONS]
  # Projections of the same catalog/registry rows, one ;-delimited spec string per command; profile site-functions enter
  # fpath through the completion owner's fingerprint.
  domainsWord = lib.concatStringsSep " " (lib.attrNames catalogRows);
  mkCompletion = name: specs:
    pkgs.writeTextDir "share/zsh/site-functions/_${name}" ''
      #compdef ${name}
      _arguments \
        ${lib.concatStringsSep " \\\n  " (map (r: "'${r}'") (lib.splitString ";" specs))}
    '';
  browseCompletion = mkCompletion "forge-browse" "1:domain:(${domainsWord});--json[emit register JSON]:domain:(${domainsWord});--list-domains[list register domains];--preview[render row preview]:domain:(${domainsWord})";
  receiptsCompletion = mkCompletion "forge-receipts" "*--kind[filter by kind]:kind:(${lib.concatMapStringsSep " " (r: r.kind) receiptSources});--since[time window ISO or Nh/Nd]:window:;--failures[failed rows only];--limit[row cap]:count:;--json[JSON rows];--tsv[TSV rows];--fzf[interactive picker];--follow[live tail];--pick[one row]:row:;--sql[SQL over the receipts spine table]:query:;--verb[canned SQL projection]:verb:(${lib.concatStringsSep " " (lib.attrNames receiptVerbs)});--verbs[list verb rows];--audit[registry-vs-disk truth];--bus[live failure push into zjstatus bars]";

  # --- [TELEVISION_CHANNELS]
  # Durable semantic channels over the same registers; source/preview commands are store-path exact so channels never depend on ambient PATH.
  # Rows with json browse a register; the delegate row rides forge-receipts lanes.
  mkChannel = domain: row: {
    metadata = {
      name = "${channelPrefix}-${domain}";
      description = row.desc;
    };
    source =
      if row ? json
      then {
        command = "${pkgs.jq}/bin/jq -r '${row.tsv}' ${row.json}";
        output = "{split:\t:0}";
      }
      else {
        command = "${forgeReceipts}/bin/forge-receipts --tsv --limit 300";
        output = "{split:\t:0}@{split:\t:1}";
      };
    preview.command =
      if row ? json
      then "${forgeBrowse}/bin/forge-browse --preview ${domain} '{split:\t:0}'"
      else "${forgeReceipts}/bin/forge-receipts --pick '{split:\t:0}@{split:\t:1}' | ${pkgs.jq}/bin/jq -C .";
    ui.preview_panel.size = 55;
  };
  tvChannels = lib.mapAttrs' (domain: row: lib.nameValuePair "${channelPrefix}-${domain}" (mkChannel domain row)) catalogRows;
in {
  options.forge.registers = let
    ro = default: description:
      lib.mkOption {
        inherit default description;
        type = lib.types.raw;
        readOnly = true;
      };
  in {
    naming = ro naming "Name policy rows: source, slug, display, domain, consumers.";
    receiptSources = ro receiptSources "Declared receipt emitters: kind, path, grain (kv|json), emitter.";
  };

  config = {
    assertions = [
      {
        assertion = slugConflicts == [];
        message = "forge.registers.naming: colliding slug claims: ${lib.concatStringsSep ", " slugConflicts}";
      }
    ];

    home.packages = [forgeBrowse forgeReceipts browseCompletion receiptsCompletion];

    # Identity bundle row (bundle-apps.nix) for the bus agent.
    forge.bundleApps.forge-receipts-bus = "Forge Receipts Bus";

    # Live push bus: KeepAlive tail over every registry log; a high-urgency row lands in every zjstatus bar the instant its receipt is written.
    launchd.agents.forge-receipts-bus = {
      enable = true;
      config = {
        Label = "com.parametric-forge.forge-receipts-bus";
        ProgramArguments = ["${forgeReceipts}/bin/forge-receipts" "--bus"];
        KeepAlive = true;
        ThrottleInterval = 30;
        ProcessType = "Background";
        Nice = 10;
        StandardOutPath = "${config.home.homeDirectory}/Library/Logs/forge-receipts-bus.log";
        StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/forge-receipts-bus.log";
        AssociatedBundleIdentifiers = ["com.parametric-forge.forge-receipts-bus"];
      };
    };

    # Television: durable channel host. Shell integration stays off — Ctrl-R is Atuin, Ctrl-T is fzf; channels launch via `tv <channel>`.
    # Theme roles bind palette roles: one role row serves every bound key.
    programs.television = {
      enable = true;
      enableBashIntegration = false;
      enableZshIntegration = false;
      settings.ui = {
        theme = "forge-dracula";
        use_nerd_font_icons = true;
      };
      channels = tvChannels;
      themes.forge-dracula = lib.concatMapAttrs (role: keys: lib.genAttrs keys (_: palette.${role}.hex)) {
        background = ["background" "channel_mode_fg" "remote_control_mode_fg" "action_picker_mode_fg"];
        comment = ["border_fg" "dimmed_text_fg"];
        cyan = ["result_name_fg" "channel_mode_bg" "send_to_channel_mode_fg"];
        foreground = ["text_fg" "input_text_fg" "result_value_fg" "selection_fg"];
        green = ["match_fg" "remote_control_mode_bg"];
        magenta = ["result_count_fg" "preview_title_fg" "action_picker_mode_bg"];
        selection = ["selection_bg"];
        yellow = ["result_line_number_fg"];
      };
    };

    # Agent-facing register projections beside the theme's palette.json.
    xdg.configFile = lib.mapAttrs' (d: json: lib.nameValuePair "forge/registers/${d}.json" {source = json;}) registers;
  };
}
