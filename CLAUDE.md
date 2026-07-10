# Parametric Forge Execution Standards

## [01]-[MODEL_DISPATCH]

Rankings, higher is better. Cost reflects actual operator spend (OpenAI is near-free under a standing deal), not list price. Intelligence is how hard a problem the model absorbs unsupervised. Taste covers UI/UX, code quality, API design, and copy.

| [INDEX] | [MODEL]  | [COST] | [INTELLIGENCE] | [TASTE] |
| :-----: | :------- | :----: | :------------: | :-----: |
|  [01]   | gpt-5.5  |   9    |       8        |    5    |
|  [02]   | sonnet-5 |   5    |       4        |    6    |
|  [03]   | opus-4.8 |   4    |       7        |    7    |
|  [04]   | fable-5  |   2    |       9        |    9    |

- Defaults, not limits — standing permission to override: when a cheaper model's output misses the bar, rerun the leg with a smarter model without asking. Judge the output, never the price tag; escalation costs less than shipping mediocre work.
- Cheap models buy information: probe, gather, and iterate on gpt-5.5 before moving a leg to an expensive model.
- Bulk/mechanical work (clear-spec implementation, data analysis, migrations) and heavy exploration/research legs dispatch to gpt-5.5 first (`codex exec`, read-only) — the transcript stays out of context and the usage is free.
- User-facing surfaces (UI, copy, API design) require taste ≥ 7. Plan and implementation reviews: fable-5 or opus-4.8, optionally gpt-5.5 as an independent extra perspective.
- gpt-5.5 is reachable only through the Codex CLI (`codex exec` / `codex review`); `~/.codex/config.toml` defaults it at medium reasoning — escalate a single run with `-c model_reasoning_effort="high"`, or `--profile xhigh` for the hardest research, review, and design legs. The `codex` skill owns delegation triggers, invocation mechanics, sandboxing, effort tiers, sessions, and review modes.
- Claude models (sonnet-5, opus-4.8, fable-5) run through the Agent/Workflow `model` parameter at effort `high` — never `xhigh`/`max` on Claude agents. [NEVER]: Haiku.
- Inside workflows gpt-5.5 rides a thin sonnet wrapper labeled with a `gpt-5.5:` prefix; wrappers are launch-only — the orchestrator owns waiting and harvests report files from disk, never the wrapper. The `codex` and `workflow-creator` skills own the full wrapper contract; workflow token budgets count only Claude tokens, so codex work is free and invisible to `budget.spent()`.

## [02]-[ESTATE_LAW]

The Nix estate is machine configuration, not application code: every Nix line configures the system/user environment, deploys files/packages, or activates services — a line doing none of these does not belong here. One module graph serves every host; the OS branch keys on the static host context (`hosts/context.nix`), never on `pkgs`. `services/` owns live service state as Pulumi rows, `docs/` owns durable law, and `overlays/` admits an upstream package only with a real consumer now.

- System scope (`modules/darwin/`, `modules/nixos/`) and home scope (`modules/home/`) never mix in one module; nothing Darwin-owned — Homebrew, launchd, macOS defaults — generalizes into `modules/nixos/`.
- Latest nixpkgs-unstable always; a pin exists only with a named incompatibility and dies when compatibility lands.
- `forge-redeploy` is the only activation path, and switches happen freely — deploy early to catch runtime-only bugs, never batch changes behind ceremony. The static gate is a pair — the darwin system build AND the maghz toplevel drv eval (`nix flake check` proves neither toplevel); `forge-accept` proves the switch end to end.
- Recurring work is a declared launchd agent under the `com.parametric-forge.<name>` grammar, beside the surface it serves; ad-hoc background processes and manual `launchctl` state are defects.
- Standing remote connections (mounts, tunnels, sessions) follow the doctrine's `[REMOTE_TRANSPORT]` card: openssh keepalive custody, probed liveness with caused receipts, detach-before-reap drains.
- [NEVER]: kill live terminal sessions — no `zellij kill-session`/`kill-all-sessions`, no WezTerm restarts. Fix in repo, redeploy; the operator restarts on their own schedule.
- `.claude/skills/` here are the estate masters for harness skills and `.claude/hooks/setup-env.sh` is the canonical SessionStart hook; edits land in the master and propagate to mirrors (`~/.codex/skills/`, sibling repos) by copy — never edit a mirror, never build sync tooling.

## [03]-[NIX_CODE_LAW]

Density target: ~300 LOC per file, measured with `loc`, never bytes. Approaching the limit means collapsing polymorphically inside the file — merged functions, dispatch tables, parameterized rows — splitting only when concerns are truly distinct; justified single-concern files (long lists, one owner) may exceed it.

Before adding any code: nixpkgs already solves it? the existing pattern extends? needed now, not "later"? Any "no" means the code does not land. Vocabulary row tables use positional constructors or delimited tuples — the formatter explodes multi-key attrset rows ~2.4x, and density that dies at the fmt lane never lands. Modification is surgical and in-place — read the entire file, understand its patterns, extend the existing surface; a parallel "improved" version is a defect.

```nix accepted
# YES: dense, multi-capable — one owner absorbs every modality
mkService = { name, exec, env ? {}, after ? [], ... }@args:
  let
    baseService = { inherit exec env; wantedBy = ["default.target"]; };
    withDeps = if after != [] then baseService // { inherit after; } else baseService;
  in withDeps // (removeAttrs args ["name" "exec" "env" "after"]);
```

```nix rejected
# NO: function spam
mkSimpleService = name: exec: { inherit exec; };
mkServiceWithEnv = name: exec: env: { inherit exec env; };
```

```nix accepted
# YES: extend the existing function in place
someFn = args:
  let base = originalLogic args;
  in base // lib.optionalAttrs (args ? ssl) { inherit (args) ssl; };
```

Every module opens with the header block and takes only the arguments it reads:

```nix template
# Title         : [filename]
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : [relative-path]
# ----------------------------------------------------------------------------
# [One-line description if complex]

{ lib, pkgs, ... }:   # never the kitchen sink { self, inputs, options, ... }
```

- Options exist only for truly configurable surfaces (`mkEnableOption` plus minimal knobs, maximum inference); direct `config` implementation is the default.
- [NEVER]: wrapper modules for single options, `with pkgs;` at file level, function spam, anticipatory code, dead code, hardcoded platform/user detection, old-version pins without a named critical reason.
- Build time: prefer `imports` over inline modules, gate heavy evaluation with `mkIf`, cache derivations in `let` bindings. Runtime: parallelize scripts with `&` + `wait`, batch file ops with `symlinkJoin`, lazy-activate services.

## [04]-[LANGUAGE_LAW]

Code-generation law lives in the stack atlases: `docs/stacks/python/README.md` and `docs/stacks/typescript/README.md` route every language, shape, rail, and boundary decision to its owning page. Design law lives in the `docs/standards/` doctrine pair — `design-doctrine.md` binds every executable surface (rails, dispatch, vocabularies), and `nix-doctrine.md` extends it onto Nix modules, overlays, packaged shell kernels, and generated config. Durable Markdown follows the remaining `docs/standards/` owners — `style-guide.md` for language law, `formatting.md` for surface mechanics, `information-structure.md` for container design. The docgen skill's `prose_gate.py` compiles those owners into the mechanical floor: bare invocation checks, `fix --write` repairs; every touched durable doc passes it before the turn ends.

[SHELL]:

- `.sh` extension on every bash script; `set -euo pipefail` mandatory; ShellCheck passes. Package shell CLIs with `writeShellApplication` when they carry a runtime closure, ShellCheck integration, or a stable Home Manager-installed binary; `writeShellScriptBin` only for closure-free one-liners.

[PYTHON]:

- 3.15 only, never older; `uv` for package management; `ruff` for all linting/formatting.
- Type checking: `ty` with `mypy` as the strict secondary gate — both resolve the project environment first, `ty` falling back to the Nix build, `mypy` to the newest release through uv's tool cache.

## [05]-[LOCAL_PROVISIONING]

- `forge-provision` is the canonical Forge-owned local provisioning and debugging command: the overlay package owns the implementation, and Home Manager only installs that derivation. Use the packaged executable or `nix run .#forge-provision -- <command>`, never the raw overlay script. Rasm campaign work enters through `uv run python -m tools.assay provision <verb>`; direct `forge-provision`, `psql`, `paths`, `prune`, `self-test`, Docker/Compose, and diagnostic JSON are Forge-level debugging surfaces.
- Clean renames over compatibility shims: retired provisioning command names never survive as aliases, wrappers, fallbacks, or silent environment-variable compatibility.
- Provisioning stays agent-first and noninteractive: no host `sudo`, no keychain prompt, no DB password prompt, no Docker credential-helper dependency for public images.
- Read-only provisioning commands avoid durable repo writes unless the command explicitly documents state creation.
- Home Manager DB tooling is client/tooling-owned: `psql`, `pg_dump`, `pg_restore`, `pg_isready`, optional `pg_config`, SQLFluff/Postgres LSP, DuckDB, SQLite/SQLean, SpatiaLite, and sqlite-vec. PostgreSQL server extensions stay Docker-owned by `forge-provision` — shared-preload rows may include pg_cron, with `pg_cron` extension creation row-gated and opt-in.
- Forge provisioning JSON is schema v3 only — no earlier-schema emitters or compatibility adapters. Doctor and extension JSON expose sanitized runtime booleans/kinds and catalog metadata only; raw sockets, Docker config paths, helper names, logs, DSNs, token material, mount paths, and host absolute paths stay out of agent-facing JSON.

## [06]-[COMMIT_STANDARDS]

```text
scope: action

- Specific change 1
- Specific change 2
```

Scopes: `nix`, `darwin`, `home`, `flake`, `tooling`, `services`, `docs`. The subject is a specific imperative action — never "update" or "improve". Body bullets name the concrete changes, one per line.
