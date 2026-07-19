# Parametric Forge Execution Standards

## [01]-[MODEL_DISPATCH]

Rankings, higher is better. Cost reflects actual operator spend, not list price. Intelligence is how hard a problem the model absorbs unsupervised. Taste covers UI/UX, code quality, API design, and copy.

| [INDEX] | [MODEL]       | [COST] | [INTELLIGENCE] | [TASTE] |
| :-----: | :------------ | :----: | :------------: | :-----: |
|  [01]   | gpt-5.6-terra |   9    |       7        |    6    |
|  [02]   | gpt-5.6-sol   |   8    |       8        |    7    |
|  [03]   | gpt-5.6-luna  |   10   |       5        |    5    |
|  [04]   | sonnet-5      |   5    |       3        |    6    |
|  [05]   | opus-4.8      |   4    |       7        |    7    |
|  [06]   | fable-5       |   2    |       9        |    9    |

- Terra is the default Codex worker for sweeps, research, migration, and clear-spec implementation; Sol owns ambiguous design, complex code, and the deepest review; Luna owns fixed-schema high-volume transformation.
- Every Codex lane pins sandbox and the suffixed model slug; effort inherits the operator default in `~/.codex/config.toml` and is stated only to deviate; every prompt carries an explicit completion bar — the enumerated deliverables and the proof each is met; the bar bounds scope and layer, never depth.
- The operator config owns the dispatch-default tier; low/medium serve bulk throughput, max deepens the single hardest leg. Bounded subagent spawning is agent-discretionary when independent or parallel work materially improves the result; Ultra only biases Sol and Terra to self-decompose - redundant where the caller owns the fan-out - while Luna ends at max. Critique and red-team roles are optional, used on explicit request or when heavy code or logic warrants independent adversarial review.
- Fan-out lanes disable every unused MCP server, including `heptabase-mcp`, and never refan with Ultra. `forge-mcp doctor --network` and `forge-mcp drift` are the fleet gates.
- User-facing surfaces require taste ≥ 7. Plan and implementation reviews use fable-5 or opus-4.8, with Terra or Sol as the independent Codex lineage.
- Delegated agents inherit this table at every depth under the agent-dispatch placement law, never self-escalating beyond the brief.
- Claude models run through the Agent/Workflow `model` parameter at effort `high`; Codex runs through the `codex` MCP tool or `codex exec` / `codex review` — the codex skill owns invocation. [NEVER]: Haiku.
- A workflow codex leg is a thin wrapper labeled with the real worker (`terra:`/`sol:`/`luna:`/`gemini:`) making one blocking `codex` MCP call; the workflow-creator codex-lanes reference owns the wrapper and receipt contract.

## [02]-[ESTATE_LAW]

The Nix estate is machine configuration, not application code: every Nix line configures the system/user environment, deploys files/packages, or activates services — a line doing none of these does not belong here. One module graph serves every host; the OS branch keys on the static host context (`hosts/context.nix`), never on `pkgs`. `services/` owns live service state as Pulumi rows, `docs/` owns durable law, and `overlays/` admits an upstream package only with a real consumer now.

- Open the memory index at `~/.claude/projects/-Users-bardiasamiee-Documents-99-Github-Parametric-Forge/memory/MEMORY.md` before module, launchd, propagation, or provisioning work — memories carry machine laws and estate gotchas the docs corpus omits, and dispatched agents reach them only through this route.
- System scope (`modules/darwin/`, `modules/nixos/`) and home scope (`modules/home/`) never mix in one module; nothing Darwin-owned — Homebrew, launchd, macOS defaults — generalizes into `modules/nixos/`.
- Latest nixpkgs-unstable always; a pin exists only with a named incompatibility and dies when compatibility lands.
- `forge-redeploy` is the only activation path, and switches happen freely — deploy early to catch runtime-only bugs, never batch changes behind ceremony. It gates on `nix flake check` (formatting, lint, both hosts' evals) and the per-host toplevel build; a failing check is a real blocker resolved at the source, never bypassed. `forge-accept` proves the switch end to end.
- Recurring work is a declared launchd agent under the `com.parametric-forge.<name>` grammar, beside the surface it serves; ad-hoc background processes and manual `launchctl` state are defects.
- Standing remote connections (mounts, tunnels, sessions) follow the doctrine's `[REMOTE_TRANSPORT]` card: openssh keepalive custody, probed liveness with caused receipts, detach-before-reap drains.
- [NEVER]: kill live terminal sessions — no `zellij kill-session`/`kill-all-sessions`, no WezTerm restarts. Fix in repo, redeploy; the operator restarts on their own schedule.
- `.claude/hooks/` and `.claude/scripts/` are Forge-mastered and copy to the sibling repos, `~/.claude/`, and `~/.codex/` (`.claude/hooks/setup-env.sh` is the canonical SessionStart hook); every other `.claude/` surface carries no master and byte-copies bidirectionally on change, skills byte-copying to `~/.codex/skills/`. Claude-caller skills such as `codex` stay outside `~/.codex/skills/` to prevent recursive triggering; never build sync tooling.
- `docs/laws/` is the design and maintenance-law corpus: `design.md` with its machine law pages, the coupling topology, and the scar trap ledger, all under the `README.md` admission law. Read it at source before any cross-surface edit; a touched `topology.md` `[SURFACE]` lands its obligated counterparts in the same change, and generalizable findings land only through a run's terminal doctrine stage under `docs/laws/README.md` with the `docgen` and `skill-writer` skills loaded.

## [03]-[NIX_CODE_LAW]

Density target: ~300 LOC per file, measured with `loc`, never bytes. Approaching the limit means collapsing polymorphically inside the file — merged functions, dispatch tables, parameterized rows — splitting only when concerns are truly distinct; justified single-concern files (long lists, one owner) may exceed it.

Before adding any code: nixpkgs already solves it? the existing pattern extends? needed now, not "later"? Any "no" means the code does not land. Vocabulary row tables use positional constructors or delimited tuples — the formatter explodes multi-key attrset rows ~2.4x, and density that dies at the fmt lane never lands. Modification is surgical and in-place — read the entire file, understand its patterns, extend the existing surface; a parallel "improved" version is a defect.

Option and package truth is probed, never recalled. The `nixos` MCP's unified `nix` tool answers the pre-add questions: `action=search` (`type=packages|options|programs`, `channel=unstable`) proves whether nixpkgs already solves it; `action=info|browse` with `source=darwin|home-manager|nixos` proves an option's existence, type, and default before any module row lands — `browse` walks a prefix such as `system.defaults.dock`; `nix_versions` dates a package across releases; `action=flake-inputs|store` reads locked inputs and store paths without shell plumbing. Division of labor: the `nixos` MCP for option and package lookup, `context7` for manual narrative and worked examples, the locked module source for final write semantics — value mappings, ByHost domains, activation behavior — because the MCP indexes current upstream manuals, never this flake's lock; `nix-locate`/`comma` for file-to-package resolution.

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

Code-generation law lives in the stack atlases: `docs/stacks/python/README.md` and `docs/stacks/typescript/README.md` route every language, shape, rail, and boundary decision to its owning page. Design law lives in the `docs/laws/` corpus — `design.md` binds every executable surface (rails, dispatch, vocabularies), and the machine law pages extend it: `modules.md` onto the Nix module graph, `kernels.md` onto packaged shell, `projections.md` onto Lua consumers and generated config, `agents.md` onto service agents and remote transport. Durable Markdown follows the `docs/standards/` owners — `style-guide.md` for language law, `formatting.md` for surface mechanics, `information-structure.md` for container design. The docgen skill's `prose_gate.py` compiles those owners into the mechanical floor: bare invocation checks, `fix --write` repairs; every touched durable doc passes it before the turn ends.

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
