# Parametric Forge Agent Policy

## [01]-[PROJECT_OWNER]

- `CLAUDE.md` is the project execution standard — model dispatch, estate law, Nix code law, language routing, provisioning contract, commit standards. This file carries only agent-runtime deltas.
- This repository is the machine/user toolchain owner for every estate host: shell, PATH, tool, wrapper, launcher, and credential behavior is fixed here, never patched in a sibling project.
- Apple Container is a coexistence runtime, never a Docker/Compose replacement or `DOCKER_HOST` owner. Install ownership: `modules/darwin/homebrew/brews.nix`; runtime/env ownership: `modules/home/environments/containers.nix`; diagnostics: `forge-provision doctor`.
- Runtime routing — Colima runs Docker Engine API, `DOCKER_HOST`, Compose, Pulumi Docker providers, Docker SDKs, Testcontainers, `docker cp`/`docker exec`, and Buildx-into-daemon.
- Runtime routing — registry/image movement without a runtime uses `skopeo`/`crane`/`oras`/`regctl`.
- Runtime routing — Apple Container runs single isolated OCI run/build, `container machine`, and per-container-VM benchmarking.
- Runtime routing — Kubernetes stays on the kubectl/kind/helm chain; Apple Container is not a Kubernetes owner.
- `~/.codex` is the sole Codex configuration home; no file in this repository is Codex configuration source of truth. Repo `.claude/` state serves the Claude harness, and this file carries policy, never configuration.

## [02]-[SKILL_MASTERS]

- `.claude/skills/` here are the estate masters for harness skills; sibling-repo copies and Codex-admitted `~/.codex/skills/` are mirrors. Claude-caller skills such as `codex` remain Claude-only to prevent recursive triggering. A skill edit lands in the master and propagates by copy — never edit a mirror, never build sync tooling.
- `.claude/hooks/setup-env.sh` is the canonical SessionStart hook, byte-identical in every estate repo and mastered here; hook fixes land here first.
- The byte-copied mirror set spans `.claude/{skills,hooks,scripts,agents}`, `commands/docs.md`, `docs/stacks/{python,typescript}/`, and the three prose standards (`information-structure`, `formatting`, `style-guide`); sibling copies are read-only mirrors.

## [03]-[NIX_SHELL_EXECUTION]

- Prefer Nix/Home Manager owned executables and wrappers over aliases or interactive shell functions.
- `fmt [--check|--json] [target...]` is the universal formatter front door (owner: `modules/home/scripts/fmt.nix`); each file type routes to its owning formatter through the never-shadow PATH wrappers, and repo law (`pyproject.toml`, `biome.json`, treefmt rows) always outranks the machine XDG fallbacks.
- Python work uses the project or tool-owner interpreter (`uv run`, `.venv/bin/python`, or the repo-declared command), never ambient `python3`, unless the task is explicitly the machine Python.
- Nix option and package truth routes through the `nixos` MCP first, never recall; `CLAUDE.md` [03] carries the tool contract and its division of labor with `context7` and module source.

## [04]-[PROVISIONING_AND_LAUNCHERS]

- The `forge-provision` mechanism — packaged executable, campaign entry, rename-over-shim policy, DB-tooling ownership, schema-v3 JSON contract — is owned by `CLAUDE.md`; provisioning stays noninteractive for agents by contract.
- MCP and server launchers are Home Manager-installed wrappers: the `forge-*-mcp` fleet wrappers project from `modules/home/programs/shell-tools/mcp-launchers.nix` rows, while `forge-ifcmcp`, `forge-jupyter` (persistent JupyterLab LaunchAgent on loopback `127.0.0.1:8888`), and `forge-jupyter-mcp` live in `modules/home/programs/languages/scientific-tools.nix` and `nuget-mcp` in `modules/home/programs/languages/dev-tools.nix`.
- Sibling-repo `ifc`/`jupyter`/`nuget` skills and MCP configs invoke these launchers; launcher behavior is fixed here, never in a sibling repo.

## [05]-[AGENT_RUNTIME]

- Diagnose agent-tool runtime behavior separately from shell behavior. Claude workflow globals such as `args` are owned by Claude's workflow runtime; Nix, zsh, aliases, and PATH only explain subprocess, hook, or shell-command behavior.
- Gemini judgment, visual, and image-prompt legs route through the `agy` skill (`.claude/skills/agy`), strongest reasoning tier pinned; its review lanes are read-only. A codex session reaches `agy` only under `-s danger-full-access` — the Seatbelt sandbox kills the process at lower sandbox levels.
- Persist API tokens through `CLAUDE_ENV_FILE` only when subagents or tools need inherited credentials; Claude may expand that file into shell launch command lines while commands run.
- Use `CLAUDE_ENV_EXPORT_KEYS` (comma/space list) for additional sub-agent credential variables required beyond the default `setup-env.sh` key set.
- The harness edit path can materialize control-character escapes (the `\u001f` class) as raw bytes on disk; after writing content that carries them, byte-verify with `cat -v` — raw control bytes are invisible to every text reader — and can strip 3-byte BMP private-use glyphs while planes 15/16 survive, so glyph-bearing files ride scripted writes with byte-level diff gates.
- Estate rebuild passes hold the structural-win bar: a pass that only polishes is a failed pass unless an exhausted attack proves clean; a byte-fidelity deferral discharges by baseline eval-diff of the rendered artifact, never by standing; every pass returns evidence-anchored harvest rows that fold into scars, doctrine, and review rules the same session.
- `docs/laws/` binds every substantive pass: a touched topology `[SURFACE]` lands its obligated counterparts in the same change, and harvest nominations land only through the run's terminal doctrine stage under the corpus admission law — `CLAUDE.md` [02] carries the full pointer.
- A touched file is a rebuild surface: ground-up to its language's bleeding edge, every line lifted — task-relevant or not; naive patterns, hand-rolled reimplementations of shipped capability, and spam shapes found in passing are destroyed on contact, and the rebuilt shape obeys the density law (`CLAUDE.md` [03]) — polymorphic collapse in place, never extraction.

## [06]-[DEPLOY_SEAM]

- Any change to a module, overlay, or launcher lands through `forge-redeploy --switch` and proves through `forge-accept`; an edited `.nix` file without a switch is invisible to the running estate.
- A file created in the working tree is `git add --intent-to-add`ed before its first build — untracked files are invisible to the git-filtered flake source, and a dirty-tree build silently packages without them.
- A change to any module the shared home graph imports proves both hosts before it lands: the darwin system build plus `nix eval '.#nixosConfigurations.maghz.config.system.build.toplevel.drvPath'` — `nix flake check` covers neither toplevel.
- The `maghz` NixOS host deploys over SSH from this repo (`forge-redeploy --os nixos --host maghz --target-host <ssh>`); its services stay loopback-bound and are reached through the `vpsTunnels` rows, never by opening ports.
- An interrupted-server dialog or dead remote mount is a transport event: decode it from the lane's receipts before touching code — the transition contract lives in `docs/atlas/interconnection.md`, the transport law in `docs/laws/agents.md`'s `[REMOTE_TRANSPORT]` card.
