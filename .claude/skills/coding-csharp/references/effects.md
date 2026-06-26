# Effects

Effect type system for C# 14 / .NET 10. LanguageExt `5.0.0-beta-77`. Operators and combinators: [advanced-surface.md](advanced-surface.md).

---
## [01]-[RAILS]
>**Dictum:** *One rail answers one failure question.*

<br>

| Rail                        | Owns                                       | Boundary                                                     |
| --------------------------- | ------------------------------------------ | ------------------------------------------------------------ |
| `Fin<T>`                    | One fallible synchronous operation.        | Native validity, value admission, numeric result projection. |
| `Validation<Error,T>`       | Independent accumulated failures.          | Domain requirements, symbol sets.                            |
| `Validation<Seq<TFault>,T>` | Batched fault accumulation.                | Parallel UI or form validation → `ToFin`.                    |
| `Eff<RT,T>`                 | Host context and effectful work.           | Document, filesystem, clock, bridge runtimes.                |
| `IO<A>`                     | Deferred side-effect/resource description. | Boundary execution before collapse.                          |

Use LINQ composition, `Bind`, `Map`, `MapFail`, `BindFail`, and applicative `Apply` / `&` to stay in the rail. Collapse with `Match` or `Run` only at host boundaries.

`Validation<string,T>` is **not supported** — use `StringM` or `Validation<Error,T>`; not `Validation<Seq<Error>,T>` in domain. UI boundaries may use `Validation<Seq<TFault>,T>` with a dedicated fault union.

---
## [02]-[RUNTIME_RECORDS]
>**Dictum:** *Runtime records expose capabilities without service location.*

<br>

Read capability with `Eff.runtime<RT>()` or `Reader.Asks` / `Ask<R,A>` on a concrete sealed record.

```csharp
public sealed record AppRuntime(Context Context, Op Op);

public static Eff<AppRuntime, Context> ContextOf() =>
    Eff.runtime<AppRuntime>().Map(static rt => rt.Context);
```

Boundary collapse: pick explicit `Run` / `RunAsync` / `RunIO` overload — do not assume `Run().Run()` always yields `Fin<T>`.

---
## [03]-[EFF_AND_IO]
>**Dictum:** *Effectful work threads runtime context; IO defers boundary execution.*

<br>

- `Eff<RT,T>` for pipelines needing host capabilities on `RT`.
- `IO<A>` for resource and process descriptions — execute at boundary via `RunIO` / `liftAsync`.
- Recovery: `Prelude.catch`, `@catch`, `IfFailEff` — not peer-Eff `|`.
- Finally: `eff | Finally(action)` on `Eff` — not recovery between two effects.

---
## [04]-[VALIDATION_APPLICATIVE]
>**Dictum:** *Independent failures accumulate; dependent steps bind.*

<br>

Use `Validation<Error,T>` with tuple `.Apply(f)` chains or `validationA & validationB` for multi-field validation. Do not sequential-guard with early returns — evaluate all rules and accumulate failures.

`Validation<E,T>` requires `E : Monoid<E>`. Prefer `Error` as the error carrier in domain modules.

---
## [05]-[RECOVERY]
>**Dictum:** *Recovery projects typed failures, not raw exceptions.*

<br>

- Convert native exceptions at boundary adapters into `Error` once via `Try.lift<Fin<T>>(…).Run()`.
- Prefer `MapFail`, `BiMap`, `IfFail`, and `Prelude.catch` over mid-pipeline `Match`.
- Keep terminal collapse at command/component/tool edges.

---
## [06]-[HOST_DECISION_MONOIDS]
>**Dictum:** *Application policy merge is not a LanguageExt type.*

<br>

Application-defined monoids for host policy merge: identity element + `operator +` for semigroup append; use at composition boundaries only.

---
## [07]-[STATE_AND_RESOURCES]
>**Dictum:** *Managed state belongs to hosts; resources use Bracket.*

<br>

`Atom<T>.Swap` / `SwapMaybe` for managed reactive state — **no** Subscribe API in 5.0.0-beta-77.

`IO<T>.Bracket`, `Prelude.use` — resource scope in LanguageExt 5.0.0-beta-77.

---
## [08]-[SCHEDULE]
>**Dictum:** *Delay schedules belong on Eff decorators, hosted jobs, and IO retry — not pure Fin transforms.*

<br>

| Surface                                                           | Use                                                     |
| ----------------------------------------------------------------- | ------------------------------------------------------- |
| `Schedule.recurs`, `spaced`, `linear`, `exponential`, `fibonacci` | Bounded retry/repeat cadence                            |
| `upto`, `fixedInterval`, `windowed`, `jitter`, `maxDelay`         | Backoff shaping                                         |
| `Schedule.a \| Schedule.b`, `union`, `intersect`                  | Policy composition — not C# `&` on `Schedule`           |
| `transformerA + transformerB`                                     | Chain `ScheduleTransformer` instances                   |
| `Prelude.retry(schedule, eff)`                                    | Eff retry inside Scrutor decorators or hosted pipelines |
| `IO<T>.Retry(Schedule)`                                           | IO-bound retry at boundary                              |

Pure `Fin`/`Validation` domain transforms avoid blocking delay schedules. HTTP outbound resilience uses `Microsoft.Extensions.Http.Resilience` at the composition root — not duplicated `Schedule` for transport.

---
## [09]-[RULES]

- [ALWAYS] `Fin<T>` for local fallible work.
- [ALWAYS] `Validation<Error,T>` or tuple `Apply` / `&` for independent fields.
- [ALWAYS] `Eff<RT,T>` when host context is required.
- [NEVER] Mix rails within one module file.
- [NEVER] Use exceptions for domain control flow.
