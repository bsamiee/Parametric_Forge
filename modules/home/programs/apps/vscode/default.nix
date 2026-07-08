# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/vscode/default.nix
# ----------------------------------------------------------------------------
# VS Code theme consumer: the estate palette owner projects terminal ANSI and
# textMate token colors into the JSONC user settings through a sentinel-managed
# block; every other key and comment stays app- and user-owned.
{
  config,
  lib,
  ...
}: let
  t = config.forge.theme;
  hexOf = lib.mapAttrs (_: c: c.hex);
  ansi = hexOf t.ansi16;

  forgeSettings = {
    "workbench.colorCustomizations" = {
      "terminal.background" = t.palette.background.hex;
      "terminal.foreground" = t.palette.foreground.hex;
      "terminal.selectionBackground" = t.palette.selection.hex;
      "terminalCursor.foreground" = t.palette.foreground.hex;
      "terminal.ansiBlack" = ansi.black;
      "terminal.ansiRed" = ansi.red;
      "terminal.ansiGreen" = ansi.green;
      "terminal.ansiYellow" = ansi.yellow;
      "terminal.ansiBlue" = ansi.blue;
      "terminal.ansiMagenta" = ansi.magenta;
      "terminal.ansiCyan" = ansi.cyan;
      "terminal.ansiWhite" = ansi.white;
      "terminal.ansiBrightBlack" = ansi.brightBlack;
      "terminal.ansiBrightRed" = ansi.brightRed;
      "terminal.ansiBrightGreen" = ansi.brightGreen;
      "terminal.ansiBrightYellow" = ansi.brightYellow;
      "terminal.ansiBrightBlue" = ansi.brightBlue;
      "terminal.ansiBrightMagenta" = ansi.brightMagenta;
      "terminal.ansiBrightCyan" = ansi.brightCyan;
      "terminal.ansiBrightWhite" = ansi.brightWhite;
    };
    "editor.tokenColorCustomizations".textMateRules = t.projections.vscodeTokenRules;
  };

  # JSONC block asserted after the root brace; sentinels make replacement
  # idempotent and duplicate keys resolve in the user's favor (later wins).
  forgeBlock = lib.concatStrings [
    "  // forge-theme:begin generated from modules/home/theme.nix; reasserted on switch\n"
    (lib.concatStrings (lib.mapAttrsToList (k: v: "  ${builtins.toJSON k}: ${builtins.toJSON v},\n") forgeSettings))
    "  // forge-theme:end"
  ];
  settingsPath = "${config.home.homeDirectory}/Library/Application Support/Code/User/settings.json";
in {
  # Project-agnostic projection artifacts; sibling repos consume these instead
  # of carrying color copies in workspace settings.
  xdg.configFile = {
    "forge/theme/vscode.json".text = builtins.toJSON forgeSettings;
    "forge/theme/vscode-settings-block.jsonc".text = forgeBlock;
  };

  home.activation.vscodeThemeSeed = lib.hm.dag.entryAfter ["writeBoundary"] ''
    settings=${lib.escapeShellArg settingsPath}
    FORGE_BLOCK=$(/bin/cat ${config.xdg.configFile."forge/theme/vscode-settings-block.jsonc".source})
    export FORGE_BLOCK
    if [ -s "$settings" ]; then
      merged=$(/usr/bin/awk '
        /\/\/ forge-theme:begin/ { skip = 1; next }
        /\/\/ forge-theme:end/   { skip = 0; next }
        skip { next }
        !inserted && match($0, /^[[:space:]]*\{/) {
          print substr($0, 1, RLENGTH)
          print ENVIRON["FORGE_BLOCK"]
          rest = substr($0, RLENGTH + 1)
          if (rest != "") print rest
          inserted = 1
          next
        }
        { print }
      ' "$settings")
    else
      run /bin/mkdir -p "''${settings%/*}"
      merged=$(printf '{\n%s\n}' "$FORGE_BLOCK")
    fi
    case "$merged" in
      *"forge-theme:begin"*)
        if [ "$merged" != "$(/bin/cat "$settings" 2>/dev/null)" ]; then
          tmp=$(/usr/bin/mktemp)
          printf '%s\n' "$merged" >"$tmp"
          run /bin/mv "$tmp" "$settings"
        fi
        ;;
      *)
        echo "vscode theme seed: no root brace in $settings; block not asserted" >&2
        ;;
    esac
  '';
}
