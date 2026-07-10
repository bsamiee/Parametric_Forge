# Title         : receipts.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/receipts.nix
# ----------------------------------------------------------------------------
# Dual-receipt emit fold for every receipt-bearing kernel: one row spec in (a k=v TSV row or a JSON object), one human TSV line plus a JSONL sibling
# out with identical envelope keys and JSON-number numerics. The host script sets receipt_log and receipt_surface and carries jq in runtimeInputs.

''
  append_receipt() { # $1: "k=v<TAB>k=v" row or one-line JSON object
    local tsv json
    if [ "''${1:0:1}" = "{" ]; then
      json="$(jq -c --arg s "$receipt_surface" '. + {surface: (.surface // $s)}' <<<"$1")"
      tsv="$(jq -r 'to_entries | map("\(.key)=\(.value | tostring)") | join("\t")' <<<"$json")"
    else
      printf -v tsv '%s\tsurface=%s' "$1" "$receipt_surface"
      json="$(jq -Rc 'split("\t")
        | map(capture("^(?<key>[^=]+)=(?<value>.*)$") // {key: "raw", value: .})
        | map(.value |= (tonumber? // .))
        | from_entries' <<<"$tsv")"
    fi
    mkdir -p "''${receipt_log%/*}" \
      && printf '%s\n' "$tsv" >>"$receipt_log" \
      && printf '%s\n' "$json" >>"''${receipt_log%.log}.jsonl"
  }
''
