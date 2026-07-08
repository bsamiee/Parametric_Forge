---
name: ifc-bim
description: Inspect, query, validate, edit, and convert IFC/BIM building models. Use when working with .ifc files, IfcOpenShell, IFC schema entities, spatial or element structure, selector queries, relations, Psets/Qtos, GlobalIds, clash detection, quantity takeoff, cost or work schedules, IDS/ifctester validation, geometry tessellation, 2D plots or 3D renders, or exporting IFC to GLB/OBJ/glTF/DAE/STEP. Covers a live in-memory model (load once, then query and edit across calls) and deterministic batch file-to-file conversion, validation, and extraction. Not the system of record for the Rasm BimModel semantic graph, which C#/Rasm.Bim owns.
---

# IFC and BIM tooling

Two surfaces own IFC work, chosen by task. The `ifc` MCP (the official IfcOpenShell server, launched by `forge-ifcmcp`) holds one model in memory across calls for live query and edit. The `ifcopenshell` batch CLI runs deterministic file-to-file conversion, validation, and extraction with no session. Reach for the MCP to investigate a model; reach for the CLI to produce an artifact.

## Surface selection

Pick the lowest tier that does the job:

1. `ifc` MCP — live inspection or edit of a loaded model. `ifc_load` once, then query and edit across calls against the in-memory model; `ifc_save` to persist. The default for ad-hoc element, property, spatial, and geometry questions.
2. `ifcopenshell` CLI — batch convert, validate, or extract to a file.
3. `ifcopenshell` Python API — an operation with no MCP tool and no CLI: a `forge-companion-env uv run` script against `import ifcopenshell`.

## The ifc MCP

One model is held in memory across calls. Load first, then operate.

- Session: `ifc_new` (schema, default `IFC4`), `ifc_load` (path), `ifc_save` (path), `ifc_reset`.
- Inspect: `ifc_summary`, `ifc_tree`, `ifc_info` (`element_id`), `ifc_select` (ifcopenshell selector query), `ifc_relations` (`element_id`, `traverse`), `ifc_contexts`, `ifc_materials`, `ifc_list` (`module`), `ifc_schema` (`entity_type`).
- Analyze: `ifc_validate` (`express_rules`), `ifc_quantify` (`rule`, `selector`), `ifc_clash` (`element_id`, `clearance`, `tolerance`, `scope`), `ifc_schedule`, `ifc_cost`.
- Author: `ifc_edit` (`function_path`, `params`) dispatches the `ifcopenshell.api` mutation surface; read `ifc_docs` (`function_path`) for the signature before the edit.
- Geometry: `ifc_shape_list`/`ifc_shape_docs`/`ifc_shape` for geometry-evaluation methods, `ifc_plot` (2D floorplan, elevation, or section as PNG/SVG), `ifc_render` (3D PNG).

## The ifcopenshell batch CLI

`ifcopenshell` ships no cp315 wheel — every CLI tool runs through the cp312 companion lane: `forge-companion-env uvx --from ifcopenshell <tool> <args>`.

- `IfcConvert` — tessellate IFC geometry to GLB, OBJ, glTF, DAE, or STEP. Tessellation tolerances are `--deflection` and `--angular-tolerance`.
- `ifctester` — validate a model against an IDS file and emit verdict rows.
- `ifccsv` — extract or write properties as CSV or XLSX.
- `ifcpatch` — recipe-driven transforms (merge, split-by-storey, IFC2SQL, vendor fixups).
- `ifcdiff` — structural diff of two models.
