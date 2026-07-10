# Title         : appearance.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/vscode/appearance.nix
# ----------------------------------------------------------------------------
# VS Code visual projection: one function of the theme and font owners
# returning the asserted design scalars and the structured appearance rows.
# The base theme is builtin Dark Modern — always present, never an extension
# dependency — and every visible family is overridden from the palette owner,
# so the rendered workbench carries zero third-party color. Git hues bind the
# owner git vocabulary (roles.git), never per-app conventions.
{
  lib,
  t,
  f,
}: let
  hexOf = lib.mapAttrs (_: c: c.hex);
  s = t.projections.rolesHex;
  g = lib.mapAttrs (_: r: r.color) t.projections.gitHex;
  p = hexOf t.palette;
  ansi = hexOf t.ansi16;
  a = hex: alpha: hex + alpha; # #RRGGBB -> #RRGGBBAA

  # Bracket-pair cycle: six palette hues, depth-distinct, never the subtle
  # punctuation tier (colorization paints over the token rule).
  brackets = [p.cyan p.purple p.blue p.magenta p.green p.amber];
  bracketRows = prefix: alpha:
    lib.listToAttrs (lib.imap1 (i: c: lib.nameValuePair "${prefix}${toString i}" (a c alpha)) brackets);
  indexedRows = prefix: hues: lib.listToAttrs (lib.imap1 (i: c: lib.nameValuePair "${prefix}${toString i}" c) hues);

  # ANSI-16 fold: the owner attr names spell the key tails (black -> ansiBlack).
  ansiRows =
    lib.mapAttrs' (
      n: c: lib.nameValuePair "terminal.ansi${lib.toUpper (lib.substring 0 1 n)}${lib.substring 1 (lib.stringLength n) n}" c
    )
    ansi;

  # Suggest/outline/breadcrumb icon hues mirror the syntax scope pivot: types
  # cyan, callables green, values blue, constants purple, keywords pink.
  symbolIcons = lib.mapAttrs' (kind: c: lib.nameValuePair "symbolIcon.${kind}Foreground" c) {
    class = p.cyan;
    struct = p.cyan;
    interface = p.cyan;
    module = p.cyan;
    namespace = p.cyan;
    package = p.cyan;
    typeParameter = p.cyan;
    enumerator = p.cyan;
    enumeratorMember = p.purple;
    constructor = p.green;
    function = p.green;
    method = p.green;
    event = p.magenta;
    field = p.blue;
    property = p.blue;
    variable = p.blue;
    reference = p.blue;
    key = p.blue;
    constant = p.purple;
    number = p.purple;
    boolean = p.purple;
    null = p.purple;
    unit = p.purple;
    keyword = p.pink;
    operator = s.text.subtle;
    string = p.yellow;
    array = s.text.subtle;
    object = s.text.subtle;
    snippet = s.text.primary;
    text = s.text.primary;
    file = s.text.primary;
    folder = s.text.subtle;
  };
in {
  # --- [ASSERTED] ---------------------------------------------------------------------------
  # Scalar design law: stripped from the user region so the owners govern
  # estate-wide. Values must stay scalar (the strip regex is single-line).
  asserted = {
    # --- [TYPOGRAPHY]
    "editor.fontFamily" = f.projections.vscodeFamily;
    "editor.fontSize" = builtins.floor f.metrics.size;
    "editor.fontLigatures" = f.features.vscode;
    "editor.fontVariations" = false; # static primary; fractional axes are a variable-font lever
    "editor.lineHeight" = f.metrics.editorLineHeight;
    "editor.renderWhitespace" = "trailing";
    "terminal.integrated.fontFamily" = f.projections.vscodeFamily;
    "terminal.integrated.fontSize" = builtins.floor f.metrics.size;
    "terminal.integrated.fontLigatures.enabled" = false;
    "terminal.integrated.lineHeight" = 1.0;
    "terminal.integrated.fontWeight" = "normal";
    "terminal.integrated.fontWeightBold" = "bold";
    # --- [THEME_OWNERSHIP]
    # Builtin substrate: every visible family is overridden below, so the
    # base theme contributes fallback values only, never a rendered color.
    # Product icons ride the one finalist that restyles the full codicon
    # registry (651 defs over 603 ids) — same publisher family as the file
    # icons, one visual vocabulary across both icon planes; product glyphs
    # are single-color fonts, so the palette above still owns every hue.
    "workbench.colorTheme" = "Default Dark Modern";
    "workbench.iconTheme" = "material-icon-theme";
    "workbench.productIconTheme" = "material-product-icons";
    "material-icon-theme.folders.color" = s.accent.structural;
    # --- [RENDER]
    # The ANSI projection is contrast-verified at the palette owner; the
    # runtime contrast mutator would repaint owned hues. Motion stays app
    # default — animated caret/scroll rows read out-of-sync on this machine.
    "terminal.integrated.minimumContrastRatio" = 1;
    "terminal.integrated.customGlyphs" = true;
    "terminal.integrated.rescaleOverlappingGlyphs" = true;
    # --- [CHROME_DENSITY]
    # +0.25 zoom (1.2^0.25, ~4.7%) is the one truthful lever for workbench text
    # scale — fractional levels pass to Electron unrounded, no finer sidebar or
    # title font key exists, and hover text follows editor font x zoom (the
    # hover registry carries enabled/delay/sticky/hidingDelay/above only; no
    # size or heading-scale keys). Manual zoom stays per-window (zoomPerWindow).
    "window.zoomLevel" = 0.25;
    "workbench.tree.indent" = 12;
    # Gutter and tab-row density: 3 line-number chars cover every file under
    # 10k lines without the 5-char default's dead margin; compact is the one
    # registered step below default tab height.
    "editor.lineNumbersMinChars" = 3;
    "window.density.editorTabHeight" = "compact";
  };

  # --- [SETTINGS] ---------------------------------------------------------------------------
  # Structured appearance rows: shadowable by design (workspace intent wins).
  settings = {
    "workbench.editor.customLabels.patterns" = {
      "**/default.nix" = "\${dirname} · default.nix";
      "**/SKILL.md" = "\${dirname} · SKILL";
      "**/README.md" = "\${dirname} · README";
      "**/CLAUDE.md" = "\${dirname} · CLAUDE";
      "**/__init__.py" = "\${dirname} · __init__";
      "**/index.ts" = "\${dirname} · index.ts";
    };
    "editor.minimap.renderCharacters" = false;
    "editor.minimap.maxColumn" = 100;
    "editor.stickyScroll.enabled" = true;
    "editor.stickyScroll.maxLineCount" = 5;
    "terminal.integrated.stickyScroll.enabled" = true;
    "editor.guides.bracketPairs" = "active";
    # Palette-bound TODO decorations: state hues, glyph-redundant via the tree.
    "todo-tree.general.tags" = ["TODO" "FIXME" "HACK" "NOTE" "XXX"];
    "todo-tree.highlights.defaultHighlight" = {
      type = "tag";
      gutterIcon = true;
      foreground = s.text.inverse;
      background = s.state.warning;
    };
    "todo-tree.highlights.customHighlight" = {
      FIXME.background = s.state.danger;
      HACK.background = s.state.attention;
      NOTE.background = s.state.info;
      XXX.background = s.accent.secondary;
    };

    # --- [TOKENS]: textMate + semantic rules from the one scope pivot.
    # Markdown scheme rides precise scopes, never the text.html.markdown base:
    # prose falls to editor.foreground (text.primary); [BRACKET] markers parse
    # as shortcut link references — labels read magenta-bold as status chips
    # while the bracket sigils recede to the structural tier beside list and
    # quote markers, so a `]-[` connector run stays typographic, never a
    # magenta smear; headings own every token inside themselves via deeper
    # selectors. fontStyle REPLACES on the deepest match (never merges), so
    # nested emphasis restates the outer weight. Raw spans are ONE literal
    # tier: sigils and content both ride string-yellow (the sigil row exists
    # because the generic punctuation rule would out-match the span rule on
    # the deeper punctuation.definition.raw scope); fence chrome recedes with
    # the info-string language id riding the attribute vocabulary.
    "editor.tokenColorCustomizations".textMateRules =
      t.projections.vscodeTokenRules
      ++ [
        {
          name = "Markdown bracket marker label";
          scope = "meta.link.reference string.other.link.title, meta.link.reference constant.other.reference.link, meta.link.reference.def constant.other.reference.link";
          settings = {
            foreground = s.accent.secondary;
            fontStyle = "bold";
          };
        }
        {
          name = "Markdown bracket marker sigils";
          scope = "meta.link.reference punctuation.definition.link.title, meta.link.reference punctuation.definition.constant, meta.link.reference.def punctuation.definition.constant";
          settings.foreground = s.accent.structural;
        }
        {
          name = "Markdown heading";
          scope = "markup.heading, markup.heading punctuation.definition.heading, markup.heading meta.link.reference string.other.link.title, markup.heading meta.link.reference punctuation.definition.link.title, markup.heading meta.link.reference constant.other.reference.link, markup.heading meta.link.reference punctuation.definition.constant";
          settings = {
            foreground = s.accent.structural;
            fontStyle = "bold";
          };
        }
        {
          # Whole raw span — content and both sigils — is one string-yellow
          # literal; known-language fences still override through their own
          # embedded grammars (deeper scopes always win).
          name = "Markdown raw span";
          scope = "markup.inline.raw, markup.raw.block";
          settings.foreground = p.yellow;
        }
        {
          name = "Markdown raw sigils";
          scope = "markup.inline.raw punctuation.definition.raw";
          settings.foreground = p.yellow;
        }
        {
          # Fence chrome recedes to the punctuation tier; embedded code keeps
          # its own grammar and the body of unknown fences stays prose.
          name = "Markdown fence delimiter";
          scope = "markup.fenced_code.block.markdown punctuation.definition.markdown";
          settings.foreground = s.text.subtle;
        }
        {
          name = "Markdown fence language";
          scope = "fenced_code.block.language";
          settings = {
            foreground = p.blue;
            fontStyle = "italic";
          };
        }
        {
          name = "Markdown link";
          scope = "text.html.markdown markup.underline.link, meta.link.inline string.other.link.title, string.other.link.description";
          settings.foreground = s.accent.primary;
        }
        {
          name = "Markdown italic";
          scope = "text.html.markdown markup.italic";
          settings = {
            foreground = s.accent.tertiary;
            fontStyle = "italic";
          };
        }
        {
          # Replacement semantics would render ***x*** italic-only without
          # this row; foreground still resolves from the italic rule above.
          name = "Markdown emphasis stack";
          scope = "markup.bold markup.italic, markup.italic markup.bold";
          settings.fontStyle = "bold italic";
        }
        {
          name = "Markdown strikethrough";
          scope = "markup.strikethrough";
          settings = {
            foreground = s.text.muted;
            fontStyle = "strikethrough";
          };
        }
        {
          name = "Markdown structure markers";
          scope = "punctuation.definition.list.begin.markdown, punctuation.definition.quote.begin.markdown";
          settings.foreground = s.accent.structural;
        }
        {
          name = "Markdown quote";
          scope = "markup.quote";
          settings = {
            foreground = s.text.subtle;
            fontStyle = "italic";
          };
        }
        {
          name = "Markdown separator";
          scope = "meta.separator.markdown";
          settings.foreground = s.text.subtle;
        }
      ];
    "editor.semanticTokenColorCustomizations" = {
      enabled = true;
      rules = t.projections.vscodeSemanticRules;
    };

    # --- [COLORS]: complete family coverage from the palette owner
    "workbench.colorCustomizations" =
      symbolIcons
      // ansiRows
      // bracketRows "editorBracketPairGuide.activeBackground" "40"
      // indexedRows "editorBracketHighlight.foreground" brackets
      // indexedRows "scmGraph.foreground" [p.cyan p.magenta p.purple p.blue p.green]
      // {
        # --- [GLOBALS]
        "focusBorder" = s.accent.primary;
        "foreground" = s.text.primary;
        "descriptionForeground" = s.text.subtle;
        "disabledForeground" = s.text.muted;
        "errorForeground" = s.state.danger;
        "icon.foreground" = s.text.subtle;
        "selection.background" = s.surface.selected;
        "widget.shadow" = a p.crust "B3";
        "sash.hoverBorder" = s.accent.primary;
        "toolbar.hoverBackground" = s.surface.raised;
        "toolbar.activeBackground" = s.surface.selected;
        "textLink.foreground" = s.state.info;
        "textLink.activeForeground" = p.brightBlue;
        "textPreformat.foreground" = p.yellow; # preview/settings inline code joins the editor's raw-literal tier
        "textPreformat.background" = s.surface.crust;
        "textBlockQuote.background" = s.surface.surface;
        "textBlockQuote.border" = s.text.muted;
        "textCodeBlock.background" = s.surface.crust;
        "pickerGroup.foreground" = s.accent.primary;
        "pickerGroup.border" = s.surface.selected;
        "progressBar.background" = s.accent.primary;
        # --- [EDITOR_CORE]
        "editor.background" = s.surface.base;
        "editor.foreground" = s.text.primary;
        "editorLineNumber.foreground" = s.text.subtle;
        "editorLineNumber.activeForeground" = s.accent.primary;
        "editorCursor.foreground" = s.ui.cursor;
        "editor.lineHighlightBackground" = s.surface.raised;
        "editor.selectionBackground" = s.surface.selected;
        "editor.inactiveSelectionBackground" = a p.selection "66";
        "editor.selectionHighlightBackground" = a p.selection "66";
        "editor.wordHighlightBackground" = a p.selection "4D";
        "editor.wordHighlightStrongBackground" = a p.selection "80";
        "editor.findMatchBackground" = s.ui.match;
        "editor.findMatchHighlightBackground" = s.ui.search;
        "editor.hoverHighlightBackground" = a p.selection "4D";
        "editorIndentGuide.background1" = s.surface.selected;
        "editorIndentGuide.activeBackground1" = s.text.subtle;
        "editorWhitespace.foreground" = s.ui.whitespace;
        "editorBracketMatch.background" = a p.selection "4D";
        "editorBracketMatch.border" = s.text.subtle;
        "editorBracketHighlight.unexpectedBracket.foreground" = s.state.danger;
        "editorCodeLens.foreground" = s.text.muted;
        "editorLink.activeForeground" = s.state.info;
        "editorLightBulb.foreground" = s.state.warning;
        "editorLightBulbAutoFix.foreground" = s.state.info;
        "editorInlayHint.background" = a p.current_line "CC";
        "editorInlayHint.foreground" = s.text.subtle;
        "editorStickyScroll.background" = s.surface.base;
        "editorStickyScroll.shadow" = s.surface.crust;
        "editorStickyScrollHover.background" = s.surface.raised;
        "editorRuler.foreground" = s.surface.selected;
        "editor.foldBackground" = a p.selection "4D";
        "editor.linkedEditingBackground" = a p.magenta "1A";
        "editor.rangeHighlightBackground" = a p.selection "33";
        "editorGhostText.foreground" = s.text.muted;
        # --- [EDITOR_WIDGETS]
        "editorWidget.background" = s.surface.overlay;
        "editorWidget.border" = s.ui.border;
        "editorHoverWidget.background" = s.surface.overlay;
        "editorHoverWidget.foreground" = s.text.primary;
        "editorHoverWidget.border" = s.surface.selected;
        "editorSuggestWidget.background" = s.surface.overlay;
        "editorSuggestWidget.border" = s.surface.selected;
        "editorSuggestWidget.selectedBackground" = s.surface.selected;
        "editorSuggestWidget.highlightForeground" = s.accent.primary;
        "editorSuggestWidget.focusHighlightForeground" = s.accent.primary;
        "quickInput.background" = s.surface.overlay;
        "quickInputTitle.background" = s.surface.crust;
        "quickInputList.focusBackground" = s.surface.selected;
        "quickInputList.focusForeground" = s.text.primary;
        "quickInputList.focusIconForeground" = s.accent.primary;
        # --- [DIAGNOSTICS]
        "editorError.foreground" = s.state.danger;
        "editorWarning.foreground" = s.state.warning;
        "editorInfo.foreground" = s.state.info;
        "editorHint.foreground" = s.text.subtle;
        "problemsErrorIcon.foreground" = s.state.danger;
        "problemsWarningIcon.foreground" = s.state.warning;
        "problemsInfoIcon.foreground" = s.state.info;
        "errorLens.errorBackground" = a p.red "1A";
        "errorLens.errorForeground" = s.state.danger;
        "errorLens.warningBackground" = a p.amber "1A";
        "errorLens.warningForeground" = s.state.warning;
        "errorLens.infoBackground" = a p.blue "1A";
        "errorLens.infoForeground" = s.state.info;
        "errorLens.hintForeground" = s.text.subtle;
        # --- [GUTTER_RULER_MINIMAP]
        "editorGutter.addedBackground" = g.added;
        "editorGutter.modifiedBackground" = g.modified;
        "editorGutter.deletedBackground" = g.deleted;
        "editorGutter.foldingControlForeground" = s.text.subtle;
        "editorGutter.commentRangeForeground" = s.text.subtle;
        "editorOverviewRuler.border" = "#00000000";
        "editorOverviewRuler.findMatchForeground" = a p.yellow "80";
        "editorOverviewRuler.selectionHighlightForeground" = a p.selection "CC";
        "editorOverviewRuler.errorForeground" = s.state.danger;
        "editorOverviewRuler.warningForeground" = s.state.warning;
        "editorOverviewRuler.infoForeground" = s.state.info;
        "editorOverviewRuler.addedForeground" = a g.added "99";
        "editorOverviewRuler.modifiedForeground" = a g.modified "99";
        "editorOverviewRuler.deletedForeground" = a g.deleted "99";
        "editorOverviewRuler.bracketMatchForeground" = s.text.subtle;
        "minimap.selectionHighlight" = s.surface.selected;
        "minimap.findMatchHighlight" = s.ui.match;
        "minimap.errorHighlight" = s.state.danger;
        "minimap.warningHighlight" = s.state.warning;
        "minimapSlider.background" = a p.selection "4D";
        "minimapSlider.hoverBackground" = a p.selection "66";
        "minimapSlider.activeBackground" = a p.selection "80";
        "minimapGutter.addedBackground" = g.added;
        "minimapGutter.modifiedBackground" = g.modified;
        "minimapGutter.deletedBackground" = g.deleted;
        "scrollbar.shadow" = s.surface.crust;
        "scrollbarSlider.background" = a p.selection "66";
        "scrollbarSlider.hoverBackground" = a p.selection "99";
        "scrollbarSlider.activeBackground" = a p.cyan "66";
        # --- [PEEK_MERGE_DIFF]
        "peekView.border" = s.accent.primary;
        "peekViewEditor.background" = s.surface.surface;
        "peekViewEditor.matchHighlightBackground" = s.ui.search;
        "peekViewResult.background" = s.surface.crust;
        "peekViewResult.matchHighlightBackground" = s.ui.search;
        "peekViewResult.selectionBackground" = s.surface.selected;
        "peekViewResult.fileForeground" = s.text.primary;
        "peekViewResult.lineForeground" = s.text.subtle;
        "peekViewTitle.background" = s.surface.surface;
        "peekViewTitleLabel.foreground" = s.text.primary;
        "peekViewTitleDescription.foreground" = s.text.subtle;
        "peekViewEditorGutter.background" = s.surface.surface;
        "searchEditor.findMatchBackground" = s.ui.search;
        "diffEditor.insertedLineBackground" = s.diff.add;
        "diffEditor.insertedTextBackground" = s.diff.addEmph;
        "diffEditor.removedLineBackground" = s.diff.del;
        "diffEditor.removedTextBackground" = s.diff.delEmph;
        "diffEditor.diagonalFill" = s.surface.selected;
        "multiDiffEditor.headerBackground" = s.surface.surface;
        "mergeEditor.change.background" = s.diff.change;
        "mergeEditor.change.word.background" = s.diff.changeEmph;
        "mergeEditor.conflict.unhandledUnfocused.border" = s.state.warning;
        "mergeEditor.conflict.handledUnfocused.border" = s.state.success;
        # --- [ACTIVITY_SIDE_STATUS_TITLE]
        "activityBar.background" = s.surface.crust;
        "activityBar.foreground" = s.accent.primary;
        "activityBar.inactiveForeground" = s.text.subtle;
        "activityBar.border" = s.surface.crust;
        "activityBar.activeBorder" = s.accent.primary;
        "activityBarBadge.background" = s.accent.secondary;
        "activityBarBadge.foreground" = s.text.inverse;
        "sideBar.background" = s.surface.crust;
        # Undecorated explorer rows inherit sideBar.foreground (no list.foreground
        # token exists); primary keeps unchanged files bright, git states recolor.
        "sideBar.foreground" = s.text.primary;
        "sideBar.border" = s.surface.crust;
        "sideBarTitle.foreground" = s.text.primary;
        "sideBarSectionHeader.background" = s.surface.crust;
        "sideBarSectionHeader.foreground" = s.text.subtle;
        "sideBarStickyScroll.background" = s.surface.crust;
        "statusBar.background" = s.surface.surface;
        "statusBar.foreground" = s.text.subtle;
        "statusBar.border" = s.surface.surface;
        "statusBar.noFolderBackground" = s.surface.surface;
        "statusBar.debuggingBackground" = s.state.attention;
        "statusBar.debuggingForeground" = s.text.inverse;
        "statusBarItem.hoverBackground" = s.surface.raised;
        "statusBarItem.prominentBackground" = s.surface.raised;
        "statusBarItem.remoteBackground" = s.accent.structural;
        "statusBarItem.remoteForeground" = s.text.primary;
        "statusBarItem.errorBackground" = s.state.danger;
        "statusBarItem.errorForeground" = s.text.inverse;
        "statusBarItem.warningBackground" = s.state.warning;
        "statusBarItem.warningForeground" = s.text.inverse;
        "titleBar.activeBackground" = s.surface.crust;
        "titleBar.activeForeground" = s.text.subtle;
        "titleBar.inactiveBackground" = s.surface.crust;
        "titleBar.inactiveForeground" = s.text.muted;
        "commandCenter.background" = s.surface.surface;
        "commandCenter.foreground" = s.text.subtle;
        "commandCenter.activeBackground" = s.surface.raised;
        "commandCenter.activeForeground" = s.text.primary;
        "commandCenter.border" = a p.subtle "33";
        "commandCenter.activeBorder" = a p.subtle "66";
        # --- [TABS_GROUPS_PANEL]
        "editorGroupHeader.tabsBackground" = s.surface.surface;
        "editorGroup.border" = s.surface.surface;
        "editorGroup.dropBackground" = a p.selection "40";
        "tab.activeBackground" = s.surface.base;
        "tab.activeForeground" = s.text.primary;
        "tab.inactiveBackground" = s.surface.surface;
        "tab.inactiveForeground" = s.text.subtle;
        "tab.activeBorderTop" = s.accent.primary;
        "tab.hoverBackground" = s.surface.raised;
        "tab.border" = s.surface.surface;
        "tab.lastPinnedBorder" = s.surface.selected;
        "tab.dragAndDropBorder" = s.accent.primary;
        "panel.background" = s.surface.base;
        "panel.border" = s.surface.surface;
        "panelTitle.activeForeground" = s.accent.primary;
        "panelTitle.inactiveForeground" = s.text.subtle;
        "panelSectionHeader.background" = s.surface.surface;
        "panelSection.border" = s.surface.surface;
        # --- [LISTS_TREES_BREADCRUMBS]
        "list.activeSelectionBackground" = s.surface.selected;
        "list.inactiveSelectionBackground" = s.surface.raised;
        "list.hoverBackground" = s.surface.raised;
        "list.focusOutline" = a p.cyan "66";
        "list.highlightForeground" = s.accent.primary;
        "list.errorForeground" = s.state.danger;
        "list.warningForeground" = s.state.warning;
        "list.deemphasizedForeground" = s.text.muted;
        "list.dropBackground" = a p.selection "40";
        "list.filterMatchBackground" = s.ui.search;
        "list.focusHighlightForeground" = s.accent.primary;
        "tree.tableColumnsBorder" = s.surface.selected;
        "listFilterWidget.background" = s.surface.overlay;
        "listFilterWidget.outline" = s.accent.primary;
        "listFilterWidget.noMatchesOutline" = s.state.danger;
        "tree.indentGuidesStroke" = s.surface.selected;
        "tree.inactiveIndentGuidesStroke" = a p.selection "66";
        "breadcrumb.background" = s.surface.base;
        "breadcrumb.foreground" = s.text.subtle;
        "breadcrumb.focusForeground" = s.text.primary;
        "breadcrumb.activeSelectionForeground" = s.accent.primary;
        "breadcrumbPicker.background" = s.surface.overlay;
        # --- [INPUTS_BUTTONS_BADGES]
        "input.background" = s.surface.crust;
        "input.foreground" = s.text.primary;
        "input.border" = s.surface.selected;
        "input.placeholderForeground" = s.text.muted;
        "inputOption.activeBackground" = a p.cyan "33";
        "inputOption.activeForeground" = s.accent.primary;
        "inputOption.activeBorder" = s.accent.primary;
        "inputValidation.errorBackground" = s.diff.del;
        "inputValidation.errorBorder" = s.state.danger;
        "inputValidation.warningBackground" = s.ui.search;
        "inputValidation.warningBorder" = s.state.warning;
        "inputValidation.infoBackground" = s.diff.change;
        "inputValidation.infoBorder" = s.state.info;
        "dropdown.background" = s.surface.overlay;
        "dropdown.listBackground" = s.surface.overlay;
        "dropdown.foreground" = s.text.primary;
        "dropdown.border" = s.surface.selected;
        "button.background" = s.accent.primary;
        "button.foreground" = s.text.inverse;
        "button.hoverBackground" = a p.cyan "CC";
        "button.secondaryBackground" = s.surface.overlay;
        "button.secondaryForeground" = s.text.primary;
        "button.secondaryHoverBackground" = s.surface.selected;
        "checkbox.background" = s.surface.crust;
        "checkbox.foreground" = s.accent.primary;
        "checkbox.border" = s.surface.selected;
        "badge.background" = s.accent.secondary;
        "badge.foreground" = s.text.inverse;
        "keybindingLabel.background" = s.surface.crust;
        "keybindingLabel.foreground" = s.text.subtle;
        "keybindingLabel.border" = s.surface.selected;
        "keybindingLabel.bottomBorder" = s.surface.crust;
        # --- [MENUS_NOTIFICATIONS_BANNER]
        "menu.background" = s.surface.overlay;
        "menu.foreground" = s.text.primary;
        "menu.selectionBackground" = s.surface.selected;
        "menu.selectionForeground" = s.text.primary;
        "menu.separatorBackground" = s.surface.selected;
        "menu.border" = s.surface.selected;
        "notifications.background" = s.surface.overlay;
        "notifications.foreground" = s.text.primary;
        "notificationCenterHeader.background" = s.surface.crust;
        "notificationCenterHeader.foreground" = s.text.subtle;
        "notificationToast.border" = s.surface.overlay;
        "notificationsErrorIcon.foreground" = s.state.danger;
        "notificationsWarningIcon.foreground" = s.state.warning;
        "notificationsInfoIcon.foreground" = s.state.info;
        "notificationLink.foreground" = s.state.info;
        "banner.background" = s.surface.raised;
        "banner.foreground" = s.text.primary;
        "banner.iconForeground" = s.state.info;
        # --- [GIT_SCM]: bound to the owner git vocabulary; the modified pair
        # rides the cyan accent role (operator law) — the blue git hue reads
        # too dark as explorer text on crust.
        "gitDecoration.addedResourceForeground" = g.added;
        "gitDecoration.modifiedResourceForeground" = s.accent.primary;
        "gitDecoration.deletedResourceForeground" = g.deleted;
        "gitDecoration.stageModifiedResourceForeground" = s.accent.primary;
        "gitDecoration.stageDeletedResourceForeground" = g.deleted;
        "gitDecoration.untrackedResourceForeground" = g.untracked;
        "gitDecoration.ignoredResourceForeground" = s.text.muted;
        "gitDecoration.renamedResourceForeground" = g.renamed;
        "gitDecoration.conflictingResourceForeground" = g.conflict;
        "gitDecoration.submoduleResourceForeground" = s.state.info;
        # --- [TERMINAL]: ANSI-16 rides the ansiRows fold
        "terminal.background" = p.background;
        "terminal.foreground" = p.foreground;
        "terminal.selectionBackground" = p.selection;
        "terminal.border" = s.surface.surface;
        "terminalCursor.foreground" = p.foreground;
        "terminalCommandDecoration.defaultBackground" = a p.subtle "66";
        "terminalCommandDecoration.successBackground" = s.state.success;
        "terminalCommandDecoration.errorBackground" = s.state.danger;
        "terminalOverviewRuler.cursorForeground" = s.accent.primary;
        "terminalStickyScroll.background" = p.background;
        "terminalStickyScrollHover.background" = s.surface.raised;
        "terminal.dropBackground" = a p.selection "40";
        # --- [DEBUG_TESTING_CHAT]
        "debugToolBar.background" = s.surface.overlay;
        "debugIcon.breakpointForeground" = s.state.danger;
        "debugIcon.startForeground" = s.state.success;
        "debugTokenExpression.name" = p.blue;
        "debugTokenExpression.value" = s.text.primary;
        "debugTokenExpression.string" = p.yellow;
        "debugTokenExpression.boolean" = p.purple;
        "debugTokenExpression.number" = p.purple;
        "debugTokenExpression.error" = s.state.danger;
        "debugTokenExpression.type" = p.cyan;
        "debugConsole.infoForeground" = s.state.info;
        "debugConsole.warningForeground" = s.state.warning;
        "debugConsole.errorForeground" = s.state.danger;
        "debugConsole.sourceForeground" = s.text.subtle;
        "notebook.editorBackground" = s.surface.base;
        "notebook.cellEditorBackground" = s.surface.surface;
        "notebook.cellBorderColor" = s.surface.selected;
        "notebook.focusedCellBorder" = s.accent.primary;
        "notebook.selectedCellBackground" = s.surface.raised;
        "testing.iconPassed" = s.state.success;
        "testing.iconFailed" = s.state.danger;
        "testing.iconErrored" = s.state.danger;
        "testing.iconQueued" = s.state.warning;
        "testing.iconUnset" = s.text.subtle;
        "testing.iconSkipped" = s.text.muted;
        "testing.peekBorder" = s.state.danger;
        "inlineChat.background" = s.surface.overlay;
        "chat.requestBackground" = s.surface.surface;
        "chat.requestBorder" = s.surface.crust;
        "chat.avatarBackground" = s.surface.raised;
        "chat.avatarForeground" = s.accent.primary;
        "chat.slashCommandForeground" = s.accent.primary;
        # --- [SETTINGS_WELCOME_CHARTS]
        "settings.headerForeground" = s.text.primary;
        "settings.modifiedItemIndicator" = s.accent.secondary;
        "settings.focusedRowBackground" = s.surface.raised;
        "settings.rowHoverBackground" = a p.current_line "80";
        "welcomePage.background" = s.surface.base;
        "welcomePage.tileBackground" = s.surface.surface;
        "welcomePage.tileHoverBackground" = s.surface.raised;
        "charts.foreground" = s.text.primary;
        "charts.lines" = s.text.subtle;
        "charts.red" = p.red;
        "charts.blue" = p.blue;
        "charts.yellow" = p.yellow;
        "charts.orange" = p.orange;
        "charts.green" = p.green;
        "charts.purple" = p.purple;
      };
  };
}
