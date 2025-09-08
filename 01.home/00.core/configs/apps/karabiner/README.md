# Parametric Forge — Karabiner-Elements + Goku Foundation

Title         : Karabiner README
Author        : Bardia Samiee
Project       : Parametric Forge
License       : MIT
Path          : /01.home/00.core/configs/apps/karabiner/README.md
-----------------------------------------------------------------------------

This directory provides a complete, production-grade foundation for Karabiner-Elements with GokuRakuJoudo (EDN → JSON). It focuses on clean leader keys and a clear scaffold to extend with layers and app-specific rules without confusion.

## Summary

- Source of truth: `~/.config/karabiner.edn` (managed in repo: `01.home/00.core/configs/apps/karabiner/karabiner.edn`)
- Generator: GokuRakuJoudo (`goku`/`gokuw`) compiles EDN → `~/.config/karabiner/karabiner.json`
- Leaders only (no unusual alone behavior):
  - Hyper  (Right Command) → ⌘⌥⌃⇧ (cmd+opt+ctrl+shift)
  - Super  (Right Option)  → ⌘⌥⌃   (cmd+opt+ctrl)
  - Power  (Right Shift)   →  ⌥⌃⇧   (opt+ctrl+shift)
- Optional complex_modifications seed: `assets/complex_modifications/parametric-forge.json` (toggleable in Karabiner UI)

## Deployment & XDG

- Files are deployed to `${XDG_CONFIG_HOME}` via Home Manager.
- 01.home/xdg.nix ensures the following dirs exist:
  - `${XDG_CONFIG_HOME}/karabiner`
  - `${XDG_CONFIG_HOME}/karabiner/assets/complex_modifications`
- Activation hook compiles EDN → JSON (if `goku` is installed):
  - `home.activation.gokuCompileKarabiner` runs `goku` with `GOKU_EDN_CONFIG_FILE="$XDG_CONFIG_HOME/karabiner.edn"`.

## Services & Resilience

- Optional: run `brew services start goku` to watch EDN changes and recompile automatically (`gokuw` under the hood).
  - Logs: `~/Library/Logs/goku.log`
  - Stop: `brew services stop goku`
- We do not auto-start the service in Nix to avoid surprise; activation compiles once for deterministic builds.

## Security / Permissions

Karabiner-Elements requires:
- Input Monitoring (karabiner_grabber; historically karabiner_observer)
- Accessibility (Assistive)
- Virtual HID device manager approval (System Settings → Extensions)

We add TCC entries in `00.system/darwin/settings/security.nix` (scripted injection; requires SIP reduced) for:
- `org.pqrs.Karabiner-Elements` (app bundle)
- `/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_grabber`
- `/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_observer`

Goku does not require special permissions.

## Leader Policy

- Leaders are mapped at the OS level via Karabiner (low-level), producing stable chords:
  - Hyper: `cmd+alt+ctrl+shift`
  - Super: `cmd+alt+ctrl`
  - Power: `alt+ctrl+shift`
- Downstream tools (skhd, hammerspoon) bind to these chords only; no direct raw right-modifier handling.
- This keeps roles clear and avoids duplication.

## How to Extend (EDN)

EDN file: `~/.config/karabiner/karabiner.edn` (this repo provides a clean scaffold).

- Profiles: we use `:Default` with sensible thresholds (`:alone`, `:held`, `:sim`).
- Templates: pre-defined `:sh`, `:yabai`, `:hs` for future shell / window / hs actions.
- Main rules: leaders only. Add new rules in `:main` as we expand.

### Example: add a Hyper-based swap-left (yabai)

```edn
{:templates {:yabai ["/usr/bin/env" "sh" "-lc" "yabai -m %s"]}
 :main
 [{:des "Window ops"
   :rules [[:!COTSh :yabai "window --swap west"]]}]}
```

- `:!COTS` stands for cmd+opt+ctrl+shift (Hyper) modifiers.
- Keys use Karabiner names (e.g., `:h`, `:left`, `:return_or_enter`, etc.)

### Layers (simlayers)

For modal-like layers based on holding a key:

```edn
{:simlayers {:nav {:key :spacebar}}
 :main
 [{:des "Nav layer (hold spacebar)"
   :rules [
     [:nav :left_arrow :left]   ;; when in :nav layer, pressing :left triggers :left_arrow
     [:nav :right_arrow :right]
   ]}]}
```

- `:simlayers` define transient layers; use descriptive names.
- You can then add `[:nav <to> <from>]` rules under `:main`.

### Per-App Conditions

Add `:applications` map and use conditions in rules:

```edn
{:applications {:vscode ["^com.microsoft.VSCode$"]}
 :main
 [{:des "App-specific"
   :rules [[:!CT1 [:yabai "space --focus 1"] :vscode]]}]}
```

- Start with leaders and global behavior; introduce app conditions purposefully.

## JSON and UI Rules

- Goku compiles EDN → `karabiner.json`. Do not hand-edit JSON; the UI will overwrite comments and can conflict with EDN.
- Keep optional UI-importable rules in `assets/complex_modifications`. We provide `parametric-forge.json` as a tiny seed.

## Style & Structure

- Keep EDN small and readable; split by domain if it grows (e.g., `leaders.edn`, `layers.edn`, `apps.edn`) and merge offline before compilation, or place everything within one EDN responsibly.
- Use descriptive `:des` for each ruleset.
- Avoid `to_if_alone` unless strictly required (we prefer predictable leaders).

## Troubleshooting

- Karabiner-Elements not responding:
  - Verify System Settings → Privacy & Security: Input Monitoring + Accessibility enabled for Karabiner.
  - Approve “Karabiner-VirtualHIDDevice-Manager” extension.
- `karabiner.json` missing:
  - Run `goku` manually, or `brew services start goku` to watch.
- Conflicts:
  - Ensure no other hotkey tool is binding the same chords. Our skhd binds are designed to consume Hyper/Super only.

## Notes

- We intentionally do not deploy `karabiner.json` from this repo to avoid symlink overwrite by Karabiner UI. EDN is the source of truth.
- SKHD and Hammerspoon are refactored to rely solely on the leader chords, eliminating duplication and drift.

-----------------------------------------------------------------------------

This foundation should let you add leaders, layers, and per-app rules quickly and safely without rework.
