# [ANATOMY]

A bundle is a directory whose every file sits at the lowest tier that owns it: the description is always resident, the root loads on selection, references load on route, scripts execute without loading, and assets are consumed without ever entering context. Tier placement is the whole cost model — a fact placed one tier too high taxes every session or every activation for nothing.

## [01]-[TIERS]

| [INDEX] | [TIER]        | [LOADS]                     | [COST_PROFILE]                                             |
| :-----: | :------------ | :-------------------------- | :--------------------------------------------------------- |
|  [01]   | `description` | Every session, budgeted     | Competes with every installed sibling for listing space    |
|  [02]   | `SKILL.md`    | On selection                | Persists across turns; rides compaction in a token budget  |
|  [03]   | `references/` | On route, per branch        | Paid only by the task that takes the branch                |
|  [04]   | `scripts/`    | Never — executes            | Invocation line plus receipt; implementation stays on disk |
|  [05]   | `assets/`     | Never — consumed by scripts | Zero context cost at any size                              |

## [02]-[FILE_KINDS]

Admission test per kind; a fact failing its kind's test moves down a tier or out of the bundle. The kinds are closed and `SKILL.md` is the only routing surface — a `README.md` or secondary router at any depth is a defect, and material it carried folds into the root's route rows or the owning reference.

- [DESCRIPTION]: The owned deliverable, the concrete objects and verbs that select the skill, and the negative boundary — third person, nothing else. Admission: the sentence changes selection.
- [ROOT]: The common-path workflow, hard law every activation needs, budget contracts, and one labeled route per branch. Admission: every activation reads it, or it is a route row.
- [REFERENCES]: Deep doctrine one hop from the root, each file whole on its subject, each route labeled by the task that opens it. Admission: one branch needs it, the common path does not, and the hop repays its route row — the file carries doctrine the root cannot hold and that branch cannot skip. A reference failing the bet folds into the root or dies; the material's existence admits nothing.
- [EXAMPLES]: Pressure cases at real composed scale, symptom-indexed, each demonstrating its fix. Admission: agents copy the rule incorrectly without the worked pair, and the accepted half drops into a template or live bundle unchanged — every example is an executable seed, never an illustration.
- [SCRIPTS]: Deterministic checks, conversions, extractions, renders. Admission: the mechanics are deterministic, repeated, drift-prone, or token-heavy as prose. The root carries only the invocation contract and the receipt shape it returns.
- [TEMPLATES]: File-kind instances copied verbatim with slot fills, each distilled from a proven example; a finished instance carries zero residual slot tokens.
- [ASSETS]: Binary and data material scripts consume — fonts, schemas, corpora — never read into context.

## [03]-[ROOT_SCHEMA]

Every root conforms to one structural schema, so an agent predicts any SKILL.md's shape before opening it and a census proves the fleet byte-structural.

- [H1]: `# [SKILL_TOKEN]` — the directory name in UPPER_SNAKE, nothing else; never a prose title, never a tier prefix.
- [LEAD]: the charter paragraph(s) under the H1 carry law only — no routing links; a cross-skill pointer names the sibling skill in prose, never a link.
- [ROUTING]: a bundle with routable files opens its numbered sections with `## [01]-[ROUTING]` — a router-card list `- [NN]-[TOKEN](path): phrase`, grouped under `[REFERENCES]:` / `[TEMPLATES]:` / `[EXAMPLES]:` / `[SCRIPTS]:` labels when more than one file kind routes, each group numbered from `[01]`. A flat bundle (no routable files) carries no routing section and its content sections start at `[01]`.
- [SECTIONS]: H2s run `[NN]-[UPPER_SNAKE]` sequentially with `-[EXTRA]` qualifier chains legal; H3s run `[NN.M]-[TOKEN]`. Group labels inside sections are `[TOKEN]:` lines, never bold. Shared concerns keep the shared name — `[GATE]` for the deterministic gate, `[GOTCHAS]` for trap rosters, `[REPO_INTEGRATION]` for repo-canon composition.
- [FAMILY]: sibling skills forming one family keep byte-consistent shapes — identical slot names, identical opening lines modulo the discriminating verb — with one designated law owner carrying the richer structure.

## [04]-[FRONTMATTER]

The portable core is `name` and `description`; every other field is loader policy, absent unless it changes behavior.

- [PATHS]: `paths` glob patterns bind the listing to work touching matching files — the cure for a monorepo skill whose description otherwise competes everywhere.
- [DISABLE_MODEL_INVOCATION]: `disable-model-invocation: true` removes the description from the listing entirely; only explicit invocation loads the skill. The mode for side-effect workflows and for zero-cost residency when the operator is the index.
- [USER_INVOCABLE]: `user-invocable: false` hides the skill from the invocation menu while the description stays listed — background knowledge the model applies but no one runs as a command.
- [ALLOWED_TOOLS]: `allowed-tools` pre-grants named tool permissions while the skill is active; `disallowed-tools` subtracts from the pool. Grants stay minimal and specifier-scoped.
- [FORK]: `context: fork` runs the body in a forked subagent context, with `agent` choosing the subagent type — the skill becomes a dispatch instead of an in-context load.
- [ARGUMENTS]: `$ARGUMENTS`, `$ARGUMENTS[N]`, and `$N` substitute invocation arguments into the body; absent placeholders append the raw arguments after the body.

Invocation policy resolves to one of three modes: model-invoked (listed description, autonomous selection), operator-invoked (`disable-model-invocation: true`, zero listing cost), or ambient (`user-invocable: false`, listed but never a command). The mode is chosen by who reliably remembers the skill exists and whether firing has side effects.

## [05]-[SHADOWING]

Same-name skills shadow by scope — enterprise over personal, personal over project — so a personal skill silently masks every project master sharing its name. An estate that masters skills inside repos keeps the personal root empty; the repo copy is the single authority and shadowing has nothing to bite. A project skill likewise replaces a bundled skill sharing its name, and a skill beats a same-named command file. Plugin skills are namespaced and exempt from the contest.

Three residency mechanics complete the placement picture:

- [NESTED]: Skills in `.claude/skills/` directories below the working directory coexist with a same-named root skill instead of shadowing it — the nested bundle lists under a directory-qualified name (`<dir>:<name>`), an unqualified invocation loads the root skill with the qualified variants appended, and the variant whose directory holds the working files still applies. A monorepo package owns its skills without contesting the root's names.
- [SYMLINK]: A skill entry at any level resolves through a symlink to a directory elsewhere on disk, and one target reachable from several locations loads once — a master bundle can live outside the scan roots with links standing in.
- [LIVE_RELOAD]: Watched skill directories hot-reload `SKILL.md` adds, edits, and removals within the running session; only a top-level skills directory created mid-session needs a restart. The authoring loop — tune a description, re-test the trigger — runs without session churn.

## [06]-[FREEDOM]

Instruction rigidity is priced per instruction by the cost of deviation, never set once per skill.

| [INDEX] | [BAND]    | [WHEN]                                      | [SHAPE]                                                   |
| :-----: | :-------- | :------------------------------------------ | :-------------------------------------------------------- |
|  [01]   | `PINNED`  | Deviation breaks the run                    | Exact invocation, zero parameters, no narrative retelling |
|  [02]   | `BOUNDED` | A known-good pattern admits local variation | Template or worked pair with named slots                  |
|  [03]   | `OPEN`    | The correct path follows the task's context | The deliverable and its acceptance gate, no mandated path |

Both inversions are the `DEGREES_OF_FREEDOM` defect: a fragile sequence left as loose guidance breaks runs, and a mandated litany over contextual work produces ritual theater. Within any band, required inclusions are stated and reshaping freedom is granted — a body that pins every sentence of the output forecloses the judgment the model was selected for.

## [07]-[SCRIPT_THRESHOLD]

Prose mechanics cross into a bundled script at the first of: the procedure is deterministic end to end; the same steps recur across activations; the prose and an existing tool drift independently; or the narration outweighs its own invocation line. A bundled script is self-contained — pinned interpreter contract, declared dependencies, no network fetch, no global install, no credential read. A skill that legitimately owns an install surface names the exact source, its scope, and its verification step in one row; everything else ships in the bundle and runs as shipped.

## [08]-[DIAGRAMS]

A root or reference admits a diagram fence only where shape is the content — a dispatch topology, a state machine, a multi-actor flow whose edge structure prose spends a paragraph per arm to carry. A fence whose nodes map one-to-one onto an adjacent table or roster with no edges beyond reading order is decoration and is deleted; the table already carries the information at lower cost. Type selection, construction, and render validation ride the mermaid-diagramming skill — this test owns admission alone, and the worked pair sits in the repairs file.
