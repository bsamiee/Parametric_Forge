# [ANATOMY]

A bundle is a directory whose every file sits at the lowest tier that owns it: the description is always resident, the root loads on selection, references load on route, scripts execute without loading, and assets are consumed without ever entering context. Tier placement is the whole cost model — a fact placed one tier too high taxes every session or every activation for nothing.

## [01]-[TIERS]

| [INDEX] | [TIER]        | [LOADS]                       | [COST_PROFILE]                                            |
| :-----: | :------------ | :---------------------------- | :-------------------------------------------------------- |
|  [01]   | `description` | Every session, budgeted       | Competes with every installed sibling for listing space   |
|  [02]   | `SKILL.md`    | On selection                  | Persists across turns; rides compaction in a token budget |
|  [03]   | `references/` | On route, per branch          | Paid only by the task that takes the branch               |
|  [04]   | `scripts/`    | Never — executes              | Invocation line plus receipt; implementation stays on disk |
|  [05]   | `assets/`     | Never — consumed by scripts   | Zero context cost at any size                             |

## [02]-[FILE_KINDS]

Admission test per kind; a fact failing its kind's test moves down a tier or out of the bundle.

- [DESCRIPTION]: The owned deliverable, the concrete objects and verbs that select the skill, and the negative boundary — third person, nothing else. Admission: the sentence changes selection.
- [ROOT]: The common-path workflow, hard law every activation needs, budget contracts, and one labeled route per branch. Admission: every activation reads it, or it is a route row.
- [REFERENCES]: Deep doctrine one hop from the root, each file whole on its subject, each route labeled by the task that opens it. Admission: one branch needs it, the common path does not.
- [EXAMPLES]: Pressure cases at real composed scale, symptom-indexed, each demonstrating its fix. Admission: agents copy the rule incorrectly without the worked pair.
- [SCRIPTS]: Deterministic checks, conversions, extractions, renders. Admission: the mechanics are deterministic, repeated, drift-prone, or token-heavy as prose. The root carries only the invocation contract and the receipt shape it returns.
- [TEMPLATES]: File-kind instances copied verbatim with slot fills; a finished instance carries zero residual slot tokens.
- [ASSETS]: Binary and data material scripts consume — fonts, schemas, corpora — never read into context.

## [03]-[FRONTMATTER]

The portable core is `name` and `description`; every other field is loader policy, absent unless it changes behavior.

- [PATHS]: `paths` glob patterns bind the listing to work touching matching files — the cure for a monorepo skill whose description otherwise competes everywhere.
- [DISABLE_MODEL_INVOCATION]: `disable-model-invocation: true` removes the description from the listing entirely; only explicit invocation loads the skill. The mode for side-effect workflows and for zero-cost residency when the operator is the index.
- [USER_INVOCABLE]: `user-invocable: false` hides the skill from the invocation menu while the description stays listed — background knowledge the model applies but no one runs as a command.
- [ALLOWED_TOOLS]: `allowed-tools` pre-grants named tool permissions while the skill is active; `disallowed-tools` subtracts from the pool. Grants stay minimal and specifier-scoped.
- [FORK]: `context: fork` runs the body in a forked subagent context, with `agent` choosing the subagent type — the skill becomes a dispatch instead of an in-context load.
- [ARGUMENTS]: `$ARGUMENTS`, `$ARGUMENTS[N]`, and `$N` substitute invocation arguments into the body; absent placeholders append the raw arguments after the body.

Invocation policy resolves to one of three modes: model-invoked (listed description, autonomous selection), operator-invoked (`disable-model-invocation: true`, zero listing cost), or ambient (`user-invocable: false`, listed but never a command). The mode is chosen by who reliably remembers the skill exists and whether firing has side effects.

## [04]-[SHADOWING]

Same-name skills shadow by scope — enterprise over personal, personal over project — so a personal skill silently masks every project master sharing its name. An estate that masters skills inside repos keeps the personal root empty; the repo copy is the single authority and shadowing has nothing to bite. Plugin skills are namespaced and exempt from the contest.

## [05]-[FREEDOM]

Instruction rigidity is priced per instruction by the cost of deviation, never set once per skill.

| [INDEX] | [BAND]    | [WHEN]                                        | [SHAPE]                                                  |
| :-----: | :-------- | :-------------------------------------------- | :-------------------------------------------------------- |
|  [01]   | `PINNED`  | Deviation breaks the run                      | Exact invocation, zero parameters, no narrative retelling |
|  [02]   | `BOUNDED` | A known-good pattern admits local variation   | Template or worked pair with named slots                  |
|  [03]   | `OPEN`    | The correct path follows the task's context   | The deliverable and its acceptance gate, no mandated path  |

Both inversions are the `DEGREES_OF_FREEDOM` defect: a fragile sequence left as loose guidance breaks runs, and a mandated litany over contextual work produces ritual theater. Within any band, required inclusions are stated and reshaping freedom is granted — a body that pins every sentence of the output forecloses the judgment the model was selected for.

## [06]-[SCRIPT_THRESHOLD]

Prose mechanics cross into a bundled script at the first of: the procedure is deterministic end to end; the same steps recur across activations; the prose and an existing tool drift independently; or the narration outweighs its own invocation line. A bundled script is self-contained — pinned interpreter contract, declared dependencies, no network fetch, no global install, no credential read. A skill that legitimately owns an install surface names the exact source, its scope, and its verification step in one row; everything else ships in the bundle and runs as shipped.
