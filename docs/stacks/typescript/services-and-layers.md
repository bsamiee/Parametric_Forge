# [TYPESCRIPT_SERVICES_AND_LAYERS]

Capability is typed dataflow: a dependency is a Tag in the requirement channel, the Layer graph is the only construction mechanism, and this page owns the five decisions that follow — which owner form mints the Tag, which edge or node form wires the graph, which engine the root selects, where the graph becomes a runtime, and how a substitute enters. The owner is one `Effect.Service` class carrying Tag, default Layer, constructor, and accessors under one name — the interface-plus-tag-plus-layer triple is the ceremony this page deletes. Requirement pressure is a three-tier ladder the type system enforces: a `Context.Tag` read adds to `R` and the root must answer it, a `Context.Reference` read costs nothing because its default answers, and an `Effect.serviceOption` read costs nothing because absence is `Option`. Wiring is algebra, not assembly: `provide` hides an edge, `provideMerge` republishes it, `fresh` breaks sharing, `project` narrows, the discard family registers lifetime without surface, `unwrapEffect` lets a value decide the shape, and one shared layer reference builds once across every arm of a diamond. The root's declared annotation — `Layer.Layer<Out>` with error and requirement defaulted to `never` — is the wiring proof, failed at the declaration rather than the run seam. A definition names no engine; the root selects one. Substitution is Layer provision against the same Tag, never a module patch. The named defect is wiring sprawl: beside-interfaces, module-level live singletons, parameter-drilled dependencies, per-call graph rebuilds, and mock frameworks.

## [01]-[WIRING_CHOOSER]

When a concern matches several rows, the most specific wins; owner form is decided before edge, edge before runtime.

| [INDEX] | [CONCERN_SIGNATURE]                          | [FORM]                                        | [REJECTED_FORM]                           |
| :-----: | :------------------------------------------- | :-------------------------------------------- | :---------------------------------------- |
|  [01]   | owned capability, one canonical construction | `Effect.Service` class owner                  | interface + Tag + Layer triple            |
|  [02]   | replaceable capability, many engines         | `Context.Tag` port, root selects a Layer      | engine named inside the definition        |
|  [03]   | ambient policy with a sensible default       | `Context.Reference`                           | knob threaded through every signature     |
|  [04]   | capability present only in some environments | `Effect.serviceOption` read                   | nullable service field                    |
|  [05]   | dependency consumed, hidden from output      | `Layer.provide`                               | `provideMerge` widening by reflex         |
|  [06]   | dependency consumed and republished          | `Layer.provideMerge`                          | re-providing the same layer downstream    |
|  [07]   | sibling capabilities with no edge between    | `Layer.mergeAll`                              | nested `provide` chains faking an edge    |
|  [08]   | rich service narrowed to a focused port      | `Layer.project`                               | hand-built adapter layer                  |
|  [09]   | shared resource needing a private copy       | `Layer.fresh`                                 | second layer const duplicating the first  |
|  [10]   | graph work publishing no service             | `Layer.scopedDiscard` / `Layer.effectDiscard` | phantom Tag minted to carry a side effect |
|  [11]   | process-wide telemetry export                | `Otlp.layerJson`/`layerProtobuf` at the root  | exporter imported in an interior file     |
|  [12]   | construction needs log or span identity      | `Layer.annotateLogs` / `Layer.withSpan`       | hand-stamped logging in every constructor |
|  [13]   | one build shared across sequenced builds     | `Layer.memoize` under `Effect.scoped`         | module-hoisted runtime faking the share   |
|  [14]   | graph shape decided by a runtime value       | `Layer.unwrapEffect` / `Layer.unwrapScoped`   | branching between two prebuilt runtimes   |
|  [15]   | imperative host calls in repeatedly          | `ManagedRuntime.make`                         | per-call `Effect.runPromise` + re-provide |
|  [16]   | acquisitions shared across several runtimes  | one `Layer.MemoMap` fed to each runtime       | duplicated acquisitions, one god runtime  |
|  [17]   | process whose whole life is the graph        | `Layer.launch`                                | a runtime handle plus an idle main        |
|  [18]   | resource family keyed by a runtime value     | `LayerMap.Service`                            | hand map of runtimes, per-key singletons  |
|  [19]   | capability re-acquired on a schedule         | `Reloadable.auto`                             | tearing down and rebuilding the graph     |
|  [20]   | proof needs a substitute implementation      | test Layer over the same Tag                  | module patch, mock framework              |

## [02]-[SERVICE_OWNER]

[ONE_NAME_OWNER]:
- Law: a service is one class — `class Shape extends Effect.Service<Shape>()("Shape", { … })` — and that single declaration is the Tag (`Context.Tag<Shape, Shape>`), the type of the built value, the default wiring (`Shape.Default`), the bare constructor (`Shape.make`), the one-shot call seam (`Shape.use`), and with `accessors: true` a static per-member proxy; a consumer takes one import and reaches every role through it, so an `interface` beside a `Context.GenericTag` beside a `Layer.effect` triple restates one concept three times and is deleted on sight.
- Law: the Tag key is a global identity — two Tags minted with the same string unify into one context slot regardless of their declared shapes — so one key has one owning declaration and carries its owner's path segment; a duplicated key is a silent service collision, not a compile error.
- Law: construction is a four-knob ladder fixed by what the build needs — `succeed` for a ready value, `sync` for a lazy thunk, `effect` for a dependent or fallible build, `scoped` for a build whose teardown registers on the graph `Scope` via `Effect.acquireRelease` or `Effect.addFinalizer` and whose `Effect.forkScoped` children die with the Layer — and giving the knob a function `(...args) => Effect` turns `Shape.Default` into a Layer factory, which is the one sanctioned way a layer takes parameters.
- Law: `dependencies: [Dep.Default]` bakes upstream defaults into `Shape.Default` and mints `Shape.DefaultWithoutDependencies` beside it; the baked form is the ninety-percent import, the unbaked form exists exactly for rewiring an upstream edge without re-declaring the service.
- Use: `accessors: true` whenever the service shape is non-generic — `Shape.member` is the call-site spelling and each accessor carries `R = Shape` so the requirement is never hidden.
- Reject: `Effect.Tag` accessor-only owners and `Context.GenericTag` string minting — both survive only as quarry in code this page replaces; a service shape key named `make`, `use`, `of`, `key`, `pipe`, `name`, `context`, `stack`, `_tag`, `Default`, or `DefaultWithoutDependencies` — the class statics own those names and the compiler rejects the shadow with a `property "…" is forbidden` literal.

[TAG_TIER]:
- Law: the tier is requirement pressure, and the pressure is visible in `R` — `yield*` on a `Context.Tag` types as `Effect<Shape, never, Shape>` so the root must answer; `yield*` on a `Context.Reference` types as `Effect<Value>` because `defaultValue` answers when no Layer overrides; `Effect.serviceOption(Tag)` types as `Effect<Option<Shape>>` so presence is data and the read never blocks the wiring proof. Choose by what an unwired root means: a compile error, a default, or a `None`.
- Law: a `Context.Reference` override is still Layer provision — `Layer.succeed(Ref, value)` at the root or a scoped `Effect.provideService` around one call — so ambient policy rides the same substitution mechanism as every hard capability and never becomes a parameter tail; the constructor ships `@experimental`, an admission the pin owns.
- Law: the tier ledger is visible in the owner's own `Default` type — a constructor that reads only defaulted and optional tiers publishes `Layer.Layer<Self>` with the requirement tail already `never`, so how much of the graph a service drags behind it is read off one annotation, never discovered at the root.
- Boundary: a port whose implementations vary by deployment is chooser row `[02]` even when a default exists — a `Reference` default is policy data, never a live engine; an engine default smuggles the root's selection into the definition.
- Reject: `Effect.serviceOptional` where the absence case has a policy — it converts absence into `NoSuchElementException` and forfeits the `Option` fold.

```typescript conceptual
import { Context, Effect, HashMap, Option, Ref } from "effect";

class Budget extends Context.Reference<Budget>()("<scope>/Budget", {
    defaultValue: () => ({ capacity: 64, floor: 8 }),
}) {}

class Probe extends Context.Tag("<scope>/Probe")<
    Probe,
    {
        readonly observed: (label: string, count: number) => Effect.Effect<void>;
    }
>() {}

class Registry extends Effect.Service<Registry>()("<scope>/Registry", {
    scoped: Effect.gen(function* () {
        const budget = yield* Budget;
        const probe = yield* Effect.serviceOption(Probe);
        const cells = yield* Ref.make(HashMap.empty<string, number>());
        const emit = (label: string) => (count: number) =>
            Option.match(probe, {
                onNone: () => Effect.void,
                onSome: (active) => active.observed(label, count),
            });
        // teardown flushes the final census to the probe before the graph closes
        yield* Effect.addFinalizer(() => Ref.get(cells).pipe(Effect.flatMap((held) => emit("drained")(HashMap.size(held)))));
        return {
            leased: (key: string) =>
                Ref.modify(cells, (held) =>
                    Option.match(HashMap.get(held, key), {
                        onNone: () => [budget.capacity - 1, HashMap.set(held, key, budget.capacity - 1)] as const,
                        onSome: (left) =>
                            left - 1 < budget.floor
                                ? ([left - 1, HashMap.remove(held, key)] as const) // an exhausted lease leaves the census; the next lease re-seeds at capacity
                                : ([left - 1, HashMap.set(held, key, left - 1)] as const),
                    }),
                ).pipe(Effect.tap(emit("leased"))),
            census: Ref.get(cells).pipe(Effect.map(HashMap.size)),
        };
    }),
    accessors: true,
}) {}

// --- [EXPORTS] --------------------------------------------------------------------------

export { Budget, Probe, Registry };
```

## [03]-[LAYER_ALGEBRA]

[GRAPH_EDGES]:
- Law: `Layer.provide` is the internal edge — the dependency is consumed and vanishes from the output type — and `Layer.provideMerge` is the republishing edge — consumed and kept public; the choice is an API decision about what the composed layer exposes, made per edge, never a default. `Layer.mergeAll` composes siblings that share no edge, and `Layer.provide([A, B])` takes the tuple form so one call wires several suppliers.
- Law: `Layer.project(source, TagA, TagB, view)` derives a focused port from a rich service as a type-checked projection — the narrowing lives at the layer value, so a consumer of the narrow Tag cannot reach the wide surface and no adapter class exists.
- Law: layer construction failure is graph policy attached at the layer value — `Layer.retry(schedule)` re-drives a flaky acquisition, `Layer.orElse` falls back to an alternate supplier, `Layer.orDie` rules the failure unrecoverable, `Layer.tapErrorCause` observes it — composed where the layer is declared, never `try`/`catch` around the run seam.
- Boundary: this policy governs construction once — per-call tiered failover across provided engines, with budgets and gates per tier, is the `ExecutionPlan` ladder, `rails-and-effects.md`'s; this page owns each tier's `Layer`.
- Reject: providing the same dependency at two altitudes — the deeper `provide` shadows the root's substitution and splits the diamond.

[REGISTRATION_NODES]:
- Law: work whose value is its lifetime publishes `never` — `Layer.scopedDiscard(effect)` when the registration owns teardown (a poller forked with `Effect.forkScoped`, a handler deregistered with the graph), `Layer.effectDiscard` for one-shot boot work, `Layer.discard` to demote an output-bearing layer to its side effects — and a `Layer<never>` merged at the root adds lifetime without widening the output, so registration rides the same annotated proof as every service.
- Law: telemetry export is the canonical registration node — `Otlp.layer({ baseUrl, resource })` builds a `Layer<never>`, `Otlp.layerJson`/`Otlp.layerProtobuf` pre-select its serialization down to a plain `HttpClient` requirement — merged once at the root and satisfied by one platform client layer, so no interior file imports an exporter and swapping the export seam replaces one node.
- Law: construction observability attaches at the layer value — `Layer.annotateLogs(record)` stamps every log the build and its forked fibers emit and `Layer.annotateSpans(record)` carries the same record to the trace side, `Layer.withSpan(name)` wraps one node's construction, `Layer.span(name)` publishes `Tracer.ParentSpan` so the whole graph's construction nests under one span — boot forensics with zero constructor edits.
- Reject: a phantom Tag minted so a side effect has something to publish — the discard family is the spelling for output-free nodes.

[DIAMOND_MEMOIZATION]:
- Law: within one build, memoization is by reference identity — every arm that composes the same layer const shares one construction, so a diamond costs one acquisition with zero annotation; the corollary is load-bearing: a layer minted by calling a factory twice is two nodes, so a shared resource is declared once as a const and every consumer composes that reference.
- Law: `Layer.fresh` is the sharing opt-out — it wraps the reference so its subtree builds privately — and it is the only spelling for a private copy; duplicating the layer declaration to break sharing hides the intent and forks the configuration.
- Law: `Layer.memoize` extends sharing across sequenced builds — the call shape is effectful: `yield* Layer.memoize(layer)` under `Effect.scoped` yields a handle whose every `Effect.provide` reuses one construction, and the sharing window closes with the scope.

[ROOT_PROOF]:
- Law: the composition root is annotated, not inferred — `const root: Layer.Layer<Out> = …` — and because `Layer.Layer<ROut, E, RIn>` defaults `E` and `RIn` to `never`, the annotation is the wiring proof: a missing edge or an unhandled construction fault fails at this declaration, one line, at compile time, before any run seam is reached.
- Law: `Layer.unwrapEffect` admits a value-decided graph — an `Effect<Layer<…>>` whose result shape the root cannot know statically — and `Layer.unwrapScoped` is the same seam when the deciding effect holds resources; both keep selection inside the layer algebra, so a runtime decision never leaks upward into two hand-assembled runtimes.
- Boundary: which services exist is this page's concern; what a built service does on the rail — spans, schedules, brackets — is `rails-and-effects.md`.

```typescript conceptual
import { Context, Effect, Layer, Schedule } from "effect";

class Conn extends Context.Tag("<scope>/Conn")<
    Conn,
    {
        readonly sent: (frame: string) => Effect.Effect<void>;
        readonly health: Effect.Effect<boolean>;
    }
>() {}

class Sender extends Context.Tag("<scope>/Sender")<
    Sender,
    {
        readonly sent: (frame: string) => Effect.Effect<void>;
    }
>() {}

const _ConnLive: Layer.Layer<Conn> = Layer.scoped(
    Conn,
    Effect.acquireRelease(Effect.succeed(Conn.of({ sent: (frame) => Effect.log(frame), health: Effect.succeed(true) })), () =>
        Effect.log("<conn-closed>"),
    ),
).pipe(Layer.retry(Schedule.jittered(Schedule.exponential("50 millis"))), Layer.annotateLogs({ node: "<conn>" }));

const _health: Effect.Effect<boolean, never, Conn> = Effect.flatMap(Conn, (conn) => conn.health);

class Store extends Effect.Service<Store>()("<scope>/Store", {
    effect: Effect.gen(function* () {
        const conn = yield* Conn;
        return { saved: (row: string) => conn.sent(`<store:${row}>`) };
    }),
    dependencies: [_ConnLive],
}) {}

class Meter extends Effect.Service<Meter>()("<scope>/Meter", {
    effect: Effect.gen(function* () {
        const conn = yield* Conn;
        return { counted: (label: string) => conn.sent(`<meter:${label}>`) };
    }),
    dependencies: [_ConnLive],
}) {}

// Layer<never>: lifetime only — the fresh copy keeps probe traffic off the domain diamond
const _heartbeat: Layer.Layer<never> = Layer.scopedDiscard(Effect.forkScoped(_health.pipe(Effect.repeat(Schedule.spaced("30 seconds"))))).pipe(
    Layer.provide(Layer.fresh(_ConnLive)),
    Layer.withSpan("<heartbeat-up>"),
);

const _domain: Layer.Layer<Store | Meter> = Layer.mergeAll(Store.Default, Meter.Default);
const _SenderLive: Layer.Layer<Sender> = Layer.project(_ConnLive, Conn, Sender, (conn) => ({ sent: conn.sent }));

const root: Layer.Layer<Store | Meter | Sender | Conn> = Layer.mergeAll(_domain, _SenderLive, _heartbeat).pipe(Layer.provideMerge(_ConnLive));

// one acquisition serves both sequenced builds; teardown when the scope closes
const probed: Effect.Effect<boolean> = Effect.scoped(
    Effect.gen(function* () {
        const shared = yield* Layer.memoize(_ConnLive);
        return (yield* Effect.provide(_health, shared)) && (yield* Effect.provide(_health, shared));
    }),
);

// --- [EXPORTS] --------------------------------------------------------------------------

export { Conn, Meter, Sender, Store, probed, root };
```

## [04]-[ENGINE_SWAP]

[PORT_LAW]:
- Law: a replaceable capability is a `Context.Tag` port — the definition declares the shape and the fault channel, consumers acquire it through `R`, and no file that declares or consumes the port names an implementation; each engine is one Layer satisfying the same Tag, so swapping engines edits the root and nothing else, and the port's shape is sized for the whole engine family at five-times demand, never for the first engine's convenience.
- Law: the same inversion holds at the work-definition altitude — an endpoint, workflow, activity, or handler is data plus Tag requirements, and the engine that executes it is a root Layer choice; a definition importing its runner has hardcoded the deployment into the domain.
- Reject: an abstract class or branded interface as the port — the Tag already carries nominal identity and the class form invites inheritance.

[ROOT_SELECTION]:
- Law: the engine roster is one interior `as const satisfies Record<string, Layer.Layer<Port>>` table — the engine union derives as `keyof typeof`, so admission (`Config.literal(...Struct.keys(table))`) and selection (`table[kind]`) read one anchor, and adding an engine is one row that updates the config validator, the type, and the dispatch in the same edit.
- Law: selection composes as `Layer.unwrapEffect` over the config read — the decision is itself an effect in the layer algebra, its `ConfigError` rides the layer's error channel, and the root that provides the selected engine still proves `never, never` or declares the config fault, one line either way.
- Use: `Layer.succeed(Port, Port.of({ … }))` as the zero-construction engine — the same table row shape serves a live engine, a stub, and a recorded fake.

```typescript conceptual
import { Config, type ConfigError, Context, Data, Effect, Layer, Ref, Struct } from "effect";

class TransportFault extends Data.TaggedError("TransportFault")<{ readonly frame: string }> {}

class Transport extends Context.Tag("<scope>/Transport")<
    Transport,
    {
        readonly dispatched: (frame: string) => Effect.Effect<string, TransportFault>;
    }
>() {}

const _DirectLive: Layer.Layer<Transport> = Layer.succeed(Transport, Transport.of({ dispatched: (frame) => Effect.succeed(`<direct:${frame}>`) }));

const _PooledLive: Layer.Layer<Transport> = Layer.scoped(
    Transport,
    Effect.gen(function* () {
        const lanes = yield* Effect.acquireRelease(Effect.succeed(2), () => Effect.log("<lanes-down>"));
        const turn = yield* Ref.make(0);
        return Transport.of({
            dispatched: (frame) =>
                frame.length === 0
                    ? Effect.fail(new TransportFault({ frame })) // the engine mints the port's declared fault: the refused frame rides as evidence
                    : Ref.getAndUpdate(turn, (spin) => spin + 1).pipe(Effect.map((spin) => `<pooled:${spin % lanes}:${frame}>`)),
        });
    }),
);

const _engines = {
    direct: _DirectLive,
    pooled: _PooledLive,
} as const satisfies Record<string, Layer.Layer<Transport>>;

const TransportLive: Layer.Layer<Transport, ConfigError.ConfigError> = Layer.unwrapEffect(
    Config.literal(...Struct.keys(_engines))("TRANSPORT_ENGINE").pipe(
        Config.withDefault("direct"),
        Effect.map((kind) => _engines[kind]),
    ),
);

const relayed = (frames: ReadonlyArray<string>): Effect.Effect<Array<string>, TransportFault, Transport> =>
    Transport.pipe(Effect.flatMap((transport) => Effect.forEach(frames, transport.dispatched, { concurrency: "inherit" })));

// --- [EXPORTS] --------------------------------------------------------------------------

export { Transport, TransportFault, TransportLive, relayed };
```

## [05]-[RUNTIME_ASSEMBLY]

[RUNTIME_ROOTS]:
- Law: the boot module is the one imperative seam — it makes runtimes, chains `dispose`, and nothing else in the codebase calls a run method; a process whose entire life is the graph boots with `Layer.launch` — build, suspend forever, teardown as interruption — and a host that calls in repeatedly — browser shell, worker bridge, foreign callback registry — holds a `ManagedRuntime.make(root)` whose `runPromise`/`runFork`/`runSync` methods carry the built context into every call, so the graph builds once and the per-call rebuild in chooser row `[15]` cannot exist.
- Law: several runtimes share acquisitions by sharing one `Layer.MemoMap` — mint it with `Layer.makeMemoMap`, pass it to each `ManagedRuntime.make(layer, memo)` — so a host runtime and a view runtime referencing the same layer consts hold the same instances, and disposal is per-runtime while the shared node lives until its last holder releases.
- Exemption: `dispose` returns a `Promise` and the boot seam chains it natively — this module is the platform-forced edge where `Promise` is legal.
- Boundary: the `runMain` boot mechanics, signal draining, and per-runtime bindings are `boundaries.md`'s; this page owns which runtime owner the process holds.

[KEYED_SCOPES]:
- Law: a resource family keyed by a runtime value — tenant, session, shard, region — is one `LayerMap.Service` owner: `lookup: (key) => Layer` declares how a key becomes a subgraph and composes the parameterized `Default` factory — `lookup: (key) => Shape.Default(key)`, which is why the `(...args) => Effect` constructor knob exists — `idleTimeToLive` declares when an unreferenced subgraph dies, a closed roster swaps `lookup` for `layers: { row: Layer }`, and `preloadKeys` warms named keys at construction; the statics carry the consumer surface — `.get(key)` yields the keyed Layer to provide, `.runtime(key)` a keyed `Runtime` under `Scope`, `.invalidate(key)` evicts. The module ships under the `@experimental` pin; the hand map of runtimes it replaces is the rejected form either way.
- Law: invalidation is the lifecycle edge — revocation, rotation, and a poisoned engine spell `.invalidate(key)`, and the next acquisition rebuilds the subgraph while every other key keeps its instance; tearing the whole graph to evict one key is the rejected form, and a keyed family whose lookup ignores its key is a shared service wearing a map.

[RELOADABLE_CAPABILITY]:
- Law: a capability that must refresh without tearing the graph — remote flags, rotated credentials, a polled roster — wraps as `Reloadable.auto(Tag, { layer, schedule })`; the Layer publishes `Reloadable.Reloadable<Tag>`, consumers read the current version through `Reloadable.get(Tag)` per use, and the schedule re-runs the underlying layer in place while every other node keeps its instance; `Reloadable.autoFromConfig(Tag, { layer, scheduleFromConfig })` derives the cadence from the layer's own config context when the refresh rate is itself an environment fact.
- Use: `Reloadable.manual(Tag, { layer })` with `Reloadable.reload(Tag)` when refresh is event-driven — the signal calls reload, readers are untouched — and `Reloadable.reloadFork(Tag)` when the signaler must not wait on reconstruction.
- Boundary: reload cadence is a `Schedule` value; its composition algebra is `rails-and-effects.md`.

```typescript conceptual
import { Clock, Context, Duration, Effect, Layer, LayerMap, ManagedRuntime, Reloadable, Schedule } from "effect";

class Roster extends Context.Tag("<scope>/Roster")<
    Roster,
    {
        readonly minted: number;
        readonly allowed: (tenant: string) => boolean;
    }
>() {}

// each reload re-reads the clock: minted is the version witness consumers compare
const _RosterLive: Layer.Layer<Roster> = Layer.effect(
    Roster,
    Effect.map(Clock.currentTimeMillis, (minted) => Roster.of({ minted, allowed: (tenant) => tenant.length <= 32 })),
);

const RosterAuto: Layer.Layer<Reloadable.Reloadable<Roster>> = Reloadable.auto(Roster, {
    layer: _RosterLive,
    schedule: Schedule.spaced(Duration.minutes(10)),
});

class Vault extends Effect.Service<Vault>()("<scope>/Vault", {
    effect: (tenant: string) => Effect.succeed({ read: (key: string) => Effect.succeed(`<${tenant}:${key}>`) }),
}) {}

class Tenants extends LayerMap.Service<Tenants>()("<scope>/Tenants", {
    lookup: (tenant: string) => Vault.Default(tenant),
    idleTimeToLive: Duration.minutes(5),
}) {}

const _read = (tenant: string, key: string): Effect.Effect<string, never, Tenants> =>
    Vault.use((vault) => vault.read(key)).pipe(Effect.provide(Tenants.get(tenant)));

const _memo: Layer.MemoMap = Effect.runSync(Layer.makeMemoMap); // the memo mint is runtime making: a boot-seam run call
const host: ManagedRuntime.ManagedRuntime<Tenants | Reloadable.Reloadable<Roster>, never> = ManagedRuntime.make(
    Layer.mergeAll(Tenants.Default, RosterAuto),
    _memo,
);
const _board: ManagedRuntime.ManagedRuntime<Reloadable.Reloadable<Roster>, never> = ManagedRuntime.make(RosterAuto, _memo);

// a disallowed tenant loses its keyed subgraph; the next acquisition rebuilds it
const served = (tenant: string, key: string): Promise<string> =>
    host.runPromise(
        Effect.flatMap(Reloadable.get(Roster), (roster) =>
            roster.allowed(tenant) ? _read(tenant, key) : Effect.as(Tenants.invalidate(tenant), "<revoked>"),
        ),
    );

const halted = (): Promise<void> => _board.dispose().then(() => host.dispose());

// --- [EXPORTS] --------------------------------------------------------------------------

export { Roster, RosterAuto, Tenants, Vault, halted, host, served };
```

## [06]-[TEST_SUBSTITUTION]

[SUBSTITUTION_LAW]:
- Law: a substitute is a Layer against the same Tag — `Layer.succeed(Port, Port.of({ … }))` for a value-backed fake, a full test engine Layer from the `[04]` roster when behavior matters, `Layer.mock(Tag, partial)` when the proof exercises one member of a wide port — an omitted member reached at runtime throws an `UnimplementedError` defect, so the gap is loud — and because the Tag types the slot, a substitute with the wrong shape fails at the provision line; module patching and mock frameworks substitute by name at distance, prove nothing about shape, and are rejected on sight.
- Law: configuration substitutes through the same mechanism — `Layer.setConfigProvider(ConfigProvider.fromMap(…))` provided to the graph under test, with `Layer.orDie` ruling a malformed pin a harness defect rather than a typed outcome — so a proof pins its environment as data and no ambient variable leaks in.
- Law: the graph under test is the production composition with edges re-provided — substitute at the port seam, keep every interior edge real — because a proof against a hand-assembled parallel graph proves the parallel graph; a service whose edges were baked through `dependencies` re-opens them as `DefaultWithoutDependencies` plus the substitute Layer, never a re-declared service.
- Reject: `Layer.mock` where the omitted member is reachable on the asserted path — the defect becomes the test outcome and the proof reads as a crash.

[PROOF_BLOCK]:
- Law: a proof block opens with the standalone `layer(SharedGraph)(name, (it) => { … })` — the graph builds once, every `it.effect` in the block receives it, teardown runs after — and block-local extension nests through `it.layer(child)`; acquiring per test what the block shares is the harness restating the memoization law by hand.
- Law: the block options are the harness's graph policy — `{ memoMap }` extends the by-reference share across sibling blocks handed the same map, `{ timeout }` bounds the build, and `{ excludeTestServices: true }` runs the block's testers on live services where determinism must yield — and `it.scoped` is the tester whose proof itself acquires, the block graph plus a per-test `Scope`.
- Law: `it.effect` runs under deterministic `TestServices` — time is virtual until `TestClock.adjust` moves it, randomness is seeded — so a duration-dependent path is proven by forking the effect, adjusting the clock, and joining the fiber: zero wall-clock waits, zero flake.
- Boundary: a spec module's public surface is empty — the collector call is its one side effect, so the exports block carries nothing and inline exports remain banned.

```typescript test-only
import { expect, layer } from "@effect/vitest";
import { Config, ConfigProvider, Context, Duration, Effect, Fiber, Layer, TestClock } from "effect";

class Gate extends Context.Tag("<scope>/Gate")<
    Gate,
    {
        // Gate and Journal stand in for the imported production owners
        readonly opened: (label: string) => Effect.Effect<boolean>;
        readonly sealed: (label: string) => Effect.Effect<void>;
    }
>() {}

class Journal extends Effect.Service<Journal>()("<scope>/Journal", {
    effect: Effect.gen(function* () {
        const gate = yield* Gate;
        const window = yield* Config.duration("WINDOW").pipe(Config.withDefault(Duration.seconds(30)));
        return {
            admitted: (label: string) =>
                Effect.flatMap(gate.opened(label), (open) => (open ? Effect.succeed(label) : Effect.as(Effect.sleep(window), `<parked:${label}>`))),
        };
    }),
}) {}

const _GateStub: Layer.Layer<Gate> = Layer.mock(Gate, {
    opened: (label) => Effect.succeed(label.startsWith("<live")),
});

const _TestGraph: Layer.Layer<Journal> = Journal.Default.pipe(
    Layer.provide(_GateStub),
    Layer.provide(Layer.setConfigProvider(ConfigProvider.fromMap(new Map([["WINDOW", "5 seconds"]])))),
    Layer.orDie,
);

layer(_TestGraph)("journal", (it) => {
    it.effect("parks a closed gate after the virtual window", () =>
        Effect.gen(function* () {
            const journal = yield* Journal;
            const parked = yield* Effect.fork(journal.admitted("<cold:one>"));
            yield* TestClock.adjust(Duration.seconds(5));
            expect(yield* Fiber.join(parked)).toBe("<parked:<cold:one>>");
        }),
    );

    it.effect("admits a live label with zero clock movement", () =>
        Effect.gen(function* () {
            const journal = yield* Journal;
            expect(yield* journal.admitted("<live:two>")).toBe("<live:two>");
        }),
    );
});

// --- [EXPORTS] --------------------------------------------------------------------------

export {};
```
