# macOS Window/Tiling & Automation Stack: Yabai, SKHD, Karabiner-Elements (+GokuRakuJoudo), Hammerspoon

This report distills practical configuration, real event hooks, and best‑practice patterns for a robust, KISS-leaning macOS setup. Sources: official GitHub docs/wikis, APIs, and common production patterns.


## 1) High-level Roles
- Yabai: BSP tiling/stacking/floating window manager controller (CLI-driven).
- SKHD: Low-latency hotkey daemon mapping chords → shell commands (often yabai).
- Karabiner-Elements: Low-level keyboard remapping, layers/modes, per-app/device, variables.
- GokuRakuJoudo (goku): EDN DSL → generates `karabiner.json` (faster authoring, fewer JSON footguns).
- Hammerspoon: Lua automation Swiss army knife; event watchers, window filters, scripting yabai, stateful logic.


## 2) Core Installation + Permissions
- Homebrew: `brew install koekeishiya/formulae/yabai koekeishiya/formulae/skhd hammerspoon`
- Yabai scripting addition (optional, unlocks extra features): requires disabling SIP partially; see yabai wiki. Auto-load on Dock restart via signal.
- Accessibility permissions: grant to Yabai, SKHD, Karabiner-Elements, Hammerspoon.
- Launch agents: `brew services start yabai`, `brew services start skhd`; Hammerspoon launches as app.


## 3) File Locations
- Yabai: `~/.yabairc` (executable). Uses `yabai -m <domain> <subcmd> …` lines.
- SKHD: `~/.skhdrc` hotkeys DSL.
- Karabiner: `~/.config/karabiner/karabiner.json` (or generate via goku from `~/.config/karabiner/karabiner.edn`).
- Hammerspoon: `~/.hammerspoon/init.lua` (+ modules/spoons in `~/.hammerspoon/` and `~/.hammerspoon/Spoons/`).


## 4) Yabai Configuration (practical subset)
- Layout: `yabai -m config layout bsp|stack|float`; `split_ratio 0.5`; `auto_balance on|off`.
- Gaps/Padding: `top_padding`, `bottom_padding`, `left_padding`, `right_padding`, `window_gap`.
- Focus + mouse: `focus_follows_mouse [autoraise|off]`; `mouse_follows_focus on|off`.
- Window behaviors: `window_shadow on|off`, `window_opacity_duration`, `window_animation_duration`, `window_animation_frame_rate`, `window_zoom_persist`.
- Origin display: `window_origin_display first|mouse|focused|…`.
- Rules (matchers → properties): match by `app=`, `title=`, `role=`, `subrole=`, etc.; set `manage=on|off`, `space=`, `display=`, `float=on`, `sticky=on`, `opacity=`, `scratchpad='<LABEL>'`, `border=on`, etc. Order matters (last wins). Keep rules minimal, specific.
- Scratchpads: on rule with `scratchpad='term'`; toggle via `yabai -m window --scratchpad 'term'` or `--toggle term`.
- Queries: `yabai -m query --windows`, `--spaces`, `--displays`, `--windows --window` (JSON for scripting).


## 5) Yabai Signals (real/viable events)
Register: `yabai -m signal --add event=<EVT> [label=…] [app=… title=…] action='<cmd>'`

Common events seen in production (names as used by signals):
- application_activated, application_deactivated, application_launched, application_terminated
- window_created, window_destroyed, window_focused, window_title_changed, window_moved, window_resized, window_minimized, window_deminimized, window_fullscreened, window_unfullscreened
- space_changed, space_created, space_destroyed, space_moved, space_renamed (depending on version)
- display_changed, display_added, display_removed, display_moved, display_resized
- dock_did_restart (use to re-load scripting addition)

Notes:
- Use `yabai -m signal --list` to inspect; `--remove <index>` to delete.
- Signals execute after yabai’s internal handling; prefer rules for initial placement when possible to avoid flicker. For creation-time overrides, keep handlers fast and idempotent.


## 6) SKHD Essentials
- Syntax: `<mods> - <key> : <shell command>`; supports blocks for app-conditional, modes, passthrough.
- Modifiers: `cmd`, `alt`, `ctrl`, `shift`, `fn`; combos like `cmd + alt - k`.
- Modes: create modal keymaps for “resize”, “move”, etc. Exit on `esc`.
- App-conditional blocks: pattern → command; `* ~` to passthrough.
- Simulate keystrokes: `skhd -k "cmd+alt-d"`.
- Hot reload: editing `~/.skhdrc` auto-applies.

Example focus/move bindings:
- `alt - h : yabai -m window --focus west`
- `alt - j : yabai -m window --focus south`
- `alt - k : yabai -m window --focus north`
- `alt - l : yabai -m window --focus east`
- `shift + alt - h : yabai -m window --swap west`


## 7) Karabiner-Elements (KE) in practice
- Layers/modes with variables: set with `set_variable` or CLI `karabiner_cli --set-variables '{"in-js":1}'`.
- Conditions: `frontmost_application_if/unless`, `device_if/unless`, `input_source_if/unless`, `keyboard_type_if/unless`, `variable_if/unless`, `event_changed_if/unless`.
- Manipulators: `type: basic|mouse_key|…`, `from`, `to`, `to_if_alone`, `to_if_held_down`, `to_after_key_up`, `to_delayed_action`, `conditions`, `parameters`.
- Simultaneous keys and simlayers (press/hold combos) enable powerful mode triggers without losing normal typing.

Recommended uses:
- Hardware-level normalization (caps → ctrl/esc tap-hold, swap cmd/ctrl on PC boards).
- App-specific overrides using `frontmost_application_*`.
- Short, focused rules; avoid over-broad matchers that cause flicker with yabai-managed windows.


## 8) GokuRakuJoudo (goku) highlights
- Author KE in EDN `karabiner.edn`, compile to JSON: `goku`.
- Sections: `:profiles` (timings), `:templates` (shell command templates), `:layers`/`:simlayers` (mode keys), `:froms` (predefined inputs), `:main` (rules lists), `:devices`, `:applications`, `:input-sources`.
- Simlayers for character-keys-as-modifiers (e.g., hold `w` to enter launch mode) with minimal JSON verbosity.
- Inline conditions and modular organization keep configs maintainable.


## 9) Hammerspoon: Watchers and Windows
Key watcher modules for real events:
- hs.application.watcher: launched, terminated, activated, deactivated, hidden, unhidden
- hs.window.filter: windowCreated, windowDestroyed, windowFocused, windowUnfocused, windowMoved, windowVisible, windowNotVisible, windowMinimized, windowUnminimized, windowTitleChanged
- hs.spaces.watcher: space changes (active screen/space when Separate Spaces is on)
- hs.screen.watcher: screen layout/active screen changes
- hs.usb.watcher: device added/removed
- hs.audiodevice.watcher: default input/output/system, device changes
- hs.caffeinate.watcher: system wake, sleep, screens, power events
- hs.eventtap: low-level input events (key/mouse) with filters

Window control helpers:
- hs.window, hs.layout, hs.grid, hs.geometry; hs.window.filter for declarative window event handling.

Bridge to yabai:
- `hs.task.new('/usr/local/bin/yabai', ...)` or `hs.execute('yabai -m …')` for robust calls.
- Use queries `yabai -m query … | jq` and feed into Lua logic for stateful automations.


## 10) Integration Patterns (battle-tested)
- SKHD → Yabai: bind focus/move/resize/space commands; keep chords memorable; prefer modal maps for bulk ops.
- KE/goku → high‑level layers: create ergonomic layers that emit keystrokes SKHD listens to, or directly run scripts where appropriate.
- Hammerspoon orchestrates:
  - App/space/display automation via watchers (e.g., pin Slack to Space 4 on launch, relabel spaces, enforce layouts on display add/remove).
  - Recovery hooks: on `dock_did_restart` via yabai signal, re-load SA; on screen watcher changes, re-apply padding/gaps/layout.
  - State machine: maintain Lua state for modes, rate-limit external calls, avoid event feedback loops.


## 11) Best Practices (KISS, stable, fast)
- Keep rules before signals: prefer Yabai rules to place/manage windows at creation; signals for notifications or follow-up tweaks only.
- Idempotency: make handlers safe to run repeatedly; avoid racey `sleep` chains.
- Minimal scope selectors: match on `app` and precise `title`/`role`/`subrole`; avoid blanket `title=^$` that hits ephemeral popups.
- Bounded work in event handlers: use tiny shell/Lua helpers; offload heavier work to background scripts.
- Logging & debug: centralize logs (`/tmp/yabai.log`, `~/.hammerspoon/console.log`), add labels to signals, and provide `--list`/diagnostic keybindings.
- SIP/SA: only enable features you need; guard `--load-sa` via `dock_did_restart` signal.
- Launch order: start yabai before skhd; Hammerspoon last. Re-emit rules/signals on reload.
- Version pinning: brew pin critical tools; track changelogs for breaking changes (event names/options can evolve).


## 12) Example Snippets (concise)
Yabai signals (reload SA after Dock restarts):
- `yabai -m signal --add event=dock_did_restart action='sudo yabai --load-sa'`

Rules (scratchpad + role filters):
- `yabai -m rule --add app='^iTerm2$' scratchpad='term'`
- `yabai -m rule --add role='AXDialog' manage=off`

SKHD focus/swap:
- `alt - h : yabai -m window --focus west`
- `shift + alt - h : yabai -m window --swap west`

Goku simlayer launch-mode (EDN):
- `:simlayers {:launch-mode {:key :w}}` with rules mapping `w+k` → open Emacs, `w+l` → open Chrome.

Hammerspoon windowCreated hook:
```lua
local wf = hs.window.filter.new():setDefaultFilter{}
wf:subscribe(hs.window.filter.windowCreated, function(win)
  hs.execute("yabai -m window --grid 2:2:0:0:1:2") -- example action
end)
```


## 13) Quick Capability Matrix
- Yabai: tiling/stacking/floating control; rules; signals; queries; scratchpads; per-space configs; animations.
- SKHD: fast hotkeys; modes; app-conditional remaps; keystroke synthesis; live reload.
- Karabiner: hardware-level remap; conditions; variables; simlayers; per-device/app.
- Goku: ergonomic authoring for Karabiner JSON with profiles, simlayers, templates.
- Hammerspoon: Lua runtime, rich watchers, window/grid/layout libs, shell/task bridge, spork for complex logic.


## 14) References
- Yabai: repo/wiki, `man yabai`, CHANGELOG highlights (signals, rules, animations)
- SKHD: https://github.com/koekeishiya/skhd
- Karabiner JSON docs (conditions/manipulators/variables): https://karabiner-elements.pqrs.org/docs/json/
- GokuRakuJoudo: https://github.com/yqrashawn/GokuRakuJoudo
- Hammerspoon API: https://www.hammerspoon.org/docs/ (watchers: application, window.filter, screen, spaces, usb, audiodevice, caffeinate)

