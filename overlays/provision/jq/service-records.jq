split("\n")
| map(select(length > 0) | split("\t"))
| map({
    key: .[0],
    role: .[1],
    enabled: (.[2] == "1"),
    connectable: (.[2] == "1"),
    profile: .[3],
    image: .[4],
    imageEnv: .[8],
    host: .[11],
    port: (.[5] | tonumber),
    portEnv: .[9],
    portSource: .[10],
    containerPort: (.[12] | tonumber),
    dsnRedacted: (if .[2] == "1" then .[6] else null end),
    dsnEnv: .[7],
    composeService: .[0]
  })
| map({key: .key, value: .})
| from_entries
