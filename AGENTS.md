# Parametric Forge Agent Policy

## Project Owner
- `CLAUDE.MD` is the project execution standard for this repository.
- Treat this repository as the machine/Home Manager toolchain owner: fix shell, PATH, tool, and wrapper behavior here instead of patching individual sibling projects.

## Nix And Shell Execution
- Prefer Nix/Home Manager owned executables and wrappers over aliases or interactive shell functions.
- Non-interactive agent shells do not inherit interactive zsh aliases or functions; invoke real executables on `PATH`, or use `zsh -ic` only when intentionally testing interactive zsh configuration.
- Bash-only snippets using `mapfile`, `readarray`, `shopt`, `BASH_*`, arrays, or Bash 5.3 features must run through `bash -lc`, a Bash heredoc, or an executable with a Bash shebang.
- For Python work, use the project or tool owner interpreter (`uv run`, `.venv/bin/python`, or the repo-declared command) rather than ambient `python3` unless the task is explicitly about the machine Python.

## Local Provisioning
- `rasm-provision` is the canonical local Rasm provisioning command; it is owned by the overlay package and installed through Home Manager from that derivation.
- Do not add compatibility executables, aliases, or fallbacks for retired provisioning names. Rename callers and documentation to the canonical command instead.
- Provisioning must stay noninteractive for agents: no host `sudo`, no keychain requirement, no password prompt, and no Docker credential helper dependency for public images.
- Read-only provisioning commands should avoid durable writes unless the command explicitly documents state creation.

## Claude And Codex Runtime Boundaries
- Diagnose agent-tool runtime behavior separately from shell behavior. Claude workflow globals such as `args` are owned by Claude's workflow runtime; Nix, zsh, aliases, and PATH only explain subprocess, hook, or shell-command behavior.
- Persist API tokens through `CLAUDE_ENV_FILE` only when subagents or tools need inherited credentials; Claude may expand that file into shell launch command lines while commands run.
- Use `CLAUDE_ENV_EXPORT_KEYS` for additional sub-agent credential variables that are required beyond the default `setup-env.sh` key set.
- For LOC reports, use `loc <path>` when `command -v loc` succeeds.
