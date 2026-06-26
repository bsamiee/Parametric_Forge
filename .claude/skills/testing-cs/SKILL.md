---
name: testing-cs
description: >-
  Builds and reviews dense adversarial law-matrix C# specs using xUnit v3, CsCheck,
  the active repo testkit, coverlet, Stryker, Verify, ArchUnitNET, BenchmarkDotNet,
  SharpFuzz, and host/runtime scenarios. Use when creating, refactoring, or
  validating C# tests, testkit code, test docs, benchmark/fuzz harnesses, or
  runtime verification.
---

# [H1][TESTING_CS]
>**Dictum:** *A test is an adversarial law with an independent oracle, not confirmation of current output.*

<br>

Use this skill with `coding-csharp` for `.cs` specs/testkit code, `coding-bash` for scripts, and repository documentation standards for Markdown. The canonical unit rail is xUnit v3/MTP + CsCheck + the active repo testkit; host-native runtime behavior belongs in the repo-declared runtime scenario rail. Managed tests attempt falsification through independent oracles, mutation-visible rows, failure categories, model/metamorphic relations, receipt tampering, and raw-payload laws.

---
## [01]-[WORKFLOW]
>**Dictum:** *Classify first; falsify with fewer, stronger laws second.*

<br>

1. Read the owning production file and its sibling tests.
2. Classify each behavior as static-managed or runtime-owned native/host behavior.
3. Inventory public APIs, union/SmartEnum cases, failure categories, output projections, native calls, and receipt metadata before writing assertions.
4. Select laws from [oracles-laws.md](references/oracles-laws.md) and density axes from [density-axes.md](references/density-axes.md).
5. Reuse active repo testkit contracts from [testkit.md](references/testkit.md).
6. Check raw tool API in `docs/stacks/csharp/testing-libs` before using unfamiliar APIs.
7. Check the repo-declared platform/API owner before changing serializers, fuzz parsers, runtime probes, host loaders, filesystem evidence, capture code, or standard-library API usage in tests.
8. Write the spec from [unit-pbt.spec.template.md](templates/unit-pbt.spec.template.md).
9. Validate with scoped cleanup first, then targeted build/test proof for touched rails.

---
## [02]-[RAILS]
>**Dictum:** *Runtime ownership is executable proof, not a documentation escape hatch.*

<br>

| [INDEX] | [RAIL]           | [LOCATION]                                                  | [OWNS]                                                                                                           |
| :-----: | ---------------- | ----------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
|  [01]   | Static spec      | `tests/csharp/libs/<Project>/<MirrorPath>/<Source>.spec.cs` | Pure managed constructors, smart enums, unions, matrix/math rails, `Fin`/`Validation`, deterministic algorithms. |
|  [02]   | Testkit          | `tests/csharp/_testkit`                                     | Universal law adapters, reusable generators, independent numeric oracles, serializers.                           |
|  [03]   | Runtime scenario | `<repo-scenario-root>/<Project>/<MirrorPath>/scenarios/*`   | Host runtime APIs, native validity, UI marshaling, document/canvas behavior.                                     |
|  [04]   | Mutation         | `<test-runner> --mutation changed                           | full`                                                                                                            | Explicit Stryker MTP survivor discovery for the configured managed target. |
|  [05]   | Architecture     | `tests/csharp/_architecture`                                | Assembly dependency direction and cycle laws.                                                                    |
|  [06]   | Tooling snapshot | `tests/csharp/_tooling`                                     | Stable generated/config artifacts through Verify.                                                                |
|  [07]   | Benchmark        | `tests/csharp/_benchmarks`                                  | Managed hot-path measurement outside xUnit.                                                                      |
|  [08]   | Fuzz             | `tests/csharp/_fuzz`                                        | Pure managed parser/token harnesses outside xUnit.                                                               |

[CRITICAL]:
- Do not move native behavior into static xUnit just to improve coverage.
- Do not document a runtime gap when an executable scenario can own it.
- Do not add test-specific shared helpers. Promote only universal higher-order capability with at least two real consumers.
- Treat testkit additions as law/oracle/generator functionality, not extraction. Shared code must replace repeated spec logic with stronger evidence, not shorter spelling.
- Treat shape-only assertions as Grade D unless paired with a Grade A/B oracle or a durable Grade C failure/category rail.
- Delete or replace shape-only assertions that only inspect values constructed inside the same test.
- Pair every declared `Output`/accepted `TOut` surface with an actual projection law. Metadata-only output checks do not prove dispatch.
- Public union cases, record structs, and policy records that bypass factory methods need default-invalid/raw-payload laws or must be made unconstructable by design.
- Mixed guards must preserve categories: invalid input stays `Input`/`Tolerance`; unsupported capability stays `Unsupported`.
- Paired raw/domain outputs both need laws, for example `Vector3d` and `Direction`, receipt and geometry, scalar and value-object projections.
- Do not use `.IsSucc`, `.IsFail`, `.IsSome`, or `.IsNone` as primary proof; use `Spec.Succ`, `Spec.FailCategory`, `Spec.Valid`, `Spec.Invalid`, `Spec.Some`, or `Spec.None`.
- Classify each Stryker survivor before test edits: missing oracle, equivalent mutant, runtime-owned path, or product bug.
- Keep `ConcurrentDictionary`, `Interlocked`, `Directory`, `Path`, `Console.WriteLine`, and platform drawing APIs inside explicit test/tool/runtime boundary adapters.
- If a repo declares a static-vs-runtime classification list, treat it as the owner for that surface; static specs own pure managed laws and managed input guards, while native success belongs in runtime scenarios.

---
## [03]-[SCENARIOS]
>**Dictum:** *Scenario files are source-only runtime laws owned by tests.*

<br>

Place runtime scenarios beside the relevant test slice under the repo-declared scenario root. The runtime rail maps that convention to the owning project; do not add manifests, catalogs, app-local scenario folders, or per-scenario path maps unless the repo scenario owner requires them.

Use the repo-declared scenario harness and injected scenario metadata. Do not declare or shadow harness-provided variables. Populate evidence through the harness-owned fact channel, and throw with observed values for failed predicates.

[CRITICAL]:
- Keep scenarios deterministic: clear or create only the document state they own, use constants instead of randomness/time/I/O, redraw before capture, and add a `facts.Add(...)` for every runtime fact that would be hard to infer from the exception alone.
- Do not bypass the scenario harness with ad hoc fact emitters or `Console.WriteLine("key=value")` evidence lines; the harness-owned evidence channel is the canonical fact wire format.
- Do not add `#r`, `#load`, absolute build-output paths, legacy bridge job files, or retired script-server flow.
- Do not treat missing endpoint metadata as missing scenario data. Use the repo-declared runtime health command.
- Do not propose headless, containerized, or simulated host substitutes for a repo-declared live host scenario rail.
- Capture paths live under the repo-owned runtime artifact directory.
- When a scenario uses viewport evidence, set the active view and redraw before capture.

---
## [04]-[SPEC_SHAPE]
>**Dictum:** *One generated input should exercise many assertions.*

<br>

| [INDEX] | [RULE]            | [DETAIL]                                                                                                                                                                                     |
| :-----: | ----------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|  [01]   | LOC               | Target 175 LOC per normal spec; 176-225 when one owning source file has multiple real concepts and the result is denser than a split. Testkit files may reach 350 LOC.                       |
|  [02]   | Layout            | Imports, namespace, `[CONSTANTS]`, `[ALGEBRAIC]`, optional `[EDGE_CASES]`.                                                                                                                   |
|  [03]   | Classes           | Public xUnit test classes; spec-local generator classes stay non-public unless discovery requires public visibility.                                                                         |
|  [04]   | Attributes        | `[Fact]`/`[Theory]` on their own line. No local analyzer suppressions for normal test shape.                                                                                                 |
|  [05]   | Generators        | Route reusable value-object generators through production factories. Avoid parallel constructors. Use `Gen.Where(...).Select(...)`, never `Select+throw` — `throw` breaks CsCheck shrinking. |
|  [06]   | Names             | PascalCase law names; no underscores.                                                                                                                                                        |
|  [07]   | Polymorphic-first | Before writing a second `[Fact]` that shares setup with an existing one, reach for a polymorphic pattern from [density-axes.md `[4][POLYMORPHIC_PATTERNS]`](references/density-axes.md).     |

[CRITICAL]:
- A spec is not strong because it has many facts. It is strong when one generated domain attacks construction, projection, unsupported outputs, failure categories, receipt invariants, and an independent oracle without mirroring production code.
- A real oracle predicts behavior from an independent source: closed-form math, conservation, fixture geometry, category contract, runtime observation, or documented external behavior. A law varies a behavior family enough to catch swapped inputs, missing validation, unsupported outputs, and receipt drift.
- Use distinct generated payload values when a source function transports or dispatches multiple inputs. Equal or placeholder payloads hide swaps and ignored branches.
- Allow 225 LOC, and exceptionally 300 LOC, only when each added line buys a real oracle, boundary, runtime classification, or product-bug guard that cannot be compressed through the project testkit, local arrays, or product generators. Specs that exceed 225 LOC must document the per-section LOC delta justifying the overage.
- If a failing law reveals a real production bug, fix the owner. Do not weaken the law into shape-only proof.
- Hand-constructing a record type and asserting its own fields is Grade D mirror coverage. Migrate to a runtime scenario OR add an `IsValid` predicate law via `TheoryData<Record, bool>` (one valid row, each invariant individually broken).
- Filter `Spec.ForAll(Gen.OneOfConst([A,B,C]), ...)` shows as ONE Stryker mutation target. Convert to `[Theory][InlineData(A)][InlineData(B)][InlineData(C)]` (or `MemberData(...)` from `SmartEnum.Items`) when Stryker survivors include per-case logic — Theory rows give N separately-killable targets.

---
## [05]-[TOOL_RAIL]
>**Dictum:** *Tool knowledge lives in docs; specs use the small contract.*

<br>

| [INDEX] | [TOOL]          | [DOC]                                                    | [LOCAL_USE]                                                                   |
| :-----: | --------------- | -------------------------------------------------------- | ----------------------------------------------------------------------------- |
|  [01]   | xUnit v3        | `docs/stacks/csharp/testing-libs/xunit/api.md`           | MTP rail, assertions, fixtures, `TheoryData<T1..T15>`, generated runner JSON. |
|  [02]   | CsCheck         | `docs/stacks/csharp/testing-libs/cscheck/api.md`         | `Gen`, `Sample`, shrink/replay, model/metamorphic/parallel/perf APIs.         |
|  [03]   | coverlet        | `docs/stacks/csharp/testing-libs/coverlet/api.md`        | Opt-in managed coverage map.                                                  |
|  [04]   | Stryker.NET     | `docs/stacks/csharp/testing-libs/stryker/api.md`         | Explicit mutation through the local test runner.                              |
|  [05]   | Verify          | `docs/stacks/csharp/testing-libs/verify/api.md`          | Stable artifact snapshots only.                                               |
|  [06]   | ArchUnitNET     | `docs/stacks/csharp/testing-libs/archunit/api.md`        | Assembly boundary laws.                                                       |
|  [07]   | BenchmarkDotNet | `docs/stacks/csharp/testing-libs/benchmarkdotnet/api.md` | Benchmark console projects.                                                   |
|  [08]   | SharpFuzz       | `docs/stacks/csharp/testing-libs/sharpfuzz/api.md`       | Fuzz harness projects.                                                        |

Current local facts:

- Runner configuration is repo-owned; do not invent root runner files.
- There is no user-facing `IAssemblyFixture<T>` API; use `[assembly: AssemblyFixture(...)]` plus constructor injection.
- xUnit typed theory rows/data exist through arity 15.
- `Spec.Metamorphic` is a path/oracle wrapper over `Spec.ForAll`, not CsCheck `SampleMetamorphic`.
- Do not claim a `Check.Hash` cache path without inspecting the current package/source.
- Treat Stryker zero discovery as a failed mutation rail; the managed target is 95% after discovery proof.

---
## [06]-[VALIDATION]
>**Dictum:** *A failing law is evidence; investigate product behavior before weakening the test.*

<br>

Use the repo-declared gate appropriate to the touched surface:

```bash
<quality-router> static fix <touched-paths>
<quality-router> static build <touched-paths>
<test-runner> [<filter>] [--target <test-project>]
<runtime-runner> verify <scenario-or-glob>
```

Default test runs execute unit tests only unless the repo quality router declares otherwise. Use explicit mutation flags for Stryker on the configured managed pair.

Runtime ownership proof:

```bash
<runtime-runner> check <source.cs> <scenario>
```

Runtime scenarios are source-only unless the repo scenario owner declares otherwise. Do not add `#r`, `#load`, or absolute build-output paths; the runtime rail owns reference projection and fresh artifact refs.
