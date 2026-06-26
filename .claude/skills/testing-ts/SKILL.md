---
name: testing-ts
description: >-
  Generates dense law-driven test suites for Effect modules via algebraic PBT
  using Vitest, @effect/vitest, fast-check. Enforces 175 LOC cap, 95% per-file
  coverage, mutation kill-ratio via Stryker. Use when writing/reviewing spec
  files, adding coverage, generating property tests, debugging flakes, or
  scaffolding unit/integration/E2E tests from templates.
---

# [H1][TESTING_TS]

Generate dense, law-driven test suites. Pure transformations tested via algebraic laws; effectful boundaries tested via properties. Density over quantity -- few powerful tests, not many trivial ones.

**Tasks:**
1. Classify test category via [section 04](#04-category_routing).
2. For unit PBT: read [->laws.md](./references/laws.md), [->density.md](./references/density.md).
3. For integration/E2E: read [->categories.md](./references/categories.md).
4. Author spec following workflow in [section 01](#01-workflow).
5. Validate against [section 08](#08-validation) and [->validation.md](./references/validation.md).

**Versions:** Vitest (inline projects), fast-check (PBT + model-based + fc.gen), @effect/vitest (Effect bridge + Schema-as-arbitraries), Stryker (mutation + TS checker), testcontainers (integration), Playwright (E2E).

**References:**

| [INDEX] | [DOMAIN]   | [FILE]                                                                 |
| :-----: | ---------- | ---------------------------------------------------------------------- |
|  [01]   | Laws       | [laws.md](references/laws.md)                                          |
|  [02]   | Density    | [density.md](references/density.md)                                    |
|  [03]   | Categories | [categories.md](references/categories.md)                              |
|  [04]   | Guardrails | [guardrails.md](references/guardrails.md)                              |
|  [05]   | Validation | [validation.md](references/validation.md)                              |
|  [06]   | Template   | [unit-pbt.spec.template.md](templates/unit-pbt.spec.template.md)       |
|  [07]   | Template   | [integration.spec.template.md](templates/integration.spec.template.md) |
|  [08]   | Template   | [contract.spec.template.md](templates/contract.spec.template.md)       |

## [01]-[WORKFLOW]

1. **Read source module** -- Inventory exported functions, Effect dependencies (R channel), error types (E channel), schemas, branded types.
2. **Classify test category** -- Walk routing table from [section 04](#04-category_routing). Most `packages/server/` modules are unit PBT. Boundary modules (database, HTTP) are integration.
3. **Select applicable laws** -- Walk matrix from [section 05](#05-law_selection) per exported function. List each law with formula.
4. **Design arbitraries** -- Pass Schema directly to `it.effect.prop` (auto-extracts arbitrary). Fall back to `Arbitrary.make(Schema)` for custom filtering. Hand-roll with `fc.*` only when schema unavailable. Use `_` prefix.
5. **Plan LOC budget** -- Allocate lines per section within 175 cap: imports 5-7, constants 8-15, layer 3-6, algebraic 80-120, edge cases 15-25.
6. **Pack and merge** -- Combine 2-4 laws sharing same arbitrary shape into single `it.effect.prop`. Merge edge cases sharing the same mock/layer config into single `it.effect` with `Effect.all` aggregation. Extract repeated service-call orchestration into `[FUNCTIONS]` helper before merging.
7. **Select density technique** -- Walk table from [section 06](#06-density_selection). Choose highest-multiplier technique that fits.
8. **Author spec from template** -- Pick `unit-pbt`, `integration`, or `contract` template from `templates/`.
9. **Verify oracle independence** -- Walk guardrails checklist from [->guardrails.md](./references/guardrails.md). Expected values come from laws, external refs, or standards -- never from re-deriving source logic.
10. **Verify coverage** -- Predict branch coverage from properties. Add `[EDGE_CASES]` section if <95% predicted. Run `pnpm exec nx test -- --coverage` to confirm.
11. **Run mutation testing** -- `npx stryker run` to verify tests kill mutants. Stryker TS checker eliminates compile-error mutants; `vitest.related: true` scopes test runs.

## [02]-[HARD_CONSTRAINTS]

[CRITICAL]:
- [ALWAYS] **175 LOC flat cap** per spec file. No exceptions.
- [ALWAYS] **95% per-file coverage** (V8 provider, statements + branches + functions). Each file measured independently.
- [ALWAYS] **Mutation thresholds**: break=50 (build fails), low=60 (investigate), high=80 (target).
- [ALWAYS] **One spec per source module per category**. No splitting, no combining.
- [ALWAYS] **Density over quantity** -- pack laws into properties, aggregate with Effect.all, leverage generation.

| [INDEX] | [METRIC]        | [VALUE] | [NOTE]                               |
| :-----: | --------------- | :-----: | ------------------------------------ |
|  [01]   | Max file LOC    |   175   | Flat cap, enforced by PostToolUse    |
|  [02]   | Coverage target |   95%   | Per-file V8 (statements+branches+fn) |
|  [03]   | Mutation break  |   50    | Build fails below this               |
|  [04]   | Mutation low    |   60    | Investigation trigger                |
|  [05]   | Mutation high   |   80    | Target -- contract-driven tests      |

## [03]-[FILE_STRUCTURE]

**Import Order** (enforced by hook):
1. `@effect/vitest` -- `it`, `layer`
2. `${WORKSPACE_SCOPE}/*` -- source module under test
3. `effect` -- `Effect`, `FastCheck as fc`, `Schema as S`, `Array as A`
4. `vitest` -- `expect`
5. External oracles (e.g., `node:crypto`) -- after vitest

**Section Order** (omit unused, separators padded to column 80):

```
// --- [CONSTANTS] -------------------------------------------------------------
// --- [FUNCTIONS] -------------------------------------------------------------
// --- [LAYER] -----------------------------------------------------------------
// --- [MOCKS] -----------------------------------------------------------------
// --- [ALGEBRAIC] -------------------------------------------------------------
// --- [EDGE_CASES] ------------------------------------------------------------
```

**Section Descriptions:**

| [INDEX] | [SECTION]      | [PURPOSE]                                                                |
| :-----: | -------------- | ------------------------------------------------------------------------ |
|  [01]   | `[CONSTANTS]`  | Arbitraries (`_` prefix), static data (`UPPER`), test fixtures           |
|  [02]   | `[FUNCTIONS]`  | Test helpers: `_provide`, `_reset`, `_mkDatabase`, `_live` — reusable    |
|         |                | factory/provider/reset functions that wire services or build fakes       |
|  [03]   | `[LAYER]`      | `layer()` wrapper for suites sharing a service layer                     |
|  [04]   | `[MOCKS]`      | `vi.mock(...)` calls for module-level mocks (database client, telemetry) |
|  [05]   | `[ALGEBRAIC]`  | PBT properties (`it.effect.prop`) and law-driven behavioral tests        |
|  [06]   | `[EDGE_CASES]` | Boundary conditions, rejection paths, specific regression tests          |

[CRITICAL]:
- [NEVER] Remove `[FUNCTIONS]` or `[MOCKS]` sections when they exist in a spec file.
- [ALWAYS] Place `[FUNCTIONS]` between `[CONSTANTS]` and `[LAYER]` — it holds test-scoped helpers.
- [ALWAYS] Place `[MOCKS]` after `[LAYER]` and before `[ALGEBRAIC]` — `vi.mock` must execute before tests.

[IMPORTANT]:
- [ALWAYS] **Extract repeated orchestration** — when 3+ tests repeat the same `Effect.gen` + `pipe` + `_provide` pattern, extract to a named helper (e.g. `_transition`) in `[FUNCTIONS]`.
- [ALWAYS] **Inline trivial mock factories** — if a factory returns a single-field literal (`{ log: vi.fn(() => Effect.void) } as never`), inline at `_provide` call site; reserve `_mk*` factories for mocks with 2+ configurable fields.
- [ALWAYS] **Terse internal names** — test helpers use short parameter names (`a`, `ns`, `set`) to maximize LOC budget; they are not public API.

**Constants Convention:**

| [INDEX] | [PREFIX]   | [PURPOSE]              | [EXAMPLE]                               |
| :-----: | ---------- | ---------------------- | --------------------------------------- |
|  [01]   | `_`        | Fast-check arbitraries | `_json`, `_text`, `_nonempty`           |
|  [02]   | `_`        | Schema-derived arbs    | `_item = Arbitrary.make(ItemSchema)`    |
|  [03]   | `UPPER`    | Static constants       | `CIPHER`, `RFC6902_OPS`, `NIST_VECTORS` |
|  [04]   | `as const` | All static constants   | `{ iv: 12, tag: 16 } as const`          |
|  [05]   | `_`        | Single-expression arbs | `_dns = fc.tuple(…).map(…)` (1 line)    |

**File Comment:** `/** [Module] tests: [brief description]. */`

**Topology:** See [section 04](#04-category_routing) for file locations per category.

## [04]-[CATEGORY_ROUTING]

**Categories:** Unit PBT (`tests/unit/`), Integration (`tests/integration/`), Contract (`tests/contract/` or `tests/integration/`), System (`tests/system/`), E2E (`tests/e2e/`).
**Quick route:** Pure modules are Unit PBT. Boundary modules (database, HTTP, Redis) are Integration. Cross-module schema/service compatibility is Contract. Cross-service orchestration is System. User-facing flows are E2E (Playwright agent pipeline -- do not manually author).

| [INDEX] | **Category** | [LOCATION]                                | [VERIFIES]                                                        | [KEY_TOOLS]                                                 |
| :-----: | ------------ | ----------------------------------------- | ----------------------------------------------------------------- | ----------------------------------------------------------- |
|  [01]   | Unit PBT     | `tests/unit/`                             | Algebraic properties of pure domain logic                         | @effect/vitest, fast-check                                  |
|  [02]   | Integration  | `tests/integration/`                      | Boundary contracts against real infrastructure                    | testcontainers, MSW                                         |
|  [03]   | Contract     | `tests/contract/` or `tests/integration/` | Schema compatibility, service tag availability, layer composition | @effect/vitest, Effect.provideService, Schema.decodeUnknown |
|  [04]   | System       | `tests/system/`                           | Cross-service orchestration via Layer composition                 | Full Layer stack, mock edges                                |
|  [05]   | E2E          | `tests/e2e/`                              | User-facing flows through full application stack                  | Playwright, agent pipeline                                  |

**Contract tests** use no mocks -- real schemas and service tags with `Layer.succeed` for minimal fakes. They verify that packages remain structurally compatible at their boundaries.

[REFERENCE] Full routing matrix, Vitest inline projects, and patterns per category: [->categories.md](./references/categories.md).

## [05]-[LAW_SELECTION]

Walk the law taxonomy per exported function. Select all applicable laws. Pack laws sharing the same arbitrary shape into a single `it.effect.prop`.

**Core laws:** Identity, Inverse, Idempotent, Commutative, Associative, Homomorphism, Annihilation, Monotonicity.
**Equivalence relations:** Reflexive, Symmetric, Transitive.
**Structural properties:** Immutability, Determinism, Non-determinism, Length formula, Preservation.
**Concurrency laws:** Fiber interruption safety, Resource cleanup (acquireRelease bracket), Ref/TRef atomicity.
**Type-level laws:** Compile-time assertions via `expectTypeOf` and `@ts-expect-error`.
**Domain invariants:** Security (proto pollution, tenant isolation, tampering), Boundary limits, Known-answer vectors.

[REFERENCE] Full law taxonomy, selection procedure, and code patterns: [->laws.md](./references/laws.md).

## [06]-[DENSITY_SELECTION]

**Top techniques:** `it.effect.prop` PBT (50-200x), property packing (2-4x), `Effect.all` aggregation (Nx1), statistical batching, symmetric iteration, model-based commands, `fc.scheduler()` race detection.

**Decision heuristic:** Start at highest multiplier. Drop to lower-multiplier techniques only when property shape or cost prevents a higher one.

[CRITICAL] **Block syntax rule:** `it.effect.prop` callbacks must return `void | Effect<void>`. Use `{ expect(...); }` not bare `expect(...)`. Expression-form returns an Assertion object, causing false failures.

[REFERENCE] Full technique catalog, decision rules, and code patterns: [->density.md](./references/density.md).

## [6.1]-[EFFECT_TESTING_API]

[IMPORTANT] **Schema-as-arbitraries**: Pass `Schema` directly to `it.effect.prop` -- no `Arbitrary.make()` wrapping needed. The framework auto-creates arbitraries.

```typescript
// Schema passed directly -- no Arbitrary.make() wrapper
it.effect.prop('roundtrip', { req: NotificationService.Request }, ({ req }) =>
    S.encode(NotificationService.Request)(req).pipe(
        Effect.flatMap(S.decodeUnknown(NotificationService.Request)),
        Effect.tap((decoded) => { expect(decoded).toEqual(req); })));
```

| [INDEX] | [API]                    | [WHEN_TO_USE]                               | [BENEFIT]                        |
| :-----: | ------------------------ | ------------------------------------------- | -------------------------------- |
|  [01]   | `it.effect`              | Standard Effect tests with TestServices     | Auto-provides TestClock, etc.    |
|  [02]   | `it.effect.prop`         | PBT with Schemas or fc.Arbitrary            | 50-200x coverage per LOC         |
|  [03]   | `it.scoped`              | Tests needing Scope (semaphores, fibers)    | Auto-release on test end         |
|  [04]   | `it.live`                | Tests needing real Clock/Random             | No TestServices overhead         |
|  [05]   | `it.effect.each`         | Parameterized Effect tests                  | Table-driven with Effect runtime |
|  [06]   | `it.flakyTest`           | Retry flaky Effect until timeout            | Removes E from type              |
|  [07]   | `layer()` + `it.layer()` | Share/nest service layers across tests      | Single materialization per suite |
|  [08]   | Schema as arbitrary      | Pass Schema directly to `.prop` arbitraries | Zero boilerplate, stays synced   |
|  [09]   | `fc.scheduler()`         | Race condition detection in concurrent ops  | Adversarial interleaving         |
|  [10]   | `expectTypeOf`           | Compile-time type assertions                | Type-level correctness           |

[CRITICAL]:
- [NEVER] Use `Arbitrary.make(Schema)` when Schema can be passed directly to `it.effect.prop`.
- [ALWAYS] Use `it.scoped` for tests acquiring `Scope`-managed resources.
- [ALWAYS] Use `layer()` wrapper for suites sharing a service layer.

## [07]-[THESIS]

- **Algebraic PBT as External Oracle** -- Laws (identity, inverse, homomorphism) are domain-independent mathematical truths. AI cannot fabricate a law that "happens to pass" -- law correctness is provable independent of implementation.
- **Parametric Generation Multiplies Coverage** -- Single `it.effect.prop` invocation generates 50-200 cases per run, replacing hundreds of hand-written assertions with single universally-quantified property.
- **Mutation Testing Detects Circular Tests** -- Stryker injects code mutants (operator swaps, conditional negations, statement deletions). Circular tests re-deriving expected values from source code fail to kill mutants.

**Seven-Layer Defense:**

| [INDEX] | [LAYER]              | [MECHANISM]                         | [STATUS] |
| :-----: | -------------------- | ----------------------------------- | -------- |
|  [01]   | Algebraic PBT        | Laws are external oracles by nature | Active   |
|  [02]   | Model-Based Testing  | fc.commands() stateful verification | Active   |
|  [03]   | Differential Testing | Cross-validation vs reference impls | Active   |
|  [04]   | Mutation Testing     | Stryker kill-ratio enforcement      | Active   |
|  [05]   | External Oracles     | NIST FIPS 180-4, RFC 4231, RFC 6902 | Active   |
|  [06]   | PostToolUse Hook     | 13-rule awk validator               | Active   |
|  [07]   | Human Review         | Final gate for spec correctness     | Always   |

## [08]-[VALIDATION]

[VERIFY]:
- [ ] Thresholds met (section 2 above)
- [ ] File structure matches (section 3 above)
- [ ] No forbidden patterns (13 hook rules)
- [ ] Properties return `void | Effect<void>` (block syntax)
- [ ] Oracle independence verified -- no re-derivation of source logic
- [ ] Schema passed directly to `it.effect.prop` where possible (no `Arbitrary.make` wrapping)
- [ ] Contract tests use no mocks -- real schemas + `Layer.succeed` for minimal fakes
- [ ] No thin wrapper mock factories -- literal mocks inlined at `_provide` call site
- [ ] No duplicated orchestration -- repeated `Effect.gen` + `pipe` + `_provide` extracted to `[FUNCTIONS]` helper
- [ ] Stryker runs with TS checker enabled (`checkers: ['typescript']`)

**Stryker Integration:**
- [ALWAYS] Run `npx stryker run` after semantic gate passes.
- [ALWAYS] Verify TS checker is enabled in `stryker.config.mjs` (`checkers: ['typescript']`).
- [ALWAYS] Use `vitest.related: true` for per-mutant test scoping.
- [ALWAYS] Use dynamic concurrency (remove hardcoded `concurrency` setting).

[REFERENCE] Detailed checklists, error symptoms, and commands: [->validation.md](./references/validation.md). Hook rules and anti-patterns: [->guardrails.md](./references/guardrails.md).
