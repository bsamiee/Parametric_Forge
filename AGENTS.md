# Parametric Forge Agent Policy

## [01]-[PROJECT_OWNER]

- `CLAUDE.md` is the project execution standard — model dispatch, estate law, Nix code law, language routing, provisioning contract, commit standards. This file carries only agent-runtime deltas.
- This repository is the machine/user toolchain owner for every estate host: shell, PATH, tool, wrapper, launcher, and credential behavior is fixed here, never patched in a sibling project.
- Apple Container is a coexistence runtime, never a Docker/Compose replacement or `DOCKER_HOST` owner. Install ownership: `modules/darwin/homebrew/brews.nix`; runtime/env ownership: `modules/home/environments/containers.nix`; diagnostics: `forge-provision doctor`.
- Runtime routing law: Docker Engine API, `DOCKER_HOST`, Compose, Pulumi Docker providers, Docker SDKs, Testcontainers, `docker cp`/`docker exec`, and Buildx-into-daemon run on Colima. Registry/image movement without a runtime uses `skopeo`/`crane`/`oras`/`regctl`. Single isolated OCI run/build, `container machine`, and per-container-VM benchmarking run on Apple Container. Kubernetes stays on the kubectl/kind/helm chain; Apple Container is not a Kubernetes owner.
- `~/.codex` is the sole Codex configuration home; no file in this repository is Codex configuration source of truth. Repo `.claude/` state serves the Claude harness, and this file carries policy, never configuration.

## [02]-[SKILL_MASTERS]

- `.claude/skills/` here are the estate masters for harness skills; `~/.codex/skills/` and sibling-repo copies are mirrors. A skill edit lands in the master and propagates by copy — never edit a mirror, never build sync tooling.
- `.claude/hooks/setup-env.sh` is the canonical SessionStart hook, byte-identical in every estate repo and mastered here; hook fixes land here first.

## [03]-[NIX_SHELL_EXECUTION]

- Prefer Nix/Home Manager owned executables and wrappers over aliases or interactive shell functions.
- Python work uses the project or tool-owner interpreter (`uv run`, `.venv/bin/python`, or the repo-declared command), never ambient `python3`, unless the task is explicitly the machine Python.
- Resolve current nixpkgs and Home Manager option behavior through `Context7` or module source, never recall.

## [04]-[PROVISIONING_AND_LAUNCHERS]

- The `forge-provision` mechanism — packaged executable, campaign entry, rename-over-shim policy, DB-tooling ownership, schema-v3 JSON contract — is owned by `CLAUDE.md`; provisioning stays noninteractive for agents by contract.
- MCP and server launchers are Home Manager-installed wrappers: the `forge-*-mcp` fleet wrappers project from `modules/home/programs/shell-tools/mcp-launchers.nix` rows, while `forge-ifcmcp`, `forge-jupyter` (persistent JupyterLab LaunchAgent on loopback `127.0.0.1:8888`), and `forge-jupyter-mcp` live in `modules/home/programs/languages/scientific-tools.nix` and `nuget-mcp` in `modules/home/programs/languages/dev-tools.nix`.
- Sibling-repo `ifc`/`jupyter`/`nuget` skills and MCP configs invoke these launchers; launcher behavior is fixed here, never in a sibling repo.

## [05]-[AGENT_RUNTIME]

- Diagnose agent-tool runtime behavior separately from shell behavior. Claude workflow globals such as `args` are owned by Claude's workflow runtime; Nix, zsh, aliases, and PATH only explain subprocess, hook, or shell-command behavior.
- Persist API tokens through `CLAUDE_ENV_FILE` only when subagents or tools need inherited credentials; Claude may expand that file into shell launch command lines while commands run.
- Use `CLAUDE_ENV_EXPORT_KEYS` (comma/space list) for additional sub-agent credential variables required beyond the default `setup-env.sh` key set.

## [06]-[DEPLOY_SEAM]

- Any change to a module, overlay, or launcher lands through `forge-redeploy --switch` and proves through `forge-accept`; an edited `.nix` file without a switch is invisible to the running estate.
- The `maghz` NixOS host deploys over SSH from this repo (`forge-redeploy --os nixos --host maghz --target-host <ssh>`); its services stay loopback-bound and are reached through the `vpsTunnels` rows, never by opening ports.
