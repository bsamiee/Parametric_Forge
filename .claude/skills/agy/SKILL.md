---
name: agy
description: >-
    Bounded one-shot Gemini sub-calls through the Antigravity CLI (`agy`): multimodal judgment
    over screenshots, generated images, UI states, and diagrams, read-only adversarial review
    lanes that return typed falsifiable findings as a second-model perspective, Nano Banana
    image generation and edit iteration feeding html-studio and mermaid work, broad
    synthesis across competing designs, ambiguity reduction into crisp constraints, alternate
    approaches and counterexample hunts, and redacted log or dataset distillation. Use when a
    task gains from an external second model, a critique or red-team stage wants an
    independent Gemini lens, or the request names Gemini, Antigravity, Google Ultra, or Nano
    Banana. gpt-5.6 offload belongs to the codex skill; delegation across Claude's own
    surfaces belongs to agent-dispatch.
---

# [AGY]

Antigravity is an external Gemini call admitted only where it adds capability beyond the local toolchain. The wrapper is print-only — one bounded prompt in, one JSON receipt out — but print mode executes tools and lands file writes without any permission flag, so safety is prompt discipline: a review or judgment prompt names no save path and directs inspect-only work, and a generation prompt binds every save path to a throwaway scratch root, never a repo path or `$HOME`. `--dangerously-skip-permissions` stays unused; it buys nothing print mode lacks. Antigravity output is advisory until local source, official docs, MCP output, or user intent confirms it.

## [01]-[ROUTING]

[SCRIPTS]:

- [01]-[RUNNER](scripts/agy.py): the wrapper this skill invokes; `prompt` and `models` subcommands.

## [02]-[CAPABILITY]

| [INDEX] | [TRIGGER]                                                         | [WHY_GEMINI]                                      |
| :-----: | :---------------------------------------------------------------- | :------------------------------------------------ |
|  [01]   | Screenshots, generated images, UI states, visual diffs, diagrams  | Native multimodal judgment over `--add-dir` files |
|  [02]   | Critique or red-team stage wanting an independent second reviewer | Read-only findings from a different model lineage |
|  [03]   | Image generation, mockup and diagram iteration                    | Native `generate_image` rendering (Nano Banana)   |
|  [04]   | Competing designs, ambiguous tradeoffs, long-context synthesis    | Independent perspective outside the main context  |
|  [05]   | Vague requirements needing constraints and edge cases             | Ambiguity reduction as a separate pass            |
|  [06]   | Counterexamples, risk inventories, blind spots on gathered facts  | Adversarial second reading                        |
|  [07]   | Redacted log or dataset distillation in a scratch directory       | Pattern finding without polluting main context    |
|  [08]   | Explicit requests for Gemini, Antigravity, or Google Ultra        | User-directed routing                             |

## [03]-[MODEL_POLICY]

The wrapper pins the strongest Gemini reasoning model at its highest tier; that pin is the carrier of a standing operator policy, never a tunable preference. A weaker or faster tier is admitted only where a specific use case proves zero signal sacrifice, and the burden of that proof sits on the routing decision, never on the default. Agents never choose models in ordinary use; `models` lists the live catalog for capability accounting and skill maintenance, and `AGY_MODEL` re-pins only when the policy owner rules a proven exception.

## [04]-[INVOCATION]

Run from this skill directory:

```sh copy-safe
uv run scripts/agy.py models
uv run scripts/agy.py prompt "Compare these two approaches and return the top 3 tradeoffs." --timeout 5m
uv run scripts/agy.py prompt "Assess the screenshot at /abs/path/shot.png and return concrete UI defects." --add-dir /abs/path --timeout 10m
```

The multimodal contract takes both halves: `--add-dir` grants the bounded directory, and the prompt names each file by ABSOLUTE path — a granted directory with a bare filename in the prompt resolves nothing. `--add-dir` grants only directories that answer the prompt, and the only writes a wrapper prompt ever requests are generation artifacts under a scratch root.

`--log-file` routes the CLI log to an explicit path; a sandboxed or scratch-rooted environment passes a writable scratch path there instead of relying on the default log location. `AGY_BIN` overrides the binary path (default `agy`), `AGY_MODEL` overrides the pinned model, `AGY_LOG_FILE` sets the default log path, and `AGY_PRINT_TIMEOUT` overrides the default `5m` timeout.

## [05]-[PROMPT_CONTRACT]

- State the task, the relevant context, and the exact output shape in one self-contained prompt; Antigravity sees nothing of the current conversation beyond what the prompt carries.
- Carry the constraints that bind the answer: audience, files already inspected, limits, and facts not to assume.
- Ask for ranked options, deltas, typed findings, or a direct answer; open-ended commentary is never the request.

## [06]-[REVIEW_LANE]

The review lane is the bounded critique/red-team second perspective: freeze the evidence, invert the objective, demand falsifiable findings. It inverts the every-agent-writes law at exactly this boundary — the Gemini reviewer inspects and returns typed findings, and a Claude writer adjudicates each finding against source before applying the fix; the repair rail never crosses into the lane.

- [EVIDENCE]: the subject arrives frozen — exact files under `--add-dir`, the invariants under test, executed check output, and known constraints — never a conversation transcript or a producer's self-justification.
- [OBJECTIVE]: the prompt directs disproof — violated invariants, omitted consumers, false assumptions, failure paths, visual-contract breaks — with the work held naive until it survives the attack; a clean verdict is earned by an attack that finds nothing.
- [FINDINGS]: each finding carries `{severity, invariant, evidence, failure_path, minimal_fix}`; praise, style preference, and ungrounded speculation are rejected shapes the prompt names explicitly.
- [ADJUDICATION]: the consuming Claude agent re-derives each finding from disk, fixes true positives at the root, and refutes false positives with source — reconciliation by evidence, never by vote.

```sh copy-safe
uv run scripts/agy.py prompt "ROLE: read-only adversarial reviewer. SUBJECT: /abs/path/target. INVARIANT UNDER TEST: <invariant>. AUTHORITY: inspect only; propose, never edit. OUTPUT: a JSON array of findings only, each {severity, invariant, evidence, failure_path, minimal_fix}; reject praise, style preferences, and ungrounded speculation. Return [] only if a real attack finds nothing." --add-dir /abs/path --timeout 5m
```

## [07]-[GENERATION]

Image generation is the default agent's built-in `generate_image` tool, fired from inside an ordinary print-mode prompt — no CLI flag, subcommand, plugin, or `models` row invokes it. The prompt carries three obligations: name the tool and forbid code-drawing (an unnamed request lets the agent fall back to scripting Pillow when the render fails), state the visual spec, and give an absolute save path under a scratch root the caller creates. The render also persists as `<image_name>_<epoch-ms>.jpg` under `~/.gemini/antigravity-cli/brain/<conversation-id>/`.

```sh copy-safe
uv run scripts/agy.py prompt "Use your generate_image tool (never code-drawing) to generate: <visual spec>, aspect ratio 16:9. Save to /abs/scratch/name.png." --add-dir /abs/scratch --timeout 5m
```

Everything routes through prompt prose; the agent maps it onto the tool's parameters: `Prompt`, `AspectRatio` (`1:1` default at 1024x1024, plus `2:3`, `3:2`, `3:4`, `4:3`, `9:16`, `16:9` — `16:9` renders 1376x768), `ImagePaths` (up to 3 absolute paths to edit, combine, or reference — the edit modality: name the source image by absolute path and state the change), and `ImageName`. No tier selector exists at any surface — not in the tool schema, the CLI flags, or the model catalog; the backend serves Nano Banana Pro where the account has access and the original Nano Banana otherwise, and `--model` picks only the reasoning agent driving the tool.

Every render passes two gates before use. `magick identify` proves a real raster at the expected dimensions — the payload is JPEG regardless of the requested extension unless the agent converts, so the filename is never format proof — and a multimodal read-back through this wrapper describes the artifact against the visual contract. The failure signature is a file around 1KB: the backend returned no image (`CORTEX_STEP_TYPE_GENERATE_IMAGE: no image generated in response` in the `--log-file`) and the agent code-drew a placeholder; the never-code-drawing clause plus the size gate catches it, and one re-run resolves a transient backend miss.

Generated mockups and diagrams are inputs to the realizing skill, never deliverables: agy drafts the spec, renders, and read-back-critiques, then html-studio realizes the page and mermaid-diagramming realizes the fence. The strongest pattern is a closed loop — visual contract, render, read-back critique against the contract, targeted correction — never a single "make it pretty" round.

## [08]-[CODEX_ALIGNMENT]

A codex session reaches agy only under `-s danger-full-access`: the Seatbelt sandbox at `read-only` and `workspace-write` kills the `agy` process silently — exit 1, empty streams, no diagnostic. When the operator has not authorized full access for that codex run, the Gemini leg belongs to the Claude side of the dispatch, never to a bent codex workaround.

## [09]-[REFUSAL]

- [SECRETS]: OAuth codes, tokens, credential files, and unredacted sensitive logs never enter a prompt.
- [AUTHORITY]: Facts owned by local source, official docs, configured MCPs, or repository commands come from those owners, never from Antigravity recall.
- [ROUTINE]: Edits, formatting, git operations, package upgrades, and checks the local toolchain owns stay local.
- [SCOPE]: The wrapper exposes `prompt` and `models` alone; agent selection, background task management, and shell-login subcommands stay outside it.

## [10]-[RECEIPT]

```json generated
{"op":"prompt","output":"..."}
{"op":"prompt","fault":"auth_required","detail":"..."}
```

Faults are `binary_not_found`, `auth_required`, `quota_exceeded`, or `process_error`. `auth_required` resolves through interactive `agy` in a real TTY with Google OAuth as `b.samiee93@gmail.com`.

## [11]-[RAW_CLI]

Interactive `agy` in a real TTY owns ongoing conversations, workspace tool permissions, resume, plugin management, and sandboxed project work; `agy --help` is the flag and subcommand contract. The `gsd-*` personas are interactive-runtime composition only: they hang under plain print mode and emit process narration rather than bounded answers under `--mode plan`, so a bounded one-shot review or judgment call always runs the default agent with a strong prompt, never a gsd persona. GSD's artifact pipeline — mapper, researcher, planner, checker, executor, verifier — composes inside a live Antigravity session where each role consumes only the prior role's artifact.
