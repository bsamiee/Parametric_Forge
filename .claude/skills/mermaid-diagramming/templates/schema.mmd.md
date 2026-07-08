# [SCHEMA]

Draw persistent entities and their relations. The template bakes in the schema discipline an unassisted attempt violates — every relationship edge has its FK attribute on the owning side and every FK has its edge, so the diagram and the storage constraint cannot disagree; cardinality states what storage enforces, never intended usage; and a many-to-many resolves through a visible junction entity carrying both FKs, because the crow's foot cannot express it directly. Use `erDiagram` with 4-7 entities around one aggregate root, typed attributes with `PK`/`FK` markers, and verb-labeled relations; the aggregate root is classed `primary`, the junction `recessed`, and an externally-owned registry `external` in its ER stroke-encoded form — dark fill, Cyan stroke and title — because a bright fill floods the attribute rows; the hierarchy the prose claims is the hierarchy the render shows. `erDiagram` takes no ELK, and this template holds the classic look — keep `theme: base` with its variable block. In-memory type relations are a class diagram, never a persistence schema.

```mermaid
---
config:
  theme: base
  look: classic
  themeVariables:
    darkMode: true
    fontFamily: "SF Mono, Menlo, Cascadia Mono, Segoe UI Mono, Consolas, monospace"
    useGradient: false
    dropShadow: "none"
    background: "#282A36"
    primaryColor: "#44475A"
    primaryTextColor: "#F8F8F2"
    primaryBorderColor: "#BD93F9"
    nodeBorder: "#BD93F9"
    lineColor: "#FF79C6"
    textColor: "#F8F8F2"
    tertiaryColor: "#21222C"
    edgeLabelBackground: "#21222C"
    attributeBackgroundColorOdd: "#282A36"
    attributeBackgroundColorEven: "#21222C"
  themeCSS: ".nodeLabel{font-size:12px}.name .nodeLabel{font-size:13px;font-weight:600}.edgeLabel .nodeLabel{font-size:12px;font-weight:500}.relationshipLine{stroke-width:2px}.edge-pattern-dashed{stroke-width:1.5px;stroke-dasharray:6 6}.marker path,.marker circle{transform:scale(.8);transform-origin:5px 5px}.marker circle{fill:#282A36}.node rect,.node path{stroke-width:1.5px;filter:none!important}.er.entityBox{filter:none}"
---
erDiagram
    accTitle: Artifact index schema
    accDescr: Runs issued by an owner yielding receipts and faults, consuming content-keyed artifacts through a junction, bound to an externally owned tool registry.
    OWNER ||--o{ RUN : issues
    RUN ||--|{ RECEIPT : yields
    RUN }o--|| REGISTRY : binds
    RECEIPT ||--o{ FAULT : records
    RUN ||--o{ RUN_ARTIFACT : consumes
    ARTIFACT ||--o{ RUN_ARTIFACT : feeds
    OWNER {
        uuid id PK
        string name
    }
    RUN {
        uuid id PK
        uuid owner_id FK
        uuid registry_id FK
        string state
    }
    RECEIPT {
        uuid id PK
        uuid run_id FK
        int code
    }
    REGISTRY {
        uuid id PK
        string version
    }
    FAULT {
        uuid id PK
        uuid receipt_id FK
        string reason
    }
    ARTIFACT {
        uuid id PK
        string content_key UK
    }
    RUN_ARTIFACT {
        uuid run_id PK, FK
        uuid artifact_id PK, FK
    }
    classDef primary fill:#44475A,stroke:#FF79C6,color:#F8F8F2
    classDef recessed fill:#21222C,stroke:#6272A4,color:#F8F8F2
    classDef external fill:#21222C,stroke:#8BE9FD,color:#8BE9FD
    class RUN primary
    class RUN_ARTIFACT recessed
    class REGISTRY external
```

Refill by renaming entities to the real aggregate, keep FK-edge reciprocity on every relation, resolve any many-to-many through a junction entity whose composite key is both FKs, and keep the root/junction/external classes on the entities that carry those roles. The frontmatter micro-scale `themeCSS` stamp, the ruled mono stack, and the `#21222C` label backing are fixed law — a refill renames entities, never strips the fidelity surface.
