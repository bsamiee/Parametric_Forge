# Title         : theme.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/theme.nix
# ----------------------------------------------------------------------------
# Forge palette owner: enriched Dracula-variant rows, semantic roles, ANSI-16 projection, the master syntax scope table (tmTheme, treesitter,
# textMate, and semantic tokens project from one pivot), derived diff/search/git roles, and the shared icon vocabulary. Every color consumer
# interpolates these tokens; no consumer carries a private hex.
{
  config,
  lib,
  pkgs,
  ...
}: let
  fonts = config.forge.fonts;
  byte = s: i: lib.fromHexString (builtins.substring i 2 s);

  # Color record: uppercase hex plus every numeric rendering consumers need.
  mkColor = raw: let
    hex = lib.toUpper raw;
    r = byte hex 1;
    g = byte hex 3;
    b = byte hex 5;
  in {
    inherit hex r g b;
    triple = "${toString r} ${toString g} ${toString b}";
    csv = "${toString r},${toString g},${toString b}";
    rgba = alpha: "rgba(${toString r}, ${toString g}, ${toString b}, ${alpha})";
  };

  # --- [ROW_GRAMMAR]
  # Positional tuples zip against a field schema: a short tuple drops trailing fields and null skips a slot. byName keys a row list on its `name`.
  row = fields: t: lib.filterAttrs (_: v: v != null) (lib.listToAttrs (lib.zipListsWith lib.nameValuePair fields t));
  byName = rows: lib.listToAttrs (map (r: lib.nameValuePair r.name (removeAttrs r ["name"])) rows);

  # Enriched palette: the canonical rows plus the design-language growth — crust/surface complete the elevation ladder, subtle is the third fg
  # tier and the structural-UI hue, amber splits warning from string-yellow, blue ends the faked ANSI blue, brightBlue ends blue==cyan.
  # current_line is retuned (chroma pulled to kill the muddy active line) and magenta is AA-lifted; every row is contrast-verified against the
  # base. Rows spell as name=#HEX tokens folded through mkColor — one vector, one constructor.
  hexRows = s: lib.listToAttrs (map (t: let p = lib.splitString "=" t; in lib.nameValuePair (builtins.head p) (mkColor (builtins.elemAt p 1))) (lib.splitString " " s));
  palette = hexRows "crust=#0E0D16 background=#15131F surface=#201E30 current_line=#2A2A3A selection=#44475A foreground=#F8F8F2 subtle=#8E91A5 comment=#6272A4 purple=#A072C6 cyan=#94F2E8 green=#50FA7B yellow=#F1FA8C amber=#F3AE51 orange=#F97359 red=#FF5555 magenta=#EE55A8 pink=#E98FBE blue=#7AA2F7 brightBlue=#A9C7FF";

  # Derived roles: computed fills, never palette rows. Diff and search tint the background and hold the code foreground neutral (fg clears 7.7+
  # on every fill); emphasis is the same hue at +0.06 OKLCH L.
  derived = hexRows "overlay=#37364D diffAdd=#122A18 diffAddEmph=#213926 diffDel=#3B1818 diffDelEmph=#4C2726 diffChange=#152539 diffChangeEmph=#233449 search=#3A3418 searchCurrent=#5A4E1E";

  # Role families as [name color] pair rows folded per family.
  pairs = ps: lib.listToAttrs (map (p: lib.nameValuePair (builtins.elemAt p 0) (builtins.elemAt p 1)) ps);
  families = lib.mapAttrs (_: pairs) {
    surface = [["crust" palette.crust] ["base" palette.background] ["surface" palette.surface] ["raised" palette.current_line] ["overlay" derived.overlay] ["selected" palette.selection]];
    text = [["primary" palette.foreground] ["subtle" palette.subtle] ["muted" palette.comment] ["inverse" palette.background]];
    accent = [["primary" palette.cyan] ["secondary" palette.magenta] ["tertiary" palette.pink] ["structural" palette.purple]];
    state = [["success" palette.green] ["warning" palette.amber] ["attention" palette.orange] ["danger" palette.red] ["info" palette.blue]];
    # Focus pair: the one active/inactive derivation every chrome surface (tabs, pane frames, ribbons) reads instead of re-picking hues.
    focus = [["active" palette.cyan] ["inactive" palette.subtle]];
    # Modal-UI hue ladder: one hue per mux/editor mode chip; search and entersearch share deliberately (one toggled surface), renames share
    # (one input-editing state), and every other mode reads distinct at a glance — no two standing modes collapse onto one hue.
    mode = [["normal" palette.green] ["locked" palette.selection] ["tab" palette.magenta] ["pane" palette.orange] ["move" palette.cyan] ["resize" palette.purple] ["scroll" palette.yellow] ["search" palette.pink] ["entersearch" palette.pink] ["session" palette.blue] ["renametab" palette.red] ["renamepane" palette.red] ["prompt" palette.foreground] ["tmux" palette.amber]];
    diff = [["add" derived.diffAdd] ["addEmph" derived.diffAddEmph] ["del" derived.diffDel] ["delEmph" derived.diffDelEmph] ["change" derived.diffChange] ["changeEmph" derived.diffChangeEmph]];
    ui = [["border" palette.subtle] ["cursor" palette.foreground] ["indent" palette.subtle] ["whitespace" palette.selection] ["search" derived.search] ["match" derived.searchCurrent]];
  };

  # Two-register git vocabulary from the fonts-catalog gitAlphabet rows; dotted role paths resolve on the folded families (contextBadges grammar),
  # so a hue rebind lands on every consumer and a new state is one catalog row. Register law: ascii = persisted/piped output and prose-like readouts
  # where marker+count reads as a text token (delta labels; the operator-ratified starship cluster); glyph = fixed one-cell icon columns where shape
  # is the cue (gitsigns gutter, yazi linemode); unthemable-glyph tools (eza NFv3) take .color only; the prompt alone bins color.
  roles =
    families
    // {
      git = byName (map (t: {
          name = builtins.elemAt t 0;
          color = lib.getAttrFromPath (lib.splitString "." (builtins.elemAt t 1)) families;
          glyph = builtins.fromJSON ''"\u${builtins.elemAt t 2}"'';
          ascii = builtins.elemAt t 3;
        })
        fonts.catalog."Symbols Nerd Font Mono".gitAlphabet);
    };

  # Canonical hex->ANSI-16 assignment; terminal palettes and ANSI-slot consumers agree with truecolor consumers. Slot 4 carries a real blue,
  # slot 12 its bright companion, and both magenta slots ride the AA lift. Brights derive from the normal octet with the two real divergences
  # (brightBlack -> selection, brightBlue -> the dedicated bright row) as override rows.
  ansi16 = let
    base = {
      inherit (palette) red green yellow blue magenta cyan;
      black = palette.background;
      white = palette.foreground;
    };
  in
    base
    // lib.mapAttrs' (n: v: lib.nameValuePair "bright${lib.toUpper (builtins.substring 0 1 n)}${builtins.substring 1 99 n}" v)
    (base
      // {
        black = palette.selection;
        blue = palette.brightBlue;
      });

  # Master scope table: the one scope-to-role-to-hue pivot. tmTheme (bat, delta, yazi syntect), VS Code textMate + semantic tokens, and the nvim
  # treesitter projection all derive from these rows; `captures` names the treesitter side so a hue rebind lands everywhere with zero edits.
  # Rebinds vs stock Dracula: keyword->pink (AA), operator/punctuation->subtle, escape->orange, variable/parameter->blue (ends type==variable),
  # tag keeps magenta, warning splits to amber so a diagnostic is never a string. Row tuple: [name scope color style captures background].
  syntaxScopes = map (row ["name" "scope" "color" "style" "captures" "background"]) [
    ["Comment" "comment, punctuation.definition.comment" palette.comment "italic" ["comment"]]
    ["String" "string" palette.yellow null ["string" "character"]]
    ["Escape" "constant.character.escape" palette.orange null ["string.escape" "character.special"]]
    ["Number" "constant.numeric" palette.purple null ["number" "number.float"]]
    ["Constant" "constant.language, constant.character, constant.other" palette.purple null ["constant" "constant.builtin" "boolean"]]
    ["Keyword" "keyword, storage, storage.type, storage.modifier" palette.pink null ["keyword"]]
    ["Operator" "keyword.operator, punctuation.accessor" palette.subtle null ["operator" "keyword.operator"]]
    ["Punctuation" "punctuation" palette.subtle null ["punctuation.bracket" "punctuation.delimiter" "punctuation.special"]]
    ["Function" "entity.name.function, support.function" palette.green null ["function" "function.method" "function.macro" "function.builtin"]]
    ["Type" "entity.name.class, entity.name.type, entity.other.inherited-class, support.type, support.class" palette.cyan null ["type" "type.builtin" "constructor"]]
    ["Variable" "variable, support.variable" palette.blue null ["variable" "variable.member" "property"]]
    ["Parameter" "variable.parameter" palette.blue "italic" ["variable.parameter"]]
    ["Attribute" "entity.other.attribute-name" palette.magenta "italic" ["attribute"]]
    ["Tag" "entity.name.tag" palette.magenta null ["tag"]]
    ["Heading" "markup.heading" palette.purple "bold" ["markup.heading"]]
    ["Bold" "markup.bold" palette.orange "bold" ["markup.strong"]]
    ["Italic" "markup.italic" palette.yellow "italic" ["markup.italic"]]
    ["Link" "markup.underline.link" palette.blue null ["markup.link" "markup.link.url" "string.special.url"]]
    ["Inserted" "markup.inserted" palette.green null ["diff.plus"]]
    ["Deleted" "markup.deleted" palette.red null ["diff.minus"]]
    ["Invalid" "invalid" palette.foreground null [] palette.red]
  ];

  # Shared icon vocabulary: one directory/process glyph table projected into consumers (Yazi dirs; tab titles, prompts, and dashboards
  # adopt through their register rows) — never app-local maps. Dir row tuple: [name glyph color].
  icons = {
    dirs = byName (map (row ["name" "glyph" "color"]) [
      [".git" "󰊢" palette.pink]
      ["node_modules" "󰏗" palette.green]
      ["target" "󰀘" palette.magenta]
      [".venv" "󰅩" palette.yellow]
      ["__pycache__" "󰌠" palette.yellow]
      [".config" "󰒓" palette.purple]
      [".ssh" "󰣀" palette.pink]
      ["src" "󰈙" palette.cyan]
      ["bin" "󰞰" palette.green]
    ]);
    process = {
      nvim = "";
      zsh = "󰆍";
      python = "󰌠";
      node = "󰎙";
      ssh = "󰣀";
      git = "󰊢";
      nix = "󱄅";
      claude = "󰙴";
      container = builtins.fromJSON ''"\uf4b7"''; # oct-container: in-container rootfs
    };
    # Status alphabet: the CLOSED glyph vocabulary for terminal-bound render surfaces — single-codepoint codicons (Symbols Nerd Font Mono,
    # 1-cell advance), each with the ASCII twin persisted surfaces use instead. Rows live on the symbols family (fonts catalog
    # statusAlphabet) beside the font they mint from; codepoint minting is immune to harness glyph-stripping. Emoji and EAW-ambiguous glyphs never render on width-load-bearing surfaces; a new status class is
    # one catalog row, never an app-local glyph.
    alphabet = byName (map (t: {
        name = builtins.elemAt t 0;
        glyph = builtins.fromJSON ''"\u${builtins.elemAt t 1}"'';
        ascii = builtins.elemAt t 2;
      })
      fonts.catalog."Symbols Nerd Font Mono".statusAlphabet);
  };

  scopeRule = row: let
    style = row.style or null;
    background = row.background or null;
  in ''
        <dict>
          <key>name</key><string>${row.name}</string>
          <key>scope</key><string>${row.scope}</string>
          <key>settings</key>
          <dict>
            <key>foreground</key><string>${row.color.hex}</string>
    ${lib.optionalString (background != null) "        <key>background</key><string>${background.hex}</string>\n"}${lib.optionalString (style != null) "        <key>fontStyle</key><string>${style}</string>\n"}      </dict>
        </dict>'';

  # Global editor settings rows: [key role] pairs folded into the leading settings dict; scope rules follow from the master pivot.
  tmSetting = p: "        <key>${builtins.elemAt p 0}</key><string>${(builtins.elemAt p 1).hex}</string>";
  tmTheme = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>name</key>
      <string>Forge Dracula</string>
      <key>settings</key>
      <array>
        <dict>
          <key>settings</key>
          <dict>
    ${lib.concatMapStringsSep "\n" tmSetting [["background" roles.surface.base] ["foreground" roles.text.primary] ["caret" roles.text.primary] ["selection" roles.surface.selected] ["lineHighlight" roles.surface.raised] ["invisibles" roles.surface.selected] ["gutterForeground" roles.text.subtle] ["findHighlight" roles.ui.match] ["findHighlightForeground" roles.text.primary] ["misspelling" roles.state.danger]]}
          </dict>
        </dict>
    ${lib.concatMapStringsSep "\n" scopeRule syntaxScopes}
      </array>
    </dict>
    </plist>
  '';
  tmThemeFile = pkgs.writeText "forge-dracula.tmTheme" tmTheme;

  fzfColorRows = [
    "--color=fg:${roles.text.primary.hex},fg+:${roles.text.inverse.hex},bg:${roles.surface.base.hex},bg+:${roles.focus.active.hex},selected-fg:${roles.text.inverse.hex},selected-bg:${roles.focus.active.hex}"
    "--color=hl:${roles.state.success.hex},hl+:${roles.accent.secondary.hex},info:${roles.text.muted.hex},marker:${roles.state.success.hex}"
    "--color=prompt:${roles.accent.secondary.hex},spinner:${roles.state.success.hex},pointer:${roles.accent.secondary.hex},header:${roles.text.muted.hex}"
    "--color=gutter:${roles.surface.base.hex},border:${roles.accent.primary.hex},separator:${roles.accent.tertiary.hex},scrollbar:${roles.accent.tertiary.hex}"
    "--color=preview-fg:${roles.text.primary.hex},preview-scrollbar:${roles.accent.tertiary.hex},label:${roles.accent.secondary.hex},query:${roles.text.primary.hex}"
  ];

  projections = {
    inherit tmThemeFile;
    # Flat hex mirror of the role families hex-projection consumers (VS Code, nvim, wezterm Lua rows) actually index; focus and mode stay Nix-side
    # deliberately — no hex consumer reads them. A new family lands here with its first consumer.
    rolesHex = lib.mapAttrs (_: lib.mapAttrs (_: c: c.hex)) {inherit (roles) surface text accent state diff ui;};
    # Git-state vocabulary rows (hex + both registers); terminal-bound consumers render .glyph, persisted/piped surfaces render .ascii, every
    # consumer takes .color from the same row.
    gitHex =
      lib.mapAttrs (_: g: {
        color = g.color.hex;
        inherit (g) glyph ascii;
      })
      roles.git;
    # Machine-context badges (remote host, in-container rootfs): the roles.git single-owner pattern applied to context — each row carries the
    # glyph and the dotted role path the prompt styles it with. Row tuple: [processIcon rolePath].
    contextBadges =
      lib.mapAttrs (_: t: {
        glyph = icons.process.${builtins.elemAt t 0};
        role = builtins.elemAt t 1;
      }) {
        remote = ["ssh" "state.warning"];
        container = ["container" "accent.structural"];
      };
    # Lua return-table behind the generated Neovim palette; derived fills ride along snake_cased for highlight consumers.
    luaPalette = ''
      -- Generated from the Forge theme owner (modules/home/theme.nix).
      return {
      ${lib.concatStrings (lib.mapAttrsToList (name: c: "  [\"${name}\"] = \"${c.hex}\",\n") palette)}${lib.concatStrings (lib.mapAttrsToList (name: c: "  [\"${name}\"] = \"${c.hex}\",\n") derived)}}
    '';
    # WezTerm color-scheme rows in the colors-TOML shape; the tab bar sits on the surface step and inactive chrome reads through the subtle tier.
    # Label quads and tab rows fold from [bg fg] pairs; ANSI vectors derive from the slot-name order.
    weztermColorScheme = let
      labeled = lib.concatMapAttrs (n: p: {
        "${n}_bg" = {Color = (builtins.elemAt p 0).hex;};
        "${n}_fg" = {Color = (builtins.elemAt p 1).hex;};
      });
      tab = bg: fg: {
        bg_color = bg.hex;
        fg_color = fg.hex;
      };
      slots = map (k: ansi16.${k}.hex);
    in
      lib.mapAttrs (_: c: c.hex) (pairs [["foreground" palette.foreground] ["background" palette.background] ["cursor_bg" palette.foreground] ["cursor_fg" palette.background] ["cursor_border" palette.foreground] ["selection_fg" palette.foreground] ["selection_bg" palette.selection] ["split" palette.subtle]])
      // {
        ansi = slots ["black" "red" "green" "yellow" "blue" "magenta" "cyan" "white"];
        brights = slots ["brightBlack" "brightRed" "brightGreen" "brightYellow" "brightBlue" "brightMagenta" "brightCyan" "brightWhite"];
        tab_bar = {
          background = roles.surface.surface.hex;
          active_tab = tab roles.accent.primary roles.text.inverse;
          inactive_tab = tab roles.surface.surface roles.text.subtle;
          inactive_tab_hover = tab roles.surface.raised roles.text.primary;
          new_tab = tab roles.surface.surface roles.text.subtle;
          new_tab_hover = tab roles.surface.raised roles.text.primary;
        };
      }
      // labeled {
        quick_select_label = [roles.state.attention roles.text.inverse];
        quick_select_match = [roles.surface.selected roles.text.primary];
        input_selector_label = [roles.surface.raised roles.accent.primary];
        launcher_label = [roles.surface.raised roles.accent.primary];
      };
    # Display-time grammar: transient/human surfaces render these strftime rows (24h local, no seconds, no tz); stored data stays ISO-8601 UTC.
    timeDisplay = {
      sameDay = "%H:%M";
      dated = "%d/%m %H:%M";
    };
    # fzf color vocabulary: the ONE role->slot mapping every fzf-embedding surface consumes (programs.fzf, fzf-tab).
    # Selection rides the focus pair, structure rides accents — a picker's selected row reads identically to the active tab chip everywhere.
    inherit fzfColorRows;
    # Per-command fzf argument vocabulary: colors plus the chrome every generated script carries per invocation (scripts never assume the
    # interactive FZF_DEFAULT_OPTS reached them); the richer global interactive chrome stays fzf.nix-owned.
    fzfArgs = fzfColorRows ++ ["--border=sharp" "--layout=reverse" "--info=right" "--highlight-line" "--prompt=❯ " "--pointer=❯"];
    # Four-step surface ramp for delta blame backgrounds.
    blameRamp = lib.concatMapStringsSep " " (c: c.hex) [
      roles.surface.base
      roles.surface.raised
      roles.surface.overlay
      roles.surface.selected
    ];
  };
in {
  options.forge.theme = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
    default = {inherit palette derived roles ansi16 syntaxScopes icons projections;};
    description = "Forge palette owner: enriched Dracula tokens, roles, ANSI-16, syntax scopes, icons, projections.";
  };
}
