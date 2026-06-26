# [H1][TESTKIT]
>**Dictum:** *The testkit is one rail, not a module-specific helper drawer.*

<br>

## [01]-[FILES]

| [INDEX] | [FILE]          | [OWNS]                                                                                                      |
| :-----: | --------------- | ----------------------------------------------------------------------------------------------------------- |
|  [01]   | `Spec.cs`       | Law adapters, CsCheck sample policy, `Fin`/`Validation`/`Option` assertions, equality/tolerance assertions. |
|  [02]   | `Gens.cs`       | Reusable primitive, geometry, value-object, context, and rail generators consumed by multiple specs.        |
|  [03]   | `Numeric.cs`    | Independent row-major numerical oracles for matrix/vector laws.                                             |
|  [04]   | `Serializer.cs` | xUnit serializer for pure data display.                                                                     |

---
## [02]-[SPEC_CONTRACT]

- Use `Spec.ForAll` instead of raw `gen.Sample` so seed/iter/time/thread precedence is consistent.
- Use `Spec.Metamorphic` when expected values come from an independent path.
- Treat `Spec.Metamorphic` as a path/oracle law wrapper; it is not CsCheck `SampleMetamorphic`.
- Use `Spec.Valid` / `Spec.Invalid` for `Validation<Error,T>` and `Spec.Succ` / `Spec.Fail` for `Fin<T>`.
- Do not use `.IsSucc`, `.IsFail`, `.IsSome`, or `.IsNone` as primary assertions; preserve category/code diagnostics through `Spec`.
- Use `Spec.Equal`, `Spec.EqualSignAmbiguous`, and `Approx.Equal` for generated numeric comparisons.
- Use `Numeric.*` for matrix expected values when testing `Matrix`.
- Add model-based, async, snapshot, benchmark, or fuzz adapters only when two concrete consumers exist.

---
## [03]-[GENERATOR_CONTRACT]

- Value-object generators call production `TryCreate`/`Create`/`AcceptValidated` paths.
- Edge-biased scalar generators include tolerance-adjacent values, not just broad random ranges.
- `Context` generators must produce valid `Context` instances and remain reusable across vector/flow/field/cloud specs.
- Keep module-local generators inside the spec until at least two consumers need the same concept.

---
## [04]-[SUPPRESSION_POLICY]

- No local `SuppressMessage` attributes for normal xUnit generator classes.
- Keep test classes public for xUnit discovery.
- Keep spec-local generator/static data classes non-public when discovery does not need them.
- Folder-wide analyzer rationale belongs in `.editorconfig`, not in repeated file-local comments.

---
## [05]-[GENERATOR_SHRINKING_RULE]
>**Dictum:** *`throw` inside `Select` breaks shrinking; use `Where(Try)+Select` to preserve it.*

<br>

CsCheck shrinking finds minimal counterexamples by narrowing failed inputs. Two patterns break it:

| [BREAKS]                                                             | [PRESERVES]                                                                        |
| -------------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| `Gen.Int.Select(i => i > 0 ? new T(i) : throw new ...)`              | `Gen.Int.Where(i => i > 0).Select(i => new T(i))`                                  |
| `Gen.Select(Factory).Select(opt => opt.IfNone(() => throw new ...))` | `Gen.Select(Factory).Where(opt => opt.IsSome).Select(opt => opt.IfNone(default!))` |

For factory-routed value-objects returning `Fin<T>` / `TryCreate(out T)`:

```csharp
public static readonly Gen<Dimension> Dimension =
    SmallDimension
        .Select(v => Vectors.Dimension.TryCreate(value: v, obj: out Vectors.Dimension d) ? Some(d) : None)
        .Where(opt => opt.IsSome)
        .Select(opt => opt.IfNone(default(Vectors.Dimension)));
```

The `throw` form turns rejected candidates into property failures instead of filtered generation. `WhereLimit` applies to `Gen.Where`; keep predicates broad enough to preserve shrinkable satisfying values.

[SOURCE] CsCheck README on `Where` shrinking semantics.

---
## [06]-[ADMISSION_EXTENSION_HOOK]
>**Dictum:** *Cross-layer types extend admission through an interface, not a switch arm.*

<br>

When a downstream layer type needs upstream admission support, the canonical extension hook is a marker interface or validation protocol:

```csharp
public interface IDomainValid { bool IsValid { get; } }

// in the upstream admission switch:
IDomainValid v => Some(v.IsValid),
```

Downstream record/struct types implement `IDomainValid`:

```csharp
public readonly record struct TopologyReceipt(...) : IDomainValid {
    public bool IsValid => /* invariant predicate */;
}
```

Do NOT add per-type arms to `ValidityOf` for cross-layer types — that would create `Domain → Vectors` dependencies and violate the universal-code-shape no-upstream-mirroring rule.

Architecture coverage: an `ArchUnitNET` test in `tests/csharp/_architecture/` enumerates all `[BoundaryAdapter]`-marked types and asserts each is reachable through `ValidityOf` (either via `IDomainValid` or explicit switch arm). Catches the entire `AcceptValue / ValidityOf` gap regression class once and forever.

---
## [07]-[ASSEMBLY_FIXTURE_PATTERN]
>**Dictum:** *Shared assembly context is an attribute, not an interface.*

<br>

xUnit v3 has **no `IAssemblyFixture<T>` API** — the v2 folklore does not apply. Shared assembly context uses `[assembly: AssemblyFixture(typeof(T))]` plus constructor injection:

```csharp
// in tests/csharp/<Project>/<AnyFile>.cs:
[assembly: AssemblyFixture(typeof(VectorsContextFixture))]

// the fixture:
public sealed class VectorsContextFixture {
    public Context Model { get; }
    public VectorsContextFixture() {
        Model = Context.Of(absolute: 1.0e-6, relative: 1.0e-6, angle: 1.0e-3, units: UnitSystem.Millimeters)
            .Match(Succ: c => c, Fail: e => throw new InvalidOperationException(e.Message));
    }
}

// consumers:
public sealed class MyLaws(VectorsContextFixture fixture) {
    private readonly Context model = fixture.Model;
    [Fact] public void LawUsesSharedContext() => Spec.ForAll(gen, x => /* uses model */);
}
```

Promote to a shared fixture only when ≥3 specs duplicate the same `static readonly Context Model = Spec.SuccValue(...)` block. AssemblyFixture is thread-shared across parallel test classes — reserve for *constructed-once expensive immutables* (reference factorizations, document loaders), never for per-test mutable state.
