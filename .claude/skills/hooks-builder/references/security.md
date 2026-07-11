# [SECURITY]

A hook is a guardrail, not the security boundary: it reasons about a hostile input and an untrusted handler, and the permission system owns the hard allow and deny. This page owns the security model — the threat surface, where enforcement truly binds, the disposition each role takes on failure, and the trust an author extends to a hook they did not write. The tactics that implement it live at their decision points; this page routes to them and never re-teaches them.

## [01]-[THREAT_SURFACE]

An author defends a fixed set of attack shapes, each landing at one event and caught by one owned tactic.

| [INDEX] | [ATTACK]            | [LANDS_AT]                                   | [CAUGHT_BY]                                                    |
| :-----: | :------------------ | :------------------------------------------- | :------------------------------------------------------------- |
|  [01]   | Command obfuscation | `PreToolUse` Bash argument                   | `_leaves` de-obfuscation and quote-aware split in the gate     |
|  [02]   | Destructive intent  | `PreToolUse` Bash argument                   | per-`argv` semantic dispatch — `rm` path tiers, `git` subtable |
|  [03]   | Path escape         | `PreToolUse` `Edit`/`Write`                  | the shared canonicalizer plus `is_relative_to` sandbox check   |
|  [04]   | Secret exfiltration | outbound `PreToolUse`, inbound `PostToolUse` | the JSON scalpel and the block-and-summarize redaction lane    |
|  [05]   | Context injection   | `additionalContext` on any injecting event   | factual-statement phrasing, never an out-of-band imperative    |
|  [06]   | Untrusted hook      | the hook file itself                         | the red-team harness audit before the hook is trusted          |

The `_leaves` decomposition of [01] de-obfuscates `$IFS`, treats an unquoted newline as `;`, strips a leading `NAME=value` env-prefix and every wrapper, and descends command substitutions, backticks, and clustered-flag shell/interpreter one-liners before any classify — and [02]'s dispatch denies an opaque inline interpreter one-liner fail-closed rather than admitting it through a keyword denylist. Tactics [01]-[03] are the `pretooluse-gate` template and the command-normalization fragment; [04] is the JSON-scalpel fragment and the `posttooluse-format` redaction lane; [05] is the context-injection placement law in the integration reference; [06] is the red-team harness in the verification reference.

## [02]-[ENFORCEMENT_LOCUS]

Exit 2 with a stderr reason on a `command` hook is the one hard block that behaves identically on both providers — real policy rides it and nothing else. An `http`, `mcp_tool`, or `prompt` handler degrades to a non-blocking error on a disconnect, a timeout, or a model refusal, so a security decision routed through one silently fails open; those handlers observe and advise, never enforce. The gate's matcher stays narrow — a specific `tool_name`, never `.*` — because a hot-path hook on every tool taxes every turn, and an auto-approval matcher stays narrow because `.*` there auto-clears file writes and shell commands the author never inspected.

## [03]-[DISPOSITION_BY_ROLE]

Failure disposition is fixed at the decode seam by the hook's role, never left to a crash: a gate blocks on a malformed payload, an unparseable command, or a raised exception, and an observer or a telemetry transmitter exits 0 on the same. A hook that raises exits a non-2 code, which is non-blocking, so a security check without an explicit fail-closed seam permits the very action it guards. The gate template's `main` wraps the whole decision in one `except` that denies; the transmitter swallows every exception and exits 0. These dispositions are opposite and chosen per hook, and the guardrail is defense-in-depth: it pairs with a permission deny rule and a startup preflight, so a single guardrail miss is not a breach.

## [04]-[SUPPLY_CHAIN]

A hook executes with the agent's authority, so a copied or shared one is trusted only after it is proven. The red-team harness subprocess-audits any hook against a paired fixture corpus before it is wired, reporting a dangerous fixture that passes and a benign one that blocks as the same defect. A remote rulebook is pinned by content digest — a `sha256:` per entry, structurally validated and fail-closed on mismatch — so a shared org policy cannot mutate under the hook. Codex records trust against the hook's SHA and skips a new or changed hook until it is trusted through `/hooks`; `allowManagedHooksOnly` and managed policy settings bound which hooks load at all, and the fixture audit is what earns a foreign hook its place in that set.
