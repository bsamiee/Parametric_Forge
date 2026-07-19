# [ANATOMY]

A bundle is a directory whose every file sits at the lowest tier that owns it: the description is always resident, the root loads on selection, references load on route, scripts execute without loading, and assets are consumed without ever entering context. Tier placement is the whole cost model — a fact placed one tier too high taxes every session or every activation for nothing.

## [01]-[TIERS]

| [INDEX] | [TIER]        | [LOADS]                     | [COST_PROFILE]                                             |
| :-----: | :------------ | :-------------------------- | :--------------------------------------------------------- |
|  [01]   | `description` | Every session, budgeted     | Competes with every installed sibling for listing space    |
|  [02]   | `SKILL.md`    | On selection                | Persists across turns and compaction inside a token budget |
|  [03]   | `references/` | On route, per branch        | Paid only by the task that takes the branch                |
|  [04]   | `scripts/`    | Never — executes            | Invocation line plus receipt; implementation stays on disk |
|  [05]   | `assets/`     | Never — consumed by scripts | Zero context cost at any size                              |

## [02]-[FILE_KINDS]

Admission test per kind; a fact failing its kind's test moves down a tier or out of the bundle. Kinds are closed and `SKILL.md` is the only routing surface — a `README.md` or secondary router at any depth is a defect.

- [DESCRIPTION]: Owned deliverable, the concrete objects and verbs that select the skill, and the negative boundary — third person, nothing else. Admission: the sentence changes selection.
- [ROOT]: Common-path workflow, hard law every activation needs, budget contracts, and one labeled route per branch. Admission: every activation reads it, or it is a route row.
- [REFERENCES]: Deep doctrine one hop from the root, each file whole on its subject and each route labeled by the task that opens it; a reference past 100 lines carries navigational structure — family sections or a leading index. Admission: one branch needs it, the common path does not, and the hop repays its route row with doctrine the root cannot hold and that branch cannot skip. A reference failing the bet folds into the root or dies — existence admits nothing.
- [EXAMPLES]: Pressure cases at real composed scale, symptom-indexed, each demonstrating its fix. Admission: agents copy the rule incorrectly without the worked pair, and the accepted half drops into a template or live bundle unchanged — every example is an executable seed, never an illustration.
- [SCRIPTS]: Deterministic checks, conversions, extractions, renders. Admission: the mechanics are deterministic, repeated, drift-prone, or token-heavy as prose. Root carries only the invocation contract and the receipt shape it returns.
- [TEMPLATES]: File-kind instances copied verbatim with slot fills, each distilled from a proven example; a finished instance carries zero residual slot tokens.
- [ASSETS]: Binary and data material scripts consume — fonts, schemas, corpora — never read into context.

## [03]-[ROOT_SCHEMA]

Every root conforms to one structural schema, so an agent predicts any SKILL.md's shape before opening it and a census proves the fleet byte-structural.

- [H1]: `# [SKILL_TOKEN]` — the directory name in UPPER_SNAKE, nothing else; never a prose title, never a tier prefix.
- [LEAD]: Charter paragraphs under the H1 carry law only — no routing links; a cross-skill pointer names the sibling skill in prose, never a link.
- [ROUTING]: a bundle with routable files opens its numbered sections with `## [01]-[ROUTING]` — a router-card list `- [NN]-[TOKEN](path): phrase`, grouped under `[REFERENCES]:` / `[TEMPLATES]:` / `[EXAMPLES]:` / `[SCRIPTS]:` labels when more than one file kind routes, each group numbered from `[01]`. A flat bundle (no routable files) carries no routing section and its content sections start at `[01]`.
- [SECTIONS]: H2s run `[NN]-[UPPER_SNAKE]` sequentially with `-[EXTRA]` qualifier chains legal; H3s run `[NN.M]-[TOKEN]`. Group labels inside sections are `[TOKEN]:` lines, never bold. Shared concerns keep the shared name — `[GATE]` for the deterministic gate, `[GOTCHAS]` for trap rosters, `[REPO_INTEGRATION]` for repo-canon composition.
- [FAMILY]: sibling skills forming one family keep byte-consistent shapes — identical slot names, identical opening lines modulo the discriminating verb — with one designated law owner carrying the richer structure.

## [04]-[FRONTMATTER]

`name` and `description` form the portable core; every other field is loader policy, absent unless it changes behavior.

- [PATHS]: `paths` glob patterns bind the listing to work touching matching files — the cure for a monorepo skill whose description otherwise competes everywhere.
- [DISABLE_MODEL_INVOCATION]: `disable-model-invocation: true` removes the description from the listing entirely. This is the mode for side-effect workflows and for zero-cost residency when the operator is the index.
- [USER_INVOCABLE]: `user-invocable: false` hides the skill from the invocation menu while the description stays listed — background knowledge the model applies but no one runs as a command.
- [ALLOWED_TOOLS]: `allowed-tools` pre-grants named tool permissions while the skill is active; `disallowed-tools` subtracts from the pool.
- [MODEL_EFFORT]: `model` pins the model to a `/model` value or `inherit`; `effort` pins the reasoning tier.
- [HOOKS]: `hooks` arms lifecycle hooks scoped to the skill's activation — they load with the skill and disarm on exit.
- [FORK]: `context: fork` runs the body in a forked subagent context, with `agent` choosing the subagent type — the skill becomes a dispatch instead of an in-context load. Fork demands an actionable task in the body; a guidelines-only body forked receives its guidelines with no prompt and returns nothing.
- [ARGUMENTS]: `arguments` names positional slots and `argument-hint` supplies their autocomplete; `$ARGUMENTS`, `$ARGUMENTS[N]`, and `$N` substitute them into the body, and absent placeholders append the raw arguments after the body.
- [SHELL]: `shell` selects the interpreter for `` !`command` `` pre-injection lines — `bash` by default, `powershell` under `CLAUDE_CODE_USE_POWERSHELL_TOOL=1`. An injection line runs before the body reaches the model and replaces itself with the command's output.
- [SUBSTRATE]: Body addresses bundled files and scripts by `${CLAUDE_SKILL_DIR}/...`, which expands to the bundle directory; a bare relative path resolves against the session working directory, not the bundle, and breaks whenever the skill fires from elsewhere.

Invocation policy resolves to one of three modes: model-invoked (listed description, autonomous selection), operator-invoked (`disable-model-invocation: true`, zero listing cost), or ambient (`user-invocable: false`, listed but never a command).

## [05]-[FREEDOM]

Instruction rigidity is priced per instruction by the cost of deviation, never set once per skill.

| [INDEX] | [BAND]    | [WHEN]                                      | [SHAPE]                                                   |
| :-----: | :-------- | :------------------------------------------ | :-------------------------------------------------------- |
|  [01]   | `PINNED`  | Deviation breaks the run                    | Exact invocation, zero parameters, no narrative retelling |
|  [02]   | `BOUNDED` | A known-good pattern admits local variation | Template or worked pair with named slots                  |
|  [03]   | `OPEN`    | The correct path follows the task's context | The deliverable and its acceptance gate, no mandated path |

Both inversions are the `DEGREES_OF_FREEDOM` defect: a fragile sequence left as loose guidance breaks runs, and a mandated litany over contextual work produces ritual theater. Within any band, required inclusions are stated and reshaping freedom is granted — a body that pins every sentence of the output forecloses the judgment the model was selected for. `BOUNDED` band names one default and a scoped escape hatch, never a menu of parallel approaches — an option list defers the choice the skill exists to make.

## [06]-[SCRIPT_THRESHOLD]

Prose mechanics cross into a bundled script at the first of: the procedure is deterministic end to end; the same steps recur across activations; the prose and an existing tool drift independently; or the narration outweighs its own invocation line. A bundled script is self-contained — pinned interpreter contract, declared dependencies, no network fetch, no global install, no credential read.

## [07]-[DIAGRAMS]

A root or reference admits a diagram fence only where shape is the content — a dispatch topology, a state machine, a multi-actor flow whose edge structure prose spends a paragraph per arm to carry. A fence whose nodes map one-to-one onto an adjacent table or roster with no edges beyond reading order is decoration and is deleted; the table already carries the information at lower cost.
