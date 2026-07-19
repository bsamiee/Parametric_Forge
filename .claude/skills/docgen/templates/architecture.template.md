# [<architecture-title-token>]

<domain-map-lead-2-3-sentences: the unit's charter in owning voice — what it owns, the one invariant band it lowers onto, and its boundary to the peers it aligns with by contract, never by reference.>

## [01]-[DOMAIN_MAP]

A codemap is the unit's file index: one node per eventual source file in the language's folder and file casing, each `#` tail naming the concept that file owns. Tails align within a block under the 150-column cap, carrying no method chain, type roster, or design detail; a tail that cannot fit aligned is trimmed to its load-bearing concept.

```text codemap
core/
├── resolver.py       # mints content keys; owns the resolve dispatch
├── registry.py       # holds the descriptor registry and admission law
└── shape/            # the shape sub-domain owners
    ├── fold.py       # folds shape ops through one entry
    └── codec.py      # decodes shape wire bytes at the seam
```

## [02]-[SEAMS]

A seam is cross-boundary by construction: an in-package relation is never a seam and lives in the codemap or the `[03]-[INTERNAL]` diagram. Each edge is one contract labeled `[KIND]: shape-name`, and a unit whose cross-boundary seams overflow one clean fence splits by counterpart group into a fence each.

<seam-graph diagram: home sub-domain owners in a subgraph, one node per counterpart package, edges kinded>
