# [H1][TEST_CATEGORIES]

[IMPORTANT] Walk routing matrix per module. Pure modules route to Unit PBT. Boundary modules (database, HTTP, Redis) route to Integration. Cross-service orchestration routes to System. User-facing flows route to E2E.

## [01]-[ROUTING_MATRIX]

| [INDEX] | **Category** | [LOCATION]              | [ENV]    | [KEY_TOOLS]                  | [ROUTE_WHEN]                      |
| :-----: | ------------ | ----------------------- | -------- | ---------------------------- | --------------------------------- |
|   [01]   | Unit (PBT)   | `tests/unit/`           | node     | @effect/vitest, fast-check   | Pure functions, domain logic.     |
|   [02]   | App          | `tests/apps/{app}/`     | node     | @effect/vitest, fast-check   | App bootstrap, migration, config. |
|   [03]   | Integration  | `tests/integration/`    | node     | testcontainers, MSW          | Database, Redis, HTTP boundaries. |
|   [04]   | System       | `tests/system/`         | node     | Full Layer stack, mock edges | Cross-service orchestration.      |
|   [05]   | E2E          | `tests/e2e/`            | chromium | Playwright, agent pipeline   | User-facing flows, visual checks. |

## [02]-[UNIT_PBT]

**Environment:** node (root-tests or packages-node Vitest project).
**Tools:** `@effect/vitest` (`it.effect`, `it.effect.prop`, `layer`), fast-check arbitraries, `node:crypto` (differential oracle).

**Setup:** `tests/setup.ts` registers `addEqualityTesters()` -- structural equality for Effect types in `expect().toEqual()`. No custom matchers -- standard `expect()` via `it.effect()`.

**Layer Scoping:** Compose test layer via `Module.Service.Default.pipe(Layer.provide(...))`. Wrap suite in `layer(_testLayer)('Suite', (it) => { ... })` for automatic service resolution.

**Patterns:**

| [INDEX] | **Pattern**                | [MECHANISM]                                                    |
| :-----: | -------------------------- | -------------------------------------------------------------- |
|   [01]   | Algebraic laws             | Identity, inverse, idempotent, composition, symmetry.          |
|   [02]   | Property packing           | 2-4 laws sharing arbitrary shape in single `it.effect.prop`.   |
|   [03]   | Schema-derived arbitraries | `Arbitrary.make(Schema)` synced with domain types.             |
|   [04]   | Differential testing       | Cross-validate against `node:crypto`, `rfc6902`.               |
|   [05]   | Known-answer vectors       | NIST FIPS 180-4, RFC 4231, RFC 6902 as `as const`.             |
|   [06]   | Statistical properties     | Chi-squared uniformity, batch sampling via `fc.sample`.        |
|   [07]   | Model-based commands       | `fc.commands()` + `fc.asyncModelRun()` for stateful sequences. |
|   [08]   | Metamorphic relations      | Composition law: `f(f(a,b), c) = f(a, f(b,c))`.                |
|   [09]   | Fault injection            | Effect layer wrapping for Nth-call failure, TestClock.         |

**Routing Decision:** Any `packages/server/src/` module exporting pure functions, Effect service methods, schema validation, or error discrimination.

[REFERENCE] Law selection: [→laws.md](./laws.md) — Density techniques: [→density.md](./density.md).

## [03]-[INTEGRATION]

**Environment:** node (root-tests Vitest project).
**Tools:** testcontainers (`GenericContainer`, `Wait`), MSW (`http.get`, `http.post` handlers).

**Container Lifecycle:** Start in `beforeAll` (60s timeout for pull/start). Stop in `afterAll`. Compose real service layer with container-provided connection via `Layer.provide(ConnectionPool.layer({ host, port }))`.

**Vitest Pool:** Prefer `forks` for database tests -- process-level isolation prevents connection pool interference.

**Patterns:**

| [INDEX] | **Pattern**             | [MECHANISM]                                               |
| :-----: | ----------------------- | --------------------------------------------------------- |
|   [01]   | Roundtrip PBT           | Insert, query, compare against real DB.                   |
|   [02]   | HTTP boundary mocking   | MSW handlers intercept outgoing HTTP; verify payloads.    |
|   [03]   | Error path verification | Connection failures, timeouts, constraint violations.     |
|   [04]   | Transaction isolation   | Concurrent writes produce consistent reads.               |
|   [05]   | Schema migration        | Migrate up, verify structure, migrate down, verify clean. |

**Routing Decision:** Modules communicating with PostgreSQL, Redis, or external HTTP services. Verify SQL queries, cache operations, HTTP client behavior.

## [3.5]-[CONTRACT]

**Environment:** node (root-tests or packages-node Vitest project).
**Tools:** `@effect/vitest` (`it.effect`, `it.effect.prop`, `layer`), `Schema.decodeUnknown`, `Effect.provideService`, `Arbitrary.make`.

**Contract tests** verify that:
1. Package A's exported schemas decode values Package B produces
2. Service tags are structurally compatible across boundaries
3. Layer composition succeeds when connecting real package exports

**No mocks** -- uses real schemas and service tags with `Layer.succeed` for minimal fakes.

**Patterns:**

| [INDEX] | **Pattern**        | [MECHANISM]                                                         |
| :-----: | ------------------ | ------------------------------------------------------------------- |
|   [01]   | Schema roundtrip   | `S.decodeUnknown(ExportedSchema)(generated_input)` succeeds         |
|   [02]   | Service tag shape  | `Effect.provideService(ServiceTag, minimal_impl)` compiles and runs |
|   [03]   | Layer merge        | `Layer.merge(PkgA.Default, PkgB.Default)` builds without error      |
|   [04]   | Decode PBT         | `it.effect.prop` with `Arbitrary.make(SchemaFromPkgA)` roundtrips   |
|   [05]   | Cross-package type | Values produced by PkgB decode through PkgA's schema                |

**Routing Decision:** Cross-package schema compatibility, service tag structural checks, layer composition verification. Use when two packages share types or services at their boundary.

## [04]-[SYSTEM]

**Environment:** node.
**Tools:** Full service stack composed via Effect Layer. Services mock at edges -- no containers.

**Layer Composition:** Merge service layers via `Layer.provideMerge(ServiceA.Default, ServiceB.Default)`. Inject test config via `ConfigProvider.fromMap`. Suppress logs via `Logger.minimumLogLevel(LogLevel.Warning)`.

**Patterns:**

| [INDEX] | **Pattern**               | [MECHANISM]                                          |
| :-----: | ------------------------- | ---------------------------------------------------- |
|   [01]   | Boundary contract         | ServiceA calls ServiceB; verify contract holds.      |
|   [02]   | Error propagation         | Error from ServiceB surfaces correctly in ServiceA.  |
|   [03]   | Multi-step pipelines      | End-to-end Effect workflows across services.         |
|   [04]   | Configuration interaction | Config changes affect cross-service behavior.        |
|   [05]   | Schema contract           | Service input/output schemas validate at boundaries. |

**Routing Decision:** Cross-service interactions. Error propagation chains. API route handlers orchestrating multiple services.

## [05]-[E2E]

**Environment:** chromium (Playwright).
**Agent Pipeline:** planner (UI exploration) -> generator (spec creation) -> healer (failure remediation). Agents handle E2E spec generation -- do not manually author.

**Bootstrap:** Start only physically present applications or documented test fixtures for the current workspace.

**Artifacts:** Screenshots (only-on-failure), Videos (retain-on-failure), Traces (retain-on-failure).

**Standards:**

| [INDEX] | **Standard**       | [RULE]                                                     |
| :-----: | ------------------ | ---------------------------------------------------------- |
|   [01]   | Spec scope         | One spec per user flow (login, navigation, CRUD).          |
|   [02]   | Selectors          | `data-testid` attributes only; avoid class names.          |
|   [03]   | Network            | Wait for network idle before data-dependent assertions.    |
|   [04]   | Constants          | Frozen `B` object with routes, selectors, expected values. |
|   [05]   | Failure simulation | `page.route()` for latency injection, response mocking.    |

**Routing Decision:** User-facing flows. Visual verification. Cross-app navigation. Authentication flows. Invoke Playwright agent pipeline.

## [06]-[CROSS_CUTTING]

| [INDEX] | **Technique**        | [SCOPE]                | [MECHANISM]                                        |
| :-----: | -------------------- | ---------------------- | -------------------------------------------------- |
|   [01]   | Mutation testing     | All unit + integration | Stryker injects mutants; kill-ratio enforcement.   |
|   [02]   | Security properties  | Unit PBT + integration | Proto pollution, tenant isolation, path traversal. |
|   [03]   | TestClock patterns   | Unit + system          | Deterministic time via `TestClock.adjust`.         |
|   [04]   | Schema-derived arbs  | Unit PBT + integration | `Arbitrary.make(Schema)` from domain schemas.      |
|   [05]   | Race detection       | Unit + integration     | `fc.scheduler()` adversarial async interleaving.   |
|   [06]   | Type-level tests     | Unit PBT               | `expectTypeOf` + `@ts-expect-error` assertions.    |
|   [07]   | Benchmark regression | Unit + system          | `vitest bench` for perf-sensitive hot paths.       |

[REFERENCE] Mutation defense: [→guardrails.md](./guardrails.md) — Validation: [→validation.md](./validation.md).
