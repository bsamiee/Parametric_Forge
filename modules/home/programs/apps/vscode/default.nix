# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/vscode/default.nix
# ----------------------------------------------------------------------------
# VS Code as a first-class theme+font consumer: the palette owner projects
# workbench colors, terminal ANSI, textMate scopes, AND semantic-token rules;
# the font owner projects editor+terminal typography (family chain, ligature
# features, line metrics). Everything lands through a sentinel-managed block
# in the JSONC user settings; managed keys are stripped from the user region
# so later-wins JSONC resolution cannot shadow the owners. Every other key
# and comment stays app- and user-owned.
# Extension-source policy (overlays/manifest.nix `extensions.vscode`): the
# declared source is the nix-vscode-extensions registry with per-row vetting
# on the manifest security fields — never registry trust, never a Homebrew
# Brewfile lane. File icons adopt the live material-icon-theme decision;
# product icons stay default until an extension row is vetted (CA-2 lane).
{
  config,
  lib,
  ...
}: let
  t = config.forge.theme;
  f = config.forge.fonts;
  hexOf = lib.mapAttrs (_: c: c.hex);
  ansi = hexOf t.ansi16;
  s = lib.mapAttrs (_: lib.mapAttrs (_: c: c.hex)) {inherit (t.roles) surface text accent state diff ui;};

  forgeSettings = {
    # --- Typography: generated from the font owner -----------------------------
    "editor.fontFamily" = f.projections.vscodeFamily;
    "editor.fontSize" = builtins.floor f.metrics.size;
    "editor.fontLigatures" = f.features.vscode;
    "editor.fontVariations" = false; # static primary; fractional axes are a variable-font lever
    "editor.lineHeight" = f.metrics.editorLineHeight;
    "terminal.integrated.fontFamily" = f.projections.vscodeFamily;
    "terminal.integrated.fontSize" = builtins.floor f.metrics.size;
    "terminal.integrated.fontLigatures.enabled" = false;
    "terminal.integrated.lineHeight" = 1.0;
    "terminal.integrated.fontWeight" = "normal";
    "terminal.integrated.fontWeightBold" = "bold";
    "workbench.iconTheme" = "material-icon-theme";

    # --- Editing law: house style (4-space, 150-col) ----------------------------
    # Globals stay shadowable by user-region keys (none exist top-level today);
    # [yaml] binds the yamlfmt extension (spawns PATH yamlfmt, cwd = workspace,
    # so project .yamlfmt wins before the XDG global) — an unbound YAML slot
    # falls to Prettier, which ignores every yamlfmt config. [nix] stays on
    # alejandra's 2-space so owners never fight.
    "editor.tabSize" = 4;
    "editor.insertSpaces" = true;
    "editor.rulers" = [150];
    "files.insertFinalNewline" = true;
    "files.trimTrailingWhitespace" = true;
    # prettier.* rows are the esbenp extension's no-config fallback, mirroring
    # the XDG prettierrc so the extension lane matches the CLI wrapper.
    "prettier.tabWidth" = 4;
    "prettier.printWidth" = 150;
    "[yaml]" = {
      "editor.defaultFormatter" = "bluebrown.yamlfmt";
      "editor.tabSize" = 4;
      "editor.insertSpaces" = true;
      "editor.detectIndentation" = false;
    };
    "[nix]" = {
      "editor.tabSize" = 2;
      "editor.detectIndentation" = false;
    };

    # --- Workbench: elevation ladder + role projection --------------------------
    "workbench.colorCustomizations" = {
      "editor.background" = s.surface.base;
      "editor.foreground" = s.text.primary;
      "editorLineNumber.foreground" = s.text.subtle;
      "editorLineNumber.activeForeground" = s.accent.primary;
      "editorCursor.foreground" = s.ui.cursor;
      "editor.lineHighlightBackground" = s.surface.raised;
      "editor.selectionBackground" = s.surface.selected;
      "editor.findMatchBackground" = s.ui.match;
      "editor.findMatchHighlightBackground" = s.ui.search;
      "editorIndentGuide.background1" = s.surface.selected;
      "editorIndentGuide.activeBackground1" = s.text.subtle;
      "editorWhitespace.foreground" = s.ui.whitespace;
      "editorWidget.background" = s.surface.overlay;
      "editorWidget.border" = s.ui.border;
      "editorHoverWidget.background" = s.surface.overlay;
      "editorSuggestWidget.background" = s.surface.overlay;
      "editorSuggestWidget.selectedBackground" = s.surface.selected;
      "quickInput.background" = s.surface.overlay;
      "activityBar.background" = s.surface.crust;
      "activityBar.foreground" = s.accent.primary;
      "activityBar.inactiveForeground" = s.text.subtle;
      "activityBarBadge.background" = s.accent.secondary;
      "activityBarBadge.foreground" = s.text.inverse;
      "sideBar.background" = s.surface.crust;
      # Undecorated explorer rows inherit sideBar.foreground (no list.foreground
      # token exists); primary keeps unchanged files bright, git states recolor.
      "sideBar.foreground" = s.text.primary;
      "sideBarTitle.foreground" = s.text.primary;
      "sideBarSectionHeader.background" = s.surface.crust;
      "statusBar.background" = s.surface.surface;
      "statusBar.foreground" = s.text.subtle;
      "statusBar.noFolderBackground" = s.surface.surface;
      "statusBar.debuggingBackground" = s.state.attention;
      "statusBar.debuggingForeground" = s.text.inverse;
      "titleBar.activeBackground" = s.surface.crust;
      "titleBar.activeForeground" = s.text.subtle;
      "editorGroupHeader.tabsBackground" = s.surface.surface;
      "tab.activeBackground" = s.surface.base;
      "tab.activeForeground" = s.text.primary;
      "tab.inactiveBackground" = s.surface.surface;
      "tab.inactiveForeground" = s.text.subtle;
      "tab.activeBorderTop" = s.accent.primary;
      "panel.background" = s.surface.base;
      "panelTitle.activeForeground" = s.accent.primary;
      "panelTitle.inactiveForeground" = s.text.subtle;
      "badge.background" = s.accent.secondary;
      "badge.foreground" = s.text.inverse;
      "list.activeSelectionBackground" = s.surface.selected;
      "list.inactiveSelectionBackground" = s.surface.raised;
      "list.hoverBackground" = s.surface.raised;
      "input.background" = s.surface.crust;
      "input.border" = s.surface.selected;
      "dropdown.background" = s.surface.overlay;
      "focusBorder" = s.accent.primary;
      "diffEditor.insertedLineBackground" = s.diff.add;
      "diffEditor.insertedTextBackground" = s.diff.addEmph;
      "diffEditor.removedLineBackground" = s.diff.del;
      "diffEditor.removedTextBackground" = s.diff.delEmph;
      "gitDecoration.addedResourceForeground" = s.state.success;
      "gitDecoration.modifiedResourceForeground" = s.accent.primary;
      "gitDecoration.deletedResourceForeground" = s.state.danger;
      "gitDecoration.untrackedResourceForeground" = s.state.success;
      "gitDecoration.ignoredResourceForeground" = s.text.muted;
      "gitDecoration.renamedResourceForeground" = s.accent.tertiary;
      "gitDecoration.conflictingResourceForeground" = s.accent.secondary;
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

    # --- Tokens: textMate scopes + semantic rules from the one pivot ------------
    "editor.tokenColorCustomizations".textMateRules = t.projections.vscodeTokenRules;
    "editor.semanticTokenColorCustomizations" = {
      enabled = true;
      rules = t.projections.vscodeSemanticRules;
    };
  };

  # Managed keys are stripped from the user region (single-line scalars only);
  # the sentinel block at the top then owns them without later-wins shadowing.
  managedScalarKeys = [
    "editor.fontFamily"
    "editor.fontSize"
    "editor.fontLigatures"
    "editor.fontVariations"
    "editor.lineHeight"
    "editor.letterSpacing"
    "terminal.integrated.fontFamily"
    "terminal.integrated.fontSize"
    "terminal.integrated.fontLigatures.enabled"
    "terminal.integrated.lineHeight"
    "terminal.integrated.letterSpacing"
    "terminal.integrated.fontWeight"
    "terminal.integrated.fontWeightBold"
    "workbench.iconTheme"
  ];
  managedKeyRegex = "^[[:space:]]*\"(${lib.concatMapStringsSep "|" (k: lib.replaceStrings ["."] ["\\."] k) managedScalarKeys})\"[[:space:]]*:";

  # JSONC block asserted after the root brace; sentinels make replacement
  # idempotent and user keys outside the managed set stay untouched.
  forgeBlock = lib.concatStrings [
    "  // forge-theme:begin generated from modules/home/{theme,fonts}.nix; reasserted on switch\n"
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
    FORGE_BLOCK=$(<${config.xdg.configFile."forge/theme/vscode-settings-block.jsonc".source})
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
        inserted && $0 ~ /${managedKeyRegex}/ { next }
        { print }
      ' "$settings")
    else
      run /bin/mkdir -p "''${settings%/*}"
      merged=$(printf '{\n%s\n}' "$FORGE_BLOCK")
    fi
    case "$merged" in
      *"forge-theme:begin"*)
        if [ "$merged" != "$(/bin/cat "$settings" 2>/dev/null)" ]; then
          # Publish by in-place copy: VS Code's kqueue watcher is bound to the
          # settings inode, so a rename publishes to an inode it never observes
          # and the live window keeps stale config until reload. cp truncates
          # and rewrites the existing inode, which the watcher applies live.
          tmp=$(/usr/bin/mktemp "$settings.XXXXXX")
          printf '%s\n' "$merged" >"$tmp"
          run /bin/cp "$tmp" "$settings"
          /bin/rm -f "$tmp"
        fi
        ;;
      *)
        echo "vscode theme seed: no root brace in $settings; block not asserted" >&2
        ;;
    esac
  '';
}
