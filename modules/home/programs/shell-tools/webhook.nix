# Title         : webhook.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/webhook.nix
# ----------------------------------------------------------------------------
# Signed-event inbox on adnanh/webhook: typed source rows generate hooks.json (HMAC verification via env-named secrets, never literals) and one
# projector appends typed receipt rows. Loopback-only; an absent secret fails closed (empty HMAC key never matches a signed delivery). Rows may
# pin event type or emitter identity through `match` clauses ANDed beside the HMAC rule. A launchd agent owns the listener on Darwin;
# forge-cockpit consumes the standing listener's receipt ledger and never creates a second listener.
{
  config,
  lib,
  pkgs,
  ...
}: let
  jsonFormat = pkgs.formats.json {};
  port = "9010"; # beside the maghz tunnel's loopback 9000 (VPS hook forward), never under it

  # Source rows: signature grammar + event-id extraction per emitter, plus optional `match` pins ({source="header"|"payload"; name; value})
  # ANDed beside the HMAC clause. `ping` carries no signature and no projector — it is the readiness contract only.
  sources = {
    github = {
      signature = {
        header = "X-Hub-Signature-256";
        secretEnv = "FORGE_WEBHOOK_GITHUB_SECRET";
      };
      eventHeader = "X-GitHub-Delivery";
    };
    doppler = {
      signature = {
        header = "X-Doppler-Signature";
        secretEnv = "FORGE_WEBHOOK_DOPPLER_SECRET";
      };
      eventHeader = null;
    };
  };

  # Projector: payload hash, per-source event-id dedupe, one JSONL receipt row. mkdir spinlock (macOS lacks flock(1)); the section runs in milliseconds.
  inbox = pkgs.writeShellApplication {
    name = "forge-webhook-inbox";
    runtimeInputs = [pkgs.coreutils pkgs.jq];
    text = ''
      source_id="''${1:?source}"
      sig_state="''${2:?signature-state}"
      payload="''${INBOX_PAYLOAD:-}"
      payload_hash="$(printf '%s' "$payload" | sha256sum | cut -d' ' -f1)"
      event_id="''${INBOX_EVENT_ID:-$payload_hash}"

      state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/forge-webhook"
      mkdir -p "$state_dir"
      lock="$state_dir/.lock"
      tries=0 total=0
      until mkdir "$lock" 2>/dev/null; do
        tries=$((tries + 1)) total=$((total + 1))
        if [ "$total" -ge 600 ]; then
          echo "forge-webhook-inbox: cannot acquire $lock after 30s" >&2
          exit 75
        fi
        if [ "$tries" -ge 100 ]; then
          tries=0
          # Stale-holder break: the section is milliseconds, so a 10s-old lock is a dead holder. One rmdir
          # per window, then the loop re-races; a live peer that recreates the lock restarts the wait cleanly.
          lock_age=$((EPOCHSECONDS - $(stat -c %Y "$lock" 2>/dev/null || echo "$EPOCHSECONDS")))
          [ "$lock_age" -lt 10 ] || rmdir "$lock" 2>/dev/null || true
        fi
        sleep 0.05
      done
      trap 'rmdir "$lock" 2>/dev/null || true' EXIT

      dedupe="fresh"
      if grep -qxF "$source_id:$event_id" "$state_dir/seen.ids" 2>/dev/null; then
        dedupe="duplicate"
      else
        printf '%s:%s\n' "$source_id" "$event_id" >>"$state_dir/seen.ids"
      fi
      # Dedupe-index retention: a bounded recent window stays authoritative; rotation runs under the lock, so no reader observes a partial index.
      if [ -f "$state_dir/seen.ids" ] && [ "$(wc -l <"$state_dir/seen.ids")" -gt 10000 ]; then
        tail -n 5000 "$state_dir/seen.ids" >"$state_dir/seen.ids.new"
        mv -f "$state_dir/seen.ids.new" "$state_dir/seen.ids"
      fi

      TZ=UTC0 printf -v ts '%(%Y-%m-%dT%H:%M:%SZ)T' "$EPOCHSECONDS"
      jq -cn --arg ts "$ts" --arg source "$source_id" --arg event_id "$event_id" \
        --arg payload_hash "$payload_hash" --arg sig "$sig_state" --arg dedupe "$dedupe" \
        '{ts: $ts, source: $source, event_id: $event_id, payload_hash: $payload_hash,
          signature_state: $sig, dedupe_state: $dedupe, action: "project",
          result: (if $dedupe == "fresh" then "recorded" else "skipped" end)}' \
        >>"$state_dir/receipts.jsonl"
    '';
  };

  mkHook = name: row: let
    hmac = {
      match = {
        type = "payload-hmac-sha256";
        # Backtick raw string: Go template parsing runs on the raw JSON bytes, so escaped double quotes would break the action.
        secret = "{{ getenv `${row.signature.secretEnv}` | js }}";
        parameter = {
          source = "header";
          name = row.signature.header;
        };
      };
    };
    pins = map (m: {
      match = {
        type = "value";
        inherit (m) value;
        parameter = {inherit (m) source name;};
      };
    }) (row.match or []);
  in {
    id = name;
    execute-command = "${inbox}/bin/forge-webhook-inbox";
    success-http-response-code = 202; # async acceptance — command output never rides the response
    trigger-rule-mismatch-http-response-code = 403; # absent signature headers and failed pins read 403; a present-but-wrong HMAC errors upstream as 500 — fail-closed either way
    pass-arguments-to-command = [
      {
        source = "string";
        inherit name;
      }
      {
        source = "string";
        name = "verified";
      }
    ];
    pass-environment-to-command =
      [
        {
          source = "entire-payload";
          envname = "INBOX_PAYLOAD";
        }
      ]
      ++ lib.optional (row.eventHeader != null) {
        source = "header";
        name = row.eventHeader;
        envname = "INBOX_EVENT_ID";
      };
    trigger-rule =
      if pins == []
      then hmac
      else {and = [hmac] ++ pins;};
  };

  # The .json suffix is load-bearing: webhook detects the hooks format by extension.
  hooksJson = jsonFormat.generate "forge-webhook-hooks.json" (
    lib.mapAttrsToList mkHook sources
    ++ [
      {
        id = "ping";
        execute-command = "${pkgs.coreutils}/bin/true";
        success-http-response-code = 202;
      }
    ]
  );

  # Secret ladder: session env (hook-resolved) execs directly; a bare spawn — the launchd agent — injects the machine config at the process
  # boundary via doppler run; when Doppler is unreachable the bare exec keeps the fail-closed HMAC floor (empty key never matches).
  runner = pkgs.writeShellApplication {
    name = "forge-webhook";
    runtimeInputs = [pkgs.webhook pkgs.doppler];
    text = ''
      argv=(webhook -hooks ${hooksJson} -ip 127.0.0.1 -port "''${WEBHOOK_PORT:-${port}}" -template -x-request-id "$@")
      if [ -n "''${FORGE_WEBHOOK_GITHUB_SECRET:-}" ]; then
        exec "''${argv[@]}"
      fi
      if doppler secrets download --project parametric-forge --config dev_machine --no-file --format json >/dev/null 2>&1; then
        exec doppler run --project parametric-forge --config dev_machine --preserve-env -- "''${argv[@]}"
      fi
      exec "''${argv[@]}"
    '';
  };
in {
  home = {
    packages = [pkgs.webhook runner inbox];
    sessionVariables.WEBHOOK_PORT = port;

    # Receipts and the dedupe index live under XDG state; activation seeds the dir.
    activation.ensureWebhookState = lib.hm.dag.entryAfter ["writeBoundary"] ''
      mkdir -p "${config.xdg.stateHome}/forge-webhook"
      chmod 700 "${config.xdg.stateHome}/forge-webhook"
    '';
  };

  # Standing listener: KeepAlive restarts a crashed webhook, the throttle bounds crash loops, and dual logs land beside the other forge agents.
  launchd.agents.forge-webhook = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    enable = true;
    config = {
      Label = "com.parametric-forge.forge-webhook";
      ProgramArguments = ["${runner}/bin/forge-webhook"];
      KeepAlive = true;
      ThrottleInterval = 30;
      ProcessType = "Background";
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/forge-webhook.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/forge-webhook.log";
      AssociatedBundleIdentifiers = ["com.parametric-forge.forge-webhook"];
    };
  };
}
