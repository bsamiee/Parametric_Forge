# [SECURITY]

A hook is a guardrail, not the security boundary: it reasons about a hostile input and an untrusted handler, and the permission system owns the hard allow and deny. This page owns the security model — the threat surface, where enforcement truly binds, the disposition each role takes on failure, and the trust an author extends to a hook they did not write. Tactics that implement it live at their decision points; this page routes to them and never re-teaches them.

## [01]-[THREAT_SURFACE]

An author defends a fixed set of attack shapes, each landing at one event and caught by one owned tactic.

| [INDEX] | [ATTACK]            | [LANDS_AT]                                   | [CAUGHT_BY]                                                    |
| :-----: | :------------------ | :------------------------------------------- | :------------------------------------------------------------- |
|  [01]   | Command obfuscation | `PreToolUse` Bash argument                   | `_leaves` de-obfuscation and quote-aware split in the gate     |
|  [02]   | Destructive intent  | `PreToolUse` Bash argument                   | per-`argv` semantic dispatch — `rm` path tiers, `git` subtable |
|  [03]   | Path escape         | `PreToolUse` `Edit`/`Write`                  | the shared canonicalizer plus `is_relative_to` sandbox check   |
|  [04]   | Secret exfiltration | outbound `PreToolUse`, inbound `PostToolUse` | the JSON scalpel and the `updatedToolOutput` redaction lane    |
|  [05]   | Context injection   | `additionalContext` on any injecting event   | factual-statement phrasing, never an out-of-band imperative    |
|  [06]   | Untrusted hook      | the hook file itself                         | the red-team harness audit before the hook is trusted          |

`_leaves` decomposition of [01] de-obfuscates `$IFS`, treats an unquoted newline as `;`, strips a leading `NAME=value` prefix and wrappers, and descends command substitutions, backticks, and clustered-flag one-liners before any classify; [02]'s dispatch denies an opaque interpreter one-liner fail-closed, never through a keyword denylist.

Tactics [01]-[03] are the `pretooluse-gate` template and the command-decomposition recipe; [04] is the value-rewrite recipe and the `posttooluse-format` redaction lane; [05] is the integration reference's placement law; [06] is the verification reference's red-team harness.

## [02]-[ENFORCEMENT_LOCUS]

Exit 2 with a stderr reason on a `command` hook is the one hard block identical on both providers — real policy rides it and nothing else. An `http`, `mcp_tool`, or `prompt` handler degrades to a non-blocking error on a disconnect, timeout, or model refusal, so a security decision routed through one silently fails open; those handlers observe and advise, never enforce. A gate's matcher stays narrow — a specific `tool_name`, never `.*` — a hot-path hook on every tool taxes every turn, and an auto-approval `.*` auto-clears file writes and shell commands the author never inspected.

## [03]-[DISPOSITION_BY_ROLE]

Failure disposition is fixed at the decode seam by the hook's role, never left to a crash: a gate blocks on a malformed payload, an unparseable command, or a raised exception; an observer or telemetry transmitter exits 0 on the same. A hook that raises exits a non-2 code, which is non-blocking, so a security check without an explicit fail-closed seam permits the very action it guards — the gate template's `main` wraps the decision in one denying `except`. A guardrail is defense-in-depth: paired with a permission deny rule and a startup preflight, a single miss is not a breach.

## [04]-[SUPPLY_CHAIN]

A hook executes with the agent's authority, so a copied or shared one is trusted only after the red-team harness audits it against its paired fixture corpus before wiring. A remote rulebook is pinned by content digest — a `sha256:` per entry, structurally validated and fail-closed on mismatch — so a shared org policy cannot mutate under the hook. Codex records trust against the hook's SHA and skips a new or changed hook until trusted through `/hooks`; `allowManagedHooksOnly` and managed policy settings bound which hooks load, and the fixture audit earns a foreign hook its place.
