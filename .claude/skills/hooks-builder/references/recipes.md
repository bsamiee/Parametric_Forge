# [RECIPES]

An advanced move is a hook technique whose correctness hinges on one field, one ordering, or one closed-shape invariant a naive body gets wrong. Each recipe names the need it serves, the hinge it turns on, and the naive form it beats; the mechanism it composes is the owning reference's law, and its runnable form is a template or an example. A move earns its place only where the naive spelling silently fails — a substring matcher that reads obfuscation as safe, a rewrite that drops the tool's other arguments, a continuation that livelocks — never as ceremony over a plain exit-2 gate.

## [01]-[ROUTING]

The chooser routes a need to its move; the hinge is the one field or invariant the move turns on, and the beaten form is the naive spelling that reads correct and fails silently.

| [INDEX] | [NEED]                        | [MOVE]                | [HINGE]                               | [BEATS]                               |
| :-----: | :---------------------------- | :-------------------- | :------------------------------------ | :------------------------------------ |
|  [01]   | classify a hostile command    | command decomposition | leaf `argv` after de-obfuscation      | substring over a collapsed string     |
|  [02]   | fix a call, not refuse it     | value rewrite         | spread-and-override one key           | emitting the changed key alone        |
|  [03]   | compose many handlers         | event dispatch        | priority band plus terminal short-cut | one settings entry per handler        |
|  [04]   | loop until an objective lands | completion loop       | two orthogonal block bounds           | inferring done from free text         |
|  [05]   | inject rules that multiply    | data-driven injection | rows decoded from disk                | one code edit per rule                |
|  [06]   | verify slowly off the loop    | hot-path offload      | `asyncRewake` exit-2 wake             | a synchronous suite on every turn     |
|  [07]   | stream events to a sink       | attention stream      | fail-open unconditional exit 0        | telemetry entangled with policy       |
|  [08]   | settle a repetitive approval  | standing permission   | `addRules` durable destination        | a broad matcher clearing every call   |
|  [09]   | remember across firings       | durable state         | `session_id`-keyed read-modify-write  | one shared filename across sessions   |
|  [10]   | trust a foreign hook          | paired audit          | every attack shipped with its twin    | a gate proven on the happy path alone |

## [02]-[COMMAND_DECOMPOSITION]

[LEAF_CLASSIFIER]:
- Use: a `PreToolUse` Bash gate where an attacker or a confused model wraps, quotes, chains, newline-splits, env-prefixes, substitutes, or nests the same call many ways.
- Law: the string decomposes into leaf `argv` lists before any classify — `$IFS` de-obfuscation, a quote-aware split treating an unquoted newline as `;`, command-substitution and backtick descent, leading `NAME=value` and wrapper stripping, and clustered-flag shell descent — so a per-`argv` classifier judges the real command, never the bytes.
- Law: an inline interpreter one-liner is opaque, so it denies fail-closed rather than admitting through a keyword denylist that lets `os.system` pass by omission; an unbalanced quote raises to the fail-closed seam.
- Law: a write-sandbox gate reads each leaf for its write surface — a redirection target (`>`, `>>`, `&>`, `>|`, `n>`) or a write-verb destination, verb-specific (`tee` every operand, `dd` its `of=`, `cp`/`mv`/`ln`/`install` the final operand) — and canonicalizes and sandbox-checks it exactly as an `Edit`/`Write` `file_path`; `apply_patch` names its targets in the `*** {Add|Update|Delete|Move to} File:` envelope inside `tool_input.command`, never a `file_path`, so a gate parses the envelope and checks each. A classifier reading only argv[0] or an absent `file_path` misses the write.
- Reject: `"rm -rf" in command`; a comment-blind matcher a trailing `#` smuggles past; verb-pattern matching where the danger is the resolved path, so an `rm` tier and a sandbox check read the canonicalized target, never the raw string.

```python conceptual
def leaves(command: str, /, *, depth: int = 0) -> list[list[str]]:  # descend substitutions, then lex the outer command
    stripped, inner = strip_substitutions(command)  # `...` and $(...) bodies each execute, so each is descended first
    out = [leaf for body in inner if depth < DESCENT_CAP for leaf in leaves(body, depth=depth + 1)]
    lexer = shlex.shlex(IFS.sub(" ", stripped), posix=True, punctuation_chars=";&|<>()\n\r")
    lexer.whitespace, lexer.whitespace_split = " \t\f\v", True  # newline is punctuation, so it separates a chain
    argv: list[str] = []
    for token in lexer:  # a ValueError on an unbalanced quote propagates to the fail-closed seam
        if token in CHAIN_OPERATORS:
            out += resolve(argv, depth=depth)  # peel env-prefixes and wrappers, descend a shell -c, mark an interpreter opaque
            argv = []
        else:
            argv.append(token)
    return out + resolve(argv, depth=depth)
```

## [03]-[VALUE_REWRITE]

[SPREAD_AND_OVERRIDE]:
- Use: the right move fixes the call rather than refusing it — sandbox a stray path, redact an outbound secret, steer without an error frame.
- Law: outbound rewriting rides `PreToolUse` `updatedInput`; the field replaces the entire input object, so the body spreads the full original `tool_input` and overrides exactly one key. Inbound redaction rides `PostToolUse` `updatedToolOutput` with a shape-preserving replacement — a built-in validates the value against its output schema and keeps the original on a mismatch, so a `Bash` scrub re-emits `{stdout, stderr, interrupted, isImage}` masked, never a bare string.
- Boundary: telemetry and side effects already fired when the rewrite lands, so a rewrite corrects only what the model next reads, never what the tool already did.
- Reject: emitting the changed key alone, which drops `old_string`/`new_string` from an `Edit`; a bare `decision: "block"` for redaction, which leaves the raw output beside the reason in Claude's context; a shape-mismatched `updatedToolOutput` on a built-in, silently ignored.

```python conceptual
def sandbox(tool_input: ToolInput, sandbox_root: str, /) -> Rewrite:  # PreToolUse: full input, one key overridden
    name = PurePosixPath(tool_input.file_path).name
    changed = {**msgspec.structs.asdict(tool_input), "file_path": f"{sandbox_root}/{name}"}
    return Rewrite(event="PreToolUse", permission="allow", updated_input=changed)  # spread, never the lone key
```

## [04]-[EVENT_DISPATCH]

[PRIORITY_REGISTRY]:
- Use: several handlers compose on one event — a safety gate, a quality check, an advisory nudge — and per-event scripts fork the payload model and the logger.
- Law: one executable routes every event through a priority-banded registry; each handler declares a `matches` predicate, a `handle` verdict, an integer band, and a `terminal` flag, and the dispatcher sorts ascending and short-circuits at the first terminal deny. A new capability is one row, so a fleet registers few settings entries.
- Law: where per-invocation interpreter spawn dominates the hot path, the same registry relocates behind a Unix-socket daemon and thin forwarders, so admission cost is paid once at load and a fifty-handler project costs the same per call as a five-handler one.
- Reject: settings-file sprawl; the merge conflicts of near-identical entries; a single-handler router that cannot compose an ordered chain.

```python conceptual
def dispatch(raw: bytes, /) -> int:  # sort by band, run each match, stop at the first terminal deny
    try:
        event = msgspec.json.decode(raw, type=Envelope).hook_event_name
    except msgspec.DecodeError:
        return 0  # an observer no-ops on a malformed envelope; a gate row inside decides its own disposition
    for row in sorted((r for r in REGISTRY if r.event == event), key=lambda r: r.band):
        if row.run(raw) == BLOCK and row.terminal:
            return BLOCK
    return 0
```

## [05]-[COMPLETION_LOOP]

[TOKEN_CONTINUATION]:
- Use: a run must loop until an objective is provably met and the completion signal has to survive automation, resume, and a thinking-block emission.
- Law: completion keys on a session token the assistant emits, detected on `last_assistant_message` first and then a bounded scan restricted to assistant and thinking transcript entries, because the transcript is flushed asynchronously and lags the turn — the field is authoritative, the scan a lagging fallback.
- Law: two orthogonal bounds cap the loop — the harness `stop_hook_active` counts consecutive blocks and resets each turn, a durable session-keyed counter counts cumulative blocks across turns — and the body releases on `stop_hook_active` first, ahead of its own counter, so the bounds never fight; the counter read fails safe to the harness cap, never an exit 1 that breaks the loop. A `Stop` handler discriminates `SubagentStop` on `hook_event_name` and `agent_type`, never on `agent_id` presence or a transcript-length guess that misclassifies a subagent and livelocks it.
- Reject: inferring done from free text; a raw-line grep counting a token echoed inside a `tool_result`; a single bound that a resume silently resets.

```python conceptual
def done(token: str, last_message: str, transcript_path: str, /) -> bool:  # field first, entry-scan fallback
    if token in last_message:
        return True
    tail = read_tail(transcript_path, lines=SCAN_WINDOW)  # OSError -> False; the field already covered the live turn
    return any(entry.type in ASSISTANT_ENTRIES and token in entry.text for entry in tail)  # a tool_result echo is not done
```

## [06]-[DATA_DRIVEN_INJECTION]

[NUDGE_TABLE]:
- Use: injection rules multiply, each new one must land as data not code, and a false fire must cost only a few ignored tokens.
- Law: nudge rows decode from a JSON table at body top, each keyed by a `target` field with `match` and `exclude` regex arrays and a priority; a fired nudge injects `additionalContext` on the landing events (`UserPromptSubmit`, `SessionStart`) and phrases the miss as cheaply dismissible, since a miss costs a correction loop while a false fire costs a few tokens.
- Boundary: static conventions live in the memory hierarchy that loads without a script; a nudge injects only dynamic state — branch, target, results, fetched data — and reads as a factual statement, never an out-of-band imperative that trips injection defenses.
- Reject: a code edit per nudge; a single-pattern rule that cannot carve an exception; unconditional injection that bloats every turn.

```python conceptual
def fired(payload: NudgeInput, rows: tuple[Nudge, ...], /) -> list[str]:  # a new nudge edits the table, never this code
    field = {"prompt": payload.prompt, "tool_name": payload.tool_name, "command": payload.tool_input.command}
    return [row.text for row in sorted(rows, key=lambda r: r.priority)
            if (hay := field[row.target]) and any(re.search(p, hay) for p in row.match)
            and not any(re.search(x, hay) for x in row.exclude)]  # exclude carves the exception the single pattern cannot
```

## [07]-[HOT_PATH_OFFLOAD]

[DETACHED_HARVEST]:
- Use: the verification is authoritative but slow — a full suite, a CI probe, a deploy smoke test — and blocking the loop for it stalls every turn.
- Law: the check runs under `asyncRewake`, letting the triggering action proceed and waking the session later only on failure, where exit 2 surfaces stderr as a system reminder; the wake rides exit-2 stderr, never `additionalContext`, and never wires to `SessionStart`, where the wake leaks a prior run's stale output into a fresh conversation.
- Law: a scan that outlives the command-hook timeout forks — the firing spawns a detached process that writes its result to a session-keyed file and returns immediately, and a later firing wakes only on findings new since the last acknowledged set; this detached lane is also the dual-provider fallback, since Codex parses `async` and skips it, so a portable guardrail runs synchronously or splits its slow leg to the same detached process.
- Reject: a synchronous suite on every `PostToolUse`; a fire-and-forget check whose failure never surfaces.

## [08]-[ATTENTION_STREAM]

[TELEMETRY_CHAIN]:
- Use: a multi-agent fleet needs an event stream — a dashboard, a registry, an attention feed — that must never gate the loop.
- Law: a transmitter chains after the policy hook on the same event array, wired `async: true`, so the gate decides and the transmitter forwards without touching the verdict; the whole body sits under one broad exception swallow and an unconditional exit 0, because a narrow `(DecodeError, HTTPError)` catch lets `httpx.InvalidURL` and `StreamError` escape as a non-zero exit that blocks the loop.
- Law: a private sink takes the raw payload nested whole with the hot query keys hoisted flat beside it; a shared bus takes a CloudEvents envelope whose `source` derives from the provider brand so a dual-provider fleet self-identifies, and whose `time` is a true-UTC stamp, never a local `strftime` suffixed `Z`.
- Reject: policy and telemetry in one hook where a logging failure blocks a tool call; a two-type catch over an async transmitter; duplicating the metrics Codex already emits through its own exporter.

```python conceptual
def envelope(event: Event, raw: bytes, source: str, /) -> dict[str, object]:  # hot keys flat, raw payload in data
    return {"specversion": "1.0", "type": f"{BRAND}.hook.{event.hook_event_name}", "source": source,
            "id": f"{event.session_id}-{time_ns()}", "time": datetime.now(UTC).isoformat(),  # true UTC, never a tagged Z
            "sessionid": event.session_id, "toolname": event.tool_name, "data": msgspec.json.decode(raw)}
```

## [09]-[STANDING_PERMISSION]

[DURABLE_RULE]:
- Use: a repetitive safe operation — a read-only probe, a scoped `git` call — prompts every invocation and one clearance settles it.
- Law: a `PermissionRequest` hook approves the matched-safe call and persists a standing rule through an `addRules` `PermissionUpdate` entry with a `localSettings` destination, so the same call auto-approves without re-prompting; a `setMode` entry switches the session mode instead. The matcher stays narrow — a broad one auto-clears the file writes and shell commands the author never inspected — and approval keys on tool identity and argument shape, never a free-text command substring.
- Boundary: the durable rule is Claude-only — Codex `PermissionRequest` accepts only `decision.behavior` and fails closed on `updatedPermissions`, `updatedInput`, and `interrupt`, so the adapter strips them and a portable rewrite moves to `PreToolUse`.
- Reject: a permission-prompt storm on a known-safe call; a `.*` matcher; a managed deny rule a hook allow can never override.

## [10]-[DURABLE_STATE]

[SESSION_KEYED_CELL]:
- Use: a control-flow hook counts, dedupes, or carries a receipt across turns, or a bootstrap computes a value once that later turns reread.
- Law: state writes to a session-keyed file under a durable root, reads on the next firing, and clears on completion — a read-modify-write keyed on `session_id` so parallel sessions on one shared worktree never clobber each other, idempotent by `turn_id` against a double firing.
- Law: a one-time computation caches an `export` line into `$CLAUDE_ENV_FILE` so later turns read the value rather than recomputing, and state that must survive a plugin update rides `$CLAUDE_PLUGIN_DATA`; a value written to the env file passes `shlex.quote`, since the file is sourced into bash.
- Reject: a counter two parallel sessions clobber; a recomputed bootstrap on every turn; state lost to a plugin update.

```python conceptual
def bump(session_id: str, turn_id: str, /) -> State:  # read-modify-write; idempotent by turn_id against a double firing
    path = state_path(session_id)  # session-keyed: no shared filename across parallel sessions on one worktree
    state = msgspec.json.decode(path.read_bytes(), type=State) if path.exists() else State()
    if turn_id not in state.seen:
        state = replace_count(state, turn_id)
        path.write_bytes(msgspec.json.encode(state))
    return state
```

## [11]-[PAIRED_AUDIT]

[TWIN_CORPUS]:
- Use: a hook enforces security and both a miss (a dangerous payload that passes) and a false alarm (a benign payload that blocks) must be caught, or a foreign hook must be proven before it is trusted.
- Law: one harness runs any hook against a paired fixture corpus in two modes — a spawned subprocess for fidelity, an in-process call for speed — and reports each row as rule, case, expected, and actual, naming the offending policy on a miss; a benign fixture that blocks is the same defect class as a dangerous fixture that passes.
- Law: the corpus is disciplined by pairing, not volume — every dangerous fixture ships its benign twin, and the merge gate binds a new or changed policy row to its paired fixture, so the corpus grows with the rules and never behind them.
- Reject: a gate proven on the happy path alone; a rulebook that outgrows its corpus; trusting a copied hook whose behavior was never exercised.
