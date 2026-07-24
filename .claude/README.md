# Claude Workspace Setup

## [01]-[SESSION_START]

`settings.json` runs `hooks/setup-env.sh` on startup, resume, and compaction. The hook is two lanes: a warm session replays the mode-600 session cache into `CLAUDE_ENV_FILE` instantly and dispatches a detached `--refresh`; the refresh lane (or a cold first boot, inline) resolves each `DOPPLER_SOURCES` row independently — a live Doppler fetch refreshes its encrypted snapshot under the doppler cache, a failed fetch serves the snapshot, and a dead row reports loudly with owed key names only. Resolved keys plus optional PATH additions land in `CLAUDE_ENV_FILE` for sub-agent/tool inheritance; the hook never sources local shell files, installs tools, or writes profiles.

[VARIABLES]:
- `CLAUDE_ENV_EXPORT_KEYS` - Extra env var names to persist, separated by spaces or commas.
- `CLAUDE_TOOL_PATHS` - Colon-separated PATH entries to prepend when directories exist.
- `CLAUDE_ALLOW_MISSING_TOOL_PATHS=1` - Preserve explicit PATH entries even when the directory is absent.
- `CLAUDE_DOPPLER_OFFLINE=1` - Force fallback-only fetches (snapshots serve, no network).

## [02]-[BOUNDARIES]

[CRITICAL]:
- [ALWAYS]: Keep startup deterministic; the only startup mutations are the hook-owned doppler snapshot and session caches.
- [ALWAYS]: Route machine tooling through the Parametric_Forge owner; no repo script installs tools, writes profiles, or mutates the host.
- [NEVER]: source local shell files during startup.
- [NEVER]: wire host bootstrap into `SessionStart`.

## [03]-[WORKSPACE]

- `scratch/<slug>/` homes campaign artifacts, one folder per campaign; the session scratchpad carries only throwaway files.
- `workflows/*.js` mix `export const meta` with top-level `await`/`return` — a dialect no Biome mode parses; formatters never touch them.
- `scripts/bootstrap-cli-tools.sh` provisions CLI tools on non-Forge hosts; default `check` reports, `apply` mutates via `CLAUDE_BOOTSTRAP_*` gates.
