# Parametric Forge Agent Policy

## Project Owner
- Read and follow `CLAUDE.md` before this file; it is the project execution standard for this repository and the single owner of Forge provisioning, Nix, code-density, and language law.
- Treat this repository as the machine/Home Manager toolchain owner: fix shell, PATH, tool, and wrapper behavior here instead of patching individual sibling projects.

## Nix And Shell Execution
- Prefer Nix/Home Manager owned executables and wrappers over aliases or interactive shell functions.
- For Python work, use the project or tool owner interpreter (`uv run`, `.venv/bin/python`, or the repo-declared command) rather than ambient `python3` unless the task is explicitly about the machine Python.

## Local Provisioning
- The canonical `forge-provision` mechanism (packaged executable / `nix run .#forge-provision`, the `uv run python -m tools.assay provision <verb>` campaign entry, rename-over-shim policy, DB-tooling ownership, and the schema-v3 JSON contract) is owned by `CLAUDE.md`; follow it there.
- Provisioning must stay noninteractive for agents: no host `sudo`, no keychain requirement, no password prompt, and no Docker credential helper dependency for public images.
- The MCP and server launchers `forge-ifcmcp` (IfcOpenShell MCP, cp312 companion lane), `forge-jupyter` (a persistent JupyterLab LaunchAgent on loopback `127.0.0.1:8888` with KeepAlive, registered as the "Forge Jupyter" Login Item so it is not a bare `sh` entry), `forge-jupyter-mcp` (the Jupyter MCP connector), and `nuget-mcp` (the NuGet MCP via the .NET 10 SDK) are Home Manager-installed wrappers under `modules/home/programs/languages/`. Sibling-repo `ifc`/`jupyter`/`nuget` skills and MCP configs invoke them; fix launcher behavior here, never in the sibling repo.

## Claude And Codex Runtime Boundaries
- Diagnose agent-tool runtime behavior separately from shell behavior. Claude workflow globals such as `args` are owned by Claude's workflow runtime; Nix, zsh, aliases, and PATH only explain subprocess, hook, or shell-command behavior.
- Persist API tokens through `CLAUDE_ENV_FILE` only when subagents or tools need inherited credentials; Claude may expand that file into shell launch command lines while commands run.
- Use `CLAUDE_ENV_EXPORT_KEYS` for additional sub-agent credential variables that are required beyond the default `setup-env.sh` key set.

## Research And Docs
- The web/docs/repo research tool-selection and chaining law is the user-global doctrine; follow it. Resolve current Nixpkgs and Home Manager option behavior through `Context7` or its source, never training-data recall.
