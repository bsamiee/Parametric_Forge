---
name: agy
description: >-
    Bounded one-shot Gemini sub-calls through the Antigravity CLI (`agy`): multimodal judgment
    over screenshots, generated images, UI states, and diagrams, image-prompt drafting, broad
    synthesis across competing designs, ambiguity reduction into crisp constraints, alternate
    approaches and counterexample hunts, and redacted log or dataset distillation. Use when a
    task gains from an external second model or names Gemini, Antigravity, Google Ultra, or
    Nano Banana image judgment. gpt-5.5 offload belongs to the codex skill; delegation across
    Claude's own surfaces belongs to agent-dispatch.
---

# [AGY]

Antigravity is an external Gemini call admitted only where it adds capability beyond the local toolchain. The wrapper is print-only: one bounded prompt in, one JSON receipt out, the default profile pinned to the strongest Gemini reasoning tier. Antigravity output is advisory until local source, official docs, MCP output, or user intent confirms it.

## [01]-[ROUTING]

[SCRIPTS]:

- [01]-[RUNNER](scripts/agy.py): the print-only Antigravity wrapper — one bounded prompt in, one JSON receipt out, pinned to the strongest Gemini reasoning tier.

## [02]-[CAPABILITY]

| [INDEX] | [TRIGGER]                                                        | [WHY_GEMINI]                                     |
| :-----: | :--------------------------------------------------------------- | :----------------------------------------------- |
|  [01]   | Screenshots, generated images, UI states, visual diffs, diagrams | Native multimodal judgment                       |
|  [02]   | Image-prompt drafting and critique                               | Image-generation domain knowledge                |
|  [03]   | Competing designs, ambiguous tradeoffs, long-context synthesis   | Independent perspective outside the main context |
|  [04]   | Vague requirements needing constraints and edge cases            | Ambiguity reduction as a separate pass           |
|  [05]   | Counterexamples, risk inventories, blind spots on gathered facts | Adversarial second reading                       |
|  [06]   | Redacted log or dataset distillation in a scratch directory      | Pattern finding without polluting main context   |
|  [07]   | Explicit requests for Gemini, Antigravity, or Google Ultra       | User-directed routing                            |

## [03]-[REFUSAL]

- [SECRETS]: OAuth codes, tokens, credential files, and unredacted sensitive logs never enter a prompt.
- [AUTHORITY]: Facts owned by local source, official docs, configured MCPs, or repository commands come from those owners, never from Antigravity recall.
- [ROUTINE]: Edits, formatting, git operations, package upgrades, and checks the local toolchain owns stay local.
- [SCOPE]: The wrapper exposes `prompt` and `models` alone; background task management and shell-login subcommands stay outside it.

## [04]-[INVOCATION]

Run from this skill directory:

```sh copy-safe
uv run scripts/agy.py models
uv run scripts/agy.py prompt "Compare these two approaches and return the top 3 tradeoffs." --timeout 5m
uv run scripts/agy.py prompt "Assess this screenshot and suggest concrete UI changes." --add-dir "$PWD" --timeout 10m
```

The wrapper pins `Gemini 3.1 Pro (High)` — the strongest reasoning tier in the catalog, which spans Gemini 3.5 Flash and 3.1 Pro effort tiers beside hosted Claude and GPT-OSS entries. Agents never choose models in ordinary use; `models` exists for capability accounting and skill maintenance. `--add-dir` grants only bounded directories that answer the prompt, and the wrapper never asks `agy` to edit files.

`AGY_BIN` overrides the binary path (default `agy`), `AGY_MODEL` overrides the pinned model, and `AGY_PRINT_TIMEOUT` overrides the default `5m` timeout.

## [05]-[PROMPT_CONTRACT]

- State the task, the relevant context, and the exact output shape in one self-contained prompt; Antigravity sees nothing of the current conversation beyond what the prompt carries.
- Carry the constraints that bind the answer: audience, files already inspected, limits, and facts not to assume.
- Ask for ranked options, deltas, or a direct answer; open-ended commentary is never the request.

## [06]-[RECEIPT]

```json generated
{"op":"prompt","output":"..."}
{"op":"prompt","fault":"auth_required","detail":"..."}
```

Faults are `binary_not_found`, `auth_required`, `quota_exceeded`, or `process_error`. `auth_required` resolves through interactive `agy` in a real TTY with Google OAuth as `b.samiee93@gmail.com`.

## [07]-[RAW_CLI]

Interactive `agy` in a real TTY owns ongoing conversations, workspace tool permissions, resume, plugin management, and sandboxed project work. The direct surface carries `-p/--print`, `-i/--prompt-interactive`, `-c/--continue`, `--conversation`, `--mode` (`accept-edits`, `plan`), `--sandbox`, `--project`/`--new-project`, and the `models`, `plugin`, `install`, `update`, and `changelog` subcommands. `--dangerously-skip-permissions` binds only on an explicit user request for that exact mode.
