---
name: rhino-mcp
user-invocable: false
description: >-
  Drives the McNeel Rhino-MCP-Platform `mcp__rhino-mcp-platform__*` tools for interactive Rhino host work:
  slot lifecycle, run_csharp/run_python scripting, headless document IO, scene query/selection, viewport
  capture, and GH2 Grasshopper graph authoring. Use when an agent must explore, script, inspect, or
  build geometry inside a live Rhino session through MCP. Not for deterministic verification (use the
  rhino-bridge) and not for authoring the Rasm.AppHost MCP server.
---

# [H1][RHINO-MCP]

Drives McNeel `Rhino-MCP-Platform` through the `mcp__rhino-mcp-platform__*` tool surface (the bridge README `[INSTALL]` owns the pinned platform version). The router (`rhino-mcp-router`, USER-scope stdio server in `~/.claude.json`) proxies each call to a per-document loopback HTTP listener inside the targeted Rhino "slot". Every document-touching tool is bound to that slot's `RhinoDoc`, never `RhinoDoc.ActiveDoc`. All outputs are JSON strings (viewport adds a JPEG block).

[IMPORTANT] The `rhino-mcp-router` wrapper gates the vendor router behind a live Rhino: with Rhino down the server exposes only a `rhino_status` tool. Start Rhino (`open -a RhinoWIP`), then reconnect the `rhino-mcp-platform` server (`/mcp` -> reconnect, or a fresh session) to load the full toolset — a stdio MCP connection never re-spawns on its own.

[IMPORTANT] This platform is `additive_external` and STANDALONE. It shares one live RhinoWIP session with the Rasm rhino-bridge but the two never couple: the bridge suppresses this platform's listener autostart (`RHINO_MCP_AUTOSTART_PORT=0`) and only reports its presence as `mcp.platform.version` / `mcp.listener` capability facts. The bridge is the deterministic typed-verification boundary; this platform is the interactive conversational host. Use MCP for exploration, scripting, and graph authoring; never as a substitute for `[RhinoScenario]` closure.

## [01]-[WHEN_TO_USE_MCP_VS_BRIDGE]

| [INTENT]                                         | [SURFACE]                                             |
| ------------------------------------------------ | ----------------------------------------------------- |
| Explore host state, script ad-hoc geometry/IO    | MCP (`run_csharp`/`run_python`)                       |
| Author/inspect a Grasshopper graph interactively | MCP (`g2_*`)                                          |
| Visually inspect a scene, drive camera           | MCP (`get_viewport_image`, camera)                    |
| Reproducible, typed, gated host verification     | rhino-bridge `[RhinoScenario]`                        |
| Build the Rasm capability-registry MCP server    | `libs/csharp/Rasm.AppHost` (unrelated SDK projection) |

[IMPORTANT] Keep MCP idle during ANY bridge cycle that holds the session — `build`/`status`/`verify`/`quit`/deploy/publish — not only `verify`. MCP `run_csharp`/`run_python`/`run_command` drive `RhinoApp` command history and inject foreign lines into the same `command.history.tail` / `command.capture.tail` evidence the bridge spools, contaminating per-scenario evidence. Run interactive MCP exploration strictly before or after the bridge holds the session, never concurrently. This rule extends conditionally to `Rasm.AppHost`: its MCP server is host-neutral capability projection and stays outside the contamination hazard, but any AppHost tool that drives a live Rhino host through its `ComputeIntent` acquires the same liability and the same idle-during-bridge-lease discipline.

[IMPORTANT] Promotion path: MCP observation -> typed `[RhinoScenario]` -> authoring certificate -> reviewed `ReferenceEvidence` -> `bridge verify`. MCP is the microscope; the bridge certificate and reviewed references are the proof boundary.

## [02]-[SLOT_LIFECYCLE]

Every non-router tool accepts an implicit `slot` arg (animal-name ID). Omitting it uses the last-used/open Rhino, auto-spawning one only if none is running. Slot state is lazy and stateful — `list_slots` is what prunes crashed Rhinos and adopts user-started ones since the last call.

| [TOOL]       | [DOES]                                                        | [KEY_IO]                                                                    |
| ------------ | ------------------------------------------------------------- | --------------------------------------------------------------------------- |
| `spawn_slot` | Launch a new Rhino, return its slot ID                        | → `{ slotId }`; pass `slot` on later calls                                  |
| `list_slots` | List running slots; prunes crashed, adopts user-started       | → `payload[]` (`slotId, port, autoSpawned, crashReportPath`)                |
| `close_slot` | Close a spawned slot (stops listener, closes doc, saves none) | → `payload.closed`; `error.code` ∈ `slot_not_found`, `cannot_close_adopted` |

[IMPORTANT] Poll `list_slots` before assuming a held `slot` is live. Adopted (user-started) slots return `cannot_close_adopted` and are non-disposable — treat them as borrowed, never force-close them.

## [03]-[SCRIPTING]—[RUN_CSHARP/PYTHON/COMMAND]

The universal escape hatch: full RhinoCommon scoped to the slot's doc, stdout/error captured.

| [TOOL]         | [INPUT]   | [OUTPUT]                                           |
| -------------- | --------- | -------------------------------------------------- |
| `run_python`   | `script`  | `{stdout, error}`; error null on success           |
| `run_csharp`   | `script`  | `{stdout, error}`                                  |
| `run_command`  | `command` | command-window text (e.g. `"_Box 0,0,0 10,10,10"`) |
| `get_commands` | `filter?` | newline list of English command names (cap 200)    |

[IMPORTANT] `run_csharp` evaluates a STATEMENT BODY, not an expression — a top-level `return <expr>;` is rejected. Emit results through `Console.WriteLine(...)`; never write an expression-returning lambda.

[IMPORTANT] Both scripting tools inject `__rhino_doc__` (the slot's `RhinoDoc`). Use it directly. In Python do NOT use `scriptcontext.doc` or `rhinoscriptsyntax`'s implicit doc — they bind to the wrong document. In C# operate on `__rhino_doc__`.

[IMPORTANT] `error: null` is necessary but NOT sufficient for success: error detection is heuristic string-matching (`Traceback`, `error CS`, `Compile Error`, `Exception:`) over scraped command-window text, so a silent failure or a no-op can read as success. Assert post-conditions explicitly — re-query `g2_get_canvas_graph` / `list_objects` / the written `.3dm` — rather than trusting a null error. Capture is fire-and-harvest, not streaming: always `print` / `Console.WriteLine` explicit, self-serialized structured results; never rely on return-value capture. `run_command` hard-blocks if a prior command awaits interactive input — prefer scripting over `run_command` for any non-trivial geometry to avoid stranding a slot in an interactive prompt.

## [04]-[DOCUMENT_IO]

Headless, no dialogs. All bound to the slot's doc.

| [TOOL]      | [INPUTS]                         | [OUTPUT]                                                              |
| ----------- | -------------------------------- | --------------------------------------------------------------------- |
| `open_doc`  | `path` (abs), `clearFirst=false` | import/merge; zoom-extents all views; → `{path, imported, cleared}`   |
| `save_doc`  | `path` (.3dm abs)                | overwrite with WriteUserData, dialogs suppressed; → `{path, objects}` |
| `close_doc` | `path?`                          | save-then-close if path given, else discard; → status string          |

## [05]-[SCENE_QUERY_SELECTION_MATERIALS]

| [INDEX] | [TOOL]               | [INPUT_SCOPE]        | [OUTPUT_SCOPE]              |
| :-----: | :------------------- | :------------------- | :-------------------------- |
|  [01]   | `list_objects`       | object filters       | object query payload        |
|  [02]   | `get_selection`      | —                    | selected object payload     |
|  [03]   | `set_selection`      | selection filters    | selection count and warning |
|  [04]   | `set_layer_material` | layer material write | material status             |

[SCENE_QUERY_SHAPES]:
- Filters: `names[]?`, `layer?`, `geometryType?`, `includeHidden=false`, `includeLocked=true`, `limit=1000`.
- Object item: `{id, name, layer, type}`.
- Selection write: `ids[]?`, `names[]?`, `layer?`, and `geometryType?` select a union after clearing current selection.
- Material write: `layer`, `color?`, `transparency?` 0-1, `gloss?` 0-1, and `applyToLayerColor=true`.
- `geometryType` vocabulary: `point`, `pointset`, `curve`, `surface`, `brep`, `mesh`, `annotation`, `light`, `block`.

## [06]-[VIEWPORT_AND_CAMERA]

| [INDEX] | [TOOL]               | [INPUT_SCOPE]        | [OUTPUT_SCOPE]           |
| :-----: | :------------------- | :------------------- | :----------------------- |
|  [01]   | `get_viewport_image` | viewport capture     | metadata plus JPEG block |
|  [02]   | `set_camera`         | camera or bbox frame | active viewport camera   |
|  [03]   | `zoom_to_layer`      | layer path           | layer union bbox zoom    |
|  [04]   | `zoom_to_object`     | object GUIDs         | object union bbox zoom   |

[VIEWPORT_CAPTURE_SHAPE]:
- Size: `width=480` up to `1280`, `height=270` up to `720`.
- Frame inputs: `view?`, `displayMode?`, `cameraLocation?`, `target?`, `boxMin?`/`boxMax?`, `zoom?`.
- Output: JSON metadata plus JPEG when the scene is renderable; metadata-only diagnostic when empty or off-screen.
- Camera write: `location?`, `target?`, `up?`, `lensLength?`, `projection?`, and `boxMin?`/`boxMax?`; bbox framing applies last.

[IMPORTANT] On an empty/off-screen capture, read `scene.boundingBox` and object counts before re-framing with `boxMin`/`boxMax` or `view`. The JPEG block costs context tokens: capture at the minimum resolution sufficient to diagnose, keep the `480x270` default first, and escalate toward the `1280x720` ceiling only after a metadata-only pass.

## [07]-[GRASSHOPPER_GRAPH_AUTHORING]-[g2_*]

`g2_*` is the Grasshopper graph-authoring surface for Rasm MCP work. It authors `Grasshopper2` canvas and document objects through McNeel's interactive MCP platform; bridge scenarios remain the typed verification boundary.

[GH_KERNEL_RULES]:
- Kernel: `g2_*` uses `Grasshopper2` canvas and document objects.
- Solve: mutating GH2 tools accept `solve=true`; set `solve=false` while batching and solve once after the batch.
- Explicit solve: use `g2_solve_canvas` for solve/status readback.
- Slider policy: GH2 sliders use `decimals` `0..12`; `0` gives integer behavior.

[GH_COMPONENT_SHAPES]:
- Component search: `query`, `category?`, `subcategory?`, and `limit=20` return `Guid`, `Name`, `Category`, `SubCategory`, `Kind`, and `Description`.
- Component description: `g2_describe_component` returns `Inputs[]` and `Outputs[]` parameter records with `Name`, `UserName`, `Description`, `TypeName`, `Access`, and `Requirement`.

Discovery operations use GH2 component lookup and port-inspection tools:

| [INDEX] | [TOOL]                  | [INPUT_SCOPE]   | [OUTPUT_SCOPE]        |
| :-----: | :---------------------- | :-------------- | :-------------------- |
|  [01]   | `g2_start`              | -               | canvas startup        |
|  [02]   | `g2_search_components`  | component query | component candidates  |
|  [03]   | `g2_describe_component` | component name  | port contract records |

Placement operations create canvas objects from component and slider inputs:

| [INDEX] | [TOOL]               | [INPUT_SCOPE]       | [OUTPUT_SCOPE]   |
| :-----: | :------------------- | :------------------ | :--------------- |
|  [01]   | `g2_place_component` | component selector  | placed component |
|  [02]   | `g2_place_slider`    | slider value policy | placed slider    |

[GH_GRAPH_BATCH_SHAPE]:
- Component placement: `selector` prefers `Guid`; `x=100`, `y=100`, and `solve=true` are default placement inputs.
- Slider placement: `min`, `value`, `max`, `x`, `y`, `decimals`, `solve`, and `name?` define the slider.
- Batch apply: `g2_apply_graph` accepts `sliders[]`, `components[]` with caller `Key`, `wires[]` with `SrcKey`/`DstKey`, and `solve=true`.
- Batch output: `g2_apply_graph` returns `Placed[]`, `PlaceErrors[]`, `Wires[]`, and `WiresOk` without aborting on per-step failures.

Wiring and solving operations connect objects, apply batches, and resolve the canvas:

| [INDEX] | [TOOL]            | [INPUT_SCOPE] | [OUTPUT_SCOPE]       |
| :-----: | :---------------- | :------------ | :------------------- |
|  [01]   | `g2_connect`      | single wire   | wire result          |
|  [02]   | `g2_connect_many` | wire batch    | batch wire result    |
|  [03]   | `g2_apply_graph`  | graph batch   | placement and wiring |
|  [04]   | `g2_solve_canvas` | solve policy  | solve status         |

[GH_CANVAS_READBACK_SHAPE]:
- Canvas readback: `g2_get_canvas_graph` accepts `include_data=true` and `sample_size=3`.
- Canvas payload: readback returns `Objects[]` and `Wires[]`; records carry `Messages[]`, input `Sources[]`, data summaries, and slider `DisplaySummary` where applicable.
- Canvas cleanup: `g2_clear_canvas` requires `confirm=true` and accepts `solve=true`.

Inspection and cleanup operations read or clear the current canvas:

| [INDEX] | [TOOL]                | [INPUT_SCOPE] | [OUTPUT_SCOPE] |
| :-----: | :-------------------- | :------------ | :------------- |
|  [01]   | `g2_get_canvas_graph` | readback      | graph payload  |
|  [02]   | `g2_clear_canvas`     | confirmation  | removal count  |

[IMPORTANT] Prefer `selector` by `Guid` from `g2_search_components`; a name match returning multiple candidates yields `{Error:"ambiguous", Candidates[]}`. Call `g2_describe_component` before placing or wiring to learn input and output ports. For closed-loop iteration, read back `g2_get_canvas_graph` because object `Messages[]` carry per-component warnings/errors and slider `DisplaySummary` carries computed values. Use `g2_apply_graph` to build a whole definition in one call; `g2_connect` and `g2_connect_many` accept numeric index, `Name`, `UserName`, or `DisplayName` for ports, and `""` or `"0"` for pure params such as sliders.

## [08]-[PRECONDITIONS]

[IMPORTANT] Assert the OFFICIAL McNeel platform, not the community `rhinomcp` fork. The official ship is assembly `RhinoMcpPlatform`, namespace `RhMcp`, with a pinned PlugIn GUID; the bridge's `bridge status` capability facts (`mcp.platform.version`, `mcp.listener`) match only the official platform. If `bridge status` reports the platform absent while these tools register, a fork is loaded — its behavior is not guaranteed by this skill. The bridge README `[10]-[INTEGRATIONS]` owns the full boundary contract.
