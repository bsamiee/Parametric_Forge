# Platform Facts

macOS reality the estate is built against: the invariants and quirks an agent needs before touching a surface, none derivable from a module read alone. Command surfaces route to their `--help`.

## [01]-[SCOPE_BOUNDARIES]

Declaring scope bounds each fact. `modules/darwin` owns system defaults, security, fonts, and Homebrew; `modules/home` owns user launchd agents, environments, programs, and XDG. Home Manager LaunchAgents mutate user state while system defaults mutate machine state. Recurring machine work is declared as `com.parametric-forge.<name>` beside its surface.

## [02]-[LAUNCHD_GRAMMAR]

Home Manager launchd mutation emits `/bin/sh` as `ProgramArguments[0]`, so Login Items & Extensions shows a generic `sh` unless the agent carries a Forge `.app` bundle with `AssociatedBundleIdentifiers`. One estate label and paired BTM app bundle produce a human-readable Login Items row. Module files own the registry because `sfltool dumpbtm` requires an authorized macOS read.

GUI launchd domains can carry credential-bearing session variables. Credential-free jobs invoke children through an explicit environment, and diagnostics inspect declared plist fields or variable names without rendering the domain environment.

Per-agent quirks a plist read does not explain live in their owner modules; the ones that bite:

| [INDEX] | [AGENT]                                 | [OWNER]                       | [NON_OBVIOUS_FACT]                    |
| :-----: | :-------------------------------------- | :---------------------------- | :------------------------------------ |
|  [01]   | `org.nix-community.home.colima-default` | `environments/containers.nix` | restart-on-stop; needs `ExitTimeOut`  |
|  [02]   | `org.nix-community.home.atuin-daemon`   | `shell-tools/atuin.nix`       | upstream HM label, not estate grammar |
|  [03]   | `com.parametric-forge.maghz-vps-tunnel` | `shell-tools/ssh.nix`         | row from `vpsTunnels`; owns forwards  |

- [01]: `KeepAlive.SuccessfulExit=true` restarts it after `colima stop`; the default exit timeout SIGKILLs VM teardown, so teardown needs the declared `ExitTimeOut`.
- [02]: upstream HM label, not estate grammar; a `com.parametric-forge.*` label search misses the live agent.
- [03]: row-generated from `vpsTunnels`; receipts classify tunnel health and port ownership.

`Forge Nix Automation.app` is one shared BTM identity for the maintenance and orphan-sweep jobs; splitting it fragments the scheduled jobs into opaque Login Items rows.

## [03]-[TCC_SUDO]

TCC is reset-only through `tccutil`; the estate writes no `TCC.db` rows and ships no PPPC profile on this unmanaged host, so first agent launches require live macOS approval prompts. Post-activation switches on `DevToolsSecurity` and puts the primary user in `_developer`. `sudo_local` PAM has Touch ID enabled with Watch ID and reattach false: a plain `sudo` from any shell — interactive or not — pops the biometric prompt on the user's screen, so root fixes stay available and `sudo -n` (which suppresses the prompt) never proves root unreachable.

`darwin/settings/security.nix` owns the NOPASSWD allowlist and the exact deploy-rail rows `forge-redeploy` consumes. Live sudoers state must match that file before a switch.

## [04]-[BASH_GNU_BSD]

`/bin/bash` is Apple bash `3.2`; the Home Manager profile bash (`/etc/profiles/per-user/$USER/bin/bash`) is `5.x`. Bash-only snippets run through `bash -lc`, a bash heredoc, or a bash-shebang executable.

BSD/GNU tool divergence is handled by probe-then-fallback. `forge-provision` carries GNU coreutils because atomic generation publication requires `mv -T`. Runtime-bearing shell CLIs use `writeShellApplication`; closure-free one-liners use `writeShellScriptBin`. Deadline-bearing scripts package their own timeout implementation.

## [05]-[CONTAINER_RUNTIME]

Colima owns the Docker runtime, XDG data home, current context, and launchd lifecycle. Its launchd profile declares writable home and `/tmp/colima` mounts because background starts omit implicit mounts. GUI launchd jobs receive `DOCKER_HOST`, `COLIMA_HOME`, and `DOCKER_CONFIG`; `programs.docker-cli` owns the helper-free config. `forge-provision` resolves `DOCKER_HOST`, then `DOCKER_CONTEXT`, then the Colima socket and rejects foreign Darwin endpoints unless explicitly admitted. Apple Container remains additive.

## [06]-[DEPLOY_LOCKS_ACTIVATION]

`forge-redeploy` is the only sanctioned activation path, and deploy/maintenance jobs serialize through `${FORGE_REDEPLOY_LOCK:-$HOME/.cache/forge-redeploy.lock}`. `forge-redeploy` rejects any post-activation profile whose `/run/current-system` differs from the built store path.

Two activation traps have owned recovery rails. Installer-written `/etc/nix/nix.custom.conf` blocks Determinate activation; the deploy rail moves it aside through an exact sudoers row. Stale root-owned Home Manager store hardlinks under `.config`, `.local/share`, `.local/state`, `.hammerspoon`, and `Library/LaunchAgents` block user-mode backup/relink; `forge-activation-sweep [--clear]` detects the topmost root-owned entries with `find -uid 0 -prune` and clears them in one sudo batch. `forge-provision` runs a parallel generation model — `gen-<epoch>-<srandom>` ids, a `.staging-<id>` dir, and an atomic `current` symlink publish that refuses a non-symlink `current`.
