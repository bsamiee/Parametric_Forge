# Validation

Checklist for auditing `.py` modules against python-standards contracts. Items below complement Ruff, ty, mypy, validate-pyproject, ast-grep, and the repo-configured semantic analyzer.

---
## Type Integrity

- [ ] One canonical schema per entity -- py-analyzer blocks duplicate dataclass/Pydantic/msgspec field shapes
- [ ] Typed atoms (`NewType`/`Annotated`) -- py-analyzer blocks raw primitive public domain signatures
- [ ] Smart constructors return `Result[T, E]` -- never raise for invalid input
- [ ] `frozen=True` on all `BaseModel` subclasses and `@dataclass` (with `slots=True`)
- [ ] Discriminated unions via `Discriminator` + `Tag` + `TypeAdapter` or `@tagged_union`
- [ ] Immutable collections: `tuple`/`frozenset`/`Mapping`/`Block[T]` over mutable equivalents

---
## Effect Integrity

- [ ] `Result[T, E]` sync, `@effect.async_result` async, `Option[T]` absence -- correct container per channel
- [ ] Boundary adapters (`try/except`) at foreign boundaries only -- py-analyzer requires exemption metadata
- [ ] Zero `.unwrap()`/`.value_or()` in `domain/` or `ops/`
- [ ] `pipe()` + `result.map`/`result.bind`/`.or_else_with` as primary composition -- not method chaining for 3+ stages
- [ ] Result library consistency: `expression` exclusively per module (no `returns` imports)
- [ ] No mid-pipeline library mixing: `expression.pipe` only -- `returns.flow` absent from codebase

---
## Control Flow

- [ ] Zero domain `if`/`else`/`elif` -- py-analyzer blocks statement flow; use `match`/`case` with `assert_never`
- [ ] Zero `for`/`while` in domain transforms -- py-analyzer blocks loops; boundary loops require exemption metadata
- [ ] Guard clauses via `case x if predicate:` -- not bare `if` statements

---
## Decorator Integrity

- [ ] PEP 695 `**P` / parameter-spec preservation + `Concatenate` + `@wraps` on every decorator
- [ ] Canonical ordering: trace > authorize > validate > cache > govern > retry > operation
- [ ] One concern per decorator; factories accept frozen `BaseModel` config
- [ ] Class-based decorators implement descriptor protocol (`__set_name__` + `__get__`)

---
## Concurrency Integrity

- [ ] `anyio.create_task_group()` sole spawn -- no bare `asyncio.create_task`
- [ ] `checkpoint()` in tight async loops; `CapacityLimiter` for backpressure
- [ ] `ContextVar` for request-scoped state; `CancelScope` with explicit deadlines

---
## Surface Quality

- [ ] No helper spam, class proliferation, DTO soup, framework coupling, or import-time IO

---
## Algorithm Integrity

- [ ] `reduce` replaces accumulator loops; `accumulate` for scans; generators for lazy transforms
- [ ] `@trampoline` for unbounded recursion depth -- stack safety mandatory
- [ ] `Decimal` + `ROUND_HALF_EVEN` for financial arithmetic -- zero `float` in monetary paths

---
## Performance Integrity

- [ ] `__slots__` on non-Pydantic domain classes; module-level singletons for Encoder/Decoder/TypeAdapter
- [ ] `CapacityLimiter` sized to downstream; `checkpoint_if_cancelled()` in hot loops
- [ ] Profiling evidence before optimization -- no premature tuning

---
## Detection Heuristics

| [INDEX] | [CAUSE]                  | [GREP_ID] | [RG_PATTERN]                                          | [FIX]                                        |
| :-----: | ------------------------ | :-------: | ----------------------------------------------------- | -------------------------------------------- |
|  [01]   | Optional masking failure |   `G1`    | `"is None:" -g "*.py"`                                | `Option[T]` + `.to_result()`                 |
|  [02]   | Exception control flow   |   `G2`    | `"^\s*except " -g "*.py"`                             | Boundary adapter at edge, `Result` in domain |
|  [03]   | Imperative iteration     |   `G3`    | `"^\s*for " -g "*.py"`                                | Comprehension or `map`                       |
|  [04]   | Nominal dispatch         |   `G4`    | `"isinstance\\(" -g "*.py"`                           | Structural `match`/`case`                    |
|  [05]   | ABC-based interface      |   `G5`    | `"class.*ABC\|from abc import" -g "*.py"`             | `Protocol` structural typing                 |
|  [06]   | Signature erasure        |   `G6`    | `"Callable\\[\\.\\.\\.," -g "*.py"`                   | PEP 695 `**P` + `Callable[P, R]`             |
|  [07]   | Mutable domain model     |   `G7`    | `"class.*BaseModel" -g "*.py"`                        | Set `frozen=True`                            |
|  [08]   | Bare collection          |   `G8`    | `"-> list\\[\|-> dict\\[" -g "*.py"`                  | Frozen model or `TypeAdapter`                |
|  [09]   | Unstructured concurrency |   `G9`    | `"asyncio\\.create_task\|asyncio\\.gather" -g "*.py"` | `TaskGroup` + `start_soon`                   |
|  [10]   | Unstructured logging     |   `G10`   | `"logging\\.info\\(f\|logger\\.info\\(f" -g "*.py"`   | Key-value structured logs                    |
|  [11]   | Global mutable state     |   `G11`   | `"^[A-Z_]*: dict\|= \\[\\]\|= \\{\\}" -g "*.py"`      | `ContextVar[tuple]` snapshots                |
|  [12]   | Bare primitive I/O       |   `G12`   | `"def .*: str\\) -> str:" -g "*.py"`                  | Typed atoms + `Result[T, E]`                 |
|  [13]   | Import-time IO           |   `G13`   | `"^db = \|^conn = \|^client = " -g "*.py"`            | Defer to `boot()`                            |
|  [14]   | Imperative branching     |   `G14`   | `"^\s*if \|^\s*elif " -g "*.py"`                      | Exhaustive `match`/`case`                    |
|  [15]   | `hasattr`/`getattr`      |   `G15`   | `"hasattr\\(\|getattr\\(" -g "*.py"`                  | `case object(attr=value)`                    |
|  [16]   | Imperative accumulation  |   `G16`   | `"^\s*total\s*[+=]\|^\s*count\s*[+=]" -g "*.py"`      | `reduce` or `Seq.fold`                       |
|  [17]   | Premature optimization   |   `G17`   | `"# WORKITEM.*optim\|# PERF" -g "*.py"`               | Profile with `cProfile`/`tracemalloc`        |
|  [18]   | Stale `returns` imports  |   `G18`   | `"from returns" -g "*.py"`                            | Replace with `expression` equivalents        |

All patterns use `rg -n`. Combine G2+G14 for full control-flow audit; G4+G15 for dispatch audit.

---
## Skill Eval Prompts

- Explicit invocation: "Using coding-python, refine this Python module for Result rails, Protocol DI, and Ruff/ty compliance."
- Implicit invocation: "Review this .py file for helper drift, unsafe recovery, and type discipline."
- Noisy context: "Ignore deployment chatter and only audit the Python serialization boundary."
- Negative control: "Only tune a PostgreSQL query." Expected: do not load Python references unless Python code is present.
- Compliance checks: output should avoid command thrash, avoid new helper files, keep recovery outside `@effect.result` generators, and prefer `assert_never` on closed matches.

---
## Quick Reference

| [INDEX] | [CHECKLIST_AREA]      | [WHAT_IT_VALIDATES]                                           |
| :-----: | --------------------- | ------------------------------------------------------------- |
|  [01]   | TYPE_INTEGRITY        | Atoms, frozen models, unions, immutable collections           |
|  [02]   | EFFECT_INTEGRITY      | Result/Option/@effect.async_result, pipe, library consistency |
|  [03]   | CONTROL_FLOW          | match/case exhaustive, zero imperative branching              |
|  [04]   | DECORATOR_INTEGRITY   | PEP 695 `**P`, ordering, single-concern                       |
|  [05]   | CONCURRENCY_INTEGRITY | TaskGroup, CancelScope, CapacityLimiter, ContextVar           |
|  [06]   | SURFACE_QUALITY       | No helpers, framework coupling, import-time IO                |
|  [07]   | ALGORITHM_INTEGRITY   | Folds, scans, generators, @trampoline, Decimal                |
|  [08]   | PERFORMANCE_INTEGRITY | __slots__, singletons, backpressure, profiling-first          |
|  [09]   | DETECTION_HEURISTICS  | Grep-based violation surface scan (G1-G18)                    |
