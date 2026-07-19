# [SCHEMA]

Draw persistent entities and their relations. Template law bakes in the schema discipline an unassisted attempt violates — every relationship edge has its FK attribute on the owning side and every FK has its edge, drawn so the diagram cannot disagree with the DDL; cardinality states what storage enforces, never intended usage; the stroke is a dependency claim, not typography — solid `--` marks an identifying relation whose FK sits inside the child's PK, dashed `..` marks a non-identifying relation whose FK is a plain column; and a many-to-many resolves through a visible junction entity carrying both FKs in its composite key, because the crow's foot cannot express it directly. A polymorphic association — one `subject_id` discriminated over N parents — is the other shape crow's foot cannot draw: split it into concrete owner tables with one real FK-edge each, or carry the bare discriminator pair with no FK marker and the union stated in prose, never two mandatory edges asserting a join that storage does not enforce. Use `erDiagram` with 4-7 entities around one aggregate root, typed attributes with `PK`/`FK`/`UK` markers including the compound `PK, FK` form, and verb-labeled relations; the aggregate root is classed `primary`, the junction `recessed`, and an externally-owned registry `external` in its ER stroke-encoded form — dark fill, Cyan stroke and title — because a bright fill floods the attribute rows; the hierarchy the prose claims is the hierarchy the render shows. `erDiagram` takes no ELK, and this template holds the classic look — keep `theme: base` with its variable block. In-memory type relations are a class diagram, never a persistence schema.

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
    accDescr: Runs issued by an owner yielding receipts and faults, consuming content-keyed artifacts through an identifying junction, bound to an externally owned tool registry, with non-identifying relations dashed.
    OWNER ||..o{ RUN : issues
    RUN ||..|{ RECEIPT : yields
    RUN }o..|| REGISTRY : binds
    RECEIPT ||..o{ FAULT : records
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

Refill by renaming entities to the real aggregate, keep FK-edge reciprocity on every relation, dash every relation whose FK sits outside the child's PK — here only the junction's two edges stay solid, because `run_id` and `artifact_id` are its composite key — resolve any many-to-many through such a junction, and keep the root/junction/external classes on the entities that carry those roles. Frontmatter micro-scale `themeCSS` stamp, the ruled mono stack, and the `#21222C` label backing are fixed law — a refill renames entities, never strips the fidelity surface.
