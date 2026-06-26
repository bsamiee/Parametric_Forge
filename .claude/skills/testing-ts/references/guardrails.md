# [H1][GUARDRAILS]

Two enforcement layers: **automated gates** (machine-checkable, zero-tolerance) and **design guardrails** (require judgment, enforced via review). Together they form defense-in-depth preventing circular, flaky, and implementation-confirming tests.

## [01]-[AUTOMATED_GATES]

### [1.1]-[HOOK_RULES]

The PostToolUse hook (`.claude/hooks/validate-spec.sh`) validates every `*.spec.ts` edit via single-pass awk. JSON `{"decision":"block","reason":"..."}` with line-specific errors for self-correction.

| [INDEX] | [RULE]             | [PATTERN]                                                      | [FIX]                                               |
| :-----: | ------------------ | -------------------------------------------------------------- | --------------------------------------------------- |
|   [01]   | LOC limit          | File exceeds 175 lines                                         | Pack properties, use `Effect.all` aggregation       |
|   [02]   | No `any`           | `: any`, `as any`, `<any>`, `, any>`                           | Branded types via Schema                            |
|   [03]   | No `let`/`var`     | `let x =`, `var x =`                                           | `const` only                                        |
|   [04]   | No loops           | `for (`, `while (`                                             | `.map`, `.filter`, `Effect.forEach`                 |
|   [05]   | No `try/catch`     | `try {`, `} catch (`                                           | Effect error channel (`.pipe(Effect.flip)`)         |
|   [06]   | No `new Date()`    | `new Date(`                                                    | `as const` constants or `TestClock`                 |
|   [07]   | No `if/else`       | `if (`, `} else`                                               | Ternary, `fc.pre()`, `Effect.fromNullable`          |
|   [08]   | No custom matchers | `.toSucceed(`, `.toBeRight(`, `.toFail(`, `.toBeLeft(`         | `it.effect()` + standard `expect()`                 |
|   [09]   | No default exports | `export default`                                               | Named exports only                                  |
|  [10]   | No Object.freeze   | `Object.freeze(`                                               | `as const` for immutability                         |
|  [11]   | Block syntax       | `Effect.sync/tap(() => expect(...)` without `=> {`             | `=> { expect(...); }` (returns void, not Assertion) |
|  [12]   | Import order       | @effect/vitest -> ${WORKSPACE_SCOPE}/* -> effect -> vitest     | Reorder to match sequence                           |
|  [13]   | Forbidden labels   | `[HELPERS]`, `[HANDLERS]`, `[UTILS]`, `[CONFIG]`, `[DISPATCH]` | Use CONSTANTS, LAYER, ALGEBRAIC, EDGE_CASES         |

### [1.2]-[MUTATION_THRESHOLDS]

Stryker injects code mutants (operator swaps, conditional negations, statement deletions, string mutations). Circular tests re-derive source logic and compute the same wrong answer as mutated source -- mutant survives.

| [INDEX] | [LEVEL] | [SCORE] | [ACTION]                                        |
| :-----: | :-----: | :-----: | ----------------------------------------------- |
|   [01]   |  high   |   80    | Target -- tests are contract-driven             |
|   [02]   |   low   |   60    | Investigate -- likely mirrors implementation    |
|   [03]   |  break  |   50    | Build fails -- test is circular or tautological |

**Kill strategies by mutant type:**

| [INDEX] | [MUTANT_TYPE]            | [WHAT_KILLS_IT]                           |
| :-----: | ------------------------ | ----------------------------------------- |
|   [01]   | Arithmetic operator swap | Algebraic law with cross-validated result |
|   [02]   | Conditional negation     | Property covering both branches           |
|   [03]   | Statement deletion       | Test that depends on deleted operation    |
|   [04]   | String mutation          | Known-answer vector comparison            |

## [02]-[ANTI_PATTERNS]

Hook rules catch syntactic violations. These anti-patterns catch **semantic** issues that require judgment:

| [INDEX] | [FORBIDDEN]                                                          | [REPLACEMENT]                                                                     |
| :-----: | -------------------------------------------------------------------- | --------------------------------------------------------------------------------- |
|   [01]   | Hardcoded test arrays                                                | `it.each(CONSTANT_TABLE)` or `Effect.forEach(VECTORS)`                            |
|   [02]   | Magic numbers                                                        | Named constants with `as const`                                                   |
|   [03]   | Re-deriving source logic                                             | Algebraic law or external oracle                                                  |
|   [04]   | Hand-rolled arbitraries                                              | Schema-derived arbitrary from `effect`                                            |
|   [05]   | Mock call-count assertions (`toHaveBeenCalledWith`) as primary test  | Test observable output or algebraic property                                      |
|   [06]   | Deep `vi.mock` of internal modules (>10 lines of mock setup)         | `layer()` with `Layer.succeed(Tag, stub)` or integration test with testcontainers |
|   [07]   | Testing mock wiring (did fn get called?)                             | Test return value shape, error tag, or behavioral property                        |
|   [08]   | Thin wrapper mock factories (`_mkAudit = () => ({ log: vi.fn(…) })`) | Inline literal at `_provide` call site; reserve `_mk*` for 2+ configurable fields |
|   [09]   | Duplicated `Effect.gen` + `pipe` + `_provide` across 3+ tests        | Extract `_transition`-style helper in `[FUNCTIONS]` section                       |
|  [10]   | Multi-line arbitrary definitions spanning 3+ lines                   | Compress to single `fc.tuple(…).map(…)` expression                                |

**Mock compression pattern:** Mock factories constructing a single-field object (`{ method: vi.fn(() => Effect.void) }`) are thin wrappers adding indirection without value. Inline the literal directly into `_provide` or `Effect.provideService`. Reserve named `_mk*` factories for mocks with 2+ configurable fields or conditional behavior (e.g., `_mkDb({ a?: …, ns?: …, set?: … })`).

## [03]-[ORACLE_INDEPENDENCE]

A test is **implementation-confirming** when changing internal algorithm (preserving contract) breaks it. These tests create maintenance burden and catch zero real bugs. Six detection signals:

| [INDEX] | [SIGNAL]                              | [FIX]                                        |
| :-----: | ------------------------------------- | -------------------------------------------- |
|   [01]   | Asserts internal data structures      | Assert output shape or behavioral property   |
|   [02]   | Mirrors source code branching logic   | Use algebraic law (identity, inverse, etc.)  |
|   [03]   | Hardcodes expected intermediate state | Generate inputs, assert only final invariant |
|   [04]   | Breaks when refactoring internals     | Test externally observable contract          |
|   [05]   | Tests private function directly       | Test via public API composition              |
|   [06]   | Low mutation score (< 60%)            | Replace with algebraic or oracle-based test  |

**Oracle classification:**

| [INDEX] | [ORACLE_TYPE]            | [STATUS]     | [EXAMPLE]                               |
| :-----: | ------------------------ | ------------ | --------------------------------------- |
|   [01]   | Algebraic law            | Independent  | `g(f(x)) = x` (inverse)                 |
|   [02]   | External reference impl  | Independent  | `createHash('sha256')` from node:crypto |
|   [03]   | Standards vectors        | Independent  | NIST FIPS 180-4, RFC 4231, RFC 6902     |
|   [04]   | Schema-derived arbitrary | Independent  | `Arbitrary.make(Schema)` for inputs     |
|   [05]   | Manually computed        | Verify       | Hand-calculate, document derivation     |
|   [06]   | Source output pasted     | **Circular** | **Replace** with law or oracle          |

## [04]-[DETERMINISM_AND_ISOLATION]

### [4.1]-[TIME_DETERMINISM]

All time-dependent tests use `TestClock.adjust` for virtual time progression. Real wall-clock (`it.scopedLive`) is reserved for integration tests requiring actual delays (container startup, semaphore saturation). Never mix TestClock and real timers in the same test.

### [4.2]-[ARBITRARY_SAFETY]

Filter arbitraries to exclude dangerous inputs that poison global state:
- **Proto pollution**: `_safeKey.filter((k) => !['__proto__', 'constructor', 'prototype'].includes(k))`
- **JSON injection**: `.filter((o) => !JSON.stringify(o).includes('"__proto__"'))`
- **Length bounds**: `maxLength` on strings prevents OOM; `maxKeys`/`maxDepth` on objects prevents combinatorial explosion

### [4.3]-[PRECONDITION_DISCIPLINE]

`fc.pre()` rejects invalid samples at generator level. If precondition rejects >5% of generated cases, the arbitrary is too broad -- narrow the generator instead. Excessive `fc.pre()` filtering degrades shrinking quality and wastes generation budget.

### [4.4]-[RESOURCE_CLEANUP]

Use `it.scoped` for tests requiring `Scope`-managed resources (semaphores, circuit breakers, fibers). The scope automatically releases resources on test completion. For integration tests: `beforeAll`/`afterAll` manage container lifecycle with explicit `60_000` timeout.

### [4.5]-[TEST_ISOLATION]

Each `it.effect` / `it.effect.prop` runs in a fresh Effect runtime. Shared state between tests must be immutable (`as const`) or re-initialized per test. Layer-scoped suites (`layer(testLayer)('name', ...)`) share a service layer but each test gets isolated fiber execution.

## [05]-[HUMAN_REVIEW]

Three criteria automation cannot verify:

1. **Law correctness** -- Algebraic laws accurately model domain contract. A syntactically valid law asserting a vacuous property (identity on a constant) provides false confidence.
2. **Generator quality** -- Arbitraries produce diverse, representative inputs covering edge cases. Schema-derived arbitraries preferred over hand-rolled. Verify generators exercise boundary conditions (empty strings, max-length, unicode, negative numbers).
3. **Coverage completeness** -- Properties cover all exported functions. Walk the law selection matrix per export. Missing functions = missing coverage regardless of per-file percentage.
