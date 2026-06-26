# [H1][MUTATION_COVERAGE]
>**Dictum:** *Scores are gates only after ownership and discovery are true.*

<br>

## [01]-[COVERAGE]

| [INDEX] | [CLASS]               | [ACTION]                                                      |
| :-----: | --------------------- | ------------------------------------------------------------- |
|  [01]   | Missing static law    | Add or strengthen managed xUnit/CsCheck spec.                 |
|  [02]   | Runtime-owned path    | Add or strengthen the runtime scenario; do not fake coverage. |
|  [03]   | Generated code        | Exclude centrally by file/attribute.                          |
|  [04]   | Defensive unreachable | Document only after source review.                            |

## [02]-[MUTATION]

- Use Stryker only through the repo-declared explicit mutation command; zero discovery fails the rail.
- Target the repo-declared threshold for eligible managed code, never for host-runtime rails.
- Classify survivors as missing oracle, equivalent mutant, runtime-owned path, or product bug.
- Improve existing laws before adding branch-by-branch tests.
- Use `--mutation changed` for bounded diagnostics before enforcing full mutation; full thresholds remain `95/90/85`.
- The quality wrapper applies a whole-process timeout. Stryker owns mutant scheduling; selected mutants plus timed-out mutants mean the rail ran.
- Mutation uses an advisory lock. Live contention fails fast; unlocked stale lock files are reused automatically.

---
## [03]-[THEORY_EXPANSION_AS_STRYKER_ENABLER]
>**Dictum:** *PBT hosts are one mutation target; Theory rows are N.*

<br>

Stryker mutates each test method body and asks "does any test fail?". A `Spec.ForAll(Gen.OneOfConst([A,B,C]), ...)` body is ONE method, ONE mutation target — Stryker kills the mutation if any case catches it, then moves on. Survivors that affect only case B are invisible.

A `[Theory][InlineData(A)][InlineData(B)][InlineData(C)]` (or `[MemberData(nameof(CasesOf))]` populated from `SmartEnum.Items`) becomes THREE separately-tracked entry points. Stryker can now report "survivor in case B" specifically, enabling targeted oracle improvements.

Convert from PBT to Theory when:
- Stryker survivor analysis points at a SmartEnum / Union case the PBT host under-samples.
- The CI mutation budget cannot afford to re-run the full PBT body per mutant (Theory rows are independent and parallelize better).
- Per-case failure-ID matters for CI triage (each row gets its own test ID).

Do NOT convert when:
- Cases share oracle logic and the PBT body is the more honest representation.
- The oracle requires random input variation per case (PBT generators over case-specific inputs).
- Per-case Theory rows would be pure copy-paste of body code.

---
## [04]-[SURVIVOR_TAXONOMY]

| [INDEX] | [CLASS]            | [ACTION]                                                                               |
| :-----: | ------------------ | -------------------------------------------------------------------------------------- |
|  [01]   | Missing oracle     | Add Grade A/B/B+ oracle (closed-form, smaller model, metamorphic, conditioning-aware). |
|  [02]   | Equivalent mutant  | Document inline; do not weaken oracle.                                                 |
|  [03]   | Runtime-owned path | Add or strengthen the runtime scenario; static spec cannot kill it.                    |
|  [04]   | Product bug        | Fix production code; mutation revealed a real defect.                                  |

Do not chase a survivor by adding an assertion on the mutant's behavior — that is implementation mirror coverage (Grade F per [oracles-laws.md `[4]`](oracles-laws.md)).
