# [<architecture-title-token>]

<domain-map-lead-2-3-sentences>

## [01]-[CHARTER]

- <owning-subject-owns-invariant-law>
- The resolver mints every content key and owns the one-key-per-content invariant.

## [02]-[TOPOLOGY]

```text codemap
core/
├── resolver.py       # mints content keys; owns the resolve dispatch
├── registry.py       # holds the descriptor registry and admission law
└── shape/            # the shape sub-domain owners
    ├── fold.py       # folds shape ops through one entry
    └── codec.py      # decodes shape wire bytes at the seam
```

## [03]-[SEAMS]

```mermaid
---
config:
  layout: elk
  look: neo
  theme: base
---
flowchart LR
    accTitle: Unit seam registry
    accDescr: Home unit sub-domain owners exchanging kinded shapes with external counterparts by seam direction.
    subgraph core[core unit]
        Resolver[Resolver]
        Registry[Registry]
    end
    DataStore[(data)]
    Registry -->|"[SHAPE]: Descriptor"| Resolver
    Resolver <-->|"[WIRE]: RowBatch"| DataStore
    classDef home fill:#44506b,stroke:#8b9bc4,color:#ffffff
    classDef biseam fill:#2f7d5b,stroke:#5cc79a,color:#ffffff
    class Resolver,Registry home
    class DataStore biseam
```
