-- Title         : keys.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : modules/home/programs/apps/wezterm/keys.lua
-- ----------------------------------------------------------------------------
-- Full-pass keyboard: default assignments disabled so every Zellij chord
-- (Hyper/Super leader stacks from karabiner, bare Super t / Super w) reaches
-- the pty. WezTerm claims native left-Command chords only — the outer-terminal
-- layer sanctioned by the chord owner (modules/home/programs/apps/chords.nix).

local wezterm = require("wezterm")
local act = wezterm.action
local behavior = require("behavior")

local M = {}

function M.setup(config)
  -- Alt Key Configuration ----------------------------------------------------
  config.send_composed_key_when_left_alt_is_pressed = false
  config.send_composed_key_when_right_alt_is_pressed = false

  -- Quick Select + launcher: nightly fields extend stable values behind the
  -- shared predicate; the bind rows below stay identical either way.
  local launcher = { flags = "FUZZY|COMMANDS|KEY_ASSIGNMENTS" }
  local quick_select = act.QuickSelect
  if behavior.has_nightly then
    quick_select = act.QuickSelectArgs({ skip_action_on_paste = true })
    launcher.title = "forge launcher"
    launcher.help_text = "Enter=run  Esc=cancel  /=filter"
    launcher.fuzzy_help_text = "Launcher (commands + keys): "
  end

  -- Native Layer (left Command) ----------------------------------------------
  config.disable_default_key_bindings = true
  config.keys = {
    -- Clipboard / window / font: native macOS vocabulary
    { key = "c", mods = "CMD", action = act.CopyTo("Clipboard") },
    { key = "v", mods = "CMD", action = act.PasteFrom("Clipboard") },
    { key = "n", mods = "CMD", action = act.SpawnWindow },
    { key = "q", mods = "CMD", action = act.QuitApplication },
    { key = "h", mods = "CMD", action = act.HideApplication },
    { key = "m", mods = "CMD", action = act.Hide },
    { key = "=", mods = "CMD", action = act.IncreaseFontSize },
    { key = "-", mods = "CMD", action = act.DecreaseFontSize },
    { key = "0", mods = "CMD", action = act.ResetFontSize },
    { key = "r", mods = "CMD", action = act.ReloadConfiguration },

    -- Outer-terminal capability layer: palette, unicode, diagnostics,
    -- quick select, launcher
    { key = "p", mods = "CMD|SHIFT", action = act.ActivateCommandPalette },
    { key = "u", mods = "CMD|SHIFT", action = act.CharSelect },
    { key = "d", mods = "CMD|SHIFT", action = act.ShowDebugOverlay },
    { key = "Space", mods = "CMD|SHIFT", action = quick_select },
    { key = "l", mods = "CMD|SHIFT", action = act.ShowLauncherArgs(launcher) },
  }
end

return M
