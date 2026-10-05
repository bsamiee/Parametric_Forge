split("\n")
| map(select(length > 0) | split("\t"))
| map({
    service: .[0],
    image: .[4],
    enabled: (.[2] == "1")
  })
| sort_by(.service)
