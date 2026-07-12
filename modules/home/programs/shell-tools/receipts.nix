# Title         : receipts.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/receipts.nix
# ----------------------------------------------------------------------------
# Dual-receipt emit fold for every receipt-bearing kernel: one row spec in (a k=v TSV row or a JSON object), one human TSV line plus a JSONL sibling
# out with identical envelope keys and JSON-number numerics. The host script sets receipt_log and receipt_surface and carries jq in runtimeInputs.
''
  append_receipt() ( # $1: "k=v<TAB>k=v" row or one-line JSON object
    local tsv json receipt_dir json_log lock_file lock_fd
    local had_tsv=0 had_json=0 tsv_size=0 json_size=0 committed=0 rollback_ready=0 rollback_failed=0
    [ "$#" -eq 1 ] || {
      printf 'append_receipt: expected one row\n' >&2
      return 64
    }
    [[ "$1" != *$'\n'* ]] || {
      printf 'append_receipt: row must occupy one line\n' >&2
      return 65
    }
    if [ "''${1:0:1}" = "{" ]; then
      json="$(printf '%s\n' "$1" | jq -ec --arg s "$receipt_surface" '. + {surface: (.surface // $s)}')" || return 65
      tsv="$(printf '%s\n' "$json" | jq -er 'to_entries | map("\(.key)=\(.value | tostring)") | join("\t")')" || return 65
    else
      printf -v tsv '%s\tsurface=%s' "$1" "$receipt_surface"
      json="$(printf '%s\n' "$tsv" | jq -Rc 'split("\t")
        | map(capture("^(?<key>[^=]+)=(?<value>.*)$") // {key: "raw", value: .})
        | map(.value |= (tonumber? // .))
        | from_entries')" || return 65
    fi

    receipt_dir="''${receipt_log%/*}"
    [ "$receipt_dir" != "$receipt_log" ] || receipt_dir=.
    json_log="''${receipt_log%.log}.jsonl"
    lock_file="$receipt_log.writer.lock"
    mkdir -p "$receipt_dir" || {
      printf 'append_receipt: cannot create receipt directory: %s\n' "$receipt_dir" >&2
      return 73
    }

    if ! exec {lock_fd}>"$lock_file"; then
      printf 'append_receipt: cannot open receipt writer lock: %s\n' "$lock_file" >&2
      return 73
    fi
    if command -v flock >/dev/null 2>&1; then
      flock -w 5 "$lock_fd" || {
        printf 'append_receipt: receipt writer lock timed out: %s\n' "$lock_file" >&2
        return 75
      }
    elif [ -x /usr/bin/lockf ]; then
      /usr/bin/lockf -s -t 5 "$lock_fd" || {
        printf 'append_receipt: receipt writer lock timed out: %s\n' "$lock_file" >&2
        return 75
      }
    else
      printf 'append_receipt: no receipt lock owner is available\n' >&2
      return 69
    fi

    # shellcheck disable=SC2329
    receipt_finish() {
      if ((rollback_ready && ! committed)); then
        if ((had_tsv)); then
          truncate -s "$tsv_size" "$receipt_log" {lock_fd}>&- 2>/dev/null || rollback_failed=1
        else
          rm -f "$receipt_log" {lock_fd}>&- 2>/dev/null || rollback_failed=1
        fi
        if ((had_json)); then
          truncate -s "$json_size" "$json_log" {lock_fd}>&- 2>/dev/null || rollback_failed=1
        else
          rm -f "$json_log" {lock_fd}>&- 2>/dev/null || rollback_failed=1
        fi
        ((rollback_failed == 0)) || printf 'append_receipt: receipt rollback failed: %s\n' "$receipt_log" >&2
      fi
      exec {lock_fd}>&-
    }
    trap receipt_finish EXIT

    if [ -e "$receipt_log" ]; then
      had_tsv=1
      tsv_size="$(exec {lock_fd}>&-; wc -c <"$receipt_log")" || {
        printf 'append_receipt: cannot inspect receipt log: %s\n' "$receipt_log" >&2
        return 74
      }
      tsv_size="''${tsv_size//[[:space:]]/}"
    fi
    if [ -e "$json_log" ]; then
      had_json=1
      json_size="$(exec {lock_fd}>&-; wc -c <"$json_log")" || {
        printf 'append_receipt: cannot inspect JSON receipt log: %s\n' "$json_log" >&2
        return 74
      }
      json_size="''${json_size//[[:space:]]/}"
    fi
    rollback_ready=1

    if ! printf '%s\n' "$tsv" >>"$receipt_log" || ! printf '%s\n' "$json" >>"$json_log"; then
      printf 'append_receipt: dual receipt append failed: %s\n' "$receipt_log" >&2
      return 74
    fi
    committed=1
  )
''
