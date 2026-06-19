def dashnull: if . == null or . == "" or . == "-" then null else . end;
split("\n")
| map(select(length > 0) | split("\t") | select(length >= 4))
| map({
    service: .[0],
    extension: .[1],
    state: .[2],
    version: (.[3] | dashnull),
    category: (.[4] // null | dashnull),
    required: ((.[5] // "optional") == "required")
  })
