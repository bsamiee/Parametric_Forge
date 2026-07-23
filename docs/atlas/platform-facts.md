# Platform Facts

macOS reality the estate is built against: the invariants and quirks an agent needs before touching a surface, none derivable from a module read alone. Command surfaces route to their `--help`.

## [01]-[SCOPE_BOUNDARIES]

A fact reaches only the scope that declares it. `modules/darwin` owns system defaults, security, fonts, and Homebrew; `modules/home` owns user launchd agents, environments, programs, and XDG. A LaunchAgent placed in Home Manager cannot set a system default, and a system default cannot touch user launchd or home files — so most user agents live under `modules/home`, not `modules/darwin`. Recurring machine work is declared as `com.parametric-forge.<name>` beside its surface; ad-hoc `launchctl` state is invisible to the flake and the acceptance rails.

## [02]-[LAUNCHD_GRAMMAR]

Home Manager launchd mutation emits `/bin/sh` as `ProgramArguments[0]`, so Login Items & Extensions shows a generic `sh` unless the agent carries a Forge `.app` bundle plus `AssociatedBundleIdentifiers`. The display-name grammar is: an estate label for the job, a paired BTM app bundle for a human-readable Login Items row. `sfltool dumpbtm` needs an authorized macOS read and is unavailable to an unattended agent, so the module files are the source of truth for the registry. nix-darwin's strict launchd schema rejects `AssociatedBundleIdentifiers` on the system-scope Homebrew reconciler, so that one agent has no display bundle by design.

Per-agent quirks a plist read does not explain live in their owner modules; the ones that bite:

| [INDEX] | [AGENT]                                 | [OWNER]                       | [NON_OBVIOUS_FACT]                    |
| :-----: | :-------------------------------------- | :---------------------------- | :------------------------------------ |
|  [01]   | `org.nix-community.home.colima-default` | `environments/containers.nix` | restart-on-stop; needs `ExitTimeOut`  |
|  [02]   | `org.nix-community.home.atuin-daemon`   | `shell-tools/atuin.nix`       | upstream HM label, not estate grammar |
|  [03]   | `com.github.domt4.homebrew-autoupdate`  | `darwin/homebrew/default.nix` | tap-owned; never rename               |
|  [04]   | `com.parametric-forge.forge-nix-drift`  | `shell-tools/forge-tools.nix` | calendar-only; no `RunAtLoad`         |
|  [05]   | `com.parametric-forge.maghz-vps-tunnel` | `shell-tools/ssh.nix`         | row from `vpsTunnels`; owns forwards  |

- [01]: `KeepAlive.SuccessfulExit=true` restarts it after `colima stop`; the default exit timeout SIGKILLs VM teardown, so teardown needs the declared `ExitTimeOut`.
- [02]: upstream HM label, not estate grammar; a `com.parametric-forge.*` label search misses the live agent.
- [03]: tap-owned upstream job the reconciler regenerates; renaming it to estate grammar breaks the lifecycle the reconciler proves.
- [04]: calendar-only, no `RunAtLoad` by design so login never races active work; a `RunAtLoad` row reintroduces the race.
- [05]: row-generated from `vpsTunnels`; receipts classify tunnel health and port ownership.

`Forge Nix Automation.app` is one shared BTM identity for the maintenance, drift, and orphan-sweep jobs; splitting it fragments three scheduled jobs into opaque Login Items rows.

## [03]-[TCC_SUDO]

TCC is reset-only through `tccutil`; the estate writes no `TCC.db` rows and ships no PPPC profile on this unmanaged host, so first agent launches require live macOS approval prompts. Post-activation switches on `DevToolsSecurity` and puts the primary user in `_developer`. `sudo_local` PAM has Touch ID enabled with Watch ID and reattach false: a plain `sudo` from any shell — interactive or not — pops the biometric prompt on the user's screen, so root fixes stay available and `sudo -n` (which suppresses the prompt) never proves root unreachable.

The NOPASSWD allowlist is owned by `darwin/settings/security.nix` and carries the exact deploy-rail rows `forge-redeploy` and maintenance depend on; removing a row causes a sudo denial mid-switch. Verify the live roster against that file rather than a memorized set — the machine's sudoers grant is what the file declares, not what a general instruction claims.

## [04]-[BASH_GNU_BSD]

`/bin/bash` is Apple bash `3.2`; the Home Manager profile bash (`/etc/profiles/per-user/$USER/bin/bash`) is `5.x`. The session hook `.claude/hooks/setup-env.sh` re-execs into profile bash when the resolved bash is `<5`, then sets `inherit_errexit` — a GUI/TUI context that resolves Apple bash rejects bash 5 features. Bash-only snippets (arrays, `mapfile`, `shopt`, `BASH_*`) run through `bash -lc`, a bash heredoc, or a bash-shebang executable, never under the interactive zsh.

BSD/GNU tool divergence is handled by probe-then-fallback, and a new script does the same: the hook's mtime read tries BSD `stat -f %Fm`, validates numeric output, then falls back to GNU `stat -c %.9Y`. `forge-provision` requires GNU `mv -T` for atomic generation publication and brings GNU coreutils through `runtimeInputs`; the raw source under BSD `mv` fails. Runtime-bearing shell CLIs use `writeShellApplication` so their runtime closure and ShellCheck are declared; one-liners use `writeShellScriptBin`. The machine has no `timeout`/`gtimeout` binary — a script that needs a deadline carries it in its own package, never an assumed GNU `timeout`.

## [05]-[CONTAINER_RUNTIME]

Colima owns the Docker runtime: `services.colima` with home under XDG data, the `colima` context current, and the lifecycle owned by the launchd agent — `colima stop` restarts it, so teardown goes through the agent. The launchd-spawned `colima start` skips Colima's implicit default mounts, so the profile declares writable `~` and `/tmp/colima` bind mounts explicitly — without them a container cannot resolve host home paths. The GUI launchd env is explicitly populated with `DOCKER_HOST` (the Colima socket), `COLIMA_HOME`, and `DOCKER_CONFIG` so a GUI-launched agent never resolves a Docker Desktop socket. `programs.docker-cli` owns `~/.config/docker/config.json` with empty `auths` and no `credsStore`, because no Docker Desktop credential helper exists — public pulls stay non-interactive. `forge-provision` resolves the Docker endpoint as `DOCKER_HOST` then `DOCKER_CONTEXT` then the Colima socket, and on Darwin rejects a non-Colima endpoint unless `FORGE_PROVISION_ALLOW_NON_COLIMA_DOCKER=1`. Apple Container is additive and never owns `DOCKER_HOST`.

## [06]-[DEPLOY_LOCKS_ACTIVATION]

`forge-redeploy` is the only sanctioned activation path, and the deploy/rollback/maintenance jobs serialize through one shared lock, `${FORGE_REDEPLOY_LOCK:-$HOME/.cache/forge-redeploy.lock}` — an agent using any other lock path fails to serialize with the live rail. `forge-nix-drift` holds its own `${FORGE_NIX_DRIFT_LOCK:-...}`. Darwin generation listing delegates to `darwin-rebuild --list-generations`; NixOS `--rollback`/`--generations` are rejected as Darwin-local. After activation, `forge-redeploy` asserts `/run/current-system` equals the built store path — a profile update without a matching live system is fatal.

Two activation traps have owned recovery rails. A real `/etc/nix/nix.custom.conf` blocks Determinate activation; the deploy rail moves it aside through an exact sudoers row. Stale root-owned Home Manager store hardlinks under `.config`, `.local/share`, `.local/state`, `.hammerspoon`, and `Library/LaunchAgents` block user-mode backup/relink; `forge-activation-sweep [--clear]` detects the topmost root-owned entries with `find -uid 0 -prune` and clears them in one sudo batch. `forge-provision` runs a parallel generation model — `gen-<epoch>-<srandom>` ids, a `.staging-<id>` dir, and an atomic `current` symlink publish that refuses a non-symlink `current`.
