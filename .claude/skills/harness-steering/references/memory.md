# [MEMORY]

Memory is the always-loaded instruction layer: operator-authored files plus model-authored auto memory, delivered as context after the system prompt. It shapes behavior without enforcing it — a rule that must hold under pressure moves to permissions or a hook.

## [01]-[HIERARCHY]

| [INDEX] | [LEVEL] | [LOCATION]                         | [SCOPE]                            |
| :-----: | :------ | :--------------------------------- | :--------------------------------- |
|  [01]   | Managed | OS-level managed path              | Organization-wide non-excludable   |
|  [02]   | User    | `~/.claude/CLAUDE.md`              | Every project on the machine       |
|  [03]   | Project | `CLAUDE.md` or `.claude/CLAUDE.md` | Everyone who clones the repository |
|  [04]   | Local   | `CLAUDE.local.md`                  | Gitignored to this checkout        |

Memory loads upward from the working directory, orders discovered files root to working directory, and appends `CLAUDE.local.md` after its sibling `CLAUDE.md` at each level. Subdirectory memory files lazy-load when work touches files beneath them, so folder conventions live beside the folders they govern instead of bloating the root. Target under 200 lines per file — adherence degrades as memory grows, and overflow moves to path-scoped rules. `claudeMdExcludes` skips matching memory files by glob at any settings scope and merges across scopes; managed files are non-excludable, and the managed `claudeMd` settings key carries organization memory inline without deploying a file. Block-level HTML comments are stripped before injection — free maintainer notes — while comments inside fenced blocks survive. After `/compact` the project-root `CLAUDE.md` re-reads from disk and re-injects; nested memory files reload only when work next touches their subtree, so an instruction that must survive compaction lives at the root.

## [02]-[IMPORTS]

`@path/to/file` inside a memory file expands the target into context at launch; relative paths resolve against the importing file, imports recurse to a depth of four hops, and code spans plus fenced blocks are skipped — backticks around a path keep it literal. Imports organize, never economize: an imported file loads at launch and costs its full weight, so splitting a fat memory file into imports changes nothing the size law cares about. A repository standardized on `AGENTS.md` bridges with a one-line `CLAUDE.md` containing `@AGENTS.md`. Imports pointing outside the project trigger a one-time approval dialog; a declined import stays dormant. A gitignored local file shared across worktrees is an import of an absolute path, since `CLAUDE.local.md` exists only in the worktree that created it. `--add-dir` directories contribute no memory by default; `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1` loads their `CLAUDE.md`, rules, and `CLAUDE.local.md` too.

## [03]-[RULES]

`.claude/rules/**/*.md` and `~/.claude/rules/**/*.md` modularize instructions one topic per file. A rule without `paths` frontmatter loads at launch with project-memory priority; a rule with `paths` globs loads only when work reads a matching file — the trigger is the path predicate, no description competes and no session pays for an unused convention. Globs take brace expansion (`src/**/*.{ts,tsx}`) and multiple patterns per rule; a rule entry resolves through symlinks, so a shared rule set links into many repos from one master, and circular links are handled. User rules load before project rules. Rules split from skills as convention versus procedure: a rule states what is always true of a subtree, a skill packages how a task is done.

## [04]-[CONTENT]

A memory file carries only what a fresh session cannot derive and otherwise gets wrong: commands the repo alone knows, conventions that differ from ecosystem defaults, architectural decisions, environment quirks, gotchas that already caused a repeated mistake. Facts the code answers — layout tours, API inventories, standard-language conventions, self-evident practice — are deleted on sight, and a fact that changes frequently lives with its owner, never in memory.

- [ADMISSION]: Recurrence is the trigger — a second identical correction, a repeated review comment, a question the file exists to answer. An entry authored for an imagined future need is deleted, not improved.
- [REMOVAL_TEST]: Every line must fail deletion — removing it causes a future session to err. A line that survives deletion in imagination is deleted in fact.
- [SPECIFICITY]: Entries are concrete enough to verify — the command, the path, the exact value — never an adjective; vague phrasing reads as ambiguous under pressure and loses to specific siblings.
- [SHAPES]: Two body templates carry the lesson classes prose flattens — a failure lesson as symptom, cause, fix; a preference lesson as the user's phrasing and the behavior it selects.
- [PLACEMENT]: Steering table adjudicates every candidate line: a procedure is a skill, a subtree convention is a path-scoped rule, an enforcement is a setting or hook, a lesson only one worker needs is that worker's memory.
- [FLOW]: Promotion and demotion run both ways — recurring topic-file knowledge promotes into the always-loaded file; a completed project's context, a cold convention, or a path-bound rule demotes out of it. A hardened auto-memory lesson graduates into an operator-authored file; a model-generation workaround is re-tested and deleted when the limitation dies.

## [05]-[AUDIT]

Audit scores every always-loaded memory file per axis; the file's grade is its weakest axis, so one rotten dimension never averages away. An axis failure names its lines, and each repair routes through the steering table — delete, demote, sharpen, or move.

| [INDEX] | [AXIS]       | [PASS_WHEN]                                                                 |
| :-----: | :----------- | :-------------------------------------------------------------------------- |
|  [01]   | Derivability | No line states what disk, manifests, or ecosystem defaults already answer   |
|  [02]   | Specificity  | Every rule names a command, path, value, or exact convention                |
|  [03]   | Currency     | Every named command, path, tool, and skill exists today                     |
|  [04]   | Consistency  | No two lines across the loaded hierarchy conflict; one term per concept     |
|  [05]   | Placement    | No procedure, subtree-only convention, or enforcement rides the loaded file |
|  [06]   | Size         | Within the hierarchy's per-file line target, every line passing removal     |
|  [07]   | Integrity    | Every file has a live index line, every index line a file, links resolve    |

Consistency runs across the whole loaded hierarchy, not per file — a user-level line contradicting a project line is one arbitrary coin flip per session. docgen's prose gate stays the mechanical floor beneath this audit — register, hedges, anchors, structure — while these axes judge what only a memory file can get wrong.

## [06]-[RECALL]

Auto-memory recall runs on two surfaces, and authoring optimizes both. At session start the first 200 lines or 25KB of `MEMORY.md` — whichever cap hits first — load as the always-on index; nothing below the boundary exists at startup, and the index re-enters from disk after `/compact`. Per turn, a harness selector scores each memory file's `metadata.type`, filename, and `description` frontmatter against the live task and injects the few winners as recalled context; the file body is invisible to selection, `MEMORY.md` itself is never a candidate, and a file already surfaced stops re-firing that session.

- [HOOK]: Index line and `description` are retrieval triggers, never summaries — each leads with the exact backticked symbols, commands, and paths a future task will type, since lexical overlap with the live prompt decides the firing.
- [FILENAME]: `<type>_<topic>.md` is itself a scored relevance signal — semantic names, never chronological ones.
- [ATOMIC]: a memory file and its index line are one write — a file without an index line is dark at startup, an index line without a file is a dead pointer, and the Integrity axis fails both.
- [BODY_CUE]: recall injects whole files, so the fact leads and its `Why:`/`How to apply:` lines carry the cue for judging whether it still binds; a repo-state snapshot reads stale by construction and never enters.
- [ENVELOPE]: A store's write path stamps `node_type` and `originSessionId` into `metadata` on every write — harness-owned keys no edit removes; the author owns `name`, `description`, and `metadata.type` alone.
- [SPLIT]: a file outgrowing one concern splits by retrieval occasion, and a volatile status line sits apart from the durable fact text so updates never rewrite settled law.

## [07]-[AUTO_MEMORY]

Auto memory is model-authored learning, on by default, stored per project at `~/.claude/projects/<project>/memory/` — derived from the git repository, so every worktree shares one store. `MEMORY.md` is the index, loading at session start under the recall cap; topic files load on demand when referenced. Toggle through `/memory`, `autoMemoryEnabled`, or `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1`; relocate with `autoMemoryDirectory` — an absolute or `~/` path, honored from a project settings file only after the workspace trust dialog, the same gate that governs hooks. This store is machine-local. Curation is real work: stale notes mislead future sessions with the same authority as fresh ones, and a hardened lesson graduates from auto memory into an operator-authored file or skill. `CLAUDE_MEMORY_STORES` mounts additional shared stores beside the project one.

## [08]-[BOUNDARY]

Every memory level is advisory context delivered as a user message after the system prompt — the model weighs it, and under long-context pressure adherence decays. Blocking a tool, protecting a path, or gating a completion is settings and hooks territory: `permissions.deny` rows block deterministically, lifecycle hooks veto with exit code 2, and neither depends on the model remembering anything. Placement test for any candidate instruction: if violation is acceptable-but-unwanted it rides memory, if violation is unacceptable it rides enforcement.

```markdown rejected
NEVER run `terraform destroy` or force-push to main. Always be careful with destructive commands.
```

```json accepted
{ "permissions": { "deny": ["Bash(terraform destroy:*)", "Bash(git push --force*:*)"] } }
```

## [09]-[SUBAGENT_MEMORY]

Subagents load the full memory hierarchy at spawn (Explore and Plan skip it), and a definition with a `memory` field maintains its own persistent directory under the same index cap. Worker-side memory mechanics live with agent-dispatch; the placement ruling — which learnings belong to a specialist versus the shared project store — lands here: knowledge only one worker uses stays in that worker's memory, knowledge every session needs rides the project hierarchy.
