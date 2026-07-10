# OSS Session Fabric Ecosystem

External OSS survey for the G4 session fabric: session-manager grammars, remote-mount alternatives, WezTerm/Zellij/Yazi ecosystem packages, and composable patterns worth stealing. Estate current-state and estate-resident tool capabilities live in `capabilities.md`.

## [01]-[TARGET_FRAMING]

- F05 targets one session-fabric vocabulary — workspace rows carrying Zellij session identity, WezTerm domain, float policy, and chord entry — anchored in `config.forge.ssh.hosts`, `zellij/ops.nix`, `wezterm/deck.lua`, and chord rows; the unlock joins session state to the receipts plane. Source: file:docs/FRONTIER.md:61-66.
- F12 targets the VFS fabric as an estate surface: the SSH-host row grows mount-policy fields (paths, read-only, cache posture) so every VFS-capable consumer folds the same rows, and `forge-workspace` gains remote-workspace entries riding the same identity. Source: file:docs/FRONTIER.md:68-73. (Estate anchors are detailed in `capabilities.md` [01].)

## [02]-[SESSION_MANAGER_GRAMMARS]

- Sesh (Go, tmux): TOML root keys `cache`, `strict_mode`, `import`, `blacklist`, `sort_order`, `dir_length`, `separator_aware`, `tmux_command`, `tui`, `default_session`, `session`, `window`, `wildcard`; `session[]` = `name`/`path`/`startup_command`/`disable_startup_command`/`tmuxp`/`tmuxinator`/`preview_command`/`windows`; `window[]` = `name`/`startup_script`/`path`; `wildcard[]` = `pattern`/`startup_command`/`disable_startup_command`/`preview_command`/`windows`. Entry points: `sesh list [-c]`, `sesh connect {session} [--root]`, `sesh window [--session]`, `sesh last`. Signal 2026-07-10: 2,673 stars, last push 2026-07-07. Source: https://raw.githubusercontent.com/joshmedeski/sesh/main/sesh.schema.json, https://github.com/joshmedeski/sesh, https://api.github.com/repos/joshmedeski/sesh.
- Smug (Go, tmux): `smug <cmd> [project] [-f file] [--worktree wt] [-w window]... [-a] [-d] [--detach] [--inside-current-session]`; session keys `attach`, `before_start`, `stop`, `attach_hook`, `detach_hook`; project keys `session`, `root`, `env`, `windows` (`name`/`manual`/`layout`/`commands`/`panes`/`type`/pane `root`). Signal 2026-07-10: 904 stars, last push 2026-06-30. Source: https://github.com/ivaaaan/smug, https://api.github.com/repos/ivaaaan/smug.
- Tmuxinator (Ruby, tmux): project keys `name`, `root`, `windows`, window `root`/`layout`/`panes`/`enable_pane_titles`/`focused_pane`, `pre_window`, `attach`, `on_project_exit`, `startup_window`, `startup_pane`; `tmuxinator start [project] -n [name] -p [config]`, local `./.tmuxinator.yml` and `--project-config` override the named lookup; ERB parameterization; records a live session into a project file. Signal 2026-07-10: 13,660 stars, last push 2026-07-03. Source: https://github.com/tmuxinator/tmuxinator, https://api.github.com/repos/tmuxinator/tmuxinator.
- Tmuxp (Python, libtmux): session files `session_name`, `windows` (`window_name`/`layout`/`shell_command_before`/`panes`/pane `shell_command`); `tmuxp load -s <name> ./file.yaml`, `tmuxp freeze <name>` (live→row snapshot), `tmuxp convert <file>` (YAML↔JSON); a Python shell over live libtmux objects. Signal 2026-07-10: 4,538 stars, last push 2026-07-05. Source: https://github.com/tmux-python/tmuxp, https://api.github.com/repos/tmux-python/tmuxp.
- [ADDED] All four are tmux-bound; none drives Zellij, whose native sessions + resurrection (`capabilities.md` [02]) are the estate's substitute. They are pattern donors — row models, lifecycle hooks, freeze/convert — not adoptable tools for a Zellij fabric. Source (adjacency): the four repos above, file:modules/home/programs/apps/zellij/ops.nix:134-202.

## [03]-[REMOTE_MOUNT_AND_IDENTITY]

- Rclone `mount remote:path/to/files /path/to/local/mount` is a cross-platform FUSE/NFS remote-mount layer with filesystem-level VFS policy: `--daemon`, `--read-only`, `--vfs-cache-mode writes|full`, `--dir-cache-time`, `--poll-interval`. Source: https://rclone.org/commands/rclone_mount/.
- [ADDED] Rclone `--vfs-cache-mode` supplies the cache posture Yazi's `ServiceSftp` structurally lacks (`capabilities.md` [04]); an OS-mount lane, not Yazi, is the only verified sink for F12's cache-posture field. Source (adjacency): https://rclone.org/commands/rclone_mount/, file:docs/FRONTIER.md:71.
- 1Password documents `IdentityAgent ~/.1password/agent.sock` as a per-host OpenSSH knob, so agent cohabitation is a host-row field: one host uses the 1Password agent while others keep a local key or another agent — the same row-addressed identity Forge already pins globally and projects into Yazi VFS and WezTerm SSH domains. Source: https://www.1password.dev/ssh/agent/advanced.

## [04]-[WEZTERM_STACK_PACKAGES]

- `resurrect.wezterm`: WezTerm-side JSON save/restore for workspaces, windows, tabs, panes, layout, shell text, and remote-domain reattach, with optional age/rage/GnuPG encryption — the WezTerm analog to Zellij resurrection. Signal: 274 stars, 23 forks, 424 commits, 29 issues, 6 PRs. Source: https://github.com/mlflexer/resurrect.wezterm.
- Yazelix: packaged Zellij + Yazi + Helix/Neovim terminal IDE — managed sidebars/popups, managed editor-pane targeting, `yzx reveal`, generated runtime state, child-owned subsystems. It splits user config (`$XDG_CONFIG_HOME/yazelix`) from generated runtime output (`$XDG_DATA_HOME/yazelix`; launchers set `YAZELIX_CONFIG_DIR`/`YAZELIX_STATE_DIR`), and uses managed pane identity for editor/sidebar handoff rather than pane scanning. Signal: `v17.9`, 1.1k stars, 3,693 commits, 49 forks, 40 issues. Source: https://github.com/luccahuguet/yazelix.
- `awesome-wezterm` catalogs independent session, attention, quota, domain, workspace, and tabset plugins — agent-attention/status, quota, quick domain attach, workspace pickers, session initializers, session save/restore, and named tabsets. Source: https://github.com/michaelbrusegard/awesome-wezterm.

## [05]-[COMPOSABLE_PATTERNS]

- Session rows split into discovery rows and launch rows: Sesh lists live sessions, configured sessions, and zoxide results, then connects-or-creates from the selected row. Source: https://github.com/joshmedeski/sesh.
- A compact session row delegates rich layout to a layout engine: Sesh `default_session.startup_command` calls `tmuxinator start …`, and `session[].windows` references reusable named `[[window]]` rows (session path inherited when the window path is omitted). Source: https://github.com/joshmedeski/sesh.
- Wildcard workspace admission is order-sensitive and path-pattern-based: Sesh `[[wildcard]]` carries `pattern`/startup/preview/disable/windows, and explicit `[[session]]` rows take priority over wildcard matches. Source: https://github.com/joshmedeski/sesh.
- Lifecycle hooks bind at the session row: Smug `before_start`, `stop`, `attach_hook`, `detach_hook` bind creation, teardown, first-client attach, and last-client detach. Source: https://github.com/ivaaaan/smug.
- Worktree selection belongs to the session-root resolver: Smug `--worktree` matches by branch or directory name and overrides the configured `root`. Source: https://github.com/ivaaaan/smug.
- Pane command arrays stay sequential send-key material rather than shell joins in both Tmuxinator and Tmuxp, keeping SSH-first panes and remote command sequences represented as pane rows. Source: https://github.com/tmuxinator/tmuxinator, https://github.com/tmux-python/tmuxp.
- Bidirectional row lifecycle: Tmuxp `load` materializes rows into tmux, `freeze` snapshots a live layout back into a row artifact, and `convert` moves artifacts between YAML and JSON. Source: https://github.com/tmux-python/tmuxp.
- [ADDED] Tmuxp `freeze` is the roster's only verified live→row session snapshot; Zellij offers `dump-layout` (live→KDL) but no session-freeze, so `forge-zellij layout record`'s gated dump is the estate's closest analog and the natural extension point for a session-freeze verb. Source (adjacency): https://github.com/tmux-python/tmuxp, file:modules/home/programs/apps/zellij/ops.nix:317-360.
- Remote filesystem identity stays row-addressed rather than mountpoint-addressed: Yazi `[services.<name>]` + `sftp://<service>` mirrors the same host-row source Forge projects into WezTerm SSH domains — one identity source, multiple consumers. Source: https://yazi-rs.github.io/docs/configuration/vfs/.
- Rclone models mount policy as filesystem-level VFS knobs (`--vfs-cache-mode writes|full`), the OS-mountpoint counterpart to Yazi's in-process row addressing. Source: https://rclone.org/commands/rclone_mount/.

## [GAPS]

- No surveyed session manager targets Zellij — hunt for a Zellij-native session-artifact tool (or a thin bridge) giving the `freeze`/`convert` round-trip Tmuxp has for tmux, or confirm `forge-zellij layout record` + resurrection is the whole story.
- Consumer ruling: which estate consumers actually need OS-mountpoint semantics (POSIX paths for non-Yazi tools) versus Yazi's in-process `sftp://` addressing — that decides whether rclone/macFUSE join the fabric at all, and whether F12's `paths`/`read-only` fields have a second consumer beyond Yazi.
- WezTerm side coverage: whether `resurrect.wezterm` or an `awesome-wezterm` session package adds anything over `forge-workspace` + Zellij resurrection, or whether deck.lua float persistence and the workspace bridge already cover it.
- rclone integration: mount readiness/daemonization under launchd without host `sudo`, and whether a declarative rclone SFTP remote can reuse the same `config.forge.ssh.hosts` row source so F12 stays single-source across Yazi and rclone.
