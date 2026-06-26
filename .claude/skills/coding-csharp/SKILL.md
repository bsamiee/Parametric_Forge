---
name: coding-csharp
description: >-
  Enforces modern C# + LanguageExt functional/ROP style. Use when writing, editing,
  reviewing, or refactoring .cs modules. Drives polymorphic collapse (Thinktecture
  [Union]/[SmartEnum]/[ValueObject]), greenfield API breaking over shims, dense
  algorithmic logic, singular OOP boundary capsules, and unified Fin/Validation/Eff
  rails. Activates on concept-density pressure points: 3+ parallel types, 3+ sibling
  factories, 3+ repeated switch arms, 3+ single-call private helpers.
---

# [H1][CODING-CSHARP]
>**Dictum:** *C# + LanguageExt style, type discipline, and module organization govern all C# work.*

All code follows six governing principles:
- **Polymorphic** — one entrypoint per concern, generic over specific, extend over duplicate
- **Functional + ROP** — pure pipelines, typed error rails, monadic composition
- **Strongly typed** — explicit types everywhere, one canonical shape per concept, zero `var`
- **Programmatic** — variable-driven dispatch, named parameters, bounded vocabularies
- **Algorithmic** — reduce branching through transforms, folds, and discriminant-driven projection
- **AOP-driven** — cross-cutting concerns via decorator composition, not in-method duplication


## Paradigm

- **Immutability**: `readonly record struct` for values, `with`-expressions for transitions, `Atom<T>` for managed state
- **Typed error channels**: sealed DU error hierarchies for file-internal errors (never exported), shared `Error` subtypes for domain-level boundary-crossing errors; `Fin<T>` sync, `Validation<Error,T>` parallel, `Eff<RT,T>` effectful
- **Exhaustive dispatch**: `switch` expressions on sealed DU hierarchies, Thinktecture `Switch`/`Map` for generated dispatch
- **Type anchoring**: `readonly record struct` + `Fin<T>` for primitives, `sealed abstract record` for DUs, `[ValueObject<T>]` for boundary wrappers — derive projections, never parallel types
- **Expression control flow**: LINQ comprehension (`from..in..select`), `Bind`/`Map`/`BiMap`, zero statement branching
- **Programmatic logic**: named parameters at domain call sites, `SmartEnum<T>` over strings, bounded vocabularies
- **Surface ownership**: one polymorphic entrypoint, `params ReadOnlySpan<T>` for arity collapse, no helpers
- **Private integration**: module logic is the export's implementation, not its neighbor — `private`/`internal` members are nested types, closures, or inline compositions inside the public class/service, not standalone file-level declarations consumed by a single caller
- **Cross-cutting composition**: Scrutor `Decorate` at composition root when a host container exists; otherwise runtime-record DI; `K<F,A>` for higher-kinded abstraction


## Architecture trinity

Every module exhibits three layers — singular boundary, unified rails, dense FP internals.

1. **Singular OOP boundary** — exactly one sealed boundary capsule per native-OOP integration point. The override surface is `sealed`; the only virtual surface returns `Fin<T>` (or `Eff<RT,T>`). Native disposables live inside `try…finally` blocks annotated `// BOUNDARY ADAPTER — reason`.
2. **Unified rails** — one rail per failure semantics within a file: `Fin<T>` (sync fallible), `Validation<Error,T>` (parallel accumulation), `Eff<RT,T>` (effectful), `IO<A>` (boundary effects). No mixing within the file. No raw `Task<T>` in domain. No `null` for absence. No `Exception` for control flow.
3. **FP internal logic** — dense expression bodies, exhaustive `switch` on `[Union]`/`SmartEnum`, LINQ comprehensions (`from..in..select`) for multi-step monadic composition, `Atom<TState>` for managed state, host decision monoids where needed, polymorphic dispatch tables, fold algebras over recursive structures. Prefer one deep complex surface over many shallow loose ones.


## Greenfield posture

Treat every refactor and every file as greenfield. No shims, no adapters, no legacy aliases, no `[Obsolete]` wrappers, no migration helpers, no `internal static T Adapt(LegacyShape)` indirections. Aggressive API breaking is the default when it produces:
- A denser polymorphic surface
- A unified rail where two parallel rails existed
- A boundary capsule where scattered OOP escaped containment
- Higher algorithmic density via `[Union]`/`SmartEnum`/fold algebra

When the analyzer rejects, treat the rejection as architectural pressure, not as a target to suppress. Search for the collapse before considering an exemption attribute.


## Conventions

| Layer | Library | Owns |
| ----- | ------- | ---- |
| ROP / Effects | LanguageExt | `Fin<T>`, `Validation<Error,T>`, `Eff<RT,T>`, `IO<A>`, `K<F,A>`, `Option<T>`, `Seq<T>` |
| Value objects / DUs | Thinktecture | `[ValueObject<T>]`, `[SmartEnum<T>]`, `[Union]`, generated dispatch |
| Numerics / Symbolics | MathNet, CSparse | Linear algebra, symbolic formulas, sparse SPD factorization |
| Scheduling | LanguageExt | `Schedule.exponential` / `spaced` / `jitter` / `recurs` / `upto` algebra |
| State | LanguageExt | `Atom<T>` validators, `Ref<T>` + `atomic` STM, `Bracket` resource scope |
| Composition (host) | Scrutor | `Scan`, `Decorate`/`TryDecorate`, keyed registration — composition root only |
| Persistence (host) | EF Core | `DbContext`, repositories, value converters — effectful shell only |
| Time (boundary) | NodaTime | `Instant`, `IClock`, zones — inject clock; no wall-clock in domain |
| Validation (boundary) | FluentValidation | DTO/rule sets — bridge to `Validation<Error,T>` before domain |
| Observability (host) | Serilog, OpenTelemetry | Logs, traces, metrics — host registration only |
| HTTP (host) | Http.Resilience | Outbound client resilience handlers — composition root only |

- One library's error/option type per module — no mixing across libraries in same file.
- Domain retry/backoff: LanguageExt `Schedule` + `Prelude.retry` on `Eff<RT,T>` and `IO<A>` — lift pure `Fin` retry via re-invocation or boundary lift; not raw Polly in domain.
- Prefer runtime-record `Eff.runtime<RT>()` in effectful pipelines; use Scrutor where `IServiceCollection` exists.


## Contracts

**Type discipline**
- Zero `var` — all types explicit in declarations and lambda parameters.
- Named parameters at every domain call site. Framework/LINQ single-arg lambdas may use positional.
- `readonly record struct` for domain primitives with `Fin<T>` smart constructors.
- `sealed abstract record` base + `sealed record` cases for DUs. Static factories on abstract base.
- One canonical type per concept; derive projections, never parallel types.
- File-scoped namespaces only. Explicit accessibility on every member.

**Control flow**
- Zero `if`/`else`/`while`/`for`/`foreach`/`try`/`catch`/`throw` in domain transforms.
- `switch` expressions with exhaustive arms on sealed DU hierarchies.
- LINQ comprehension (`from..in..select`) for multi-step monadic composition.
- Boundary adapters may use required statement forms with marker: `// BOUNDARY ADAPTER — reason`.

**Error handling**
- Sealed DU error hierarchies for file-internal errors — never exported, never cross module boundaries.
- Shared `Error` subtypes at domain level — few per system (1-3), boundary-crossing, co-located in owning package (no dedicated error files).
- Domain error types carry polymorphic/agnostic logic reusable across all call sites.
- `Fin<T>` sync fallible, `Validation<Error,T>` parallel accumulation, `Eff<RT,T>` effectful pipelines, `IO<A>` boundary effects.
- `K<F,A>` + trait constraints for algorithms generic over computation shape.

**Surface**
- One polymorphic entrypoint per concern — `params ReadOnlySpan<T>` for arity collapse.
- Private-by-default: every non-public member is `private` (or `internal` for assembly-level sharing). Public API surface is 1–2 types per file maximum.
- Internal logic integrates INTO exports — `private` nested classes, closures inside methods, `private static` composed pipelines inside the owning class. Not defined alongside as standalone file-level declarations consumed by a single caller.
- No helper files, no single-caller extracted functions, no one-use file-level declarations.
- No convenience wrappers that rename or forward external APIs.
- **Pressure-point signals** (concept density, not byte count): ≥3 parallel types/records modeling overlapping concepts; ≥3 sibling factory methods sharing a prefix; ≥3 near-identical switch arms; ≥3 single-call private helpers. Each signal triggers IN-PLACE polymorphic collapse — merge the cases into one `[Union]`, one `SmartEnum<T>`, one fold algebra, or one data table. NEVER extract to a new file. NEVER delete functionality to reduce LOC. The goal is denser polymorphic capability in fewer surfaces, not less code.
- Expression-bodied members where body is a single expression. Primary constructors preferred.

**Resources**
- Time via host-injected `IClock` (NodaTime), never direct `DateTime*` in domain.
- Retry/timeout/resilience via LanguageExt `Schedule` in domain; HTTP client resilience via `Microsoft.Extensions.Http.Resilience` at host only.
- `static` lambdas on hot-path closures — zero closure allocations.

**Formatting**
- `using static LanguageExt.Prelude;` assumed in every module.
- K&R brace style, zero consecutive blank lines, method group conversion preferred.


## Load sequence

**Foundation** (always):

| Reference | Focus |
| --------- | ----- |
| [validation.md](references/validation.md) | Compliance checklist |
| [patterns.md](references/patterns.md) | Anti-pattern detection heuristics |
| [advanced-surface.md](references/advanced-surface.md) | Operators, Thinktecture attrs, combinators, numerics, C# 14 |

**Task-routed references**:

| Reference | Load when |
| --------- | --------- |
| [effects.md](references/effects.md) | Fin/Validation/Eff/IO pipelines, Schedule boundary |
| [transforms.md](references/transforms.md) | Folds, LINQ composition, K<F,A> |
| [types.md](references/types.md) | C# types, generics, keyed-service keys |
| [objects.md](references/objects.md) | Records, DU hierarchies, value objects |
| [composition.md](references/composition.md) | Runtime-record wiring, hosted scope |
| [scrutor.md](references/scrutor.md) | Scrutor scan/decorator composition |
| [persistence.md](references/persistence.md) | EF Core, repositories |
| [concurrency.md](references/concurrency.md) | Channels, cancellation, periodic work |
| [observability.md](references/observability.md) | Serilog, OpenTelemetry |
| [performance.md](references/performance.md) | SIMD, Span, hot paths |
| [diagnostics.md](references/diagnostics.md) | Debugging, profiling |


## Project Proof

- Apply project static analysis and tests when C# code changes.
- Reject completion when contracts or checks are not satisfied.
- Examples inside this skill are concrete patterns: runtime-record `Eff.runtime<RT>()`, generated Thinktecture factories only when they serve boundary construction, no legacy runtime trait DI pattern, and no single-call helper extraction.


## First-class libraries

Use over BCL/stdlib equivalents where applicable.

### Domain

| Package | Provides | Scope |
| ------- | -------- | ----- |
| LanguageExt.Core | FP primitives, ROP, `Eff`/`Fin`/`Validation`, `Schedule`, STM | Domain + host |
| Thinktecture.Runtime.Extensions | Value objects, smart enums, `[Union]` dispatch | Domain + host |
| MathNet.Numerics | Linear algebra, solvers, statistics, optimization | Domain numerics |
| MathNet.Symbolics | Symbolic parse, transform, calculus, evaluation | Domain numerics |
| CSparse | Sparse direct factorization with MathNet iterative paths | Domain numerics |
| Meziantou.Analyzer | Static analysis enforcement | Build |
| Microsoft.VisualStudio.Threading.Analyzers | Threading-correctness diagnostics | Build |

### Host

| Package | Provides | Scope |
| ------- | -------- | ----- |
| Scrutor | `Scan`, `Decorate`/`TryDecorate`, `WithServiceKey`, keyed registration | Composition root |
| FluentValidation | Boundary DTO validation — bridge to `Validation<Error,T>` | HTTP/API/config boundary |
| NodaTime | `Instant`, `IClock`, time zones | Boundary + persistence adapters |
| EF Core | Relational persistence, `IQueryable`, value converters | Persistence host projects |
| Serilog | Structured logging, enrichers, sinks | Generic host |
| OpenTelemetry | Traces, metrics, exporters | Generic host |
| Microsoft.Extensions.Http.Resilience | Outbound `HttpClient` resilience | Composition root |

Polly raw is intentionally absent from domain guidance. BenchmarkDotNet belongs to dedicated measurement rails only — not domain hot-path doctrine. Domain retry: LanguageExt `Schedule` + `Prelude.retry` on `Eff`/`IO`; domain validation: `Validation<Error,T>`; domain time: `IClock`; container wiring: Scrutor when `IServiceCollection` exists, else runtime records.


## Advanced surface index

Load [advanced-surface.md](references/advanced-surface.md) when prompts mention operators, codegen attributes, or non-basic library sugar:

| Concern | Primary symbols / attrs |
| ------- | ----------------------- |
| Kleisli / applicative operators | `>>`, `>>>`, `*`, `Validation &`, `Error +` |
| Option / effect recovery | `.Choose`, `IfNone`, `Match`; `Prelude.catch`, `Prelude.retry` |
| Schedule algebra | `\|`, `union`, `intersect`, transformer `+` |
| State-threaded union dispatch | `[Union(SwitchMapStateParameterName = …)]` |
| VO / complex VO / custom faults | `[ValueObject<T>]`, `[ComplexValueObject]`, `[ValidationError<T>]` |
| SmartEnum dispatch | `[SmartEnum]`, `[SmartEnum<TKey>]`, `[UseDelegateFromConstructor]` |
| Traverse v5 lowering | `.TraverseM(f).As()`, `.Choose`, `.BiBind` |
| Atoms and guards | `Atom.Swap`, `guard`, `Optional(…).ToFin` |
| Sparse numerics | `BiCgStab`, CSparse `SparseCholesky`, CSR/CSC hybrid |
| C# 14 expression substrate | extension blocks, collection expressions, `params ReadOnlySpan` |
