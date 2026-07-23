# [MACROSCOPE]

`.macroscope/` tree drives two surfaces: the local CLI correctness engine over git changes and the hosted PR reviewer with its check runs. Config is markdown concern files and one glob-list ignore file — no JSON schema exists anywhere.

## [01]-[CONCERN_SPLIT]

| [INDEX] | [AXIS]      | [CHECK_RUN_AGENTS]                  | [CORRECTNESS]                         |
| :-----: | :---------- | :---------------------------------- | :------------------------------------ |
|  [01]   | Unit        | one agent = one separate check run  | folds into the one correctness pass   |
|  [02]   | Frontmatter | rich field set below                | optional `include`/`exclude` only     |
|  [03]   | Blocking    | `conclusion: failure` blocks the PR | advisory, inherits the built-in check |
|  [04]   | Surface     | hosted GitHub Checks only           | hosted and local CLI both             |

Each check-run agent is one cross-cutting lens over the whole diff — boundary integrity, topology closure, a strongest-form adversary — seeing what the file-local correctness pass cannot; agents deliberately never re-litigate mechanical checks the correctness lane owns.

## [02]-[CHECK_RUN_AGENTS]

`.macroscope/check-run-agents/*.md` frontmatter fields: `title` (60 chars max, the Checks-tab name), `input`, `effort`, `reasoning`, `model`, `conclusion` (`neutral` advisory default / `failure` may block merge), `include`/`exclude` glob arrays, `labels`/`authors`/`targets` run filters, `requiredStatusCheck`, `showToolCalls`, `waitsFor` with `waitsForTimeout`, `maxRuns`.

## [03]-[LENS_DEPTH]

- `model:` omitted inherits the product default; an unrecognized or deprecated id SKIPS the check ("model is not available") with no fallback — never hardcode an id in a lens. Enumerate the live roster through the docs' machine-readable index: `docs.macroscope.com/llms.txt` names the models page, and no CLI enumeration route exists.
- One knob bites per model: `effort` (`low`/`medium`/`high`) is agentic depth, Anthropic models only; `reasoning` (`off` through `xhigh`) is extended-thinking budget for OpenAI, open-source, and the older Anthropic models that expose it — newer Anthropic models set thinking automatically and ignore it, and `xhigh` is single-model, downgrading to `low` with a warning elsewhere. Set the knob the roster row marks live and leave the other unset.
- Depth matches the LENS's semantic difficulty, never the artifact: mechanical or `pr_metadata` gates ride low/off, doctrine conformance low, boundary/topology/owner-shape medium, adversarial strongest-form correctness high (`xhigh` only where supported); a `code_object` fan-out grades the per-object judgment then steps DOWN one for the multiplier, and a `conclusion: failure` blocking lens steps UP one over the same lens run `neutral`.
- `input` decides the fan-out: `full_diff` runs one agent over the whole diff, `code_object` up to 20 parallel agents — one per changed object, count capped at 20 and ungated by effort — and `pr_metadata` one agent over metadata alone. Higher depth costs more tokens and latency, multiplied by object count under `code_object`.
- CI gating: `waitsFor` (check names, matched case-insensitive) with `waitsForTimeout` (minutes, 1-60, default 20) hold a lens for prerequisites; `maxRuns` caps per-PR runs, `@macroscope review` bypassing the cap; `requiredStatusCheck: true` always reports a conclusion, for branch protection.

## [04]-[CORRECTNESS]

- `.macroscope/correctness/**/*.md`: frontmatter is optional and carries only `include`/`exclude` glob arrays; omitting both applies the file globally.
- Macroscope walks `correctness/` recursively — subfolders are purely organizational (globs alone decide targeting, never the folder path), only `*.md` is processed, `README.md` is ignored, and every matching file stacks cumulatively onto a changed file.
- One topic per file with room to grow: `general/` carries only law that bites every language and concern, and a file accumulating a distinct defect family's cluster — or one the sediment law can no longer shrink — spins that cluster into a family-named sibling under the owning subfolder, split at the family grain, never per-rule; the source file keeps its concern-spanning residue, and the sibling's globs carry any targeting the move sharpens.
- Body shape: one `# [UPPERCASE_LABEL]` H1 and markdown instructions.

## [05]-[IGNORE]

`.macroscope/ignore` REPLACES the built-in defaults (vendored deps, generated code, binary assets, test files) rather than extending them — preserving a default means copying its pattern back in; one glob per line, `#` comments, blank lines skipped, and the file governs both code review and check-run agents. A bare basename does NOT self-exclude a file, and the accepted glob spelling is unpinned — prove a new pattern by running a review and grepping the flagged paths. Docs name the file `ignore`; a live tree carrying `ignore.md` is honored, and disk is ground truth over the docs' spelling.

## [06]-[CLI_SEMANTICS]

- Fix-at-root lane: `macroscope codereview --raw --in-place --base <base>` — review and fixes share the real working tree, and `--raw` blocks to completion streaming everything on stderr while stdout stays empty.
- Base semantics: `--in-place` without `--base` diffs against `HEAD` — uncommitted only, so on a branch it reviews almost nothing; `--in-place --base <ref>` spans committed branch work and uncommitted edits.
- Stream grammar, in emission order: `review_id=<jwt>` once, `issue_event={issue_id, sequence, path, function, line, end_line, severity, category, body}` per finding, terminal `issue_status=completed`. Category and severity vocabularies are open — `REVIEW_TYPE_CORRECTNESS` covers security findings too, `medium` and `critical` sit on the wire — so an adapter passes both through raw and never enum-gates them.
- Empty-diff terminal: `error: no objects found - check if there are any changes to supported files` on stderr, exit 1, no `issue_status` marker — a clean zero-findings review, never a failure.
- Worktree custody: the default (non-`--in-place`) flow builds `<repo>/.worktrees/macroscope-review-<sha>` and a `macroscope/review-*` branch and strands BOTH even on success; detect via `git worktree list --porcelain`, clean via `git worktree remove -f <path>`, `git worktree prune`, `git branch -D macroscope/review-*`. In-place runs strand nothing, and the rail's macroscope launch preflight sweeps prior strays.
- No status subcommand exists; `macroscope me | jq -e .success` gates auth.
- A `codereview` failing `FailedPrecondition: … CLI update required` means a stale binary — update the binary alone from the release asset (`curl -fL https://github.com/prassoai/macroscope-local/releases/latest/download/macroscope-darwin-arm64 -o <tmp> && chmod +x <tmp> && mv <tmp> ~/.local/bin/macroscope`), then `macroscope me` confirms acceptance; never `macroscope update`, which re-installs the editor plugins and demands a TTY.
- No per-run instruction flag exists — `.macroscope/` files are the only steering channel, so an aimed round lands its concern file first, then launches.
- Local runs read `correctness/**` and `ignore`; check-run agents ride the hosted Checks surface, so a local run surfaces correctness-style issues, never per-agent check runs.

## [07]-[LANGUAGES]

Two engines split the roster: mainstream application languages get native AST-level, per-language-tuned review, and every language outside that set rides the agentic cross-file engine. `macroscope --help` and the vendor release notes carry the current native set. C# rides the agentic engine, so C# doctrine reaches the reviewer only through `correctness/csharp/*` instructions. Config files, documentation, and scripts review as non-code, which is how markdown planning corpora enter scope.

## [08]-[DISTILL_SURFACE]

A distill fact lands as a `correctness/**` topic file or a check-run-agent lens: one topic per file, a new file earned only by a new topic — a fact extending a standing topic edits that file in place, an outgrown topic splits into sibling files, and a lens edit widening its hunt scope ripples its `include` globs. Format gate: YAML-frontmatter parse, glob sanity, and the prose gate.
