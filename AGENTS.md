# Repository Guidelines

## Project Structure & Module Organization

Configuration is split by scope: `00.system/` holds root-level Darwin and NixOS modules, while `01.home/` provides user programs, packages, and deployed assets. Shared flake logic lands in `flake/`, and reusable helpers live in `lib/` as `myLib`. Module code should stay lean (≤300 LOC) and delegate reusable logic to `lib/` or purpose-specific subdirectories. Keep platform branching context-driven—use `myLib.detectContext` over host files or hard-coded checks.

## Build, Test & Development Commands

Use `nix develop` (or `nix develop .#python`) for reproducible shells. Run `nix fmt` before commits to format Nix, Python, and shell sources. Validate changes with `nix flake check`; follow with `nix run .#check-system` for integration sanity. Apply OS configs via `darwin-rebuild build|switch --flake .` on macOS or `nixos-rebuild build|switch --flake .` on Linux. Update inputs intentionally with `nix flake update` and review the diff.

## Coding Style & Naming Conventions

Import modules as `{ lib, pkgs, myLib, context, ... }` and avoid `with pkgs;` at file scope. Prefer pure functions and atomic option sets; never add placeholders "for later." Python (3.13+) uses `uv`-managed dependencies, `ruff format`/`ruff check`, and Basedpyright for type safety; follow `snake_case` functions and `PascalCase` types. Shell scripts end in `.sh`, start with `set -euo pipefail`, and should pass ShellCheck—package them with `myLib.build.mkBinPackage` or `writeShellScriptBin` rather than ad-hoc copies.

## Testing Guidelines

Treat `nix fmt` and `nix flake check` as mandatory gates. For system changes, ensure the appropriate `darwin-rebuild build` or `nixos-rebuild build` succeeds before opening a PR. Python code should include `pytest -q` coverage, with Hypothesis property tests when behavior warrants. Co-locate tests beside their modules or under a `tests/` folder; name files `test_<feature>.py` to keep discovery simple. Aim for fast, deterministic cases and document any external prerequisites in `docs/`.

## Commit & Pull Request Guidelines

Commits follow `[scope]: action`, where `scope` maps to directories like `00.system`, `01.home`, or `lib`. Group related changes; avoid spanning unrelated domains. Pull requests must summarize intent, link related issues, and include screenshots or GIFs for UI-facing adjustments. Note required rebuild commands, mention any follow-up chores, and confirm all formatting and checks have run before requesting review.

## Architecture & Context Tips

Keep platform-specific behavior isolated behind context predicates (`context.isDarwin`, `context.isLinux`, etc.) and reuse `myLib.build.deployDir` for asset sync. Prefer nixpkgs-unstable defaults, avoid wrapper-only modules, and ensure every non-trivial file carries the standard header banner to signal ownership and revision history.
