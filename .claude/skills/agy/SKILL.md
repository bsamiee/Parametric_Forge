---
name: agy
user-invocable: true
description: Use Antigravity CLI (`agy`) for bounded Gemini/Google Ultra sub-calls: visual and multimodal reasoning, image prompt work, broad synthesis, ambiguity reduction, alternate approaches, and explicit Gemini or Antigravity requests.
---

# Antigravity (`agy`)

Use Antigravity as an external Gemini call when it adds capability to the main agent's local tools. The wrapper is print-only: it asks `agy` for one bounded answer using the default strongest Gemini profile and returns one JSON object.

## Good Fits

- Multimodal reasoning over screenshots, generated images, UI states, diagrams, visual diffs, or image-prompt drafts.
- Broad synthesis across competing ideas, ambiguous tradeoffs, product direction, research notes, or long-context design material.
- Ambiguity reduction: turn vague requirements into crisp constraints, edge cases, and clarifying questions.
- Alternative approaches, counterexamples, risk inventories, and blind spots when local source evidence is already gathered.
- Redacted data or log distillation in a scratch directory when pattern finding benefits from a separate model pass.
- Isolated proof-of-concept ideation before the main agent writes production code.
- Explicit user requests for Gemini, Antigravity, Google Ultra, Nano Banana-style image judgment, or a second external model.

## Avoid

- Secrets, OAuth codes, private tokens, raw credential files, or unredacted sensitive logs.
- Authoritative facts that should come from local source, official docs, configured MCPs, or repository-owned commands.
- Routine edits, formatting, git operations, package upgrades, or checks that local tooling already owns.
- Background task management or shell-login subcommands; this wrapper supports only `prompt` and `models`.

## Commands

Run from this skill directory:

```sh
uv run scripts/agy.py models
uv run scripts/agy.py prompt "Compare these two approaches and return the top 3 tradeoffs." --timeout 5m
uv run scripts/agy.py prompt "Assess this screenshot and suggest concrete UI changes." --add-dir "$PWD" --timeout 10m
```

Normal prompt calls use `Gemini 3.1 Pro (High)` through the wrapper. Agents do not choose models in ordinary use; `models` is for capability accounting, diagnostics, and maintaining this skill. Use `--add-dir` only for bounded directories that help answer the prompt. The wrapper never asks `agy` to edit files.

For native Antigravity sessions, use `agy` directly in a real TTY. Direct CLI surfaces include `--prompt-interactive`, `--continue`, `--conversation`, `--sandbox`, `plugin`, `update`, and `changelog`; the wrapper remains one-shot and print-only.

## Raw CLI Escalation

Use the wrapper for one-shot answers. Use raw interactive `agy` in a real TTY when the task needs an ongoing conversation, workspace tool permissions, conversation resume, plugin management, or sandboxed project work. Do not bypass tool permissions unless the user explicitly asks for that exact mode.

## Prompt Shape

- State the task, the relevant context, and the exact output shape.
- Include constraints that matter: target audience, files already inspected, limits, and what not to assume.
- Ask for ranked options, deltas, concrete recommendations, or a direct answer instead of open-ended commentary.
- Keep the prompt self-contained; do not assume Antigravity can see the current conversation unless you pass the context explicitly.

## Result Handling

Success:

```json
{"op":"prompt","output":"..."}
```

Failure:

```json
{"op":"prompt","fault":"auth_required","detail":"..."}
```

Faults are `binary_not_found`, `auth_required`, `quota_exceeded`, or `process_error`. Treat output as advisory until local source, official docs, MCP output, or user intent confirms it.

`AGY_BIN` overrides the binary path and defaults to `agy`. `AGY_MODEL` overrides the hidden default model and defaults to `Gemini 3.1 Pro (High)`. `AGY_PRINT_TIMEOUT` overrides the default timeout and defaults to `5m`.

Current Antigravity sign-in starts from interactive `agy` in a real TTY. Complete Google OAuth as `b.samiee93@gmail.com`.
