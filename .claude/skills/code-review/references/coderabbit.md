# [CODERABBIT]

`.coderabbit.yaml` at the repository root owns CodeRabbit behavior for hosted and CLI reviews alike; organization and workspace overrides outrank it, and it outranks every UI setting. Top-level `inheritance: true` opts into the central config in a repository named `coderabbit`, the chain stopping at the first parent lacking the flag. Reviews are language-general; per-language depth rides the static-analysis tool gates below.

## [01]-[SCHEMA_AND_LIMITS]

A real JSON Schema validates the file, fetched fresh from the pinned URL into the gitignored cache — never a vendored copy; a `# yaml-language-server: $schema=<url>` modeline gives editors the same schema live. `ajv-cli` takes only a local schema path, the schema rides draft 2020-12 and carries the non-standard `enumNames`, and no bare `ajv` sits on PATH — so `npx`, the fetch step, `--spec=draft2020`, and `--strict=false` are each load-bearing:

```bash copy-safe
curl -fsSL https://coderabbit.ai/integrations/schema.v2.json -o .cache/coderabbit-schema.v2.json
npx ajv-cli validate --spec=draft2020 --strict=false -s .cache/coderabbit-schema.v2.json -d .coderabbit.yaml
```

| [INDEX] | [FIELD]                                         | [LIMIT]     |
| :-----: | :---------------------------------------------- | :---------- |
|  [01]   | `reviews.path_instructions[].instructions`      | 20000 chars |
|  [02]   | `tone_instructions`                             | 250 chars   |
|  [03]   | `pre_merge_checks.custom_checks[].instructions` | 10000 chars |
|  [04]   | `knowledge_base.learnings.approval_delay`       | 0-30 days   |

`tone_instructions` is a top-level key, a sibling of `reviews` — nesting it under `reviews` fails the schema.

## [02]-[GUIDANCE_CHANNELS]

Four channels, routed by durability and origin:
- [PATH_INSTRUCTIONS]: durable reviewer law versioned in the repo — the distill surface below.
- [GUIDELINE_FILES]: `knowledge_base.code_guidelines.filePatterns` absorbs doctrine files wholesale — plain globs or `{files, applyTo}` objects whose comma-separated `applyTo` globs scope a guideline set to the paths it governs; defaults cover the `CLAUDE.md`/`AGENTS.md` agent-rule family.
- [RUN_CONTEXT]: `-c <files...>` on `coderabbit review` attaches per-run instruction files — the focus channel.
- [LEARNINGS]: hosted-PR chat-taught facts (`@coderabbitai remember`) stored server-side; `learnings.scope` picks `local`/`global`/`auto`, `approval_delay` gates auto-apply, and `opt_out: true` erases stored data irrevocably.

## [03]-[HIGH_LEVERAGE_FIELDS]

- `reviews.profile`: `quiet` | `chill` | `assertive`.
- `reviews.path_filters`: include/exclude globs, `!` prefixing excludes.
- `reviews.pre_merge_checks`: per-check `off`/`warning`/`error`; `error` blocks the PR under `reviews.request_changes_workflow: true`.
- `reviews.tools.<tool>.enabled`: per-tool static-analysis gates over the schema's tool catalog (`ruff`, `biome`, `shellcheck`, `gitleaks`, and peers); `ast-grep` alone takes `essential_rules` instead of `enabled`.
- `reviews.finishing_touches` / `reviews.slop_detection.enabled` / `reviews.enable_prompt_for_ai_agents`: post-review recipes, slop screening, inline AI-fix prompts.
- `knowledge_base.mcp.usage`: `auto`/`enabled`/`disabled` and `disabled_servers[]`.
- `knowledge_base.linked_repositories[]`: `{repository, instructions}` cross-repo context rows.

## [04]-[RUN_AND_BASE]

- `coderabbit review --agent` scope flags: `-t all|committed|uncommitted` (default `all`), `--base <branch>`, `--base-commit <commit>` pinning a small on-branch diff, `-c <files...>` per-run instruction files, `--light` for a reduced-context fast pass. `--light` and `--base-commit` are the two cheap post-fix re-review levers; `--dir` path-scoping breaks store correlation (`git.json` `workingDirectory` anchors the epoch match at the repo root) and stays unexposed.
- Every scope needs a resolvable base — even working-tree scopes call `getBranchInfo`. Resolution order: current-branch upstream, `origin/HEAD`, `git config coderabbit.baseBranch` naming an EXISTING branch; base==current is fine for working-tree scopes.
- A base failure exits the process 0 while emitting `{"type":"error","details":{"stage":"gitService.getBranchInfo"}}` on the stream within a second — the error line, never the exit status, carries the failure.

## [05]-[STREAM_AND_STORE]

- `--agent` emits NDJSON on stdout, line types `review_context` (first: reviewType, current and base branch, workingDirectory), `status`, `heartbeat` (the only keep-alive through the long analysis gap), `finding`, `complete` (terminal: status, finding count, reviewed files), and `error` — the failure channel, since errors ride it at exit 0. A streamed `finding` carries only `{severity, fileName, codegenInstructions, suggestions}` — liveness-only, so the stream never yields title, comment, or line range.
- Rich per-finding records live at `~/.coderabbit/reviews/<repoHash>/<subHash>/reviews/<epochMs>/<uuid>.json`, one file per finding: `title`, `comment` (markdown carrying the proposed-fix diff), `lineRange`, `commentCategory`, `severity` ranking `critical` > `major` > `minor` > `trivial` > `info`, `codegenInstructions` (consume first, `comment` the fallback), `fingerprint` (CodeRabbit's own dedup key, `phantom:<codename>:<codename>` form), and `id`, the store back-link uuid.
- Sibling `git.json` carries `workingDirectory` and `timestamp` in epoch SECONDS (review start) — the run-to-store correlation key; the epoch directory name and per-finding `timestamp` are epoch MILLISECONDS (write time). `internalState.json` carries the walkthrough summary in `rawSummaryMap`; `diff.json` and `incrementalDiff.json` are diff payloads, never findings.
- Store reads are the only recovery for a finished review: `coderabbit review findings` reprints human text only (it drops `--agent` silently) and can replay a previous unrelated review — never a harvest source, and a finished review is never re-run to recover its findings.

## [06]-[DISTILL_SURFACE]

A distill fact lands as a clause inside the owning `reviews.path_instructions` block `{path, instructions}` — never a per-fact block or row; `path` is a minimatch glob, and the owning block is the NARROWEST path whose files the clause bites: universal stance alone rides the global `path: "{**,.claude/**}"` block, a clause biting one language, corpus, or path family rides that family's block, and a misplaced clause relocates before any other cure. Each block's 20000-char instruction limit is a hard schema bound — measure every touched block in the same pass (`yq -r '.reviews.path_instructions[].instructions | length' .coderabbit.yaml`), and a block past 16000 relieves pressure immediately: first relocate misplaced clauses to their owning blocks, then collapse sediment under the trim law; a breach fails the pinned schema and the engine's read of the block is undefined. Clause grain is the same law one level down: the prose gate never reads YAML, so nothing else watches clause growth — probe every touched block (`yq -r '.reviews.path_instructions[].instructions' .coderabbit.yaml | awk '{print length}' | sort -rn | head`), and a clause several times its block's sibling median holds fused decisions, the bad-guidance signal itself: split it into sibling one-decision clauses, collapse its restatement, or relocate its language-bound halves — in the same touch, never deferred. `path_instructions` outrank server-side learnings, so durable law lands here while learnings stay ephemeral chat-taught facts; `tone_instructions` carries register alone and never policy. Every landed edit re-passes the pinned-schema validation.
