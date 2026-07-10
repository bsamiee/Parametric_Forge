# [TYPESCRIPT_BOUNDARIES]

The edge is the only place the system meets material it did not mint: wire payloads, foreign codecs, callback surfaces, platform capability, sibling threads and peers, durable stores. This page fixes where each crossing converts and who owns it, so that no module past a seam names a provider shape, re-validates an admitted value, or resolves a runtime. Every seam is a declaration site: what crosses, in which direction, with which fault, is recoverable from the owner alone.

## [01]-[EDGE_CHOOSER]

When a foreign signal matches several rows, the most specific owner wins, and identity rows are read before transport rows.

| [INDEX] | [FOREIGN_SIGNAL]               | [SEAM_OWNER]                    | [INTERIOR_FORM]                 | [REJECTED_FORM]                |
| :-----: | :----------------------------- | :------------------------------ | :------------------------------ | :----------------------------- |
|  [01]   | raw payload: body/file/message | Schema owner at first sight     | decoded value on the rail       | interior re-validation         |
|  [02]   | signed or hashed octets        | opaque byte band at admission   | digest receipt + projection     | parse-then-reserialize         |
|  [03]   | trace identity in headers      | `HttpTraceContext` codec family | `Option`-carried parent span    | hand-parsed `traceparent`      |
|  [04]   | HTTP, RPC, or CLI surface      | contribution family             | derived server, client, spec    | hand-rolled route table        |
|  [05]   | foreign binary or text format  | `Schema.transformOrFail` codec  | `ParseError` on the decode rail | second codec fault family      |
|  [06]   | platform capability            | abstract `Context.Tag`          | requirement in the `R` channel  | direct `node:*`/`fetch` import |
|  [07]   | foreign callback API           | `Effectify.effectify`           | typed effect signature          | per-site `Effect.async` wrap   |
|  [08]   | environment or config read     | `Config` provider chain         | validated value at construction | scattered `process.env` reads  |
|  [09]   | process start                  | `runMain` in one boot module    | drained fibers and finalizers   | top-level `Effect.runPromise`  |
|  [10]   | host cancellation signal       | `{ signal }`, `tryPromise`      | fiber interruption on `Cause`   | `AbortController` in domain    |
|  [11]   | off-thread or socket handoff   | Schema-typed marshal frame      | tagged request/response family  | untyped `postMessage` payload  |
|  [12]   | relational store               | `SqlClient`; `sql` statements   | `SqlSchema`-fused decoded rows  | hand-built SQL, driver import  |
|  [13]   | store read after writes        | `Reactivity` keyed invalidation | re-run `Mailbox`/`Stream`       | cadence poll of unchanged rows |
|  [14]   | reactive view binding          | `Atom.runtime` over Layer graph | `useAtomValue`/`useAtomSet`     | `run*`, per-render Layer       |
|  [15]   | wasm module                    | scoped capability-Tag instance  | calls through the marked kernel | escaping linear-memory view    |

- [04]: contribution family: endpoint/group expressed as data.
- [06]: platform capability: fs, net, exec.

## [02]-[ADMISSION]

[DECODE_PLACEMENT]:

- Use: every ingress — request bodies, headers, query params, file content, message frames, storage reads.
- Law: the decode sits on the first line that sees the foreign value, and that seam fixes three decisions at once: the owner (`Schema.decodeUnknown(Owner)`), the accumulation posture (`errors: "all"` for reportable admission, first-error for guard seams), and the drift posture (`onExcessProperty: "error"` where an unknown member is evidence of contract skew, the default where extension bands are tolerated). The configured decode is a module-scope value — one admission policy per seam, never per call.
- Law: HTTP decode is written once against the owner both edges instantiate — `HttpServerRequest` and `HttpClientResponse` extend `HttpIncomingMessage` with the edge's fault as `E` (`RequestError`, `ResponseError`), so `HttpIncomingMessage.schemaBodyJson`/`schemaBodyUrlParams`/`schemaHeaders` fuse read, decode, and error lift for server ingress and client replies in one spelling; the server edge adds `HttpServerRequest.schemaSearchParams`/`schemaCookies`, the reply edge adds `HttpClientResponse.schemaJson`/`matchStatus`, and `HttpIncomingMessage.withMaxBodySize` scopes the admission ceiling before any byte materializes. A raw body read followed by a separate validate, or a decode family maintained per edge, is the fused owner decomposed by hand.
- Law: causal identity crosses as headers through one codec family — `HttpTraceContext.toHeaders` stamps a span outbound, `HttpTraceContext.fromHeaders` recovers `Option<Tracer.ExternalSpan>` inbound, and the `w3c`/`b3`/`xb3` rows select the dialect; `HttpClient.withTracerPropagation` composes the stamp onto the shared client, so a hand-parsed `traceparent` header re-implements a codec the platform ships.
- Law: a foreign value that resurfaces past the seam — a nested `unknown` band, a lazy provider default, a second read from the same source — is a second admission site, not a leaked first one; it decodes where it appears, because the first decode never covered it and interior totality holds only over what was admitted.
- Law: egress is the mirror seam — `Schema.encode` at the explicit projection point, never field-by-field serialization; the encoded twin derives from the same owner, so the wire shape cannot skew from the interior shape.
- Exemption: the `TextDecoder` byte-to-text crossing inside the admission kernel is the named platform-forced seam.
- Reject: a decoded value re-checked downstream; a decode inside a loop body where the seam owns the collection; `ParseResult.ArrayFormatter`/`TreeFormatter` rendering anywhere but the terminal reporting edge; an `as` cast standing where a decode produces evidence.

[BYTE_IDENTITY]:

- Use: signatures, content keys, idempotency tokens, checksum verification, byte-stable forwarding.
- Law: a sub-band that must round-trip byte-identically is held opaque at admission — `Schema.Uint8ArrayFromSelf` in memory, `Schema.Uint8ArrayFromBase64` across a text wire — and the digest computes over those held octets before any content parse; identity and content are two projections of one admission, never two reads of the source.
- Law: parse-then-reserialize is rejected for signed material — a re-encode respells float forms, key order, and escapes — so forwarding emits the held octets verbatim, and `Schema.encode` of the envelope re-emits the same band bytes by construction.
- Boundary: the receipt carries the coordinate and the digest, never the octets; the digest function is fixed at composition and arrives as a parameter or service, never chosen per site.

```typescript conceptual
import { Effect, Option, type ParseResult, Schema } from "effect";

// --- [MODELS] ---------------------------------------------------------------------------

class Passport extends Schema.Class<Passport>("Passport")({
    kind: Schema.Literal("<kind-a>", "<kind-b>"),
    extent: Schema.Number.pipe(Schema.positive(), Schema.brand("Extent")),
    note: Schema.optionalWith(Schema.String, { as: "Option" }),
}) {}

class Envelope extends Schema.Class<Envelope>("Envelope")({
    coordinate: Schema.String,
    band: Schema.Uint8ArrayFromBase64,
}) {
    static readonly emitted: (envelope: Envelope) => Effect.Effect<typeof Envelope.Encoded, ParseResult.ParseError> = Schema.encode(Envelope); // the configured encode rides the owner: egress is a derivation, never a sibling export
}

// --- [OPERATIONS] -----------------------------------------------------------------------

const _utf8 = new TextDecoder();
const _opened = Schema.decodeUnknown(Envelope, { errors: "all", onExcessProperty: "error" });
const _content = Schema.decodeUnknown(Schema.parseJson(Passport), { errors: "all" });

const admitted: (
    raw: unknown,
    digest: (octets: Uint8Array) => string,
) => Effect.Effect<
    { readonly key: string; readonly coordinate: string; readonly label: string; readonly passport: Passport },
    ParseResult.ParseError
> = Effect.fn("admitted")(function* (raw: unknown, digest: (octets: Uint8Array) => string) {
    const envelope = yield* _opened(raw);
    const passport = yield* _content(_utf8.decode(envelope.band));
    return {
        key: digest(envelope.band),
        coordinate: envelope.coordinate,
        label: Option.getOrElse(passport.note, () => "<value-a>"),
        passport,
    } as const;
});

// --- [EXPORTS] --------------------------------------------------------------------------

export { admitted, Envelope, Passport };
```

## [03]-[CONTRACT_FAMILY]

[CONTRIBUTION_FAMILY]:

- Use: every HTTP, RPC, and CLI entry surface.
- Law: the contract is data — `HttpApiEndpoint` carries path, payload, success, and error Schemas as one declaration (`HttpApiEndpoint.get(name, path)` with `.setPath`/`.setPayload`/`.addSuccess`/`.addError`, or the `HttpApiSchema.param` template form); `HttpApiGroup.make(name).add(endpoint)` is the owning module's contribution; exactly one `HttpApi.make(id).add(group)` assembles at the composition root, so no lib-side module spells a god contract.
- Law: the same assembly law spans transports — `RpcGroup.make(...Rpc.make(tag, { payload, success, error, stream }))` is the procedure family, and the CLI command tree contributes verbs under the identical shape; protocol and serialization cross as two orthogonal Layer axes the root selects from the matrix below. A definition names no transport, no port, no engine.
- Law: handler exhaustiveness is compiler-checked — `HttpApiBuilder.group` demands `.handle` for every declared endpoint and `RpcGroup.toLayer` demands the full handler record; a missing or mistyped handler is a compile error, never a 404 discovered at runtime.
- Law: group-scoped concerns ride the declaration — `.middleware(Tag)` on the group, `.addError` for group-wide faults, `.prefix` for mount points — so a cross-cutting obligation is recoverable from the contract value, never from handler bodies.
- Reject: a hand-rolled router table where the declarative family fits; a route registered beside the contract; transport or codec baked into a handler; a second contract authored for a client variant.

Axes pair freely — any protocol row under any serialization row, selected only at the root; protocol rows live on `RpcServer`, serialization rows on `RpcSerialization`, and the client mirror rows are `RpcClient.layerProtocolHttp`/`layerProtocolSocket`/`layerProtocolWorker`.

| [INDEX] | [PROTOCOL_ROW]                     | [SERIALIZATION_ROW] |
| :-----: | :--------------------------------- | :------------------ |
|  [01]   | `layerProtocolHttp({ path })`      | `layerJson`         |
|  [02]   | `layerProtocolWebsocket({ path })` | `layerNdjson`       |
|  [03]   | `layerProtocolWorkerRunner`        | `layerMsgPack`      |
|  [04]   | `layerProtocolStdio`               | `layerJsonRpc()`    |
|  [05]   | `layerProtocolSocketServer`        | `layerNdJsonRpc()`  |

[DERIVED_SURFACES]:

- Law: one declaration derives every consumer surface — `HttpApiBuilder.api` plus `HttpApiBuilder.serve` derive the server, `HttpApiClient.make` derives the fully typed client, `OpenApi.fromApi` derives the spec, `HttpApiBuilder.toWebHandler` derives the fetch-shaped handler for hostless runtimes; server, client, and spec cannot drift because they are projections of one value. `RpcClient.make` against the same group is the identical law on the RPC axis, `RpcServer.toWebHandler` its hostless projection, and `RpcTest.makeClient` short-circuits transport in specs — the production and test callers share the contract.
- Law: endpoint faults are declared — `Schema.TaggedError` classes on `.addError` with their status — so the caller reconstructs the exact tagged family the handler failed with, and one error vocabulary spans the wire; the family's design is `rails-and-effects.md`'s.
- Reject: a hand-written fetch client beside a contract; an API document authored by hand; a client-side error type parallel to the declared fault; a spec regenerated into source and committed as a second truth.

```typescript conceptual
import {
    HttpApi,
    HttpApiBuilder,
    HttpApiClient,
    HttpApiEndpoint,
    type HttpApiError,
    HttpApiGroup,
    type HttpClient,
    type HttpClientError,
    OpenApi,
} from "@effect/platform";
import { Effect, Layer, type ParseResult, Schema } from "effect";

// --- [MODELS] ---------------------------------------------------------------------------

class Row extends Schema.Class<Row>("Row")({
    key: Schema.Number,
    label: Schema.String,
}) {}

class Missing extends Schema.TaggedError<Missing>()("Missing", { key: Schema.Number }) {}

// --- [CONTRACT] -------------------------------------------------------------------------

const _rows = HttpApiGroup.make("rows")
    .add(
        HttpApiEndpoint.get("one", "/rows/:key")
            .setPath(Schema.Struct({ key: Schema.NumberFromString }))
            .addSuccess(Row)
            .addError(Missing, { status: 404 }),
    )
    .add(
        HttpApiEndpoint.post("grow", "/rows")
            .setPayload(Schema.Struct({ label: Schema.String }))
            .addSuccess(Row),
    );

const Contract = HttpApi.make("contract").add(_rows);

// --- [COMPOSITION] ----------------------------------------------------------------------

const _RowsLive = HttpApiBuilder.group(Contract, "rows", (handlers) =>
    handlers
        .handle("one", ({ path }) =>
            path.key > 0 ? Effect.succeed(new Row({ key: path.key, label: "<value-a>" })) : Effect.fail(new Missing({ key: path.key })),
        )
        .handle("grow", ({ payload }) => Effect.succeed(new Row({ key: 1, label: payload.label }))),
);

const ContractLive: Layer.Layer<HttpApi.Api> = HttpApiBuilder.api(Contract).pipe(Layer.provide(_RowsLive)); // the root proof: every handler edge eliminated at the declaration

// --- [OPERATIONS] -----------------------------------------------------------------------

const specification: OpenApi.OpenAPISpec = OpenApi.fromApi(Contract);

const probed: (
    key: number,
) => Effect.Effect<Row, Missing | HttpApiError.HttpApiDecodeError | HttpClientError.HttpClientError | ParseResult.ParseError, HttpClient.HttpClient> =
    Effect.fn("probed")(function* (key: number) {
        // the stated union is the whole client fault surface: declared fault, decode skew, transport
        const client = yield* HttpApiClient.make(Contract, { baseUrl: "<origin>" });
        return yield* client.rows.one({ path: { key } });
    });

// --- [EXPORTS] --------------------------------------------------------------------------

export { Contract, ContractLive, Missing, probed, Row, specification };
```

## [04]-[CODEC_ENGINE]

[ENGINE_FOLD]:

- Use: every foreign codec — binary formats, text formats, compression, crypto envelopes — whose decode/encode pair the platform does not own.
- Law: the engine is a pure function pair behind one `Schema.transformOrFail` from the byte schema to `Schema.Unknown`, composed onto the owned shape with `Schema.compose(shape, { strict: false })`; the engine's throw is caught inside the transform — `Either.try` folding the defect to `new ParseResult.Type(ast, actual, message)` — so codec faults join the same `ParseError` rail every admission rides. A codec fault family beside the decode rail is the rejected second vocabulary: the caller already discriminates admission failure, and the engine's failure is admission failure.
- Law: the engine configures once at the owner per policy — instance options, untrusted-input ceilings, tag and extension registries are module-init facts — and the configured decode is the exported surface; the interior receives the owned shape and never a raw engine value, so replacing the engine is an edit to one module.
- Law: the transform is total both directions — the encode arm folds the engine's serializer through the same `Either.try` — so the owner round-trips and the wire twin derives; a decode-only crossing that hand-writes its egress is half an owner.
- Reject: engine output touched by domain code before the Schema owner; a throwing engine call outside the transform; per-call engine construction; a decode ceiling checked after the decode it was meant to bound.

[QUIRK_CAPTURE]:

- Law: provider type-surface drift — runtime-real members the shipped declarations omit, mislabeled declarations, phantom re-exports — reconciles at one `declare module "<package>"` augmentation co-located with the engine owner; the augmentation declares only verified runtime truth, the mislabeled member is never called, and downstream composes the corrected surface without re-discovering the mismatch.
- Law: behavioral quirks — a default option that engages a proprietary dialect, a shared global registry, a native accelerator probe — are internalized as the owner's configuration facts; the owner's construction encodes the correct posture, so no consumer can reach the quirk path.
- Reject: an `as` bridge at call sites where the augmentation owns the truth; the augmentation in a global ambient dump far from the engine; a wrapper whose only job is smuggling a corrected type.

```typescript conceptual
import { type Effect, Either, ParseResult, Schema } from "effect";

// --- [TYPES] ----------------------------------------------------------------------------

type Engine = {
    readonly decode: (octets: Uint8Array) => unknown;
    readonly encode: (value: unknown) => Uint8Array;
};

// --- [MODELS] ---------------------------------------------------------------------------

class Snapshot extends Schema.Class<Snapshot>("Snapshot")({
    key: Schema.String,
    extent: Schema.Number,
    held: Schema.Uint8ArrayFromSelf,
}) {}

// --- [OPERATIONS] -----------------------------------------------------------------------

const engineSchema = <A, I, R>(engine: Engine, shape: Schema.Schema<A, I, R>): Schema.Schema<A, Uint8Array, R> =>
    Schema.transformOrFail(Schema.Uint8ArrayFromSelf, Schema.Unknown, {
        strict: true,
        decode: (octets, _options, ast) =>
            Either.try({
                try: () => engine.decode(octets),
                catch: (defect) => new ParseResult.Type(ast, octets, String(defect)),
            }),
        encode: (value, _options, ast) =>
            Either.try({
                try: () => engine.encode(value),
                catch: (defect) => new ParseResult.Type(ast, value, String(defect)),
            }),
    }).pipe(Schema.compose(shape, { strict: false }));

const admitted = (engine: Engine): ((raw: unknown) => Effect.Effect<Snapshot, ParseResult.ParseError>) =>
    Schema.decodeUnknown(engineSchema(engine, Snapshot)); // the configured decode is the exported surface; its stated type is the whole seam contract

// --- [EXPORTS] --------------------------------------------------------------------------

export { admitted, engineSchema, Snapshot };
export type { Engine };
```

## [05]-[RUNTIME_SELECTION]

[CAPABILITY_TAG]:

- Use: filesystem, HTTP egress, subprocess, tty, socket, worker spawn, key-value storage, path algebra.
- Law: capability is the abstract Tag — `FileSystem.FileSystem`, `HttpClient.HttpClient`, `Command`/`CommandExecutor`, `Terminal.Terminal`, `Socket.Socket`, `Worker.WorkerManager`, `KeyValueStore.KeyValueStore`, `Path.Path` — yielded on the rail; the runtime binding — `NodeContext.layer` plus `NodeHttpClient.layerUndici` and `NodeHttpServer.layer`, `BunContext.layer` plus `BunHttpServer.layer`, `FetchHttpClient.layer`, `BrowserHttpClient.layerXMLHttpRequest` — is provided once at the root, so a runtime change is a Layer row, never a fork; the wiring algebra is `services-and-layers.md`'s.
- Law: a direct `node:*`, `fetch`, or socket-library import in domain flow bypasses tracing, the typed error rail, pooling policy, and portability in one stroke; those specifiers survive only inside the binding packages and the named FFI seam.
- Law: a foreign callback surface admits once at the seam owner — `Effectify.effectify(fn)` lifts the callback arity into an `Effect`-returning signature, and `effectify(fn, onError, onSyncError)` types the failure channel at the same declaration — so the callback API has exactly one effect spelling; an `Effect.async` wrap repeated per call site is the same defect as a scattered `process.env` read.
- Law: a wasm module is capability, not code — instantiation is a scoped acquisition behind an abstract Tag, exports call through the marked kernel, and no linear-memory `TypedArray` view escapes it, because the module's memory is shared mutable state only the kernel may touch; the mark's legality is `language.md`'s.
- Law: egress policy attaches to the one shared client as composed transformers — `HttpClient.retryTransient`, `filterStatusOk`, `mapRequest`, `withTracerPropagation` — so retry, admission, auth, and propagation are recoverable from the client's declaration, never re-stated per call.
- Boundary: config ingress is the same shape — the provider chain (`PlatformConfigProvider.layerDotEnv`, `layerFileTree`) satisfies `Config` reads at the root; a `process.env` read in domain flow is the same defect as a `node:fs` import.

[BOOT_EDGE]:

- Law: one `runMain` per process is the entire imperative surface — `NodeRuntime.runMain`, `BunRuntime.runMain`, and `BrowserRuntime.runMain` inhabit the single `RunMain` shape that forks the root fiber, installs interrupt handling, sets the exit code from the `Exit`, and drains finalizers on signal; its parameter pins `R` to `never`, so the boot line is where an unwired Tag becomes a compile error rather than a runtime absence.
- Law: `Effect.runPromise` heading a long-lived process is the rejected boot — no signal draining, finalizers lost on interrupt; a second `runMain` in one process is the named defect.
- Law: the boot module is the only module that names a runtime, and it exports nothing — the empty exports surface is the structural proof it is terminal; a worker entry is a boot module under the same law, `WorkerRunner.launch` run beneath the runner binding.
- Law: the view lane boots the same way once — `Atom.runtime(root)` stands the Layer graph behind the atom registry with one shared `memoMap` across runtime atoms, components project through `useAtomValue`/`useAtomSet`, and `withReactivity(keys)` re-runs an atom on the invalidation coordinates `[07]`'s bus stamps — an in-view `run*` call or a per-render Layer build is a second boot edge in disguise; which runtime owner a process holds is `services-and-layers.md`'s.
- Law: host cancellation crosses as `AbortSignal` exactly twice — inbound, the run seam's option (`runPromise(effect, { signal })` on the `Runtime` and `ManagedRuntime` handles) converts an abort into fiber interruption; outbound, `Effect.tryPromise` and `Effect.promise` hand their evaluator a signal the fiber's own interruption fires — so an `AbortController` threaded through domain flow restates the interruption rail, whose semantics are `concurrency.md`'s.
- Law: importing a binding pins a module to that runtime lane; domain modules import zero bindings and therefore sit in every lane — the per-runtime subpath gate enforces the fence, and this page owns its consequence: a browser bundle cannot resolve a server binding because the module graph never reaches one.
- Exemption: the top-level `runMain` call is the named platform-forced statement seam.
- Reject: a runtime binding imported for one capability where the aggregate context Layer already carries it; runtime detection branching inside domain flow; a library module that calls any `run*`.

[CONFIG_SURFACE]:

- Law: configuration is one `Config.unwrap` owner — a nested record of reads collapsed to a single validated struct at construction, each scalar admitted where it enters: `Config.branded` lifts a `Brand.Constructor` an owner already carries, a Schema-refined brand admits through `Schema.Config` with the owning field schema, `Config.url`/`Config.port`/`Config.duration` parse structure, `Config.nested` scopes the namespace, `Config.redacted` seals secrets — so the environment contract is one declaration resolved once at the boot edge and no validated value is re-checked past it.
- Law: a config value with real shape admits through `Schema.Config(name, shape)` — the full Schema algebra over a string `Encoded`, brands, unions, and transforms included, its `ParseError` folded into the same `ConfigError` rail — so structure never re-parses past the seam.
- Law: `Config.withDescription` rides every row — a missing or malformed variable reports its meaning in the `ConfigError`, never a bare key name.
- Reject: scattered per-site `Config.string` reads; a raw scalar carried where the brand exists; a default buried at a read site where `Config.withDefault` states it at the owner; a regex check after `Config.string` where `Schema.Config` owns the shape.

```typescript conceptual
import { Command, FileSystem, HttpClient, Path, PlatformConfigProvider } from "@effect/platform";
import { NodeContext, NodeHttpClient, NodeRuntime } from "@effect/platform-node";
import { Config, Effect, Layer, Schema } from "effect";

// --- [CONSTANTS] ------------------------------------------------------------------------

const Setting = Config.unwrap({
    origin: Config.url("ORIGIN").pipe(Config.withDescription("<meaning-a>")),
    root: Config.string("ROOT").pipe(Config.withDefault("<root>"), Config.withDescription("<meaning-b>")),
    lane: Config.nested(
        Config.unwrap({
            port: Config.port("PORT").pipe(Config.withDescription("<meaning-c>")),
            token: Config.redacted("TOKEN").pipe(Config.withDescription("<meaning-d>")),
        }),
        "LANE",
    ),
    extent: Schema.Config("EXTENT", Schema.NumberFromString.pipe(Schema.int(), Schema.between(1, 64), Schema.brand("Extent"))).pipe(
        Config.withDescription("<meaning-e>"), // the owning field schema admits here: the resolved scalar arrives branded, not re-proven downstream
    ),
});

// --- [OPERATIONS] -----------------------------------------------------------------------

const staged = Effect.fn("staged")(function* () {
    const setting = yield* Setting; // the one resolution; no config read survives past this line
    const client = yield* HttpClient.HttpClient;
    const fs = yield* FileSystem.FileSystem;
    const path = yield* Path.Path;
    const body = yield* client.get(setting.origin).pipe(
        Effect.flatMap((response) => response.text),
        Effect.scoped,
    );
    const target = path.join(setting.root, "<file>");
    yield* fs.writeFileString(target, body);
    const code = yield* Command.make("<command>", target).pipe(Command.exitCode);
    return { target, code, extent: setting.extent } as const;
});

// --- [COMPOSITION] ----------------------------------------------------------------------

const Root = Layer.mergeAll(
    NodeContext.layer,
    NodeHttpClient.layerUndici,
    PlatformConfigProvider.layerDotEnv("<file>").pipe(Layer.provide(NodeContext.layer)),
);

// --- [ENTRY] ----------------------------------------------------------------------------

NodeRuntime.runMain(staged().pipe(Effect.provide(Root))); // R pinned to never: an unwired Tag fails here at compile time

// --- [EXPORTS] --------------------------------------------------------------------------

export {};
```

## [06]-[MARSHAL]

[WORKER_PROTOCOL]:

- Use: off-main-thread compute, worker pools, process-boundary request/response.
- Law: the message vocabulary is a closed family of `Schema.TaggedRequest` classes — payload, success, and failure Schemas in one declaration — collected by `Schema.Union` into one protocol; the pool executes decoded requests (`Worker.makePoolSerializedLayer(Tag, options)` — `executeEffect` one-shot, `execute` streaming, `broadcast` fan-out; the request's declared nature discriminates the modality, never a parallel pool), and the worker implements the same protocol through `WorkerRunner.layerSerialized(protocol, handlers)` — an `Effect` handler answers once, a `Stream` handler streams — with the handler record compiler-checked against the union.
- Law: pool sizing is one policy value — fixed `{ size, concurrency, targetUtilization }` or elastic `{ minSize, maxSize, timeToLive }` — chosen at the pool layer; a second pool per load profile restates what the options row already carries.
- Law: failure crosses as the request's failure Schema and reconstructs as the same tagged class on the caller, so one fault vocabulary spans the thread boundary; a stringified error message crossing a worker seam destroys the discriminant every downstream recovery dispatches on.
- Law: zero-copy crossings are declared at the schema — `Transferable.Uint8Array`, `Transferable.MessagePort`, `Transferable.ImageData`, or `Transferable.schema(shape, project)` for a composite — and the `Transferable.Collector` service gathers the projected list during encode (`makeCollector` constructs it, `addAll` accumulates, `read` yields the transfer list), so the marshal plan is recoverable from the message declaration and the transfer list from the encode itself, never from an argument list at a call site.
- Boundary: the pool's spawner and the runner's binding are runtime rows at the boot edge; the protocol module names neither; the RPC protocol row `RpcServer.layerProtocolWorkerRunner` serves an `RpcGroup` over this same runner law.
- Reject: an untyped `postMessage` payload; a hand-rolled `onmessage` switch; a string-keyed message map with casts; per-message transferable lists at call sites; a second pool where a request tag discriminates.

[FRAME_CHANNEL]:

- Use: socket duplex, WebSocket sessions, any byte-stream peer.
- Law: the schema seam over a structured channel is one owner — `ChannelSchema.duplex`/`duplexUnknown({ inputSchema, outputSchema })` types messages in both directions with backpressure, `ChannelSchema.decodeUnknown`/`encode` are its one-directional rows — and a byte wire first rides a frame row that owns chunk reassembly and mints its own fault: `MsgPack.duplex` (`MsgPackError`) for length-delimited binary, `Ndjson.duplex`/`duplexString` (`NdjsonError`) for newline-delimited frames. The shipped fusions `MsgPack.duplexSchema` and `Ndjson.duplexSchema` are `ChannelSchema.duplexUnknown` composed over the frame row, so the frame choice is a row swap under an unchanged schema seam.
- Law: the socket is a byte `Channel` — `Socket.toChannelWith<E>()` — and its construction is capability, not code: `Socket.makeWebSocket(url)` against the `Socket.WebSocketConstructor` Tag the runtime row satisfies, so one framed transport definition serves every runtime lane; the pipeline geometry above the frame is `streams.md`'s.
- Reject: raw socket event listeners; a hand-written length-prefix parser; `JSON.stringify` written to a socket where a frame row owns the framing; a per-format duplex owner where the frame table and the one schema seam compose.

```typescript conceptual
import { ChannelSchema, Ndjson, Socket, Transferable, Worker, type WorkerError, WorkerRunner } from "@effect/platform";
import { type Channel, type Chunk, Context, Effect, type Layer, type ParseResult, Schema, Stream } from "effect";

// --- [MODELS] ---------------------------------------------------------------------------

class MarshalFault extends Schema.TaggedError<MarshalFault>()("MarshalFault", {
    reason: Schema.Literal("<reason-a>", "<reason-b>"),
}) {}

class Grade extends Schema.TaggedRequest<Grade>()("Grade", {
    payload: { octets: Transferable.Uint8Array },
    success: Schema.Struct({ key: Schema.String, extent: Schema.Number }),
    failure: MarshalFault,
}) {
    static readonly executed = (
        octets: Uint8Array,
    ): Effect.Effect<{ readonly key: string; readonly extent: number }, MarshalFault | ParseResult.ParseError | WorkerError.WorkerError, Bench> =>
        Effect.flatMap(Bench, (pool) => pool.executeEffect(new Grade({ octets }))); // the union states the marshal truth: domain fault, wire decode, worker transport
}

class Sweep extends Schema.TaggedRequest<Sweep>()("Sweep", {
    payload: { keys: Schema.Array(Schema.String) },
    success: Schema.String,
    failure: MarshalFault,
}) {
    static readonly streamed = (
        keys: ReadonlyArray<string>,
    ): Stream.Stream<string, MarshalFault | ParseResult.ParseError | WorkerError.WorkerError, Bench> =>
        Stream.unwrap(Effect.map(Bench, (pool) => pool.execute(new Sweep({ keys }))));
}

const _Protocol = Schema.Union(Grade, Sweep);

// --- [SERVICES] -------------------------------------------------------------------------

class Bench extends Context.Tag("Bench")<Bench, Worker.SerializedWorkerPool<Grade | Sweep>>() {}

// --- [COMPOSITION] ----------------------------------------------------------------------

const BenchLive: Layer.Layer<Bench, WorkerError.WorkerError, Worker.Spawner | Worker.WorkerManager> = Worker.makePoolSerializedLayer(Bench, {
    size: 4,
    concurrency: 2,
}); // the R tail names the runtime rows only the boot edge satisfies

const RunnerLive: Layer.Layer<never, WorkerError.WorkerError, WorkerRunner.PlatformRunner> = WorkerRunner.layerSerialized(_Protocol, {
    Grade: ({ octets }) => Effect.succeed({ key: "<value-a>", extent: octets.byteLength }),
    Sweep: ({ keys }) => Stream.fromIterable(keys),
});

// --- [OPERATIONS] -----------------------------------------------------------------------

const framed = (
    socket: Socket.Socket,
): Channel.Channel<
    Chunk.Chunk<Grade | Sweep>,
    Chunk.Chunk<Grade | Sweep>,
    Ndjson.NdjsonError | ParseResult.ParseError | Socket.SocketError,
    ParseResult.ParseError,
    void,
    unknown
> =>
    Socket.toChannelWith<Ndjson.NdjsonError | ParseResult.ParseError>()(socket).pipe(
        Ndjson.duplex(),
        ChannelSchema.duplexUnknown({ inputSchema: _Protocol, outputSchema: _Protocol }), // the fused Ndjson.duplexSchema collapses this pair; the frame row swaps to MsgPack.duplex with the schema seam untouched
    );

// --- [EXPORTS] --------------------------------------------------------------------------

export { Bench, BenchLive, framed, Grade, MarshalFault, RunnerLive, Sweep };
```

## [07]-[PERSISTENCE_SEAM]

[SQL_STORE]:

- Use: every relational store — statements, transactions, migrations, batched lookups.
- Law: the store is the `SqlClient` Tag on `R`, and statements are `sql` tagged-template fragments composed as values — parameters bind at the fragment, and the helper rows (`sql.insert`, `sql.update`, `sql.in`, `sql.and`, `sql.or`) compose fragments from data — so string-built SQL has no spelling; the transaction is the bracket-shaped `sql.withTransaction`, a rail transformer that commits on success and rolls back on failure or interruption.
- Law: decode rides the admission law — `SqlSchema.findAll`/`findOne`/`single`/`void` fuse Request and Result Schemas with the statement so every row enters as a decoded value on the one `ParseError` rail, and `SqlResolver.ordered`/`grouped`/`findById` batch keyed lookups behind the same fused contract, each resolver's `.execute` the one call surface its callers share; accessors and resolvers bind once at the owning service construction — a fused accessor or resolver rebuilt inside a call body re-mints resolver identity per call and defeats the batch window.
- Law: migrations run at the boot edge — `Migrator.fromGlob`/`Migrator.fromRecord` rows executed by the boot module's Layer, never by a handler; the dialect binding and its migrator Layer are runtime rows at the root under `[05]`'s law.
- Reject: a driver import in domain flow; a query string assembled by hand; a second decode after the fused accessor; a transaction opened per statement where one bracket owns the unit of work.

[DURABLE_AND_LIVE]:

- Use: flat durable state, schema-keyed result bands, fleet-quota windows, reads that must follow writes.
- Law: flat durable state rides `KeyValueStore.layerSchema(shape, tagIdentifier)` — the returned `{ tag, layer }` publishes a `SchemaStore` whose `get` yields `Option` of the decoded owner and whose `set` encodes through the same Schema — decode skew rides the admission `ParseError`, the store's own I/O fault rides `PlatformError` beside it — chosen where a relational store is unearned, satisfied at the root like every capability.
- Law: store-backed capability rows provision here and are consumed elsewhere — `Persistence.ResultPersistence` (`Persistence.layerResultKeyValueStore`, `layerResultMemory`) is the schema-keyed result band behind `PersistedCache` and `RequestResolver.persisted`, and `RateLimiterStore` (`RateLimiter/Redis.layerStore` and `layerStoreConfig`, `RateLimiter.layerStoreMemory`) is the fleet-quota window's band — both `@effect/experimental` under the manifest pin, with the consuming owners `concurrency.md`'s and `streams.md`'s.
- Law: a read that must follow writes rides the `Reactivity` bus (`@effect/experimental`, provisioned by `Reactivity.layer`) — `mutation(keys, write)` stamps the write's invalidation coordinates, `query(keys, read)` yields a `Mailbox` re-delivering on every overlapping mutation, `stream` is the same feed as a `Stream`, and `invalidate(keys)` is the foreign-write edge; keys are the currency — the array form names whole bands, the record form scopes `{ band: ids }`, and a record mutation wakes member readers and whole-band readers both — the same coordinates `[05]`'s view lane refreshes on, so a cadence poll of unchanged rows restates delivery the keys already own.
- Reject: a stored string re-shaped by hand where the `SchemaStore` fuses admission; an in-process quota beside the store-backed window; a hand pub/sub of table-changed strings beside the bus.

```typescript conceptual
import { Reactivity } from "@effect/experimental";
import { KeyValueStore } from "@effect/platform";
import { Migrator, SqlClient, SqlResolver, SqlSchema } from "@effect/sql";
import { Array, Effect, Option, Schema } from "effect";

// --- [MODELS] ---------------------------------------------------------------------------

class Row extends Schema.Class<Row>("Row")({
    key: Schema.Number.pipe(Schema.int(), Schema.brand("Key")),
    label: Schema.String,
    extent: Schema.Number,
}) {}

// --- [SERVICES] -------------------------------------------------------------------------

const Checkpoint = KeyValueStore.layerSchema(Schema.Struct({ mark: Schema.String }), "Checkpoint");

class Ledger extends Effect.Service<Ledger>()("Ledger", {
    effect: Effect.gen(function* () {
        const sql = yield* SqlClient.SqlClient;
        const bus = yield* Reactivity.Reactivity;
        const mark = yield* Checkpoint.tag;
        const inserted = SqlSchema.void({
            Request: Schema.Array(Schema.Struct({ label: Schema.String, extent: Schema.Number })),
            execute: (rows) => sql`INSERT INTO rows ${sql.insert(rows)}`,
        });
        const found = SqlSchema.findAll({
            Request: Schema.String,
            Result: Row,
            execute: (label) => sql`SELECT * FROM rows WHERE label = ${label}`,
        });
        const byKey = yield* SqlResolver.findById("RowByKey", {
            Id: Schema.Number,
            Result: Row,
            ResultId: (row) => row.key,
            execute: (keys) => sql`SELECT * FROM rows WHERE ${sql.in("key", keys)}`, // one statement answers the whole batch window
        });
        return {
            // fused accessors, the resolver, the store, and the bus bind once; every call shares them
            recorded: (drafts: ReadonlyArray<{ readonly label: string; readonly extent: number }>, needle: string) =>
                bus.mutation(
                    { rows: Array.map(drafts, (draft) => draft.label) }, // the write stamps its coordinates: member readers and whole-band readers both re-run
                    sql.withTransaction(inserted(drafts)).pipe(
                        Effect.andThen(found(needle)),
                        Effect.tap(() => mark.set("<key>", { mark: needle })),
                    ),
                ),
            held: (key: number) => Effect.map(byKey.execute(key), Option.isSome),
            watched: (needle: string) => bus.stream({ rows: [needle] }, found(needle)), // the live query: re-runs on every overlapping mutation, never a cadence poll
        };
    }),
    dependencies: [Checkpoint.layer, Reactivity.layer],
}) {}

// --- [COMPOSITION] ----------------------------------------------------------------------

const migrations = Migrator.fromRecord({
    "0001_<name>": Effect.asVoid(
        Effect.flatMap(SqlClient.SqlClient, (sql) => sql`CREATE TABLE rows (key INTEGER PRIMARY KEY, label TEXT, extent REAL)`),
    ),
});

// --- [EXPORTS] --------------------------------------------------------------------------

export { Checkpoint, Ledger, migrations, Row };
```
