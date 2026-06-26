# [H1][BRIDGE_RUNTIME]
>**Dictum:** *Native behavior is proven in the host that owns it.*

<br>

## [01]-[OWNERSHIP]

| [INDEX] | [BEHAVIOR]                                          | [OWNER]                           |
| :-----: | --------------------------------------------------- | --------------------------------- |
|  [01]   | Pure managed constructors, unions, SmartEnums, math | xUnit/CsCheck                     |
|  [02]   | Host document, viewport, command input, UI thread   | Runtime scenario                  |
|  [03]   | Host document, canvas, wires, editor events         | Runtime scenario                  |
|  [04]   | Runtime protocol/client/plugin behavior             | Runtime scenarios and tool checks |

## [02]-[RULES]

- Static specs may classify runtime-owned behavior, but must not pretend to execute it.
- Pair new runtime scenarios with owning source files through the repo runtime check command or run them through the repo runtime verify command.
- Place library-owned scenarios under the repo-declared scenario root.
- Keep scenarios source-only: no `#r`, no `#load`, and no absolute build-output paths.
- Host/package collisions are evidence. Investigate loaded host assemblies before weakening scenarios.
- Keep runtime output as JSON evidence plus captures under the repo-owned runtime artifact root.
- Static specs should treat host-native object creation, native validity, UI/document behavior, and host materialization as runtime-owned unless a current run proves the path is pure managed.
- Static specs still own managed input guards around those payloads: null/default validation, unsupported outputs, category shape, and no exception-shaped failures.
- Do not replace a runtime-owned success case with a weaker xUnit shape assertion. Add a scenario or record the exact executable gap.

## [03]-[RECLASSIFICATION]

When a host update or product change makes a previously runtime-owned API genuinely pure-managed, reclassify it back to static via the following audit:

1. Run the repo runtime check command and confirm the scenario passes without loading host-resolved types at the relevant call path.
2. Run the same behavior as a static xUnit spec; confirm the assertion succeeds in a clean managed process with no live host runtime.
3. If both pass, move the law into the static spec, delete the scenario or shrink it to the still-runtime-owned remainder, and update the ownership table plus repo test instructions if the change affects multiple owners.
4. Record the host version that enabled the reclassification in the spec or commit message; reclassifications are reversible if a later update reintroduces the host dependency.

Reclassifications are conservative by default: when in doubt, the behavior stays runtime-owned. The cost of a false-positive reclassification outweighs the cost of an over-strict runtime classification.

---
## [04]-[SCENARIO_GROUPING]
>**Dictum:** *Runtime handshakes are expensive; amortize via thematic grouping.*

<br>

Every runtime verify invocation pays host startup and scenario setup cost. N independent scenario files cost N × handshake; grouping K related scenarios into one file costs 1 × handshake + K × scenario body.

| [PATTERN]                | [EXAMPLE]                                                            |
| ------------------------ | -------------------------------------------------------------------- |
| One scenario per concern | `<mesh-topology-scenario>` (one topology check only)                 |
| Thematic group           | `<mesh-topology-validity-scenario>` (topology + validity predicates) |

Group when scenarios:
- Share the same fixture geometry (one cube/tetrahedron loaded once, reused for 4-6 assertions).
- Cover related production code paths that are all native predicates on the same host object.
- Have similar performance cost (do not group a 50ms predicate with a 30s eigendecomposition).

Do NOT group when:
- A scenario's failure must be triagable without parsing N other assertions in the same evidence file.
- The fixture setup for one scenario is incompatible with another (different document units, conflicting active views).
- The grouped file would exceed 200 LOC — split into thematic subgroups.

Evidence channel: grouped assertions populate a shared fact bag through the repo scenario harness. When a grouped scenario fails, the runtime evidence JSON shows the predicate that threw plus the full fact dictionary collected before the throw.

---
## [05]-[SCENARIO_LOC_GUIDANCE]

| [TYPE]                  | [TARGET_LOC] | [NOTES]                                                                |
| ----------------------- | ------------ | ---------------------------------------------------------------------- |
| Single-concern scenario | 30-80        | Fixture setup + 1-2 assertions + `facts.Add` lines.                    |
| Thematic group          | 80-200       | 4-8 assertions over shared fixture, all wrapped in one `Scenario.Run`. |
| Hard cap per file       | 250          | Above 250, split into thematic subgroups.                              |

Use the repo scenario helpers to keep boilerplate compact. Adding scenario helpers is permitted when the helper has 2+ scenario consumers across different specs.
