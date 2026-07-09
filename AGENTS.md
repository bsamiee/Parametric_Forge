# Parametric Forge Agent Policy

## [01]-[PROJECT_OWNER]
- `CLAUDE.md` is the project execution standard and the single owner of Forge provisioning, Nix, code-density, and language law; this file carries only agent-runtime deltas.
- Code-generation law lives in the `docs/stacks/python` and `docs/stacks/typescript` atlases; durable Markdown follows the `docs/standards/` owners.
- Treat this repository as the machine/Home Manager toolchain owner: fix shell, PATH, tool, and wrapper behavior here instead of patching individual sibling projects.

## [02]-[NIX_SHELL_EXECUTION]
- Prefer Nix/Home Manager owned executables and wrappers over aliases or interactive shell functions.
- For Python work, use the project or tool owner interpreter (`uv run`, `.venv/bin/python`, or the repo-declared command) rather than ambient `python3` unless the task is explicitly about the machine Python.

## [03]-[LOCAL_PROVISIONING]
- The canonical `forge-provision` mechanism (packaged executable / `nix run .#forge-provision`, the `uv run python -m tools.assay provision <verb>` campaign entry, rename-over-shim policy, DB-tooling ownership, and the schema-v3 JSON contract) is owned by `CLAUDE.md`; follow it there.
- Provisioning must stay noninteractive for agents: no host `sudo`, no keychain requirement, no password prompt, and no Docker credential helper dependency for public images.
- The MCP and server launchers are Home Manager-installed wrappers under `modules/home/programs/languages/`: `forge-ifcmcp` (IfcOpenShell MCP on the cp312 companion lane), `forge-jupyter` (persistent JupyterLab LaunchAgent on loopback `127.0.0.1:8888`, registered as the "Forge Jupyter" Login Item), `forge-jupyter-mcp` (the Jupyter MCP connector), and `nuget-mcp` (the NuGet MCP via the .NET 10 SDK).
- Sibling-repo `ifc`/`jupyter`/`nuget` skills and MCP configs invoke these launchers; fix launcher behavior here, never in a sibling repo.

## [04]-[AGENT_RUNTIME]
- Diagnose agent-tool runtime behavior separately from shell behavior. Claude workflow globals such as `args` are owned by Claude's workflow runtime; Nix, zsh, aliases, and PATH only explain subprocess, hook, or shell-command behavior.
- Persist API tokens through `CLAUDE_ENV_FILE` only when subagents or tools need inherited credentials; Claude may expand that file into shell launch command lines while commands run.
- Use `CLAUDE_ENV_EXPORT_KEYS` for additional sub-agent credential variables that are required beyond the default `setup-env.sh` key set.

## [05]-[RESEARCH_DOCS]
- The web/docs/repo research tool-selection and chaining law is the user-global doctrine; follow it. Resolve current Nixpkgs and Home Manager option behavior through `Context7` or its source, never training-data recall.
