# Parametric Forge • Execution Standards

## Model Dispatch

Rankings, higher = better. Cost reflects what I actually pay (OpenAI is near-free for me due to a deal), not list price. Intelligence is how hard a problem you can hand the model unsupervised. Taste covers UI/UX, code quality, API design, and copy.

| [INDEX] | [MODEL]  | [COST] | [INTELLIGENCE] | [TASTE] |
| :-----: | :------- | :----: | :------------: | :-----: |
|  [00]   | gpt-5.5  |   9    |       8        |    5    |
|  [00]   | sonnet-5 |   5    |       4        |    6    |
|  [00]   | opus-4.8 |   4    |       7        |    7    |
|  [00]   | fable-5  |   2    |       9        |    9    |

How to apply:
- These are defaults, not limits. You have standing permission to override them: if a cheaper model's output doesn't meet the bar, rerun or redo the work with a smarter model without asking. Judge the output, not the price tag. Escalating costs less than shipping mediocre work.
- Don't let cost prevent you from using the right model for the job. Instead, take advantage of cheaper options to get more information and try things before moving the work to a more expensive option.
- Bulk/mechanical work (clear-spec implementation, data analysis, migrations): gpt-5.5 - it's effectively free.
- Heavy exploration, investigation, and research legs: dispatch to gpt-5.5 (`codex exec`, read-only) before spawning Claude subagents - the transcript stays out of context and the usage is free.
- Anything user-facing (UI, copy, API design) needs taste ≥ 7.
- Reviews of plans/implementations: fable-5 or opus-4.8, optionally gpt-5.5 as an extra independent perspective.
- Mechanics: gpt-5.5 is only reachable through the Codex CLI - `codex exec` / `codex review` (my ~/.codex/config.toml defaults to gpt-5.5 at high reasoning).
- Load the codex skill `.claude/skills/codex/SKILL.md` whenever dispatching work to codex - delegation triggers, invocation mechanics, sandboxing, effort tiers, sessions, and review modes live there.
- Reasoning effort defaults to high; escalate a single run to xhigh with `codex exec --profile xhigh` (or `-c model_reasoning_effort="xhigh"`) for the hardest research, review, and design legs - multi-minute latency, reserve for depth over throughput.
- Claude models (sonnet-5, opus-4.8, fable-5) run via the Agent/Workflow model parameter.
- [NEVER] use Haiku.

Using gpt-5.5 inside workflows and subagents (the model parameter only takes Claude models, so use a wrapper):
- Spawn a thin Claude wrapper agent with `model: 'sonnet', effort: 'low'` whose prompt instructs it to write a self-contained codex prompt, run `codex exec` via Bash, and return the report (use `schema` on the wrapper to get structured output back).
- Always label these agents with a `gpt-5.5:` prefix, e.g. `{label: 'gpt-5.5:review-auth'}` - the workflow UI shows the wrapper's Claude model, so the label is the only indication the real worker is gpt-5.5.
- Codex runs can exceed Bash's 10-minute timeout: pass an explicit timeout, or run in the background and poll for the report file. Inside workflows wrappers are LAUNCH-ONLY - a subagent has no legal wait (foreground sleep is blocked, background tasks never notify it, idle no-ops trip no-progress enforcement and file a false failure while codex runs on): the wrapper returns a launch receipt in seconds, the orchestrator owns time (`await new Promise(r => setTimeout(r, ms))` between harvest rounds), and a short-lived harvester agent per round promotes finished reports mechanically from disk - never relaunch a live run.
- `codex exec -o <file>` writes the final message to a file (the report artifact to poll in background runs); `--output-schema <schema.json>` constrains the final message to a JSON Schema when the wrapper must return typed results.
- Workflow token budgets only count Claude tokens; codex work is free and invisible to `budget.spent()`.

## Code Quality

### Nix Requirements

**ALWAYS**
- Use latest nixpkgs-unstable
- Pure functions where possible

**NEVER**
- Pin old nixpkgs versions
- Create wrapper modules for single options
- Mix system and home-manager scopes
- Use `with pkgs;` at file level (scope pollution)
- Create files "for later" or "just in case"

### Code Density

**Target**: 300 LOC max per file. If approaching limit:
- Split by concern if truly distinct
- EXCEPTION: Some files are justified to be larger than LOC limit (must be justified - long list, single concern files)

**Patterns**:
```nix
# YES: Dense, multi-capable
mkService = { name, exec, env ? {}, after ? [], ... }@args:
  let
    baseService = { inherit exec env; wantedBy = ["default.target"]; };
    withDeps = if after != [] then baseService // { inherit after; } else baseService;
  in withDeps // (removeAttrs args ["name" "exec" "env" "after"]);

# NO: Function spam
mkSimpleService = name: exec: { inherit exec; };
mkServiceWithEnv = name: exec: env: { inherit exec env; };
mkServiceWithDeps = name: exec: after: { inherit exec after; };
```

### File Structure

```nix
# Title         : [filename]
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /[relative-path]
# ----------------------------------------------------------------------------
# [One-line description if complex]

{ lib, pkgs, myLib, context, ... }:

let
  # Minimal let bindings (prefer inline)
  critical = computeExpensive args;
in
{
  # Direct implementation
}
```

## Execution Philosophy

### YAGNI + KISS

**Before adding ANY code, ask**:
1. Does nixpkgs have a solution?
2. Can I extend existing pattern?
3. Is this needed NOW (not "might be useful")?

If any "no" → don't add it.

### Refactoring > Rewriting

**When modifying**:
- Read entire file first
- Understand existing patterns
- Surgically modify in-place
- Never create "improved" versions

**Example**:
```nix
# File exists with 10 functions
# Need: Add SSL support to one function

# YES: Extend existing function
someFn = args:
  let base = originalLogic args;
  in base // lib.optionalAttrs (args ? ssl) { inherit (args) ssl; };

# NO: Create new function
someFnWithSSL = args: ...  # Function spam
```

## Language-Specific Standards


### Shell Scripts
- IMPORTANT: CRITICAL: Always add the .sh extension to bash scripts
- `set -euo pipefail` mandatory
- ShellCheck must pass
- Prefer `writeShellApplication` for shell CLIs with declared runtime tools, ShellCheck integration, or stable Home Manager-installed binaries. Use `writeShellScriptBin` only for tiny scripts that do not need a runtime closure.
- Package shell CLIs with `writeShellApplication` when they need declared runtime tools, ShellCheck integration, or a stable Home Manager-installed binary.

### Local Provisioning
- `forge-provision` is the canonical Forge-owned local provisioning and debugging command. The overlay package owns the implementation; Home Manager only installs that derivation. Use the packaged executable or `nix run .#forge-provision -- <command>`, never `bash overlays/forge-provision/forge-provision.sh`. Rasm campaign work enters through `uv run python -m tools.assay provision <verb>`; direct `forge-provision`, `psql`, `paths`, `prune`, `self-test`, Docker/Compose, and diagnostic JSON are Forge-level debugging surfaces.
- Clean renames are preferred over compatibility shims. Do not keep retired provisioning command names as aliases, wrappers, fallbacks, or silent environment-variable compatibility.
- Provisioning commands are agent-first and noninteractive: no host `sudo`, no keychain prompt, no DB password prompt, and no Docker credential-helper dependency for public images.
- Read-only provisioning commands avoid durable repo writes unless the command explicitly documents state creation.
- Home Manager DB tooling is client/tooling-owned: `psql`, `pg_dump`, `pg_restore`, `pg_isready`, optional `pg_config`, SQLFluff/Postgres LSP, DuckDB, SQLite/SQLean, SpatiaLite, and sqlite-vec. PostgreSQL server extensions stay Docker-owned by `forge-provision`; image-specific shared-preload requirements may include pg_cron, but `pg_cron` extension creation stays row-gated and opt-in.
- Forge provisioning JSON is schema v3 only. Do not add schema-v1/v2 emitters or compatibility adapters. Doctor and extension JSON expose sanitized runtime booleans/kinds and catalog metadata only; raw sockets, Docker config paths, helper names, logs, DSNs, token material, mount paths, and host absolute paths stay out of agent-facing JSON.

### Python (Secondary)
- Python 3.15+ only (never older)
- `uv` for package management
- `ruff` for all linting/formatting
- `ty` for type checking
- `anyio` + `aiofiles` for async

### Rust (Tertiary)
- Latest stable toolchain
- `cargo-deny` for security
- Workspace-first organization
- `#![deny(warnings)]` always


## Module Patterns

### Options (sparingly)
```nix
# Only if TRULY configurable
options.myFeature = {
  enable = mkEnableOption "feature";
  # Minimal options, maximum inference
};

# Prefer direct config over options
config = {
  # Direct implementation
};
```

### Imports
```nix
# YES: Specific imports
{ lib, pkgs, myLib, context, ... }:

# NO: Kitchen sink
{ self, config, lib, pkgs, inputs, ... }:
```

## Anti-Patterns to Avoid

**Function Spam**: Multiple functions doing similar things
**Wrapper Modules**: Modules that just wrap other modules
**Anticipatory Code**: "Might need this later"
**Over-Abstraction**: More abstraction than implementation
**Dead Code**: Commented out or unreachable code
**Version Pinning**: Using old versions without critical reason
**Manual Checks**: Hardcoded platform/user detection

## Commit Standards

**Message Format**:
```
[scope]: action

- Specific change 1
- Specific change 2
```

**Scopes**: `nix`, `darwin`, `home`, `lib`, `flake`
**Actions**: `add`, `fix`, `refactor`, `remove` (never "update" or "improve")

## Performance

**Build Time**:
- Prefer `imports` over inline modules
- Use `mkIf` for conditional heavy evaluations
- Cache derivations in `let` bindings

**Runtime**:
- Scripts: Parallelize with `&` and `wait`
- Services: Lazy activation where possible
- File ops: Batch with `symlinkJoin`

## Remember

IMPORTANT: CRITICAL:This is Nix configuration, not application code. Every line either:
1. Configures the system/user environment
2. Deploys files/packages
3. Enables services

If it doesn't do one of these, it doesn't belong here.
