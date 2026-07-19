# [STYLE_GUIDE]

Language law for every durable artifact: what a sentence is allowed to carry, at what altitude, in which words.

## [01]-[USE_WHEN]

Apply when writing or reviewing prose, headings, captions, notes, examples, comments, commands, paths, symbols, placeholders, terminology, and accessibility-sensitive wording in any durable artifact — docs, standards, specs, skills, prompts, templates, and code fences.

## [02]-[WORDING_PRECEDENCE]

Use the first owner that decides a naming or wording question:
1. Current repository material, manifests, generated contracts, API fields, and actual product or package names.
2. Active document-type standard for the document being written.
3. Maintained product names, UI labels, APIs, commands, and support status.
4. This guide for local prose and notation rules.
5. Established editorial style for unresolved general mechanics.

When owners conflict, choose the repo-local term only when a current route or contract proves it. Never alternate terms to avoid the conflict.

## [03]-[AGENT_PROSE]

Durable prose is law for agents that read it with no memory of why it was written. Every sentence is either law an agent must obey or a defect that anchors, drifts, or wastes tokens.

[REGENERATION_TEST] — Runs sentence by sentence: delete the sentence. A fresh agent regenerating the fact from disk plus the document's stated invariants proves it a mirror — delete it, or demote it to a fenced representation when structure must be shown. A fact that cannot be regenerated is law kept at the altitude that owns it, still answerable to every defect class — surviving regeneration rules out the mirror alone, never a freeze, hedge, or ledger the catalog deletes. Fences and diagrams are exempt: a representation is declared regenerable, verified by tooling, and never paraphrased back into prose.

[FACT_CLASSES] — Every fact in a durable doc is exactly one of:
- [LAW]: Intent, invariant, boundary, prohibition. Survives any rename. Carried in prose.
- [REPRESENTATION]: A structure snapshot (tree, codemap, diagram). Regenerable from disk, verified by tooling, carried only in a fence or diagram, never restated in prose.
- [REGISTRY]: A fact whose system of record is the doc itself (package admissions, seam contracts) — the only class allowed to enumerate.

[ALTITUDE] — A fact lands at the lowest tier that owns it; a higher tier states only the invariant the fact instantiates. A sentence that can move one tier down without losing governing force over more than one child is at the wrong altitude. Fixing a violation demotes the fact to its owner, then collapses the higher copy — payload dropped during demotion is a defect.

Tier ledger — what each tier carries; everything below its line is a lower tier's property:
- [ROOT_README]: Repo purpose, layer law, and entry routes by concern — never folder inventories, tool rosters, or package facts.
- [BRANCH_INDEX]: Branch invariants, package-grain topology and seams, and admission law — never a package's member inventory or file names.
- [FOLDER_INDEX]: Folder charter, sub-domain structure, package-grain seams, and package registries — never file-tier wire truth, signatures, literals, or sibling-doc description.
- [SPEC]: Mechanism, signatures, wire byte-truth, literals, and one owner's flow — never branch law restated or sibling pages re-taught.
- [CARD]: Scoped intent, integration points, and growth — never design content or settled law.
- [COMMENT]: One in-situ constraint the code cannot show — never anything else.

## [04]-[DEFECT_CATALOG]

Defect classes are the review vocabulary; findings cite the class and the line.

[ENUMERATION_ANCHOR] — Lists or counts enumerable content: files, folders, types, functions, packages — or the document's own members. Every list is a second copy of a truth living elsewhere; each add, rename, or removal stales it silently, and future agents read the stale copy as binding law. Its self-directed form counts or characterizes the document's own content — a member count, a completeness claim ("the complete catalog"), an ordinal self-reference ("the third law below"), a size self-description — and the next entry falsifies it. A quantity is legal only as a rule threshold, a domain value, or a count whose members are enumerated in the same clause.

- Rejected: `runtime` mints `ContentIdentity`/`ContentKey`, `BoundaryFault`/`RuntimeRail`, `Retry`, `RuntimeContext`/`SettingsAdmission`, and `Receipt`/`ReceiptContributor`, and references no sibling.
- Accepted: One package is the foundation: it mints the shared value, fault, transport, and receipt owners, and references no sibling.
- Reason: Accepted form states the invariant class; the member list is the owning folder's topology, regenerable from disk. Scalar counts of surfaces ("five sub-domains", "22 types") are the same defect; domain values are data, not enumeration.

[STALE_MIRROR] — A hand-maintained copy of truth whose system of record is elsewhere: disk, a manifest, a lockfile, another doc.

- Rejected: A README routing table carrying one row per spec page under `.planning/`.
- Accepted: One card per sub-domain pointing at `.planning/<sub>/`; the tree is the page index.
- Reason: Docs add only the intent the tree cannot carry; navigation below the pointer is disk truth.

[MECHANISM_LEAK] — Index-tier prose carrying spec-tier mechanism: wire framing, hash algorithms, buffer sizes, exact signatures.

- Rejected (index doc): streaming the GLB as 64 KiB Crc32-framed rows keyed by the seed-zero XxHash128 artifact hash.
- Accepted (index doc): serve frames and never tessellates.
- Reason: Frame size, checksum, and seed live on the spec that owns the serve mechanism; the index states the boundary invariant. Demote the mechanism, never delete it.

[META_FRAME] — Prose describing the artifact, its audience, its siblings, or its process instead of stating law.

- Rejected: This file routes the spec pages and registers the packages; `ARCHITECTURE.md` carries the domain map and `TASKLOG.md` the open work.
- Accepted: (nothing — the planning standard states the doc-set once; each doc just begins.)
- Reason: N docs restating the doc-set is N copies of one fact plus self-description. Routing surfaces (README indexes, route maps, instruction files) may name owner relationships because routing is their job.

[TWIN_TRUTH] — One fact stated in two docs or two tiers, in different words. Each wording drifts independently, so a future agent cannot tell which is law.

- Rejected: A seam contract worded in the folder README lead, the ARCHITECTURE seam registry, and the branch ledger — three wordings.
- Accepted: One seam registry edge (package grain, mirrored verbatim at the counterpart) plus the owning spec's mechanism; nothing else.
- Reason: One owner per fact; every other site composes or points.

[HEDGE] — Non-committal qualifiers, deferred-decision markers, and defensive residue around settled decisions: apology, reassurance tails answering unasked doubts, risk-hedge warnings, litigation against a claim nobody made. A durable doc records decisions; an open decision is a tracked item, never a soft sentence. Future tense is legal only on a card growth line and a tracked research item.

- Banned: Word-boundary, page-wide — `should`, `could`, `would`, `might`, `maybe`, `perhaps`, `likely`, `probably`, `propose`, `consider`, `recommended`, `ideally`, `TBD`, `TODO`, `FIXME`, `we`, `our`, `you` — and the synonym forms `is expected to`, `can be`, `aims to`, `is designed to`, `in the future`, `eventually`, `as needed`, `if necessary`.
- Survivors: Contract qualifiers that scope behavior rather than defer decisions — `optional`, `if present`, `where supported`, `when configured`, `only when`, `unless`.
- A prohibition's consequence states in the present tense: `delegating it silently swaps moduli`, never `would swap` — the subjunctive is the hedge wearing a rationale.
- Rejected: Delivery is exactly-once effective — transport plus consumer dedupe by content key (never magic).
- Accepted: Consumer dedupe by content key makes delivery exactly-once effective.
- Reason: Stating the guarantee as the mechanism that produces it kills the reassurance tail, the mood verb, and the anticipated objection.

[REPORT_FRAME] — Session, provenance, freshness, review, or checklist narration in a durable doc: research origins, source tails, "as of" dates, reviewer labels, process history, verification evidence, proof posture, closure checklists.

- Rejected: All members decompile-verified against `provider 12.2.0`; four proofs, each independently fatal.
- Accepted: (the member set and the rule, stated as law.)
- Reason: Verification happens before authoring; durable artifacts state resulting law and omit origin — history is version control's job.

[CAPABILITY_GATE] — Capability adjudicated against consumer presence, in either polarity: deferral gates it behind future demand; defense argues a consumerless addition past an imagined objection. Consumer count is never a design axis.

- Rejected: The growth register re-opens this row only when a consumer names it; assume 5x the consumer demand on every surface.
- Accepted: Graphite rows bind the recorder surface at composition.
- Reason: Arm, contract, and policy row are designed now in full; only the binding fact varies at composition. A capability that cannot yet be modeled gets silence; open work is a card.

[LEGACY_COMPAT] — A shape preserved because an old caller, persisted reader, or predecessor depends on it; retired engines, dead aliases, and migration grace narrated in owner law.

- Rejected: The legacy ingress survives as the fallback row for controllers that predate the gateway class.
- Accepted: Clusters without the gateway class select the ingress row.
- Reason: Coexisting arms are peer rows selected by a present environment fact. A genuine persisted-wire pin is a positive wire property stated once at its codec owner; everything else has no predecessor to spare.

[IMPORTED_POSTURE] — A foreign authority's posture adopted over the corpus ruling: an upstream maturity label on a ruled standard, the ecosystem default presented as the default here, a fallback named beside the ruling, probationary ceremony on the ruled path, environment caveats the operating environment already resolves.

- Rejected: The engine stays experimental — a diagram ships only after its render is inspected, and the shared renderer is the fallback when a defect bites.
- Accepted: One engine lays out every graph family; a family that cannot take it routes to its own engine truth, and each engine trap carries its authoring rule beside it.
- Reason: A maturity label, default, or risk posture is a fact about the upstream, never law here. Reframing flips the authority: the ruling stated as owned law, every alternative demoted to a boundary fact where the standard structurally cannot apply, each trap carrying its in-standard answer.

[VERSION_ANCHOR] — Durable prose anchored to a release point in time: a version number or pin, a version-conditional behavior band, a date, release narration, or deictic freshness vocabulary — `newest`, `latest`, `modern`, `currently`, `recently`. This corpus assumes the newest stable release of everything it touches.

- Rejected: The neo look lands at 2.14.0+; the curve default moved at 2.13.0 — restore the spline with the prior key.
- Accepted: `neo` is an admitted look key; the curve default is `rounded`, and `basis` restores the spline.
- Reason: Behavior is stated as the behavior — the newest stable's truth with no band. A genuine wire or persistence version boundary is a positive property stated once at its codec owner; every other pin lives in the owning manifest alone.
- Survivors: A capability floor a doctrine page legislates — interpreter floor, tool major — is admission law stated once at the owning page; registry data inside a compatibility matrix is the document's own system of record; an ordering selector (`latest` session, `newest` commit) states a cursor, never freshness. Trigger vocabulary a law page enumerates rides code spans, and a standards-document clause or table citation (`Table 2.3.2`, `§ 6.3`) is a domain value, never a release pin.

[SET_IN_STONE] — Wording that freezes the current shape against ground-up rebuild: SEALED, FROZEN, FINAL, legislated counts, "never re-opened", per-member byte-identical chants.

- Rejected: The FROZEN twenty-column receipt: field names, types, and order are byte-identical wire law.
- Accepted: Each receipt's `[Key]` sequence is the persisted decode contract; growth is trailing-append.
- Reason: A real wire contract is stated once at its owning declaration; a design-shape freeze is deleted outright. Partition principle is the law; a count is reported, never legislated.

[WEAK_VERBS] — Permission verbs — `supports`, `allows`, `enables`, `provides`, `offers` — where an owning verb states law, including a permission verb smuggled into the object of an owning main verb (owns the option to enable).

- Rejected: The package offers an optional self-hosted graph lane.
- Accepted: Only the self-hosted profile row binds the graph lane.
- Reason: Packages are material the owner consumes, never benefactors that supply; the deployment condition is a policy row, not a hedge in the verb.

[VERB_LED_OPENER] — A prose opener riding the definite article: a sentence opening on `The`, a list entry opening on `the`, or an annotation after a named-surface leader (`` `Symbol` — the ... ``, `- [LABEL]: the ...`) re-labelling the leader instead of acting on the concern. An opener leads with the owner's name, a quantifier, a possessive, a demonstrative, a bare noun, or the claim itself; a leader is already the subject, so an article opener buries it while deciding nothing. Comments answer the same law, in a fence body and a source file alike. Mid-sentence lowercase `the` stays legal everywhere.

- Rejected: `Codec.Frame` — the frame decoder over the ingress stream.
- Accepted: `Codec.Frame` — decodes each ingress frame into the admitted owner.
- Reason: A leader names the surface and its annotation states what the surface does. Lowercasing `The` to `the` is the dodge — it clears the finding and leaves the subject buried.

[LOAD_BEARING_WORD] — Words that do not earn their slot: an intensifier grading what the fact already carries (`powerful`, `seamless`, `comprehensive`, `simply`, `very`), a lead-in delaying the operative verb, a coordinator padding one clause into two, a phrase one verb states, a clause restating its neighbour. Voice is present and active — an owner acts on its concern now, never was-acting, will-act, or is-acted-upon. A finished passage states identical law in a third fewer tokens.

- Rejected: It is important to note that the resolver is a very robust component which will be responsible for handling the seamless mapping of keys, and it also provides comprehensive support for the batch case.
- Accepted: `Resolver` maps every key, batch included.
- Reason: Economy is never bought with capability — every decision, condition, and code span survives the cut, and an entry holding two decisions splits into sibling entries, never a longer line.
- Survivors: A domain term whose grade is the algorithm's property, never the prose's — `robust` in robust predicates and robust arithmetic names the numerical guarantee.

[PROCESS_LEDGER] — Campaign or session bookkeeping fossilized into durable law: ship-status markers, decision tags and ruling IDs, research/wave/gate stamps, self-revision narration.

- Rejected: DECISION [V10]: the trust gate binds every identifier crossing into engine SQL — LANDED, verify and extend.
- Accepted: Every identifier crossing into engine SQL passes the trust gate.
- Reason: Rules are the authority. Open work moves to the card owner; anything resolved reads as if it had always been so — the reader cannot tell which parts were built when.
- In a design-first corpus, realization status is this class: `planned or implemented`, `treat as realized`, `the eventual source file`, and verification narration (`verified against the live decompile`) all die — the corpus charter states once what the work product is, and no page narrates its distance from code.

[ASSERTED_IMPOSSIBILITY] — An impossibility claim ("unspellable", "structurally impossible") whose clause does not name the enforcing structure — a victory lap standing in for the mechanism.

- Rejected: Cross-tenant batching is unspellable.
- Accepted: Batch keys carry the tenant brand, so a batch is tenant-scoped by construction.
- Reason: Enforcing structure is the subject and the impossibility its stated consequence, in one clause; with no nameable enforcer the claim is deleted.

[DELETED_FORM_LITANY] — Law stated as an inventory of forbidden alternatives, the positive rule buried after the corpses or absent. Every enumerated strawman anchors a future agent to the anti-shape.

- Rejected: Zero new surface — a per-extension package, a second engine, an open-per-query connection, inline credentials, or a raw-string identifier is the deleted form.
- Accepted: One broker fold owns permission, cost, and consent for every operation.
- Reason: A total positive claim forecloses every listed corpse by construction. One genuinely non-obvious trap survives as one tight positive invariant; a single prohibition with its enforcing mechanism in-clause is the house register, not this defect.

[COUPLING] — Links, citations, numbered references, or meta-references to files, sources, or the project outside the artifact's own concern, anywhere but a declared routing surface.

- Rejected: Per the fabrication decision and `sibling/page.md`, the codec follows the vendor's recommended framing (see reference 4).
- Accepted: Codecs frame append-only positional rows.
- Reason: Authoring follows verification and states the fact as owned law; routes live in routing surfaces, and the origin dies with the decision that consumed it.

## [05]-[COMMENTS]

Comments — in source files and in transcription-complete fences alike — exist for the agent editing the file in isolation, with none of the index docs loaded.

- A comment carries the one in-situ constraint the code cannot show: the why, the invariant, the trap. Never the what, never a duplicate of card or index content, never process or session narration.
- A comment line fills toward the 150-column width before wrapping; a block is 1-2 wrapped lines, 3-4 only when the constraint truly needs them, never more than 4 stacked. Shortening a kept comment beats keeping a long one.
- Stacked short fragments are one shredded thought: 2 or more consecutive comment lines each under 100 columns merge into one dense line or one properly wrapped block. A wrapped block is legal by construction — its early lines ride near the cap.
- A wrapped block never ends on a runt trailing line: a final fragment far under the width signals re-flow — tighten into fewer lines, let a near-fit collapse ride slightly past 150, or rebalance so the last line carries real width. When content exceeds one cap, the split is asymmetric: the first line packs to 100 columns or more and the tail keeps 50 or more — never an even split, which shreds both lines.
- Header identity rows and the dash divider are frozen structural surfaces, as are shebangs, doc-comment glyphs, and tool pragmas. Charter docstrings below the divider are prose under full comment discipline — filling toward the cap and merging their shreds — exempt only from the stack cap; a dense filled charter earns its length.
- Remediation runs one ladder per comment, in order: delete whole when no load survives — narration, code restatement, a human-facing tour; tighten the load-bearing survivor in place — active voice, coordinating conjunctions, filler dropped; re-wrap the multi-line survivor toward the cap, collapsing 3 lines to 2 and 2 to 1 where the tightened prose fits; inline the one-line survivor governing exactly one line or entry as its trailing tail. Deletion never drops payload.
- A merge is a rewrite, never a concatenation: packing runs only over already-tightened prose, and a collapse that joins fragments verbatim or preserves weak prose is a rejected fix. Detection is mechanical; repair is exclusively read-and-rewrite judgment — no fixer arm, `sed`/regex pass, or scripted bulk rewrite ever mutates comment text.
- A trailing comment rides its code line outside every count and width budget — the inline form is the preferred spelling for a per-line or per-entry constraint. A comment governing a block, category, or more than one line stays a full-line comment above what it governs; inlining it couples the group's law to one member.
- Inlining follows tightening, never replaces it: the tail carries the same discipline — short, atomic, re-tightened on every pass that touches the line — and runs long only where the file kind's own convention carries columnar tails.
- Section dividers, sub-section dividers, and file docstring headers are structural surfaces: corrected in style, structure, or label, never deleted as comment noise.
- A divider's label truthfully charters the block below it. A phantom section — a label naming a concern the block does not own, or a full divider standing where a sub-section belongs — is corrected only after reading the enclosing section structure, never by lexical swap.
- Comments are uncoupled: no paths that break on rename, no references to sessions, passes, reviews, or sibling docs. A machine-config comment naming its owning module's path carries an in-situ ownership constraint and survives; a path that merely narrates is deleted.
- Comment hygiene is a standing obligation: every pass that touches a file — ad hoc or workflow — prunes its stale, drifted, or unnecessary comments and tightens the survivors in the same pass. This ladder audits existing comments and never obligates authoring one on a surface whose code already carries the constraint.

## [06]-[SENTENCES]

Use a front-and-close paragraph shape: sentence one states the rule, claim, scope, outcome, or transition, and the last closes on the consequence, boundary, confirmation, or route the reader retains.

[KEEP_OR_CONVERT]:
- Keep a standalone sentence when it leads, transitions, captions, closes, states a consequence, names a route boundary, or marks a gap.
- Convert a sentence to `Label: value` only when the value is scanned, quoted, or updated independently.
- Convert local detail to a note, alert, or row-owned record only when its scope is local to one row, claim, risk, or artifact.
- Delete or fold a sentence that only repeats emphasis.

[MECHANICS]:
- Coordinating conjunctions join equal-rank ideas: `for`, `and`, `nor`, `but`, `or`, `yet`, and `so`.
- Use a comma before a coordinating conjunction joining two independent clauses.
- Omit the comma for imperative clauses sharing an implied subject unless contrast, length, or ambiguity requires it.
- Omit the comma before a coordinating conjunction that joins only a compound predicate.
- Use a semicolon before and a comma after a conjunctive adverb joining two independent clauses: `however`, `therefore`, `otherwise`.
- Do not join independent clauses with a comma alone.
- Use a semicolon only for closely related independent clauses or complex inline lists with internal commas.
- Use `that` for restrictive clauses and `which` for nonrestrictive clauses.
- Use sentence-initial conjunctions, split infinitives, and terminal prepositions when they produce the clearest technical sentence.
- Construct both arms of a correlative pair in parallel: `both ... and`, `either ... or`, `not only ... but also`.
- State conditions before the actions they control; keep modifiers next to the terms they govern; keep parallel items parallel in grammar and scope.

## [07]-[TERMINOLOGY]

Use one term for one concept inside a bounded context. Names are load-bearing: product names, package names, API members, commands, file paths, UI labels, and config keys match the actual surface.

- Preserve verified product, package, API, command, file, and UI names exactly.
- Define a domain term before relying on it unless the target reader already owns that domain; settled vocabulary arrives settled and is never re-taught.
- Introduce an acronym once per document unless the acronym is more recognizable than its expansion.
- Use singular `they` when gender is unknown, irrelevant, or intentionally unspecified.
- Do not invent reader-facing names for internal concepts; do not name stale commands, removed tools, transient task labels, or removed skills.

## [08]-[PUNCTUATION]

[LOCAL_MECHANICS]:
- Use U.S. English spelling unless a product or proper name differs.
- Form singular possessives with `'s`; use the serial comma; use one space after terminal punctuation.
- Use ASCII hyphen-minus in commands, flags, paths, slugs, identifiers, code, config, tracker literals, and copyable text.

[COLONS_DASHES]:
- Use a colon after a complete sentence that introduces a list, table, example, consequence, or explanation.
- Capitalize the first word after a colon only when the following material is a complete sentence.
- Use parentheses for nonessential clarification; promote required conditions into the main sentence.
- If a parenthetical is a full sentence, put the period inside the closing parenthesis; otherwise outside.
- Use spaced em dashes only for prose interruptions, spelled as the character — ASCII `--` or `---` never stands in for it in prose; en dashes carry inclusive ranges and name-based compounds outside copyable text.
- Hyphenate compound modifiers before nouns when needed for clarity; omit hyphens after `-ly` adverbs; use a suspended hyphen for shared compounds such as `short- and long-term`.
- Prefer sentence splits or vertical lists over semicolon-ended bullets.

[QUOTES_NUMBERS]:
- Use numerals for versions, measurements, commands, flags, identifiers, dates, editions, counts, thresholds, and compared values.
- Spell out isolated nontechnical counts from zero through nine only when the value is not a comparison, threshold, field value, or literal.
- Use backticks for UI labels, commands, code, exact strings, and copied literals.
- Place commas and periods inside closing quotation marks in ordinary prose quotations; preserve literal punctuation for copied text.
- Use straight quotes and ASCII-safe punctuation in copyable Markdown.

## [09]-[CODE_SAFE_MARKDOWN]

- Wrap commands, flags, paths, environment variables, package IDs, symbols, literal values, and placeholders in backticks.
- Name placeholders by route, such as `<scenario-glob>` or `<package-name>`.
- Use language-valid neutral identifiers in reusable code examples: `Shape`, `RefinedShape`, `Variant`, `PRIMARY`, `Field`, `KEY`, `Row`, `ROW_A`, `TABLE`, `SELECTED`, `"<value-a>"`, `"<result-a>"`.
- Do not use repository, host, customer, pricing, deployment, or product nouns in reusable examples unless the documented concept is that domain.
- Omit shell prompts from copyable commands; put sentence punctuation outside a code span unless it is part of the literal.
- When inline code contains a backtick, use a longer matching backtick delimiter rather than a backslash escape.

[PLACEHOLDER_EXAMPLES]:
- Accepted: `Shape`, `RefinedShape`, and `OtherShape`. Near miss: `Customer`, `PremiumCustomer`, and `WebhookPayload`. Reason: accepted names show type structure without importing a business domain.
- Accepted: `Variant`, `PRIMARY`, `SECONDARY`, `"<variant-a>"`. Near miss: `Mode`, `PROD`, `STAGING`, `"premium"`. Reason: accepted names teach enum shape without deployment or pricing semantics.
- Accepted: `SELECTED`, `SELECTED_RESULT`, `"<value-a>"`. Near miss: `active_customer`, `invoice_total`, `"alice"`. Reason: accepted names mark selection and data position without anchoring the sample to an identity or product.

## [10]-[COUPLING]

A durable artifact holds only its own concern. Links, citations, numbered references, and meta-references to other files, sources, or the project couple the artifact to surfaces it does not own — every coupling is a drift channel and an anchor a future rebuild inherits.

- Routing is a file class, never a section grafted onto an ordinary page: `README.md`, a skill root `SKILL.md`, an instruction root (`CLAUDE.md`, `AGENTS.md`), and a memory index `MEMORY.md` are the only durable files that carry links, file paths, or cross-references. Prose in every other file states law without naming where the law came from or where a sibling's law lives; the prose gate fails a relative link anywhere else as `coupled-link`.
- No numbered references, footnotes, citation apparatus, or source names in prose — an external fact is verified before authoring and stated as law; the origin dies.
- No meta-references to sibling artifacts, paraphrased or direct: a fact owned elsewhere is composed silently, or the owning symbol alone is named. Cross-reference and boundaries sections institutionalize coupling and are banned.
- A sibling earns at most one boundary pointer line naming the owner and the one consumed symbol; a section-anchored reference (`page#SECTION`) couples prose to the sibling's interior, and a page never names itself.
- Link text in a routing surface describes the destination; bare URLs appear only as example values.

## [11]-[EXAMPLES]

Examples prove shape or prevent misuse. Place them beside the rule they clarify.

- Use one positive example and one near miss only where agents copy the distinction incorrectly without them.
- Keep example wording aligned with the terminology it teaches.
- Mark copyable, generated, conceptual, output-only, or rejected blocks with the correct fence intent.

## [12]-[ACCESSIBILITY]

- Carry meaning through text, not through color, position, shape, pointer movement, screenshots, or sound alone.
- Provide text equivalents for visual, audio, or screenshot-only information — diagrams carry `accTitle`/`accDescr`, glyph-heavy structures carry adjacent prose stating the relation they encode. A syntax-teaching fence inside a diagram skill's own reference corpus is exempt where the directives corrupt or pollute the taught grammar and adjacent prose already states the relation.
- Use input-neutral UI verbs when keyboard, pointer, touch, voice, or automation can perform the action; preserve exact UI labels when the label is the action target.
- Prefer conventional grammar and punctuation for machine translation.
