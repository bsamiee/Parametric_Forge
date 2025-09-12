# Repository Guidelines

## Core Principles (from CLAUDE.MD)
- Always: latest `nixpkgs-unstable`, use `myLib`, detect platform via `context`, prefer atomic ops and pure functions.
- Never: pin old nixpkgs, create wrapper modules for single options, mix system and home scopes, `with pkgs;` at file scope, or add code “for later”.
- Code density: target ≤300 LOC/file. If near limit, extract to `lib/`, split by concern, or refactor for density. Use standard header banner in all non-trivial files.

## Structure & Imports
- Split by concern: `00.system/` (root) vs `01.home/` (user). `flake/` holds flake-parts modules; `lib/` exposes helpers as `myLib`.
- Import pattern: `{ lib, pkgs, myLib, context, ... }`. Avoid kitchen-sink argument lists.
- Platform logic must be context-driven (no hardcoded OS/arch or host files).

## Coding Standards
- Nix: `nix fmt` (120 cols). Prefer `myLib` builders; keep functions pure where feasible.
- Python (3.13+): use `uv` for packages; `ruff` for lint/format; prefer Basedpyright (mypy configured strictly as needed). Naming: `snake_case`, `PascalCase`.
- Shell: files end with `.sh`, start with `set -euo pipefail`; ShellCheck clean; prefer `writeShellScriptBin`/Nix apps over ad‑hoc scripts.

## Tools & Commands
- Format: `nix fmt`. Quality: `nix flake check`. Dev shells: `nix develop`, `nix develop .#python`.
- Apply configs: macOS `darwin-rebuild build|switch --flake .`; NixOS `nixos-rebuild build|switch --flake .`. System check: `nix run .#check-system`.

## Testing & Validation
- Required before commit: `nix fmt` and `nix flake check`; for OS changes, ensure `darwin-rebuild build`/`nixos-rebuild build` succeeds.
- Python: `pytest -q`; property tests via `hypothesis` when useful; keep tests fast and isolated.

## Commits & PRs
- Commit format: `[scope]: action` (e.g., `hammerspoon: refactor window rules`). Keep changes small and cohesive.
- PRs must include a clear description, relevant context, and screenshots/GIFs for UI-affecting changes.

## Anti‑Patterns to Avoid
- Function spam, wrapper-only modules, anticipatory code, over‑abstraction, dead code, version pinning, manual platform checks.
