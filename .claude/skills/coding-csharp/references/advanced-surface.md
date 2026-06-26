# Advanced Surface

Self-contained advanced capability reference. **Not** basic `Map`/`Bind`/`Create`.

---
## [01]-[LOAD_WITH]

| Task                            | Reference                                                            |
| ------------------------------- | -------------------------------------------------------------------- |
| Rails, Schedule boundary        | [effects.md](effects.md)                                             |
| Folds, `K<F,A>`                 | [transforms.md](transforms.md)                                       |
| Thinktecture attrs, unions, VOs | [objects.md](objects.md), [types.md](types.md)                       |
| Scrutor scan/decorate           | [scrutor.md](scrutor.md)                                             |
| EF, FluentValidation bridge     | [persistence.md](persistence.md), [validation.md](validation.md) §10 |
| Serilog, OTel, Http resilience  | [observability.md](observability.md)                                 |

---
## [02]-[LANGUAGEEXT_OPERATORS]

| Symbol                 | Carrier                 | Semantics                                   |
| ---------------------- | ----------------------- | ------------------------------------------- |
| `>>`                   | `K<F,A>`                | Kleisli bind / discard-first sequence       |
| `>>>`                  | `K<F,A>`                | Applicative sequence                        |
| `*`                    | `K<F,A>`                | Functor map / applicative apply             |
| `>> lower` / unary `+` | `K<F,A>`                | Downcast to concrete rail (`Prelude.lower`) |
| `\|`                   | `K<Validation<E,A>>`    | Choice — first success wins                 |
| `\|`                   | `Fallible` + `CatchM`   | Catch / recovery                            |
| `\|`                   | `Eff<RT,A>` + `Finally` | Finally composition — not peer-Eff choice   |
| `&`                    | `Validation<E,A>`       | Applicative product — accumulate errors     |
| `+`                    | `Error` / monoid `E`    | Error append                                |

Schedule: `Schedule.a \| Schedule.b` (union), `union(a,b)` / `intersect(a,b)` Prelude functions, `ScheduleTransformer +`; intersect is **not** ASCII `&` on `Schedule`. Duration: `200 * LanguageExt.UnitsOfMeasure.ms`.

Eff recovery: `Prelude.catch`, `Prelude.retry(schedule, eff)`, `IfFailEff` — not `.Retry(schedule:)` on `Eff`.

Use LINQ `from..in..select` for monadic composition.

---
## [03]-[LANGUAGEEXT_COMBINATORS]

| Combinator                                              | Notes                                          |
| ------------------------------------------------------- | ---------------------------------------------- |
| `.TraverseM(f) >> lower`                                | Fin / Validation / Option lowering             |
| `.TraverseM(f).As()`                                    | Eff / IO lowering                              |
| `.Traverse(identity) >> lower`                          | Sequence replacement (v4 `Sequence`)           |
| `.Choose(f)`                                            | Filter-map to Option                           |
| `.MapFail` / `.BindFail` / `.IfFail`                    | `IfFail` not on `Fin` — use `Match` / `BiBind` |
| `.BiBind(Succ:, Fail:)`                                 | Both branches                                  |
| `Validation.Apply` / `&`                                | Multi-field validation product                 |
| `guard` / `Optional(…).ToFin`                           | Prelude guards                                 |
| `Try.lift<Fin<T>>().Run()`                              | Native boundary                                |
| `Eff.runtime<RT>()` / `Reader.Asks` / `Prelude.liftEff` | Effects                                        |
| `Atom.Swap` / `SwapMaybe`                               | State — Subscribe absent in 5.0.0-beta-77      |

`Validation<string,T>` is not supported — use `Validation<StringM,T>` or `Validation<Error,T>`. Parallel fault channels at UI boundaries may use `Validation<Seq<TFault>,T>` with a dedicated fault type — not `Validation<Seq<Error>,T>` in domain.

---
## [04]-[THINKTECTURE_ATTRIBUTES]

| Attribute                                                        | Effect                            |
| ---------------------------------------------------------------- | --------------------------------- |
| `[Union(SwitchMapStateParameterName = "…")]`                     | State-threaded `.Switch` / `.Map` |
| `SwitchMethods` / `MapMethods`                                   | `SwitchMapMethodsGeneration` enum |
| `[UnionSwitchMapOverload(StopAt = typeof(...))]`                 | Partial overload generation       |
| `[ValueObject<T>]`                                               | Branded scalar                    |
| `[ComplexValueObject]`                                           | Multi-field VO — partial only     |
| `[ValidationError<TFault>]`                                      | Typed factory validation          |
| `[SmartEnum]` / `[SmartEnum<TKey>]`                              | Total enum dispatch               |
| `[UseDelegateFromConstructor]`                                   | SmartEnum delegate from ctor      |
| `[KeyMemberEqualityComparer<T>]` / `[MemberEqualityComparer<,>]` | Key/member equality               |

Thinktecture does **not** emit union `operator +`/`|`. Set `SerializationFrameworks = None` when JSON integration packages are not part of the host surface. `[SkipUnionOps]` / `[GenerateUnionOps]` control analyzer SelfOp emission on project unions — not hand union lattice operators.

Generic or ref-struct constrained sums use plain `abstract record` + manual `switch` — not `[Union]`.

---
## [05]-[MATHNET_CSPARSE]

| Surface                                       | Owner                        |
| --------------------------------------------- | ---------------------------- |
| Dense factorizations, statistics, integration | MathNet                      |
| `BiCgStab`, preconditioners, `Iterator<T>`    | MathNet iterative            |
| `SparseCholesky`, AMD ordering, CSC solve     | CSparse — SPD gate required  |
| CSR/CSC hybrid strategy                       | CSparse + MathNet projection |

Package id for direct sparse library: **`CSparse`**. Prefer native geometry APIs for model semantics; MathNet for numerical kernels after explicit coordinate projection.

---
## [06]-[C14_HIGHLIGHTS]

| Feature                          | Use                                        |
| -------------------------------- | ------------------------------------------ |
| Extension blocks                 | Instance/static operators without wrappers |
| Collection expressions           | `[..a, ..b, x]`                            |
| `params ReadOnlySpan<T>`         | Arity-polymorphic APIs                     |
| `field` keyword                  | Inline property validation                 |
| Implicit span conversions        | Audit ambiguous overload sets              |
| Null-conditional assignment      | Boundary-only `target?.Prop = value`       |
| User-defined compound assignment | Domain monoid/receipt `+=`                 |
| Switch / list patterns           | Total value-returning dispatch             |

---
## [07]-[HOST_PACKAGES]

| Package             | Composition-root surface                                                 |
| ------------------- | ------------------------------------------------------------------------ |
| Scrutor 7           | `Scan`, `Decorate`, `WithServiceKey`, `DecoratedService<T>`              |
| FluentValidation 11 | `ValidateAsync` → `Validation<Error,T>` at boundary                      |
| NodaTime 3          | `IClock`, `Instant` on runtime record                                    |
| EF Core 10          | `DbContext` on `RT`; `EnableRetryOnFailure` at persistence boundary only |
| Serilog 4 / OTel 1  | Host registration; `[LoggerMessage]`, `ActivitySource`                   |
| Http.Resilience 10  | `AddStandardResilienceHandler` on typed `HttpClient`                     |

Detail: [scrutor.md](scrutor.md), [persistence.md](persistence.md), [observability.md](observability.md), [composition.md](composition.md).
