# Parametric Forge WezTerm Guide

This document captures how our WezTerm environment is assembled, the helper tools that orbit it, and the conventions you should remember the next time you revisit the setup. It focuses on the configuration under `01.home/00.core/configs/apps/wezterm`, the Yazi file manager that we launch from the terminal, and the `wezterm-utils` integration script that glues everything together. Expect roughly a thousand words of institutional memory—annotated shortcuts, plugin behaviour, and a mental model for how workspaces move between WezTerm, Yazi, and yabai.

## 1. Configuration Layout

The entry point is `wezterm.lua`, which constructs a config builder and then composes several slim modules:

- `appearance.lua` - visual palette, fonts, padding, cursor.
- `behavior.lua` - shell, command palette styling, bell policies, performance caps.
- `icons.lua` - Nerd Font lookups for process, directory, and UI glyphs.
- `keys.lua` - modal key tables (`Ctrl+w`/`Ctrl+g`), workspace and resurrect actions.
- `mouse.lua` - click, scroll, and selection gestures.
- `tabs.lua` - status bar, tab title formatting, and mode indicator logic.

Two WezTerm plugins are required up front:

1. [`smart_workspace_switcher.wezterm`](https://github.com/MLFlexer/smart_workspace_switcher.wezterm) for fuzzy workspace navigation and creation.
1. [`resurrect.wezterm`](https://github.com/MLFlexer/resurrect.wezterm) to snapshot and restore sessions.

`wezterm.lua` sets up periodic workspace autosaves (every 15 minutes), trims resurrect's captured scrollback to 500 lines for performance, and registers three plugin events:

- `smart_workspace_switcher.workspace_switcher.chosen` - forwards the selected workspace name to yabai via `wezterm-utils`.
- `smart_workspace_switcher.workspace_switcher.created` - attempts to resurrect the workspace state; if no state is saved, it simply labels the yabai space.
- `smart_workspace_switcher.workspace_switcher.selected` - saves the workspace before switching away so the last state stays current.

## 2. Visual Identity (`appearance.lua`)

The terminal theme is a tuned version of **Dracula (base16)**. Fonts fall back gracefully: GeistMono Nerd Font → Iosevka Nerd Font → Symbols Nerd Font (Mono first, then proportional). Font size is 12pt with a compact 0.85 line height. Cursors use a reverse-video blinking bar with a 250 ms cadence, and pane backgrounds desaturate for inactive panes.

Mac windows are translucent (`window_background_opacity = 1.0` plus a 20px blur) with padding (15px left/right, 5px top/bottom). Tab styling is fully custom: fancy tabs are disabled, background glass is `rgba(40, 42, 54, 0.75)`, and active tabs invert to cyan foreground with a dark Dracula background so focused editors remain legible. Host-specific colouring exists for future remote domains (`prod`, `staging`, `dev`) and is consumed in `tabs.lua`.

## 3. Runtime Behaviour (`behavior.lua`)

Shells launch as `/bin/zsh -l`. Hot reload is enabled (`automatically_reload_config = true`), and macOS fullscreen relies on the native transition to avoid the old cocoa animation. We enable kitty keyboard protocol for better TUI support and opt into `WebGpu` with both max and animation FPS capped at 120. Scrollback holds 5000 lines. Bells are entirely visual, using a 150 ms ease-in/out to tint the background.

The command palette inherits Dracula colours, renders 10 rows, and shares the main font size. Window close prompts are suppressed for typical shells (`bash`, `zsh`, `fish`, `tmux`, etc.).

## 4. Tabs, Status, and Modes (`tabs.lua`)

`tabs.lua` centralises UI feedback:

- **Mode detector**: The left status reads `[MODE]` in colour. Named modes exist for key tables (`COPY`, `WINDOW`, `WORKSPACE`, `SEARCH`), plus a `VISUAL` state if text is highlighted outside copy-mode. If the pane is in the alternate screen, we display `ALT` unless the foreground process is a known TUI (nvim, yazi, lazygit, etc.). Unknown key tables render their uppercase name.
- **Tab titles**: Each tab starts with its index. If the user renamed the tab (`tab_title`), that wins. Otherwise we attempt to fetch the foreground process icon (from `icons.lua`), then fall back to the working directory. Directories are shortened (`…/leaf` for deep paths) and labelled with icons for common roots (~/Development, ~/.config, git repos). Zoomed panes append a magnifier glyph.
- **Status bar**: Right-aligned status is `cwd | workspace | host`. CWD shrinks to a tilde where appropriate and recognises special folders and git repos. Workspaces compress to 12 characters. Hostnames are truncated at the first dot. Failures in pane APIs are wrapped in `pcall` so status updates never throw.
- **Git detection**: We check `git -C <cwd> rev-parse --git-dir` with a five-second cache to avoid repeated subprocesses during status updates. Shell injection is impossible because we pass arguments vector-style via `wezterm.run_child_process`.

## 5. Keyboard Surfaces (`keys.lua`)

### 5.1 Modal Prefixes

- `Ctrl+w` → window table (mirrors Vim’s `<C-w>`). After pressing the prefix:
  - `h/j/k/l` focus panes; `H/J/K/L` resize in three-cell increments.
  - `s` splits below, `v` splits right (same orientation as the Cmd+D / Cmd+Shift+D shortcuts).
  - `c` enters copy mode; `t` opens a new tab; `y` spawns Yazi in a fresh tab; `o` closes the current pane; `z` toggles pane zoom.
  - `q` cancels without performing an action.
- `Ctrl+g` → workspace table (aligns with Yazi’s `g` workflows).
  - `g` opens the smart workspace switcher; `l` hops back to the previous workspace; `w` surfaces WezTerm’s built-in workspace launcher.
  - `n` creates a new workspace; `r` renames the current workspace.
  - `s` saves via Resurrect; `S` opens the Resurrect loader (Enter restores, `q` cancels); `y` spawns Yazi in a new tab; `q` cancels.

Behind the scenes the plugins emit events that `wezterm.lua` listens for, keeping workspace snapshots current and yabai spaces labelled/focused via `wezterm-utils`.

### 5.2 Copy Mode

`Ctrl+w c` enters copy mode. Movement is Vim-like, `v/V/CTRL+v` switch selection types, `y` yanks to both the system clipboard and primary selection, and `q` exits. While copy mode is active the status badge shows `[COPY]`; highlighting text outside copy mode presents as `[VISUAL]` so you know the terminal is still interactive.

### 5.3 Direct Shortcuts

- Cmd+T / Cmd+W → new/close tab (iTerm muscle memory).
- Cmd+D / Cmd+Shift+D → split panes right/below (unchanged).
- Cmd+numbers → select tabs directly; Option+Tab cycles forward and Ctrl+Tab cycles backward.
- Cmd+Shift+F → WezTerm search; Cmd+F opens the command palette pre-filtered for search.
- Ctrl+Arrow keys or Cmd+Option+HJKL → focus panes; Ctrl+Shift+Arrow or Cmd+Shift+HJKL → resize.
- Cmd+Option+Z → toggle pane zoom; Cmd+Shift+K → clear scrollback.

### 5.4 System Clipboard Overrides

Option still emits literal characters, Cmd+C/V map to copy/paste, and the command palette remains on Cmd+K. Copy-mode yanks continue to target both the system clipboard and the primary selection for seamless TUI↔GUI transfers.

## 6. Mouse Defaults (`mouse.lua`)

- ⌘ + Left click releases to open URLs.
- ⌘ + scroll adjusts font size.
- Scroll wheel without modifiers moves three lines at a time.
- Middle click pastes the primary selection; right release copies to clipboard and primary selection.
- Double-click selects words, triple-click selects lines.

`bypass_mouse_reporting_modifiers = "SHIFT"` forwards Shift+drag to TUI apps while retaining our own bindings for plain gestures.

## 7. WezTerm ↔ Yabai Bridge (`wezterm-utils.sh`)

`01.home/02.assets/bin/wezterm-utils.sh` is a bash helper that coordinates WezTerm CLI actions and yabai. Key commands:

- `spawn-workspace <name> [cwd]` - creates a WezTerm workspace tab and optionally focuses the matching yabai space.
- `switch-workspace <name>` - purely switches WezTerm's workspace (also focuses yabai when available).
- `space-label <label>` - applies a label to the current yabai space.
- `focus-space <label>` - focuses a yabai space by label.
- `workspace-change <name>` - internal hook used when the plugin tells us a workspace changed; focuses or creates the yabai space and labels it.

Environment variables make the script flexible: `WEZTERM_BIN` to override the CLI path, `WEZTERM_UTILS_DISABLE_YABAI` to skip yabai calls, `WEZTERM_UTILS_VERBOSE` for debug logging. All yabai calls are soft-failed with warnings so the terminal keeps working even if yabai is offline.

## 8. Yazi Integration (`01.home/00.core/configs/apps/yazi`)

### 8.1 Launching and Workspaces

Inside Yazi, `Ctrl+N` (or the `Ctrl+g n` alias) runs `wezterm-utils spawn-workspace` for the current directory—mirroring `Ctrl+w y`, which launches Yazi from WezTerm. Together they allow either tool to create a dedicated terminal workspace for the project you are browsing.

### 8.2 Plugin Loadout

`init.lua` loads a curated plugin set via `safe_setup` (failures become toast notifications):

- **UI/UX**: `full-border` (rounded frame), `starship` prompt alignment, and `system-clipboard` to keep copy/cut in sync with the macOS clipboard.
- **Source control**: `git` status badges, `lazygit`, and `git-files` for narrowed views.
- **Navigation**: `projects` (predefined roots), `cdhist`, `easyjump`, `smart-tab`, and `smart-switch` (custom plugins in `plugins/` to grow/switch tabs on demand).
- **Content management**: `smart-paste`, `toggle-pane`, `command-palette`, `whoosh` (quick search), `recycle-bin`, `restore`, `mactag`, `compress`, `sudo`, `rsync`, and `sshfs` support.

### 8.3 Manager Profile

`yazi.toml` emphasises readability: pane ratios [1,5,3], natural sort, hidden files off by default, and a modification-time line mode. Previewers cover text, code, archives, fonts, PDFs, media, and disk images with tuned image settings for WezTerm (30 ms delay, 512 MB cap). Opener groups point to `$EDITOR`, VS Code, Finder, MPV, and Quick Look. Task pools are sized to 10 workers each, and all prompt dialogs are positioned consistently (top-centre for input, centre for confirmations).

### 8.4 Keymap Highlights

A sampling of custom bindings defined in `keymap.toml`:

- `!` → run an arbitrary shell command in place; `Ctrl+T` → open a shell inside Yazi.
- `o x` → extract archives via 7zz; `o c` → compress through the plugin.
- `g g` → launch lazygit; `g d` → diff hovered vs selected.
- `Ctrl+C/X/V` → copy/cut/paste through system clipboard.
- `Ctrl+N` / `Ctrl+g n` → spawn a WezTerm workspace (see §8.1).
- `p` → smart paste into hovered directory; `P` → toggle the preview pane.
- `Ctrl+P` → Quick Look preview.
- `Option+K` → command palette.
- Numeric keys `1-9` → smart tab switching (create on demand); `t` → open hovered directory in a new tab.
- Navigation upgrades: `l` smart-enter (skip single-child directories), `h` smart leave, `J` easyjump, `H` directory history, `g p` projects list, `g f` restrict to git-tracked files.
- Trash workflow: `g t` open trash, `u` undo delete, `R r/d/e/D` restore or purge items.
- macOS tags: `T a` add, `T r` remove.
- Sudo rescue: `S r` rename with sudo, `S p` paste with sudo.

All inputs and confirm dialogs share consistent offsets so prompts appear in predictable places.

## 9. Daily Flow

1. **Start WezTerm**: default workspace is `default`. Use `Ctrl+w y` to launch Yazi or `Ctrl+g g` to invoke the smart workspace switcher.
1. **Within Yazi**: browse with the enhanced navigation. When you want a new terminal context, hit `Ctrl+N` (or `Ctrl+g n`) to spawn a WezTerm workspace matching the current directory. Use `g g` for lazygit or `o x` to extract archives; clipboard shortcuts remain macOS-native.
1. **Workspace hygiene**: autosave runs every 15 minutes, but you can press `Ctrl+g s` after significant changes. If yabai is running, switching workspaces keeps WezTerm and macOS spaces aligned via `wezterm-utils`.
1. **Restoring sessions**: `Ctrl+g S` brings back prior layouts from JSON snapshots. Because we limit scrollback to 500 lines, restores stay snappy.

## 10. Extending and Troubleshooting

- Override `WEZTERM_UTILS_BIN` if you install the helper script elsewhere. Set `WEZTERM_UTILS_DISABLE_YABAI=1` when testing without yabai.
- All Lua modules are defensive: failures in `pane:get_current_working_dir()` or git probes are wrapped in `pcall`. Status bars fall back to safe defaults.
- To add a new icon, update `icons.lua` (processes or directories) and it will flow into tabs and status chips automatically.
- Additional Yazi plugins belong in `package.toml`. Remember to call `safe_setup` in `init.lua` to surface load errors cleanly.

Armed with this overview you should be able to re-enter the workflow quickly: recall the leader sequences, know how WezTerm/Yazi/yabai coordinate, and understand where to tweak fonts, prompts, or integrations as the Parametric Forge evolves.
