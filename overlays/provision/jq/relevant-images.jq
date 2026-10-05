def ref: .Repository + ":" + .Tag;
map({repository: .Repository, tag: .Tag, id: (.ID // null), size: (.Size // null), ref: ref})
| map(select(.ref as $ref | any($configured[]; .image == $ref or (.image | startswith($ref + "@")))))
| sort_by(.repository, .tag)
