# Title         : browsers.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/browsers.nix
# ----------------------------------------------------------------------------
# Register rail owner: one row grammar projected to fzf browse commands,
# Television durable channels, XDG register JSON, and zsh completions.
# Previews are read-only evidence; every browse run emits one typed receipt.
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.forge.theme) palette;
  profileBin = "/etc/profiles/per-user/${config.home.username}/bin";
  fleet = import ./mcp-fleet.nix {
    inherit profileBin;
    homeDir = config.home.homeDirectory;
  };

  # --- Name policy rows -------------------------------------------------------
  # One repo/workroot identity resolves to stable slugs across consumers; the
  # channel prefix and receipt-log grammar are the live consumers today.
  # `collision` is the slug-clash policy (reject = eval assertion below);
  # `previous` carries retired slugs so renames keep receipt-partition history.
  naming = [
    {
      source = "Parametric_Forge";
      slug = "forge";
      display = "[FORGE]";
      domain = "estate-repo";
      collision = "reject";
      previous = [];
      consumers = ["television-channel-prefix" "receipt-log-prefix" "launchd-agent-name-prefix" "wezterm-workspace-name" "zellij-session-name"];
    }
    {
      source = "Rasm";
      slug = "rasm";
      display = "[RASM]";
      domain = "estate-repo";
      collision = "reject";
      previous = [];
      consumers = ["zellij-session-name"];
    }
    {
      source = "Maghz";
      slug = "maghz";
      display = "[MAGHZ]";
      domain = "estate-repo";
      collision = "reject";
      previous = [];
      consumers = ["tunnel-receipt-partition" "zellij-session-name"];
    }
  ];
  channelPrefix = (lib.findFirst (r: lib.elem "television-channel-prefix" r.consumers) {slug = "forge";} naming).slug;
  slugClaims = lib.concatMap (r: [r.slug] ++ r.previous) naming;
  slugConflicts = lib.attrNames (lib.filterAttrs (_: c: c > 1) (lib.foldl' (acc: s: acc // {${s} = (acc.${s} or 0) + 1;}) {} slugClaims));

  # --- Receipt source register --------------------------------------------------
  # Declared kv-receipt emitters; paths are $HOME-relative and may not exist yet.
  receiptSources =
    [
      {
        kind = "redeploy";
        path = "Library/Logs/forge-redeploy.receipts.log";
        emitter = "forge-redeploy";
      }
      {
        kind = "maintenance";
        path = "Library/Logs/forge-nix-maintenance.receipts.log";
        emitter = "forge-nix-maintenance";
      }
      {
        kind = "drift";
        path = "Library/Logs/forge-nix-drift.receipts.log";
        emitter = "forge-nix-drift";
      }
      {
        kind = "orphan-sweep";
        path = "Library/Logs/forge-orphan-sweep.receipts.log";
        emitter = "forge-orphan-sweep";
      }
      {
        kind = "activation-sweep";
        path = "Library/Logs/forge-activation-sweep.receipts.log";
        emitter = "forge-activation-sweep";
      }
      {
        kind = "accept";
        path = "Library/Logs/forge-accept.receipts.log";
        emitter = "forge-accept";
      }
      {
        kind = "browse";
        path = "Library/Logs/forge-browse.receipts.log";
        emitter = "forge-browse";
      }
      {
        kind = "workspace";
        path = "Library/Logs/forge-workspace.receipts.log";
        emitter = "forge-workspace";
      }
      {
        kind = "wezterm";
        path = "Library/Logs/forge-wezterm.receipts.log";
        emitter = "wezterm command deck";
      }
      {
        kind = "zellij";
        path = "Library/Logs/forge-zellij.receipts.log";
        emitter = "forge-zellij";
      }
      {
        kind = "mcp";
        path = "Library/Logs/forge-mcp.receipts.log";
        emitter = "forge-mcp";
      }
      {
        kind = "agents";
        path = "Library/Logs/forge-agents.receipts.log";
        emitter = "forge-agents collector";
      }
    ]
    # Tunnel receipt rows derive from the ssh tunnel registry: a new VPS row
    # appears in the receipts browser without touching this file.
    ++ lib.mapAttrsToList (name: _: {
      kind = "tunnel-${name}";
      path = "Library/Logs/forge-${name}-vps-tunnel.receipts.log";
      emitter = "${name}-vps-tunnel launchd agent";
    })
    config.forge.ssh.hosts;

  # --- Register JSON projections -------------------------------------------------
  # MCP rows are sanitized at the seam: endpoint basename, key NAMES, pin,
  # doctor family (label/port/exec names) — never argv (host paths), token
  # custody paths, or values.
  mcpRegister =
    map (r: {
      inherit (r) name transport probe;
      endpoint = r.url or (baseNameOf r.command);
      envKeys = r.envKeys or [];
      clients = r.clients or ["claude" "codex"];
      assertLevel = r.assertLevel or "full";
      launcher =
        if r ? launcher
        then {inherit (r.launcher) pkg version;}
        else null;
      codex = r.codex or null;
      doctor =
        if r ? doctor
        then {
          launchdLabel = r.doctor.launchdLabel or null;
          port = r.doctor.port or null;
          execs = r.doctor.execs or [];
        }
        else null;
    })
    fleet;
  registerJson = domain: rows: pkgs.writeText "forge-register-${domain}.json" (builtins.toJSON rows);
  registers = {
    aliases = registerJson "aliases" config.forge.registers.aliases;
    chords = registerJson "chords" (config.forge.chords.register or []);
    mcp = registerJson "mcp" mcpRegister;
    naming = registerJson "naming" naming;
    receipts = registerJson "receipts" receiptSources;
  };

  # --- Browse catalog --------------------------------------------------------------
  # Catalog-driven dispatch: one row per domain — source JSON, TSV projection,
  # label, per-domain binds. The receipts domain delegates to forge-receipts.
  catalogRows = {
    aliases = {
      json = registers.aliases;
      label = "[ALIASES]";
      tsv = ''.[] | [.alias, .category, .risk, .expansion] | @tsv'';
      desc = "shell alias register";
    };
    chords = {
      json = registers.chords;
      label = "[CHORDS]";
      tsv = ''.[] | [.chord_id, .mods, .key, .label] | @tsv'';
      desc = "chord register across consumers";
    };
    mcp = {
      json = registers.mcp;
      label = "[MCP]";
      tsv = ''.[] | [.name, .transport, (.launcher.version // "-"), .probe] | @tsv'';
      desc = "MCP fleet rows";
      binds = ["ctrl-d:execute(${profileBin}/forge-mcp doctor | ${pkgs.less}/bin/less -R)"];
    };
    naming = {
      json = registers.naming;
      label = "[NAMING]";
      tsv = ''.[] | [.slug, .source, .display, .domain] | @tsv'';
      desc = "name policy rows";
    };
    receipts = {
      delegate = "receipts";
      label = "[RECEIPTS]";
      desc = "typed receipt rows across estate logs";
    };
  };
  catalogJson = pkgs.writeText "forge-browse-catalog.json" (builtins.toJSON catalogRows);

  # Per-browser fzf projection: theme rides each generated command, never a
  # global default (global fzf options stay theme-only in fzf.nix).
  fzfColorRows = [
    "--color=fg:${palette.foreground.hex},fg+:${palette.background.hex},bg:${palette.background.hex},bg+:${palette.cyan.hex},selected-fg:${palette.background.hex},selected-bg:${palette.cyan.hex}"
    "--color=hl:${palette.green.hex},hl+:${palette.magenta.hex},info:${palette.comment.hex},marker:${palette.green.hex}"
    "--color=prompt:${palette.magenta.hex},spinner:${palette.green.hex},pointer:${palette.magenta.hex},header:${palette.comment.hex}"
    "--color=gutter:${palette.background.hex},border:${palette.cyan.hex},separator:${palette.pink.hex},scrollbar:${palette.pink.hex}"
    "--color=preview-fg:${palette.foreground.hex},preview-scrollbar:${palette.pink.hex},label:${palette.magenta.hex},query:${palette.foreground.hex}"
  ];
  fzfBaseArgs = fzfColorRows ++ ["--border=sharp" "--layout=reverse" "--info=right" "--highlight-line" "--prompt=❯ " "--pointer=❯"];
  # Bash array literal injected into each generated script; consumers expand
  # "''${fzf_base[@]}" so every browser carries the theme per command.
  fzfArgsBash = "fzf_base=(\n${lib.concatMapStringsSep "\n" (a: "        ${lib.escapeShellArg a}") fzfBaseArgs}\n      )";

  # --- forge-receipts ------------------------------------------------------------
  forgeReceipts = pkgs.writeShellApplication {
    name = "forge-receipts";
    runtimeInputs = [pkgs.coreutils pkgs.jq pkgs.fzf pkgs.gawk];
    text = ''
      # Unified browser over kv receipt logs; registry rows declare the corpus.
      registry="${registers.receipts}"
      self="''${BASH_SOURCE[0]}"
      ${fzfArgsBash}
      mode="table" since="" failures=0 limit=40 pick=""
      kinds=()
      usage() {
        printf 'Usage: forge-receipts [--kind K]... [--since ISO|Nh|Nd] [--failures]\n'
        printf '                      [--limit N] [--json|--tsv|--fzf|--follow] [--pick kind@ts]\n'
      }
      while [ "$#" -gt 0 ]; do
        case "$1" in
          --kind) kinds+=("''${2:?--kind needs a value}"); shift ;;
          --since) since="''${2:?--since needs a value}"; shift ;;
          --failures) failures=1 ;;
          --limit) limit="''${2:?--limit needs a value}"; shift ;;
          --json) mode="json" ;;
          --tsv) mode="tsv" ;;
          --fzf) mode="fzf" ;;
          --follow) mode="follow" ;;
          --pick) mode="pick"; pick="''${2:?--pick needs kind@ts}"; shift ;;
          --help | -h) usage; exit 0 ;;
          *) usage >&2; exit 64 ;;
        esac
        shift
      done
      # --limit feeds --argjson, --since Nh/Nd feeds arithmetic: both reject
      # non-numeric input at the option seam instead of a bash math abort.
      case "$limit" in "" | *[!0-9]*) usage >&2; exit 64 ;; esac
      case "$since" in
        *h | *d) case "''${since%?}" in "" | *[!0-9]*) usage >&2; exit 64 ;; esac ;;
      esac

      threshold=""
      if [ -n "$since" ]; then
        case "$since" in
          *h) TZ=UTC0 printf -v threshold '%(%Y%m%dT%H%M%SZ)T' "$((EPOCHSECONDS - ''${since%h} * 3600))" ;;
          *d) TZ=UTC0 printf -v threshold '%(%Y%m%dT%H%M%SZ)T' "$((EPOCHSECONDS - ''${since%d} * 86400))" ;;
          *) threshold="''${since//[:-]/}" ;;
        esac
      fi

      wanted() {
        [ "''${#kinds[@]}" -eq 0 ] && return 0
        local k
        for k in "''${kinds[@]}"; do [ "$k" = "$1" ] && return 0; done
        return 1
      }

      collect() {
        local kind path f
        while IFS=$'\t' read -r kind path; do
          f="$HOME/$path"
          [ -f "$f" ] || continue
          wanted "$kind" || continue
          tail -n 500 "$f" | jq -R -c --arg kind "$kind" '
            split("\t")
            | map(select(test("^[^=]+=")) | capture("^(?<key>[^=]+)=(?<value>.*)$"))
            | from_entries + {kind: $kind}' 2>/dev/null || true
        done < <(jq -r '.[] | [.kind, .path] | @tsv' "$registry")
      }

      if [ "$mode" = "follow" ]; then
        logs=()
        while IFS=$'\t' read -r kind path; do
          wanted "$kind" || continue
          [ -f "$HOME/$path" ] && logs+=("$HOME/$path")
        done < <(jq -r '.[] | [.kind, .path] | @tsv' "$registry")
        [ "''${#logs[@]}" -gt 0 ] || { printf 'forge-receipts: no logs to follow\n' >&2; exit 1; }
        exec tail -n 0 -F "''${logs[@]}"
      fi

      if [ "$mode" = "pick" ]; then
        kinds=("''${pick%%@*}")
        collect | jq -s --arg ts "''${pick#*@}" '[.[] | select(.ts == $ts)] | last // empty'
        exit 0
      fi

      rows="$(collect | jq -s -c --arg th "$threshold" --argjson failures "$failures" --argjson limit "$limit" '
        map(select(.ts != null))
        | (if $th != "" then map(select((.ts | gsub("[-:]"; "")) >= $th)) else . end)
        | (if $failures == 1 then map(select(((.result // "ok") != "ok") or ((.status // "") | test("(?i)fail")))) else . end)
        | sort_by(.ts | gsub("[-:]"; "")) | reverse | .[:$limit]')"

      to_tsv() {
        jq -r '.[] | [.kind, .ts, (.result // .status // "-"),
          (to_entries | map(select(.key | IN("kind", "ts", "result") | not))
            | map("\(.key)=\(.value)") | join(" "))] | @tsv' <<<"$rows"
      }

      case "$mode" in
        json) jq -c '.[]' <<<"$rows" ;;
        tsv) to_tsv ;;
        table)
          to_tsv | awk -F'\t' '{printf "%-17s %-21s %-8s %s\n", $1, $2, $3, $4}'
          ;;
        fzf)
          sel="$(to_tsv | fzf --delimiter=$'\t' --border-label='[RECEIPTS]' \
            --preview="$self --pick {1}@{2} | jq ." --preview-window=right:55%:border-bold \
            "''${fzf_base[@]}")" || exit 0
          IFS=$'\t' read -r sel_kind sel_ts _ <<<"$sel"
          [ -n "$sel_kind" ] && "$self" --pick "$sel_kind@$sel_ts"
          ;;
        *) usage >&2; exit 64 ;;
      esac
    '';
  };

  # --- forge-browse ---------------------------------------------------------------
  forgeBrowse = pkgs.writeShellApplication {
    name = "forge-browse";
    runtimeInputs = [pkgs.coreutils pkgs.jq pkgs.fzf pkgs.gawk pkgs.gnused];
    text = ''
      # Polymorphic register browser: one entrypoint dispatches on the catalog;
      # previews are read-only evidence; one typed receipt per browse run.
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

      emit_receipt() { # $1=domain $2=query $3=row_id $4=selection $5=action $6=result $7=exit $8=duration_ms
        local ts q sel
        TZ=UTC0 printf -v ts '%(%Y-%m-%dT%H:%M:%SZ)T' "$EPOCHSECONDS"
        q="''${2//$'\t'/ }"
        sel="''${4//$'\t'/ }"
        mkdir -p "$(dirname "$receipt_log")"
        printf 'ts=%s\towner=forge-browse\tbrowser_id=forge-browse\tscope=%s\trow_kind=%s\tmutation=none\thost=fzf\tsession_id=%s\tpane_id=%s\tcwd=%s\tquery=%s\trow_id=%s\tselection=%s\taction=%s\texit=%s\tduration_ms=%s\tstdout_path=-\tstderr_path=-\tnext_row=-\tresult=%s\n' \
          "$ts" "$1" "$1" "''${ZELLIJ_SESSION_NAME:--}" "''${ZELLIJ_PANE_ID:--}" "$PWD" \
          "''${q:--}" "''${3:--}" "''${sel:--}" "$5" "$7" "$8" "$6" >>"$receipt_log"
      }

      case "''${1:-}" in
        --help | -h) usage; exit 0 ;;
        --list-domains) jq -r 'keys[]' "$catalog"; exit 0 ;;
        --preview)
          preview "''${2:?--preview needs DOMAIN ID}" "''${3:?--preview needs DOMAIN ID}"
          exit 0
          ;;
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
      # fzf exit classes: 0 select, 1 no-match, 130 user abort — benign runs;
      # any other rc is a browser fault: result=error survives --failures
      # triage and the rc propagates to the caller.
      case "$rc" in
        0)
          if [ -n "$id" ]; then
            emit_receipt "$domain" "$query" "$id" "$sel" "print" "ok" "0" "$duration_ms"
            row_by_id "$json" "$id"
          else
            emit_receipt "$domain" "$query" "-" "-" "cancel" "ok" "0" "$duration_ms"
          fi
          ;;
        1 | 130)
          emit_receipt "$domain" "$query" "-" "-" "cancel" "ok" "$rc" "$duration_ms"
          ;;
        *)
          emit_receipt "$domain" "$query" "-" "-" "browse" "error" "$rc" "$duration_ms"
          exit "$rc"
          ;;
      esac
    '';
  };

  # --- Completions ------------------------------------------------------------------
  # Projections of the same catalog/registry rows; profile site-functions
  # enter fpath through the completion owner's fingerprint.
  domains = lib.attrNames catalogRows;
  kinds = map (r: r.kind) receiptSources;
  browseCompletion = pkgs.writeTextDir "share/zsh/site-functions/_forge-browse" ''
    #compdef forge-browse
    _arguments \
      '1:domain:(${lib.concatStringsSep " " domains})' \
      '--json[emit register JSON]:domain:(${lib.concatStringsSep " " domains})' \
      '--list-domains[list register domains]' \
      '--preview[render row preview]:domain:(${lib.concatStringsSep " " domains})'
  '';
  receiptsCompletion = pkgs.writeTextDir "share/zsh/site-functions/_forge-receipts" ''
    #compdef forge-receipts
    _arguments \
      '*--kind[filter by kind]:kind:(${lib.concatStringsSep " " kinds})' \
      '--since[time window ISO or Nh/Nd]:window:' \
      '--failures[failed rows only]' \
      '--limit[row cap]:count:' \
      '--json[JSON rows]' \
      '--tsv[TSV rows]' \
      '--fzf[interactive picker]' \
      '--follow[live tail]' \
      '--pick[one row]:row:'
  '';

  # --- Television channels -------------------------------------------------------
  # Durable semantic channels over the same registers; source/preview commands
  # are store-path exact so channels never depend on ambient PATH.
  mkChannel = domain: row: {
    metadata = {
      name = "${channelPrefix}-${domain}";
      description = row.desc;
    };
    source = {
      command = "${pkgs.jq}/bin/jq -r '${row.tsv}' ${row.json}";
      output = "{split:\t:0}";
    };
    preview.command = "${forgeBrowse}/bin/forge-browse --preview ${domain} '{split:\t:0}'";
    ui.preview_panel.size = 55;
  };
  tvChannels =
    lib.mapAttrs' (domain: row: lib.nameValuePair "${channelPrefix}-${domain}" (mkChannel domain row))
    (lib.filterAttrs (_: row: row ? json) catalogRows)
    // {
      "${channelPrefix}-receipts" = {
        metadata = {
          name = "${channelPrefix}-receipts";
          description = "typed receipt rows across estate logs";
        };
        source = {
          command = "${forgeReceipts}/bin/forge-receipts --tsv --limit 300";
          output = "{split:\t:0}@{split:\t:1}";
        };
        preview.command = "${forgeReceipts}/bin/forge-receipts --pick '{split:\t:0}@{split:\t:1}' | ${pkgs.jq}/bin/jq -C .";
        ui.preview_panel.size = 55;
      };
    };
in {
  options.forge.registers.naming = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
    default = naming;
    description = "Name policy rows: source, slug, display, domain, consumers.";
  };
  options.forge.registers.receiptSources = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
    default = receiptSources;
    description = "Declared kv-receipt emitters: kind, path, emitter.";
  };

  config = {
    assertions = [
      {
        assertion = slugConflicts == [];
        message = "forge.registers.naming: colliding slug claims: ${lib.concatStringsSep ", " slugConflicts}";
      }
    ];

    home.packages = [forgeBrowse forgeReceipts browseCompletion receiptsCompletion];

    # Television 0.15.9: durable channel host. Shell integration stays off —
    # Ctrl-R is Atuin, Ctrl-T is fzf; channels launch via `tv <channel>`.
    programs.television = {
      enable = true;
      enableBashIntegration = false;
      enableZshIntegration = false;
      settings.ui = {
        theme = "forge-dracula";
        use_nerd_font_icons = true;
      };
      channels = tvChannels;
      themes.forge-dracula = {
        background = palette.background.hex;
        border_fg = palette.comment.hex;
        text_fg = palette.foreground.hex;
        dimmed_text_fg = palette.comment.hex;
        input_text_fg = palette.foreground.hex;
        result_count_fg = palette.magenta.hex;
        result_name_fg = palette.cyan.hex;
        result_line_number_fg = palette.yellow.hex;
        result_value_fg = palette.foreground.hex;
        selection_fg = palette.foreground.hex;
        selection_bg = palette.selection.hex;
        match_fg = palette.green.hex;
        preview_title_fg = palette.magenta.hex;
        channel_mode_fg = palette.background.hex;
        channel_mode_bg = palette.cyan.hex;
        remote_control_mode_fg = palette.background.hex;
        remote_control_mode_bg = palette.green.hex;
        action_picker_mode_fg = palette.background.hex;
        action_picker_mode_bg = palette.magenta.hex;
        send_to_channel_mode_fg = palette.cyan.hex;
      };
    };

    # Agent-facing register projections beside the theme's palette.json.
    xdg.configFile = {
      "forge/registers/aliases.json".source = registers.aliases;
      "forge/registers/chords.json".source = registers.chords;
      "forge/registers/mcp.json".source = registers.mcp;
      "forge/registers/naming.json".source = registers.naming;
      "forge/registers/receipts.json".source = registers.receipts;
    };
  };
}
