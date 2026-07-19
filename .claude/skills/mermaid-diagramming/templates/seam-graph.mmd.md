# [SEAM_GRAPH]

Draw who exchanges what shape across a package boundary. A seam edge is cross-boundary by construction: the home package's sub-domain owner on one side, a counterpart package on the other. An in-package relation — home sub-domain to home sub-domain — is never a seam; it lives in the codemap or an internal-flow diagram. Every edge is one contracted shape labeled `"[KIND]: shape-name"` from the KIND vocabulary `[WIRE] [SHAPE] [PORT] [BOUNDARY] [IMPORT] [RECEIPT] [CONTENT_KEY] [GRADUATION] [TESSELLATION] [FAULT] [PROJECTION] [TRANSPORT]`, so an unkinded edge is an unowned contract; a new kind joins the vocabulary by taking a seat on its nearest rail family, never by riding unrailed. A bidirectional edge exists only where a real inverse contract exists, and the counterpart mirrors the same edge verbatim in its own seam graph, so the label is shared law, not local prose. Each label carries the canonical wire name only — never a method chain, sub-path, or "via" clause; the owning page carries the bytes.

A seam graph is partner-package grain, not row grain: the home `subgraph` holds only the sub-domain owners that carry a cross-boundary seam, and each counterpart is one node named by its package, never a sub-path. Multiple contracts between one sub-domain and one partner collapse to a single edge at the load-bearing kind — the owning page's prose enumerates the rest. Node shape encodes counterpart role, `classDef` encodes it in color: a data store rides the cylinder `[( )]` and `data`; a bidirectional peer rides the hexagon `{{ }}` and `external`; a pure-sink peer rides the stadium `([ ])` and `recessed`. A pure source has no reversed-arrow form — flowchart rejects `<--`, so a source counterpart is always the edge source (`Source e@--> Owner`) and lands left of the home subgraph unless a split isolates sources. Home owners ride the rectangle `[ ]` and `primary`.

Each KIND selects the edge rail through one total map, bound insertion-stably by an edge-id class — never `linkStyle`, whose positional indices drift on every edge insertion. Data-bearing kinds (`[WIRE] [CONTENT_KEY] [GRADUATION] [TESSELLATION]`) ride Orange `edgeData`; `[RECEIPT]` rides Green `edgeSuccess`; `[FAULT]` rides Red `edgeError`; boundary-crossing delivery (`[PROJECTION] [TRANSPORT]`) rides Cyan `edgeExternal`; the control kinds (`[SHAPE] [PORT] [BOUNDARY] [IMPORT]`) share Pink `edgeControl` and lean on the label to disambiguate — so the label's law and the stroke's law agree, and every seam edge carries an explicit rail. Where one seam genuinely streams live traffic, that one edge carries `animate: true` — here the host wire — and a second animated edge dilutes the claim. Never `elk.mergeEdges`, which fuses same-target rails into one arrowhead and erases the kind semantics this archetype exists to carry.

One fence renders clean — no edge-over-node, few crossings. Crossing control starts at declaration order: group counterparts beside the owners they attach to and keep a shared counterpart adjacent to both, but the primary cure is the split, never ELK knobs. A package whose cross-boundary seams overflow one clean fence splits by counterpart group into two fences, each answering one question and carrying its own frontmatter and `accTitle` — the natural partition is peer-role (domain peers versus platform and cross-runtime peers) or same-branch versus cross-branch. A layer-permission question is strata, never a seam registry.

```mermaid
---
config:
  theme: base
  look: classic
  layout: elk
  flowchart:
    curve: linear
    padding: 25
  themeVariables:
    darkMode: true
    fontFamily: "SF Mono, Menlo, Cascadia Mono, Segoe UI Mono, Consolas, monospace"
    useGradient: false
    dropShadow: "none"
    background: "#282A36"
    primaryColor: "#44475A"
    primaryTextColor: "#F8F8F2"
    primaryBorderColor: "#BD93F9"
    lineColor: "#FF79C6"
    textColor: "#F8F8F2"
    clusterBkg: "#21222C"
    clusterBorder: "#D6BCFA"
    edgeLabelBackground: "#21222C"
    labelBackgroundColor: "#21222C"
    titleColor: "#D6BCFA"
  themeCSS: ".nodeLabel{font-size:13px;font-weight:500}.edgeLabel{font-size:12px;font-weight:500}.cluster-label .nodeLabel{font-size:13.5px;font-weight:700;letter-spacing:.08em}.edge-thickness-normal{stroke-width:2px}.edge-thickness-thick{stroke-width:3px}.edge-pattern-dashed,.edge-pattern-dotted{stroke-width:1.5px;stroke-dasharray:4 6}.node rect,.node circle,.node polygon,.node path,.node .outer-path{stroke-width:1.5px;filter:none!important}.cluster rect{stroke-width:1px!important;stroke-dasharray:5 4!important;filter:none!important}.marker path{transform:scale(.8);transform-origin:5px 5px}.marker circle{transform:scale(.48);transform-origin:5px 5px}.edgeLabel rect{transform-box:fill-box;transform-origin:center;transform:scale(1.1,1.2)}"
---
flowchart LR
    accTitle: Core package seam registry
    accDescr: Core sub-domain owners exchanging kinded shapes with persistence, compute, the host boundary, and the app shell, edge rails colored by kind, nodes classed by seam direction, and the live host wire animated.
    subgraph core[CORE]
        Semantic[Semantic model]
        ElementSet[Element set]
        Wire[Core wire]
    end
    Persistence[(Persistence)]
    Compute{{Compute}}
    Host{{Host boundary}}
    AppUi([AppUi])
    Persistence e1@-->|"[CONTENT_KEY]: XxHash128"| Semantic
    Wire e2@<-->|"[WIRE]: CoreWire"| Host
    Wire e3@-->|"[TESSELLATION]: GlbChunk"| Persistence
    ElementSet e4@<-->|"[GRADUATION]: ElementSnapshot"| Compute
    Compute e5@-->|"[RECEIPT]: SolveReceipt"| Wire
    Wire e6@-->|"[FAULT]: FaultRow"| AppUi
    Semantic e7@-->|"[PROJECTION]: ViewModel"| AppUi
    Host e8@-->|"[TRANSPORT]: Frame"| AppUi
    ElementSet e9@-->|"[PORT]: SelectPort"| Persistence
    Semantic e10@-->|"[SHAPE]: SemanticModel"| Compute
    ElementSet e11@-->|"[BOUNDARY]: SelectionGate"| Host
    Host e12@-->|"[IMPORT]: CoreWireCodec"| Wire
    e2@{ animate: true }
    classDef primary fill:#44475A,stroke:#FF79C6,color:#F8F8F2
    classDef external fill:#8BE9FDBF,stroke:#8BE9FD,color:#282A36
    classDef data fill:#FFB86CBF,stroke:#FFB86C,color:#282A36
    classDef recessed fill:#21222C,stroke:#6272A4,color:#F8F8F2
    classDef edgeData stroke:#FFB86C,color:#F8F8F2
    classDef edgeSuccess stroke:#50FA7B,color:#F8F8F2
    classDef edgeError stroke:#FF5555,stroke-width:3px,color:#F8F8F2
    classDef edgeExternal stroke:#8BE9FD,color:#F8F8F2
    classDef edgeControl stroke:#FF79C6,color:#F8F8F2
    class Semantic,ElementSet,Wire primary
    class Compute,Host external
    class Persistence data
    class AppUi recessed
    class e1,e2,e3,e4 edgeData
    class e5 edgeSuccess
    class e6 edgeError
    class e7,e8 edgeExternal
    class e9,e10,e11,e12 edgeControl
```

Refill by renaming owners and counterparts to the real packages, keep every label `[KIND]: shape-name` with the shape's exact wire name, bind each edge to its kind's rail class, and land the mirrored edge in the counterpart's graph in the same change — `eN@` ids and their `class eN edge<Rail>` bindings survive insertions without recounts.
